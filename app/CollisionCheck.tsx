'use client';
// On-demand 3D collision check for the design on screen: every part (or group of parts) is
// rendered on its own, spread over a pool of workers (lib/collision-run.ts), pairs whose
// extents meet are intersected, and any shared volume is listed. Runs only when asked. Renders
// and pair results are kept for the session, so checking an unchanged design again is immediate
// and after a change only what changed is done again.
import {useEffect,useRef,useState} from 'react';
import {Boxes,Check,LoaderCircle,TriangleAlert,X} from 'lucide-react';
import {assetUrl} from '@/lib/asset-url';
import type {CollisionJob} from '@/lib/interference';
import {CollisionCache,CollisionPool,collisionWorkerCount,runCollisionCheck,type CollisionResult as Result} from '@/lib/collision-run';

// One cache for every design of the session (bounded in lib/collision-run.ts).
const cache=new CollisionCache();
type State={kind:'idle'}|{kind:'running';phase:'render'|'intersect';done:number;total:number;name:string;key:string}|{kind:'done';result:Result;key:string}|{kind:'failed';error:string;key:string};
type Props={
 // The design's identity: a result for another key is shown as out of date.
 designKey:string;filename:string;sources:{name:string;text:string}[];
 // The jobs for the current design, or a reason the check cannot run yet.
 jobs:()=>CollisionJob[]|string;threshold:number;
 // What one job is: "part" for products, "part group" for cabinets (made plural with s).
 unit:string;
};
const seconds=(ms:number)=>ms<10000?(ms/1000).toFixed(1)+' s':Math.round(ms/1000)+' s';
// Work taken from an earlier check of the same parts.
function reusedNote(r:Result){
 if(!r.reused.renders&&!r.reused.pairs)return '';
 return ` Reused from an earlier check: ${r.reused.renders} of ${r.parts+r.empty} renders, ${r.reused.pairs} of ${r.candidates} pair results.`;
}
const label=(id:string)=>id.replace(/([a-z])([A-Z])/g,'$1 $2').replaceAll('_',' ');

export default function CollisionCheck({designKey,filename,sources,jobs,threshold,unit}:Props){
 const [state,setState]=useState<State>({kind:'idle'});
 // The pool lives while the panel is open, so its workers compile the engine once.
 const pool=useRef<CollisionPool|null>(null),run=useRef(0);
 const drop=()=>{pool.current?.terminate();pool.current=null};
 useEffect(()=>drop,[]);
 const stop=()=>{run.current++;drop();setState({kind:'idle'})};
 async function start(){
  const list=jobs();
  if(typeof list==='string'){setState({kind:'failed',error:list,key:designKey});return}
  const key=designKey,mine=++run.current;
  setState({kind:'running',phase:'render',done:0,total:list.length,name:list[0]?.name??'',key});
  try{
   pool.current??=new CollisionPool(()=>new Worker(assetUrl('/openscad/interference-worker.js'),{type:'module'}) as never,collisionWorkerCount(navigator.hardwareConcurrency));
   const result=await runCollisionCheck({pool:pool.current,filename,sources,jobs:list,threshold,cache,onProgress:p=>{if(run.current===mine)setState({kind:'running',...p,key})}});
   if(run.current===mine)setState({kind:'done',result,key});
  }catch(e){
   if(run.current!==mine)return;
   // Work still queued for a failed check is dropped with its workers.
   drop();setState({kind:'failed',error:e instanceof Error?e.message:String(e),key});
  }
 }
 const stale=state.kind!=='idle'&&state.key!==designKey;
 return <section className={'collision-check'+(stale?' is-stale':'')} aria-label='3D collision check'>
  <div className='collision-head'>
   <Boxes size={17}/>
   <div><strong>Parts intersecting in 3D</strong><small>Renders every {unit} of this design on its own and intersects the ones that meet. Takes from seconds to a few minutes.</small></div>
   {state.kind==='running'?<button type='button' onClick={stop}><X size={15}/>Stop</button>:<button type='button' className='primary' onClick={start}>{state.kind==='idle'?'Check for intersecting parts':'Check again'}</button>}
  </div>
  {state.kind==='running'&&<div className='collision-progress' role='status'>
   <LoaderCircle size={15} className='render-spinner'/>
   <span>{state.phase==='render'?`Rendering ${state.done+1} of ${state.total}: ${label(state.name)}`:`Intersecting pair ${state.done+1} of ${state.total}: ${state.name.split(' × ').map(label).join(' × ')}`}</span>
   <progress max={state.total} value={state.done}/>
  </div>}
  {stale&&<p className='collision-stale'>The settings changed since this check. Check again to see the current design.</p>}
  {state.kind==='failed'&&<p className='collision-result is-bad'><TriangleAlert size={15}/>{state.error}</p>}
  {state.kind==='done'&&(state.result.overlaps.length?<div className='collision-result is-bad'>
   <p><TriangleAlert size={15}/>{state.result.overlaps.length} pair{state.result.overlaps.length===1?'':'s'} of parts share volume:</p>
   <ul>{state.result.overlaps.map(o=><li key={o.a+o.b}><strong>{label(o.a)}</strong> and <strong>{label(o.b)}</strong> · {o.volume<1000?Math.round(o.volume)+' mm³':(o.volume/1000).toFixed(1)+' cm³'}</li>)}</ul>
  </div>:<p className='collision-result is-ok'><Check size={15}/>No parts intersect.</p>)}
  {state.kind==='done'&&(state.result.reused.renders===state.result.parts+state.result.empty&&state.result.reused.pairs===state.result.candidates?<p className='collision-stats'>Same parts as an earlier check: all {state.result.parts+state.result.empty} renders and {state.result.candidates} pair results reused ({state.result.parts} {unit}s with geometry, {state.result.candidates} of {state.result.pairs} pairs close enough to intersect).</p>:<p className='collision-stats'>{state.result.parts} {unit}s rendered, {state.result.candidates} of {state.result.pairs} pairs close enough to intersect (the rest are apart), in {seconds(state.result.ms.total)} on {state.result.workers} worker{state.result.workers===1?'':'s'}: rendering {seconds(state.result.ms.render)}, intersecting {seconds(state.result.ms.intersect)}.{reusedNote(state.result)}</p>)}
 </section>;
}
