// Layout editor model against the engine. For every starter of the five cabinet
// types with a layout editor, the editor's opening tree must (1) map back to the
// same cabinet without changing any front, (2) place openings where the engine
// does, and (3) typed sizes and drags must produce exactly the requested engine
// dimensions.
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
 new Function('require','module','exports',ts.transpileModule(fs.readFileSync(new URL('lib/'+name+'.ts',root),'utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2022,esModuleInterop:true}}).outputText)(n=>{if(n in deps)return deps[n];throw Error('missing dep '+n+' for '+name)},m,m.exports);
 return m.exports;
}
const sections=load('sections');
const cabinet=load('cabinet',{'./sections':sections,'./schema.json':schema,'./engine-sources.json':bundle});
const {analyse}=load('analysis',{'./manufacturing':load('manufacturing')});
const L=load('layout',{'./cabinet':cabinet,'./sections':sections,'./settings':load('settings')});
const configure=(f,values)=>{let s=bundle[schema[f].file];for(const fl of schema[f].fields){const v=values[fl.key];if(v!==undefined&&v!==null)s=s.replace(new RegExp('^('+fl.key+'\\s*=\\s*)[^;]+;','m'),(_m,p)=>p+JSON.stringify(v)+';')}return s};
function bom(f,values){
 const worker=new Worker(new URL('./section-worker.mjs',import.meta.url),{workerData:'export-worker.js'});
 return new Promise((resolve,reject)=>{
  const timer=setTimeout(()=>{worker.terminate();reject(Error('timeout'))},180000);
  worker.on('error',e=>{clearTimeout(timer);worker.terminate();reject(e)});
  worker.on('message',m=>{if(m.type==='result'||m.type==='error'){clearTimeout(timer);worker.terminate();const text=(m.logs??[]).join('\n')+'\n'+(typeof m.output==='string'?m.output:'');resolve({type:m.type,text,plan:analyse(text)})}});
  worker.postMessage({filename:schema[f].file,source:configure(f,values),mode:'bom',sources});
 });
}
const valuesFor=(f,id,patch={})=>cabinet.normalizeValues(f,{...cabinet.starterValues(f,id??schema[f].defaultStarter),...patch});
const close=(a,b,tol=0.01)=>Math.abs(a-b)<=tol;
const errorsOf=plan=>plan.issues.filter(i=>i.severity==='error');
function sameFronts(a,b,label){
 assert.equal(a.fronts.length,b.fronts.length,label+': front count');
 for(const f of a.fronts){
  const g=b.fronts.find(x=>x.id===f.id);
  assert(g,label+': missing front '+f.id);
  for(const k of ['x','z','w','h'])assert(close(f[k],g[k]),`${label}: front ${f.id} ${k} ${f[k]} -> ${g[k]}`);
 }
 assert.equal(a.shelves.length,b.shelves.length,label+': shelf count');
}

// 1-2. Every starter: lossless round trip and engine-matching openings.
const jobs=[];
for(let f=0;f<5;f++)for(const st of schema[f].starters)jobs.push({f,id:st.id});
let next=0,checked=0,bound=0;
async function lane(){
 while(next<jobs.length){
  const {f,id}=jobs[next++],v=valuesFor(f,id),label=f+':'+id;
  const a=await bom(f,v);
  assert.equal(a.type,'result',label);
  const report=a.plan.layout;
  assert(report,label+': no layout report');
  const tree=L.fromValues(f,v,report);
  assert(tree,label+': no tree');
  const map=L.toValues(f,v,tree,report);
  assert(!('error' in map),label+': '+map.error);
  assert.equal(map.mode,L.currentMode(f,v),label+': construction changed');
  const v2=cabinet.normalizeValues(f,{...v,...map.patch});
  const b=await bom(f,v2);
  assert.equal(b.type,'result',label);
  if(report.mode!=='sections')sameFronts(report,b.plan.layout,label);
  else for(const s of report.sections){const t=b.plan.layout.sections.find(x=>x.index===s.index);assert(t&&['x','z','w','h'].every(k=>close(s[k],t[k])),label+': section '+s.index)}
  // Openings computed by the editor from the tree alone must match the engine.
  const g=L.geometry(f,v,tree,L.frameFor(f,v,report),undefined);
  for(const c of g.cells){
   const ref=c.node.ref??{};
   const bay=ref.bay!==undefined&&report.bays.find(x=>x.index===ref.bay),bank=ref.bank!==undefined&&report.banks.find(x=>x.index===ref.bank),sec=ref.section!==undefined&&report.sections.find(x=>x.index===ref.section);
   const target=bay||bank||sec;
   if(target){assert(close(c.rect.x,target.x,0.05)&&close(c.rect.w,target.w,0.05),`${label}: opening ${c.path} x/w ${c.rect.x}/${c.rect.w} vs engine ${target.x}/${target.w}`);bound++}
   if(sec)assert(close(c.rect.z,sec.z,0.05)&&close(c.rect.h,sec.h,0.05),`${label}: section ${c.path} z/h`);
   if(ref.doors&&report.doorRegion&&L.shape(tree)==='combo')assert(close(c.rect.h,report.doorRegion.h,0.05),`${label}: door region ${c.rect.h} vs ${report.doorRegion.h}`);
  }
  checked++;
 }
}
await Promise.all(Array.from({length:Math.max(1,Math.min(4,os.cpus().length))},lane));
console.log(`Layout editor: ${checked} starters round-trip without changing any front; ${bound} openings match the engine.`);

// 3. Edits produce exactly the requested engine dimensions.
async function edit(f,v,fn){
 const a=await bom(f,v),report=a.plan.layout,frame=L.frameFor(f,v,report),tree=L.fromValues(f,v,report,frame),g=L.geometry(f,v,tree,frame,report);
 const out=fn({tree,g,report,frame});
 if('error' in out)return out;
 const map=L.toValues(f,v,out,report,frame);
 if('error' in map)return map;
 const v2=cabinet.normalizeValues(f,{...v,...map.patch}),b=await bom(f,v2);
 return {map,v2,plan:b.plan,report:b.plan.layout};
}
const p0=L.profile(0);
// Shop cart: type a bay width.
{
 const r=await edit(0,valuesFor(0),({tree,g})=>L.setChildSize(tree,[],0,300,L.childSizes(g,tree,[]),false));
 assert(close(r.report.bays[0].w,300),'bay width '+r.report.bays[0].w);
 assert.deepEqual(errorsOf(r.plan),[]);
}
// Shop cart: type a drawer front height.
{
 const r=await edit(0,valuesFor(0),({tree,g,report})=>{const cell=g.cells.find(c=>c.node.contents==='drawers'),fronts=L.frontsFor(cell,valuesFor(0),report);return L.setDrawerHeight(tree,cell.path,1,120,fronts.map(f=>f.nominal))});
 const d2=r.report.fronts.find(f=>f.id==='B1-D2');
 assert(close(d2.nominal,120),'drawer front '+d2.nominal);
 assert.deepEqual(errorsOf(r.plan),[]);
}
// Utility (drawers over doors): drag the drawer/door boundary, then type a door height.
{
 const v=valuesFor(1);
 const r=await edit(1,v,({tree,g})=>L.moveBoundary(tree,[],1,-80,L.childSizes(g,tree,[])));
 assert(r.map.patch.combo_door_height>0,'combo door height set');
 assert(close(r.report.doorRegion.h,r.map.patch.combo_door_height),'door region follows the drag');
 const t=await edit(1,r.v2,({tree,g,report})=>{const doors=report.fronts.find(f=>f.kind==='door'),region=report.doorRegion.h;return L.setChildSize(tree,[],1,500-(doors.h-region),L.childSizes(g,tree,[]),false)});
 assert(close(t.report.fronts.find(f=>f.kind==='door').h,500),'door front height '+t.report.fronts.find(f=>f.kind==='door').h);
 assert.deepEqual(errorsOf(t.plan),[]);
}
// Benchtop: add a drawer column and type its width.
{
 const r=await edit(2,valuesFor(2),({tree})=>L.splitColumns(tree,[]));
 assert.equal(r.v2.drawer_bank_count,2);
 const t=await edit(2,r.v2,({tree,g})=>L.setChildSize(tree,[],1,120,L.childSizes(g,tree,[]),false));
 assert(close(t.report.banks[1].w,120),'bank width '+t.report.banks[1].w);
 assert.deepEqual(errorsOf(t.plan),[]);
}
// Stackable: a door module; side-by-side doors are refused with a reason.
{
 const r=await edit(3,valuesFor(3),({tree})=>L.changeContents(tree,[],'doors',L.profile(3),false,400));
 assert.equal(r.v2.module_type,'door');
 const bad=await edit(3,r.v2,({tree})=>L.splitColumns(tree,[]));
 assert(bad.error&&/must all be drawers/.test(bad.error),String(bad.error));
}
// Shop cart: stacking inside a bay is refused (kitchen only), and a fifth bay is refused.
{
 const v=valuesFor(0);
 const nested=await edit(0,v,({tree})=>L.splitRows(tree,[1],p0,600));
 assert(nested.error&&/cannot stack/.test(nested.error),String(nested.error));
 let tree=L.fromValues(0,v);for(let i=0;i<2;i++)tree=L.splitColumns(tree,[0]);
 assert(!('error' in L.toValues(0,v,tree)),'four bays allowed');
 const five=L.toValues(0,v,L.splitColumns(tree,[0]));
 assert(five.error,'fifth bay refused');
}
// Kitchen: splitting the doors below the drawer side by side needs sections; the layout still builds.
{
 const v=valuesFor(4,'kitchen_standard_B36');
 const r=await edit(4,v,({tree})=>L.splitColumns(tree,[1]));
 assert.equal(r.map.mode,'sections');
 assert.deepEqual(errorsOf(r.plan),[]);
 const leaves=r.plan.layout.sections;
 assert.equal(leaves.length,3);
}
// Kitchen with a face frame: bays with drawers at the ends use sections instead of a rejected bay layout.
{
 const v=valuesFor(4,'kitchen_standard_B36');
 const r=await edit(4,v,({tree})=>{let t=L.changeContents(L.fromValues(4,v),[],'drawers',L.profile(4),false,900);t=L.changeContents(t,[1],'doors',L.profile(4),false,900);return L.splitColumns(L.splitColumns(L.removeOpening(t,[1]),[]),[0])});
 assert.deepEqual(errorsOf(r.plan),[]);
}
// Mixed bays: changing a bay to doors keeps the bay construction and hinge choice.
{
 const v=valuesFor(0);
 const r=await edit(0,v,({tree})=>L.setLeaf(L.changeContents(tree,[1],'doors',p0,true,300),[1],{hinge:'right'}));
 assert.equal(r.map.mode,'mixed_bays');
 assert.equal(r.report.fronts.find(f=>f.kind==='door').hinge,'right');
 assert.deepEqual(errorsOf(r.plan),[]);
}
console.log('Layout editor edits: typed bay widths, drawer fronts and door heights land exactly; drags, column splits, module contents, kitchen sections and refusals behave as described.');
