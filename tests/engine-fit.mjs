// Engine fit regression suite. Runs the production export worker (the same code the
// app uses) over every starter plus targeted configurations for previously fixed
// accuracy bugs, and checks the engine's own reports and the app's plan analysis.
import fs from 'node:fs';
import assert from 'node:assert/strict';
import os from 'node:os';
import {Worker} from 'node:worker_threads';
import ts from 'typescript';
const root=new URL('../',import.meta.url);
const read=n=>JSON.parse(fs.readFileSync(new URL(n,root)));
const schema=read('lib/schema.json'),bundle=read('lib/engine-sources.json');
const sources=Object.entries(bundle).filter(([n])=>n.endsWith('.scad')).map(([name,text])=>({name,text}));
function load(name,deps={}){
 const m={exports:{}};
 new Function('require','module','exports',ts.transpileModule(fs.readFileSync(new URL('lib/'+name+'.ts',root),'utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2022}}).outputText)(n=>deps[n],m,m.exports);
 return m.exports;
}
const {analyse}=load('analysis',{'./manufacturing':load('manufacturing')});
const {linkedChanges}=load('settings');
const configure=(f,values)=>{let s=bundle[schema[f].file];for(const fl of schema[f].fields){const v=values[fl.key];if(v!==undefined&&v!==null)s=s.replace(new RegExp('^('+fl.key+'\\s*=\\s*)[^;]+;','m'),(_m,p)=>p+JSON.stringify(v)+';')}return s};
const valuesFor=(f,starter,patch={})=>({...Object.fromEntries(schema[f].fields.map(x=>[x.key,x.value])),...schema[f].starters.find(s=>s.id===(starter??schema[f].defaultStarter)).values,...patch});
function bom(f,values,mode='bom'){
 const worker=new Worker(new URL('./section-worker.mjs',import.meta.url),{workerData:'export-worker.js'});
 return new Promise((resolve,reject)=>{
  const timer=setTimeout(()=>{worker.terminate();reject(Error('timeout'))},180000);
  worker.on('error',e=>{clearTimeout(timer);worker.terminate();reject(e)});
  worker.on('message',m=>{if(m.type==='result'||m.type==='error'){clearTimeout(timer);worker.terminate();resolve({...m,text:(m.logs??[]).join('\n')+'\n'+(typeof m.output==='string'&&mode==='bom'?m.output:'')})}});
  worker.postMessage({filename:schema[f].file,source:configure(f,values),mode,sources});
 });
}
const undefWarning=/^WARNING: (undefined operation|Ignoring unknown variable|.*could not be converted)/m;
function check(label,r,{allowErrors=[]}={}){
 assert.equal(r.type,'result',label+': '+r.error);
 assert(!undefWarning.test(r.text),label+': engine evaluated undef\n'+r.text.split('\n').filter(l=>undefWarning.test(l)).slice(0,3).join('\n'));
 const plan=analyse(r.text);
 const errors=plan.issues.filter(i=>i.severity==='error'&&!allowErrors.includes(i.code));
 assert.deepEqual(errors,[],label);
 assert(plan.cut.length>0&&plan.partCount>0,label+': empty cut list');
 return plan;
}
// 1. Every starter evaluates cleanly and every drawer box fits its opening.
const jobs=schema.flatMap((s,f)=>s.starters.map(st=>({f,id:st.id})));
let next=0;
async function lane(){while(next<jobs.length){const j=jobs[next++];check(j.f+':'+j.id,await bom(j.f,valuesFor(j.f,j.id)),{allowErrors:[]})}}
await Promise.all(Array.from({length:Math.max(1,Math.min(4,os.cpus().length))},lane));
console.log('Engine fit: all '+jobs.length+' starters evaluate without undefined values, errors or drawer-fit problems.');

// 2. Regressions for accuracy fixes.
const dims=(text,prefix)=>text.split('\n').filter(l=>l.includes(prefix));
// Standalone drawers sized from the inside used an unassigned thickness for the wood-rail length.
for(const basis of ['inside_clear','modular_grid']){
 const r=await bom(5,valuesFor(5,undefined,{drawer_design_basis:basis,drawer_mount:'wood_rails',standalone_include_fixed_wood_rails:true}));
 const plan=check('drawer '+basis+' wood rails',r);
 assert(plan.cut.some(c=>c.category==='drawer_rail'&&c.width>20),basis+': rail length');
}
check('drawer inset face',await bom(5,valuesFor(5,undefined,{drawer_face_style:'inset_flush'})));
// Enabling hinges must not drill shelf pins through the hinge plates.
for(const hinge_style of ['euro_35mm','screw_holes'])check('kitchen '+hinge_style,await bom(4,valuesFor(4,undefined,{hinge_style})));
// Stackable dado carcasses lift the bottom deliberately; no false engine warning.
assert(!/bottom plane should equal/.test((await bom(3,valuesFor(3,undefined,{joinery_style:'dado'}))).text));
// Short drawer stacks no longer overlap: boxes shrink to their openings.
{const plan=check('benchtop 6 drawers',await bom(2,valuesFor(2,'benchtop_shallow_parts_6_drawer')));assert(plan.drawers.length===6&&plan.drawers.every(d=>d.ok))}
// Slides taller than the box are reported.
{const plan=analyse((await bom(2,valuesFor(2,'benchtop_shallow_parts_6_drawer',{drawer_mount:'metal_slides'}))).text);assert(plan.issues.some(i=>i.code==='SLIDE_HEIGHT'))}
// Rear stretchers: drawer boxes and shelves stop in front of them.
{
 const r=await bom(2,valuesFor(2,'benchtop_wide_6_drawer',{back_style:'stretchers'}));
 const plan=check('benchtop stretchers',r);
 const cab=plan.outside.d,thick=Number(dims(r.text,'DIM|MATERIALS')[0].match(/CARCASS_T=([\d.]+)/)[1]);
 for(const d of plan.drawers)assert(d.box.d+1.5<=cab-thick+1e-6,'drawer behind stretchers '+d.box.d);
}
// Wood rails never run past the back of the cabinet.
{
 const r=await bom(2,valuesFor(2,undefined,{drawer_mount:'wood_rails'}));
 const plan=check('benchtop wood rails',r);
 const rail=plan.cut.find(c=>c.category==='drawer_rail');
 const setback=valuesFor(2).wood_rail_front_setback;
 assert(rail.width+setback<=plan.outside.d+1e-6,'rail '+rail.width+' + '+setback+' > '+plan.outside.d);
}
// Face frame: stiles are pocketed for the bottom/top, interior members sit behind the frame.
{
 const r=await bom(4,valuesFor(4));
 const plan=check('kitchen face frame',r);
 assert(plan.cut.some(c=>c.category==='face_frame_stile'&&/cross_pockets=bottom,top/.test(c.notes)));
 const shelf=plan.shelves[0],cab=plan.interior.d;
 assert(shelf.depth<=cab-10-6.35+1e-6,'shelf set behind the face frame');
 const drawer=plan.drawers[0],frame=dims(r.text,'DIM|FACE_FRAME|')[0];
 assert(frame&&drawer.box.h+2*drawer.vertical<=drawer.opening.h+1e-6);
}
// combo_auto rail only exists for drawer-over-door contents.
{const r=await bom(4,valuesFor(4,'kitchen_standard_FD30',{face_frame_mid_rail_mode:'combo_auto'}));check('doors with combo_auto',r);assert(!/BOM\|FF-MID\|/.test(r.text))}
// Inset doors close against door-hinge partitions instead of overlapping them.
{
 const r=await bom(1,valuesFor(1,'utility_tall_2_door_storage',{front_mount_style:'inset_flush',door_count:3}));
 const plan=check('inset doors with partitions',r);
 const t=Number(dims(r.text,'DIM|MATERIALS')[0].match(/CARCASS_T=([\d.]+)/)[1]);
 const reveal=valuesFor(1,'utility_tall_2_door_storage').front_edge_reveal;
 const total=plan.doors.reduce((a,d)=>a+d.w,0);
 const open=Number(dims(r.text,'DIM|CABINET|FRONT_OPENING')[0].match(/W=([\d.]+)/)[1]);
 assert(Math.abs(total+2*(t+2*reveal)+2*reveal-open)<0.05,'door widths leave room for two partitions');
}
// Unsupported face-frame combinations are rejected rather than drawn colliding.
assert(analyse((await bom(4,valuesFor(4,'kitchen_standard_DB324',{cabinet_layout_mode:'mixed_bays',mixed_bay_count:3}))).text).issues.some(i=>i.code==='FACE_FRAME_BAYS'));
// Fixed runners cannot travel; the UI zeroes travel when they are chosen.
assert.deepEqual(linkedChanges('slide_type','fixed_runner',{_family:6,tray_extension:450}),{tray_extension:0,preview_extension:0});
check('fixed runner stand',await bom(6,valuesFor(6,undefined,{slide_type:'fixed_runner',...linkedChanges('slide_type','fixed_runner',{_family:6})})),{allowErrors:[]});
console.log('Engine fit regressions passed: undefined drawer-rail length, hinge/shelf-pin collisions, stackable dado check, short drawer stacks, slide height, rear stretchers, rail length, face-frame pockets and setbacks, combo-only mid rail, inset partitions, unsupported bay frames, fixed runners.');
