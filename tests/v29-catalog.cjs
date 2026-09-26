const fs=require('node:fs'),assert=require('node:assert/strict'),ts=require('typescript');
function compile(path,deps={}){const m={exports:{}};new Function('require','module','exports',ts.transpileModule(fs.readFileSync(path,'utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2022,esModuleInterop:true}}).outputText)(n=>deps[n]??require(n),m,m.exports);return m.exports}
const source=require('../public/engine/modular_storage_schema_v1.json'),settings=compile('lib/settings.ts');const c=compile('lib/cabinet.ts',{'./schema.json':require('../lib/schema.json'),'./engine-sources.json':require('../lib/engine-sources.json')});
let total=0;for(let family=0;family<6;family++){
 const schema=c.schemas[family],api=Object.values(source.frontends).find(f=>f.file===schema.file);assert.equal(schema.fields.length,api.parameters.length);
 for(const field of schema.fields)assert(settings.sectionOrder.includes(settings.sectionFor(field)));
 for(const recipe of schema.starters){const v=c.starterValues(family,recipe.id);assert.deepEqual(c.validate(v),[],recipe.id);assert(c.geometry(v,false,false).every(p=>[p.x,p.y,p.z,p.w,p.d,p.h].every(Number.isFinite)));const text=c.applySettings(fs.readFileSync('public/engine/'+schema.file,'utf8'),family,v);assert(!/=\s*null;/.test(text));assert(text.includes('modular_storage_core_v32.scad'));total++}
}
const report=compile('lib/manufacturing.ts');assert.throws(()=>report.reports('ECHO: "BOM|X|1|carcass|PLY|18|undef|500|"\nECHO: "DIM|UNITS|mm"'),/undefined/);
console.log(total+' default/recipe configurations, schema coverage, geometry, automatic expressions and invalid-BOM rejection passed.');
