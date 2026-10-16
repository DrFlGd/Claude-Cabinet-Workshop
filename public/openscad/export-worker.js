import manifest from './engine-v5-files.js';
// One worker serves jobs in sequence so the compiled engine is reused; terminating it still
// cancels synchronous WASM work. A 'warm' message compiles the engine before the first job.
let compiled=null;
// Pre-compilation is a browser-only optimisation: the Node test harness runs many short-lived
// workers in parallel, where an ahead-of-time compiled module can trip a V8 JIT-page check on
// worker termination; there the engine loads exactly as it did before.
const compiling=(async()=>{if(typeof WorkerGlobalScope==='undefined'||typeof WebAssembly==='undefined'||typeof fetch!=='function')return;try{const r=await fetch(new URL('./openscad.wasm',self.location.href));compiled=await (WebAssembly.compileStreaming?WebAssembly.compileStreaming(r.clone()).catch(async()=>WebAssembly.compile(await r.arrayBuffer())):WebAssembly.compile(await r.arrayBuffer()))}catch{compiled=null}})();
async function engineOptions(options){await compiling;return compiled?{...options,instantiateWasm:(info,receive)=>{WebAssembly.instantiate(compiled,info).then(instance=>receive(instance,compiled));return {}}}:options}
self.onmessage=async({data})=>{
 if(data&&data.type==='warm'){try{await compiling;await import('./openscad.js')}catch{}self.postMessage({type:'warm'});return}
 if(typeof data.filename==='string'&&/^(modular_organization_.*_v3|modular_storage_.*_v(29|32)|parametric_.*)\.scad$/.test(data.filename)){await import('./export-worker-legacy.js');return self.onmessage({data});}
 const logs=[];const log=line=>logs.push(String(line));
 try{
  const {filename,source,sources,mode}=data;
  const modern=Object.hasOwn(manifest.frontends,filename);
  if(!modern||!manifest.frontends[filename].includes(mode)||!['bom','cut_layout','engrave_layout',...manifest.frontends[filename].filter(m=>m.startsWith('pocket_'))].includes(mode)||typeof source!=='string'||source.length>2000000||!Array.isArray(sources)||sources.length!==manifest.files.length||!manifest.files.every(name=>sources.some(f=>f.name===name&&typeof f.text==='string'&&f.text.length<2000000)))throw Error('Invalid export request. Refresh the app and try again.');
  const {default:OpenSCAD}=await import('./openscad.js');
  let font;if(mode==='engrave_layout'){const r=await fetch(new URL('./DejaVuSans.ttf',self.location.href));if(!r.ok)throw Error('Could not load the engraving font. Check your connection and try again.');font=new Uint8Array(await r.arrayBuffer());}
  const engine=await OpenSCAD(await engineOptions({noInitialRun:true,locateFile:path=>new URL(path,self.location.href).href,print:log,printErr:log}));
  if(font){engine.FS.mkdirTree('/fonts');engine.FS.writeFile('/fonts/DejaVuSans.ttf',font);}
  for(const f of sources){engine.FS.mkdirTree('/'+f.name.split('/').slice(0,-1).join('/'));engine.FS.writeFile('/'+f.name,f.text);}
  engine.FS.writeFile('/'+filename,source);
  const path=mode==='bom'?'/report.echo':'/layout.svg';
  const code=engine.callMain(['/'+filename,'-D','output_mode='+JSON.stringify(mode),'-D','dimension_report="full"','-D','system_contract_report='+(data.report==='verbose'?'"verbose"':'"summary"'),'-D','validation_report="verbose"','-D','interface_keepout_policy="enforce"','-o',path]);
  let output='';try{output=engine.FS.readFile(path,{encoding:'utf8'})}catch{}
  const all=logs.join('\n')+'\n'+(mode==='bom'?output:'');
  if(/(^|\n)ERROR:|ECHO: "ERROR\|/.test(all)){if(mode==='bom')logs.push(output);throw Error('OpenSCAD rejected '+mode+'. See the export log.');}
  if(mode!=='bom'&&/CHECK\|ERROR\|/.test(all))throw Error('Manufacturing blocked by Design Health errors. See the export log.');
  // An operation with no enabled features may have no geometry at all.
  const empty=mode!=='bom'&&/Current top level object is empty/.test(all)&&!output;
  if(!empty&&(code!==0||!output))throw Error('OpenSCAD could not export '+mode+'. See the export log.');
  if(mode!=='bom'&&!empty&&!output.includes('<svg'))throw Error('OpenSCAD returned an invalid SVG.');
  self.postMessage({type:'result',output,logs,empty});
 }catch(e){self.postMessage({type:'error',error:e instanceof Error?e.message:String(e),logs})}
};
