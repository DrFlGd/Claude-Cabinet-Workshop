const fs=require('node:fs'),assert=require('node:assert/strict'),vm=require('node:vm'),ts=require('typescript');
const bundled=require('../lib/engine-sources.json'),schema=require('../lib/schema.json');
const m={exports:{}};
new Function('require','module','exports',ts.transpileModule(fs.readFileSync('lib/cabinet.ts','utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2022,esModuleInterop:true}}).outputText)(n=>n==='./schema.json'?schema:bundled,m,m.exports);
const c=m.exports;
(async()=>{
 global.fetch=()=>{throw Error('Network unavailable')};
 for(let family=0;family<6;family++){
  const values=c.defaults(family);const source=await c.configuredSource(family,values);
  assert.equal(source,c.applySettings(fs.readFileSync('public/engine/'+schema[family].file,'utf8'),family,values));
  assert((await c.exportBundle(family,values)).size>100000);
 }
 for(const [name,text] of Object.entries(bundled))assert.equal(text,fs.readFileSync('public/engine/'+name,'utf8'));
 const controller=new AbortController();controller.abort();await assert.rejects(c.configuredSource(0,c.defaults(0),controller.signal),{name:'AbortError'});
 for(const filename of [schema[0].file,'parametric_shop_cart_v5.scad']){
  const writes={},messages=[],requests=[];
  const engine={FS:{writeFile:(name,text)=>writes[name]=text,readFile:()=>new Uint8Array(100)},callMain:()=>0};
  const context={performance,Uint8Array,URL,self:{location:{href:'https://example/openscad/render-worker.js'},postMessage:m=>messages.push(m)},fetch:async url=>{requests.push(url);return {ok:true,text:async()=>fs.readFileSync('public'+url,'utf8')}}};
  let worker=fs.readFileSync('public/openscad/render-worker.js','utf8').replace("await import('./openscad.js')","{default:async()=>mockEngine}");context.mockEngine=engine;vm.runInNewContext(worker,context);
  const legacy=filename.includes('_v5.');
  await context.self.onmessage({data:{filename,source:fs.readFileSync('public/engine/'+filename,'utf8'),mode:'assembly',...(legacy?{}:{sources:c.renderSources})}});
  assert.equal(messages.at(-1).type,'result',JSON.stringify(messages));
  assert.equal(requests.length,legacy?2:0);assert(writes[legacy?'/cabinet_core_v17.scad':'/modular_storage_core_v32.scad']);
 }
 console.log('All families configure and export without network; cancellation, bundled source parity, and old/new worker protocols passed.');
})();
