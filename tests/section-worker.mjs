// Node harness for the unchanged production browser worker.
import fs from 'node:fs';
import {parentPort,workerData} from 'node:worker_threads';
globalThis.self={location:{href:'http://test/openscad/'+workerData},postMessage:(data,transfer)=>parentPort.postMessage(data,transfer)};
globalThis.importScripts=()=>{};
globalThis.fetch=async url=>{const pathname=new URL(String(url),'http://test').pathname;try{return new Response(fs.readFileSync(new URL('../public'+pathname,import.meta.url)),{headers:{'Content-Type':pathname.endsWith('.wasm')?'application/wasm':'text/plain'}})}catch{return new Response('',{status:404})}};
await import('../public/openscad/'+workerData);
parentPort.on('message',data=>self.onmessage({data}));
