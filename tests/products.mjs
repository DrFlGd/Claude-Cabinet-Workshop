// Products (lib/products, public/products): every starter of every product through the
// production export and render workers. Checks the engine's report (no errors, no
// undefined values), the cut layout against its placement table (one outline per part, no
// overlaps), per-sheet nesting with one outline per part per sheet, that every pocket and
// label lands inside its part, and golden snapshots (tests/golden/products/<id>.json).
// Also unit checks of the product framework: parameters parsed from the SCAD file, saved
// designs, linked settings and the editor's quick validation.
//
//   node tests/products.mjs            check
//   node tests/products.mjs --update   rewrite the snapshots (review the diff)
import fs from 'node:fs';
import os from 'node:os';
import crypto from 'node:crypto';
import assert from 'node:assert/strict';
import {Worker} from 'node:worker_threads';
import {checkCutLayout} from './cut-layout-check.mjs';
import {loadProducts,loadNesting} from './product-load.mjs';
import manifestModule from '../public/openscad/product-files.js';
const P=loadProducts(),nesting=loadNesting(),update=process.argv.includes('--update'),manifest=manifestModule;
const dir=new URL('golden/products/',import.meta.url);

// ---- framework units ----
for(const p of P.products){
 const keys=new Set(p.params.map(x=>x.key));
 for(const s of p.sections)for(const c of s.controls)assert(keys.has(c.key),`${p.id}: control ${c.key} is not a SCAD parameter`);
 for(const s of p.starters){for(const k of Object.keys(s.values))assert(keys.has(k),`${p.id}:${s.id}: ${k} is not a SCAD parameter`);assert.deepEqual(p.validate(P.productStarterValues(p,s.id)),[],`${p.id}:${s.id} fails the editor check`)}
 const v=P.productStarterValues(p,p.defaultStarter),src=P.productSource(p,{...v,width:777});
 assert(/^width = 777;/m.test(src),'width applied to the SCAD source');
 assert.deepEqual(P.parseProductValues(p,JSON.parse(P.productDesignFile(p,v,'x','mm')).values),v);
 const choice=p.params.find(x=>x.options),count=p.params.find(x=>typeof x.value==='number');
 assert.throws(()=>P.parseProductValues(p,{...v,[choice.key]:'pyramid'}),/Invalid option/);
 assert.throws(()=>P.parseProductValues(p,{...v,[count.key]:'3'}),/Invalid setting/);
 // The workers accept exactly the engine files the product sends.
 const t=P.productTarget(p);
 assert.deepEqual(t.sources.map(f=>f.name).sort(),[...manifest.files[p.file]].sort(),`${p.id}: engine files differ from public/openscad/product-files.js`);
 for(const f of t.sources)assert(t.projectFiles(v,'x','mm').some(x=>x.name===f.name&&x.data===f.text),`${p.id}: ${f.name} missing from the project download`);
 assert(manifest.frontends[p.file].includes('bom')&&p.exportModes.every(m=>manifest.frontends[p.file].includes(m)),`${p.id}: export modes not accepted by the workers`);
}
// Shop wall: every module has a starter and a starting size, choosing a module loads it,
// and settings that do not apply say why.
const sw=P.productById('shop_wall'),swParam=sw.params.find(x=>x.key==='module_type');
assert.deepEqual(sw.starters.map(s=>s.id).sort(),[...swParam.options].sort());
for(const s of sw.starters)assert(s.group&&s.values.module_type===s.id&&s.values.width>0,`shop_wall:${s.id} starter`);
const swV=P.productStarterValues(sw,'simple_shelves'),moved=sw.linked('module_type','three_drawer_cabinet',{...swV,tool_width:99});
assert.equal(moved.drawer_count,3);assert.equal(moved.width,381);assert.equal(moved.tool_width,sw.params.find(x=>x.key==='tool_width').value);
const swControl=k=>sw.sections.flatMap(x=>x.controls).find(c=>c.key===k);
assert.match(swControl('cleat_strategy').when({...swV,mount:'direct_screws'}),/French cleat/);
assert.match(swControl('cleat_strategy').when(P.productStarterValues(sw,'hook_panel')),/no side panels/);
assert.equal(swControl('cleat_strategy').when(swV),null);
assert.match(swControl('drawer_count').when(swV),/Not used/);
assert.equal(swControl('tool_width').labelFor(P.productStarterValues(sw,'router_bit_stand')),'Bit shank diameter');
assert(sw.validate({...swV,height:100,cleat_height:63.5}).some(e=>/too short|below/.test(e)),'short module with CNC hooks is refused');
assert.match(P.productTarget(sw).coupon.source(swV),/^module_type = "fit_coupon";/m);
const mc=P.productById('media_cart');
assert.deepEqual(mc.params.find(x=>x.key==='rows'),{key:'rows',value:3,section:'Body and grid',help:'',min:1,max:12,step:1});
assert.deepEqual(mc.params.find(x=>x.key==='joinery_style').options,['butt','screw','dado','tab_slot']);
assert.deepEqual(mc.linked('custom_tower','Left',P.productStarterValues(mc,'stepped_bins')),{shape:'custom',custom_tower:'None',custom_lower_cubbies:true,bin_profile:'Stepped'});
assert(mc.validate({...P.productStarterValues(mc,'sloped_bins'),columns:40}).length>0);

// ---- engine runs through the production workers ----
function run(file,source,mode,worker='export-worker.js',sources=[]){
 const w=new Worker(new URL('./section-worker.mjs',import.meta.url),{workerData:worker});
 return new Promise(resolve=>{
  const timer=setTimeout(()=>{w.terminate();resolve({type:'error',error:'timeout'})},300000);
  w.on('error',e=>{clearTimeout(timer);w.terminate();resolve({type:'error',error:String(e)})});
  w.on('message',m=>{if(m.type==='result'||m.type==='error'){clearTimeout(timer);w.terminate();resolve(m)}});
  w.postMessage({filename:file,source,mode,sources});
 });
}
const RECORD=/^ECHO: "((?:BOM|PLACE|DIM|CHECK|WARN|HARDWARE)\|.*|WARNING: .*)"\s*$/;
const recordsOf=m=>{const text=(m.logs??[]).join('\n')+'\n'+(typeof m.output==='string'?m.output:'');const out=[];for(const l of text.split(/\r?\n/)){const r=l.match(RECORD);if(r&&!out.includes(r[1]))out.push(r[1])}return {out,text}};
const finger=svg=>({sha256:crypto.createHash('sha256').update(svg).digest('hex').slice(0,24),bytes:Buffer.byteLength(svg),paths:(svg.match(/<path/g)??[]).length});
async function snapshot(p,s){
 const v=s.patched??P.productStarterValues(p,s.id),source=P.productSource(p,v),problems=[];
 const inc=P.productTarget(p).sources,go=(mode,worker)=>run(p.file,source,mode,worker,inc);
 const bom=await go('bom');
 if(bom.type!=='result')return {problems:['bom failed: '+bom.error+' '+(bom.logs??[]).slice(-3).join(' ')]};
 const {out:recs,text}=recordsOf(bom);
 for(const l of text.split('\n'))if(/^ERROR|^WARNING: (undefined|Ignoring unknown)|CHECK\|ERROR/.test(l.replace(/^ECHO: "/,'')))problems.push('engine: '+l);
 const snap={records:recs,svg:{}},kerf=v.apply_kerf_compensation?Number(v.kerf)||0:0;
 const parts=nesting.partRecords(recs),places=nesting.placementRecords(recs),nest=nesting.nest(parts,places,nesting.nestOptions(v));
 for(const mode of p.exportModes){
  const r=await go(mode);
  if(r.type!=='result'){problems.push(`${mode} failed: ${r.error}`);continue}
  const svg=r.empty?'':r.output;snap.svg[mode]=finger(svg);
  if(mode==='cut_layout'){
   problems.push(...checkCutLayout({records:recs,svg,kerf,registrationFrame:v.include_shared_export_bounding_box!==false}));
   problems.push(...nesting.checkNesting(nest,parts,svg,kerf/2).map(x=>'nesting: '+x));
   snap.sheets=nesting.nestingSummary(nest);
  }else if(svg){
   // Every pocket and label contour must move with a part onto the sheets (none dropped).
   const all=nesting.svgPolygons(svg).length,frame=v.include_shared_export_bounding_box!==false?2:0;
   // Second-face layouts are drawn turned over about the engine's flip axis.
   const axis=mode.endsWith('_flip')?Number(text.match(/FLIP\|AXIS_X=([-\d.eE]+)/)?.[1]):undefined;
   if(axis!==undefined&&!Number.isFinite(axis))problems.push(`${mode}: no FLIP|AXIS_X record`);
   const kept=nest.sheets.reduce((n,sh)=>n+nesting.sheetPolygons(svg,sh,kerf/2,axis).reduce((k,x)=>k+x.polys.length,0),0);
   if(kept!==all-frame)problems.push(`${mode}: ${all-frame-kept} contour(s) fall outside every part`);
  }
 }
 return {snap,problems};
}
// Extra configurations checked for problems only (no snapshot): paths no starter takes,
// such as dados on both faces of a wall (second-face layout on the flipped sheet).
const EXTRA={media_cart:[['double_tower',{panel_joinery:'dado'}],['shelf_cart',{panel_joinery:'dado',joinery_style:'dado',slot_corner_relief:'t_bone'}]]};
const jobs=P.products.flatMap(p=>p.starters.map(s=>({p,s})));
const extra=P.products.flatMap(p=>(EXTRA[p.id]??[]).map(([id,patch])=>({p,s:{id:id+'+'+Object.values(patch).join('+'),patched:{...P.productStarterValues(p,id),...patch}}})));
const results=new Map(),problems=[];let next=0;const started=Date.now();
const all=[...jobs,...extra];
await Promise.all(Array.from({length:Math.max(1,Math.min(4,os.cpus().length))},async()=>{while(next<all.length){const j=all[next++];const r=await snapshot(j.p,j.s);if(!j.s.patched)results.set(j.p.id+':'+j.s.id,r.snap);for(const x of r.problems)problems.push(`${j.p.id}:${j.s.id}: ${x}`)}}));
// The render worker builds the 3D assembly of each product's default starter.
for(const p of P.products){
 const r=await run(p.file,P.productSource(p,P.productStarterValues(p,p.defaultStarter)),'assembly','render-worker.js',P.productTarget(p).sources);
 if(r.type!=='result'||!(r.output?.byteLength>84))problems.push(`${p.id}: assembly render failed: ${r.error??'empty'}`);
}
let changed=0;
fs.mkdirSync(dir,{recursive:true});
for(const p of P.products){
 const file=new URL(p.id+'.json',dir),old=fs.existsSync(file)?JSON.parse(fs.readFileSync(file)):{},now={};
 for(const s of p.starters)now[s.id]=results.get(p.id+':'+s.id);
 if(update){fs.writeFileSync(file,JSON.stringify(now,null,1)+'\n');continue}
 for(const [id,snap] of Object.entries(now)){
  const was=old[id];
  if(!was){console.log(`${p.id}:${id} has no snapshot; run with --update`);changed++;continue}
  const removed=was.records.filter(x=>!snap.records.includes(x)),added=snap.records.filter(x=>!was.records.includes(x));
  const svg=Object.keys({...was.svg,...snap.svg}).filter(m=>JSON.stringify(was.svg[m])!==JSON.stringify(snap.svg[m]));
  if(removed.length||added.length||svg.length||was.sheets!==snap.sheets){changed++;console.log(`${p.id}:${id} changed${svg.length?' (SVG: '+svg.join(', ')+')':''}`);for(const x of removed.slice(0,8))console.log('  - '+x);for(const x of added.slice(0,8))console.log('  + '+x)}
 }
 for(const id of Object.keys(old))if(!now[id]){console.log(`${p.id}:${id} snapshot has no starter`);changed++}
}
for(const x of problems)console.log('problem: '+x);
const seconds=Math.round((Date.now()-started)/1000);
if(problems.length){console.log(`Products: ${problems.length} problem(s).`);process.exitCode=1}
if(update)console.log(`Products: wrote snapshots for ${jobs.length} starters in ${seconds} s.`);
else if(changed){console.log(`Products: ${changed} starter(s) differ from tests/golden/products. If intended, run node tests/products.mjs --update and review the diff.`);process.exitCode=1}
else if(!problems.length)console.log(`Products: ${jobs.length} starters of ${P.products.length} product(s) match their snapshots; cut layouts, nesting, pockets, second-face pockets and labels pass for them and ${extra.length} extra configuration(s) (${seconds} s).`);
