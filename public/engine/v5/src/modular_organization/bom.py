#!/usr/bin/env python3
"""
Export the cabinet generator's OpenSCAD BOM echo stream to CSV.

Examples:

  python export_cabinet_bom.py parametric_utility_cabinet_v43.scad -o bom.csv

  python export_cabinet_bom.py parametric_utility_cabinet_v43.scad \
      --json my_config.json --preset "New set 1" -o bom.csv

  python export_cabinet_bom.py parametric_utility_cabinet_v43.scad \
      --define 'cabinet_layout_mode="mixed_bays"' \
      --define 'mixed_bay_count=3' \
      --aggregate \
      -o bom_grouped.csv
"""

from __future__ import annotations

import argparse
import csv
from .runtime import run_scad
import sys
import tempfile
from collections import OrderedDict
from pathlib import Path


COLUMNS = [
    "ID",
    "QTY",
    "CATEGORY",
    "MATERIAL",
    "THICKNESS_MM",
    "CUT_W_MM",
    "CUT_H_MM",
    "NOTES",
]


def parse_bom_lines(text: str) -> list[dict[str, str]]:
    rows: list[dict[str, str]] = []

    for line in text.splitlines():
        marker = 'ECHO: "BOM|'
        if marker not in line:
            continue

        payload = line.split('ECHO: "', 1)[1]
        if payload.endswith('"'):
            payload = payload[:-1]

        fields = payload.split("|")
        if not fields or fields[0] != "BOM":
            continue

        values = fields[1:]
        if len(values) < len(COLUMNS):
            values += [""] * (len(COLUMNS) - len(values))
        elif len(values) > len(COLUMNS):
            # NOTES should be the only free-form trailing field.
            values = values[: len(COLUMNS)-1] + [
                "|".join(values[len(COLUMNS)-1:])
            ]

        rows.append(dict(zip(COLUMNS, values)))

    return rows


def aggregate_rows(rows: list[dict[str, str]]) -> list[dict[str, str]]:
    keys = [
        "CATEGORY",
        "MATERIAL",
        "THICKNESS_MM",
        "CUT_W_MM",
        "CUT_H_MM",
        "NOTES",
    ]

    grouped: OrderedDict[tuple[str, ...], dict[str, object]] = OrderedDict()

    for row in rows:
        key = tuple(row[k] for k in keys)
        if key not in grouped:
            grouped[key] = {
                "ids": [],
                "qty": 0,
                "row": row.copy(),
            }

        grouped[key]["ids"].append(row["ID"])
        grouped[key]["qty"] += int(float(row.get("QTY", "1") or "1"))

    out: list[dict[str, str]] = []
    for data in grouped.values():
        row = dict(data["row"])
        row["ID"] = ", ".join(data["ids"])
        row["QTY"] = str(data["qty"])
        out.append(row)

    return out


def main(argv=None) -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("scad", type=Path, help="Cabinet entry-point .scad file")
    ap.add_argument("-o", "--output", type=Path, required=True,
                    help="Destination CSV")
    ap.add_argument("--openscad", default="openscad",
                    help="OpenSCAD executable (default: openscad)")
    ap.add_argument("--json", type=Path,
                    help="Optional OpenSCAD parameter-set JSON")
    ap.add_argument("--preset",
                    help="Parameter-set name used with --json")
    ap.add_argument("--define", action="append", default=[],
                    help="Additional OpenSCAD -D expression; repeat as needed")
    ap.add_argument("--aggregate", action="store_true",
                    help="Group identical category/material/dimension rows")
    args = ap.parse_args(argv)

    if args.json and not args.preset:
        ap.error("--preset is required when --json is supplied")
    if args.preset and not args.json:
        ap.error("--json is required when --preset is supplied")

    scad = args.scad.resolve()
    if not scad.exists():
        ap.error(f"SCAD file does not exist: {scad}")

    cmd = [args.openscad]
    temp_json = None

    if args.json:
        # OpenSCAD parameter sets can take precedence over -D for a parameter
        # stored in the JSON. Make a temporary copy with output_mode forced to
        # BOM instead of relying on command-line override precedence.
        import json

        with args.json.resolve().open("r", encoding="utf-8") as fh:
            param_data = json.load(fh)

        try:
            param_set = param_data["parameterSets"][args.preset]
        except KeyError as exc:
            raise SystemExit(
                f"Parameter set {args.preset!r} was not found in {args.json}"
            ) from exc

        param_set["output_mode"] = "bom"

        tmpj = tempfile.NamedTemporaryFile(
            suffix=".json", delete=False, mode="w", encoding="utf-8"
        )
        json.dump(param_data, tmpj, indent=2)
        tmpj.close()
        temp_json = Path(tmpj.name)

        cmd += ["-p", str(temp_json), "-P", args.preset]
    else:
        # Without a parameter set, -D is the simplest way to force BOM mode.
        cmd += ["-D", 'output_mode="bom"']

    for expr in args.define:
        cmd += ["-D", expr]

    with tempfile.NamedTemporaryFile(suffix=".csg", delete=False) as tmp:
        temp_svg = Path(tmp.name)

    try:
        cmd += ["-o", str(temp_svg), str(scad)]
        proc = run_scad(
            cmd,
            cwd=str(scad.parent),
            capture_output=True,
            text=True,
        )

        combined = (proc.stdout or "") + "\n" + (proc.stderr or "")
        rows = parse_bom_lines(combined)

        if proc.returncode != 0 or "CHECK|ERROR|" in combined:
            sys.stderr.write(combined)
            return proc.returncode or 2

        if not rows:
            sys.stderr.write(combined)
            raise SystemExit("No BOM rows found in OpenSCAD output.")

        if args.aggregate:
            rows = aggregate_rows(rows)

        args.output.parent.mkdir(parents=True, exist_ok=True)
        with args.output.open("w", newline="", encoding="utf-8") as fh:
            writer = csv.DictWriter(fh, fieldnames=COLUMNS)
            writer.writeheader()
            writer.writerows(rows)

        print(f"Wrote {len(rows)} BOM rows to {args.output}")
        return 0
    finally:
        try:
            temp_svg.unlink()
        except FileNotFoundError:
            pass

        if temp_json is not None:
            try:
                temp_json.unlink()
            except FileNotFoundError:
                pass


if __name__ == "__main__":
    raise SystemExit(main())
