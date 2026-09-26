import manifest from './engine-v5-files.js';
// One engine instance per job. Terminating this worker cancels synchronous WASM work.
self.onmessage = async ({data}) => {
 if(typeof data.filename==='string'&&/^(modular_organization_.*_v3|modular_storage_.*_v(29|32)|parametric_.*)\.scad$/.test(data.filename)){await import('./render-worker-legacy.js');return self.onmessage({data});}
 const started=performance.now();const logs=[];
 const log=(line)=>{line=String(line).slice(0,2000);logs.push(line);if(logs.length>150)logs.shift();self.postMessage({type:'log',line})};
 try {
  const {filename,source,mode}=data;
  if(!Object.hasOwn(manifest.frontends,filename)||!manifest.frontends[filename].includes(mode)||!['assembly','flat_3d','carcass_only','drawers_only'].includes(mode)||typeof source!=='string'||source.length>2000000)throw Error('Invalid render request. Refresh the app and try again.');
  self.postMessage({type:'stage',stage:'Loading OpenSCAD…'});
  const sources=data.sources;
  if(!Array.isArray(sources)||sources.length!==manifest.files.length||!manifest.files.every(name=>sources.some(f=>f.name===name&&typeof f.text==='string'&&f.text.length<2000000)))throw Error('Invalid engine snapshot. Refresh the app and try again.');
  const {default:OpenSCAD}=await import('./openscad.js');
  const engine=await OpenSCAD({noInitialRun:true,locateFile:path=>new URL(path,self.location.href).href,print:log,printErr:log});
  for(const f of sources){engine.FS.mkdirTree('/'+f.name.split('/').slice(0,-1).join('/'));engine.FS.writeFile('/'+f.name,f.text);}
  engine.FS.writeFile('/'+filename,source);
  self.postMessage({type:'stage',stage:'Rendering cabinet…'});
  let code;
  try{code=engine.callMain(['/'+filename,'--backend=Manifold','--export-format=binstl','-D','output_mode='+JSON.stringify(mode),'-o','/cabinet.stl'])}catch(e){if(typeof e==='number'&&engine.formatException)throw Error(engine.formatException(e));throw e}
  if(code!==0||logs.some(s=>/^ERROR:|ECHO: \"ERROR\|/.test(s)))throw Error('OpenSCAD could not render this configuration. Check the render log.');
  const bytes=engine.FS.readFile('/cabinet.stl');
  if(bytes.length<84)throw Error('The selected view contains no geometry.');
  const output=bytes.slice().buffer;
  self.postMessage({type:'result',output,elapsed:performance.now()-started,logs},[output]);
 }catch(e){self.postMessage({type:'error',error:e instanceof Error?e.message:String(e),logs})}
};
