// Runs a collision check (jobs from lib/interference.ts) across a pool of interference
// workers (public/openscad/interference-worker.js): every job is rendered on its own, the
// extents of the results are compared, and only the pairs whose extents meet are intersected.
// Renders and intersections are spread over the pool's workers.
//
// A cache kept between runs skips work whose inputs have not changed: a job's render is reused
// when the engine files and the job's own source are the same, and a pair's shared volume is
// reused when both rendered parts are byte for byte the same. A check of an unchanged design
// is therefore immediate, and after a change only the pairs that involve a changed part are
// intersected again.
import type {CollisionJob} from './interference';

export type Overlap={a:string;b:string;volume:number};
export type CollisionResult={parts:number;empty:number;pairs:number;candidates:number;overlaps:Overlap[];ms:{render:number;intersect:number;total:number};workers:number;reused:{renders:number;pairs:number}};
export type CollisionProgress={phase:'render'|'intersect';done:number;total:number;name:string};
type Extent={lo:number[];hi:number[]};
// What the pool needs of a worker: the browser's Worker, or a Node adapter in the tests.
export type WorkerLike={postMessage(message:unknown,transfer?:Transferable[]):void;onmessage:((event:{data:unknown})=>void)|null;onerror:((event:unknown)=>void)|null;terminate():void};

// Workers for this machine: one per core, keeping one for the page, at most 4 (each holds an
// OpenSCAD engine in memory).
export const MAX_COLLISION_WORKERS=4;
export const collisionWorkerCount=(cores?:number)=>Math.max(1,Math.min(MAX_COLLISION_WORKERS,(cores||2)-1));

// 2 × 53-bit string and byte hashes (cyrb53 with two seeds): cache keys, not security.
function cyrb(read:(i:number)=>number,n:number,seed:number){
 let h1=0xdeadbeef^seed,h2=0x41c6ce57^seed;
 for(let i=0;i<n;i++){const c=read(i);h1=Math.imul(h1^c,2654435761);h2=Math.imul(h2^c,1597334677)}
 h1=Math.imul(h1^(h1>>>16),2246822507)^Math.imul(h2^(h2>>>13),3266489909);
 h2=Math.imul(h2^(h2>>>16),2246822507)^Math.imul(h1^(h1>>>13),3266489909);
 return (4294967296*(2097151&h2)+(h1>>>0)).toString(36);
}
export const hashText=(s:string)=>s.length+':'+cyrb(i=>s.charCodeAt(i),s.length,1)+cyrb(i=>s.charCodeAt(i),s.length,2);
export function hashBytes(b:Uint8Array){
 const words=b.byteLength>>2,v=new DataView(b.buffer,b.byteOffset,b.byteLength),tail=b.byteLength&3;
 const read=(i:number)=>i<words?v.getUint32(i*4,true):b[words*4+(i-words)];
 return b.byteLength+':'+cyrb(read,words+tail,1)+cyrb(read,words+tail,2);
}

type Render={stl:Uint8Array|null;ext:Extent|null;hash:string};
// Renders and pair volumes of earlier runs, oldest dropped first once the rendered parts
// exceed the byte limit.
export class CollisionCache{
 renders=new Map<string,Render>();pairs=new Map<string,number>();bytes=0;
 constructor(readonly limit=128*1024*1024){}
 getRender(key:string){const r=this.renders.get(key);if(r){this.renders.delete(key);this.renders.set(key,r)}return r}
 setRender(key:string,r:Render){
  const old=this.renders.get(key);if(old){this.bytes-=old.stl?.byteLength??0;this.renders.delete(key)}
  this.renders.set(key,r);this.bytes+=r.stl?.byteLength??0;
  for(const [k,x] of this.renders){if(this.bytes<=this.limit||k===key)break;this.bytes-=x.stl?.byteLength??0;this.renders.delete(k)}
  while(this.pairs.size>20000)this.pairs.delete(this.pairs.keys().next().value as string);
 }
 clear(){this.renders.clear();this.pairs.clear();this.bytes=0}
}

type Slot={worker:WorkerLike;busy:boolean;init:string|null;pending:Map<number,{resolve:(d:Record<string,unknown>)=>void;reject:(e:Error)=>void}>};
// A fixed set of workers; requests go to the first idle one, in order.
export class CollisionPool{
 private slots:Slot[]=[];private queue:{message:Record<string,unknown>;transfer:Transferable[];init:{key:string;filename:string;sources:unknown};resolve:(d:Record<string,unknown>)=>void;reject:(e:Error)=>void}[]=[];private next=1;private dead:Error|null=null;
 constructor(create:()=>WorkerLike,readonly size:number){
  for(let i=0;i<size;i++){
   const slot:Slot={worker:create(),busy:false,init:null,pending:new Map()};
   slot.worker.onmessage=({data})=>{
    const d=data as Record<string,unknown>,p=slot.pending.get(d.id as number);if(!p)return;
    slot.pending.delete(d.id as number);
    if(d.type==='error'){const e=Error(String(d.error));(e as Error&{logs?:unknown}).logs=d.logs;p.reject(e)}else p.resolve(d);
    if(!slot.pending.size){slot.busy=false;this.pump()}
   };
   slot.worker.onerror=()=>this.fail(Error('Could not start the OpenSCAD engine in this browser.'));
   this.slots.push(slot);
  }
 }
 private fail(e:Error){this.dead=e;for(const s of this.slots){for(const p of s.pending.values())p.reject(e);s.pending.clear()}for(const q of this.queue.splice(0))q.reject(e)}
 private send(slot:Slot,message:Record<string,unknown>,transfer:Transferable[]=[]){
  const id=this.next++;return new Promise<Record<string,unknown>>((resolve,reject)=>{slot.pending.set(id,{resolve,reject});slot.worker.postMessage({...message,id},transfer)});
 }
 private pump(){
  for(const slot of this.slots){
   if(slot.busy||!this.queue.length)continue;
   const q=this.queue.shift()!;slot.busy=true;
   // A worker is given the engine files once; it keeps them for later requests.
   const init=slot.init===q.init.key?null:this.send(slot,{type:'init',filename:q.init.filename,sources:q.init.sources});
   slot.init=q.init.key;
   if(init)init.catch(e=>{slot.init=null;q.reject(e)});
   this.send(slot,q.message,q.transfer).then(q.resolve,q.reject);
  }
 }
 request(init:{key:string;filename:string;sources:unknown},message:Record<string,unknown>,transfer:Transferable[]=[]){
  if(this.dead)return Promise.reject(this.dead);
  return new Promise<Record<string,unknown>>((resolve,reject)=>{this.queue.push({message,transfer,init,resolve,reject});this.pump()});
 }
 terminate(){for(const s of this.slots)s.worker.terminate();this.fail(Error('Stopped.'))}
}

const meet=(a:Extent,b:Extent)=>[0,1,2].every(k=>a.lo[k]<b.hi[k]-0.01&&b.lo[k]<a.hi[k]-0.01);
const now=()=>globalThis.performance?.now()??Date.now();

export async function runCollisionCheck(o:{pool:CollisionPool;filename:string;sources:{name:string;text:string}[];jobs:CollisionJob[];threshold:number;cache?:CollisionCache;onProgress?:(p:CollisionProgress)=>void}):Promise<CollisionResult>{
 const {pool,filename,sources,jobs,cache,onProgress}=o,threshold=Number.isFinite(o.threshold)?Math.max(0,o.threshold):1;
 if(!Array.isArray(jobs)||jobs.length<2||jobs.length>400||new Set(jobs.map(j=>j?.name)).size!==jobs.length||!jobs.every(j=>j&&typeof j.name==='string'&&j.name.length<=80&&typeof j.source==='string'&&j.source.length<2000000))throw Error('Invalid collision check request. Refresh the app and try again.');
 const started=now();
 const engineKey=hashText(filename+'\n'+sources.map(f=>f.name+'\n'+hashText(f.text)).join('\n'));
 const init={key:engineKey,filename,sources};
 // ---- render ----
 const renders:Record<string,Render>={};let reusedRenders=0,done=0;
 await Promise.all(jobs.map(async j=>{
  const key=engineKey+'|'+hashText(j.source),hit=cache?.getRender(key);
  if(hit){renders[j.name]=hit;reusedRenders++;onProgress?.({phase:'render',done:++done,total:jobs.length,name:j.name});return}
  onProgress?.({phase:'render',done,total:jobs.length,name:j.name});
  const r=await pool.request(init,{type:'render',name:j.name,source:j.source});
  const stl=r.stl instanceof Uint8Array&&r.stl.byteLength>84?r.stl:null;
  const out:Render={stl,ext:stl?r.ext as Extent:null,hash:stl?hashBytes(stl):''};
  renders[j.name]=out;cache?.setRender(key,out);
  onProgress?.({phase:'render',done:++done,total:jobs.length,name:j.name});
 }));
 const rendered=now();
 // ---- intersect the pairs whose extents meet ----
 const names=jobs.map(j=>j.name).filter(n=>renders[n].stl),candidates:[string,string][]=[];
 for(let a=0;a<names.length;a++)for(let b=a+1;b<names.length;b++)if(meet(renders[names[a]].ext!,renders[names[b]].ext!))candidates.push([names[a],names[b]]);
 const overlaps:Overlap[]=[];let reusedPairs=0;done=0;
 await Promise.all(candidates.map(async([a,b])=>{
  const ra=renders[a],rb=renders[b],key=[ra.hash,rb.hash].sort().join('|');
  let volume=cache?.pairs.get(key);
  if(volume===undefined){
   onProgress?.({phase:'intersect',done,total:candidates.length,name:a+' × '+b});
   // The cache keeps the renders, so the worker gets copies.
   const r=await pool.request(init,{type:'intersect',a:ra.stl!.slice(),b:rb.stl!.slice()});
   volume=Number(r.volume)||0;cache?.pairs.set(key,volume);
  }else reusedPairs++;
  if(volume>threshold)overlaps.push({a,b,volume});
  onProgress?.({phase:'intersect',done:++done,total:candidates.length,name:a+' × '+b});
 }));
 const finished=now();
 return {parts:names.length,empty:jobs.length-names.length,pairs:names.length*(names.length-1)/2,candidates:candidates.length,overlaps:overlaps.sort((x,y)=>y.volume-x.volume),ms:{render:rendered-started,intersect:finished-rendered,total:finished-started},workers:pool.size,reused:{renders:reusedRenders,pairs:reusedPairs}};
}
