// One engine instance per job. Terminating this worker cancels synchronous WASM work.
self.onmessage = async ({data}) => {
 const started=performance.now();const logs=[];
 const log=(line)=>{line=String(line).slice(0,2000);logs.push(line);if(logs.length>150)logs.shift();self.postMessage({type:'log',line})};
 try {
  const {filename,source,mode}=data;
  const legacy=['parametric_shop_cart_v5.scad','parametric_utility_cabinet_v49.scad','parametric_benchtop_drawer_cabinet_v21.scad'].includes(filename);
  const organization=/^modular_organization_(shop_cart|utility|benchtop|stackable|kitchen|drawer)_v3\.scad$/.test(filename);
  const modular=filename?.startsWith('modular_storage_');
  const version=filename?.endsWith('_v32.scad')?32:29;
  const names=organization?["modular_organization_core_v3.scad","modular_organization_layouts_v3.scad"]:modular?[`modular_storage_core_v${version}.scad`,`modular_storage_layouts_v${version}.scad`]:legacy?['cabinet_core_v17.scad','cabinet_layouts_v17.scad']:['cabinet_core_v25.scad','cabinet_layouts_v25.scad'];
  if(!organization&&!/^modular_storage_(shop_cart|utility|benchtop|stackable|kitchen|drawer)_v32\.scad$/.test(filename)&&!['modular_storage_shop_cart_v29.scad','modular_storage_utility_v29.scad','modular_storage_benchtop_v29.scad','modular_storage_stackable_v29.scad','modular_storage_kitchen_v29.scad'].includes(filename)&&!legacy&&!['parametric_shop_cart_v13.scad','parametric_utility_cabinet_v57.scad','parametric_benchtop_drawer_cabinet_v29.scad','parametric_stackable_cabinet_v7.scad','parametric_kitchen_cabinet_v2.scad'].includes(filename)||typeof source!=='string'||source.length>1000000||!['assembly','carcass_only','drawers_only'].includes(mode))throw Error('Invalid render request.');
  self.postMessage({type:'stage',stage:'Loading OpenSCAD…'});
  // New tabs supply a complete, matching engine snapshot; older tabs use versioned assets.
  const sources=data.sources===undefined?await Promise.all(names.map(async name=>{
   const r=await fetch('/engine/'+name);
   if(!r.ok)throw Error('Unable to load cabinet engine (HTTP '+r.status+'). Save your design, refresh the page, and try again.');
   const text=await r.text();if(/^\s*</.test(text))throw Error('Please save your design and sign in again before rendering.');
   return {name,text};
  })):data.sources;
  if(!Array.isArray(sources)||sources.length!==2||!names.every(name=>sources.some(f=>f.name===name&&typeof f.text==='string'&&f.text.length<1000000)))throw Error('Invalid cabinet engine sources.');
  const {default:OpenSCAD}=await import('./openscad.js');
  const engine=await OpenSCAD({noInitialRun:true,locateFile:path=>new URL(path,self.location.href).href,print:log,printErr:log});
  for(const f of sources)engine.FS.writeFile('/'+f.name,f.text);
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
