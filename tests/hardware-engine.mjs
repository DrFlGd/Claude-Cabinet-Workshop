// The Hardware view against the engine: for every starter of the five cabinet types with a
// layout, switched to metal slides and 35 mm cup hinges, the drilling the view draws must be the
// drilling the engine reports.
//  - every slide row in the engine's side-panel feature ledger belongs to a drawer of the plan,
//    and the holes worked out from the settings (the view's estimate) are the engine's holes;
//  - every hinge mounting plate on a side sits at a cup height of a door hinged on that side;
//  - the door fixing-hole offset moves the fixing holes in the cut layout toward the door center.
//   node tests/hardware-engine.mjs        (FAMILIES=1 STARTERS=a,b for a subset)
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import {Worker} from 'node:worker_threads';
import ts from 'typescript';
const root=new URL('../',import.meta.url),rootPath=root.pathname;
const read=n=>JSON.parse(fs.readFileSync(new URL(n,root)));
const schema=read('lib/schema.json'),bundle=read('lib/engine-sources.json');
const sources=Object.entries(bundle).filter(([n])=>n.endsWith('.scad')).map(([name,text])=>({name,text}));
// The app's TypeScript modules, transpiled the way the other Node suites load them.
const cache=new Map();
function load(file){
 if(cache.has(file))return cache.get(file).exports;
 const m={exports:{}};cache.set(file,m);
 const req=n=>{const p=path.resolve(path.dirname(file),n);if(n.endsWith('.json'))return JSON.parse(fs.readFileSync(p));return load(fs.existsSync(p+'.ts')?p+'.ts':p)};
 new Function('require','module','exports',ts.transpileModule(fs.readFileSync(file,'utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2022,esModuleInterop:true}}).outputText)(req,m,m.exports);
 return m.exports;
}
const H=load(rootPath+'lib/hardware.ts'),A=load(rootPath+'lib/analysis.ts');
const configure=(f,values)=>{let s=bundle[schema[f].file];for(const fl of schema[f].fields){const v=values[fl.key];if(v!==undefined&&v!==null)s=s.replace(new RegExp('^('+fl.key+'\\s*=\\s*)[^;]+;','m'),(_m,p)=>p+JSON.stringify(v)+';')}return s};
function run(f,values,mode){
 const worker=new Worker(new URL('./section-worker.mjs',import.meta.url),{workerData:'export-worker.js'});
 return new Promise(resolve=>{
  const timer=setTimeout(()=>{worker.terminate();resolve({type:'error',error:'timeout'})},300000);
  worker.on('error',e=>{clearTimeout(timer);worker.terminate();resolve({type:'error',error:String(e)})});
  worker.on('message',m=>{if(m.type==='result'||m.type==='error'){clearTimeout(timer);worker.terminate();resolve(m)}});
  worker.postMessage({filename:schema[f].file,source:configure(f,values),mode,report:'verbose',sources});
 });
}
const HARDWARE={drawer_mount:'metal_slides',include_metal_slide_holes:true,hinge_style:'euro_35mm',hinge_plate_holes_enabled:true,hinge_door_fixing_enabled:true};
const families=(process.env.FAMILIES??'0,1,2,3,4').split(',').map(Number),only=process.env.STARTERS?new Set(process.env.STARTERS.split(',')):null;
const jobs=[];
for(const f of families)for(const s of schema[f].starters)if(!only||only.has(s.id))jobs.push({f,id:s.id,values:{...Object.fromEntries(schema[f].fields.map(x=>[x.key,x.value])),...s.values,...HARDWARE,_family:f}});
const problems=[];let slideRows=0,plates=0;
async function check({f,id,values}){
 const out=await run(f,values,'bom');
 if(out.type!=='result'){problems.push(`${f}/${id}: engine ${out.error}`);return}
 const text=(out.logs??[]).join('\n')+'\n'+(out.output??''),plan=A.analyse(text),features=H.sideFeatures(A.records(text));
 const drawers=H.drawerRefs(plan),doors=H.doorRefs(plan);
 for(const part of ['CS-L','CS-R']){
  const side=plan.cut.find(c=>c.ids.includes(part));if(!side)continue;
  const engine=H.cabinetSlideRows(values,features,drawers,part,side.width).filter(r=>r.engine);
  const estimate=H.cabinetSlideRows(values,[],drawers,part,side.width);
  for(const r of engine){
   slideRows++;
   if(!r.drawer){problems.push(`${f}/${id} ${part}: slide row ${r.id} at ${r.z} matches no drawer`);continue}
   const e=estimate.find(x=>x.drawer===r.drawer);
   const same=e&&e.holes.length===r.holes.length&&e.holes.every((h,i)=>Math.abs(h.y-r.holes[i].y)<0.01&&Math.abs(h.z-r.holes[i].z)<0.01&&Math.abs(h.d-r.holes[i].d)<0.01);
   if(!same)problems.push(`${f}/${id} ${part}: drawer ${r.drawer} engine holes ${JSON.stringify(r.holes.map(h=>[h.y,h.z]))} vs view ${JSON.stringify(e?.holes.map(h=>[h.y,h.z]))}`);
  }
  for(const p of H.cabinetHingePlates(features,part)){
   plates++;
   const door=doors.find(d=>(d.hinge==='left')===(part==='CS-L')&&H.hingeHeights(values,d.h).some(z=>Math.abs(d.z+z-p.z)<0.05));
   if(!door)problems.push(`${f}/${id} ${part}: mounting plate ${p.id} at ${p.z} is level with no cup of a door hinged on that side`);
  }
 }
}
const queue=[...jobs],workers=Math.max(1,Math.min(os.availableParallelism?.()??os.cpus().length,6));
await Promise.all(Array.from({length:workers},async()=>{while(queue.length)await check(queue.shift())}));
// Fixing-hole offset in the door cut layout: every 3 mm fixing hole moves 9.5 mm toward the door center.
const doorStarter={...Object.fromEntries(schema[1].fields.map(x=>[x.key,x.value])),...schema[1].starters.find(s=>s.id==='utility_door_base').values,...HARDWARE,_family:1};
const holes=svg=>{const out=[];for(const d of svg.match(/d="([^"]+)"/g)??[])for(const sub of d.slice(3,-1).split(/(?=M)/)){const n=(sub.match(/-?[0-9.]+(?:e-?\d+)?/g)??[]).map(Number);if(n.length<4)continue;const xs=n.filter((_,i)=>i%2===0),ys=n.filter((_,i)=>i%2);const w=Math.max(...xs)-Math.min(...xs),h=Math.max(...ys)-Math.min(...ys);if(w>2.5&&w<3.5&&h>2.5&&h<3.5)out.push([(Math.max(...xs)+Math.min(...xs))/2,(Math.max(...ys)+Math.min(...ys))/2])}return out.sort((a,b)=>a[1]-b[1]||a[0]-b[0])};
const [a,b]=await Promise.all([0,9.5].map(o=>run(1,{...doorStarter,hinge_door_fixing_hole_offset:o},'cut_layout')));
if(a.type!=='result'||b.type!=='result')problems.push('door cut layout: '+(a.error??b.error));
else{
 const h0=holes(a.output),h1=holes(b.output),moved=h0.map((p,i)=>Math.abs(Math.abs(h1[i][0]-p[0])-9.5)<0.01&&Math.abs(h1[i][1]-p[1])<0.01);
 if(!h0.length||h0.length!==h1.length||moved.includes(false))problems.push(`door cut layout: fixing holes did not move 9.5 mm (${JSON.stringify(h0)} → ${JSON.stringify(h1)})`);
 // toward the door center: holes left of a door's middle move right, and the reverse
 const xs=h0.map(p=>p[0]),mid=(Math.min(...xs)+Math.max(...xs))/2;
 if(h0.some((p,i)=>(h1[i][0]-p[0])*(mid-p[0])<=0))problems.push('door cut layout: a fixing hole moved toward the hinge edge');
}
console.log(`${jobs.length} starters, ${slideRows} slide rows, ${plates} mounting plates checked.`);
if(problems.length){console.error(problems.slice(0,40).join('\n')+(problems.length>40?`\n… ${problems.length} problems`:''));process.exit(1)}
console.log('Hardware view matches the engine: slide holes, mounting plates and the door fixing-hole offset.');
