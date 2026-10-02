// Golden engine outputs for every starter of every cabinet type.
//
// Records the engine's parts list and reports (BOM, DIM, LAYOUT, CHECK, WARN,
// HARDWARE, TARGET records) and fingerprints of the through-cut and pocket SVG
// layouts. Refactors must reproduce them exactly; an intended change is accepted
// with `node tests/golden.mjs --update`, and the diff of tests/golden/*.json shows
// exactly which parts or dimensions changed.
//
//   node tests/golden.mjs             check (exit 1 on any difference)
//   node tests/golden.mjs --update    rewrite the snapshots
//   FAMILIES=4 STARTERS=kitchen_standard_B36 node tests/golden.mjs   subset
import fs from 'node:fs';
import os from 'node:os';
import crypto from 'node:crypto';
import {Worker} from 'node:worker_threads';
const root=new URL('../',import.meta.url);
const read=n=>JSON.parse(fs.readFileSync(new URL(n,root)));
const schema=read('lib/schema.json'),bundle=read('lib/engine-sources.json');
const sources=Object.entries(bundle).filter(([n])=>n.endsWith('.scad')).map(([name,text])=>({name,text}));
const update=process.argv.includes('--update');
const families=(process.env.FAMILIES??'0,1,2,3,4,5,6').split(',').map(Number);
const only=process.env.STARTERS?new Set(process.env.STARTERS.split(',')):null;
const dir=new URL('tests/golden/',root);
const configure=(f,values)=>{let s=bundle[schema[f].file];for(const fl of schema[f].fields){const v=values[fl.key];if(v!==undefined&&v!==null)s=s.replace(new RegExp('^('+fl.key+'\\s*=\\s*)[^;]+;','m'),(_m,p)=>p+JSON.stringify(v)+';')}return s};
const valuesFor=(f,id)=>({...Object.fromEntries(schema[f].fields.map(x=>[x.key,x.value])),...schema[f].starters.find(s=>s.id===id).values});
function run(f,values,mode){
 const worker=new Worker(new URL('./section-worker.mjs',import.meta.url),{workerData:'export-worker.js'});
 return new Promise(resolve=>{
  const timer=setTimeout(()=>{worker.terminate();resolve({type:'error',error:'timeout'})},300000);
  worker.on('error',e=>{clearTimeout(timer);worker.terminate();resolve({type:'error',error:String(e)})});
  worker.on('message',m=>{if(m.type==='result'||m.type==='error'){clearTimeout(timer);worker.terminate();resolve(m)}});
  worker.postMessage({filename:schema[f].file,source:configure(f,values),mode,sources});
 });
}
const RECORD=/^ECHO: "((?:BOM|DIM|LAYOUT|CHECK|WARN|HARDWARE|TARGET)\|.*|WARNING: .*)"\s*$/;
function records(m){
 const text=(m.logs??[]).join('\n')+'\n'+(typeof m.output==='string'?m.output:'');
 const out=[],seen=new Set();
 for(const line of text.split(/\r?\n/)){const r=line.match(RECORD);if(r&&!seen.has(r[1])){seen.add(r[1]);out.push(r[1])}}
 return out;
}
const svgModes=f=>{const modes=schema[f].fields.find(x=>x.key==='output_mode').options;return ['cut_layout',modes.includes('pocket_layout')?'pocket_layout':'pocket_carcass_dados'].filter(m=>modes.includes(m))};
async function snapshot(f,id){
 const v=valuesFor(f,id),bom=await run(f,v,'bom');
 const snap={records:bom.type==='result'?records(bom):['ERROR: '+bom.error],svg:{}};
 for(const mode of svgModes(f)){
  const r=await run(f,v,mode);
  const svg=r.type==='result'&&typeof r.output==='string'?r.output:'';
  snap.svg[mode]=r.type==='result'?{sha256:crypto.createHash('sha256').update(svg).digest('hex').slice(0,24),bytes:Buffer.byteLength(svg),paths:(svg.match(/<path/g)??[]).length}:{error:String(r.error).slice(0,200)};
 }
 return snap;
}
function diff(a,b){
 const removed=a.filter(x=>!b.includes(x)),added=b.filter(x=>!a.includes(x));
 return [...removed.slice(0,8).map(x=>'  - '+x),...added.slice(0,8).map(x=>'  + '+x),...(removed.length+added.length>16?[`  … ${removed.length} removed, ${added.length} added in total`]:[])];
}
const jobs=families.flatMap(f=>schema[f].starters.filter(s=>!only||only.has(s.id)).map(s=>({f,id:s.id})));
const results=new Map();let next=0;
const started=Date.now();
await Promise.all(Array.from({length:Math.max(1,Math.min(4,os.cpus().length))},async()=>{while(next<jobs.length){const j=jobs[next++];results.set(j.f+':'+j.id,await snapshot(j.f,j.id))}}));
fs.mkdirSync(dir,{recursive:true});
let problems=0;
for(const f of families){
 const file=new URL(schema[f].id+'.json',dir);
 const old=fs.existsSync(file)?JSON.parse(fs.readFileSync(file)):{};
 const now={...(only?old:{})};
 for(const s of schema[f].starters.filter(s=>!only||only.has(s.id)))now[s.id]=results.get(f+':'+s.id);
 if(update){fs.writeFileSync(file,JSON.stringify(now,null,1)+'\n');continue}
 for(const [id,snap] of Object.entries(now)){
  const was=old[id];
  if(!was){console.log(`${schema[f].id}:${id} has no snapshot; run with --update`);problems++;continue}
  const lines=diff(was.records,snap.records);
  const svgChanged=Object.keys({...was.svg,...snap.svg}).filter(m=>JSON.stringify(was.svg[m])!==JSON.stringify(snap.svg[m]));
  if(lines.length||svgChanged.length){
   problems++;
   console.log(`${schema[f].id}:${id} changed`+(svgChanged.length?` (SVG: ${svgChanged.join(', ')})`:''));
   for(const l of lines)console.log(l);
  }
 }
 if(!only)for(const id of Object.keys(old))if(!now[id]){console.log(`${schema[f].id}:${id} snapshot has no starter`);problems++}
}
const seconds=Math.round((Date.now()-started)/1000);
if(update)console.log(`Golden outputs: wrote snapshots for ${jobs.length} starters in ${seconds} s.`);
else if(problems){console.log(`Golden outputs: ${problems} starter(s) differ from tests/golden. If the change is intended, run node tests/golden.mjs --update and review the diff.`);process.exitCode=1}
else console.log(`Golden outputs: ${jobs.length} starters match their recorded parts, reports and cut/pocket layouts (${seconds} s).`);
