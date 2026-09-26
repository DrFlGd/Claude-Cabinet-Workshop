"""Typed request boundary and explicit cross-module aliases.

Do not pass untrusted SCAD, filenames, -D expressions or arbitrary preset documents
through this API. Frontends/presets/hardware IDs resolve from packaged resources.
"""
from __future__ import annotations
import copy,json,math,re
from pathlib import Path
from functools import lru_cache
from .paths import SCAD_DIR,CONFIG_DIR,FRONTENDS

@lru_cache(maxsize=1)
def catalog():
    return json.loads((CONFIG_DIR/'schema.json').read_text(encoding='utf-8'))

def spec(frontend):
    if frontend not in FRONTENDS: raise ValueError(f'Unknown frontend: {frontend!r}')
    return {p['id']:p for p in catalog()['frontends'][frontend]['parameters']}

def _finite(value,depth=0):
    if depth>12: raise ValueError("Configuration nesting exceeds 12 levels")
    if isinstance(value,float) and not math.isfinite(value): raise ValueError('Non-finite numbers are not accepted')
    if isinstance(value,list):
        if len(value)>256: raise ValueError('Parameter arrays are limited to 256 entries')
        for v in value: _finite(v,depth+1)
    if isinstance(value,dict):
        for v in value.values(): _finite(v,depth+1)

def check_parameter(p,value,*,native=False):
    typ=p['type']
    if native and isinstance(value,str) and typ not in ('string','enum'):
        try:value=json.loads(value)
        except json.JSONDecodeError as exc: raise ValueError(f"Invalid native preset value for {p['id']}") from exc
    _finite(value)
    if typ=='boolean' and not isinstance(value,bool): raise ValueError(f"{p['id']} must be boolean")
    if typ=='number':
        if isinstance(value,bool) or not isinstance(value,(int,float)): raise ValueError(f"{p['id']} must be numeric")
        if abs(value)>100000:raise ValueError(f"{p['id']} exceeds the engine input limit")
        limits=p.get('range',{})
        if value<limits.get('min',-100000) or value>limits.get('max',100000): raise ValueError(f"{p['id']} is outside its supported range")
        if any(token in p['id'] for token in ('count','columns','rows','segments','target_index')) and value!=int(value):
            raise ValueError(f"{p['id']} must be an integer")
    if typ=='enum':
        vals=p['enum']
        if value not in vals:
            # A few native OpenSCAD selectors enumerate numeric values.
            if isinstance(p.get('default'),(int,float)) and not isinstance(value,bool) and str(value) in vals:pass
            else:raise ValueError(f"{p['id']} must be one of {vals}")
    if typ=='string':
        if not isinstance(value,str) or len(value)>512 or any(ord(c)<32 for c in value):raise ValueError(f"Invalid text for {p['id']}")
    if typ=='array':
        if not isinstance(value,list):raise ValueError(f"{p['id']} must be an array")
        def valid(x):
            if isinstance(x,list):return all(valid(y) for y in x)
            return isinstance(x,(int,float,str,bool)) and (not isinstance(x,str) or len(x)<=128)
        if not all(valid(x) for x in value):raise ValueError(f"Invalid array items for {p['id']}")
    return value

def common_patch(frontend,common):
    ps=spec(frontend); out={}
    for key,value in common.items():
        if key=='joinery':out['drawer_joinery_style' if frontend=='drawer' else 'joinery_style']=value
        elif key=='material_thickness':
            if frontend=='equipment_stand':out['material_thickness']=value
            else:
                target,stock=('custom_drawer_material_thickness','drawer_stock') if frontend=='drawer' else ('custom_carcass_thickness','carcass_stock')
                out[target]=value
                if stock in ps:out[stock]='custom_mm' if 'custom_mm' in ps[stock].get('enum',[]) else 'custom'
        elif key=='tray_thickness' and frontend=='equipment_stand':out[key]=value
        else:raise ValueError(f'Common setting {key!r} is unsupported for {frontend}')
    return out

def compile_config(frontend,*,preset=None,parameters=None,common=None,hardware_id=None):
    ps=spec(frontend); values={}; warnings=[]
    if parameters is not None and not isinstance(parameters,dict):raise ValueError('parameters must be an object')
    if common is not None and not isinstance(common,dict):raise ValueError('common must be an object')
    _finite(parameters or {});_finite(common or {})
    if len(json.dumps([parameters,common],allow_nan=False))>65536:raise ValueError('Configuration exceeds 64 KiB')
    if preset is not None:
        sets=json.loads((SCAD_DIR/FRONTENDS[frontend][1]).read_text())['parameterSets']
        if preset not in sets:raise ValueError(f'Unknown preset for {frontend}: {preset!r}')
        for key,value in sets[preset].items():
            # Legacy presets contain hidden compatibility defaults. They are local,
            # trusted resource data; retain those but never accept them in requests.
            values[key]=check_parameter(ps[key],value,native=True) if key in ps else value
    if hardware_id:
        file='equipment_hardware.json' if frontend=='equipment_stand' else 'hardware_resolved.json'
        profiles=json.loads((CONFIG_DIR/file).read_text())['profiles']
        profile=next((p for p in profiles if p['id']==hardware_id),None)
        if profile is None or frontend not in profile.get('targets',[]):raise ValueError('Hardware profile unavailable for this frontend')
        for key,value in profile.get('apply',{}).items():
            if key not in ps: raise ValueError(f'Hardware patch key not supported: {key}')
            values[key]=check_parameter(ps[key],value)
        warnings.append('Hardware values are reference data; verify purchased hardware and drilling. Equipment travel/rating patches reset to zero.')
    parameters=copy.deepcopy(parameters or {})
    if frontend=='equipment_stand' and 'joinery_type' in parameters:
        if 'joinery_style' in parameters:raise ValueError('Specify only joinery_style, not both joinery aliases')
        parameters['joinery_style']=parameters.pop('joinery_type');warnings.append('joinery_type is deprecated; use joinery_style')
    patch=common_patch(frontend,common or {})
    if set(patch)&set(parameters):raise ValueError('Common and native settings conflict; specify a value in only one place')
    patch.update(parameters)
    for key,value in patch.items():
        if key not in ps:raise ValueError(f'Unsupported public parameter for {frontend}: {key!r}')
        if key in ('output_mode','validation_report','system_contract_report'):raise ValueError(f'{key} is controlled by the operation')
        values[key]=check_parameter(ps[key],value)
    return {'frontend':frontend,'parameters':values,'warnings':warnings}

def write_parameter_file(config,path,*,mode='bom'):
    values={k:(v if isinstance(v,str) else json.dumps(v,separators=(',',':'),allow_nan=False)) for k,v in config['parameters'].items()}
    values.update(output_mode=mode,validation_report='verbose',system_contract_report='verbose')
    Path(path).write_text(json.dumps({'fileFormatVersion':'1','parameterSets':{'Request':values}},indent=2,allow_nan=False),encoding='utf-8')

def validate_project(project):
    from jsonschema import Draft202012Validator
    _finite(project)
    schema=json.loads((CONFIG_DIR/'project_schema.json').read_text())
    errors=sorted(Draft202012Validator(schema).iter_errors(project),key=lambda e:str(list(e.path)))
    if errors:raise ValueError('Invalid project: '+errors[0].message)
    modules=project['modules']; rels=project['relationships']
    if not modules or len(modules)>64 or len(rels)>128:raise ValueError('Project limits: 1..64 modules, at most 128 relationships')
    ids=[m['id'] for m in modules]
    if len(ids)!=len(set(ids)):raise ValueError('Module IDs must be unique')
    for m in modules:
        if m['type']=='openscad':
            if m.get('frontend') not in FRONTENDS:raise ValueError('OpenSCAD module requires a known frontend')
            compile_config(m['frontend'],preset=m.get('preset'),parameters=m.get('parameters',{}))
        if m['type']=='box' and (len(m.get('size',[]))!=3 or min(m['size'])<=0):raise ValueError('Box requires three positive dimensions')
        if m['type']=='span_worktop' and (not m.get('supports') or any(i not in ids for i in m['supports'])):raise ValueError('Worktop requires valid supports')
    if len({r['id'] for r in rels})!=len(rels):raise ValueError('Relationship IDs must be unique')
    graph={i:[] for i in ids}
    for r in rels:
        if r['type']=='contains' and r.get('parent') in graph:graph[r['parent']].append(r.get('child'))
    def visit(node,active,done):
        if node in active:raise ValueError('Containment cycle detected')
        if node in done:return
        active.add(node)
        for child in graph.get(node,[]):visit(child,active,done)
        active.remove(node);done.add(node)
    done=set()
    for node in ids:visit(node,set(),done)
    for r in rels:
        refs=[]
        if r['type']=='mate':
            if not all(k in r for k in ('a','b')):raise ValueError('Mate requires a and b')
            refs=[r['a']['module'],r['b']['module']]
        elif r['type']=='contains':
            if not all(k in r for k in ('parent','child')):raise ValueError('Contains requires parent and child')
            refs=[r['parent'],r['child']]
        elif r['type']=='mount':
            if 'host' not in r or 'child' not in r:raise ValueError('Mount requires host and child')
            refs=[r['host']['module'],r['child']]
        if any(x not in ids for x in refs) or (len(refs)>1 and refs[0]==refs[1]):raise ValueError('Relationship references missing or identical modules')


