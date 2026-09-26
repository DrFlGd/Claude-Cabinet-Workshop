#!/usr/bin/env python3
"""One-command manufacturing package exporter for Modular Organization v5.

Produces registered CUT/POCKET/ENGRAVE exports, BOM CSV, dimensions, structured
validation, configuration snapshot, a conservative sheet nesting plan/preview,
and a manifest inside one ZIP archive.
"""
from __future__ import annotations

import argparse
import csv
import json
import re
import os
import shutil
from .runtime import run_scad
import tempfile
import zipfile
from datetime import datetime, timezone
from pathlib import Path

from .nesting import rows_to_parts, nest_parts, plan_dict, write_preview_svg
from .validation import run_audit

COLUMNS=["ID","QTY","CATEGORY","MATERIAL","THICKNESS_MM","CUT_W_MM","CUT_H_MM","NOTES"]
POCKET_MODES=[
    "pocket_slide_holes",
    "pocket_carcass_dados","pocket_drawer_dados","pocket_bottom_grooves",
    "pocket_divider_bottom_grooves",
    "pocket_divider_perimeter_grooves",
    "pocket_shelf_pins","pocket_hinge_cups","pocket_face_registration",
    "pocket_base_hardware","pocket_worktop_registration",
    "pocket_face_frame_dados","pocket_ganging",
]


def parse_echo_payloads(text: str, prefix: str):
    out=[]
    # Handles normal ECHO: "..." records without depending on OpenSCAD's
    # representation of unrelated multi-argument echo lines.
    pat=re.compile(r'^ECHO:\s+"('+re.escape(prefix)+r'.*)"\s*$',re.M)
    for m in pat.finditer(text):
        out.append(m.group(1))
    return out


def parse_bom(text: str):
    rows=[]
    for payload in parse_echo_payloads(text,"BOM|"):
        fields=payload.split('|')
        if not fields or fields[0] != 'BOM':
            continue
        vals=fields[1:]
        if len(vals)<len(COLUMNS): vals += ['']*(len(COLUMNS)-len(vals))
        elif len(vals)>len(COLUMNS): vals=vals[:len(COLUMNS)-1]+['|'.join(vals[len(COLUMNS)-1:])]
        rows.append(dict(zip(COLUMNS,vals)))
    return rows


def parse_record(payload: str):
    fields=payload.split('|')
    rec={'record_type':fields[0] if fields else ''}
    extras=[]
    for field in fields[1:]:
        if '=' in field:
            key,val=field.split('=',1)
            rec[key.lower()]=val
        elif field:
            extras.append(field)
    if extras:
        rec['subtype']=extras[0]
        if len(extras)>1:
            rec['values']=extras[1:]
    return rec


def make_param_json(source: Path, preset: str, mode: str, dest: Path):
    data=json.loads(source.read_text(encoding='utf-8'))
    try:
        ps=data['parameterSets'][preset]
    except KeyError as exc:
        raise SystemExit(f"Preset {preset!r} not found in {source}") from exc
    ps['output_mode']=mode
    # Ensure structured health checks are available in generated logs.
    ps['validation_report']='summary'
    ps['system_contract_report']='verbose'
    dest.write_text(json.dumps(data,indent=2),encoding='utf-8')


def run_openscad(scad: Path, openscad: str, out: Path, mode: str,
                 defines: list[str], param_json: Path|None, preset: str|None):
    cmd=[openscad]
    temp_param=None
    if param_json is not None:
        temp_param=out.parent/(f"._params_{mode}.json")
        make_param_json(param_json,preset,mode,temp_param)
        cmd += ['-p',str(temp_param),'-P',preset]
    else:
        cmd += ['-D',f'output_mode="{mode}"','-D','validation_report="summary"','-D','system_contract_report="verbose"']
    for d in defines:
        cmd += ['-D',d]
    cmd += ['-o',str(out),str(scad)]
    proc=run_scad(cmd,cwd=str(scad.parent),capture_output=True,text=True)
    text=(proc.stdout or '')+'\n'+(proc.stderr or '')
    if temp_param:
        temp_param.unlink(missing_ok=True)
    return proc.returncode,text,cmd


def is_empty_export(text: str) -> bool:
    t=text.lower()
    return ('top level object is empty' in t or 'current top level object is empty' in t)


def write_bom_csv(rows, path: Path):
    with path.open('w',newline='',encoding='utf-8') as fh:
        w=csv.DictWriter(fh,fieldnames=COLUMNS)
        w.writeheader(); w.writerows(rows)


def main(argv=None) -> int:
    ap=argparse.ArgumentParser()
    ap.add_argument('scad',type=Path)
    ap.add_argument('-o','--output',type=Path,required=True,help='Destination .zip')
    ap.add_argument('--openscad',default='openscad')
    ap.add_argument('--json',type=Path)
    ap.add_argument('--preset')
    ap.add_argument('--define',action='append',default=[])
    ap.add_argument('--formats',default='svg,dxf',help='svg, dxf, or svg,dxf')
    ap.add_argument('--sheet-width',type=float,default=2440)
    ap.add_argument('--sheet-height',type=float,default=1220)
    ap.add_argument('--sheet-margin',type=float,default=10)
    ap.add_argument('--part-gap',type=float,default=6.35)
    ap.add_argument('--no-rotate',action='store_true')
    ap.add_argument('--grain-lock',action='append',default=[])
    args=ap.parse_args(argv)
    if bool(args.json) != bool(args.preset):
        ap.error('--json and --preset must be supplied together')
    scad=args.scad.resolve()
    if not scad.exists(): ap.error(f'Not found: {scad}')
    formats=[x.strip().lower() for x in args.formats.split(',') if x.strip()]
    if not formats or any(x not in {'svg','dxf'} for x in formats):
        ap.error('--formats must contain svg and/or dxf')

    with tempfile.TemporaryDirectory(prefix='modular_organization_v5_pkg_') as td:
        root=Path(td)/'Modular_Organization_v5_Manufacturing_Package'
        (root/'CUT').mkdir(parents=True)
        (root/'POCKET').mkdir()
        (root/'ENGRAVE').mkdir()
        (root/'REPORTS').mkdir()
        (root/'PLANNING').mkdir()

        # Fast metadata/BOM pass using CSG, avoiding expensive render/export.
        bom_probe=root/'REPORTS'/'_bom_probe.csg'
        rc,log,_=run_openscad(scad,args.openscad,bom_probe,'bom',args.define,args.json,args.preset)
        bom_probe.unlink(missing_ok=True)
        if rc != 0 or 'CHECK|ERROR|' in log:
            (root/'REPORTS'/'openscad_bom_error.txt').write_text(log,encoding='utf-8')
            raise SystemExit('OpenSCAD BOM pass failed; see console output.\n'+log[-4000:])

        rows=parse_bom(log)
        if not rows:
            raise SystemExit('No BOM rows were emitted by the selected design.')
        write_bom_csv(rows,root/'REPORTS'/'bom.csv')
        hardware=[parse_record(x) for x in parse_echo_payloads(log,'HARDWARE|')]
        (root/'REPORTS'/'hardware.json').write_text(json.dumps(hardware,indent=2),encoding='utf-8')
        dims=parse_echo_payloads(log,'DIM|')
        checks=parse_echo_payloads(log,'CHECK|')
        warns=parse_echo_payloads(log,'WARN|')
        (root/'REPORTS'/'dimensions.txt').write_text('\n'.join(dims)+'\n',encoding='utf-8')
        health=[]
        for c in checks:
            f=c.split('|',3)
            health.append({'severity':f[1] if len(f)>1 else '',
                           'code':f[2] if len(f)>2 else '',
                           'message':f[3] if len(f)>3 else ''})
        health_errors=sum(1 for x in health if x.get('severity') == 'ERROR')
        health_warnings=sum(1 for x in health if x.get('severity') == 'WARN') + len(warns)
        health_info=sum(1 for x in health if x.get('severity') == 'INFO')
        health_status='ERROR' if health_errors else 'WARN' if health_warnings else 'PASS'
        (root/'REPORTS'/'design_health.json').write_text(json.dumps({
            'status':health_status,
            'coverage_state':'semantic_only',
            'complete_manufacturing_validation':False,
            'companion_report':'exhaustive_validation.json',
            'scope_statement':'OpenSCAD semantic checks plus exhaustive outer-side feature/interface validation. Final whole-model CUT/POCKET contour coverage is only complete after exhaustive_validation.json is generated. A clean Design Health report alone is not an exhaustive manufacturing, structural/load, or CAM verification.',
            'summary':{'errors':health_errors,'warnings':health_warnings,'info':health_info},
            'checks':health,'legacy_warn_records':warns
        },indent=2),encoding='utf-8')

        system_records=[parse_record(x) for x in parse_echo_payloads(log,'SYSTEM|')]
        module_records=[parse_record(x) for x in parse_echo_payloads(log,'MODULE|')]
        compat_records=[parse_record(x) for x in parse_echo_payloads(log,'COMPAT|')]
        interface_records=[parse_record(x) for x in parse_echo_payloads(log,'INTERFACE|')]
        interface_frame_records=[parse_record(x) for x in parse_echo_payloads(log,'INTERFACE_FRAME|')]
        coverage_records=[parse_record(x) for x in parse_echo_payloads(log,'COVERAGE|')]
        keepout_records=[parse_record(x) for x in parse_echo_payloads(log,'KEEPOUT|')]
        feature_owner_records=[parse_record(x) for x in parse_echo_payloads(log,'FEATURE_OWNER|')]
        feature_records=[parse_record(x) for x in parse_echo_payloads(log,'FEATURE|')]
        (root/'REPORTS'/'system_contract.json').write_text(json.dumps({
            'system':system_records,
            'modules':module_records,
            'compatibility':compat_records,
            'coverage':coverage_records,
            'interfaces':interface_records,
            'interface_frames':interface_frame_records,
            'keepouts':keepout_records,
            'feature_owners':feature_owner_records,
            'features':feature_records,
        },indent=2),encoding='utf-8')
        (root/'REPORTS'/'openscad_console.txt').write_text(log,encoding='utf-8')

        config={
            'source_scad':scad.name,
            'defaults':{p['id']:p.get('default',p.get('default_expression')) for p in __import__('modular_organization.schema',fromlist=['parse_frontend']).parse_frontend(scad)},
            'parameter_json':str(args.json) if args.json else None,
            'preset':args.preset,
            'defines':args.define,
        }
        if args.json:
            pdata=json.loads(args.json.read_text(encoding='utf-8'))
            config['preset_values']=pdata.get('parameterSets',{}).get(args.preset,{})
        (root/'REPORTS'/'configuration.json').write_text(json.dumps(config,indent=2),encoding='utf-8')

        # Bounding-rectangle sheet planning by material/thickness.
        parts=rows_to_parts(rows,set(args.grain_lock))
        sheets,oversized=nest_parts(parts,args.sheet_width,args.sheet_height,
                                     args.sheet_margin,args.part_gap,not args.no_rotate)
        plan=plan_dict(sheets,oversized)
        plan['settings']={
            'sheet_width_mm':args.sheet_width,'sheet_height_mm':args.sheet_height,
            'margin_mm':args.sheet_margin,'part_gap_mm':args.part_gap,
            'rotation_enabled':not args.no_rotate,
            'grain_locked_materials':args.grain_lock,
        }
        (root/'PLANNING'/'nesting_plan.json').write_text(json.dumps(plan,indent=2),encoding='utf-8')
        write_preview_svg(plan,root/'PLANNING'/'nesting_preview.svg')

        statuses=[]
        jobs=[('CUT','cut_layout'),('ENGRAVE','engrave_layout')]+[('POCKET',m) for m in POCKET_MODES if m != "pocket_slide_holes" or "equipment_stand" in scad.name]
        for folder,mode in jobs:
            for fmt in formats:
                out=root/folder/f'{mode}.{fmt}'
                rc,oplog,_=run_openscad(scad,args.openscad,out,mode,args.define,args.json,args.preset)
                if rc != 0 and is_empty_export(oplog):
                    out.unlink(missing_ok=True)
                    statuses.append({'mode':mode,'format':fmt,'status':'empty_skipped'})
                    continue
                if rc != 0:
                    (root/'REPORTS'/f'{mode}_{fmt}_error.txt').write_text(oplog,encoding='utf-8')
                    statuses.append({'mode':mode,'format':fmt,'status':'error','returncode':rc})
                    continue
                statuses.append({'mode':mode,'format':fmt,'status':'exported','bytes':out.stat().st_size if out.exists() else 0})

        # Independent final-geometry audit. This re-runs CUT and all POCKET
        # modes as DXF so validation remains exhaustive even when the requested
        # manufacturing package format is SVG-only.
        audit=run_audit(scad,args.openscad,args.json,args.preset,args.define)
        (root/'REPORTS'/'exhaustive_validation.json').write_text(
            json.dumps(audit,indent=2),encoding='utf-8')

        manifest={
            'package':'modular_organization_v5',
            'created_utc':datetime.now(timezone.utc).isoformat(),
            'source':scad.name,
            'exports':statuses,
            'bom_parts':len(rows),
            'interface_contract':'MOI-4',
            'parent_engine':'modular_storage_v35',
            'active_interfaces':len(interface_records),
            'active_keepouts':len(keepout_records),
            'active_side_features':len(feature_records),
            'validation':{
                'status':audit.get('status'),
                'summary':audit.get('summary',{}),
                'scope':audit.get('scope_statement'),
            },
            'nesting':{
                'type':'bounding_rectangle',
                'sheet_count':len(sheets),
                'oversized_parts':len(oversized),
                'note':'Use CUT geometry for machining. The nesting preview/planner uses conservative BOM bounding rectangles, not contour nesting.'
            }
        }
        (root/'manifest.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
        (root/'README.txt').write_text(
            'Modular Organization v5 manufacturing package\n\n'
            'CUT/ contains through-cut geometry.\n'
            'POCKET/ contains operation-separated blind machining geometry.\n'
            'ENGRAVE/ contains part-ID engraving geometry.\n'
            'REPORTS/ contains BOM, dimensions, configuration, structured design health, exhaustive CUT/POCKET validation, and the MOI-4 interface/frame/keepout/feature contract.\n'
            'PLANNING/ contains conservative multi-sheet bounding-rectangle nesting.\n\n'
            'CUT, POCKET and ENGRAVE exports retain the generator registration frame.\n'
            'Always verify tool compensation, material thickness and hardware drilling against a test coupon/manufacturer drawing.\n',
            encoding='utf-8')

        args.output.parent.mkdir(parents=True,exist_ok=True)
        errors=sum(1 for x in statuses if x['status']=='error')
        if audit.get('status')=='ERROR' or errors or oversized:
            raise ValueError(f'Manufacturing export rejected: audit={audit.get("status")}, export_errors={errors}, oversized_parts={len(oversized)}')
        with tempfile.TemporaryDirectory(prefix='mo-publish-',dir=args.output.parent) as publish_dir:
            pending=Path(publish_dir)/'package.zip'
            with zipfile.ZipFile(pending,'w',zipfile.ZIP_DEFLATED) as zf:
                for p in sorted(root.rglob('*')):
                    if p.is_file(): zf.write(p,p.relative_to(root.parent))
            os.replace(pending,args.output)
        print(f'Wrote {args.output}')
        exported=sum(1 for x in statuses if x['status']=='exported')
        skipped=sum(1 for x in statuses if x['status']=='empty_skipped')
        errors=sum(1 for x in statuses if x['status']=='error')
        print(f'Exports: {exported} written, {skipped} empty skipped, {errors} errors; {len(sheets)} planning sheets')
        if audit.get('status') == 'ERROR':
            print('Validation: ERROR (package was still written; see REPORTS/exhaustive_validation.json)')
            return 2
        if audit.get('status') == 'WARN':
            print('Validation: WARN (see REPORTS/exhaustive_validation.json)')
        return 0 if errors==0 else 2


if __name__=='__main__':
    raise SystemExit(main())
