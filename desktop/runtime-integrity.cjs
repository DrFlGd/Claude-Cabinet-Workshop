// Checks that the Electron runtime files beside the EXE are the ones this build
// shipped with. Every launch does a quick check (each file present with the
// recorded size, metadata only), retrying briefly while Windows is still
// extracting new files. The full SHA-256 comparison reads about 330 MB, so it runs
// only on request (Help → Verify program files) and in the packaged smoke test.
const fs=require('node:fs/promises');
const {createReadStream}=require('node:fs');
const {createHash}=require('node:crypto');
const path=require('node:path');

class RuntimeFileError extends Error{
 constructor(kind,name,detail=''){
  const text={missing:'Runtime file missing',locked:'Runtime file in use or blocked',mismatch:'Runtime file damaged or from a different version'}[kind];
  super(`${text}${detail?' ('+detail+')':''}: ${name}`);
  this.kind=kind;this.file=name;
 }
}
const TRANSIENT=new Set(['EBUSY','EPERM','EACCES','ENOENT','EAGAIN']);
const sleep=ms=>new Promise(r=>setTimeout(r,ms));

// Manifest values are {sha256,size}; older builds stored the hash string only.
function entries(manifest,root){
 if(!manifest['resources.pak']||!manifest['Cabinet Workshop.exe'])throw Error('Invalid runtime manifest');
 return Object.entries(manifest).map(([name,value])=>{
  const sha256=typeof value==='string'?value:value?.sha256,size=typeof value==='object'&&value?Number(value.size):undefined;
  const filename=path.resolve(root,name);
  if(!filename.startsWith(path.resolve(root)+path.sep)||!/^[a-f0-9]{64}$/.test(String(sha256))||(size!==undefined&&!(Number.isInteger(size)&&size>=0)))throw Error('Invalid runtime manifest entry');
  return {name,filename,sha256,size};
 });
}

async function checkFile(e,full){
 const stat=await fs.stat(e.filename).catch(error=>{throw error.code==='ENOENT'?new RuntimeFileError('missing',e.name):TRANSIENT.has(error.code)?new RuntimeFileError('locked',e.name,error.code):new RuntimeFileError('locked',e.name,error.code||String(error))});
 if(!stat.isFile())throw new RuntimeFileError('missing',e.name);
 if(e.size!==undefined&&stat.size!==e.size)throw new RuntimeFileError('mismatch',e.name,`size ${stat.size}, expected ${e.size}`);
 // The quick check reads metadata only. Opening each file would make antivirus scan
 // all of them (about 330 MB) on the first launch, including DLLs Chromium loads
 // only when needed, which is the delay this check replaces.
 if(!full&&e.size!==undefined)return;
 const hash=createHash('sha256');
 try{for await(const chunk of createReadStream(e.filename))hash.update(chunk)}
 catch(error){throw new RuntimeFileError(error.code==='ENOENT'?'missing':'locked',e.name,error.code)}
 if(hash.digest('hex')!==e.sha256)throw new RuntimeFileError('mismatch',e.name);
}

async function verifyRuntime(root,{full=false,retries=0,delay=400,manifestPath=path.join(root,'RUNTIME-SHA256.json')}={}){
 let text;
 for(let attempt=0;;attempt++){
  try{text=await fs.readFile(manifestPath,'utf8');break}
  catch(error){if(attempt>=retries||!TRANSIENT.has(error.code))throw new RuntimeFileError(error.code==='ENOENT'?'missing':'locked','RUNTIME-SHA256.json',error.code);await sleep(delay)}
 }
 const list=entries(JSON.parse(text),root);
 for(const e of list){
  for(let attempt=0;;attempt++){
   try{await checkFile(e,full);break}
   catch(error){
    // Missing, locked and short files are usually an extraction or virus scan still in progress.
    if(attempt>=retries||!(error instanceof RuntimeFileError))throw error;
    await sleep(delay);
   }
  }
 }
 return list.length;
}

module.exports={verifyRuntime,RuntimeFileError};
