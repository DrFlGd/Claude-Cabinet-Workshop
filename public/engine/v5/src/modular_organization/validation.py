#!/usr/bin/env python3
"""Exhaustive geometry/contract validator for Modular Organization v5.

The validator deliberately combines two independent views:

1. OpenSCAD semantic validation (interfaces, keepouts, and the complete outer
   cabinet-side machining ledger).
2. A final-geometry audit that traverses every contour emitted by CUT and every
   registered POCKET manufacturing operation in the common layout coordinate
   system.

"Exhaustive" here means exhaustive over the generated interface signatures and
manufacturing geometry that the engine emits. It does not claim structural
engineering, fastener load analysis, material-defect analysis, or CAM/toolpath
verification.
"""
from __future__ import annotations

import argparse
import json
import math
import re
from .runtime import run_scad
import tempfile
from collections import defaultdict
from pathlib import Path
from typing import Iterable

try:
    import ezdxf
except ImportError as exc:  # pragma: no cover
    raise SystemExit("modular-organization audit requires ezdxf") from exc
try:
    from shapely.geometry import GeometryCollection, LineString, Polygon
    from shapely.ops import unary_union
    from shapely.validation import explain_validity
except ImportError as exc:  # pragma: no cover
    raise SystemExit("modular-organization audit requires shapely") from exc

POCKET_MODES = [
    "pocket_slide_holes",
    "pocket_carcass_dados",
    "pocket_drawer_dados",
    "pocket_bottom_grooves",
    "pocket_divider_bottom_grooves",
    "pocket_divider_perimeter_grooves",
    "pocket_shelf_pins",
    "pocket_hinge_cups",
    "pocket_face_registration",
    "pocket_base_hardware",
    "pocket_worktop_registration",
    "pocket_face_frame_dados",
    "pocket_ganging",
]
ALL_MODES = ["cut_layout", *POCKET_MODES]
EXPECTED_POCKET_OVERLAPS = {
    frozenset(("pocket_drawer_dados", "pocket_bottom_grooves")),
    # Divider perimeter grooves intentionally terminate into the drawer-bottom
    # groove at the floor datum. Fit-clearance expansion can create a tiny
    # projected overlap; both operations are on the same inside face and this
    # is designed capture geometry rather than an accidental collision.
    frozenset(("pocket_bottom_grooves", "pocket_divider_perimeter_grooves")),
}


def parse_echo_payloads(text: str, prefix: str) -> list[str]:
    pat = re.compile(r'^ECHO:\s+"(' + re.escape(prefix) + r'.*)"\s*$', re.M)
    return [m.group(1) for m in pat.finditer(text)]


def parse_record(payload: str) -> dict[str, str]:
    parts = payload.split("|")
    rec: dict[str, str] = {"record_type": parts[0] if parts else ""}
    extras: list[str] = []
    for field in parts[1:]:
        if "=" in field:
            k, v = field.split("=", 1)
            rec[k.lower()] = v
        elif field:
            extras.append(field)
    if extras:
        rec["subtype"] = extras[0]
    return rec


def make_param_json(source: Path, preset: str, mode: str, dest: Path,
                    verbose_contract: bool = True) -> None:
    data = json.loads(source.read_text(encoding="utf-8"))
    try:
        ps = dict(data["parameterSets"][preset])
    except KeyError as exc:
        raise SystemExit(f"Preset {preset!r} not found in {source}") from exc
    ps["output_mode"] = mode
    ps["validation_report"] = "verbose"
    ps["system_contract_report"] = "verbose" if verbose_contract else "summary"
    dest.write_text(json.dumps({"parameterSets": {"AUDIT": ps}}, indent=2), encoding="utf-8")


def run_openscad(scad: Path, openscad: str, out: Path, mode: str,
                 defines: list[str], param_json: Path | None,
                 preset: str | None, verbose_contract: bool = False) -> tuple[int, str, list[str]]:
    cmd = [openscad]
    temp_param: Path | None = None
    if param_json is not None:
        temp_param = out.parent / f"._audit_params_{mode}.json"
        make_param_json(param_json, preset or "", mode, temp_param, verbose_contract)
        cmd += ["-p", str(temp_param), "-P", "AUDIT"]
    else:
        cmd += [
            "-D", f'output_mode="{mode}"',
            "-D", 'validation_report="verbose"',
            "-D", f'system_contract_report="{"verbose" if verbose_contract else "summary"}"',
        ]
    for d in defines:
        cmd += ["-D", d]
    cmd += ["-o", str(out), str(scad)]
    proc = run_scad(cmd, cwd=str(scad.parent), capture_output=True, text=True)
    if temp_param:
        temp_param.unlink(missing_ok=True)
    return proc.returncode, (proc.stdout or "") + "\n" + (proc.stderr or ""), cmd


def _sample_arc(cx: float, cy: float, radius: float, a0: float, a1: float,
                max_seg: float = 0.5) -> list[tuple[float, float]]:
    sweep = a1 - a0
    if sweep <= 0:
        sweep += 360.0
    arc_len = math.radians(sweep) * radius
    n = max(8, int(math.ceil(arc_len / max_seg)))
    return [
        (cx + radius * math.cos(math.radians(a0 + sweep * i / n)),
         cy + radius * math.sin(math.radians(a0 + sweep * i / n)))
        for i in range(n + 1)
    ]


def dxf_segments(path: Path) -> list[tuple[tuple[float, float], tuple[float, float]]]:
    doc = ezdxf.readfile(path)
    segs: list[tuple[tuple[float, float], tuple[float, float]]] = []
    def consume(e):
        t=e.dxftype()
        if t=="LINE":
            a,b=e.dxf.start,e.dxf.end
            segs.append(((float(a.x),float(a.y)),(float(b.x),float(b.y))))
        elif t in {"LWPOLYLINE","POLYLINE"}:
            # virtual_entities preserves bulged arc segments; straight chords do not.
            for child in e.virtual_entities():consume(child)
        elif t in {"CIRCLE","ARC"}:
            c=e.dxf.center
            pts=_sample_arc(float(c.x),float(c.y),float(e.dxf.radius),
                0 if t=="CIRCLE" else float(e.dxf.start_angle),
                360 if t=="CIRCLE" else float(e.dxf.end_angle))
            segs.extend(zip(pts,pts[1:]))
        else:
            raise ValueError(f"Unsupported DXF entity {t}; refusing an incomplete contour audit")
    for e in doc.modelspace():consume(e)
    return segs


def _q(p: tuple[float, float], tol: float = 1e-5) -> tuple[int, int]:
    return (round(p[0] / tol), round(p[1] / tol))


def closed_loops_from_segments(segments: list[tuple[tuple[float, float], tuple[float, float]]],
                               tol: float = 1e-5) -> tuple[list[list[tuple[float, float]]], list[str]]:
    """Chain final OpenSCAD DXF contour segments into closed loops."""
    edges: list[tuple[tuple[int, int], tuple[int, int], tuple[float, float], tuple[float, float]]] = []
    adj: dict[tuple[int, int], list[int]] = defaultdict(list)
    for idx, (a, b) in enumerate(segments):
        qa, qb = _q(a, tol), _q(b, tol)
        if qa == qb:
            continue
        edge_idx = len(edges)
        edges.append((qa, qb, a, b))
        adj[qa].append(edge_idx)
        adj[qb].append(edge_idx)

    issues: list[str] = []
    for node, es in adj.items():
        if len(es) != 2:
            issues.append(f"contour node {node} has degree {len(es)} (expected 2)")

    used: set[int] = set()
    loops: list[list[tuple[float, float]]] = []
    for ei in range(len(edges)):
        if ei in used:
            continue
        qa, qb, a, b = edges[ei]
        start = qa
        current = qb
        coords = [a, b]
        used.add(ei)
        guard = 0
        while current != start and guard <= len(edges) + 2:
            guard += 1
            candidates = [x for x in adj.get(current, []) if x not in used]
            if not candidates:
                issues.append(f"open contour beginning near {coords[0]}")
                break
            ne = candidates[0]
            used.add(ne)
            nqa, nqb, na, nb = edges[ne]
            if nqa == current:
                current = nqb
                coords.append(nb)
            else:
                current = nqa
                coords.append(na)
        if current == start and len(coords) >= 4:
            coords[-1] = coords[0]
            loops.append(coords)
    return loops, issues


def _bounds_close(a: tuple[float, float, float, float],
                  b: tuple[float, float, float, float], tol: float = 0.05) -> bool:
    return all(abs(x - y) <= tol for x, y in zip(a, b))


def contour_polygons(path: Path, frame: dict[str, float] | None) -> tuple[list[Polygon], list[dict]]:
    segs = dxf_segments(path)
    loops, chain_issues = closed_loops_from_segments(segs)
    issues: list[dict] = [{"severity": "ERROR", "code": "OPEN_CONTOUR", "message": x} for x in chain_issues]
    polys: list[Polygon] = []
    for i, loop in enumerate(loops):
        p = Polygon(loop)
        if p.is_empty or p.area <= 1e-9:
            continue
        if not p.is_valid:
            issues.append({
                "severity": "ERROR", "code": "INVALID_CONTOUR",
                "message": f"{path.name} contour {i+1}: {explain_validity(p)}",
            })
            # Keep the original boundary out of downstream boolean checks to
            # avoid cascading GEOS errors.
            continue
        polys.append(p)

    if frame:
        outer = (frame["x0"], frame["y0"], frame["x1"], frame["y1"])
        fw = frame["fw"]
        inner = (outer[0] + fw, outer[1] + fw, outer[2] - fw, outer[3] - fw)
        polys = [p for p in polys if not (_bounds_close(p.bounds, outer) or _bounds_close(p.bounds, inner))]
    return polys, issues


def parity_geometry(polys: Iterable[Polygon]):
    geom = GeometryCollection()
    for p in polys:
        geom = geom.symmetric_difference(p)
    return geom


def outer_union(polys: list[Polygon]):
    outer: list[Polygon] = []
    for i, p in enumerate(polys):
        if not any(j != i and q.covers(p) and q.area > p.area + 1e-7 for j, q in enumerate(polys)):
            outer.append(p)
    return unary_union(outer) if outer else GeometryCollection()


def parse_frame(log: str) -> dict[str, float] | None:
    rows = parse_echo_payloads(log, "EXPORT_FRAME|")
    if not rows:
        return None
    r = parse_record(rows[0])
    try:
        return {k: float(r[k]) for k in ("x0", "y0", "x1", "y1", "fw")}
    except (KeyError, ValueError):
        return None


def run_audit(scad: Path, openscad: str = "openscad", param_json: Path | None = None,
              preset: str | None = None, defines: list[str] | None = None) -> dict:
    defines = defines or []
    audit_modes = ALL_MODES if "equipment_stand" in scad.name else [m for m in ALL_MODES if m != "pocket_slide_holes"]
    issues: list[dict] = []
    with tempfile.TemporaryDirectory(prefix="modular_organization_v5_audit_") as td:
        td = Path(td)
        meta_out = td / "metadata.csg"
        rc, meta_log, meta_cmd = run_openscad(
            scad, openscad, meta_out, "bom", defines, param_json, preset, True
        )
        meta_out.unlink(missing_ok=True)
        if rc != 0:
            return {
                "status": "ERROR",
                "scope": "audit_failed",
                "issues": [{"severity": "ERROR", "code": "OPENSCAD_METADATA_FAILED", "message": meta_log[-4000:]}],
                "coverage": {},
            }

        for payload in parse_echo_payloads(meta_log, "CHECK|"):
            f = payload.split("|", 3)
            if len(f) >= 4:
                issues.append({"severity": f[1], "code": f[2], "message": f[3], "source": "openscad"})

        frame = parse_frame(meta_log)
        if frame is None:
            issues.append({
                "severity": "ERROR", "code": "MISSING_EXPORT_FRAME",
                "message": "Metadata pass did not emit EXPORT_FRAME; registered whole-model contour comparison cannot be certified exhaustive.",
                "mode": "bom",
            })
        coverage_records = [parse_record(x) for x in parse_echo_payloads(meta_log, "COVERAGE|")]
        interfaces = [parse_record(x) for x in parse_echo_payloads(meta_log, "INTERFACE|")]
        features = [parse_record(x) for x in parse_echo_payloads(meta_log, "FEATURE|")]

        mode_stats: dict[str, dict] = {}
        geoms: dict[str, object] = {}
        raw_polys: dict[str, list[Polygon]] = {}
        mode_frames: dict[str, dict[str, float] | None] = {}
        all_modes_ok = True
        for mode in audit_modes:
            out = td / f"{mode}.dxf"
            rc, log, cmd = run_openscad(scad, openscad, out, mode, defines, param_json, preset, False)
            if rc != 0 or not out.exists():
                all_modes_ok = False
                issues.append({
                    "severity": "ERROR", "code": "OPENSCAD_MODE_FAILED",
                    "message": f"{mode} failed with return code {rc}: {log[-1200:]}",
                    "mode": mode,
                })
                continue
            # The registration/export frame can depend on the actual output
            # mode.  Parse it from the same OpenSCAD invocation rather than
            # assuming the BOM/metadata frame has identical extents.
            emitted_mode_frame = parse_frame(log)
            mode_frame = emitted_mode_frame or frame
            mode_frames[mode] = mode_frame
            if emitted_mode_frame is None:
                issues.append({
                    "severity": "ERROR", "code": "MISSING_MODE_EXPORT_FRAME",
                    "message": f"{mode} did not emit EXPORT_FRAME; mode registration cannot be independently verified.",
                    "mode": mode,
                })
            try:
                polys, pissues = contour_polygons(out, mode_frame)
            except (ValueError,ezdxf.DXFError) as exc:
                issues.append({'severity':'ERROR','code':'DXF_PARSE_FAILED','message':str(exc),'mode':mode})
                all_modes_ok=False
                continue
            for x in pissues:
                x["mode"] = mode
            issues.extend(pissues)
            raw_polys[mode] = polys
            geom = parity_geometry(polys)
            geoms[mode] = geom
            mode_stats[mode] = {
                "contours": len(polys),
                "filled_area_mm2": round(float(geom.area), 6),
                "valid": bool(geom.is_valid),
                "empty": bool(geom.is_empty),
            }
            if not geom.is_valid:
                issues.append({
                    "severity": "ERROR", "code": "INVALID_MODE_GEOMETRY",
                    "message": f"{mode} final parity geometry is invalid: {explain_validity(geom)}",
                    "mode": mode,
                })

        if 'cut_layout' not in geoms or geoms['cut_layout'].is_empty:
            issues.append({'severity':'ERROR','code':'EMPTY_CUT_LAYOUT','message':'No manufacturing part contours were emitted'})
        # Exhaustive cross-operation overlap scan across every pocket polygon.
        modes_present = [m for m in POCKET_MODES if m in geoms and not geoms[m].is_empty]
        for ii, a in enumerate(modes_present):
            for b in modes_present[ii + 1:]:
                inter = geoms[a].intersection(geoms[b])
                if inter.area <= 1e-6:
                    continue
                pair = frozenset((a, b))
                if pair in EXPECTED_POCKET_OVERLAPS:
                    sev, code = "INFO", "EXPECTED_POCKET_OPERATION_OVERLAP"
                elif "pocket_ganging" in pair:
                    # Ganging dowels are drilled from the outside face while
                    # several other side pockets are on the inside face. The
                    # 3D OpenSCAD ledger resolves actual depth intersection.
                    sev, code = "INFO", "PROJECTED_GANGING_POCKET_OVERLAP"
                else:
                    sev, code = "ERROR", "POCKET_OPERATION_COLLISION"
                issues.append({
                    "severity": sev, "code": code,
                    "message": f"{a} overlaps {b} by {inter.area:.3f} mm^2 in registered layout coordinates.",
                    "operations": [a, b], "area_mm2": float(inter.area),
                })

        # Compare every pocket operation with the complete through-cut void set.
        # Open-edge pocket extensions are tracked separately and are not assumed
        # to be errors because dados/grooves intentionally open at some edges.
        if "cut_layout" in geoms:
            cut_polys = raw_polys.get("cut_layout", [])
            cut_material = geoms["cut_layout"]
            cut_outer = outer_union(cut_polys)
            cut_voids = cut_outer.difference(cut_material)
            for mode in modes_present:
                g = geoms[mode]
                hit = g.intersection(cut_voids)
                if hit.area > 1e-6:
                    issues.append({
                        "severity": "ERROR", "code": "POCKET_THROUGH_CUT_COLLISION",
                        "message": f"{mode} intersects through-cut void geometry by {hit.area:.3f} mm^2.",
                        "operation": mode, "area_mm2": float(hit.area),
                    })
                outside = g.difference(cut_outer)
                if outside.area > 1e-6:
                    issues.append({
                        "severity": "INFO", "code": "OPEN_EDGE_POCKET_EXTENSION",
                        "message": f"{mode} extends {outside.area:.3f} mm^2 beyond part outer contours; open-edge pockets can be intentional.",
                        "operation": mode, "area_mm2": float(outside.area),
                    })

        errors = [x for x in issues if x.get("severity") == "ERROR"]
        warnings = [x for x in issues if x.get("severity") == "WARN"]
        status = "ERROR" if errors else "WARN" if warnings else "PASS"
        return {
            "contract": "MOI-4",
            "engine": "modular_organization_v5",
            "status": status,
            "scope_statement": (
                "Exhaustive for current MOI external-interface signatures, the complete outer cabinet-side machining ledger, "
                "and every contour emitted by CUT plus all registered POCKET manufacturing modes. "
                "It is not structural/load analysis and does not replace CAM/toolpath verification."
            ),
            "coverage": {
                "interface_contract_records": coverage_records,
                "external_interfaces_checked": len([x for x in interfaces if "external" in x.get("tags", "").split(";")]),
                "side_feature_records": len(features),
                "manufacturing_modes_expected": audit_modes,
                "manufacturing_modes_checked": [m for m in audit_modes if m in mode_stats],
                "all_manufacturing_modes_checked": all_modes_ok and len(mode_stats) == len(audit_modes),
                "registered_export_frame_detected": frame is not None,
                "registered_export_frame_detected_for_all_modes": all(
                    mode_frames.get(m) is not None for m in audit_modes if m in mode_stats
                ),
            },
            "mode_stats": mode_stats,
            "summary": {
                "errors": len(errors), "warnings": len(warnings),
                "info": len([x for x in issues if x.get("severity") == "INFO"]),
            },
            "issues": issues,
        }


def main(argv=None) -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("scad", type=Path)
    ap.add_argument("-o", "--output", type=Path, required=True)
    ap.add_argument("--openscad", default="openscad")
    ap.add_argument("--json", type=Path)
    ap.add_argument("--preset")
    ap.add_argument("--define", action="append", default=[])
    args = ap.parse_args(argv)
    if bool(args.json) != bool(args.preset):
        ap.error("--json and --preset must be supplied together")
    scad = args.scad.resolve()
    result = run_audit(scad, args.openscad, args.json, args.preset, args.define)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(result, indent=2), encoding="utf-8")
    print(f"{result['status']}: wrote {args.output}")
    print(json.dumps(result.get("summary", {}), sort_keys=True))
    return 2 if result["status"] == "ERROR" else 1 if result["status"] == "WARN" else 0


if __name__ == "__main__":
    raise SystemExit(main())
