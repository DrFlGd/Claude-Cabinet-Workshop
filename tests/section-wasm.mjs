import fs from 'node:fs';import {Worker} from 'node:worker_threads';import assert from 'node:assert/strict';
const read=name=>JSON.parse(fs.readFileSync(new URL('../'+name,import.meta.url)));
const schema=read('lib/schema.json'),bundle=read('lib/engine-sources.json'),example=read('examples/photo-section-cabinet.cabinet.json'),filename=schema[4].file;
let source=bundle[filename];for(const [key,value] of Object.entries({...example.values,hinge_style:'euro_35mm',include_shared_export_bounding_box:true}))source=source.replace(new RegExp('^'+key+'\\s*=\\s*[^;]+;','m'),key+' = '+JSON.stringify(value)+';');
const sources=Object.entries(bundle).filter(([name])=>name.endsWith('.scad')).map(([name,text])=>({name,text}));
let viewBox;
for(const mode of ['assembly','flat_3d','bom','cut_layout','pocket_hinge_cups','engrave_layout']){
 const render=['assembly','flat_3d'].includes(mode),worker=new Worker(new URL('./section-worker.mjs',import.meta.url),{workerData:render?'render-worker.js':'export-worker.js'});
 const result=await new Promise((resolve,reject)=>{const timer=setTimeout(()=>{worker.terminate();reject(Error(mode+' timed out'))},120000);worker.on('error',e=>{clearTimeout(timer);worker.terminate();reject(e)});worker.on('message',m=>{if(['error','result'].includes(m.type)){clearTimeout(timer);worker.terminate();resolve(m)}});worker.postMessage({filename,source,mode,sources})});
 assert.equal(result.type,'result',JSON.stringify(result));
 if(render)assert(result.output.byteLength>84);
 else if(mode==='bom'){assert.equal(result.output.split('\n').filter(l=>l.includes('|drawer_face|')).length,6);assert.equal(result.output.split('\n').filter(l=>l.includes('|door|')).length,2);}
 else {const box=result.output.match(/viewBox="([^"]+)/)[1];if(viewBox)assert.equal(box,viewBox);viewBox=box;assert(result.output.includes('<svg'));}
 console.log('Production worker: photo '+mode+' passed.');
}
