'use client';
import {assetUrl} from '@/lib/asset-url';
import {useEffect,useRef,useState} from 'react';
import {configuredSource,renderSources,schemas,Values} from '@/lib/cabinet';
import {Units,formatDimension} from '@/lib/units';
export default function FitTargetResult({family,values,onSolved,units}:{units:Units;family:number;values:Values;onSolved:(dimensions:Record<string,number>)=>void}){
 const [result,setResult]=useState<Record<string,number>|null>(null);
 const [status,setStatus]=useState(''),[busy,setBusy]=useState(false);const worker=useRef<Worker|null>(null),generation=useRef(0);const callback=useRef(onSolved);callback.current=onSolved;
 const timeout=useRef<ReturnType<typeof setTimeout>|null>(null);
 const active=family>=5||values.width_basis==='drawer_inside'||values.depth_basis==='drawer_inside';
 useEffect(()=>{generation.current++;worker.current?.terminate();if(timeout.current)clearTimeout(timeout.current);setBusy(false);setStatus('');setResult(null);return()=>{generation.current++;worker.current?.terminate();if(timeout.current)clearTimeout(timeout.current)}},[family,values]);
 async function solve(){const id=++generation.current;worker.current?.terminate();setBusy(true);setStatus('Calculating with OpenSCAD…');
 try{const source=await configuredSource(family,values);if(generation.current!==id)return;const job=new Worker(assetUrl('/openscad/export-worker.js'),{type:'module'});worker.current=job;
 const timer=timeout.current=setTimeout(()=>{if(generation.current!==id)return;job.terminate();setBusy(false);setStatus('Calculation timed out. Try again.')},180000);
 job.onerror=()=>{clearTimeout(timer);if(generation.current!==id)return;job.terminate();setBusy(false);setStatus('Could not load OpenSCAD. Check your connection and try again.')};
 job.onmessage=({data})=>{clearTimeout(timer);job.terminate();if(generation.current!==id)return;setBusy(false);if(data.type==='error'){setStatus(data.error+' '+(data.logs??[]).filter((l:string)=>l.includes('ERROR|')).join(' '));return}
 const text=data.output+'\n'+data.logs.join('\n');const line=text.split('\n').find(l=>l.includes(family===6?'DIM|equipment_stand|':family===5?'TARGET|DRAWER_DESIGN|':'TARGET|DRAWER_INSIDE|'));
 if(!line){setStatus('No target result was returned.');return}const result:Record<string,number>={};for(const m of line.matchAll(/\|([A-Z_]+)=(-?[\d.]+)/g))result[m[1]]=Number(m[2]);
 if(family===6)Object.assign(result,{RESOLVED_CABINET_W:result.W,RESOLVED_CARCASS_D:result.D,RESOLVED_FINISHED_D:result.D,RESOLVED_CABINET_H:result.H,ACHIEVED_W:result.TRAY_W,ACHIEVED_D:result.TRAY_D});
 if(family===5)Object.assign(result,{RESOLVED_CABINET_W:result.OUTSIDE_W,RESOLVED_CARCASS_D:result.OUTSIDE_D,RESOLVED_FINISHED_D:result.OUTSIDE_D,RESOLVED_CABINET_H:result.OUTSIDE_H,ACHIEVED_W:result.INSIDE_W,ACHIEVED_D:result.INSIDE_D});
 if(!['RESOLVED_CABINET_W','RESOLVED_CARCASS_D','RESOLVED_FINISHED_D','ACHIEVED_W','ACHIEVED_D'].every(k=>Number.isFinite(result[k]))){setStatus('The target result was incomplete.');return}
 callback.current(result);setResult(result);setStatus('');
 };job.postMessage({filename:schemas[family].file,source,sources:renderSources,mode:'bom'});
 }catch(e){if(generation.current===id){setBusy(false);setStatus(String(e))}}}
 if(!active)return null;
 return <div className='fit-result'><p>{family===6?'Calculate the exact equipment frame and tray dimensions with OpenSCAD.':family===5?'Calculate the drawer’s outside and usable inside dimensions with OpenSCAD. The enclosure is reference only and is excluded from manufacturing parts.':'Drawer-interior sizing is active. Calculate to update the schematic’s envelope. Render and exports always solve your current targets.'}</p><button className='primary' disabled={busy} onClick={solve}>{busy?'Calculating…':'Calculate fitted size'}</button>{result&&family<5&&<table className='fit-comparison'><thead><tr><th>Dimension</th><th>Requested</th><th>Achieved</th></tr></thead><tbody>{[['Drawer inside width','REQUESTED_W','ACHIEVED_W','width_basis'],['Drawer inside depth','REQUESTED_D','ACHIEVED_D','depth_basis']].map(([title,requested,achieved,active])=><tr key={title}><td>{title}</td><td>{values[active]==='drawer_inside'?formatDimension(result[requested],units)+' '+units:'Outside sizing'}</td><td>{formatDimension(result[achieved],units)} {units}</td></tr>)}</tbody></table>}<p role='status'>{status||(result&&family===5?`Drawer outside: ${formatDimension(result.OUTSIDE_W,units)} × ${formatDimension(result.OUTSIDE_H,units)} × ${formatDimension(result.OUTSIDE_D,units)} ${units}. Usable inside: ${formatDimension(result.INSIDE_W,units)} × ${formatDimension(result.INSIDE_H,units)} × ${formatDimension(result.INSIDE_D,units)} ${units} (W × H × D).`:result&&family===6?`Tray: ${formatDimension(result.TRAY_W,units)} × ${formatDimension(result.TRAY_D,units)} ${units}. Frame: ${formatDimension(result.W,units)} × ${formatDimension(result.H,units)} × ${formatDimension(result.D,units)} ${units} (W × H × D).`:result?`Drawer interior: ${formatDimension(result.ACHIEVED_W,units)} × ${formatDimension(result.ACHIEVED_D,units)} ${units}. Cabinet outside: ${formatDimension(result.RESOLVED_CABINET_W,units)} × ${formatDimension(values.cabinet_height,units)} × ${formatDimension(result.RESOLVED_FINISHED_D,units)} ${units} (W × H × D).`:'The schematic currently shows the configured outside dimensions.')}</p></div>
}
