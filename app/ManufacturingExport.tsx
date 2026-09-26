'use client';
import {assetUrl} from '@/lib/asset-url';
import {useEffect,useRef,useState} from 'react';
import {configuredSource,engineSources,renderSources,schemas,zip,download,Values} from '@/lib/cabinet';
import {designHealth,operations,reports,Entry,parseManufacturing,operationNotes} from '@/lib/manufacturing';
import {assemblyPacket} from '@/lib/assembly';
import {formatDimension,Units} from '@/lib/units';
function SvgPreview({data}:{data:string}){const [url,setUrl]=useState('');useEffect(()=>{const u=URL.createObjectURL(new Blob([data],{type:'image/svg+xml'}));setUrl(u);return()=>URL.revokeObjectURL(u)},[data]);return url?<img className='svg-review' src={url} alt='OpenSCAD manufacturing layout preview'/>:null}
type Package={entries:Entry[];text:string;packet:string;key:string;name:string;full:boolean};
export default function ManufacturingExport({family,values,name,invalid,units='mm'}:{family:number;values:Values;name:string;invalid:boolean;units?:Units}){
 const [running,setRunning]=useState(false),[status,setStatus]=useState(''),[error,setError]=useState(''),[log,setLog]=useState(''),[result,setResult]=useState<Package|null>(null),[svg,setSvg]=useState('svg/cut_layout.svg');
 const task=useRef<AbortController|null>(null),key=JSON.stringify({family,values,name,units});
 useEffect(()=>()=>{const active=task.current;task.current=null;active?.abort()},[]);
 function operation(data:object,signal:AbortSignal):Promise<{output:string;logs:string[];empty:boolean}>{return new Promise((resolve,reject)=>{
  signal.throwIfAborted();const worker=new Worker(assetUrl('/openscad/export-worker.js'),{type:'module'});let finished=false;
  const finish=(err?:Error,result?:any)=>{if(finished)return;finished=true;clearTimeout(timer);signal.removeEventListener('abort',abort);worker.terminate();err?reject(err):resolve(result)};
  const abort=()=>finish(new Error('Export cancelled.'));
  const timer=setTimeout(()=>finish(new Error('This operation exceeded 3 minutes. Reduce layout complexity and try again.')),180000);
  signal.addEventListener('abort',abort,{once:true});
  worker.onmessage=({data})=>{if(data.type==='error'){setLog(data.logs?.join('\n')??'');finish(new Error(data.error))}else if(data.type==='result')finish(undefined,data)};
  worker.onerror=()=>finish(new Error('Could not start OpenSCAD. Check your connection and try again.'));worker.postMessage(data);
 })}
 async function generate(full:boolean){
  task.current?.abort();const controller=new AbortController();task.current=controller;setRunning(true);setError('');setLog('');setResult(null);
  const snapshot=JSON.parse(JSON.stringify(values)),filename=schemas[family].file;const entries:Entry[]=[],notes:string[]=[];let text='';
  try{
   const source=await configuredSource(family,snapshot,controller.signal),supported=schemas[family].fields.find(f=>f.key==='output_mode')?.options??[],modes=full?['bom',...supported.filter(mode=>mode==='cut_layout'||mode==='engrave_layout'||mode.startsWith('pocket_'))]:['bom'];
   for(let i=0;i<modes.length;i++){
    controller.signal.throwIfAborted();const mode=modes[i];setStatus(`${i+1} / ${modes.length} · ${mode==='bom'?'BOM and dimensions':mode.replaceAll('_',' ')}`);
    const output=await operation({filename,source,sources:renderSources,mode},controller.signal);
    const outputLog=output.logs.join('\n')+(mode==='bom'?'\n'+output.output:'');entries.push({name:`logs/${mode}.txt`,data:outputLog});
    if(mode==='bom'){text=outputLog;const health=designHealth(text);if(health.status==='ERROR'||health.status==='UNVERIFIED'){setLog(text);throw Error(health.errors.map(c=>c.code+': '+c.message).join('\n')||'No validation report returned. Manufacturing package blocked.')}entries.push(...reports(text))}
    else if(!output.empty)entries.push({name:`svg/${mode}.svg`,data:output.output});
    notes.push(mode+': '+(output.empty?'No geometry; SVG omitted.':'Exported; inspect for registration-only output.'));
   }
   const packet=assemblyPacket(name,snapshot,text,units);
   entries.push({name:'assembly-packet.html',data:packet},{name:`source/${filename}`,data:source},...Object.entries(engineSources).filter(([name])=>name!==filename).map(([name,text])=>({name:'source/'+name,data:text})),{name:'design.cabinet.json',data:JSON.stringify({version:2,engine:5,engineFamily:"modular_organization",bundleRevision:5,family,name,displayUnits:units,values:snapshot},null,2)});
   entries.push({name:'READ-ME.txt',data:`${name}\nGenerated ${new Date().toISOString()} from settings captured when generation started.\n\nOpen assembly-packet.html in a browser, then Print / Save as PDF. The exploded arrangement is schematic; labels correspond to the actual BOM. The panel BOM does not provide a complete purchased-hardware count.\n\nSVGs are OpenSCAD layouts in millimeters. Preserve original scale and registration frame in CAM. These layouts are not sheet nesting or toolpaths. Never machine registration frames as cabinet parts.\n\ncut_layout: through cuts. engrave_layout: labels. pocket_layout: combined reference only, potentially multiple depths. Use separate operation SVGs and their logs for depths and machining faces, including face-frame BACK dados. Disabled operations may contain only the registration frame.\n\nBOM dimensions are cut sizes; grouped BOM only combines matching category, material, dimensions and notes. Original reports retain full precision in mm.\n\n${notes.join('\n')}`});
   controller.signal.throwIfAborted();setResult({entries,text,packet,key,name,full});setStatus('Ready for review. Nothing has been downloaded yet.');
  }catch(e){if(task.current===controller){setError(e instanceof Error?e.message:String(e));setStatus('')}}finally{if(task.current===controller)setRunning(false)}
 }
 const parsed=result?parseManufacturing(result.text):null,stale=!!result&&result.key!==key;
 const materials=new Map<string,number>();parsed?.bom.forEach(r=>{const k=r.material+' · '+formatDimension(r.thickness,units)+' '+units;materials.set(k,(materials.get(k)??0)+r.qty)});
 const svgs=result?.entries.filter(e=>e.name.startsWith('svg/'))??[],selectedSvg=svgs.find(e=>e.name===svg)??svgs[0];
 const allWarnings=[...new Set(result?.entries.filter(e=>e.name.startsWith('logs/')).flatMap(e=>parseManufacturing(e.data).warnings)??[])];
 const filename=(result?.name.replace(/[^a-z0-9_-]/gi,'-')||'cabinet');
 return <div className='export-includes'><h3>Manufacturing review</h3><p>Generate a snapshot to review parts, material quantities, operation notes and layouts before downloading.</p><div className='manufacturing-actions'><button className='primary' disabled={running||invalid} onClick={()=>generate(true)}>Generate SVGs + reports</button><button disabled={running||invalid} onClick={()=>generate(false)}>Reports + assembly packet</button>{running&&<button onClick={()=>task.current?.abort()}>Cancel</button>}</div><p role='status'>{status}</p>{error&&<p className='error' role='alert'>{error}</p>}{log&&<details><summary>Export log</summary><pre className='export-log'>{log}</pre></details>}
 {result&&parsed&&<div className='manufacturing-review'>{stale&&<p className='error' role='status'>Settings changed. Generate again to download a current package.</p>}<p><strong>Design Health: {designHealth(result.text).status}</strong> · Engine checks completed. Final contour audit has not run in the browser; use the included desktop validation tools before machining.</p><h4>Materials · {parsed.bom.reduce((n,r)=>n+r.qty,0)} parts</h4><div className='material-summary'>{[...materials].map(([m,n])=><p key={m}><strong>{n}</strong> × {m}</p>)}</div><details open><summary>Part dimensions ({units})</summary><div className='review-table'><table><thead><tr><th>ID</th><th>Qty</th><th>Material</th><th>Thickness</th><th>Cut W × H</th></tr></thead><tbody>{parsed.bom.map((r,i)=><tr key={r.id+'-'+i}><td>{r.id}</td><td>{r.qty}</td><td>{r.material}</td><td>{formatDimension(r.thickness,units)}</td><td>{formatDimension(r.width,units)} × {formatDimension(r.height,units)}</td></tr>)}</tbody></table></div></details><details open={allWarnings.length>0}><summary>Engine warnings · {allWarnings.length}</summary>{allWarnings.length?<pre className='export-log'>{allWarnings.join('\n')}</pre>:<p>No engine warnings in the generated jobs.</p>}</details>
 {svgs.length>0&&<><h4>Inspect SVG layouts</h4><select aria-label='Select operation layout' value={selectedSvg?.name} onChange={e=>setSvg(e.target.value)}>{svgs.map(e=><option key={e.name} value={e.name}>{e.name.slice(4,-4).replaceAll('_',' ')}</option>)}</select>{selectedSvg&&<SvgPreview data={selectedSvg.data}/>}<p className='field-note'>Preview is scaled to fit. Files retain millimeter scale. A frame-only layout indicates no part features for that operation.</p><details open><summary>Machining depths and faces</summary><p>Use the operation-specific notes below. Combined pockets can contain multiple depths; do not assign a single depth to that layout.</p>{result.entries.filter(e=>e.name.startsWith('logs/')&&e.name!=='logs/bom.txt').map(e=><details key={e.name}><summary>{e.name.slice(5,-4).replaceAll('_',' ')}</summary><pre className='export-log'>{operationNotes(e.data).join('\n')||'No depth or face stated. Consult the full log and selected hardware specifications.'}</pre><details><summary>Full operation log</summary><pre className='export-log'>{e.data}</pre></details></details>)}</details></>}
 <h4>Printable assembly packet</h4><p>Exploded schematic guides with BOM IDs, complete part index, assembly order, hardware checklist and engine dimensions. Open the HTML file and choose Print / Save as PDF.</p><div className='manufacturing-actions'><button disabled={stale} onClick={()=>download(new Blob([result.packet],{type:'text/html'}),filename+'-assembly.html')}>Download assembly packet</button><button className='primary' disabled={stale} onClick={()=>{download(zip(result.entries),filename+(result.full?'-manufacturing.zip':'-reports.zip'));setStatus('Reviewed package downloaded.')}}>Download reviewed package</button></div></div>}
 <small>Closing this window cancels generation and clears this review. All calculations use the settings captured when generation starts.</small></div>
}
