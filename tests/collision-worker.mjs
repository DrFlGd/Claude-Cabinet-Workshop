// The in-app 3D collision check (lib/collision-run.ts over a pool of
// public/openscad/interference-worker.js, jobs from lib/interference.ts) run through the
// production worker: the default design of every product and of every cabinet type must report
// no intersecting parts, a design with a part drawn twice must report that pair, a second check
// of an unchanged design must come entirely from the cache, a changed design must render again,
// and bad requests are refused. Prints the timings the app's users would see.
//
//   node tests/collision-worker.mjs                 every product and cabinet type's default
//   FAMILIES=0,7 node tests/collision-worker.mjs    a subset of cabinet types
//   WORKERS=1 node tests/collision-worker.mjs       pool size (default: as the app picks for this machine)
import os from 'node:os';
import fs from 'node:fs';
import assert from 'node:assert/strict';
import {Worker} from 'node:worker_threads';
import {loadProducts,loadInterference,loadCollisionRun} from './product-load.mjs';
const root=new URL('../',import.meta.url),P=loadProducts(),I=loadInterference(),C=loadCollisionRun();
const read=n=>JSON.parse(fs.readFileSync(new URL(n,root)));
const schema=read('lib/schema.json'),bundle=read('lib/engine-sources.json');
const renderSources=Object.entries(bundle).filter(([n])=>n.endsWith('.scad')).map(([name,text])=>({name,text}));
const size=Number(process.env.WORKERS)||C.collisionWorkerCount(os.cpus().length);

// The browser Worker interface over a Node worker running the unchanged production worker.
function nodeWorker(){
 const w=new Worker(new URL('./section-worker.mjs',import.meta.url),{workerData:'interference-worker.js'});
 const o={postMessage:(m,t)=>w.postMessage(m,t),onmessage:null,onerror:null,terminate:()=>w.terminate()};
 w.on('message',data=>o.onmessage?.({data}));w.on('error',e=>o.onerror?.(e));
 return o;
}
const pool=n=>new C.CollisionPool(nodeWorker,n);
function exportReport(filename,source,sources){
 const w=new Worker(new URL('./section-worker.mjs',import.meta.url),{workerData:'export-worker.js'});
 return new Promise((resolve,reject)=>{w.on('error',e=>{w.terminate();reject(e)});w.on('message',m=>{if(m.type==='result'||m.type==='error'){w.terminate();m.type==='result'?resolve(m.logs.join('\n')+'\n'+m.output):reject(Error(m.error))}});w.postMessage({filename,source,sources,mode:'bom'})});
}
const secs=ms=>(ms/1000).toFixed(1)+' s';
const lines=[],failures=[];
const stats=r=>`${r.parts} with geometry, ${r.candidates} of ${r.pairs} pairs intersected, ${secs(r.ms.total)} (render ${secs(r.ms.render)}, intersect ${secs(r.ms.intersect)})`;
async function check(label,o){
 const p=pool(size),cache=new C.CollisionCache();
 try{
  const r=await C.runCollisionCheck({...o,pool:p,cache});
  if(r.overlaps.length)failures.push(`${label}: ${JSON.stringify(r.overlaps)}`);
  // The same design again: every render and pair result comes from the cache.
  const again=await C.runCollisionCheck({...o,pool:p,cache});
  assert.equal(again.reused.renders,o.jobs.length,label+': a second check reuses every render');
  assert.equal(again.reused.pairs,again.candidates,label+': a second check reuses every pair');
  assert.deepEqual(again.overlaps,r.overlaps);
  lines.push(`${label}: ${o.jobs.length} jobs, ${stats(r)} on ${size} worker(s); again ${secs(again.ms.total)}`);
  return {r,cache,p};
 }catch(e){failures.push(`${label}: ${e.message}`);p.terminate();return null}
}

// ---- products ----
for(const p of P.products){
 const t=P.productTarget(p),v=P.productStarterValues(p,p.defaultStarter),src=t.source(v);
 const jobs=I.productJobs(p.id,src,await exportReport(p.file,src,t.sources));
 if(p.id==='media_cart')assert(jobs.length>=10&&jobs.some(j=>j.name==='CASTERS'),'media cart jobs list every part and the casters');
 const done=await check(`${p.name.toLowerCase()} (default)`,{filename:p.file,sources:t.sources,jobs,threshold:I.PRODUCT_THRESHOLD});
 if(!done)continue;
 if(p.id==='media_cart'){
  // A changed design renders again; parts whose source did not change are not reused either
  // (every job carries the whole design), but pairs of byte-identical parts are.
  const key='width';assert.equal(typeof v[key],'number');
  const src2=t.source({...v,[key]:v[key]+20}),jobs2=I.productJobs(p.id,src2,await exportReport(p.file,src2,t.sources));
  const changed=await C.runCollisionCheck({filename:p.file,sources:t.sources,jobs:jobs2,threshold:I.PRODUCT_THRESHOLD,pool:done.p,cache:done.cache});
  assert(changed.reused.renders<jobs2.length,'a changed design renders again');
  lines.push(`media cart, ${key} +20: rendered ${jobs2.length-changed.reused.renders}, reused ${changed.reused.pairs} of ${changed.candidates} pair results, ${secs(changed.ms.total)}`);
  // A part drawn twice must be reported against itself.
  const twice=[...jobs.slice(0,3),{name:'BOTTOM_AGAIN',source:jobs.find(j=>j.name==='BOTTOM').source}];
  const d=await C.runCollisionCheck({filename:p.file,sources:t.sources,jobs:twice,threshold:I.PRODUCT_THRESHOLD,pool:done.p});
  assert(d.overlaps.some(o=>[o.a,o.b].sort().join()==='BOTTOM,BOTTOM_AGAIN'&&o.volume>1e5),'a duplicated part is reported: '+JSON.stringify(d.overlaps));
  // Refused requests.
  for(const [bad,re] of [[{filename:'nope.scad',sources:[],jobs},/Invalid/],[{filename:p.file,sources:[],jobs},/Invalid engine snapshot/],[{filename:p.file,sources:t.sources,jobs:jobs.slice(0,1)},/Invalid/],[{filename:p.file,sources:t.sources,jobs:[jobs[0],jobs[0]]},/Invalid/]]){
   const q=pool(1);await assert.rejects(C.runCollisionCheck({...bad,threshold:1,pool:q}),re);q.terminate();
  }
 }
 done.p.terminate();
}

// ---- cabinets: the default starter of every type ----
const only=process.env.FAMILIES?process.env.FAMILIES.split(',').map(Number):schema.map((_,i)=>i);
for(const f of only){
 const fam=schema[f],v={...Object.fromEntries(fam.fields.map(x=>[x.key,x.value])),...fam.starters.find(s=>s.id===fam.defaultStarter).values};
 const configure=vals=>{let s=bundle[fam.file];for(const fl of fam.fields){const x=vals[fl.key];if(x!==undefined&&x!==null)s=I.setAssignment(s,fl.key,x)}return s};
 const text=await exportReport(fam.file,configure({...v,output_mode:'bom'}),renderSources);
 const cj=I.cabinetJobs({id:fam.id,fields:fam.fields,configure},v,text);
 const done=await check(`${fam.id} (${fam.defaultStarter})`,{filename:fam.file,sources:renderSources,jobs:cj,threshold:I.CABINET_THRESHOLD});
 done?.p.terminate();
}
for(const l of lines)console.log(l);
for(const f of failures)console.log('FAIL '+f);
if(failures.length){console.log(`Collision worker: ${failures.length} failure(s).`);process.exitCode=1}
else console.log(`Collision worker: ${P.products.length} product(s) and ${only.length} cabinet type(s) check clean on ${size} worker(s) and again from the cache, a changed design renders again, a duplicated part is caught and bad requests are refused.`);
