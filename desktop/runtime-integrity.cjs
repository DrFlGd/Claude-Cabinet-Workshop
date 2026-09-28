const fs=require('node:fs/promises');
const {createReadStream}=require('node:fs');
const {createHash}=require('node:crypto');
const path=require('node:path');
async function verifyRuntime(root,manifestPath=path.join(root,'RUNTIME-SHA256.json')){
 const manifest=JSON.parse(await fs.readFile(manifestPath,'utf8'));
 if(!manifest['resources.pak']||!manifest['Cabinet Workshop.exe'])throw Error('Invalid runtime manifest');
 for(const [name,expected] of Object.entries(manifest)){
  const filename=path.resolve(root,name);
  if(!filename.startsWith(path.resolve(root)+path.sep)||! /^[a-f0-9]{64}$/.test(expected))throw Error('Invalid runtime manifest entry');
  const hash=createHash('sha256');
  try { for await(const chunk of createReadStream(filename))hash.update(chunk); }
  catch { throw Error('Runtime file missing or unreadable: '+name); }
  if(hash.digest('hex')!==expected)throw Error('Runtime file damaged or from a different version: '+name);
 }
 return Object.keys(manifest).length;
}
module.exports={verifyRuntime};
