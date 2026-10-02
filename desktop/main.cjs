const {app,BrowserWindow,protocol,shell,dialog,Menu}=require('electron');
const fs=require('node:fs/promises');
const smoke=process.argv.includes('--smoke-test');
const path=require('node:path');
const {resolveAsset}=require('./assets.cjs');
const {verifyRuntime}=require('./runtime-integrity.cjs');
protocol.registerSchemesAsPrivileged([{scheme:'cabinet',privileges:{standard:true,secure:true,supportFetchAPI:true,corsEnabled:true,stream:true}}]);
app.setName('Cabinet Workshop');
const installRoot=path.join(__dirname,'..','..');

// A short start-up log (last launch only) in the user profile, for diagnosing
// launches that fail on a particular machine.
const started=Date.now(),logLines=[];
const log=message=>logLines.push(`${new Date().toISOString()} +${Date.now()-started} ms ${message}`);
const logPath=()=>path.join(app.getPath('userData'),'startup.log');
async function saveLog(){try{await fs.mkdir(app.getPath('userData'),{recursive:true});await fs.writeFile(logPath(),logLines.join('\n')+'\n')}catch{}}

const startingPage='data:text/html;charset=utf-8,'+encodeURIComponent(`<!doctype html><html><head><meta charset="utf-8"><title>Cabinet Workshop</title><style>
html,body{height:100%;margin:0}body{display:flex;align-items:center;justify-content:center;background:#f6f8f8;color:#213943;font:15px Arial,Helvetica,sans-serif}
main{text-align:center;max-width:420px;padding:24px}h1{font-size:22px;margin:0 0 10px}p{margin:6px 0;color:#5a737e;line-height:1.5}
.bar{width:180px;height:4px;margin:18px auto 0;border-radius:2px;background:#dde4e6;overflow:hidden}.bar::after{content:"";display:block;width:40%;height:100%;background:#ce572b;animation:s 1.1s ease-in-out infinite}
@keyframes s{0%{transform:translateX(-100%)}100%{transform:translateX(250%)}}</style></head>
<body><main><h1>Cabinet Workshop</h1><p>Starting…</p><p><small>The first start after extracting can take a little longer while Windows checks the new files.</small></p><div class="bar"></div></main></body></html>`);

function startupMessage(error){
 const file=error&&error.file?` (${error.file})`:'';
 if(error&&error.kind==='locked')return `Windows is still using one of the program files${file}. This usually means the ZIP is still being extracted or antivirus is scanning the new files.\n\nWait a few seconds, then start Cabinet Workshop again.`;
 if(error&&error.kind==='missing')return `A program file was not found next to Cabinet Workshop.exe${file}.\n\nExtract ALL files from the ZIP into a NEW folder, let the extraction finish, and start Cabinet Workshop.exe from that folder. Copying only the EXE does not work.`;
 if(error&&error.kind==='mismatch')return `A program file is damaged or from a different version${file}.\n\nExtract ALL files from the latest ZIP into a NEW folder. Do not merge different versions.`;
 return `${String(error)}\n\nExtract ALL files from the latest ZIP into a NEW folder. Do not copy just the EXE or merge different versions.`;
}

const single=app.requestSingleInstanceLock();
let win;
if(!single){
 // Another copy is already running; it brings its window to the front.
 app.quit();
}
else {
 app.on('second-instance',()=>{log('second launch: focusing the running window');if(win){if(win.isMinimized())win.restore();win.show();win.focus()}});
 app.whenReady().then(async()=>{
  log('ready; '+installRoot);
  // The window appears immediately with a starting page; the app replaces it once checked.
  win=new BrowserWindow({show:false,width:1440,height:960,minWidth:800,minHeight:600,title:'Cabinet Workshop',backgroundColor:'#f6f8f8',webPreferences:{nodeIntegration:false,contextIsolation:true,sandbox:true,webSecurity:true}});
  win.webContents.session.setPermissionRequestHandler((_wc,_p,cb)=>cb(false));
  const openExternal=url=>{try{if(new URL(url).protocol==='https:')shell.openExternal(url).catch(()=>{})}catch{}};
  win.webContents.setWindowOpenHandler(({url})=>{openExternal(url);return {action:'deny'}});
  win.webContents.on('will-navigate',(event,url)=>{if(!url.startsWith('cabinet://app/')){event.preventDefault();openExternal(url)}});
  win.webContents.on('will-prevent-unload',event=>{
   const response=dialog.showMessageBoxSync(win,{type:'question',buttons:['Keep editing','Leave without downloading'],defaultId:0,cancelId:0,title:'Unsaved design',message:'Leave this design?',detail:'Download important designs with Save design before leaving.'});
   if(response===1)event.preventDefault();
  });
  win.webContents.on('render-process-gone',(_event,details)=>{log('renderer gone: '+details.reason);saveLog();dialog.showErrorBox('Cabinet Workshop renderer stopped','Reason: '+details.reason+'. Close and restart the application.');});
  await win.loadURL(startingPage);
  win.show();
  log('starting page shown');

  // Quick check on every launch (present, readable, right size), retrying for a few
  // seconds while Windows finishes extracting or scanning. The smoke test compares hashes.
  const runtimeFiles=await verifyRuntime(installRoot,smoke?{full:true}:{retries:10,delay:400});
  log(`runtime files checked: ${runtimeFiles}${smoke?' (SHA-256)':''}`);

  const root=path.join(__dirname,'renderer');
  protocol.handle('cabinet',async request=>{
   try{
    const asset=resolveAsset(root,request.url);
    if(!asset||!['GET','HEAD'].includes(request.method))return new Response('Not found',{status:404});
    const bytes=await fs.readFile(asset.file);
    return new Response(request.method==='HEAD'?null:bytes,{headers:{'Content-Type':asset.type,'X-Content-Type-Options':'nosniff','Content-Security-Policy':"default-src 'self'; script-src 'self' 'wasm-unsafe-eval'; style-src 'self' 'unsafe-inline'; img-src 'self' data: blob:; font-src 'self' data:; connect-src 'self' blob:; worker-src 'self' blob:; object-src 'none'"}});
   }catch{return new Response('Not found',{status:404})}
  });
  let verifying=false;
  const verifyFiles=async()=>{
   if(verifying)return;verifying=true;
   try{const count=await verifyRuntime(installRoot,{full:true});dialog.showMessageBox(win,{type:'info',title:'Program files',message:'All program files are intact.',detail:`${count} runtime files match the checksums recorded when this build was made.`})}
   catch(error){dialog.showMessageBox(win,{type:'error',title:'Program files',message:'A program file does not match this build.',detail:startupMessage(error)})}
   finally{verifying=false}
  };
  Menu.setApplicationMenu(Menu.buildFromTemplate([{label:'File',submenu:[{role:'quit'}]},{label:'Edit',submenu:[{role:'undo'},{role:'redo'},{type:'separator'},{role:'cut'},{role:'copy'},{role:'paste'},{role:'selectAll'}]},{label:'View',submenu:[{role:'resetZoom'},{role:'zoomIn'},{role:'zoomOut'},{role:'togglefullscreen'}]},{label:'Help',submenu:[{label:'Verify program files…',click:verifyFiles},{label:'Open start-up log',click:async()=>{await saveLog();shell.showItemInFolder(logPath())}},{type:'separator'},{label:'About Cabinet Workshop',click:()=>dialog.showMessageBox(win,{type:'info',title:'Cabinet Workshop',message:'Cabinet Workshop '+app.getVersion(),detail:'Windows x64 portable test build. Modular Organization engine v5.'})}]}]));
  await win.loadURL('cabinet://app/');
  const layoutReady=await win.webContents.executeJavaScript(`(()=>{
   const probe=document.createElement('div');document.body.append(probe);
   const block=getComputedStyle(probe).display;probe.remove();
   return getComputedStyle(document.head).display==='none'&&block==='block';
  })()`);
  if(!layoutReady)throw Error('Browser default styles did not load. Extract the complete ZIP into a new folder and launch the EXE from that folder.');
  log('application loaded');
  await saveLog();
  if(smoke){
   const example=JSON.parse(await fs.readFile(path.join(installRoot,'Photo-example.cabinet.json'),'utf8'));
   let result;
   try { result=await require('./smoke.cjs')(win,example.values); }
   finally { const screenshot=await win.webContents.capturePage(); await fs.writeFile(path.join(installRoot,'WINDOWS-LAYOUT.png'),screenshot.toPNG()); }
   await fs.writeFile(process.env.CABINET_SMOKE_REPORT||path.join(app.getPath('temp'),'cabinet-smoke.json'),JSON.stringify({passed:true,version:app.getVersion(),runtimeFilesVerified:runtimeFiles,startupMs:Date.now()-started,...result},null,2));
   app.exit(0);
  }
 }).catch(async error=>{
  log('start-up failed: '+String(error));
  // Closing the window while it was still starting is not a failure.
  if(!smoke&&win&&win.isDestroyed()){await saveLog();app.quit();return}
  await saveLog();
  if(smoke){await fs.writeFile(process.env.CABINET_SMOKE_REPORT||path.join(app.getPath('temp'),'cabinet-smoke.json'),JSON.stringify({passed:false,error:String(error)}));app.exit(1)}
  else{dialog.showErrorBox('Cabinet Workshop could not start',startupMessage(error)+'\n\nDetails: '+String(error)+'\nStart-up log: '+logPath());app.quit()}
 });
 app.on('window-all-closed',()=>app.quit());
}
