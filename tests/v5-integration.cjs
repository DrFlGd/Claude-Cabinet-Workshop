const fs=require('fs'),assert=require('assert/strict'),ts=require('typescript'),cp=require('child_process');
function load(name,deps={}){const m={exports:{}};new Function('require','module','exports',ts.transpileModule(fs.readFileSync('lib/'+name+'.ts','utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2022,esModuleInterop:true}}).outputText)(n=>deps[n],m,m.exports);return m.exports}
const c=load('cabinet',{'./schema.json':require('../lib/schema.json'),'./engine-sources.json':require('../lib/engine-sources.json')}),p=load('projects',{'./cabinet':c}),m=load('manufacturing'),s=load('settings'),u=load('units');
const old=require('./fixtures/v3-schema.json');
for(let family=0;family<6;family++){
 const values=Object.fromEntries(old[family].fields.map(f=>[f.key,f.value]));const result=p.parseDesign({version:2,engine:3,engineFamily:'modular_organization',family,displayUnits:'in',values});
 assert.equal(result.engine,5);assert.equal(result.displayUnits,'in');
 for(const f of old[family].fields)if(c.schemas[family].fields.some(x=>x.key===f.key)&&!['cabinet_preset','cabinet_layout_mode','mixed_bay_count','mixed_bay_types','mixed_bay_width_weights','mixed_bay_drawer_counts','mixed_bay_shelf_counts','mixed_bay_door_counts','base_style','include_worktop'].includes(f.key))assert.deepEqual(result.values[f.key],f.value,family+' '+f.key);
}
for(let family=0;family<7;family++)for(const starter of c.schemas[family].starters){const v=c.starterValues(family,starter.id);p.parseDesign({version:2,engine:5,engineFamily:'modular_organization',family,values:v});assert.deepEqual(c.validate(v),[],starter.id);assert(c.geometry(v,false,false).every(p=>[p.x,p.y,p.z,p.w,p.d,p.h].every(Number.isFinite)),starter.id)}
assert.deepEqual(s.sectionOrder.slice(0,2),['Materials','Machining']);
const stand=c.schemas[6].fields;
for(const k of ['equipment_mass_kg','slide_load_rating_kg','cleat_angle','cleat_safety_factor','tray_count'])assert.equal(u.isLengthField(stand.find(f=>f.key===k)),false,k);
for(const k of ['material_thickness','router_bit_diameter','tray_extension'])assert.equal(u.isLengthField(stand.find(f=>f.key===k)),true,k);
for(const f of c.schemas[0].fields.filter(f=>/target_module_pitch|_from_|label_size/.test(f.key)))assert.equal(u.isLengthField(f),true,f.key);
const divider=c.schemas[0].fields.find(f=>f.key==='custom_drawer_divider_thickness');assert(s.inactiveReason(divider,{include_drawer_divider_grid:false}));assert.equal(s.inactiveReason(divider,{include_drawer_divider_grid:true,drawer_divider_stock:'custom_mm'}),null);
assert.equal(c.schemas[4].starters.filter(s=>s.id.startsWith('kitchen_standard_')).length,48);
const src=c.applySettings(c.engineSources[c.schemas[6].file],6,{...c.defaults(6),material_thickness:18.35,cleat_angle:45});assert(src.includes('material_thickness = 18.35;'));assert(src.includes('cleat_angle = 45;'));
(async()=>{const bytes=await c.exportBundle(6,c.defaults(6));const text=await bytes.text();for(const name of ['v5/pyproject.toml','v5/src/modular_organization/data/scad/core/resolve.scad','v5/src/modular_organization/api.py'])assert(text.includes(name));console.log('V5: old designs, 109 presets, schematic finite geometry, units, visibility, decimal stock and complete nested source bundle passed')})();
