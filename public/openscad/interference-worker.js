import engine from './engine-v5-files.js';
import products from './product-files.js';
// Collision check for one design: each job is the design's engine source set to draw one part
// or group of parts in assembly position. Every job is rendered on its own (Manifold), the
// axis-aligned extents of the results are compared, and only the pairs whose extents overlap
// are intersected. Correctly fitted parts only touch (zero volume); any shared volume above
// the threshold means two parts would occupy the same space.
//   in:  {filename, sources, jobs:[{name, source}], threshold?: mm³}
//   out: {type:'progress', phase:'render'|'intersect', done, total, name}
//        {type:'result', parts, empty, pairs, candidates, overlaps:[{a, b, volume}], ms:{render, intersect, total}}
//        {type:'error', error, logs}
const engineFor=filename=>typeof filename==='string'&&Object.hasOwn(products.frontends,filename)?{frontends:products.frontends,files:products.files[filename]}:engine;
let compiled=null;
const compiling=(async()=>{if(typeof WorkerGlobalScope==='undefined'||typeof WebAssembly==='undefined'||typeof fetch!=='function')return;try{const r=await fetch(new URL('./openscad.wasm',self.location.href));compiled=await (WebAssembly.compileStreaming?WebAssembly.compileStreaming(r.clone()).catch(async()=>WebAssembly.compile(await r.arrayBuffer())):WebAssembly.compile(await r.arrayBuffer()))}catch{compiled=null}})();
async function engineOptions(options){await compiling;return compiled?{...options,instantiateWasm:(info,receive)=>{WebAssembly.instantiate(compiled,info).then(instance=>receive(instance,compiled));return {}}}:options}
async function run(OpenSCAD,files,main,args,out){
 const logs=[];
 const e=await OpenSCAD(await engineOptions({noInitialRun:true,locateFile:path=>new URL(path,self.location.href).href,print:l=>logs.push(String(l).slice(0,500)),printErr:l=>logs.push(String(l).slice(0,500))}));
 for(const [name,data] of files){const dir='/'+name.split('/').slice(0,-1).join('/');if(dir!=='/')e.FS.mkdirTree(dir);e.FS.writeFile('/'+name,data)}
 try{e.callMain(['/'+main,'--backend=Manifold',...args])}catch(x){logs.push('ERROR: '+(typeof x==='number'&&e.formatException?e.formatException(x):String(x)))}
 let data=null;try{data=e.FS.readFile(out)}catch{}
 return {logs,data};
}
// Enclosed volume of a binary STL (mm³).
function volume(buf){
 if(!buf||buf.length<84)return 0;const dv=new DataView(buf.buffer,buf.byteOffset,buf.byteLength),n=dv.getUint32(80,true);let v=0;
 for(let i=0;i<n;i++){const o=84+i*50+12,p=[];for(let k=0;k<9;k++)p.push(dv.getFloat32(o+k*4,true));v+=(p[0]*(p[4]*p[8]-p[5]*p[7])-p[1]*(p[3]*p[8]-p[5]*p[6])+p[2]*(p[3]*p[7]-p[4]*p[6]))/6}
 return Math.abs(v);
}
function extent(buf){
 const dv=new DataView(buf.buffer,buf.byteOffset,buf.byteLength),n=dv.getUint32(80,true),lo=[Infinity,Infinity,Infinity],hi=[-Infinity,-Infinity,-Infinity];
 for(let i=0;i<n;i++){const o=84+i*50+12;for(let k=0;k<9;k++){const v=dv.getFloat32(o+k*4,true),a=k%3;if(v<lo[a])lo[a]=v;if(v>hi[a])hi[a]=v}}
 return {lo,hi};
}
const meet=(a,b)=>[0,1,2].every(k=>a.lo[k]<b.hi[k]-0.01&&b.lo[k]<a.hi[k]-0.01);
self.onmessage=async({data})=>{
 if(data&&data.type==='warm'){try{await compiling;await import('./openscad.js')}catch{}self.postMessage({type:'warm'});return}
 const started=performance.now();let logs=[];
 try{
  const {filename,sources,jobs}=data,threshold=Number.isFinite(data.threshold)?Math.max(0,data.threshold):1;
  const manifest=engineFor(filename);
  if(!Object.hasOwn(manifest.frontends,filename)||!Array.isArray(jobs)||jobs.length<2||jobs.length>400||!jobs.every(j=>j&&typeof j.name==='string'&&j.name.length<=80&&typeof j.source==='string'&&j.source.length<2000000))throw Error('Invalid collision check request. Refresh the app and try again.');
  if(!Array.isArray(sources)||sources.length!==manifest.files.length||!manifest.files.every(name=>sources.some(f=>f.name===name&&typeof f.text==='string'&&f.text.length<2000000)))throw Error('Invalid engine snapshot. Refresh the app and try again.');
  const {default:OpenSCAD}=await import('./openscad.js');
  const base=sources.map(f=>[f.name,f.text]),stl={},ext={};let empty=0;
  for(let i=0;i<jobs.length;i++){
   const j=jobs[i];self.postMessage({type:'progress',phase:'render',done:i,total:jobs.length,name:j.name});
   const r=await run(OpenSCAD,[...base,[filename,j.source]],filename,['--export-format=binstl','-o','/part.stl'],'/part.stl');
   const bad=r.logs.filter(l=>/^ERROR|ECHO: "ERROR\||^WARNING: (undefined operation|Ignoring unknown variable)/.test(l));
   if(bad.length){logs=r.logs.slice(-40);throw Error(`OpenSCAD could not render ${j.name}: ${bad[0]}`)}
   if(r.data&&r.data.length>84){stl[j.name]=r.data;ext[j.name]=extent(r.data)}else empty++;
  }
  const rendered=performance.now(),names=Object.keys(stl),candidates=[];
  for(let a=0;a<names.length;a++)for(let b=a+1;b<names.length;b++)if(meet(ext[names[a]],ext[names[b]]))candidates.push([names[a],names[b]]);
  const overlaps=[];
  for(let k=0;k<candidates.length;k++){
   const [a,b]=candidates[k];self.postMessage({type:'progress',phase:'intersect',done:k,total:candidates.length,name:a+' × '+b});
   const r=await run(OpenSCAD,[['a.stl',stl[a]],['b.stl',stl[b]],['i.scad','intersection(){import("/a.stl");import("/b.stl");}']],'i.scad',['--export-format=binstl','-o','/o.stl'],'/o.stl');
   const v=volume(r.data);if(v>threshold)overlaps.push({a,b,volume:v});
  }
  const done=performance.now();
  self.postMessage({type:'result',parts:names.length,empty,pairs:names.length*(names.length-1)/2,candidates:candidates.length,overlaps:overlaps.sort((x,y)=>y.volume-x.volume),ms:{render:rendered-started,intersect:done-rendered,total:done-started}});
 }catch(e){self.postMessage({type:'error',error:e instanceof Error?e.message:String(e),logs})}
};
