const assert=require('node:assert/strict'),fs=require('node:fs'),path=require('node:path');
const {resolveAsset}=require('../desktop/assets.cjs'),root=path.resolve(process.argv[2]||'web-dist');
for(const url of ['https://app/index.html','cabinet://other/index.html','cabinet://app/%2e%2e%2fpackage.json','cabinet://app/%5csecret','cabinet://app/%00'])assert.equal(resolveAsset(root,url),null,url);
const entry=resolveAsset(root,'cabinet://app/');assert.equal(entry.file,path.join(root,'index.html'));assert(entry.type.startsWith('text/html'));
const html=fs.readFileSync(entry.file,'utf8');assert(html.includes('<base href="/">'));
for(const match of html.matchAll(/(?:src|href)="([^"]+)"/g)){const asset=resolveAsset(root,new URL(match[1],'cabinet://app/').href);assert(asset&&fs.existsSync(asset.file),match[1]);}
for(const [file,type] of [['openscad/openscad.wasm','application/wasm'],['openscad/render-worker.js','text/javascript'],['openscad/export-worker.js','text/javascript'],['openscad/engine-v5-files.js','text/javascript'],['openscad/DejaVuSans.ttf','font/ttf']]){const asset=resolveAsset(root,'cabinet://app/'+file);assert(asset.type.startsWith(type));assert(fs.statSync(asset.file).size>0);}
const manifestText=fs.readFileSync(path.join(root,'openscad/engine-v5-files.js'),'utf8');const manifest=JSON.parse(manifestText.replace(/^export default /,'').replace(/;\s*$/,''));for(const name of manifest.files)assert(fs.existsSync(path.join(root,'engine',name)),name);
const bundles=fs.readdirSync(path.join(root,'assets')).filter(n=>n.endsWith('.js')).map(n=>fs.readFileSync(path.join(root,'assets',n),'utf8')).join('\n');assert(bundles.includes('photo_section_cabinet'));assert(bundles.includes('Section layout'));
console.log('Desktop: root-relative entry, offline assets, MIME types, engine source manifest, photo starter and traversal rejection passed.');
