#!/usr/bin/env python3
"""Adapt shipped v4 slide metadata into editable equipment-stand patches."""
import json
from pathlib import Path
from .paths import CONFIG_DIR as ROOT, SCAD_DIR
KEYS={'metal_slide_clearance_per_side','metal_slide_length','metal_slide_front_setback','metal_slide_envelope_height','include_metal_slide_holes','metal_slide_cabinet_holes_x','metal_slide_drawer_holes_x','metal_slide_cabinet_hole_diameter','metal_slide_drawer_hole_diameter'}
def main():
    source=json.loads((ROOT/'hardware_resolved.json').read_text())
    profiles=[]
    for p in source['profiles']:
        a=p.get('apply',{})
        if p.get('category')!='drawer_slide' or not a.get('metal_slide_length'): continue
        q={k:v for k,v in p.items() if k not in ('apply','targets')}
        q['targets']=['equipment_stand']
        q['apply']={k:v for k,v in a.items() if k in KEYS}
        q['apply'].update(slide_type='side_mount',slide_supported_travel=0,tray_extension=0,slide_load_rating_kg=0,
                          tray_cheek_height=max(70,a.get('metal_slide_envelope_height',45)+20))
        if not a.get('metal_slide_cabinet_holes_x') or not a.get('metal_slide_drawer_holes_x'):
            q['apply']['include_metal_slide_holes']=False
        q['equipment_note']='Reuses shipped v4 reference data, not newly verified specifications. Travel and rating reset to zero until checked. Drilling disabled without explicit hole arrays. Centered slide rows; verify vertical placement on purchased hardware.'
        profiles.append(q)
    (ROOT/'equipment_hardware.json').write_text(json.dumps({'catalog_version':1,'semantics':'one-time editable patches; no live binding','profiles':profiles},indent=2))
    print(f'{len(profiles)} equipment slide profiles')
if __name__=='__main__': main()
