const {app,BrowserWindow,protocol,shell,dialog,Menu}=require('electron');
const fs=require('node:fs/promises');
const smoke=process.argv.includes('--smoke-test');
if(smoke)app.disableHardwareAcceleration();
const path=require('node:path');
const {resolveAsset}=require('./assets.cjs');
protocol.registerSchemesAsPrivileged([{scheme:'cabinet',privileges:{standard:true,secure:true,supportFetchAPI:true,corsEnabled:true,stream:true}}]);
app.setName('Cabinet Workshop');
const single=app.requestSingleInstanceLock();
let win;
if(!single)app.quit();
else {
 app.on('second-instance',()=>{if(win){if(win.isMinimized())win.restore();win.focus()}});
 app.whenReady().then(async()=>{
  const root=path.join(__dirname,'renderer');
  protocol.handle('cabinet',async request=>{
   try{
    const asset=resolveAsset(root,request.url);
    if(!asset||!['GET','HEAD'].includes(request.method))return new Response('Not found',{status:404});
    const bytes=await fs.readFile(asset.file);
    return new Response(request.method==='HEAD'?null:bytes,{headers:{'Content-Type':asset.type,'X-Content-Type-Options':'nosniff','Content-Security-Policy':"default-src 'self'; script-src 'self' 'wasm-unsafe-eval'; style-src 'self' 'unsafe-inline'; img-src 'self' data: blob:; font-src 'self' data:; connect-src 'self' blob:; worker-src 'self' blob:; object-src 'none'"}});
   }catch{return new Response('Not found',{status:404})}
  });
  win=new BrowserWindow({show:!smoke,width:1440,height:960,minWidth:800,minHeight:600,title:'Cabinet Workshop',backgroundColor:'#f6f8f8',webPreferences:{nodeIntegration:false,contextIsolation:true,sandbox:true,webSecurity:true}});
  win.webContents.session.setPermissionRequestHandler((_wc,_p,cb)=>cb(false));
  const openExternal=url=>{try{if(new URL(url).protocol==='https:')shell.openExternal(url).catch(()=>{})}catch{}};
  win.webContents.setWindowOpenHandler(({url})=>{openExternal(url);return {action:'deny'}});
  win.webContents.on('will-navigate',(event,url)=>{if(!url.startsWith('cabinet://app/')){event.preventDefault();openExternal(url)}});
  win.webContents.on('will-prevent-unload',event=>{
   const response=dialog.showMessageBoxSync(win,{type:'question',buttons:['Keep editing','Leave without downloading'],defaultId:0,cancelId:0,title:'Unsaved design',message:'Leave this design?',detail:'Download important designs with Save design before leaving.'});
   if(response===1)event.preventDefault();
  });
  Menu.setApplicationMenu(Menu.buildFromTemplate([{label:'File',submenu:[{role:'quit'}]},{label:'Edit',submenu:[{role:'undo'},{role:'redo'},{type:'separator'},{role:'cut'},{role:'copy'},{role:'paste'},{role:'selectAll'}]},{label:'View',submenu:[{role:'resetZoom'},{role:'zoomIn'},{role:'zoomOut'},{role:'togglefullscreen'}]},{label:'Help',submenu:[{label:'About Cabinet Workshop',click:()=>dialog.showMessageBox(win,{type:'info',title:'Cabinet Workshop',message:'Cabinet Workshop '+app.getVersion(),detail:'Windows x64 portable test build. Modular Organization engine v5.'})}]}]));
  win.webContents.on('render-process-gone',(_event,details)=>{dialog.showErrorBox('Cabinet Workshop renderer stopped','Reason: '+details.reason+'. Close and restart the application.');});
  await win.loadURL('cabinet://app/');
  if(smoke){
   const example=JSON.parse(await fs.readFile(path.join(__dirname,'..','..','Photo-example.cabinet.json'),'utf8'));
   let result;
   try { result=await require('./smoke.cjs')(win,example.values); }
   finally { const screenshot=await win.webContents.capturePage(); await fs.writeFile(path.join(__dirname,'..','..','WINDOWS-LAYOUT.png'),screenshot.toPNG()); }
   await fs.writeFile(process.env.CABINET_SMOKE_REPORT||path.join(app.getPath('temp'),'cabinet-smoke.json'),JSON.stringify({passed:true,version:app.getVersion(),...result},null,2));
   app.exit(0);
  }
 }).catch(async error=>{if(smoke){await fs.writeFile(process.env.CABINET_SMOKE_REPORT||path.join(app.getPath('temp'),'cabinet-smoke.json'),JSON.stringify({passed:false,error:String(error)}));app.exit(1)}else{dialog.showErrorBox('Cabinet Workshop could not start',String(error));app.quit()}});
 app.on('window-all-closed',()=>app.quit());
}
