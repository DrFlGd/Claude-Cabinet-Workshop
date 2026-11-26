const fs=require('fs'),assert=require('assert/strict'),ts=require('typescript'),cp=require('child_process');
function load(name,deps={}){const m={exports:{}};new Function('require','module','exports',ts.transpileModule(fs.readFileSync('lib/'+name+'.ts','utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2022,esModuleInterop:true}}).outputText)(n=>deps[n],m,m.exports);return m.exports}
const c=load('cabinet',{'./workbench':load('workbench'),'./sections':load('sections'),'./schema.json':require('../lib/schema.json'),'./engine-sources.json':require('../lib/engine-sources.json')}),p=load('projects',{'./cabinet':c,'./sections':load('sections')}),m=load('manufacturing'),s=load('settings'),u=load('units');
const old=require('./fixtures/v3-schema.json');
for(let family=0;family<6;family++){
 const values=Object.fromEntries(old[family].fields.map(f=>[f.key,f.value]));const result=p.parseDesign({version:2,engine:3,engineFamily:'modular_organization',family,displayUnits:'in',values});
 assert.equal(result.engine,5);assert.equal(result.displayUnits,'in');
 for(const f of old[family].fields)if(c.schemas[family].fields.some(x=>x.key===f.key)&&!['cabinet_preset','cabinet_layout_mode','mixed_bay_count','mixed_bay_types','mixed_bay_width_weights','mixed_bay_drawer_counts','mixed_bay_shelf_counts','mixed_bay_door_counts','base_style','include_worktop'].includes(f.key))assert.deepEqual(result.values[f.key],f.value,family+' '+f.key);
}
for(let family=0;family<8;family++)for(const starter of c.schemas[family].starters){const v=c.starterValues(family,starter.id);p.parseDesign({version:2,engine:5,engineFamily:'modular_organization',family,values:v});assert.deepEqual(c.validate(v),[],starter.id);assert(c.geometry(v,false,false).every(p=>[p.x,p.y,p.z,p.w,p.d,p.h].every(Number.isFinite)),starter.id)}
assert.deepEqual(s.sectionOrder.slice(0,2),['Sizing','Structure']);assert(s.shopSections.every(x=>s.sectionOrder.includes(x)));
// Modular workbench: the app's size and layout checks agree with the engine's reference sizes.
{const w=load('workbench'),v=c.defaults(7);
 assert.deepEqual([v.custom_cabinet_width,v.custom_cabinet_height,v.custom_cabinet_depth],[1300,908,900]);
 assert.deepEqual(w.modules(v).map(m=>m.z),[160,160,160,160,160]);
 const stacked=c.starterValues(7,'workbench_stacked');assert.deepEqual(w.modules(stacked).slice(0,2).map(m=>[m.z,m.top]),[[160,525],[525,890]]);
 assert.deepEqual(c.validate({...v,modules:[[0,0,1,1,730,'door',1,'back','left'],[0,1,1,1,730,'door',1,'front','left']]}).length,2);
 assert.match(c.validate({...v,modules:[[2,0,2,1,730,'door',1,'front','left']]})[0],/does not fit the 3 × 2 grid/);
 assert.match(c.validate({...v,modules:[[0,0,1,1,730,'door',1,'front','left'],[0,0,2,1,730,'door',1,'front','left']]})[0],/not fully supported/);
 // Drawer modules: rows saved before drawers existed read as three drawers; fronts, boxes and checks.
 assert.equal(w.normalizeRow([0,0,1,1,730,'door',1,'front','left'])[9],3);
 const dr=c.starterValues(7,'workbench_drawers'),dm=w.modules(dr);
 assert.deepEqual(dm.map(m=>w.drawerCount(m)),[4,1,0,2,6,0,0,0]);assert.deepEqual(dm.slice(2,4).map(m=>[m.z,m.top]),[[160,525],[525,890]]);
 assert.equal(c.validate(dr).length,0);
 const ids=c.geometry(dr,false,false).map(p=>p.id);for(const id of ['M1-DRAWER-4-FACE','M1-DRAWER-4-BOX','M2-DOOR-1','M3-FACE','M5-DRAWER-6-HANDLE'])assert(ids.includes(id),id);
 assert.deepEqual(w.drawerBoxHeights(dm[0],dr).map(Math.round),[145,163,163,145]);
 assert.match(c.validate({...v,modules:[[0,0,1,1,365,'drawers',0,'front','left',8]]})[0],/too low for 8 drawers/);
 assert.match(c.validate({...v,modules:[[0,0,1,1,730,'drawers',0,'back','left',3],[0,1,1,1,730,'open',1,'back','left']]})[0],/drawers open into M2/);
 assert.match(c.validate({...v,modules:[[0,0,1,1,365,'drawer_door',0,'front','left',2]]})[0],/no room for a door/);
 const field=k=>c.schemas[7].fields.find(f=>f.key===k);
 assert(s.inactiveReason(field('combo_drawer_height'),v));assert.equal(s.inactiveReason(field('combo_drawer_height'),dr),null);
 assert(s.inactiveReason(field('metal_slide_length'),v));assert.equal(s.inactiveReason(field('metal_slide_length'),dr),null);
 assert(s.inactiveReason(field('include_stack_keys'),v));assert.equal(s.inactiveReason(field('include_stack_keys'),stacked),null);
 assert(s.inactiveReason(field('face_opening_border'),v));assert.equal(s.inactiveReason(field('face_opening_border'),dr),null);
 assert(s.inactiveReason(field('grid_columns'),v));assert.equal(s.inactiveReason(field('grid_columns'),{...v,frame_size:'custom'}),null);
 assert(s.inactiveReason(field('hand_slot_length'),{...v,include_hand_slots:false}));assert(s.inactiveReason(field('handle_edge_offset'),{...v,handle_style:'none'}));
 assert.equal(s.inactiveReason(field('joint_fit_clearance'),v),null);assert.equal(s.inactiveReason(field('hinge_cup_diameter'),v),null);
 // Drilling jig and screw-mark detail controls follow their switches.
 assert.equal(s.inactiveReason(field('include_handle_jig'),v),null);assert.match(s.inactiveReason(field('jig_thickness'),v),/Enable the handle jig/);
 assert.equal(s.inactiveReason(field('jig_thickness'),{...v,include_handle_jig:true}),null);assert.match(s.inactiveReason(field('include_handle_jig'),{...v,handle_style:'none'}),/handle style/);
 assert.equal(s.inactiveReason(field('screw_mark_depth'),v),null);assert.match(s.inactiveReason(field('frame_screw_offset'),{...v,include_screw_marks:false}),/Enable screw marks/);
 assert.equal(field('jig_thickness').unit,'mm');assert(c.schemas[7].fields.find(f=>f.key==='output_mode').options.includes('pocket_screw_marks'));
 assert.equal(u.isLengthField(field('modules')),false);assert.equal(u.isLengthField(field('grid_columns')),false);assert.equal(u.isLengthField(field('cell_size')),true);}
const stand=c.schemas[6].fields;
for(const k of ['equipment_mass_kg','slide_load_rating_kg','cleat_angle','cleat_safety_factor','tray_count'])assert.equal(u.isLengthField(stand.find(f=>f.key===k)),false,k);
for(const k of ['material_thickness','router_bit_diameter','tray_extension'])assert.equal(u.isLengthField(stand.find(f=>f.key===k)),true,k);
for(const f of c.schemas[0].fields.filter(f=>/target_module_pitch|_from_|label_size/.test(f.key)))assert.equal(u.isLengthField(f),true,f.key);
const divider=c.schemas[0].fields.find(f=>f.key==='custom_drawer_divider_thickness');assert(s.inactiveReason(divider,{include_drawer_divider_grid:false}));assert.equal(s.inactiveReason(divider,{include_drawer_divider_grid:true,drawer_divider_stock:'custom_mm'}),null);
assert.equal(c.schemas[4].starters.filter(s=>s.id.startsWith('kitchen_standard_')).length,48);
const src=c.applySettings(c.engineSources[c.schemas[6].file],6,{...c.defaults(6),material_thickness:18.35,cleat_angle:45});assert(src.includes('material_thickness = 18.35;'));assert(src.includes('cleat_angle = 45;'));
(async()=>{const bytes=await c.exportBundle(6,c.defaults(6));const text=await bytes.text();for(const name of ['v5/pyproject.toml','v5/src/modular_organization/data/scad/core/resolve.scad','v5/src/modular_organization/api.py'])assert(text.includes(name));console.log('V5: old designs, 120 presets, schematic finite geometry, workbench layout checks, units, visibility, decimal stock and complete nested source bundle passed')})();
