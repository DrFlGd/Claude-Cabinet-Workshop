// Cut-layout placement gate.
//
// The engine places every through-cut part from one placement table and echoes
// it as PLACE records (tests/golden.mjs keeps them in the snapshots). This module
// checks, for one design, that the table, the BOM and the exported cut SVG agree:
//
//   - every BOM part has exactly one PLACE record of the same cut size;
//   - no two placement rectangles overlap (the engine reports the same pairs as
//     CHECK|ERROR|LAYOUT_OVERLAP);
//   - the cut SVG has exactly one outer contour per part, and each contour's
//     extent equals its part's rectangle (so fused parts, drifted positions and
//     parts drawn larger than their BOM size all fail).
//
// golden.mjs runs checkCutLayout() for every starter. Run this file directly to
// prove the overlap error fires: it renders one starter with a negative layout
// gap and expects LAYOUT_OVERLAP to block the cut export.
//
//   node tests/cut-layout-check.mjs
import fs from 'node:fs';
import {Worker} from 'node:worker_threads';

// Echo and SVG values carry six significant digits, so the comparison tolerance
// grows with the coordinate: 0.05 mm near the origin, 0.25 mm at y = 20 m.
const TOL=0.05;
const tol=(a,b)=>TOL+1e-5*Math.max(Math.abs(a),Math.abs(b));

export const PLACE=/^PLACE\|([^|]+)\|X=([-\d.e]+)\|Y=([-\d.e]+)\|W=([-\d.e]+)\|H=([-\d.e]+)$/;

export function placements(records){
 const out=[];
 for(const r of records){const m=r.match(PLACE);if(m)out.push({id:m[1],x:+m[2],y:+m[3],w:+m[4],h:+m[5]})}
 return out;
}

export function bomParts(records){
 const out=[];
 for(const r of records){if(!r.startsWith('BOM|'))continue;const f=r.split('|');out.push({id:f[1],qty:+f[2],w:+f[6],h:+f[7]})}
 return out;
}

// Closed subpaths of OpenSCAD's single <path>, as polygons in engine coordinates
// (OpenSCAD's SVG export negates y).
export function svgPolygons(svg){
 const polys=[];
 for(const m of svg.matchAll(/<path[^>]*\sd="([^"]+)"/g)){
  for(const sp of m[1].split(/(?=M)/)){
   const nums=[...sp.matchAll(/-?\d+(?:\.\d+)?(?:e-?\d+)?/g)].map(x=>+x[0]);
   const pts=[];for(let i=0;i+1<nums.length;i+=2)pts.push([nums[i],-nums[i+1]]);
   if(pts.length>=3)polys.push(pts);
  }
 }
 return polys;
}
const bbox=pts=>{let x0=Infinity,y0=Infinity,x1=-Infinity,y1=-Infinity;for(const [x,y] of pts){x0=Math.min(x0,x);y0=Math.min(y0,y);x1=Math.max(x1,x);y1=Math.max(y1,y)}return {x0,y0,x1,y1}};
function inside(pt,poly){ // ray casting
 let c=false;const [px,py]=pt;
 for(let i=0,j=poly.length-1;i<poly.length;j=i++){const [xi,yi]=poly[i],[xj,yj]=poly[j];if((yi>py)!==(yj>py)&&px<(xj-xi)*(py-yi)/(yj-yi)+xi)c=!c}
 return c;
}
// Outer contours: subpaths enclosed by an even number of other subpaths (a part
// outline sits inside the shared export registration frame and its hole; a part's
// own holes sit one level deeper). The frame, the one outer contour enclosing
// every other, is removed when present.
export function outerContours(svg,{registrationFrame=true}={}){
 const polys=svgPolygons(svg).map(pts=>({pts,box:bbox(pts)}));
 const encloses=(q,p)=>q!==p&&q.box.x0<=p.box.x0+TOL&&q.box.y0<=p.box.y0+TOL&&q.box.x1>=p.box.x1-TOL&&q.box.y1>=p.box.y1-TOL&&(q.box.x1-q.box.x0)*(q.box.y1-q.box.y0)>(p.box.x1-p.box.x0)*(p.box.y1-p.box.y0)&&inside(p.pts[0],q.pts);
 const outer=polys.filter(p=>polys.filter(q=>encloses(q,p)).length%2===0);
 if(!registrationFrame)return outer.map(p=>p.box);
 const frame=outer.length>1?outer.find(p=>outer.every(q=>q===p||encloses(p,q))):undefined;
 return outer.filter(p=>p!==frame).map(p=>p.box);
}

const overlap=(a,b)=>a.x<b.x+b.w-0.001&&b.x<a.x+a.w-0.001&&a.y<b.y+b.h-0.001&&b.y<a.y+a.h-0.001;
const same=(a,b)=>Math.abs(a-b)<=tol(a,b);

// Problems found for one design, as human-readable lines (empty when the layout passes).
export function checkCutLayout({records,svg,kerf=0,registrationFrame=true}){
 const problems=[];
 const places=placements(records),bom=bomParts(records);
 const ids=new Map();
 for(const p of places){if(ids.has(p.id))problems.push(`PLACE record for ${p.id} appears twice`);ids.set(p.id,p)}
 for(const b of bom){
  const p=ids.get(b.id);
  if(!p){problems.push(`BOM part ${b.id} has no PLACE record`);continue}
  if(!(same(p.w,b.w)&&same(p.h,b.h)))problems.push(`${b.id}: PLACE ${p.w} × ${p.h} differs from BOM ${b.w} × ${b.h}`);
 }
 const bomIds=new Set(bom.map(b=>b.id));
 for(const p of places)if(!bomIds.has(p.id))problems.push(`PLACE record ${p.id} has no BOM part`);
 for(let i=0;i<places.length;i++)for(let j=i+1;j<places.length;j++)if(overlap(places[i],places[j]))problems.push(`${places[i].id} overlaps ${places[j].id} in the placement table`);
 if(typeof svg==='string'&&svg.includes('<svg')){
  const contours=outerContours(svg,{registrationFrame});
  const k=kerf/2;
  const unmatched=[];const used=new Set();
  for(const c of contours){
   const hit=places.find(p=>!used.has(p.id)&&same(c.x0,p.x-k)&&same(c.y0,p.y-k)&&same(c.x1,p.x+p.w+k)&&same(c.y1,p.y+p.h+k));
   if(hit)used.add(hit.id);else unmatched.push(c);
  }
  if(contours.length!==places.length)problems.push(`cut SVG has ${contours.length} outer contour(s) for ${places.length} placed part(s)`);
  for(const p of places)if(!used.has(p.id))problems.push(`${p.id} (${p.w} × ${p.h} at ${p.x}, ${p.y}) has no matching contour in the cut SVG`);
  for(const c of unmatched.slice(0,6))problems.push(`contour ${(c.x1-c.x0).toFixed(2)} × ${(c.y1-c.y0).toFixed(2)} at ${c.x0.toFixed(2)}, ${c.y0.toFixed(2)} matches no placed part`);
 }
 return problems;
}

// ---- standalone run: prove LAYOUT_OVERLAP fires and blocks the export ----
if(process.argv[1]&&import.meta.url===new URL(process.argv[1],'file://').href){
 const root=new URL('../',import.meta.url);
 const read=n=>JSON.parse(fs.readFileSync(new URL(n,root)));
 const schema=read('lib/schema.json'),bundle=read('lib/engine-sources.json');
 const sources=Object.entries(bundle).filter(([n])=>n.endsWith('.scad')).map(([name,text])=>({name,text}));
 const configure=(f,values)=>{let s=bundle[schema[f].file];for(const fl of schema[f].fields){const v=values[fl.key];if(v!==undefined&&v!==null)s=s.replace(new RegExp('^('+fl.key+'\\s*=\\s*)[^;]+;','m'),(_m,p)=>p+JSON.stringify(v)+';')}return s};
 const valuesFor=(f,id,patch)=>({...Object.fromEntries(schema[f].fields.map(x=>[x.key,x.value])),...schema[f].starters.find(s=>s.id===id).values,...patch});
 const run=(f,values,mode)=>new Promise(resolve=>{
  const worker=new Worker(new URL('./section-worker.mjs',import.meta.url),{workerData:'export-worker.js'});
  const timer=setTimeout(()=>{worker.terminate();resolve({type:'error',error:'timeout'})},300000);
  worker.on('error',e=>{clearTimeout(timer);worker.terminate();resolve({type:'error',error:String(e)})});
  worker.on('message',m=>{if(m.type==='result'||m.type==='error'){clearTimeout(timer);worker.terminate();resolve(m)}});
  worker.postMessage({filename:schema[f].file,source:configure(f,values),mode,sources});
 });
 const recordsOf=m=>[...new Set(((m.logs??[]).join('\n')+'\n'+(m.output??'')).split(/\r?\n/).flatMap(l=>{const r=l.match(/^ECHO: "([A-Z_]+\|.*)"\s*$/);return r?[r[1]]:[]}))];
 let failures=0;
 const fail=msg=>{failures++;console.log('FAIL '+msg)};
 const f=2,id='benchtop_wide_8_drawer'; // the starter whose drawer bottoms used to fuse with the box backs
 // 1. At the default gap the starter is clean and its layout is consistent.
 const good=valuesFor(f,id,{});
 const bom=await run(f,good,'bom');
 const cut=await run(f,good,'cut_layout');
 if(bom.type!=='result')fail('bom failed: '+bom.error);
 if(cut.type!=='result')fail('cut_layout failed: '+cut.error);
 else{
  const problems=checkCutLayout({records:recordsOf(bom),svg:cut.output,kerf:good.apply_kerf_compensation?good.kerf:0});
  for(const p of problems)fail(id+': '+p);
  if(!problems.length)console.log(`${id}: ${placements(recordsOf(bom)).length} parts placed, one contour each, no overlap.`);
 }
 // 2. A negative layout gap pushes rows into each other: the engine must say so and refuse the export.
 const bad=valuesFor(f,id,{layout_gap:-30});
 const bomBad=await run(f,bad,'bom');
 const recs=bomBad.type==='result'?recordsOf(bomBad):[];
 const overlaps=recs.filter(r=>r.startsWith('CHECK|ERROR|LAYOUT_OVERLAP|'));
 if(!overlaps.length)fail('layout_gap = -30 produced no CHECK|ERROR|LAYOUT_OVERLAP record');
 else console.log(`layout_gap = -30: ${overlaps.length} LAYOUT_OVERLAP error(s), e.g. ${overlaps[0].split('|').slice(3).join('|')}`);
 const jsOverlaps=checkCutLayout({records:recs}).filter(p=>p.includes('overlaps'));
 if(!jsOverlaps.length)fail('the placement table shows no overlap at layout_gap = -30');
 const cutBad=await run(f,bad,'cut_layout');
 if(cutBad.type!=='error'||!/Design Health/.test(cutBad.error))fail('the cut export was not blocked at layout_gap = -30: '+(cutBad.type==='error'?cutBad.error:'exported'));
 else console.log('cut export blocked: '+cutBad.error);
 if(failures){console.log(`Cut layout check: ${failures} failure(s).`);process.exitCode=1}
 else console.log('Cut layout check passed.');
}
