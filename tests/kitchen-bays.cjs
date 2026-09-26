const fs=require('fs'),assert=require('assert/strict'),ts=require('typescript'),cp=require('child_process'),os=require('os'),path=require('path');
function load(name,deps={}){const m={exports:{}};new Function('require','module','exports',ts.transpileModule(fs.readFileSync('lib/'+name+'.ts','utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2022,esModuleInterop:true}}).outputText)(n=>deps[n],m,m.exports);return m.exports}
const schema=require('../lib/schema.json'),sources=require('../lib/engine-sources.json');const c=load('cabinet',{'./schema.json':schema,'./engine-sources.json':sources}),u=load('units');
for(const f of schema)for(const k of ['wood_rail_thickness','wood_drawer_runner_thickness']){const field=f.fields.find(p=>p.key===k);if(field)assert.equal(field.section,'Hardware / Wood Runners')}
assert(!u.isLengthField({key:'width_basis',value:'outside',unit:'mm',options:['outside']}));assert(!u.isLengthField({key:'mixed_bay_width_weights',value:[1,1],unit:'mm'}));
const tmp=fs.mkdtempSync(path.join(process.cwd(),'.kitchen-bays-'));
try{
 const base=path.join(tmp,'scad');fs.cpSync('public/engine/v5/src/modular_organization/data/scad',base,{recursive:true});
 for(const count of [2,3,4])for(const joinery of ['butt','dado','tab_slot']){
  const v=c.normalizeValues(4,{...c.defaults(4),cabinet_width:count*400,cabinet_layout_mode:'mixed_bays',mixed_bay_count:count,mixed_bay_types:['drawers'],mixed_bay_width_weights:[2],joinery_style:joinery});
  assert.equal(v.mixed_bay_types.length,count);assert.equal(v.mixed_bay_width_weights[0],2);assert.equal(v.mixed_bay_width_weights.length,count);assert.equal(v.include_mixed_bay_partitions,true);
  assert.equal(c.geometry(v,false,false).filter(p=>p.name==='Bay divider').length,count-1);
  fs.writeFileSync(path.join(base,'kitchen.scad'),c.applySettings(sources[schema[4].file],4,v));
  const r=cp.spawnSync('openscad',['-o',path.join(tmp,'model.csg'),path.join(base,'kitchen.scad')],{encoding:'utf8',timeout:30000});const log=r.stdout+r.stderr;
  assert.equal(r.status,0,log);assert(!/ECHO: "ERROR\||CHECK\|ERROR|^ERROR:/m.test(log),log);assert(log.includes('"  structural partitions = ", '+(count-1)),log);
 }
 console.log('Kitchen 2/3/4 bays with butt/dado/tab-slot: partition counts, saved-array migration, exported source, native geometry and hardware grouping passed.');
}finally{fs.rmSync(tmp,{recursive:true,force:true})}
