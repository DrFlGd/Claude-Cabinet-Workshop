#!/usr/bin/env python3
"""Conservative multi-sheet nesting planner for Modular Organization v3 BOMs.

This planner uses each part's BOM cut bounding rectangle.  It is safe for sheet
count/material planning and produces machine-readable placements plus an SVG
preview.  It does NOT contour-nest irregular profiles; production CUT geometry
still comes from the OpenSCAD exports.
"""
from __future__ import annotations

import argparse
import csv
import json
from dataclasses import dataclass, asdict
from pathlib import Path
from typing import Iterable


@dataclass
class Part:
    id: str
    material: str
    thickness: float
    width: float
    height: float
    category: str = ""
    notes: str = ""
    grain_locked: bool = False


@dataclass
class Rect:
    x: float
    y: float
    w: float
    h: float


@dataclass
class Placement:
    part_id: str
    x: float
    y: float
    width: float
    height: float
    rotated: bool
    source_width: float
    source_height: float
    category: str
    notes: str


@dataclass
class Sheet:
    material: str
    thickness: float
    index: int
    width: float
    height: float
    margin: float
    placements: list[Placement]
    free: list[Rect]


def _intersects(a: Rect, b: Rect) -> bool:
    return not (b.x >= a.x+a.w or b.x+b.w <= a.x or b.y >= a.y+a.h or b.y+b.h <= a.y)


def _contains(a: Rect, b: Rect, eps: float = 1e-7) -> bool:
    return (b.x >= a.x-eps and b.y >= a.y-eps
            and b.x+b.w <= a.x+a.w+eps and b.y+b.h <= a.y+a.h+eps)


def _split_free_rectangles(free: list[Rect], used: Rect) -> list[Rect]:
    out: list[Rect] = []
    for f in free:
        if not _intersects(f, used):
            out.append(f)
            continue
        # Regions left/right of used rectangle.
        if used.x > f.x:
            out.append(Rect(f.x, f.y, used.x-f.x, f.h))
        if used.x+used.w < f.x+f.w:
            out.append(Rect(used.x+used.w, f.y, f.x+f.w-(used.x+used.w), f.h))
        # Regions above/below. These intentionally span the original width;
        # contained rectangles are pruned below.
        if used.y > f.y:
            out.append(Rect(f.x, f.y, f.w, used.y-f.y))
        if used.y+used.h < f.y+f.h:
            out.append(Rect(f.x, used.y+used.h, f.w, f.y+f.h-(used.y+used.h)))

    out = [r for r in out if r.w > 1e-6 and r.h > 1e-6]
    pruned: list[Rect] = []
    for i, r in enumerate(out):
        if any(i != j and _contains(other, r) for j, other in enumerate(out)):
            continue
        pruned.append(r)
    return pruned


def _best_fit(sheet: Sheet, part: Part, gap: float, allow_rotation: bool):
    best = None
    orientations = [(part.width, part.height, False)]
    if allow_rotation and not part.grain_locked and abs(part.width-part.height) > 1e-7:
        orientations.append((part.height, part.width, True))

    for fi, f in enumerate(sheet.free):
        for w, h, rotated in orientations:
            pw, ph = w+gap, h+gap
            if pw <= f.w+1e-7 and ph <= f.h+1e-7:
                leftover_w = f.w-pw
                leftover_h = f.h-ph
                score = (min(leftover_w,leftover_h), max(leftover_w,leftover_h), f.y, f.x)
                candidate = (score, fi, f, w, h, pw, ph, rotated)
                if best is None or score < best[0]:
                    best = candidate
    return best


def nest_parts(parts: Iterable[Part], sheet_width: float = 2440,
               sheet_height: float = 1220, margin: float = 10,
               gap: float = 6.35, allow_rotation: bool = True):
    groups: dict[tuple[str,float], list[Part]] = {}
    for p in parts:
        groups.setdefault((p.material, p.thickness), []).append(p)

    all_sheets: list[Sheet] = []
    oversized: list[dict] = []
    for (material, thickness), group in sorted(groups.items()):
        # Large/awkward parts first improves MaxRects-style packing.
        group.sort(key=lambda p: (max(p.width,p.height), p.width*p.height), reverse=True)
        sheets: list[Sheet] = []
        for part in group:
            candidates = []
            for si, sh in enumerate(sheets):
                bf = _best_fit(sh, part, gap, allow_rotation)
                if bf is not None:
                    candidates.append((bf[0], si, bf))
            if candidates:
                _, si, bf = min(candidates, key=lambda x: x[0])
                sh = sheets[si]
            else:
                usable_w = sheet_width - 2*margin
                usable_h = sheet_height - 2*margin
                probe = Sheet(material, thickness, len(sheets)+1, sheet_width,
                              sheet_height, margin, [],
                              [Rect(margin, margin, usable_w, usable_h)])
                bf = _best_fit(probe, part, gap, allow_rotation)
                if bf is None:
                    oversized.append({
                        "id": part.id, "material": material,
                        "thickness_mm": thickness,
                        "width_mm": part.width, "height_mm": part.height,
                    })
                    continue
                sheets.append(probe)
                sh = probe

            _, fi, free_rect, w, h, pw, ph, rotated = bf
            used = Rect(free_rect.x, free_rect.y, pw, ph)
            sh.placements.append(Placement(
                part.id, used.x, used.y, w, h, rotated,
                part.width, part.height, part.category, part.notes,
            ))
            sh.free = _split_free_rectangles(sh.free, used)
        all_sheets.extend(sheets)

    return all_sheets, oversized


def rows_to_parts(rows: Iterable[dict], grain_locked_materials: set[str] | None = None):
    locked = {x.upper() for x in (grain_locked_materials or set())}
    out: list[Part] = []
    for row in rows:
        try:
            qty = max(1, int(float(row.get("QTY", 1) or 1)))
            w = float(row["CUT_W_MM"])
            h = float(row["CUT_H_MM"])
            t = float(row["THICKNESS_MM"])
        except (KeyError, ValueError, TypeError):
            continue
        material = (row.get("MATERIAL") or "UNSPECIFIED").strip()
        for q in range(qty):
            pid = row.get("ID", "PART")
            if qty > 1:
                pid = f"{pid}#{q+1}"
            out.append(Part(
                id=pid, material=material, thickness=t,
                width=w, height=h,
                category=row.get("CATEGORY", ""), notes=row.get("NOTES", ""),
                grain_locked=material.upper() in locked,
            ))
    return out


def plan_dict(sheets: list[Sheet], oversized: list[dict]):
    grouped: dict[str, dict] = {}
    for sh in sheets:
        key=f"{sh.material}|{sh.thickness:g}"
        g=grouped.setdefault(key, {
            "material": sh.material,
            "thickness_mm": sh.thickness,
            "sheet_count": 0,
            "part_area_mm2": 0.0,
            "sheet_area_mm2": 0.0,
            "sheets": [],
        })
        area=sum(p.width*p.height for p in sh.placements)
        g["sheet_count"] += 1
        g["part_area_mm2"] += area
        g["sheet_area_mm2"] += sh.width*sh.height
        g["sheets"].append({
            "sheet": sh.index, "width_mm": sh.width, "height_mm": sh.height,
            "margin_mm": sh.margin,
            "placements": [asdict(p) for p in sh.placements],
        })
    for g in grouped.values():
        g["utilization_percent"] = round(
            100*g["part_area_mm2"]/g["sheet_area_mm2"], 2
        ) if g["sheet_area_mm2"] else 0
        g["part_area_mm2"] = round(g["part_area_mm2"],2)
        g["sheet_area_mm2"] = round(g["sheet_area_mm2"],2)
    return {
        "nest_type": "bounding_rectangle",
        "production_note": (
            "Placements use BOM cut bounding rectangles. Use the exported CUT geometry "
            "for machining; irregular-profile contour nesting is not performed."
        ),
        "groups": list(grouped.values()),
        "oversized": oversized,
    }


def write_preview_svg(plan: dict, path: Path):
    groups=plan["groups"]
    sheet_records=[]
    for g in groups:
        for sh in g["sheets"]:
            sheet_records.append((g,sh))
    if not sheet_records:
        path.write_text('<svg xmlns="http://www.w3.org/2000/svg" width="600" height="80"><text x="10" y="30">No nestable BOM rectangles.</text></svg>')
        return

    page_w=1000.0
    gap_px=70
    rendered=[]
    y=40.0
    for g,sh in sheet_records:
        scale=min(0.34, (page_w-80)/sh["width_mm"])
        w=sh["width_mm"]*scale
        h=sh["height_mm"]*scale
        rendered.append((g,sh,scale,40,y,w,h))
        y += h+gap_px
    total_h=y+30
    esc=lambda x: str(x).replace('&','&amp;').replace('<','&lt;').replace('>','&gt;')
    out=[f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {page_w:g} {total_h:g}">',
         '<style>text{font-family:Arial,sans-serif;fill:#111}.sheet{fill:none;stroke:#111;stroke-width:1}.part{fill:none;stroke:#555;stroke-width:.8}.small{font-size:11px}.title{font-size:15px;font-weight:bold}</style>']
    for g,sh,scale,x0,y0,w,h in rendered:
        out.append(f'<text class="title" x="{x0:g}" y="{y0-10:g}">{esc(g["material"])} — {g["thickness_mm"]:g} mm — sheet {sh["sheet"]}</text>')
        out.append(f'<rect class="sheet" x="{x0:g}" y="{y0:g}" width="{w:g}" height="{h:g}"/>')
        for p in sh["placements"]:
            x=x0+p["x"]*scale; yy=y0+p["y"]*scale
            pw=p["width"]*scale; ph=p["height"]*scale
            out.append(f'<rect class="part" x="{x:g}" y="{yy:g}" width="{pw:g}" height="{ph:g}"/>')
            if pw>28 and ph>14:
                label=esc(p["part_id"])+( ' ↻' if p["rotated"] else '')
                out.append(f'<text class="small" x="{x+3:g}" y="{yy+13:g}">{label}</text>')
    out.append('</svg>')
    path.write_text('\n'.join(out), encoding='utf-8')


def main() -> int:
    ap=argparse.ArgumentParser()
    ap.add_argument('bom_csv', type=Path)
    ap.add_argument('-o','--output-json', type=Path, required=True)
    ap.add_argument('--preview-svg', type=Path)
    ap.add_argument('--sheet-width', type=float, default=2440)
    ap.add_argument('--sheet-height', type=float, default=1220)
    ap.add_argument('--margin', type=float, default=10)
    ap.add_argument('--gap', type=float, default=6.35)
    ap.add_argument('--no-rotate', action='store_true')
    ap.add_argument('--grain-lock', action='append', default=[], metavar='MATERIAL')
    args=ap.parse_args()

    with args.bom_csv.open(newline='',encoding='utf-8') as fh:
        rows=list(csv.DictReader(fh))
    parts=rows_to_parts(rows,set(args.grain_lock))
    sheets,oversized=nest_parts(parts,args.sheet_width,args.sheet_height,
                                 args.margin,args.gap,not args.no_rotate)
    plan=plan_dict(sheets,oversized)
    plan['settings']={
        'sheet_width_mm':args.sheet_width,'sheet_height_mm':args.sheet_height,
        'margin_mm':args.margin,'part_gap_mm':args.gap,
        'rotation_enabled':not args.no_rotate,
        'grain_locked_materials':args.grain_lock,
    }
    args.output_json.parent.mkdir(parents=True,exist_ok=True)
    args.output_json.write_text(json.dumps(plan,indent=2),encoding='utf-8')
    if args.preview_svg:
        args.preview_svg.parent.mkdir(parents=True,exist_ok=True)
        write_preview_svg(plan,args.preview_svg)
    print(f"Wrote {args.output_json}; {len(sheets)} sheets, {len(oversized)} oversized parts")
    return 0


if __name__=='__main__':
    raise SystemExit(main())
