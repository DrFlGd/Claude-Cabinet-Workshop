// Pocket operation overlap gate: no two pocket operations of a starter may machine the same
// area, except the pairs the engine draws to meet (the same exceptions as the Python audit,
// validation.py EXPECTED_POCKET_OVERLAPS, plus ganging holes, drilled from the outside face).
//
// Every pocket output mode a cabinet type offers is exported through the production worker.
// The registration frame is dropped (it is drawn in every mode), contours of different
// operations are compared by their extents, and only the pairs whose extents meet are
// intersected exactly (OpenSCAD, even-odd fill as in the export) to measure shared area.
//
// The frame is matched with a tolerance that grows with the coordinate: EXPORT_FRAME is echoed
// with six significant digits, so on a layout longer than 10 m its edge is known only to
// 0.1 mm. With a fixed tolerance the frame of a long layout was kept as pocket geometry and
// every operation appeared to overlap every other one by the frame's area (the Python audit
// reported that for the 3-section drawer workbench shop cart).
//
//   node tests/pocket-overlap.mjs                every starter of every cabinet type
//   FAMILIES=0 STARTERS=default node tests/pocket-overlap.mjs   a subset
//   SHARD=2/6 node tests/pocket-overlap.mjs      one shard of the starters (CI)
import fs from 'node:fs';
import os from 'node:os';
import assert from 'node:assert/strict';
import {Worker} from 'node:worker_threads';

const root=new URL('../',import.meta.url);
const read=n=>JSON.parse(fs.readFileSync(new URL(n,root)));
// Same pairs as validation.py: drawer dados meet the bottom groove, divider perimeter grooves
// end in it. Ganging holes are drilled from the outside face, the other side pockets from the inside.
export const EXPECTED=new Set(['pocket_bottom_grooves|pocket_drawer_dados','pocket_bottom_grooves|pocket_divider_perimeter_grooves']);
const expected=(a,b)=>EXPECTED.has([a,b].sort().join('|'))||a==='pocket_ganging'||b==='pocket_ganging';
// Shared area below this (mm²) is coordinate round-off.
export const AREA_TOLERANCE=1e-3;

const tol=(a,b)=>0.05+1e-5*Math.max(Math.abs(a),Math.abs(b));
export function frameOf(logs){
 const m=logs.join('\n').match(/EXPORT_FRAME\|X0=([-\d.e]+)\|Y0=([-\d.e]+)\|X1=([-\d.e]+)\|Y1=([-\d.e]+)\|FW=([-\d.e]+)/);
 return m?{x0:+m[1],y0:+m[2],x1:+m[3],y1:+m[4],fw:+m[5]}:null;
}
// Closed contours of an OpenSCAD SVG, in model coordinates (the SVG's y axis points down).
export function contours(svg){
 const out=[];
 for(const [,d] of svg.matchAll(/ d="([^"]*)"/g))for(const sub of d.split(/z/i)){
  const pts=[...sub.matchAll(/(-?[\d.e+-]+),(-?[\d.e+-]+)/g)].map(m=>[+m[1],-m[2]]);
  if(pts.length>=3){const xs=pts.map(p=>p[0]),ys=pts.map(p=>p[1]);out.push({pts,lo:[Math.min(...xs),Math.min(...ys)],hi:[Math.max(...xs),Math.max(...ys)]})}
 }
 return out;
}
// The pocket contours of one operation: the registration frame's outer and inner edges removed.
export function pocketContours(svg,frame){
 const cs=contours(svg);if(!frame)return cs;
 const near=(c,b)=>[[c.lo[0],b[0]],[c.lo[1],b[1]],[c.hi[0],b[2]],[c.hi[1],b[3]]].every(([x,y])=>Math.abs(x-y)<=tol(x,y));
 const outer=[frame.x0,frame.y0,frame.x1,frame.y1],inner=[frame.x0+frame.fw,frame.y0+frame.fw,frame.x1-frame.fw,frame.y1-frame.fw];
 return cs.filter(c=>!near(c,outer)&&!near(c,inner));
}
const meet=(a,b)=>a.lo[0]<b.hi[0]-0.01&&b.lo[0]<a.hi[0]-0.01&&a.lo[1]<b.hi[1]-0.01&&b.lo[1]<a.hi[1]-0.01;

let engine=null;
async function openscad(){
 if(!engine){const {default:OpenSCAD}=await import(new URL('public/openscad/openscad.js',root).href);engine={OpenSCAD,wasmBinary:fs.readFileSync(new URL('public/openscad/openscad.wasm',root))}}
 return engine;
}
const polygon=cs=>{const pts=[],paths=[];for(const c of cs){paths.push(c.pts.map((_,i)=>pts.length+i));pts.push(...c.pts)}return `polygon(points=${JSON.stringify(pts)},paths=${JSON.stringify(paths)});`};
const ring=pts=>pts.reduce((s,p,i)=>{const q=pts[(i+1)%pts.length];return s+p[0]*q[1]-q[0]*p[1]},0)/2;
// Exact shared area of two sets of contours, each filled even-odd (as polygon() fills them).
export async function sharedArea(a,b){
 const {OpenSCAD,wasmBinary}=await openscad(),logs=[];
 const e=await OpenSCAD({noInitialRun:true,wasmBinary,print:l=>logs.push(l),printErr:l=>logs.push(l)});
 e.FS.writeFile('/i.scad',`intersection(){${polygon(a)}${polygon(b)}}`);
 e.callMain(['/i.scad','--backend=Manifold','-o','/o.svg']);
 let svg='';try{svg=e.FS.readFile('/o.svg',{encoding:'utf8'})}catch{}
 // An empty intersection exports nothing (OpenSCAD reports an empty or non-2D top level object).
 if(!svg){if(logs.some(l=>/top level object is (empty|not a 2D object)/i.test(l)))return 0;throw Error('intersection failed: '+logs.slice(-3).join(' '))}
 return Math.abs(contours(svg).reduce((s,c)=>s+ring(c.pts),0));
}
// Overlapping pocket operations of one design: {a, b, area} for every pair that shares area.
export async function pocketOverlaps(ops){
 const names=Object.keys(ops).sort(),out=[];
 for(let i=0;i<names.length;i++)for(let j=i+1;j<names.length;j++){
  const a=names[i],b=names[j];if(expected(a,b))continue;
  const ca=ops[a].filter(x=>ops[b].some(y=>meet(x,y)));if(!ca.length)continue;
  const cb=ops[b].filter(y=>ca.some(x=>meet(x,y)));
  const area=await sharedArea(ca,cb);if(area>AREA_TOLERANCE)out.push({a,b,area});
 }
 return out;
}

// ---- checks of the gate itself ----
async function selfTest(){
 const sq=(x,y,s)=>({pts:[[x,y],[x+s,y],[x+s,y+s],[x,y+s]],lo:[x,y],hi:[x+s,y+s]});
 const tri=(p)=>({pts:p,lo:[Math.min(...p.map(q=>q[0])),Math.min(...p.map(q=>q[1]))],hi:[Math.max(...p.map(q=>q[0])),Math.max(...p.map(q=>q[1]))]});
 // Overlapping squares share 25 mm²; triangles that split one square have overlapping extents but no shared area.
 const o=await pocketOverlaps({pocket_hinge_cups:[sq(0,0,10)],pocket_shelf_pins:[sq(5,5,10)]});
 assert.equal(o.length,1);assert(Math.abs(o[0].area-25)<1e-6,'overlap area '+o[0].area);
 assert.deepEqual(await pocketOverlaps({pocket_hinge_cups:[tri([[0,0],[10,0],[0,10]])],pocket_shelf_pins:[tri([[10,0],[10,10],[0,10]])]}),[]);
 // A pocket inside another operation's hole (even-odd) does not overlap it.
 assert.deepEqual(await pocketOverlaps({pocket_carcass_dados:[sq(0,0,10),sq(2,2,6)],pocket_shelf_pins:[sq(3,3,4)]}),[]);
 // Pairs the engine draws to meet are not reported.
 assert.deepEqual(await pocketOverlaps({pocket_drawer_dados:[sq(0,0,10)],pocket_bottom_grooves:[sq(5,5,10)]}),[]);
 // A long layout's frame, echoed with six significant digits, is still recognised.
 const frame=frameOf(['ECHO: "EXPORT_FRAME|X0=-20|Y0=-20|X1=4600|Y1=18147.3|FW=0.2"']);
 const svg='<path d="\nM 4600,-18147.2 L -20,-18147.2 L -20,20 L 4600,20 z\nM -19.8,-18147 L 4599.8,-18147 L 4599.8,19.8 L -19.8,19.8 z\nM 0,0 L 10,0 L 10,-10 z\n"/>';
 assert.equal(pocketContours(svg,frame).length,1,'frame contours dropped, the pocket kept');
}

// ---- every starter ----
function exportMode(file,source,mode,sources){
 const w=new Worker(new URL('./section-worker.mjs',import.meta.url),{workerData:'export-worker.js'});
 return new Promise(resolve=>{
  const timer=setTimeout(()=>{w.terminate();resolve({type:'error',error:'timeout'})},300000);
  w.on('error',e=>{clearTimeout(timer);w.terminate();resolve({type:'error',error:String(e)})});
  w.on('message',m=>{if(m.type==='result'||m.type==='error'){clearTimeout(timer);w.terminate();resolve(m)}});
  w.postMessage({filename:file,source,mode,sources});
 });
}
if(process.argv[1]&&new URL(import.meta.url).pathname===fs.realpathSync(process.argv[1])){
 const started=Date.now();
 await selfTest();
 const schema=read('lib/schema.json'),bundle=read('lib/engine-sources.json');
 const sources=Object.entries(bundle).filter(([n])=>n.endsWith('.scad')).map(([name,text])=>({name,text}));
 const families=(process.env.FAMILIES??schema.map((_,i)=>i).join(',')).split(',').map(Number);
 const only=process.env.STARTERS?new Set(process.env.STARTERS.split(',')):null;
 const configure=(f,values)=>{let s=bundle[schema[f].file];for(const fl of schema[f].fields){const v=values[fl.key];if(v!==undefined&&v!==null)s=s.replace(new RegExp('^('+fl.key+'\\s*=\\s*)[^;]+;','m'),(_m,p)=>p+JSON.stringify(v)+';')}return s};
 let jobs=families.flatMap(f=>schema[f].starters.filter(s=>!only||only.has(s.id)).map(s=>({f,id:s.id})));
 if(process.env.SHARD){const [k,n]=process.env.SHARD.split('/').map(Number);jobs=jobs.filter((_,i)=>i%n===k-1)}
 if(!jobs.length)throw Error('No starters selected.');
 const failures=[];let next=0,ops=0,compared=0,framed=0;
 async function one({f,id}){
  const fam=schema[f],v={...Object.fromEntries(fam.fields.map(x=>[x.key,x.value])),...fam.starters.find(s=>s.id===id).values},src=configure(f,v);
  const modes=fam.fields.find(x=>x.key==='output_mode').options.filter(m=>m.startsWith('pocket_')&&m!=='pocket_layout');
  const byMode={};
  for(const mode of modes){
   const r=await exportMode(fam.file,src,mode,sources);
   if(r.type!=='result'){failures.push(`${fam.id}:${id} ${mode}: ${r.error}`);continue}
   if(r.empty){byMode[mode]=[];continue}
   const frame=frameOf(r.logs??[]);if(frame)framed++;
   byMode[mode]=pocketContours(r.output,frame);ops++;
  }
  const n=Object.keys(byMode).length;compared+=n*(n-1)/2;
  for(const o of await pocketOverlaps(byMode))failures.push(`${fam.id}:${id}: ${o.a} and ${o.b} machine the same ${o.area.toFixed(3)} mm²`);
 }
 await Promise.all(Array.from({length:Math.max(1,Math.min(4,os.cpus().length))},async()=>{while(next<jobs.length)await one(jobs[next++])}));
 const seconds=Math.round((Date.now()-started)/1000);
 for(const x of failures)console.log('FAIL '+x);
 if(failures.length){console.log(`Pocket overlap: ${failures.length} problem(s).`);process.exitCode=1}
 else console.log(`Pocket overlap: ${jobs.length} starter(s), ${ops} pocket operations (${framed} with their registration frame removed), ${compared} operation pairs compared, none machine the same area (${seconds} s).`);
}
