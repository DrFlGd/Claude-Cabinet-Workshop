#!/usr/bin/env python3
"""Resolve Modular Organization v3 (.morg) composition graphs.

The project layer owns module identity, relationships, transforms, and project
state. OpenSCAD remains the geometry authority for generated modules: this tool
asks each OpenSCAD frontend for its MOI-3 contract, compares mating interfaces,
and resolves rigid module placement from interface frames.

V3 intentionally keeps automatic mating conservative: it resolves translation
and orthogonal Z rotations. Arbitrary 3-D rotation and a general constraint
solver are future contract extensions, not silently approximated here.
"""
from __future__ import annotations

import argparse
import copy
import json
import math
import re
import subprocess
import tempfile
from pathlib import Path
from typing import Any

PACKAGE_ROOT = Path(__file__).resolve().parent
CONTRACT = "MOI-3"
PROJECT_FORMAT = "MORG-1"
FRONTENDS = {
    "utility": ("modular_organization_utility_v3.scad", "modular_organization_utility_v3.json"),
    "shop_cart": ("modular_organization_shop_cart_v3.scad", "modular_organization_shop_cart_v3.json"),
    "benchtop": ("modular_organization_benchtop_v3.scad", "modular_organization_benchtop_v3.json"),
    "stackable": ("modular_organization_stackable_v3.scad", "modular_organization_stackable_v3.json"),
    "kitchen": ("modular_organization_kitchen_v3.scad", "modular_organization_kitchen_v3.json"),
    "drawer": ("modular_organization_drawer_v3.scad", "modular_organization_drawer_v3.json"),
}
ROLE_MATES = {("male", "female"), ("female", "male"), ("peer", "peer")}
EPS = 1e-5


def parse_echo_payloads(text: str, prefix: str) -> list[str]:
    pat = re.compile(r'^ECHO:\s+"(' + re.escape(prefix) + r'.*)"\s*$', re.M)
    return [m.group(1) for m in pat.finditer(text)]


def parse_record(payload: str) -> dict[str, str]:
    fields = payload.split("|")
    rec: dict[str, str] = {"record_type": fields[0] if fields else ""}
    extras = []
    for field in fields[1:]:
        if "=" in field:
            k, v = field.split("=", 1)
            rec[k.lower()] = v
        elif field:
            extras.append(field)
    if extras:
        rec["subtype"] = extras[0]
        if len(extras) > 1:
            rec["values"] = extras[1:]
    return rec


def fnum(v: Any) -> float:
    return float(v)


def vec(rec: dict[str, str], prefix: str) -> list[float]:
    return [fnum(rec[prefix + a]) for a in ("x", "y", "z")]


def vadd(a, b): return [a[i] + b[i] for i in range(3)]
def vsub(a, b): return [a[i] - b[i] for i in range(3)]
def vneg(a): return [-x for x in a]
def vdist(a, b): return math.sqrt(sum((a[i] - b[i]) ** 2 for i in range(3)))
def veq(a, b, tol=1e-4): return vdist(a, b) <= tol


def rz(v: list[float], deg: int) -> list[float]:
    d = deg % 360
    x, y, z = v
    if d == 0: return [x, y, z]
    if d == 90: return [-y, x, z]
    if d == 180: return [-x, -y, z]
    if d == 270: return [y, -x, z]
    raise ValueError("V3 resolver only accepts rotate_z values 0/90/180/270")


def transform_point(local: list[float], transform: dict[str, Any]) -> list[float]:
    return vadd(rz(local, int(transform.get("rotate_z", 0))), transform.get("translate", [0, 0, 0]))


def transform_vector(local: list[float], transform: dict[str, Any]) -> list[float]:
    return rz(local, int(transform.get("rotate_z", 0)))


def normalize_transform(value: dict[str, Any] | None) -> dict[str, Any]:
    value = value or {}
    t = value.get("translate", [0, 0, 0])
    if len(t) != 3:
        raise ValueError("transform.translate must contain three numbers")
    r = int(value.get("rotate_z", 0)) % 360
    if r not in (0, 90, 180, 270):
        raise ValueError("V3 transform.rotate_z must be 0, 90, 180, or 270 degrees")
    return {"translate": [float(x) for x in t], "rotate_z": r}


def param_value(v: Any) -> str:
    if isinstance(v, bool): return "true" if v else "false"
    if isinstance(v, (list, dict)): return json.dumps(v, separators=(",", ":"))
    return str(v)


def make_project_parameter_file(frontend: str, preset: str | None, overrides: dict[str, Any], dest: Path,
                                output_mode: str = "bom", report: str = "verbose") -> None:
    _, json_name = FRONTENDS[frontend]
    src = PACKAGE_ROOT / json_name
    data = json.loads(src.read_text(encoding="utf-8"))
    sets = data.setdefault("parameterSets", {})
    if preset:
        if preset not in sets:
            raise ValueError(f"Preset {preset!r} not found for frontend {frontend!r}")
        values = copy.deepcopy(sets[preset])
    else:
        values = {}
    for k, v in overrides.items():
        values[k] = param_value(v)
    values["output_mode"] = output_mode
    values["system_contract_report"] = report
    values["validation_report"] = "summary"
    values["dimension_report"] = "summary"
    data["parameterSets"] = {"Project": values}
    dest.write_text(json.dumps(data, indent=2), encoding="utf-8")


def run_scad_contract(module: dict[str, Any], openscad: str, work: Path) -> dict[str, Any]:
    frontend = module["frontend"]
    if frontend not in FRONTENDS:
        raise ValueError(f"Unknown frontend {frontend!r}")
    scad_name, _ = FRONTENDS[frontend]
    scad = PACKAGE_ROOT / scad_name
    params = work / f"{module['id']}_params.json"
    make_project_parameter_file(frontend, module.get("preset"), module.get("parameters", {}), params)
    out = work / f"{module['id']}_contract.csg"
    cmd = [openscad, "-p", str(params), "-P", "Project", "-o", str(out), str(scad)]
    proc = subprocess.run(cmd, cwd=PACKAGE_ROOT, capture_output=True, text=True)
    text = (proc.stdout or "") + "\n" + (proc.stderr or "")
    out.unlink(missing_ok=True)
    if proc.returncode != 0:
        raise RuntimeError(f"OpenSCAD contract pass failed for {module['id']}:\n{text[-5000:]}")
    systems = [parse_record(x) for x in parse_echo_payloads(text, "SYSTEM|")]
    module_records = [parse_record(x) for x in parse_echo_payloads(text, "MODULE|")]
    interfaces = [parse_record(x) for x in parse_echo_payloads(text, "INTERFACE|")]
    frames = [parse_record(x) for x in parse_echo_payloads(text, "INTERFACE_FRAME|")]
    checks = parse_echo_payloads(text, "CHECK|")
    if not systems or systems[0].get("contract") != CONTRACT:
        raise RuntimeError(f"{module['id']} did not emit a {CONTRACT} system contract")
    if not module_records:
        raise RuntimeError(f"{module['id']} did not emit a MODULE record")
    mr = module_records[0]
    frame_map = {}
    for r in frames:
        frame_map[r["id"]] = {
            "origin": vec(r, "o"), "u": vec(r, "u"), "v": vec(r, "v"), "n": vec(r, "n")
        }
    interface_map = {r["id"]: r for r in interfaces}
    return {
        "source": {"frontend": frontend, "scad": scad_name, "preset": module.get("preset")},
        "kind": mr.get("kind", module.get("kind", "module")),
        "size": [fnum(mr["w"]), fnum(mr["d"]), fnum(mr["h"])],
        "interfaces": interface_map,
        "frames": frame_map,
        "checks": checks,
        "console": text,
        "parameter_file": params,
    }


def compatible(a: dict[str, str], b: dict[str, str]) -> tuple[bool, list[str]]:
    reasons = []
    if a.get("standard") != b.get("standard"):
        reasons.append(f"standard differs ({a.get('standard')} vs {b.get('standard')})")
    if (a.get("role"), b.get("role")) not in ROLE_MATES:
        reasons.append(f"roles do not mate ({a.get('role')} vs {b.get('role')})")
    if a.get("key") != b.get("key"):
        reasons.append("compatibility geometry key differs")
    return not reasons, reasons


def candidate_mate_transform(parent_frame: dict[str, list[float]], parent_tf: dict[str, Any],
                             child_frame: dict[str, list[float]], preferred_rotation: int | None = None) -> dict[str, Any]:
    po = transform_point(parent_frame["origin"], parent_tf)
    pu = transform_vector(parent_frame["u"], parent_tf)
    pv = transform_vector(parent_frame["v"], parent_tf)
    pn = transform_vector(parent_frame["n"], parent_tf)
    rotations = [preferred_rotation % 360] if preferred_rotation is not None else [0, 90, 180, 270]
    for r in rotations:
        cu, cv, cn = rz(child_frame["u"], r), rz(child_frame["v"], r), rz(child_frame["n"], r)
        if veq(cu, pu) and veq(cv, pv) and veq(cn, vneg(pn)):
            co = rz(child_frame["origin"], r)
            return {"translate": vsub(po, co), "rotate_z": r}
    raise ValueError("interface frames cannot mate using the V3 orthogonal-Z resolver")


def verify_mate(frame_a, tf_a, frame_b, tf_b) -> list[str]:
    errors = []
    ao, bo = transform_point(frame_a["origin"], tf_a), transform_point(frame_b["origin"], tf_b)
    if not veq(ao, bo, 0.05): errors.append(f"interface origins differ by {vdist(ao, bo):.3f} mm")
    au, av, an = (transform_vector(frame_a[k], tf_a) for k in ("u", "v", "n"))
    bu, bv, bn = (transform_vector(frame_b[k], tf_b) for k in ("u", "v", "n"))
    if not veq(au, bu): errors.append("interface U axes are not aligned")
    if not veq(av, bv): errors.append("interface V axes are not aligned")
    if not veq(an, vneg(bn)): errors.append("interface outward normals are not opposed")
    return errors


def world_aabb(size: list[float], tf: dict[str, Any]) -> list[float]:
    w, d, h = size
    pts = [transform_point([x, y, z], tf) for x in (0, w) for y in (0, d) for z in (0, h)]
    return [min(p[i] for p in pts) for i in range(3)] + [max(p[i] for p in pts) for i in range(3)]


def aabb_overlap(a, b, tol=0.01):
    return [min(a[i + 3], b[i + 3]) - max(a[i], b[i]) for i in range(3)]


def validate_project_shape(project: dict[str, Any]) -> list[dict[str, str]]:
    problems = []
    if project.get("project_format") != PROJECT_FORMAT:
        problems.append({"severity": "ERROR", "code": "PROJECT_FORMAT", "message": f"project_format must be {PROJECT_FORMAT}"})
    ids = [m.get("id") for m in project.get("modules", [])]
    if None in ids or len(set(ids)) != len(ids):
        problems.append({"severity": "ERROR", "code": "MODULE_IDS", "message": "module ids must be present and unique"})
    return problems


def resolve_project(project: dict[str, Any], openscad: str, work: Path) -> dict[str, Any]:
    health = validate_project_shape(project)
    modules: dict[str, dict[str, Any]] = {m["id"]: copy.deepcopy(m) for m in project.get("modules", []) if m.get("id")}
    meta: dict[str, dict[str, Any]] = {}
    transforms: dict[str, dict[str, Any]] = {}

    for mid, m in modules.items():
        typ = m.get("type", "openscad")
        if typ == "openscad":
            try:
                meta[mid] = run_scad_contract(m, openscad, work)
            except Exception as exc:
                health.append({"severity": "ERROR", "code": "MODULE_CONTRACT", "module": mid, "message": str(exc)})
        elif typ == "box":
            size = [float(x) for x in m.get("size", [])]
            if len(size) != 3 or min(size) <= 0:
                health.append({"severity": "ERROR", "code": "BOX_SIZE", "module": mid, "message": "box module requires positive [W,D,H] size"})
                continue
            iface_map, frames = {}, {}
            for r in m.get("interfaces", []):
                iface_map[r["id"]] = {str(k).lower(): str(v) for k, v in r.items() if k != "frame"}
                fr = r.get("frame")
                if fr:
                    frames[r["id"]] = {k: [float(x) for x in fr[k]] for k in ("origin", "u", "v", "n")}
            meta[mid] = {"kind": m.get("kind", "box"), "size": size, "interfaces": iface_map, "frames": frames, "checks": []}
        elif typ == "span_worktop":
            # Deferred until support transforms are known.
            continue
        else:
            health.append({"severity": "ERROR", "code": "MODULE_TYPE", "module": mid, "message": f"unknown module type {typ!r}"})
        if mid in meta:
            for payload in meta[mid].get("checks", []):
                fields = payload.split("|", 3)
                sev = fields[1] if len(fields) > 1 else "INFO"
                code = fields[2] if len(fields) > 2 else "OPENSCAD_CHECK"
                msg = fields[3] if len(fields) > 3 else payload
                health.append({"severity": sev, "code": code, "module": mid, "message": msg})
        if "transform" in m:
            try: transforms[mid] = normalize_transform(m["transform"])
            except Exception as exc: health.append({"severity": "ERROR", "code": "TRANSFORM", "module": mid, "message": str(exc)})

    # Anchor the first normal module if no explicit anchor is supplied.
    if not transforms:
        for mid in modules:
            if mid in meta:
                transforms[mid] = {"translate": [0.0, 0.0, 0.0], "rotate_z": 0}
                health.append({"severity": "INFO", "code": "AUTO_ROOT", "module": mid, "message": "first resolvable module anchored at project origin"})
                break

    relationships = project.get("relationships", [])
    # Rigid mates and containment offsets are solved iteratively.
    progress = True
    for _ in range(max(1, len(modules) * 3)):
        if not progress: break
        progress = False
        for rel in relationships:
            if rel.get("_invalid"):
                continue
            typ = rel.get("type")
            if typ == "mate":
                a, b = rel.get("a", {}), rel.get("b", {})
                ma, mb = a.get("module"), b.get("module")
                ia, ib = a.get("interface"), b.get("interface")
                if ma not in meta or mb not in meta: continue
                ra, rb = meta[ma]["interfaces"].get(ia), meta[mb]["interfaces"].get(ib)
                fa, fb = meta[ma]["frames"].get(ia), meta[mb]["frames"].get(ib)
                if not ra or not rb:
                    health.append({"severity": "ERROR", "code": "INTERFACE_MISSING", "relationship": rel.get("id"), "message": f"missing {ma}.{ia} or {mb}.{ib}"})
                    rel["_invalid"] = True; continue
                ok, reasons = compatible(ra, rb)
                if not ok:
                    health.append({"severity": "ERROR", "code": "INTERFACE_INCOMPATIBLE", "relationship": rel.get("id"), "message": "; ".join(reasons)})
                    rel["_invalid"] = True; continue
                if not fa or not fb:
                    health.append({"severity": "ERROR", "code": "INTERFACE_FRAME_MISSING", "relationship": rel.get("id"), "message": "external mate requires INTERFACE_FRAME records"})
                    rel["_invalid"] = True; continue
                if ma in transforms and mb not in transforms:
                    try:
                        pref = modules[mb].get("preferred_rotate_z")
                        transforms[mb] = candidate_mate_transform(fa, transforms[ma], fb, pref)
                        progress = True
                    except Exception as exc:
                        health.append({"severity": "ERROR", "code": "MATE_RESOLVE", "relationship": rel.get("id"), "message": str(exc)}); rel["_invalid"] = True
                elif mb in transforms and ma not in transforms:
                    try:
                        pref = modules[ma].get("preferred_rotate_z")
                        transforms[ma] = candidate_mate_transform(fb, transforms[mb], fa, pref)
                        progress = True
                    except Exception as exc:
                        health.append({"severity": "ERROR", "code": "MATE_RESOLVE", "relationship": rel.get("id"), "message": str(exc)}); rel["_invalid"] = True
            elif typ == "contains":
                parent, child = rel.get("parent"), rel.get("child")
                if parent in transforms and child in meta and child not in transforms:
                    off = [float(x) for x in rel.get("offset", [0, 0, 0])]
                    parent_tf = transforms[parent]
                    local = rz(off, parent_tf["rotate_z"])
                    transforms[child] = {
                        "translate": vadd(parent_tf["translate"], local),
                        "rotate_z": (parent_tf["rotate_z"] + int(rel.get("rotate_z", 0))) % 360,
                    }
                    progress = True

    # Span worktops are derived after support modules are positioned.
    for mid, m in modules.items():
        if m.get("type") != "span_worktop": continue
        supports = m.get("supports", [])
        if not supports or any(s not in meta or s not in transforms for s in supports):
            health.append({"severity": "ERROR", "code": "SPAN_SUPPORT", "module": mid, "message": "all span_worktop supports must be resolved modules"})
            continue
        boxes = [world_aabb(meta[s]["size"], transforms[s]) for s in supports]
        tops = [b[5] for b in boxes]
        tol = float(m.get("support_height_tolerance", 0.5))
        if max(tops) - min(tops) > tol:
            health.append({"severity": "ERROR", "code": "SPAN_HEIGHT_MISMATCH", "module": mid, "message": f"support tops differ by {max(tops)-min(tops):.3f} mm"})
            continue
        ov = m.get("overhang", {})
        x0 = min(b[0] for b in boxes) - float(ov.get("left", 0))
        x1 = max(b[3] for b in boxes) + float(ov.get("right", 0))
        y0 = min(b[1] for b in boxes) - float(ov.get("front", 0))
        y1 = max(b[4] for b in boxes) + float(ov.get("back", 0))
        z0 = max(tops) + float(m.get("gap", 0))
        th = float(m.get("thickness", 25))
        meta[mid] = {"kind": "worktop", "size": [x1-x0, y1-y0, th], "interfaces": {}, "frames": {}, "checks": []}
        transforms[mid] = {"translate": [x0, y0, z0], "rotate_z": 0}

    # Verify every mate after graph resolution.
    for rel in relationships:
        if rel.get("type") != "mate" or rel.get("_invalid"): continue
        a, b = rel.get("a", {}), rel.get("b", {})
        ma, mb, ia, ib = a.get("module"), b.get("module"), a.get("interface"), b.get("interface")
        if ma not in transforms or mb not in transforms or ma not in meta or mb not in meta: continue
        errs = verify_mate(meta[ma]["frames"][ia], transforms[ma], meta[mb]["frames"][ib], transforms[mb])
        for e in errs:
            health.append({"severity": "ERROR", "code": "MATE_ALIGNMENT", "relationship": rel.get("id"), "message": e})

    for mid in modules:
        if mid not in transforms or mid not in meta:
            health.append({"severity": "ERROR", "code": "MODULE_UNRESOLVED", "module": mid, "message": "module could not be placed/resolved"})

    # Conservative assembly AABB collision pass. Containment pairs intentionally
    # overlap and are exempt; mating surfaces that merely touch have zero overlap.
    contains_pairs = {frozenset((r.get("parent"), r.get("child"))) for r in relationships if r.get("type") == "contains"}
    resolved_ids = [m for m in modules if m in meta and m in transforms]
    boxes = {m: world_aabb(meta[m]["size"], transforms[m]) for m in resolved_ids}
    for i, a in enumerate(resolved_ids):
        for b in resolved_ids[i+1:]:
            if frozenset((a, b)) in contains_pairs: continue
            ov = aabb_overlap(boxes[a], boxes[b])
            if min(ov) > 0.05:
                health.append({"severity": "ERROR", "code": "MODULE_AABB_COLLISION", "modules": [a,b], "message": f"module envelopes overlap by {ov[0]:.2f} x {ov[1]:.2f} x {ov[2]:.2f} mm"})

    resolved_modules = []
    for mid, m in modules.items():
        if mid not in meta or mid not in transforms: continue
        resolved_modules.append({
            "id": mid, "type": m.get("type", "openscad"), "kind": meta[mid]["kind"],
            "size": meta[mid]["size"], "transform": transforms[mid],
            "aabb": boxes.get(mid, world_aabb(meta[mid]["size"], transforms[mid])),
            "source": meta[mid].get("source"),
            "interfaces": list(meta[mid].get("interfaces", {}).values()),
        })

    errors = sum(1 for h in health if h["severity"] == "ERROR")
    warnings = sum(1 for h in health if h["severity"] == "WARN")
    return {
        "project_format": PROJECT_FORMAT,
        "contract": CONTRACT,
        "name": project.get("name", "Untitled Modular Organization Project"),
        "status": "ERROR" if errors else "WARN" if warnings else "PASS",
        "summary": {"errors": errors, "warnings": warnings, "info": sum(1 for h in health if h["severity"] == "INFO")},
        "coverage": {
            "project_graph": "complete_for_v3_relationship_types",
            "rigid_mating": "orthogonal_z_rotation_and_translation",
            "module_geometry": "OpenSCAD-authoritative semantic/interface checks are included",
            "manufacturing_geometry": "run modular_organization_validate.py or the manufacturing exporter per OpenSCAD module for exhaustive CUT/POCKET contour audit",
            "project_collision": "conservative module AABB",
            "not_claimed": ["arbitrary 3-D rotation", "general constraint solving", "structural/load analysis", "motion-envelope validation"],
        },
        "modules": resolved_modules,
        "relationships": [{k:v for k,v in r.items() if not k.startswith("_")} for r in relationships],
        "health": health,
    }


def scad_matrix(tf: dict[str, Any]) -> list[list[float]]:
    r = tf["rotate_z"] % 360
    c, s = {0:(1,0), 90:(0,1), 180:(-1,0), 270:(0,-1)}[r]
    x, y, z = tf["translate"]
    return [[c,-s,0,x],[s,c,0,y],[0,0,1,z],[0,0,0,1]]


def matrix_literal(m):
    return "[" + ",".join("[" + ",".join(f"{v:.9g}" for v in row) + "]" for row in m) + "]"


def render_module(module: dict[str, Any], resolved: dict[str, Any], openscad: str, work: Path, dest: Path) -> None:
    typ = module.get("type", "openscad")
    if typ == "openscad":
        frontend = module["frontend"]
        scad_name, _ = FRONTENDS[frontend]
        params = work / f"{module['id']}_render_params.json"
        make_project_parameter_file(frontend, module.get("preset"), module.get("parameters", {}), params,
                                    output_mode="assembly", report="off")
        cmd = [openscad, "-p", str(params), "-P", "Project", "-o", str(dest), str(PACKAGE_ROOT/scad_name)]
        proc = subprocess.run(cmd, cwd=PACKAGE_ROOT, capture_output=True, text=True)
        if proc.returncode != 0:
            raise RuntimeError(f"render failed for {module['id']}:\n{((proc.stdout or '')+(proc.stderr or ''))[-5000:]}")
    else:
        rm = next(x for x in resolved["modules"] if x["id"] == module["id"])
        w,d,h = rm["size"]
        src = work / f"{module['id']}_box.scad"
        src.write_text(f"cube([{w},{d},{h}], center=false);\n", encoding="utf-8")
        proc = subprocess.run([openscad, "-o", str(dest), str(src)], capture_output=True, text=True)
        if proc.returncode != 0:
            raise RuntimeError(f"render failed for {module['id']}: {proc.stderr[-3000:]}")


def write_assembly(project: dict[str, Any], resolved: dict[str, Any], output_dir: Path, openscad: str, render: bool) -> None:
    module_specs = {m["id"]: m for m in project["modules"]}
    parts = output_dir / "MODULES"
    parts.mkdir(parents=True, exist_ok=True)
    lines = ["// Generated by Modular Organization v3 project resolver.", "$fn=48;"]
    if render:
        with tempfile.TemporaryDirectory(prefix="morg_v3_render_") as td:
            work = Path(td)
            for rm in resolved["modules"]:
                mid = rm["id"]
                stl = parts / f"{mid}.stl"
                render_module(module_specs[mid], resolved, openscad, work, stl)
                lines.append(f'multmatrix({matrix_literal(scad_matrix(rm["transform"]))}) import("MODULES/{mid}.stl");')
    else:
        for rm in resolved["modules"]:
            w,d,h = rm["size"]
            lines.append(f'multmatrix({matrix_literal(scad_matrix(rm["transform"]))}) cube([{w},{d},{h}], center=false);')
    assembly = output_dir / "assembly_preview.scad"
    assembly.write_text("\n".join(lines)+"\n", encoding="utf-8")
    if render:
        out = output_dir / "assembly_preview.stl"
        proc = subprocess.run([openscad, "-o", str(out), str(assembly)], cwd=output_dir, capture_output=True, text=True)
        if proc.returncode != 0:
            raise RuntimeError(f"assembly preview render failed:\n{proc.stderr[-5000:]}")


def main() -> int:
    ap = argparse.ArgumentParser(description="Resolve a Modular Organization MORG-1 project graph")
    ap.add_argument("project", type=Path)
    ap.add_argument("-o", "--output-dir", type=Path, required=True)
    ap.add_argument("--openscad", default="openscad")
    ap.add_argument("--render-modules", action="store_true", help="render true OpenSCAD module STLs and combined assembly preview")
    ap.add_argument("--allow-errors", action="store_true", help="write outputs even if project validation reports errors")
    args = ap.parse_args()
    project = json.loads(args.project.read_text(encoding="utf-8"))
    args.output_dir.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="morg_v3_contract_") as td:
        resolved = resolve_project(project, args.openscad, Path(td))
    (args.output_dir/"resolved_project.json").write_text(json.dumps(resolved, indent=2), encoding="utf-8")
    (args.output_dir/"project_health.json").write_text(json.dumps({
        "status": resolved["status"], "summary": resolved["summary"], "coverage": resolved["coverage"], "health": resolved["health"]
    }, indent=2), encoding="utf-8")
    if resolved["status"] == "ERROR" and not args.allow_errors:
        print(json.dumps(resolved["summary"]))
        for h in resolved["health"]:
            if h["severity"] == "ERROR": print(f"ERROR {h['code']}: {h['message']}")
        return 2
    write_assembly(project, resolved, args.output_dir, args.openscad, args.render_modules)
    print(f"{resolved['status']}: {resolved['name']} -> {args.output_dir}")
    return 0 if resolved["status"] != "ERROR" else 2


if __name__ == "__main__":
    raise SystemExit(main())
