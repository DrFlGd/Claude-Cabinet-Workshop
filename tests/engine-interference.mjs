// Physical fit check: renders sub-assemblies of real configurations with the bundled
// OpenSCAD WASM and intersects them. Correctly fitted parts only touch (zero volume);
// any overlap means two parts in the plans would occupy the same space.
//
// Three sources of configurations, all run through the same check:
//   - CASES: hand-picked constructions that exercise every joinery and layout path;
//   - every starter of every cabinet type (--starters), with interior members split
//     out one by one wherever the design has partitions or section dividers;
//   - a seeded random sweep (--random N) that patches starters with construction
//     choices, counts and sizes the engine accepts and checks those too.
// Hardware is in: worktop, base mounting plate with casters or levelers, stack base,
// and the metal slide envelopes between the drawer boxes and the cabinet.
//
//   node tests/engine-interference.mjs                 the hand-picked cases
//   node tests/engine-interference.mjs --starters      plus all 110 starters
//   node tests/engine-interference.mjs --random 24     plus 24 random designs
//   node tests/engine-interference.mjs --all           cases + starters + 24 random
//   SHARD=1/4 node tests/engine-interference.mjs --all  one quarter of that job list
//   CASES='[[4,"kitchen_standard_B36",{}]]' node ...   ad-hoc configurations
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
// Axis-aligned extent of a binary STL; pairs whose extents do not meet are not intersected.
function extent(buf){
 const dv=new DataView(buf.buffer,buf.byteOffset,buf.byteLength),n=dv.getUint32(80,true),lo=[Infinity,Infinity,Infinity],hi=[-Infinity,-Infinity,-Infinity];
 for(let i=0;i<n;i++){const o=84+i*50+12;for(let k=0;k<9;k++){const v=dv.getFloat32(o+k*4,true),a=k%3;if(v<lo[a])lo[a]=v;if(v>hi[a])hi[a]=v}}
 return {lo,hi};
}
const extentsMeet=(a,b)=>[0,1,2].every(k=>a.lo[k]<b.hi[k]-0.01&&b.lo[k]<a.hi[k]-0.01);
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
 // Hardware and accessories.
 worktop:{on:['show_worktop'],code:'carcass();'},
 base:{on:['show_base_hardware'],code:'carcass();'},
 stackBase:{on:['show_stack_base'],code:'carcass();'},
 // The slide envelope is the space a metal slide needs between the drawer box and the
 // cabinet side or partition; nothing else may enter it.
 slideEnvelopes:{on:['show_drawer_slide_parts'],envelopes:true,code:'carcass();',when:v=>v.drawer_mount==='metal_slides'},
};
// The standalone drawer renders drawer boxes only.
const DRAWER_GROUPS={drawersA:GROUPS.drawersA,drawersB:GROUPS.drawersB};
// The equipment stand has its own engine; its parts are grouped by kind from its part table.
const standGroup=kinds=>({code:`for(p=parts) if(${kinds.map(k=>`p[1]=="${k}"`).join('||')}) if(p[1]=="runner") translate([0,0,tz(p[5])-runner_height]) assemble_part(p); else assemble_part(p);`});
const STAND_GROUPS={
 sides:standGroup(['side']),horizontals:standGroup(['horizontal']),trays:standGroup(['tray','lip']),cheeks:standGroup(['cheek']),
 backs:standGroup(['back','structural','applied']),runners:standGroup(['runner']),cleats:standGroup(['cleat_stand','cleat_wall']),backers:standGroup(['backer','spacer','shim']),
 slides:{code:'if(slide_type=="side_mount") for(i=[0:N-1]) for(s=[0:1]) { translate([s==0 ? t : W-t-sg,tray_inset+metal_slide_front_setback,slide_z(i)-metal_slide_envelope_height/2]) cube([sg/2,metal_slide_length,metal_slide_envelope_height]); translate([s==0 ? t+sg/2 : W-t-sg/2,tray_inset+metal_slide_front_setback-ext,slide_z(i)-metal_slide_envelope_height/2]) cube([sg/2,metal_slide_length,metal_slide_envelope_height]); }'},
};
const files0=Object.fromEntries(Object.entries(bundle).filter(([n])=>n.endsWith('.scad')));
const isStand=f=>schema[f].id==='equipment_stand',isDrawer=f=>schema[f].id==='drawer';
// Engine report of a design (bom mode): LAYOUT records, CHECK records and OpenSCAD messages.
async function report(f,values){
 const files={...files0},main=schema[f].file;
 files[main]=configure(f,{...values,output_mode:'bom'});
 const r=await scad(files,main,['-o','/o.echo']);
 const t=r.echo+'\n'+r.logs.join('\n');
 return {text:t,errors:[...t.matchAll(/CHECK\|ERROR\|([A-Z_]+)/g)].map(m=>m[1]),broken:r.logs.filter(l=>/^ERROR|^WARNING: (undefined operation|Ignoring unknown variable)/.test(l))};
}
// Interior members of bay and section layouts, from the engine's LAYOUT report.
function members(t){
 const ids=re=>[...new Set([...t.matchAll(re)].map(m=>+m[1]-1))];
 return {vm:ids(/LAYOUT\|MEMBER\|MB(\d+)/g),hm:ids(/LAYOUT\|MEMBER\|SD(\d+)/g),fs:ids(/LAYOUT\|SHELF\|B(\d+)-SH\d+\|[^"]*STYLE=fixed/g)};
}
async function overlaps(f,values,split=false,text){
 const files={...files0},main=schema[f].file,stl={},ext={};
 const groups=isStand(f)?{...STAND_GROUPS}:isDrawer(f)?{...DRAWER_GROUPS}:{...GROUPS};
 if(split&&!isStand(f)&&!isDrawer(f)){
  // Each partition, section divider and bay's fixed shelves on its own, so members
  // that meet from opposite faces of another member are checked against each other.
  const m=members(text??(await report(f,values)).text);
  groups.verticals={on:['show_door_hinge_partitions','show_drawer_bank_partitions'],code:'carcass();'};
  groups.horizontals={on:['show_drawer_separators'],code:'carcass();'};
  groups.shelves={on:[],code:'for (b=[0:layout_bay_count-1]) if (mixed_bay_has_adjustable_shelves(b)) for (s=[1:mixed_bay_shelf_count(b)]) mixed_bay_adjustable_shelf_3d(b,mixed_bay_shelf_z(b,s));'};
  for(const p of m.vm)groups['partition'+p]={on:[],code:`mixed_bay_partition_3d(${p});`};
  for(const h of m.hm)groups['divider'+h]={on:[],code:`section_divider_3d(${h});`};
  for(const b of m.fs)groups['fixedShelves'+b]={on:[],code:`for (s=[1:mixed_bay_shelf_count(${b})]) mixed_bay_fixed_shelf_3d(${b},mixed_bay_shelf_z(${b},s),s);`};
  assert(m.vm.length+m.hm.length+m.fs.length>0,'split check found no members');
 }
 for(const [g,def] of Object.entries(groups)){
  if(def.when&&!def.when(values))continue;
  // Probe mode renders nothing of its own; the appended code renders one group. The
  // equipment stand renders its flat layout for any mode but bom, so bom is its probe.
  const v={...values,output_mode:isStand(f)?'bom':'__probe__',show_metal_slide_envelopes:!!def.envelopes};
  for(const k of FLAGS)if(schema[f].fields.some(x=>x.key===k))v[k]=(def.on??[]).includes(k);
  files[main]=configure(f,v)+'\n'+def.code+'\n';
  const r=await scad(files,main,['--export-format=binstl','-o','/o.stl']);
  assert(!r.logs.some(l=>/^ERROR|^WARNING: (undefined operation|Ignoring unknown variable)/.test(l)),g+': '+r.logs.filter(l=>/ERROR|WARNING/.test(l)).slice(0,3).join(' '));
  if(r.out&&r.out.length>84){stl[g]=r.out;ext[g]=extent(r.out)}
 }
 const names=Object.keys(stl),bad={};let pairs=0;
 for(let i=0;i<names.length;i++)for(let j=i+1;j<names.length;j++){
  if(!extentsMeet(ext[names[i]],ext[names[j]]))continue;
  pairs++;
  const r=await scad({'a.stl':stl[names[i]],'b.stl':stl[names[j]],'i.scad':'intersection(){import("/a.stl");import("/b.stl");}'},'i.scad',['--export-format=binstl','-o','/o.stl']);
  const v=volume(r.out)/1000;if(v>0.05)bad[names[i]+'×'+names[j]]=+v.toFixed(2);
 }
 return {bad,groups:names.length,pairs};
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
const CASES=[
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
 // Hardware: worktop with registration, casters on a mounting plate, levelers, stack base, metal slide envelopes.
 [0,undefined,{include_worktop:true,include_worktop_registration_holes:true,include_base_mounting_plate:true,base_style:'casters'}],
 [1,undefined,{base_style:'levelers',include_base_mounting_plate:true,include_base_hardware_drill_holes:true}],
 [3,undefined,{include_stack_base:true,drawer_mount:'metal_slides'}],
 [2,'benchtop_wide_6_drawer',{drawer_mount:'metal_slides',include_metal_slide_holes:true}],
];
// ---- random sweep: construction choices, counts and sizes the engine accepts ----
function rng(seed){let a=seed>>>0;return()=>{a=(a+0x6D2B79F5)>>>0;let t=a;t=Math.imul(t^(t>>>15),t|1);t^=t+Math.imul(t^(t>>>7),t|61);return((t^(t>>>14))>>>0)/4294967296}}
const CHOICES=['cabinet_contents','top_style','back_style','joinery_style','tab_count_mode','drawer_joinery_style','drawer_bottom_joinery','front_mount_style','shelf_style','drawer_height_mode','drawer_separator_style','hinge_style','single_door_hinge_side','drawer_mount','base_style','cabinet_mount_style','module_type','front_facing_style','face_frame_mid_rail_mode','face_frame_construction','drawer_bank_layout_mode','drawer_bank_partition_joinery','side_style','brace_style','slide_type','mount_mode'];
const TOGGLES=['include_drawer_separators','include_door_hinge_partitions','include_mixed_bay_partitions','include_face_frame_center_stile','include_worktop','include_worktop_registration_holes','include_base_mounting_plate','include_stack_base','include_drawer_faces','include_drawer_divider_grid','include_metal_slide_holes','include_toe_kick'];
const COUNTS={drawer_count:[1,6],door_count:[1,3],door_shelf_count:[0,3],drawer_bank_count:[1,3],back_stretcher_count:[1,3],tray_count:[1,4]};
const SIZES={custom_cabinet_width:[300,1500],custom_cabinet_height:[300,2000],custom_cabinet_depth:[250,700]};
function randomDesign(random){
 const f=Math.floor(random()*schema.length),fam=schema[f],keys=new Set(fam.fields.map(x=>x.key));
 const starter=fam.starters[Math.floor(random()*fam.starters.length)].id,patch={};
 const pick=list=>list[Math.floor(random()*list.length)];
 const field=k=>fam.fields.find(x=>x.key===k);
 const n=2+Math.floor(random()*5);
 for(let i=0;i<n;i++){
  const kind=random();
  if(kind<0.5){const k=pick(CHOICES.filter(k=>keys.has(k)));if(k)patch[k]=pick(field(k).options)}
  else if(kind<0.7){const k=pick(TOGGLES.filter(k=>keys.has(k)));if(k)patch[k]=random()<0.5}
  else if(kind<0.9){const k=pick(Object.keys(COUNTS).filter(k=>keys.has(k)));if(k){const [a,b]=COUNTS[k];patch[k]=a+Math.floor(random()*(b-a+1))}}
  else{const k=pick(Object.keys(SIZES).filter(k=>keys.has(k)));if(k){const [a,b]=SIZES[k];patch[k]=Math.round(a+random()*(b-a))}}
 }
 return [f,starter,patch];
}
// ---- job list ----
const argv=process.argv.slice(2),flag=n=>argv.includes(n),after=n=>{const i=argv.indexOf(n);return i>=0?argv[i+1]:undefined};
const only=process.env.CASES?JSON.parse(process.env.CASES):null;
let jobs=only?only.map(c=>({label:'case',f:c[0],starter:c[1],patch:c[2]??{},split:!!c[3]})):CASES.map(c=>({label:'case',f:c[0],starter:c[1],patch:c[2],split:!!c[3]}));
if(!only&&(flag('--starters')||flag('--all')))for(let f=0;f<schema.length;f++)for(const s of schema[f].starters)jobs.push({label:'starter',f,starter:s.id,patch:{},split:'auto'});
const randomCount=flag('--all')?24:Number(after('--random')??0);
if(!only&&randomCount>0){const random=rng(Number(process.env.SEED??20261015));let made=0,tries=0;while(made<randomCount&&tries<randomCount*4){tries++;const [f,starter,patch]=randomDesign(random);jobs.push({label:'random',f,starter,patch,split:'auto',optional:true});made++}}
if(process.env.SHARD){const [i,n]=process.env.SHARD.split('/').map(Number);jobs=jobs.filter((_,k)=>k%n===i-1)}
// ---- run ----
const started=Date.now();let failures=0,checked=0,skipped=0,pairs=0;
for(const j of jobs){
 const values=valuesFor(j.f,j.starter,j.patch),name=`${schema[j.f].id}:${j.starter??'default'} ${JSON.stringify(j.patch)}`;
 let split=j.split,text;
 if(j.optional||split==='auto'){
  const r=await report(j.f,values);text=r.text;
  if(j.optional&&(r.errors.length||r.broken.length)){skipped++;console.log(`skip ${name}: engine rejects it (${[...r.errors,...r.broken].slice(0,2).join('; ')})`);continue}
  if(split==='auto'){const m=members(text);split=m.vm.length+m.hm.length+m.fs.length>0}
 }
 try{
  const r=await overlaps(j.f,values,split,text);
  checked++;pairs+=r.pairs;
  if(Object.keys(r.bad).length){failures++;console.log(`FAIL ${name}: overlapping parts ${JSON.stringify(r.bad)} cm³`)}
 }catch(e){failures++;console.log(`FAIL ${name}: ${e.message}`)}
}
const seconds=Math.round((Date.now()-started)/1000);
if(failures){console.log(`Engine interference: ${failures} of ${checked} configurations have overlapping parts or failed to render (${seconds} s).`);process.exitCode=1}
else console.log(`Engine interference: ${checked} configurations render with no overlapping parts (${pairs} group pairs intersected${skipped?`, ${skipped} random designs skipped as rejected by the engine`:''}; carcass, interior members, rails, face frame, drawers, doors, worktop, base hardware, stack base and slide envelopes; ${seconds} s).`);
