// Runs only when the packaged EXE is launched with --smoke-test.
module.exports=async function smoke(win,example){
 return win.webContents.executeJavaScript(`(async()=>{
  const until=Date.now()+45000;
  while(!document.querySelector('#root button')){if(Date.now()>until)throw Error('UI did not become ready: '+document.body.innerText.slice(0,400));await new Promise(r=>setTimeout(r,100));}
  if(/could not (load|start)/i.test(document.body.innerText))throw Error('Startup error shown');
  const waitFor=async check=>{const deadline=Date.now()+10000;while(!check()){if(Date.now()>deadline)throw Error('Section editor interaction timed out');await new Promise(r=>setTimeout(r,50));}};
  const layout={head:getComputedStyle(document.head).display,title:getComputedStyle(document.querySelector('title')).display,styles:[...document.querySelectorAll('style')].map(e=>({display:getComputedStyle(e).display,rects:e.getClientRects().length})),headerTop:document.querySelector('.app-header').getBoundingClientRect().top};
  if(layout.head!=='none'||layout.styles.some(e=>e.rects)||Math.abs(layout.headerTop)>2)throw Error('Broken document layout: '+JSON.stringify(layout));
  const imported={version:2,engine:5,engineFamily:'modular_organization',family:4,name:'Windows section regression',displayUnits:'mm',values:${JSON.stringify(example)}};
  const transfer=new DataTransfer();transfer.items.add(new File([JSON.stringify(imported)],'photo.cabinet.json',{type:'application/json'}));
  const fileInput=document.querySelector('input[type=file]');fileInput.files=transfer.files;fileInput.dispatchEvent(new Event('change',{bubbles:true}));
  await waitFor(()=>document.querySelector('input[aria-label="Design name"]').value==='Windows section regression');
  document.getElementById('settings-section').click();
  await waitFor(()=>[...document.querySelectorAll('[role=option]')].some(e=>e.textContent.trim()==='Structure'));
  [...document.querySelectorAll('[role=option]')].find(e=>e.textContent.trim()==='Structure').click();
  await waitFor(()=>document.getElementById('section-selection'));
  if(document.querySelector('.section-breadcrumbs'))throw Error('Redundant section buttons still present');
  const highlighted=()=>[...document.querySelectorAll('.section-diagram g[aria-pressed=true]')].map(e=>Number(e.dataset.sectionId)).join(',');
  const select=document.getElementById('section-selection');
  for(const [id,expected] of [[0,'3,4,5,6,7'],[1,'3,4,5'],[2,'6,7'],[4,'4']]){select.value=String(id);select.dispatchEvent(new Event('change',{bubbles:true}));await waitFor(()=>highlighted()===expected);}
  document.querySelector('.section-diagram g[data-section-id="3"]').dispatchEvent(new MouseEvent('click',{bubbles:true}));
  await waitFor(()=>select.value==='3'&&highlighted()==='3');
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
  return {uiLoaded:true,sectionSelection:true,photoAssembly:output,origin:location.origin};
 })()`);
};
