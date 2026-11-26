// Loads the app's product modules (lib/products/*.ts and what they import) in Node by
// transpiling them the way the other suites load the app's TypeScript.
import fs from 'node:fs';
import path from 'node:path';
import {createRequire} from 'node:module';
import ts from 'typescript';
const root=new URL('../',import.meta.url).pathname,nodeRequire=createRequire(import.meta.url),cache=new Map();
function load(file){
 if(cache.has(file))return cache.get(file).exports;
 if(file.endsWith('.json')){const m={exports:JSON.parse(fs.readFileSync(file,'utf8'))};cache.set(file,m);return m.exports}
 const m={exports:{}};cache.set(file,m);
 const out=ts.transpileModule(fs.readFileSync(file,'utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2022,esModuleInterop:true,resolveJsonModule:true}}).outputText;
 const req=n=>{
  if(!n.startsWith('.')&&!n.startsWith('@/'))return nodeRequire(n);
  const base=n.startsWith('@/')?path.join(root,n.slice(2)):path.resolve(path.dirname(file),n);
  for(const c of [base,base+'.ts',base+'.tsx',path.join(base,'index.ts')])if(fs.existsSync(c)&&fs.statSync(c).isFile())return load(c);
  throw Error('Cannot resolve '+n+' from '+file);
 };
 new Function('require','module','exports',out)(req,m,m.exports);
 return m.exports;
}
export const loadProducts=()=>load(path.join(root,'lib/products/index.ts'));
export const loadNesting=()=>load(path.join(root,'lib/nesting.ts'));
