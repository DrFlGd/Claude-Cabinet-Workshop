#!/usr/bin/env python3
"""Generate schema.json from Modular Organization v4 OpenSCAD Customizer inputs.

The SCAD front ends are the source of truth for parameter names/defaults/groups.
This generator only serializes that public contract for web/configurator use.
"""
from pathlib import Path
from .paths import SCAD_DIR, CONFIG_DIR
import re, json, ast, argparse

from .paths import FRONTENDS as MODULE_FILES
FRONTENDS={name:files[0] for name,files in MODULE_FILES.items()}

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
        u=unit_for(name) if p['type'] not in ('enum','boolean','string') and not re.search(r'weights|count|graduated_step|circle_segments|^target_drawer_bank$',name) else None
        if u: p['unit']=u
        p.update(mod)
        if comments: p['description']=' '.join(x for x in comments[-5:] if x)
        out.append(p); comments=[]
    return out

def build(root):
    doc={
      'schema_version':7,'engine_family':'modular_organization','engine_version':5,'package':'modular-organization','package_version':'5.3.0',
      'forked_from':{'package':'modular_storage_v35','engine_version':35},
      'contract':{
        'configuration_model':'direct',
        'recipes':'one-time editable value patches; native OpenSCAD Customizer parameter sets are supplied beside each front end',
        'hardware':'hardware.json; one-time editable apply patches using the same canonical settings as manual configuration',
        'equipment_hardware':'equipment_hardware.json',
        'outputs':{
          'api_prefix':'API|','api_compat_prefix':'API_COMPAT|','config_prefix':'CONFIG|',
          'dimension_prefix':'DIM|','target_prefix':'TARGET|','info_prefix':'INFO|',
          'bom_prefix':'BOM|','warning_prefix':'WARN|','error_prefix':'ERROR|',
          'validation_prefix':'CHECK|','system_prefix':'SYSTEM|','compatibility_prefix':'COMPAT|',
          'module_prefix':'MODULE|','interface_prefix':'INTERFACE|','interface_frame_prefix':'INTERFACE_FRAME|','keepout_prefix':'KEEPOUT|',
          'feature_owner_prefix':'FEATURE_OWNER|','feature_prefix':'FEATURE|','coverage_prefix':'COVERAGE|','export_frame_prefix':'EXPORT_FRAME|'
        },
        'interface_contract':{
          'id':'MOI-4',
          'definition_file':'interface_contract.json',
          'model':'project -> modules/relationships -> parts -> interfaces/frames -> features/keepouts',
          'standards':{
            'stack':'MOI-STACK-1',
            'side_gang':'MOI-GANG-1',
            'carcass_joint':'MOI-JOINT-1',
            'drawer_joint':'MOI-DRAWER-1',
            'drawer_organizer':'MOI-DIVIDER-GRID-1',
            'equipment_stack':'MOI-EQUIP-STACK-1','cleat':'MOI-MOUNT-CLEAT-1','equipment_tray':'MOI-EQUIP-TRAY-1','device_bay':'MOI-DEVICE-BAY-1'
          },
          'compatibility_rule':'Compare STANDARD and KEY for mating external interfaces. KSV=2 keys sign all current geometry-driving fields; keepout AABBs reserve geometry owned by another interface.',
          'coordinate_system':'millimeters in global cabinet coordinates; front-left-bottom datum unless interface record states otherwise'
        },
        'project_composition':{
          'project_format':'MORG-1',
          'project_schema':'project_schema.json',
          'resolver':'python -m modular_organization project',
          'placement':'interface-frame mating with translation and orthogonal Z rotation; contains offsets; derived multi-support worktops',
          'project_collision':'conservative module AABB validation'
        },
        'manufacturing':{
          'package_exporter':'modular_organization.api.manufacture',
          'nesting_planner':'modular_organization.nesting',
          'exhaustive_validator':'modular_organization.validation',
          'nesting_mode':'bounding_rectangle',
          'registration':'CUT, POCKET, and ENGRAVE layouts share the OpenSCAD export registration frame',
          'validation_scope':'OpenSCAD is exhaustive for current external-interface signatures and current outer-side machining features; modular-organization audit completes exhaustive CUT/POCKET contour coverage. Neither is structural/load or CAM/toolpath verification.'
        }
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
        'mixed_bay_width_weights':{'cabinet_layout_mode':'mixed_bays'},
        'include_mixed_bay_partitions':{'cabinet_layout_mode':'mixed_bays'},
        'mixed_bay_front_gap':{'cabinet_layout_mode':'mixed_bays'},
        'face_frame_stock':{'front_facing_style':'face_frame'},
        'face_frame_construction':{'front_facing_style':'face_frame'},
        'face_frame_back_dado_depth':{'face_frame_construction':'segmented_back_dado'},
        'face_frame_back_dado_clearance':{'face_frame_construction':'segmented_back_dado'},
        'face_frame_custom_mid_rail_z':{'face_frame_mid_rail_mode':'custom'},
        'inset_front_back_clearance':{'front_mount_style':'inset_flush'}
      },
      'stackable':{
        'stack_base_height':{'include_stack_base':True},
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
    edge_joinery_rules={
      'edge_joinery_policy':{'joinery_style':'tab_slot'},
      'bottom_tab_placement':{'joinery_style':'tab_slot','edge_joinery_policy':'location_aware'},
      'top_tab_placement':{'joinery_style':'tab_slot','edge_joinery_policy':'location_aware'},
      'shelf_tab_placement':{'joinery_style':'tab_slot','edge_joinery_policy':'location_aware'},
      'separator_tab_placement':{'joinery_style':'tab_slot','edge_joinery_policy':'location_aware'},
      'bottom_tab_custom_centers':{'bottom_tab_placement':'custom'},
      'top_tab_custom_centers':{'top_tab_placement':'custom'},
      'shelf_tab_custom_centers':{'shelf_tab_placement':'custom'},
      'separator_tab_custom_centers':{'separator_tab_placement':'custom'},
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
    divider_rules={
      'drawer_divider_layout_mode':{'include_drawer_divider_grid':True},
      'drawer_divider_columns':{'include_drawer_divider_grid':True,'drawer_divider_layout_mode':'equal_count'},
      'drawer_divider_rows':{'include_drawer_divider_grid':True,'drawer_divider_layout_mode':'equal_count'},
      'drawer_divider_custom_x':{'include_drawer_divider_grid':True,'drawer_divider_layout_mode':'custom_positions'},
      'drawer_divider_custom_y':{'include_drawer_divider_grid':True,'drawer_divider_layout_mode':'custom_positions'},
      'drawer_divider_target_mode':{'include_drawer_divider_grid':True},
      'drawer_divider_target_index':{'include_drawer_divider_grid':True,'drawer_divider_target_mode':'drawer_index'},
      'drawer_divider_mounting':{'include_drawer_divider_grid':True},
      'drawer_divider_stock':{'include_drawer_divider_grid':True},
      'custom_drawer_divider_thickness':{'include_drawer_divider_grid':True,'drawer_divider_stock':'custom_mm'},
      'drawer_divider_height':{'include_drawer_divider_grid':True},
      'drawer_divider_groove_clearance':{'include_drawer_divider_grid':True},
      'drawer_divider_interlock_clearance':{'include_drawer_divider_grid':True},
      'drawer_divider_bottom_groove_depth':{'include_drawer_divider_grid':True},
      'drawer_divider_perimeter_groove_depth':{'include_drawer_divider_grid':True,'drawer_divider_mounting':'bottom_and_perimeter'},
      'drawer_divider_edge_margin':{'include_drawer_divider_grid':True},
      'drawer_divider_interlock_orientation':{'include_drawer_divider_grid':True},
      'engrave_drawer_divider_ids':{'include_drawer_divider_grid':True},
    }
    for kind in doc['frontends']:
        vis.setdefault(kind,{}).update(divider_rules)
        vis.setdefault(kind,{}).update(edge_joinery_rules)
        vis.setdefault(kind,{}).update(ganging_rules)
        vis.setdefault(kind,{}).update(sizing_rules)
        vis.setdefault(kind,{}).update(hardware_rules)

    for kind,rules in vis.items():
        pm={p['id']:p for p in doc['frontends'][kind]['parameters']}
        for pid,rule in rules.items():
            if pid in pm and all(key in pm for key in rule): pm[pid]['visible_if']=rule
    for kind,frontend in doc['frontends'].items():
        frontend['presets']=list(json.loads((root/(kind+'.json')).read_text())['parameterSets'])
        ids={x['id'] for x in frontend['parameters']}
        frontend['capabilities']={
            'carcass_joinery':'joinery_style' in ids,
            'drawer_joinery':'drawer_joinery_style' in ids,
            'screw_guides':True,'decimal_stock':True,'flat_3d':True,
            'rear_construction':'back_style' in ids,
            'french_cleat':kind=='equipment_stand',
            'equipment_trays':kind=='equipment_stand',
            'cabinet_stack_interface':kind=='stackable',
            'equipment_stack_interface':kind=='equipment_stand',
            'drawer_organizers':'include_drawer_divider_grid' in ids,
            'common_joinery_parameter':'drawer_joinery_style' if kind=='drawer' else 'joinery_style'}
        for parameter in frontend['parameters']:
            if parameter['type']=='expression':
                parameter['type']='number'
                parameter['computed_default']=True
            if parameter.get('unit')=='mm' and parameter['type']=='number':
                parameter.setdefault('step',0.01)
        # Source order is the native Customizer order; never silently re-sort the web UI.
        frontend['groups']=list(dict.fromkeys(p['group'] for p in frontend['parameters']))
    layout=json.loads((CONFIG_DIR/'parameter_layout.json').read_text())
    doc['parameter_layout']=layout
    shared={}
    for kind,frontend in doc['frontends'].items():
        actual=frontend['groups']
        expected=[g for g in layout['groups'] if g in actual]
        if actual!=expected: raise ValueError(f'{kind}: unknown or out-of-order parameter groups')
        ids=set()
        for p in frontend['parameters']:
            if p['id'] in ids: raise ValueError(f"{kind}: duplicate public parameter {p['id']}")
            ids.add(p['id'])
            previous=shared.setdefault(p['id'],p['group'])
            if previous!=p['group']: raise ValueError(f"{kind}: inconsistent group for {p['id']}")
    return doc

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument('--root',default=SCAD_DIR,type=Path)
    ap.add_argument('-o','--output',default=str(CONFIG_DIR/'schema.json'))
    args=ap.parse_args()
    doc=build(args.root)
    out=Path(args.output)
    if not out.is_absolute(): out=args.root/out
    out.write_text(json.dumps(doc,indent=2))
    print(out)

if __name__=='__main__': main()
