// Physical fit check: renders sub-assemblies of real configurations with the bundled
// OpenSCAD WASM and intersects them. Correctly fitted parts only touch (zero volume);
// any overlap means two parts in the plans would occupy the same space.
import fs from 'node:fs';
import assert from 'node:assert/strict';
const root=new URL('../',import.meta.url);
const read=n=>JSON.parse(fs.readFileSync(new URL(n,root)));
const schema=read('lib/schema.json'),bundle=read('lib/engine-sources.json');
globalThis.self??={location:{href:'http://test/openscad/x.js'}};
globalThis.fetch=async url=>{const p=new URL(String(url),'http://test').pathname;try{return new Response(fs.readFileSync(new URL('public'+p,root)),{headers:{'Content-Type':p.endsWith('.wasm')?'application/wasm':'text/plain'}})}catch{return new Response('',{status:404})}};
const {default:OpenSCAD}=await import(new URL('public/openscad/openscad.js',root).href);
async function scad(files,main,args){
 const logs=[];const e=await OpenSCAD({noInitialRun:true,locateFile:p=>'http://test/openscad/'+p,print:l=>logs.push(String(l)),printErr:l=>logs.push(String(l))});
 for(const [n,d] of Object.entries(files)){const dir='/'+n.split('/').slice(0,-1).join('/');if(dir!=='/')e.FS.mkdirTree(dir);e.FS.writeFile('/'+n,d)}
 try{e.callMain(['/'+main,'--backend=Manifold',...args])}catch{}
 let out=null;try{out=e.FS.readFile('/o.stl')}catch{}
 let echo='';try{echo=e.FS.readFile('/o.echo',{encoding:'utf8'})}catch{}
 return {logs,out,echo};
}
function volume(buf){
 if(!buf||buf.length<84)return 0;const dv=new DataView(buf.buffer,buf.byteOffset,buf.byteLength),n=dv.getUint32(80,true);let v=0;
 for(let i=0;i<n;i++){const o=84+i*50+12,p=[];for(let k=0;k<9;k++)p.push(dv.getFloat32(o+k*4,true));v+=(p[0]*(p[4]*p[8]-p[5]*p[7])-p[1]*(p[3]*p[8]-p[5]*p[6])+p[2]*(p[3]*p[7]-p[4]*p[6]))/6}
 return Math.abs(v);
}
const configure=(f,values)=>{let s=bundle[schema[f].file];for(const fl of schema[f].fields){const v=values[fl.key];if(v!==undefined&&v!==null)s=s.replace(new RegExp('^('+fl.key+'\\s*=\\s*)[^;]+;','m'),(_m,p)=>p+JSON.stringify(v)+';')}return s};
const FLAGS=['show_carcass_sides','show_carcass_bottom','show_carcass_top','show_toe_kick','show_base_hardware','show_worktop','show_back_construction','show_combo_divider','show_shelves','show_door_hinge_partitions','show_drawer_separators','show_drawer_bank_partitions','show_mixed_bay_partitions','show_drawer_slide_parts','show_stack_base'];
const drawers=parity=>`if (has_drawers) for (b=[0:active_drawer_bank_count()-1]) if (drawer_bank_drawer_count(b) > 0) for (i=[0:drawer_bank_drawer_count(b)-1]) if ((i+b)%2==${parity}) { drawer_box(i,b); if (show_drawer_slide_parts) drawer_mounted_wood_slides(i,b); }`;
const GROUPS={
 sides:{on:['show_carcass_sides'],code:'carcass();'},
 caps:{on:['show_carcass_bottom','show_carcass_top','show_toe_kick'],code:'carcass();'},
 back:{on:['show_back_construction'],code:'carcass();'},
 shelves:{on:['show_shelves'],code:'carcass();'},
 // Horizontal and vertical interior members are separate groups so partition tabs and
 // tongues are checked against the divider and separators that receive them.
 horizontals:{on:['show_combo_divider','show_drawer_separators'],code:'carcass();'},
 verticals:{on:['show_door_hinge_partitions','show_drawer_bank_partitions','show_mixed_bay_partitions'],code:'carcass();'},
 rails:{on:['show_drawer_slide_parts'],code:'carcass();'},
 frame:{on:[],code:'face_frame_assembly_3d();'},
 drawersA:{on:['show_drawer_slide_parts'],code:drawers(0)},
 drawersB:{on:['show_drawer_slide_parts'],code:drawers(1)},
 doors:{on:[],code:'doors();'},
};
// Interior members of bay and section layouts, from the engine's LAYOUT report.
async function members(f,values){
 const files=Object.fromEntries(Object.entries(bundle).filter(([n])=>n.endsWith('.scad'))),main=schema[f].file;
 files[main]=configure(f,{...values,output_mode:'bom'});
 const t=(await scad(files,main,['-o','/o.echo'])).echo;
 const ids=re=>[...new Set([...t.matchAll(re)].map(m=>+m[1]-1))];
 return {vm:ids(/LAYOUT\|MEMBER\|MB(\d+)/g),hm:ids(/LAYOUT\|MEMBER\|SD(\d+)/g),fs:ids(/LAYOUT\|SHELF\|B(\d+)-SH\d+\|[^"]*STYLE=fixed/g)};
}
async function overlaps(f,values,split=false){
 const files=Object.fromEntries(Object.entries(bundle).filter(([n])=>n.endsWith('.scad'))),main=schema[f].file,stl={};
 const groups={...GROUPS};
 if(split){
  // Each partition, section divider and bay's fixed shelves on its own, so members
  // that meet from opposite faces of another member are checked against each other.
  const m=await members(f,values);
  groups.verticals={on:['show_door_hinge_partitions','show_drawer_bank_partitions'],code:'carcass();'};
  groups.horizontals={on:['show_drawer_separators'],code:'carcass();'};
  groups.shelves={on:[],code:'for (b=[0:layout_bay_count-1]) if (mixed_bay_has_adjustable_shelves(b)) for (s=[1:mixed_bay_shelf_count(b)]) mixed_bay_adjustable_shelf_3d(b,mixed_bay_shelf_z(b,s));'};
  for(const p of m.vm)groups['partition'+p]={on:[],code:`mixed_bay_partition_3d(${p});`};
  for(const h of m.hm)groups['divider'+h]={on:[],code:`section_divider_3d(${h});`};
  for(const b of m.fs)groups['fixedShelves'+b]={on:[],code:`for (s=[1:mixed_bay_shelf_count(${b})]) mixed_bay_fixed_shelf_3d(${b},mixed_bay_shelf_z(${b},s),s);`};
  assert(m.vm.length+m.hm.length+m.fs.length>0,'split check found no members');
 }
 for(const [g,def] of Object.entries(groups)){
  const v={...values,output_mode:'__probe__',show_metal_slide_envelopes:false};
  for(const k of FLAGS)if(schema[f].fields.some(x=>x.key===k))v[k]=def.on.includes(k);
  files[main]=configure(f,v)+'\n'+def.code+'\n';
  const r=await scad(files,main,['--export-format=binstl','-o','/o.stl']);
  assert(!r.logs.some(l=>/^ERROR|^WARNING: (undefined operation|Ignoring unknown variable)/.test(l)),g+': '+r.logs.filter(l=>/ERROR|WARNING/.test(l)).slice(0,3).join(' '));
  if(r.out&&r.out.length>84)stl[g]=r.out;
 }
 const names=Object.keys(stl),bad={};
 for(let i=0;i<names.length;i++)for(let j=i+1;j<names.length;j++){
  const r=await scad({'a.stl':stl[names[i]],'b.stl':stl[names[j]],'i.scad':'intersection(){import("/a.stl");import("/b.stl");}'},'i.scad',['--export-format=binstl','-o','/o.stl']);
  const v=volume(r.out)/1000;if(v>0.05)bad[names[i]+'×'+names[j]]=+v.toFixed(2);
 }
 return bad;
}
// Section trees: a 2x2 grid whose dividers meet a partition (or divider) from both
// faces at the same place, and a nested layout with doors, open shelves and a rail.
function grid(axis){
 const r=(parent,order,kind,contents='open',count=0,shelves=0,hinge='left',style='adjustable')=>[parent,order,kind,'weight',1,contents,count,'equal',.25,Array(Math.max(1,contents==='drawers'?count:1)).fill(1),'panel',shelves,hinge,style];
 const other=axis==='x'?'z':'x';
 return [r(-1,0,axis),r(0,0,other),r(0,1,other),r(1,0,'leaf','drawers',2),r(1,1,'leaf','doors',1,1,'left','fixed'),r(2,0,'leaf','drawers',2),r(2,1,'leaf','doors',1,2,'right','adjustable')];
}
const nested=[
 [-1,0,'x','weight',1,'open',0,'equal',.25,[1],'panel',0,'left','adjustable'],
 [0,0,'leaf','weight',2,'doors',2,'equal',.25,[1],'panel',2,'left','adjustable'],
 [0,1,'z','weight',1,'open',0,'equal',.25,[1],'rail',0,'left','adjustable'],
 [2,0,'leaf','weight',1,'drawers',3,'equal',.25,[1,1,1],'panel',0,'left','adjustable'],
 [2,1,'x','weight',1,'open',0,'equal',.25,[1],'panel',0,'left','adjustable'],
 [4,0,'leaf','weight',1,'open',2,'equal',.25,[1],'panel',0,'left','fixed'],
 [4,1,'leaf','weight',1,'doors',1,'equal',.25,[1],'panel',1,'right','adjustable'],
];
const valuesFor=(f,starter,patch={})=>({...Object.fromEntries(schema[f].fields.map(x=>[x.key,x.value])),...schema[f].starters.find(s=>s.id===(starter??schema[f].defaultStarter)).values,...patch});
const cases=[
 [0,undefined,{}],[0,undefined,{drawer_mount:'metal_slides',back_style:'stretchers'}],
 [1,undefined,{}],[1,'utility_tall_2_door_storage',{front_mount_style:'inset_flush',door_count:3,door_shelf_count:2}],
 [2,'benchtop_shallow_parts_6_drawer',{}],[2,'benchtop_wide_6_drawer',{back_style:'stretchers'}],[2,undefined,{drawer_mount:'wood_rails'}],
 [3,undefined,{}],[3,undefined,{joinery_style:'dado'}],
 [4,undefined,{}],[4,undefined,{shelf_style:'fixed',door_shelf_count:2,include_drawer_separators:true,drawer_count:2}],
 [4,'kitchen_standard_B36',{cabinet_contents:'doors',door_count:3,include_door_hinge_partitions:true}],
 [4,'kitchen_standard_B30',{include_face_frame_center_stile:true,front_mount_style:'inset_flush'}],
 [4,'kitchen_standard_DB324',{}],
 // Combo contents: partitions joined to a divider that is set back behind the face frame or inset fronts.
 [4,'kitchen_standard_B36',{cabinet_contents:'combo',drawer_bank_count:3,door_count:3,include_door_hinge_partitions:true,joinery_style:'tab_slot'}],
 [4,'kitchen_standard_B36',{cabinet_contents:'combo',front_mount_style:'inset_flush',joinery_style:'dado',drawer_bank_count:4,door_count:3,include_door_hinge_partitions:true,include_drawer_faces:false,face_frame_mid_rail_mode:'none'}],
 // Door region set by the layout editor (combo_door_height), overlay and inset behind a face frame.
 [1,undefined,{combo_door_height:400}],
 [4,'kitchen_standard_B36',{combo_door_height:450,front_mount_style:'inset_flush'}],
 // Bay and section layouts, every interior member checked on its own (fourth entry).
 // Fixed shelves at equal heights on both faces of a partition share half-length tabs.
 [0,'shop_cart_open_service_cart',{joinery_style:'tab_slot'},true],
 [4,'photo_section_cabinet',{},true],
 [0,undefined,{cabinet_layout_mode:'sections',section_nodes:grid('x'),joinery_style:'tab_slot',drawer_mount:'wood_rails'},true],
 [1,undefined,{cabinet_layout_mode:'sections',section_nodes:grid('z'),joinery_style:'dado',top_style:'full',back_style:'stretchers',hinge_style:'euro_35mm',drawer_mount:'metal_slides',include_metal_slide_holes:true},true],
 [4,'photo_section_cabinet',{section_nodes:nested,front_facing_style:'face_frame',front_mount_style:'inset_flush',joinery_style:'tab_slot',hinge_style:'euro_35mm'},true],
];
const only=process.env.CASES?JSON.parse(process.env.CASES):null;
for(const [f,starter,patch,split] of only??cases){
 const bad=await overlaps(f,valuesFor(f,starter,patch),split);
 assert.deepEqual(bad,{},`${schema[f].id}:${starter??'default'} ${JSON.stringify(patch)} has overlapping parts`);
}
console.log('Engine interference: '+(only??cases).length+' configurations render with no overlapping parts (carcass sides, bottom/top, rear construction, shelves, dividers, partitions, rails, face frame, drawers and doors).');
