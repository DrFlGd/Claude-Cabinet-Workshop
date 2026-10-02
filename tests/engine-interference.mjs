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
 return {logs,out};
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
 shell:{on:['show_carcass_sides','show_carcass_bottom','show_carcass_top','show_toe_kick'],code:'carcass();'},
 back:{on:['show_back_construction'],code:'carcass();'},
 shelves:{on:['show_shelves'],code:'carcass();'},
 members:{on:['show_combo_divider','show_door_hinge_partitions','show_drawer_separators','show_drawer_bank_partitions','show_mixed_bay_partitions'],code:'carcass();'},
 rails:{on:['show_drawer_slide_parts'],code:'carcass();'},
 frame:{on:[],code:'face_frame_assembly_3d();'},
 drawersA:{on:['show_drawer_slide_parts'],code:drawers(0)},
 drawersB:{on:['show_drawer_slide_parts'],code:drawers(1)},
 doors:{on:[],code:'doors();'},
};
async function overlaps(f,values){
 const files=Object.fromEntries(Object.entries(bundle).filter(([n])=>n.endsWith('.scad'))),main=schema[f].file,stl={};
 for(const [g,def] of Object.entries(GROUPS)){
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
];
for(const [f,starter,patch] of cases){
 const bad=await overlaps(f,valuesFor(f,starter,patch));
 assert.deepEqual(bad,{},`${schema[f].id}:${starter??'default'} ${JSON.stringify(patch)} has overlapping parts`);
}
console.log('Engine interference: '+cases.length+' configurations render with no overlapping parts (carcass, rear construction, shelves, partitions, rails, face frame, drawers and doors).');
