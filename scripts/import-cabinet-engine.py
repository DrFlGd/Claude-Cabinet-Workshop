import json,re,pathlib,subprocess,tempfile,shutil,sys
root=pathlib.Path(__file__).resolve().parents[1];src=pathlib.Path(sys.argv[1]).resolve();dest=root/'public/engine';dest.mkdir(exist_ok=True)
files=['parametric_shop_cart_v13.scad','parametric_utility_cabinet_v57.scad','parametric_benchtop_drawer_cabinet_v29.scad','parametric_stackable_cabinet_v7.scad','parametric_kitchen_cabinet_v2.scad']
# Preserve uploaded sources; only generated exports later apply user settings.
for p in src.iterdir():
 if p.suffix in ['.scad','.py','.md']:shutil.copyfile(p,dest/p.name)
def parse(s):
 section='';fields=[]
 for m in re.finditer(r'/\*\s*\[([^\]]+)\]\s*\*/|^([a-zA-Z_]\w*)\s*=\s*([^;]+);([^\n]*)',s,re.M):
  if m[1]:section=m[1];continue
  if 'hidden' in section.lower():continue
  expression=re.sub(r'//[^\n]*','',m[3]).strip()
  try:value=json.loads(expression)
  except:continue
  desc=[]
  for line in reversed(s[:m.start()].splitlines()):
   if line.strip().startswith('//'):desc.insert(0,line.strip()[2:].strip())
   else:break
  opts=re.search(r'\[([^\]]+)\]',m[4]);options=None;bounds=None
  if opts:
   raw=opts[1]
   if re.fullmatch(r'[\d.:-]+',raw):
    n=[float(x) for x in raw.split(':')];bounds=[n[0],n[-1],n[1] if len(n)==3 else 1]
   else:options=[x.strip() for x in raw.split(',')]
  fields.append(dict(key=m[2],value=value,section=section,description=' '.join(desc),options=options,bounds=bounds,advanced='Advanced' in section))
 return fields
resolved=['cabinet_width','cabinet_height','cabinet_depth','cabinet_contents','drawer_count','door_count','active_mount_style','active_base_style','top_style','shelf_style','door_shelf_count','module_type','wood_rail_depth','wood_drawer_runner_depth','active_cabinet_layout_mode','active_mixed_bay_count','active_mixed_bay_types','active_mixed_bay_width_weights','active_mixed_bay_drawer_counts','active_mixed_bay_door_counts','active_mixed_bay_shelf_styles','active_mixed_bay_shelf_counts','active_mixed_bay_drawer_height_modes','active_mixed_bay_drawer_graduated_steps','active_mixed_bay_drawer_height_weights','active_mixed_bay_door_hinge_sides']
def evaluate(name,overrides):
 with tempfile.TemporaryDirectory(dir=root/'.sites-runtime') as td:
  p=pathlib.Path(td);wrapper=p/'probe.scad';wrapper.write_text('include <'+str(src/name)+'>\necho("WEB_VALUES",['+','.join('["'+k+'",'+k+']' for k in resolved)+']);\n')
  args=['openscad','-o',str(p/'result.echo')]
  for k,v in overrides.items():args+=['-D',k+'='+json.dumps(v)]
  subprocess.run(args+[str(wrapper)],check=True,capture_output=True)
  line=next(x for x in (p/'result.echo').read_text().splitlines() if x.startswith('ECHO: "WEB_VALUES",'))
  return dict(json.loads(line.split(', ',1)[1].replace('undef','null')))
mapkeys={'cabinet_width':'custom_cabinet_width','cabinet_height':'custom_cabinet_height','cabinet_depth':'custom_cabinet_depth','cabinet_contents':'custom_cabinet_contents','drawer_count':'custom_drawer_count','door_count':'custom_door_count','active_mount_style':'cabinet_mount_style','active_base_style':'base_style','top_style':'custom_top_style','shelf_style':'custom_shelf_style','door_shelf_count':'custom_door_shelf_count','module_type':'custom_module_type'}
for k in resolved:
 if k.startswith('active_mixed_') or k=='active_cabinet_layout_mode':mapkeys[k]=k.removeprefix('active_')
all_data=[]
for index,name in enumerate(files):
 fields=parse((src/name).read_text());keys={f['key'] for f in fields};default=next((f['value'] for f in fields if f['key']=='cabinet_preset'),'B30');recipes=[]
 if index<4:
  options=next(f['options'] for f in fields if f['key']=='cabinet_preset')
  for preset in options:
   effective=evaluate(name,{'cabinet_preset':preset});values={mapkeys[k]:v for k,v in effective.items() if k in mapkeys and mapkeys[k] in keys and v is not None};values['cabinet_preset']='custom'
   if index==3:values['custom_module_shelf_count']=effective['door_shelf_count']
   recipes.append({'id':preset,'name':preset.replace('_',' ').capitalize() if preset!='custom' else 'Custom configuration','values':values})
 else:
  for width in [12,15,18,21,24,27,30,33,36,39,42,45,48]:
   recipes.append({'id':'B'+str(width),'name':f'B{width} · Base, drawer over doors','values':{'kitchen_family':'base','kitchen_nominal_width_in':width,'kitchen_base_configuration':'drawer_over_doors'}})
  for config,prefix,title in [('3_drawer','DB3','3 drawers'),('4_drawer','DB4','4 drawers'),('full_height_doors','FD','Full-height doors'),('sink_base','SB','Sink base')]:
   for width in [18,24,30,36]:recipes.append({'id':prefix+str(width),'name':f'{prefix}{width} · {title}','values':{'kitchen_family':'base','kitchen_nominal_width_in':width,'kitchen_base_configuration':config}})
  for height in [30,36,42]:
   for width in [12,18,24,30,36]:recipes.append({'id':f'W{width}{height}','name':f'W{width}{height} · Wall, {width} × {height} in','values':{'kitchen_family':'wall','kitchen_nominal_width_in':width,'kitchen_wall_height_in':height,'kitchen_wall_configuration':'doors'}})
  for width in [18,24,30,36]:recipes.append({'id':f'P{width}90','name':f'P{width}90 · Pantry, {width} × 90 in','values':{'kitchen_family':'tall','kitchen_nominal_width_in':width,'kitchen_tall_height_in':90}})
 all_data.append({'file':name,'fields':fields,'defaultStarter':default,'starters':recipes});print(name,len(fields),'settings',len(recipes),'starters')
(root/'lib/schema.json').write_text(json.dumps(all_data,indent=2))

# Bundle source with the UI so long-lived tabs do not fetch changed assets.
engine_files=list((root/'public/engine').glob('*.scad'))+[root/'public/engine/export_cabinet_bom.py']
(root/'lib/engine-sources.json').write_text(json.dumps({p.name:p.read_text() for p in sorted(engine_files) if '_v17' not in p.name and p.name not in ['parametric_shop_cart_v5.scad','parametric_utility_cabinet_v49.scad','parametric_benchtop_drawer_cabinet_v21.scad']}))
