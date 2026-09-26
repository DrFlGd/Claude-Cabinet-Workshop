#!/usr/bin/env python3
"""Generate modular_storage_schema_v1.json from V32 OpenSCAD Customizer inputs.

The SCAD front ends are the source of truth for parameter names/defaults/groups.
This generator only serializes that public contract for web/configurator use.
"""
from pathlib import Path
import re, json, ast, argparse

FRONTENDS={
    'utility':'modular_storage_utility_v32.scad',
    'shop_cart':'modular_storage_shop_cart_v32.scad',
    'benchtop':'modular_storage_benchtop_v32.scad',
    'stackable':'modular_storage_stackable_v32.scad',
    'kitchen':'modular_storage_kitchen_v32.scad',
    'drawer':'modular_storage_drawer_v32.scad',
}

def parse_value(expr):
    e=expr.strip()
    if e=='true': return True
    if e=='false': return False
    if e=='undef': return None
    try: return ast.literal_eval(e)
    except Exception:
        try: return float(e) if any(c in e for c in '.eE') else int(e)
        except Exception: return None

def unit_for(name):
    n=name.lower()
    if n.endswith('_in'): return 'in'
    if any(tok in n for tok in [
        'width','height','depth','thickness','diameter','spacing','clearance',
        'setback','inset','margin','overhang','reveal','gap','kerf','radius',
        'offset','projection','length','dado_depth']): return 'mm'
    return None

def modifier(comment):
    if not comment: return {}
    c=comment.strip(); m=re.match(r'^\[(.*)\]$',c)
    if not m: return {'help_inline':c} if c else {}
    body=m.group(1); parts=body.split(':')
    if len(parts) in (2,3):
        try:
            nums=[float(x) for x in parts]
            return {'range':{'min':nums[0],'max':nums[-1],**({'step':nums[1]} if len(nums)==3 else {})}}
        except Exception: pass
    return {'enum':[x.strip() for x in body.split(',') if x.strip()]}

def infer(value,expr,mod):
    if 'enum' in mod: return 'enum'
    if 'range' in mod: return 'number'
    if isinstance(value,bool): return 'boolean'
    if isinstance(value,(int,float)): return 'number'
    if isinstance(value,str): return 'string'
    if isinstance(value,list) or expr.startswith('['): return 'array'
    return 'expression'

def parse_frontend(path):
    section=''; comments=[]; out=[]
    for raw in path.read_text().splitlines():
        s=raw.strip()
        sm=re.match(r'/\* \[(.*?)\] \*/',s)
        if sm:
            section=sm.group(1); comments=[]; continue
        if s.startswith('//'):
            comments.append(s[2:].strip()); continue
        m=re.match(r'([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.+?);(?:\s*//\s*(.*))?$',s)
        if not m:
            if s: comments=[]
            continue
        name,expr,c=m.groups()
        if section=='Hidden' or section.startswith('Resolved') or name.startswith('$'):
            comments=[]; continue
        val=parse_value(expr); mod=modifier(c)
        p={'id':name,'group':section or 'Ungrouped','type':infer(val,expr,mod),'default':val}
        if val is None and expr!='undef': p['default_expression']=expr
        u=unit_for(name)
        if u: p['unit']=u
        p.update(mod)
        if comments: p['description']=' '.join(x for x in comments[-5:] if x)
        out.append(p); comments=[]
    return out

def build(root):
    doc={
      'schema_version':1,'engine_version':32,'package':'modular_storage_v32',
      'contract':{
        'configuration_model':'direct',
        'recipes':'one-time editable value patches; native OpenSCAD Customizer parameter sets are supplied beside each front end',
        'hardware':'modular_storage_hardware_v2.json; one-time editable apply patches using the same canonical settings as manual configuration',
        'outputs':{'api_prefix':'API|','config_prefix':'CONFIG|','dimension_prefix':'DIM|','target_prefix':'TARGET|','info_prefix':'INFO|','bom_prefix':'BOM|','warning_prefix':'WARN|','error_prefix':'ERROR|'}
      },
      'frontends':{}
    }
    for kind,fn in FRONTENDS.items():
        doc['frontends'][kind]={'file':fn,'design_type':kind,'parameters':parse_frontend(root/fn)}
    vis={
      'utility':{'mixed_bay_count':{'cabinet_layout_mode':'mixed_bays'},'mixed_bay_types':{'cabinet_layout_mode':'mixed_bays'},'mixed_bay_width_weights':{'cabinet_layout_mode':'mixed_bays'}},
      'shop_cart':{'mixed_bay_count':{'cabinet_layout_mode':'mixed_bays'},'mixed_bay_types':{'cabinet_layout_mode':'mixed_bays'},'mixed_bay_width_weights':{'cabinet_layout_mode':'mixed_bays'}},
      'kitchen':{
        'mixed_bay_count':{'cabinet_layout_mode':'mixed_bays'},
        'mixed_bay_types':{'cabinet_layout_mode':'mixed_bays'},
        'mixed_bay_shelf_counts':{'cabinet_layout_mode':'mixed_bays'},
        'face_frame_stock':{'front_facing_style':'face_frame'},
        'face_frame_construction':{'front_facing_style':'face_frame'},
        'face_frame_back_dado_depth':{'face_frame_construction':'segmented_back_dado'},
        'face_frame_back_dado_clearance':{'face_frame_construction':'segmented_back_dado'},
        'face_frame_custom_mid_rail_z':{'face_frame_mid_rail_mode':'custom'},
        'inset_front_back_clearance':{'front_mount_style':'inset_flush'}
      },
      'stackable':{
        'stack_base_height':{'include_stack_base':True},
        'bottom_tab_placement':{'joinery_style':'tab_slot'},
        'bottom_tab_custom_centers':{'bottom_tab_placement':'custom'}
      },
      'drawer':{
        'enclosure_opening_width':{'drawer_design_basis':'enclosure'},
        'enclosure_opening_height':{'drawer_design_basis':'enclosure'},
        'enclosure_usable_depth':{'drawer_design_basis':'enclosure'},
        'enclosure_height_mode':{'drawer_design_basis':'enclosure'},
        'enclosure_target_box_height':{
            'drawer_design_basis':'enclosure',
            'enclosure_height_mode':'box_height'
        },
        'enclosure_target_inside_height':{
            'drawer_design_basis':'enclosure',
            'enclosure_height_mode':'inside_clear'
        },
        'target_box_outside_width':{'drawer_design_basis':'outside_box'},
        'target_box_outside_depth':{'drawer_design_basis':'outside_box'},
        'target_box_outside_height':{'drawer_design_basis':'outside_box'},
        'target_box_inside_width':{'drawer_design_basis':'inside_clear'},
        'target_box_inside_depth':{'drawer_design_basis':'inside_clear'},
        'target_box_inside_height':{'drawer_design_basis':'inside_clear'},
        'drawer_module_pitch_x':{'drawer_design_basis':'modular_grid'},
        'drawer_module_count_x':{'drawer_design_basis':'modular_grid'},
        'drawer_module_edge_clearance_x':{'drawer_design_basis':'modular_grid'},
        'drawer_module_pitch_y':{'drawer_design_basis':'modular_grid'},
        'drawer_module_count_y':{'drawer_design_basis':'modular_grid'},
        'drawer_module_edge_clearance_y':{'drawer_design_basis':'modular_grid'},
        'drawer_module_inside_height':{'drawer_design_basis':'modular_grid'},
        'drawer_face_overlay_horizontal':{'drawer_face_style':'overlay'},
        'drawer_face_overlay_vertical':{'drawer_face_style':'overlay'},
        'drawer_face_inset_reveal':{'drawer_face_style':'inset_flush'},
        'drawer_face_back_clearance':{'drawer_face_style':'inset_flush'},
        'custom_drawer_face_width':{'drawer_face_size_mode':'custom'},
        'custom_drawer_face_height':{'drawer_face_size_mode':'custom'},
        'drawer_free_fit_clearance_per_side':{'drawer_mount':'none'},
        'standalone_include_fixed_wood_rails':{'drawer_mount':'wood_rails'},
        'standalone_wood_slide_length':{'drawer_mount':'wood_rails'}
      },
    }
    hardware_rules={
      'metal_slide_first_hole_from_front':{'metal_slide_hole_pattern_mode':'legacy_spacing'},
      'metal_slide_hole_spacing':{'metal_slide_hole_pattern_mode':'legacy_spacing'},
      'metal_slide_hole_count':{'metal_slide_hole_pattern_mode':'legacy_spacing'},
      'metal_slide_cabinet_holes_x':{'metal_slide_hole_pattern_mode':'explicit_array'},
      'metal_slide_drawer_holes_x':{'metal_slide_hole_pattern_mode':'explicit_array'},
      'metal_slide_cabinet_hole_diameter':{'metal_slide_hole_pattern_mode':'explicit_array'},
      'metal_slide_drawer_hole_diameter':{'metal_slide_hole_pattern_mode':'explicit_array'},
      'hardware_drilling_mode':{'metal_slide_hole_pattern_mode':'explicit_array'},
    }
    ganging_rules={
      'ganging_dowel_diameter':{'ganging_style':'dowel_connector'},
      'ganging_dowel_depth':{'ganging_style':'dowel_connector'},
    }
    sizing_rules={
      'target_drawer_inside_width':{
        'width_basis':'drawer_inside',
        'target_dimension_mode':'direct'
      },
      'target_drawer_inside_depth':{
        'depth_basis':'drawer_inside',
        'target_dimension_mode':'direct'
      },
      'target_module_pitch_x':{'target_dimension_mode':'modular_grid'},
      'target_module_count_x':{'target_dimension_mode':'modular_grid'},
      'target_module_edge_clearance_x':{'target_dimension_mode':'modular_grid'},
      'target_module_pitch_y':{'target_dimension_mode':'modular_grid'},
      'target_module_count_y':{'target_dimension_mode':'modular_grid'},
      'target_module_edge_clearance_y':{'target_dimension_mode':'modular_grid'},
    }
    for kind in doc['frontends']:
        vis.setdefault(kind,{}).update(ganging_rules)
        vis.setdefault(kind,{}).update(sizing_rules)
        vis.setdefault(kind,{}).update(hardware_rules)

    for kind,rules in vis.items():
        pm={p['id']:p for p in doc['frontends'][kind]['parameters']}
        for pid,rule in rules.items():
            if pid in pm: pm[pid]['visible_if']=rule
    return doc

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument('--root',default=Path(__file__).resolve().parent,type=Path)
    ap.add_argument('-o','--output',default='modular_storage_schema_v1.json')
    args=ap.parse_args()
    doc=build(args.root)
    out=Path(args.output)
    if not out.is_absolute(): out=args.root/out
    out.write_text(json.dumps(doc,indent=2))
    print(out)

if __name__=='__main__': main()
