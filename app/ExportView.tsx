'use client';
// Export view: a page of its own for turning the design into shop files. Generate the
// manufacturing package (operation SVGs, per-sheet SVG/DXF, reports, assembly packet), review
// it with large layout previews, then download; or download the editable OpenSCAD project.
import {assetUrl} from '@/lib/asset-url';
import {useEffect,useRef,useState} from 'react';
import {configuredSource,engineSources,renderSources,schemas,zip,download,Values} from '@/lib/cabinet';
import {designHealth,operations,reports,Entry,parseManufacturing,operationNotes} from '@/lib/manufacturing';
import {assemblyPacket} from '@/lib/assembly';
import {analyse,records,MATERIAL_NAMES} from '@/lib/analysis';
import {nest,nestOptions,partRecords,placementRecords,sheetSvg,sheetDxf,nestingReport,nestingSummary,checkNesting,NestResult,Rotate} from '@/lib/nesting';
import {formatDimension,formatShop,Units} from '@/lib/units';
import {ArrowLeft,Download,Check,Info,LoaderCircle,TriangleAlert,FileCode2,Layers,PackageCheck} from 'lucide-react';
function SvgPreview({data}:{data:string}){const [url,setUrl]=useState('');useEffect(()=>{const u=URL.createObjectURL(new Blob([data],{type:'image/svg+xml'}));setUrl(u);return()=>URL.revokeObjectURL(u)},[data]);return url?<img className='svg-review' src={url} alt='OpenSCAD manufacturing layout preview'/>:null}
type Package={entries:Entry[];text:string;packet:string;key:string;name:string;full:boolean;nesting?:NestResult;nestingProblems?:string[]};
type Props={family:number;values:Values;name:string;errors:string[];units?:Units;onBack:()=>void;onEditSheets:()=>void;onDownloadProject:()=>void;projectBusy:boolean};
const ROTATIONS:{value:Rotate;title:string;note:string}[]=[
 {value:'needed',title:'Keep the drawn orientation',note:'A part turns a quarter only when it cannot fit on the sheet as drawn.'},
 {value:'never',title:'Never turn parts',note:'Grain runs exactly as drawn; a part too long for the sheet is reported.'},
 {value:'free',title:'Turn parts freely',note:'Denser sheets, but grain direction is ignored.'},
];
export default function ExportView({family,values,name,errors,units='mm',onBack,onEditSheets,onDownloadProject,projectBusy}:Props){
 const invalid=errors.length>0;
 const [rotate,setRotate]=useState<Rotate>('needed'),[running,setRunning]=useState(false),[status,setStatus]=useState(''),[error,setError]=useState(''),[log,setLog]=useState(''),[result,setResult]=useState<Package|null>(null),[svg,setSvg]=useState('svg/cut_layout.svg');
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
    if(mode==='bom'){text=outputLog;const health=designHealth(text),blocking=analyse(text).issues.filter(i=>i.severity==='error');if(health.status==='UNVERIFIED'||blocking.length){setLog(text);throw Error(blocking.map(c=>c.code+': '+c.message).join('\n')||'No validation report returned. Manufacturing package blocked.')}entries.push(...reports(text))}
    else if(!output.empty)entries.push({name:`svg/${mode}.svg`,data:output.output});
    notes.push(mode+': '+(output.empty?'No geometry; SVG omitted.':'Exported; inspect for registration-only output.'));
   }
   // Per-sheet cut files: every operation layout re-mapped onto the design's stock sheets.
   let nesting:NestResult|undefined,nestingProblems:string[]=[];
   if(full){
    const recs=records(text),parts=partRecords(recs),places=placementRecords(recs),slack=snapshot.apply_kerf_compensation?(Number(snapshot.kerf)||0)/2:0;
    nesting=nest(parts,places,nestOptions(snapshot,rotate));
    const cut=entries.find(e=>e.name==='svg/cut_layout.svg')?.data;
    nestingProblems=checkNesting(nesting,parts,cut,slack);
    for(const s of nesting.sheets){
     const folder=`sheets/${String(s.index).padStart(2,'0')}-${s.material.toLowerCase().replace(/[^a-z0-9]+/g,'-')}-${String(Math.round(s.thickness*100)/100).replace('.','_')}mm`;
     for(const e of entries.filter(e=>e.name.startsWith('svg/'))){const mode=e.name.slice(4,-4);entries.push({name:`${folder}/${mode}.svg`,data:sheetSvg(e.data,s,mode,slack)},{name:`${folder}/${mode}.dxf`,data:sheetDxf(e.data,s,mode,slack)})}
    }
    entries.push({name:'sheets/nesting.json',data:nestingReport(nesting)});
    if(nestingProblems.length)entries.push({name:'sheets/PROBLEMS.txt',data:nestingProblems.join('\n')+'\n'});
    notes.push('sheets: '+nestingSummary(nesting,m=>MATERIAL_NAMES[m]??m)+(nestingProblems.length?` · ${nestingProblems.length} problem(s), see sheets/PROBLEMS.txt`:''));
   }
   const packet=assemblyPacket(name,snapshot,text,units);
   entries.push({name:'assembly-packet.html',data:packet},{name:`source/${filename}`,data:source},...Object.entries(engineSources).filter(([name])=>name!==filename).map(([name,text])=>({name:'source/'+name,data:text})),{name:'design.cabinet.json',data:JSON.stringify({version:2,engine:5,engineFamily:"modular_organization",bundleRevision:5,family,name,displayUnits:units,values:snapshot},null,2)});
   entries.push({name:'READ-ME.txt',data:`${name}\nGenerated ${new Date().toISOString()} from settings captured when generation started.\n\nOpen assembly-packet.html in a browser, then Print / Save as PDF. The exploded arrangement is schematic; labels correspond to the actual BOM. The panel BOM does not provide a complete purchased-hardware count.\n\nSVGs are OpenSCAD layouts in millimeters. Preserve original scale and registration frame in CAM. These strip layouts are not toolpaths. Never machine registration frames as cabinet parts.\n\nsheets/: the same operations nested per stock sheet (sheet size, margin and part spacing from the Flat Layout settings; parts keep the engine's orientation unless a part cannot fit as drawn or free turning was chosen). One folder per sheet with an SVG and a DXF per operation, nesting.json with every placement, and PROBLEMS.txt only when a part did not fit.\n\ncut_layout: through cuts. engrave_layout: labels. pocket_layout: combined reference only, potentially multiple depths. Use separate operation SVGs and their logs for depths and machining faces, including face-frame BACK dados. Disabled operations may contain only the registration frame.\n\nBOM dimensions are cut sizes; grouped BOM only combines matching category, material, dimensions and notes. Original reports retain full precision in mm.\n\n${notes.join('\n')}`});
   controller.signal.throwIfAborted();setResult({entries,text,packet,key,name,full,nesting,nestingProblems});setStatus('Ready for review. Nothing has been downloaded yet.');
  }catch(e){if(task.current===controller){setError(e instanceof Error?e.message:String(e));setStatus('')}}finally{if(task.current===controller)setRunning(false)}
 }

 const parsed=result?parseManufacturing(result.text):null,stale=!!result&&result.key!==key;
 const materials=new Map<string,number>();parsed?.bom.forEach(r=>{const k=r.material+' · '+formatDimension(r.thickness,units)+' '+units;materials.set(k,(materials.get(k)??0)+r.qty)});
 const svgs=result?.entries.filter(e=>(e.name.startsWith('svg/')||e.name.startsWith('sheets/'))&&e.name.endsWith('.svg'))??[],selectedSvg=svgs.find(e=>e.name===svg)??svgs[0];
 const allWarnings=[...new Set(result?.entries.filter(e=>e.name.startsWith('logs/')).flatMap(e=>parseManufacturing(e.data).warnings)??[])];
 const filename=(result?.name.replace(/[^a-z0-9_-]/gi,'-')||'cabinet');
 const cap=(t:string)=>t.charAt(0).toUpperCase()+t.slice(1),opName=(n:string)=>cap(n.replaceAll('_',' ').replace(/ layout$/,''));
 const operationsList=svgs.filter(e=>e.name.startsWith('svg/'));
 const sheets=new Map<string,typeof svgs>();for(const e of svgs.filter(e=>e.name.startsWith('sheets/'))){const folder=e.name.split('/')[1];sheets.set(folder,[...(sheets.get(folder)??[]),e])}
 const sheetOf=(n?:string)=>n?.startsWith('sheets/')?n.split('/')[1]:'';
 const opOf=(n?:string)=>(n?.split('/').pop()??'cut_layout.svg').slice(0,-4);
 const fileFor=(sheet:string,op:string)=>sheet?`sheets/${sheet}/${op}.svg`:`svg/${op}.svg`;
 const sheetLabel=(folder:string)=>{const m=folder.match(/^(\d+)-(.*)-([\d_]+)mm$/);return m?`Sheet ${Number(m[1])} · ${cap(m[2].replaceAll('-',' '))} ${m[3].replace('_','.')} mm`:folder};
 const sheetW=Number(values.stock_width),sheetH=Number(values.stock_height),gap=Number(values.layout_gap);
 const health=result?designHealth(result.text).status:null;
 return <section className='export-view' aria-label='Export'>
  <div className='export-head'>
   <button className='export-back' onClick={onBack}><ArrowLeft size={16}/>Back to design</button>
   <div><span className='eyebrow'>EXPORT</span><h1>Take {name||'your design'} to the workshop</h1><p>Generate cut files and reports, check them here, then download. Every file uses millimeters.</p></div>
  </div>
  {invalid&&<div className='export-card export-errors' role='alert'><TriangleAlert size={18}/><div><strong>Fix these before exporting</strong>{errors.map(e=><p key={e}>{e}</p>)}</div></div>}
  <div className='export-grid'>
   <div className='export-main'>
    <section className='export-card'>
     <h2><span>1</span>Manufacturing package</h2>
     <p className='export-lede'>OpenSCAD evaluates the design once per operation: through cuts, pockets and engraving, then nests every operation onto your stock sheets as SVG and DXF.</p>
     <fieldset className='export-nesting' disabled={running}>
      <legend>Sheet nesting</legend>
      <p className='field-note'>Sheets are {formatShop(sheetW,units)} × {formatShop(sheetH,units)}{units==='mm'?' mm':''} with {formatShop(gap,units)}{units==='mm'?' mm':''} between parts and at the edges. <button className='link-button' onClick={onEditSheets}>Change sheet size or spacing</button></p>
      {ROTATIONS.map(r=><label key={r.value} className={rotate===r.value?'is-active':''}><input type='radio' name='rotate' value={r.value} checked={rotate===r.value} onChange={()=>setRotate(r.value)}/><span><strong>{r.title}</strong><small>{r.note}</small></span></label>)}
     </fieldset>
     <div className='manufacturing-actions'>
      <button className='primary' disabled={running||invalid} onClick={()=>generate(true)}>{running?<LoaderCircle size={16} className='spin'/>:<Layers size={16}/>}Generate cut files and reports</button>
      <button disabled={running||invalid} onClick={()=>generate(false)}>Reports and assembly packet only</button>
      {running&&<button onClick={()=>task.current?.abort()}>Cancel</button>}
     </div>
     <p role='status' className='export-status'>{status}</p>{error&&<p className='error' role='alert'>{error}</p>}{log&&<details><summary>Export log</summary><pre className='export-log'>{log}</pre></details>}
    </section>
    {result&&parsed&&<section className='export-card'>
     <h2><span>2</span>Review</h2>
     {stale&&<p className='error' role='status'>Settings changed since this package was generated. Generate again to download a current package.</p>}
     <div className='export-stats'>
      <div><span>Design health</span><strong className={health==='PASS'?'is-ok':''}>{health}</strong></div>
      <div><span>Parts</span><strong>{parsed.bom.reduce((n,r)=>n+r.qty,0)}</strong></div>
      {result.nesting&&<div><span>Sheets</span><strong>{result.nesting.sheets.length}</strong></div>}
      <div><span>Engine warnings</span><strong>{allWarnings.length}</strong></div>
     </div>
     <p className='field-note'>Engine checks completed, including the flat cut layout (every part placed from one table, no overlapping outlines). The included desktop validation tools audit the final contours before machining.</p>
     {result.nesting&&<p><strong>Sheets:</strong> {nestingSummary(result.nesting,m=>MATERIAL_NAMES[m]??m)}, {result.nesting.options.margin} mm margin, {result.nesting.options.gap} mm between parts.</p>}
     {!!result.nestingProblems?.length&&<p className='error' role='alert'>Nesting problems: {result.nestingProblems.slice(0,3).join(' ')}{result.nestingProblems.length>3?` … ${result.nestingProblems.length} in total (sheets/PROBLEMS.txt).`:''}</p>}
     <div className='material-summary'>{[...materials].map(([m,n])=><p key={m}><strong>{n}</strong> × {m}</p>)}</div>
     <details><summary>Part dimensions ({units})</summary><div className='review-table'><table><thead><tr><th>ID</th><th>Qty</th><th>Material</th><th>Thickness</th><th>Cut W × H</th></tr></thead><tbody>{parsed.bom.map((r,i)=><tr key={r.id+'-'+i}><td>{r.id}</td><td>{r.qty}</td><td>{r.material}</td><td>{formatDimension(r.thickness,units)}</td><td>{formatDimension(r.width,units)} × {formatDimension(r.height,units)}</td></tr>)}</tbody></table></div></details>
     <details open={allWarnings.length>0}><summary>Engine warnings · {allWarnings.length}</summary>{allWarnings.length?<pre className='export-log'>{allWarnings.join('\n')}</pre>:<p>No engine warnings in the generated jobs.</p>}</details>
     {svgs.length>0&&<details><summary>Machining depths and faces</summary><p className='field-note'>Use the operation-specific notes below. Combined pockets can contain multiple depths; do not assign a single depth to that layout.</p>{result.entries.filter(e=>e.name.startsWith('logs/')&&e.name!=='logs/bom.txt').map(e=><details key={e.name}><summary>{e.name.slice(5,-4).replaceAll('_',' ')}</summary><pre className='export-log'>{operationNotes(e.data).join('\n')||'No depth or face stated. Consult the full log and selected hardware specifications.'}</pre><details><summary>Full operation log</summary><pre className='export-log'>{e.data}</pre></details></details>)}</details>}
    </section>}
    {result&&<section className='export-card'>
     <h2><span>3</span>Download</h2>
     <div className='export-downloads'>
      <button className='primary' disabled={stale} onClick={()=>{download(zip(result.entries),filename+(result.full?'-manufacturing.zip':'-reports.zip'));setStatus('Reviewed package downloaded.')}}><PackageCheck size={17}/>Download reviewed package</button>
      <button disabled={stale} onClick={()=>download(new Blob([result.packet],{type:'text/html'}),filename+'-assembly.html')}><Download size={16}/>Assembly packet only</button>
     </div>
     <p className='field-note'>The package holds the operation SVGs, the sheets folder (SVG and DXF per sheet and operation), reports, the printable assembly packet and the editable source. Open the assembly packet in a browser and choose Print / Save as PDF.</p>
    </section>}
    <section className='export-card'>
     <h2><FileCode2 size={18}/>Editable OpenSCAD project</h2>
     <p className='export-includes-line'><Check size={15}/>Your cabinet and all current settings</p>
     <p className='export-includes-line'><Check size={15}/>Shared geometry and manufacturing layouts</p>
     <p className='export-includes-line'><Check size={15}/>BOM export script and editable design file</p>
     <div className='note'><Info size={18}/><p>Open the included .scad file in OpenSCAD to render exact geometry and export cut, pocket, engraving or BOM outputs. The cut list tab and the manufacturing package evaluate the same engine directly in your browser.</p></div>
     <button className='primary download-button' disabled={projectBusy||invalid} onClick={onDownloadProject}><Download size={18}/>{projectBusy?'Preparing project…':'Download OpenSCAD project'}</button>
    </section>
   </div>
   <aside className='export-preview' aria-label='Layout preview'>
    <h2>Layouts</h2>
    {svgs.length===0?<div className='export-preview-empty'><Layers size={28}/><p>{running?'Generating…':'Generate the manufacturing package to preview the cut layouts and every nested sheet here.'}</p></div>:<>
     <div className='export-layout-pickers'>
      <label>Layout<select value={sheetOf(selectedSvg?.name)} onChange={e=>setSvg(fileFor(e.target.value,opOf(selectedSvg?.name)))}>
       <option value=''>All parts in one strip (engine layout)</option>
       {[...sheets.keys()].map(folder=><option key={folder} value={folder}>{sheetLabel(folder)}</option>)}
      </select></label>
      <label>Operation<select value={opOf(selectedSvg?.name)} onChange={e=>setSvg(fileFor(sheetOf(selectedSvg?.name),e.target.value))}>
       {operationsList.map(e=>{const op=e.name.slice(4,-4);return <option key={op} value={op}>{opName(op)}</option>})}
      </select></label>
      <span className='field-note'>{svgs.length} files · {sheets.size} sheet{sheets.size===1?'':'s'}</span>
     </div>
     {selectedSvg&&<div className='export-preview-frame'><SvgPreview data={selectedSvg.data}/></div>}
     <p className='field-note'>Preview is scaled to fit. Files keep millimeter scale. A frame-only layout means the operation has no features.</p>
    </>}
   </aside>
  </div>
 </section>;
}
