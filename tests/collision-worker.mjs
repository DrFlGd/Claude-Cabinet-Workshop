// The in-app 3D collision check (public/openscad/interference-worker.js, jobs from
// lib/interference.ts) run through the production worker: the default design of the media
// cart and of every cabinet type must report no intersecting parts, a design with a part
// drawn twice must report that pair, and bad requests are refused. Prints the timings the
// app's users would see (one worker, as in the browser).
//
//   node tests/collision-worker.mjs             media cart and every cabinet type's default
//   FAMILIES=0,4 node tests/collision-worker.mjs   a subset of cabinet types
import fs from 'node:fs';
import assert from 'node:assert/strict';
import path from 'node:path';
import {createRequire} from 'node:module';
import ts from 'typescript';
import {Worker} from 'node:worker_threads';
import {loadProducts} from './product-load.mjs';
const root=new URL('../',import.meta.url),P=loadProducts();
const req=createRequire(import.meta.url);
function loadTs(file){const m={exports:{}};new Function('require','module','exports',ts.transpileModule(fs.readFileSync(file,'utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2022}}).outputText)(req,m,m.exports);return m.exports}
const I=loadTs(path.join(root.pathname,'lib/interference.ts'));
const read=n=>JSON.parse(fs.readFileSync(new URL(n,root)));
const schema=read('lib/schema.json'),bundle=read('lib/engine-sources.json');
const renderSources=Object.entries(bundle).filter(([n])=>n.endsWith('.scad')).map(([name,text])=>({name,text}));

function worker(file,message,onProgress){
 const w=new Worker(new URL('./section-worker.mjs',import.meta.url),{workerData:file});
 return new Promise(resolve=>{
  const timer=setTimeout(()=>{w.terminate();resolve({type:'error',error:'timeout'})},1200000);
  w.on('error',e=>{clearTimeout(timer);w.terminate();resolve({type:'error',error:String(e)})});
  w.on('message',m=>{if(m.type==='progress'){onProgress?.(m);return}if(m.type==='result'||m.type==='error'){clearTimeout(timer);w.terminate();resolve(m)}});
  w.postMessage(message);
 });
}
const report=async(filename,source,sources)=>{const r=await worker('export-worker.js',{filename,source,sources,mode:'bom'});assert.equal(r.type,'result',r.error);return r.logs.join('\n')+'\n'+r.output};
const secs=ms=>(ms/1000).toFixed(1)+' s';
const lines=[],failures=[];

// ---- media cart ----
const mc=P.productById('media_cart'),target=P.productTarget(mc),values=P.productStarterValues(mc,mc.defaultStarter);
const source=target.source(values),rep=await report(mc.file,source,target.sources);
const jobs=I.productJobs(source,rep,!!values.show_casters);
assert(jobs.length>=10&&jobs.some(j=>j.name==='CASTERS'),'media cart jobs list every part and the casters');
const r=await worker('interference-worker.js',{filename:mc.file,sources:target.sources,jobs,threshold:I.PRODUCT_THRESHOLD});
if(r.type!=='result')failures.push('media cart: '+r.error);
else{
 if(r.overlaps.length)failures.push('media cart default: '+JSON.stringify(r.overlaps));
 lines.push(`media cart (default): ${r.parts} parts, ${r.candidates} of ${r.pairs} pairs intersected, ${secs(r.ms.total)} (render ${secs(r.ms.render)}, intersect ${secs(r.ms.intersect)})`);
}
// A part drawn twice must be reported against itself.
const twice=[...jobs.slice(0,3),{name:'BOTTOM_AGAIN',source:jobs.find(j=>j.name==='BOTTOM').source}];
const d=await worker('interference-worker.js',{filename:mc.file,sources:target.sources,jobs:twice,threshold:I.PRODUCT_THRESHOLD});
assert.equal(d.type,'result',d.error);
assert(d.overlaps.some(o=>[o.a,o.b].sort().join()==='BOTTOM,BOTTOM_AGAIN'&&o.volume>1e5),'a duplicated part is reported: '+JSON.stringify(d.overlaps));
// Refused requests.
for(const bad of [{filename:'nope.scad',sources:[],jobs},{filename:mc.file,sources:[],jobs},{filename:mc.file,sources:target.sources,jobs:jobs.slice(0,1)}]){
 const e=await worker('interference-worker.js',{...bad,threshold:1});assert.equal(e.type,'error');assert.match(e.error,/Invalid/);
}

// ---- cabinets: the default starter of every type ----
const only=process.env.FAMILIES?process.env.FAMILIES.split(',').map(Number):schema.map((_,i)=>i);
for(const f of only){
 const fam=schema[f],v={...Object.fromEntries(fam.fields.map(x=>[x.key,x.value])),...fam.starters.find(s=>s.id===fam.defaultStarter).values};
 const configure=vals=>{let s=bundle[fam.file];for(const fl of fam.fields){const x=vals[fl.key];if(x!==undefined&&x!==null)s=I.setAssignment(s,fl.key,x)}return s};
 const text=await report(fam.file,configure({...v,output_mode:'bom'}),renderSources);
 const cj=I.cabinetJobs({id:fam.id,fields:fam.fields,configure},v,text);
 const c=await worker('interference-worker.js',{filename:fam.file,sources:renderSources,jobs:cj,threshold:I.CABINET_THRESHOLD});
 if(c.type!=='result'){failures.push(`${fam.id}: ${c.error}`);continue}
 if(c.overlaps.length)failures.push(`${fam.id}:${fam.defaultStarter}: ${JSON.stringify(c.overlaps)}`);
 lines.push(`${fam.id} (${fam.defaultStarter}): ${cj.length} groups, ${c.parts} with geometry, ${c.candidates} of ${c.pairs} pairs intersected, ${secs(c.ms.total)} (render ${secs(c.ms.render)}, intersect ${secs(c.ms.intersect)})`);
}
for(const l of lines)console.log(l);
for(const f of failures)console.log('FAIL '+f);
if(failures.length){console.log(`Collision worker: ${failures.length} failure(s).`);process.exitCode=1}
else console.log(`Collision worker: the media cart and ${only.length} cabinet type(s) check clean, a duplicated part is caught and bad requests are refused.`);
