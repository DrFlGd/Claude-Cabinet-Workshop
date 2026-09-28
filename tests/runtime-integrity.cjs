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
  for(const [name,content] of Object.entries(files)){await fs.mkdir(path.dirname(path.join(root,name)),{recursive:true});await fs.writeFile(path.join(root,name),content);manifest[name]=createHash('sha256').update(content).digest('hex');}
  await fs.writeFile(path.join(root,'RUNTIME-SHA256.json'),JSON.stringify(manifest));
  assert.equal(await verifyRuntime(root),3);
  await fs.writeFile(path.join(root,'resources.pak'),'different runtime pack');
  await assert.rejects(verifyRuntime(root),/damaged or from a different version: resources.pak/);
  await fs.unlink(path.join(root,'resources.pak'));
  await assert.rejects(verifyRuntime(root),/missing or unreadable: resources.pak/);
  console.log('Runtime integrity: complete, mismatched and missing files checked');
 } finally { await fs.rm(root,{recursive:true,force:true}); }
})().catch(e=>{console.error(e);process.exitCode=1});
