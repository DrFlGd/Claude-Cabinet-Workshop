"""Geometry isolation checks through real part entry points, not mocked cutters."""
from pathlib import Path
import tempfile,subprocess,hashlib,re
root=Path.cwd();scad=root/'public/engine/v5/src/modular_organization/data/scad/kitchen.scad'
with tempfile.TemporaryDirectory(dir=root,prefix='.relief-test-') as work:
 work=Path(work)
 def shape(name,geometry,drawer=3,carcass=6,divider=2,bottom=2,mode='dogbone'):
  source=f'''include <{scad.as_posix()}>;
output_mode="bom";
slot_corner_relief="dogbone";
carcass_slot_corner_relief="dogbone";carcass_cnc_tool_diameter={carcass};
drawer_slot_corner_relief="{mode}";drawer_cnc_tool_diameter={drawer};
divider_slot_corner_relief="dogbone";divider_cnc_tool_diameter={divider};
drawer_bottom_slot_corner_relief="dogbone";drawer_bottom_cnc_tool_diameter={bottom};
drawer_joinery_style="tab_slot";
include_drawer_divider_grid=true;
drawer_divider_mounting="bottom_and_perimeter";
{geometry}
'''
  p=work/(name+'.scad');p.write_text(source);out=p.with_suffix('.svg');r=subprocess.run(['openscad','-o',str(out),str(p)],capture_output=True,text=True,timeout=30)
  assert r.returncode==0,r.stderr
  assert not re.search(r'^ERROR:|ECHO: "ERROR\||CHECK\|ERROR',r.stderr,re.M),r.stderr
  return out.read_bytes()
 for material,geometry,param in [('carcass','slot_shape_2d(20,30);','carcass'),('drawer','drawer_side_tab_slots_2d(250,100);','drawer'),('divider','drawer_divider_longitudinal_cut();','divider'),('bottom','drawer_divider_bottom_grooves_2d();','bottom')]:
  baseline=shape(material,geometry)
  changed=shape(material+'-changed',geometry,**{param:8})
  assert baseline!=changed,material+' tool did not affect geometry'
  other='carcass' if material!='carcass' else 'drawer'
  unrelated=shape(material+'-isolated',geometry,**{other:10})
  assert baseline==unrelated,material+' changed with unrelated cutter'
  print(material,'cutter isolation passed')
 assert shape('drawer-none','drawer_side_tab_slots_2d(250,100);',mode='none')!=shape('drawer-tbone','drawer_side_tab_slots_2d(250,100);',mode='t_bone')
 print('Drawer none/T-bone geometry differs as expected')
