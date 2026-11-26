'use client';
// On-demand 3D collision check for the design on screen: every part (or group of parts) is
// rendered on its own in a worker, pairs whose extents meet are intersected, and any shared
// volume is listed. Runs only when asked: it takes from seconds to a few minutes.
import {useEffect,useRef,useState} from 'react';
import {Boxes,Check,LoaderCircle,TriangleAlert,X} from 'lucide-react';
import {assetUrl} from '@/lib/asset-url';
import type {CollisionJob} from '@/lib/interference';

type Result={parts:number;empty:number;pairs:number;candidates:number;overlaps:{a:string;b:string;volume:number}[];ms:{render:number;intersect:number;total:number}};
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
const label=(id:string)=>id.replace(/([a-z])([A-Z])/g,'$1 $2').replaceAll('_',' ');

export default function CollisionCheck({designKey,filename,sources,jobs,threshold,unit}:Props){
 const [state,setState]=useState<State>({kind:'idle'});
 const worker=useRef<Worker|null>(null);
 useEffect(()=>()=>{worker.current?.terminate();worker.current=null},[]);
 const stop=()=>{worker.current?.terminate();worker.current=null;setState({kind:'idle'})};
 function start(){
  const list=jobs();
  if(typeof list==='string'){setState({kind:'failed',error:list,key:designKey});return}
  worker.current?.terminate();
  const w=new Worker(assetUrl('/openscad/interference-worker.js'),{type:'module'});worker.current=w;
  const key=designKey;
  setState({kind:'running',phase:'render',done:0,total:list.length,name:list[0]?.name??'',key});
  w.onmessage=({data})=>{
   if(worker.current!==w)return;
   if(data.type==='progress')setState({kind:'running',phase:data.phase,done:data.done,total:data.total,name:data.name,key});
   else if(data.type==='result'||data.type==='error'){
    w.terminate();worker.current=null;
    setState(data.type==='result'?{kind:'done',result:data,key}:{kind:'failed',error:data.error,key});
   }
  };
  w.onerror=()=>{w.terminate();worker.current=null;setState({kind:'failed',error:'Could not start the OpenSCAD engine in this browser.',key})};
  w.postMessage({filename,sources,jobs:list,threshold});
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
  {state.kind==='done'&&<p className='collision-stats'>{state.result.parts} {unit}s rendered, {state.result.candidates} of {state.result.pairs} pairs close enough to intersect (the rest are apart), in {seconds(state.result.ms.total)}: rendering {seconds(state.result.ms.render)}, intersecting {seconds(state.result.ms.intersect)}.</p>}
 </section>;
}
