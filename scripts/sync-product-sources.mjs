// Refresh the embedded product engine sources (lib/products/product-sources.json) from
// public/products/**. The browser and the source export read the embedded copies, so every
// edit to a product's SCAD file must be followed by this sync. `--check` exits non-zero
// when the embedded copy is stale or a product file is missing from it.
import fs from 'node:fs';
import path from 'node:path';
const root=new URL('../',import.meta.url),base=new URL('public/',root),target=new URL('lib/products/product-sources.json',root);
const found={};
(function walk(dir){for(const e of fs.readdirSync(dir,{withFileTypes:true})){const p=path.join(dir,e.name);if(e.isDirectory())walk(p);else if(e.name.endsWith('.scad'))found[path.relative(base.pathname,p).split(path.sep).join('/')]=fs.readFileSync(p,'utf8')}})(new URL('products/',base).pathname);
const now=fs.existsSync(target)?JSON.parse(fs.readFileSync(target,'utf8')):{};
const stale=Object.keys({...found,...now}).filter(k=>found[k]!==now[k]);
if(process.argv.includes('--check')){
 if(stale.length){console.error('Embedded product sources are stale:\n  '+stale.join('\n  ')+'\nRun: node scripts/sync-product-sources.mjs');process.exit(1)}
 console.log('Embedded product sources match public/products.');
}else{fs.writeFileSync(target,JSON.stringify(found,null,1)+'\n');console.log(stale.length?'Updated '+stale.join(', '):'Already in sync.')}
