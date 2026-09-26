const fs=require('fs'),assert=require('assert/strict'),ts=require('typescript'),cp=require('child_process'),path=require('path');
function load(name,deps={}){const m={exports:{}};new Function('require','module','exports',ts.transpileModule(fs.readFileSync('lib/'+name+'.ts','utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2022,esModuleInterop:true}}).outputText)(n=>deps[n],m,m.exports);return m.exports}
const c=load('cabinet',{'./schema.json':require('../lib/schema.json'),'./engine-sources.json':require('../lib/engine-sources.json')}),s=load('settings');
const field=k=>c.schemas[3].fields.find(f=>f.key===k);
const tmp=fs.mkdtempSync(path.join(process.cwd(),'.stack-controls-'));
try{fs.cpSync('public/engine/v5/src/modular_organization/data/scad',tmp,{recursive:true});
for(const type of ['open','drawers','door','drawers','open']){
 const v=c.normalizeValues(3,{...c.defaults(3),module_type:type,stack_preview_count:1,custom_cabinet_contents:'open',door_shelf_count:3,drawer_count:3});
 assert.equal(v.custom_cabinet_contents,type);
 assert.equal(!!s.inactiveReason(field('drawer_count'),v),type!=='drawers');
 assert.equal(!!s.inactiveReason(field('door_shelf_count'),v),type==='drawers');
 assert(s.inactiveReason(field('mixed_bay_shelf_counts'),v));
 const source=c.applySettings(c.engineSources[c.schemas[3].file],3,v);fs.writeFileSync(path.join(tmp,'stackable.scad'),source);
 const r=cp.spawnSync('openscad',['-o',path.join(tmp,'model.csg'),path.join(tmp,'stackable.scad')],{encoding:'utf8',timeout:30000});assert.equal(r.status,0,r.stderr);assert(!/ECHO: "ERROR\||CHECK\|ERROR|^ERROR:/m.test(r.stderr),r.stderr);
 const parts=c.geometry(v,true,false);
 if(type==='drawers'){assert(/DIM\|DRAWER_BANK\|B1\|[^\n]*DRAWERS=3/.test(r.stderr));assert.equal(parts.filter(p=>p.name==='Drawer bottom').length,3);}
 else assert.equal(parts.filter(p=>p.name==='Shelf').length,3);
}
console.log('Stackable open/door/drawer transitions: controls, stale values, exported OpenSCAD and schematic counts passed.');
}finally{fs.rmSync(tmp,{recursive:true,force:true})}
