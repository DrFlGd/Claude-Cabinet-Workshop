const assert=require('node:assert/strict');
const fs=require('node:fs/promises');
const os=require('node:os');
const path=require('node:path');
const {createHash}=require('node:crypto');
const {verifyRuntime}=require('../desktop/runtime-integrity.cjs');
(async()=>{
 const root=await fs.mkdtemp(path.join(os.tmpdir(),'cabinet-integrity-'));
 try {
  const files={'Cabinet Workshop.exe':'runtime executable','resources.pak':'matching browser styles','locales/en-US.pak':'locale'};
  const manifest={};
  for(const [name,content] of Object.entries(files)){await fs.mkdir(path.dirname(path.join(root,name)),{recursive:true});await fs.writeFile(path.join(root,name),content);manifest[name]={sha256:createHash('sha256').update(content).digest('hex'),size:Buffer.byteLength(content)};}
  await fs.writeFile(path.join(root,'RUNTIME-SHA256.json'),JSON.stringify(manifest));
  // Quick (every launch) and full (Help > Verify, smoke test) checks of a complete runtime.
  assert.equal(await verifyRuntime(root),3);
  assert.equal(await verifyRuntime(root,{full:true}),3);
  // Same size, different bytes: only the full check can see it.
  await fs.writeFile(path.join(root,'resources.pak'),'MATCHING browser styles');
  assert.equal(await verifyRuntime(root),3);
  await assert.rejects(verifyRuntime(root,{full:true}),e=>e.kind==='mismatch'&&/damaged or from a different version: resources.pak/.test(e.message));
  // A different size is caught by the quick check.
  await fs.writeFile(path.join(root,'resources.pak'),'different runtime pack');
  await assert.rejects(verifyRuntime(root),e=>e.kind==='mismatch'&&e.file==='resources.pak');
  // Missing files are reported by name.
  await fs.unlink(path.join(root,'resources.pak'));
  await assert.rejects(verifyRuntime(root),e=>e.kind==='missing'&&/missing: resources.pak/.test(e.message));
  // A file that is still being extracted (missing, then short, then complete) passes once it settles.
  const late=setTimeout(()=>fs.writeFile(path.join(root,'resources.pak'),'matching'),150);
  const done=setTimeout(()=>fs.writeFile(path.join(root,'resources.pak'),files['resources.pak']),450);
  const t=Date.now();
  assert.equal(await verifyRuntime(root,{retries:10,delay:100,full:true}),3);
  assert(Date.now()-t>=400,'waited for the file to settle');
  clearTimeout(late);clearTimeout(done);
  // Manifests from earlier builds (hash strings only) are still accepted.
  const legacy=Object.fromEntries(Object.entries(manifest).map(([k,v])=>[k,v.sha256]));
  await fs.writeFile(path.join(root,'RUNTIME-SHA256.json'),JSON.stringify(legacy));
  assert.equal(await verifyRuntime(root),3);
  await fs.writeFile(path.join(root,'RUNTIME-SHA256.json'),JSON.stringify({...legacy,'../outside.dll':legacy['resources.pak']}));
  await assert.rejects(verifyRuntime(root),/Invalid runtime manifest entry/);
  console.log('Runtime integrity: quick and full checks, size and hash mismatches, missing files, files still being written, legacy manifests and path traversal checked');
 } finally { await fs.rm(root,{recursive:true,force:true}); }
})().catch(e=>{console.error(e);process.exitCode=1});
