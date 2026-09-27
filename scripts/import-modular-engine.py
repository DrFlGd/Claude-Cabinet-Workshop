"""Import the packaged v5 schema, native presets, runtime tree and hardware."""
import json,pathlib,shutil,sys,re,hashlib
root=pathlib.Path(__file__).resolve().parents[1];src=pathlib.Path(sys.argv[1]);data=src/'src/modular_organization/data';dest=root/'public/engine/v5'
schema=json.loads((data/'config/schema.json').read_text());extras=json.loads((root/'catalog/kitchen-standard-recipes.json').read_text())['recipes']+json.loads((root/'catalog/section-layout-recipes.json').read_text())['recipes'];out=[]
def typed(v,p):
 if not isinstance(v,str) or p['type'] in ['string','enum']:return v
 try:return json.loads(v)
 except ValueError:raise ValueError('Invalid native preset value '+p['id'])
for family in ['shop_cart','utility','benchtop','stackable','kitchen','drawer','equipment_stand']:
 f=schema['frontends'][family];parameters=list(f['parameters'])
 for p in parameters:
  if p['id']=='output_mode' and f['capabilities'].get('flat_3d') and 'flat_3d' not in p.get('enum',[]):p['enum'].append('flat_3d')
 # Supported native drawer relief is missing from the supplied public schema.
 if family=='drawer' and not any(p['id']=='slot_corner_relief' for p in parameters):
  parameters.append(dict(id='slot_corner_relief',type='enum',default='none',group='Machining / Shared Slot Relief',enum=['none','dogbone','t_bone']))
 parameters.sort(key=lambda p:schema['parameter_layout']['groups'].index(p['group']))
 public={p['id']:p for p in parameters};fields=[]
 for p in parameters:
  r=p.get('range');key=p['id'];unit=p.get('unit')
  if unit is None:
   unit='mm' if (p['type'] in ['number','array'] or p.get('default_expression')) and not re.search(r'count|columns|rows|index|weights|(?:^|_)ratios?(?:_|$)|factor|angle|_kg$|circle_segments|graduated_step|^target_drawer_bank$|types|styles|modes|sides',key) else 'scalar'
  fields.append(dict(key=key,value=p['default'],expression=p.get('default_expression'),section=p['group'],description=p.get('description',''),options=p.get('enum'),bounds=[r['min'],r['max'],r.get('step',p.get('step',1))] if r else None,step=p.get('step'),unit=unit,visibleIf=p.get('visible_if'),advanced=p['group'] in ['System / Reports','System / Interface Validation','Output / Export Registration','Hardware / Slide Drilling','Hardware / Frame Fasteners','Hardware / Drawer Fasteners','Hardware / Cleat Fasteners','Structure / Tab Placement']))
 base={p['id']:p['default'] for p in parameters};starters=[dict(id='default',name='Default configuration',values=base)]
 native=json.loads((data/'scad'/f['file'].replace('.scad','.json')).read_text())['parameterSets']
 for name,patch in native.items():
  values={k:typed(v,public[k]) for k,v in patch.items() if k in public}
  starters.append(dict(id=family+'_'+re.sub('[^a-z0-9]+','_',name.lower()).strip('_'),name=name,values={**base,**values},group='Engine presets'))
 additions=[]
 for recipe in extras:
  if recipe['frontend']!=family:continue
  for key,value in recipe['apply'].items():
   if key not in public:raise ValueError('Catalog field removed: '+key)
   if public[key].get('enum') and str(value) not in [str(x) for x in public[key]['enum']]:raise ValueError('Catalog enum changed: '+key)
  additions.append(dict(id=recipe['id'],name=recipe['label'],values=recipe['apply'],group=recipe['group']))
 starters=starters[:1]+additions+starters[1:]
 out.append(dict(id=family,file='v5/src/modular_organization/data/scad/'+f['file'],fields=fields,groups=f['groups'],capabilities=f['capabilities'],defaultStarter='default',starters=starters))
sources={}
for p in sorted(src.rglob('*')):
 if p.is_file() and p.suffix in ['.scad','.json','.py','.md','.toml','.morg'] and '__pycache__' not in p.parts:
  rel=p.relative_to(src);target=dest/rel;target.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(p,target);sources['v5/'+rel.as_posix()]=p.read_text()
sources['section-layout-recipes.json']=(root/'catalog/section-layout-recipes.json').read_text()
sources['kitchen-standard-recipes.json']=(root/'catalog/kitchen-standard-recipes.json').read_text()
(root/'lib/engine-sources.json').write_text(json.dumps(sources))
(root/'lib/schema.json').write_text(json.dumps(out,indent=2))
shutil.copyfile(data/'config/hardware_resolved.json',root/'lib/hardware.json');shutil.copyfile(data/'config/equipment_hardware.json',root/'lib/equipment-hardware.json')
manifest=dict(files=[n for n in sources if n.endswith('.scad')],frontends={f['file']:next(p['options'] for p in f['fields'] if p['key']=='output_mode') for f in out})
(root/'public/openscad/engine-v5-files.js').write_text('export default '+json.dumps(manifest)+';\n')
archive=src.parent.parent/'upload/modular_organization_v5.zip'
(root/'public/engine/BUNDLE_PROVENANCE.json').write_text(json.dumps(dict(engine_family='modular_organization',engine_version=5,package_version=schema['package_version'],sha256=hashlib.sha256(archive.read_bytes()).hexdigest()),indent=2))
print('Imported',len(out),'families,',sum(len(f['fields']) for f in out),'fields and',sum(len(f['starters']) for f in out),'starters')
