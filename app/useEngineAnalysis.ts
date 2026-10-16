'use client';
import {useEffect,useRef,useState} from 'react';
import {assetUrl} from '@/lib/asset-url';
import {configuredSource,renderSources,schemas,validate,Values} from '@/lib/cabinet';
import {analyse,Plan} from '@/lib/analysis';
export type Analysis={state:'idle'|'waiting'|'running'|'ready'|'failed'|'invalid';plan:Plan|null;key:string;planKey:string;error:string;log:string;seconds:number};
// Re-runs the engine's BOM/validation pass shortly after each edit. One worker is kept warm
// between runs (the engine is compiled once and reused); an edit that lands mid-run terminates
// that run and a fresh worker takes over. The last good plan stays visible (marked stale).
export default function useEngineAnalysis(family:number,values:Values,delay=650):Analysis&{rerun:()=>void}{
 const key=JSON.stringify({family,values});
 const [state,setState]=useState<Analysis>({state:'idle',plan:null,key,planKey:'',error:'',log:'',seconds:0});
 const [nonce,setNonce]=useState(0);
 const worker=useRef<Worker|null>(null),running=useRef(false),generation=useRef(0);
 const spawn=()=>{const w=new Worker(assetUrl('/openscad/export-worker.js'),{type:'module'});w.postMessage({type:'warm'});return w};
 const discard=()=>{worker.current?.terminate();worker.current=null;running.current=false};
 useEffect(()=>{
  const id=++generation.current;
  if(running.current)discard();
  const invalid=validate(values);
  if(invalid.length){setState(s=>({...s,state:'invalid',key,error:invalid.join(' ')}));return}
  setState(s=>({...s,state:'waiting',key,error:''}));
  if(!worker.current)worker.current=spawn();
  let timeout:ReturnType<typeof setTimeout>|undefined;
  const timer=setTimeout(async()=>{
   if(id!==generation.current)return;
   setState(s=>({...s,state:'running'}));
   const started=performance.now();
   try{
    const source=await configuredSource(family,values);
    if(id!==generation.current)return;
    const job=worker.current??spawn();
    worker.current=job;running.current=true;
    const finish=(update:Partial<Analysis>,keep:boolean)=>{
     if(timeout)clearTimeout(timeout);
     running.current=false;
     if(!keep){job.terminate();if(worker.current===job)worker.current=null}
     if(id===generation.current)setState(s=>({...s,...update,seconds:(performance.now()-started)/1000}));
    };
    timeout=setTimeout(()=>finish({state:'failed',error:'The engine check timed out after 3 minutes.'},false),180000);
    job.onerror=()=>finish({state:'failed',error:'Could not start the OpenSCAD engine in this browser.'},false);
    job.onmessage=({data})=>{
     if(data.type!=='result'&&data.type!=='error')return;
     const text=(data.logs??[]).join('\n')+'\n'+(typeof data.output==='string'?data.output:'');
     const plan=analyse(text);
     finish({state:data.type==='result'?'ready':'failed',plan,planKey:key,log:text,error:data.type==='error'?data.error:''},data.type==='result');
    };
    // The verbose system report adds the side-panel feature ledger (every hole the engine
    // drills in a cabinet side), which the Hardware view draws.
    job.postMessage({filename:schemas[family].file,source,sources:renderSources,mode:'bom',report:'verbose'});
   }catch(e){if(id===generation.current)setState(s=>({...s,state:'failed',error:String(e)}))}
  },delay);
  return ()=>{clearTimeout(timer);if(timeout)clearTimeout(timeout)};
 },[key,nonce]);
 useEffect(()=>()=>{generation.current++;discard()},[]);
 return {...state,rerun:()=>setNonce(n=>n+1)};
}
