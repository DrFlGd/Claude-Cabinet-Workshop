'use client';
import {assetUrl} from '@/lib/asset-url';
import {useEffect,useRef,useState} from 'react';
import {configuredSource,renderSources,schemas,Values} from '@/lib/cabinet';
import {designHealth} from '@/lib/manufacturing';
export default function DesignHealth({family,values}:{family:number;values:Values}){
 const [result,setResult]=useState<ReturnType<typeof designHealth>|null>(null),[busy,setBusy]=useState(false),[error,setError]=useState('');
 const worker=useRef<Worker|null>(null),generation=useRef(0),timer=useRef<ReturnType<typeof setTimeout>|null>(null);
 function stop(){worker.current?.terminate();worker.current=null;if(timer.current)clearTimeout(timer.current)}
 useEffect(()=>{generation.current++;stop();setResult(null);setError('');setBusy(false);return()=>{generation.current++;stop()}},[family,values]);
 async function check(){const id=++generation.current;stop();setBusy(true);setError('');setResult(null);
  try{const source=await configuredSource(family,values);if(id!==generation.current)return;const job=new Worker(assetUrl('/openscad/export-worker.js'),{type:'module'});worker.current=job;
   const fail=(message:string)=>{if(id!==generation.current)return;stop();setBusy(false);setError(message)};
   timer.current=setTimeout(()=>fail('Check timed out. Try again with a simpler configuration.'),180000);
   job.onerror=()=>fail('Could not load OpenSCAD. Please try again.');
   job.onmessage=({data})=>{if(id!==generation.current)return;stop();setBusy(false);const report=designHealth((data.output??'')+'\n'+(data.logs??[]).join('\n'));setResult(report);if(data.type==='error')setError(data.error)};
   job.postMessage({filename:schemas[family].file,source,sources:renderSources,mode:'bom'});
  }catch(e){if(id===generation.current){stop();setBusy(false);setError(String(e))}}
 }
 return <details className='design-health'><summary>Design Health · {busy?'Checking…':result?.status??'Not checked'}</summary><p>Check the current design’s geometry and supported interfaces with OpenSCAD. Manufacturing exports repeat these checks and block on errors.</p><button className='primary' disabled={busy} onClick={check}>{busy?'Checking…':'Check design'}</button>{busy&&<button onClick={()=>{generation.current++;stop();setBusy(false)}}>Cancel</button>}{error&&<p className='error' role='alert'>{error}</p>}{result&&<div role='status'>{result.checks.filter(c=>c.severity!=='INFO').map((c,i)=><p key={i} className={c.severity==='ERROR'?'error':''}><strong>{c.severity} · {c.code}</strong><br/>{c.message}</p>)}{result.status==='PASS'&&<p>No errors or warnings in the checked scope.</p>}<details><summary>Validation coverage</summary><p>{result.wholeModelAudit}</p><pre className='export-log'>{result.coverage.join('\n')||result.checks.filter(c=>c.code.includes('SCOPE')).map(c=>c.message).join('\n')}</pre></details></div>}</details>
}
