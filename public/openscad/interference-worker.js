import engine from './engine-v5-files.js';
import products from './product-files.js';
// One worker of the collision check's pool (lib/collision-run.ts runs the check and spreads
// it over several of these). A worker is given a design's engine files once, then renders jobs
// (the design's engine source set to draw one part or group of parts in assembly position) to
// STL with Manifold, and intersects pairs of rendered parts.
//   in:  {type:'init', id, filename, sources}            -> {type:'ready', id}
//        {type:'render', id, name, source}               -> {type:'rendered', id, stl: Uint8Array|null, ext: {lo, hi}|null}
//        {type:'intersect', id, a: Uint8Array, b: Uint8Array} -> {type:'intersected', id, volume: mm³}
//        {type:'warm'}                                    -> {type:'warm'}
//   any request may instead answer {type:'error', id, error, logs}
const engineFor=filename=>typeof filename==='string'&&Object.hasOwn(products.frontends,filename)?{frontends:products.frontends,files:products.files[filename]}:engine;
let compiled=null;
const compiling=(async()=>{if(typeof WorkerGlobalScope==='undefined'||typeof WebAssembly==='undefined'||typeof fetch!=='function')return;try{const r=await fetch(new URL('./openscad.wasm',self.location.href));compiled=await (WebAssembly.compileStreaming?WebAssembly.compileStreaming(r.clone()).catch(async()=>WebAssembly.compile(await r.arrayBuffer())):WebAssembly.compile(await r.arrayBuffer()))}catch{compiled=null}})();
async function engineOptions(options){await compiling;return compiled?{...options,instantiateWasm:(info,receive)=>{WebAssembly.instantiate(compiled,info).then(instance=>receive(instance,compiled));return {}}}:options}
async function run(files,main,args,out){
 const {default:OpenSCAD}=await import('./openscad.js');
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
const isStl=x=>x instanceof Uint8Array&&x.byteLength>=84&&x.byteLength<512*1024*1024;
let design=null;
self.onmessage=async({data})=>{
 if(data&&data.type==='warm'){try{await compiling;await import('./openscad.js')}catch{}self.postMessage({type:'warm'});return}
 const id=data?.id;let logs=[];
 try{
  if(data?.type==='init'){
   const {filename,sources}=data,manifest=engineFor(filename);
   design=null;
   if(!Object.hasOwn(manifest.frontends,filename))throw Error('Invalid collision check request. Refresh the app and try again.');
   if(!Array.isArray(sources)||sources.length!==manifest.files.length||!manifest.files.every(name=>sources.some(f=>f.name===name&&typeof f.text==='string'&&f.text.length<2000000)))throw Error('Invalid engine snapshot. Refresh the app and try again.');
   design={filename,base:sources.map(f=>[f.name,f.text])};
   self.postMessage({type:'ready',id});
  }else if(data?.type==='render'){
   const {name,source}=data;
   if(!design||typeof name!=='string'||name.length>80||typeof source!=='string'||source.length>=2000000)throw Error('Invalid collision check request. Refresh the app and try again.');
   const r=await run([...design.base,[design.filename,source]],design.filename,['--export-format=binstl','-o','/part.stl'],'/part.stl');
   const bad=r.logs.filter(l=>/^ERROR|ECHO: "ERROR\||^WARNING: (undefined operation|Ignoring unknown variable)/.test(l));
   if(bad.length){logs=r.logs.slice(-40);throw Error(`OpenSCAD could not render ${name}: ${bad[0]}`)}
   const stl=r.data&&r.data.length>84?r.data:null;
   self.postMessage({type:'rendered',id,stl,ext:stl?extent(stl):null},stl?[stl.buffer]:[]);
  }else if(data?.type==='intersect'){
   if(!isStl(data.a)||!isStl(data.b))throw Error('Invalid collision check request. Refresh the app and try again.');
   const r=await run([['a.stl',data.a],['b.stl',data.b],['i.scad','intersection(){import("/a.stl");import("/b.stl");}']],'i.scad',['--export-format=binstl','-o','/o.stl'],'/o.stl');
   self.postMessage({type:'intersected',id,volume:volume(r.data)});
  }else throw Error('Invalid collision check request. Refresh the app and try again.');
 }catch(e){self.postMessage({type:'error',id,error:e instanceof Error?e.message:String(e),logs})}
};
