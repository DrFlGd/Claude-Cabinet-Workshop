// Runs only when the packaged EXE is launched with --smoke-test.
module.exports=async function smoke(win,example){
 return win.webContents.executeJavaScript(`(async()=>{
  const until=Date.now()+45000;
  while(!document.querySelector('#root button')){if(Date.now()>until)throw Error('UI did not become ready: '+document.body.innerText.slice(0,400));await new Promise(r=>setTimeout(r,100));}
  if(/could not (load|start)/i.test(document.body.innerText))throw Error('Startup error shown');
  const {default:manifest}=await import('cabinet://app/openscad/engine-v5-files.js');
  const sources=await Promise.all(manifest.files.map(async name=>{const r=await fetch('cabinet://app/engine/'+name);if(!r.ok)throw Error('Missing engine source: '+name);return {name,text:await r.text()}}));
  const filename='v5/src/modular_organization/data/scad/kitchen.scad';
  let source=sources.find(f=>f.name===filename).text;
  for(const [key,value] of Object.entries(${JSON.stringify(example)}))source=source.replace(new RegExp('^'+key+'\\\\s*=\\\\s*[^;]+;','m'),key+' = '+JSON.stringify(value)+';');
  const output=await new Promise((resolve,reject)=>{
   const w=new Worker('cabinet://app/openscad/render-worker.js',{type:'module'});
   const timer=setTimeout(()=>{w.terminate();reject(Error('OpenSCAD worker timed out'))},60000);
   w.onerror=e=>{clearTimeout(timer);w.terminate();reject(Error(e.message))};
   w.onmessage=({data})=>{if(data.type==='error'||data.type==='result'){clearTimeout(timer);w.terminate();data.type==='error'?reject(Error(data.error)):resolve({bytes:data.output.byteLength,elapsed:data.elapsed})}};
   w.postMessage({filename,source,sources,mode:'assembly'});
  });
  if(output.bytes<=84)throw Error('Empty model');
  return {uiLoaded:true,photoAssembly:output,origin:location.origin};
 })()`);
};
