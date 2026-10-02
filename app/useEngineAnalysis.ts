'use client';
import {useEffect,useRef,useState} from 'react';
import {assetUrl} from '@/lib/asset-url';
import {configuredSource,renderSources,schemas,validate,Values} from '@/lib/cabinet';
import {analyse,Plan} from '@/lib/analysis';
export type Analysis={state:'idle'|'waiting'|'running'|'ready'|'failed'|'invalid';plan:Plan|null;key:string;planKey:string;error:string;log:string;seconds:number};
// Re-runs the engine's BOM/validation pass shortly after each edit. One worker at a time;
// a newer edit terminates the older run. The last good plan stays visible (marked stale).
export default function useEngineAnalysis(family:number,values:Values,delay=650):Analysis&{rerun:()=>void}{
 const key=JSON.stringify({family,values});
 const [state,setState]=useState<Analysis>({state:'idle',plan:null,key,planKey:'',error:'',log:'',seconds:0});
 const [nonce,setNonce]=useState(0);
 const worker=useRef<Worker|null>(null),generation=useRef(0);
 useEffect(()=>{
  const id=++generation.current;
  worker.current?.terminate();worker.current=null;
  const invalid=validate(values);
  if(invalid.length){setState(s=>({...s,state:'invalid',key,error:invalid.join(' ')}));return}
  setState(s=>({...s,state:'waiting',key,error:''}));
  let timeout:ReturnType<typeof setTimeout>|undefined;
  const timer=setTimeout(async()=>{
   if(id!==generation.current)return;
   setState(s=>({...s,state:'running'}));
   const started=performance.now();
   try{
    const source=await configuredSource(family,values);
    if(id!==generation.current)return;
    const job=new Worker(assetUrl('/openscad/export-worker.js'),{type:'module'});
    worker.current=job;
    const finish=(update:Partial<Analysis>)=>{
     if(timeout)clearTimeout(timeout);
     job.terminate();if(worker.current===job)worker.current=null;
     if(id===generation.current)setState(s=>({...s,...update,seconds:(performance.now()-started)/1000}));
    };
    timeout=setTimeout(()=>finish({state:'failed',error:'The engine check timed out after 3 minutes.'}),180000);
    job.onerror=()=>finish({state:'failed',error:'Could not start the OpenSCAD engine in this browser.'});
    job.onmessage=({data})=>{
     if(data.type!=='result'&&data.type!=='error')return;
     const text=(data.logs??[]).join('\n')+'\n'+(typeof data.output==='string'?data.output:'');
     const plan=analyse(text);
     finish({state:data.type==='result'?'ready':'failed',plan,planKey:key,log:text,error:data.type==='error'?data.error:''});
    };
    job.postMessage({filename:schemas[family].file,source,sources:renderSources,mode:'bom'});
   }catch(e){if(id===generation.current)setState(s=>({...s,state:'failed',error:String(e)}))}
  },delay);
  return ()=>{clearTimeout(timer);if(timeout)clearTimeout(timeout)};
 },[key,nonce]);
 useEffect(()=>()=>{generation.current++;worker.current?.terminate()},[]);
 return {...state,rerun:()=>setNonce(n=>n+1)};
}
