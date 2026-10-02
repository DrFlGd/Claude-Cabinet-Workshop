const fs=require('fs'),assert=require('assert/strict'),ts=require('typescript');
const m={exports:{}};new Function('module','exports',ts.transpileModule(fs.readFileSync('lib/settings.ts','utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2022}}).outputText)(m,m.exports);
const {inactiveReason}=m.exports,schema=require('../lib/schema.json');
function check(key,hidden,patch={},family=0){const s=schema[family],f=s.fields.find(x=>x.key===key);assert(f,key);const v={...Object.fromEntries(s.fields.map(x=>[x.key,x.value])),_family:family,cabinet_layout_mode:'legacy',cabinet_contents:'drawers',...patch};assert.equal(!!inactiveReason(f,v),hidden,key+' '+JSON.stringify(patch))}
for(const key of ['tab_count_mode','joint_tab_count','target_tab_spacing','joint_tab_width','bottom_tab_custom_centers'])check(key,true,{joinery_style:'butt',bottom_tab_placement:'custom'});
check('tab_count_mode',false,{joinery_style:'tab_slot'});check('joint_tab_count',false,{joinery_style:'tab_slot',tab_count_mode:'fixed'});check('joint_tab_count',true,{joinery_style:'tab_slot',tab_count_mode:'adaptive'});check('target_tab_spacing',false,{joinery_style:'tab_slot',tab_count_mode:'adaptive'});
// Layout settings (bays, counts, drawer heights, drawer/door split) belong to the Layout tab
// for the five cabinet types that have the layout editor; they are hidden from the settings list.
for(let family=0;family<5;family++)for(const f of schema[family].fields.filter(f=>m.exports.LAYOUT_KEYS.has(f.key)))assert.equal(inactiveReason(f,{...Object.fromEntries(schema[family].fields.map(x=>[x.key,x.value])),_family:family}),m.exports.LAYOUT_REASON,family+' '+f.key);
for(const key of ['drawer_height_weights','drawer_graduated_step','mixed_bay_drawer_graduated_steps','mixed_bay_count','cabinet_contents','combo_door_height'])assert(m.exports.LAYOUT_KEYS.has(key),key);
for(const key of ['drawer_gap','door_width_weights','include_drawer_separators','mixed_bay_front_gap'])assert(!m.exports.LAYOUT_KEYS.has(key),key);
for(const key of ['metal_slide_length','include_metal_slide_holes','metal_slide_cabinet_holes_x'])check(key,true,{drawer_mount:'wood_rails',metal_slide_hole_pattern_mode:'explicit_array'});
check('metal_slide_length',false,{drawer_mount:'metal_slides'});check('metal_slide_hole_count',true,{drawer_mount:'metal_slides',include_metal_slide_holes:false});check('metal_slide_hole_count',false,{drawer_mount:'metal_slides',include_metal_slide_holes:true,metal_slide_hole_pattern_mode:'legacy_spacing'});
check('wood_rail_thickness',true,{drawer_mount:'none'});check('wood_rail_thickness',false,{drawer_mount:'wood_rails'});check('drawer_mount',true,{cabinet_contents:'doors'});
check('hinge_cup_depth',true,{cabinet_contents:'doors',hinge_style:'none'});check('hinge_cup_depth',false,{cabinet_contents:'doors',hinge_style:'euro_35mm'});
check('drawer_screw_hole_diameter',false,{drawer_joinery_style:'screw'});check('drawer_screw_hole_diameter',true,{drawer_joinery_style:'dado'});
check('drawer_bottom_dado_depth',false,{drawer_bottom_joinery:'dado'});check('kerf',true,{apply_kerf_compensation:false});
check('metal_slide_length',true,{slide_type:'fixed_runner'},6);check('metal_slide_length',false,{slide_type:'side_mount'},6);
const picker=fs.readFileSync('app/HardwarePicker.tsx','utf8');assert(!picker.includes('hardware-category'));assert(picker.includes("['drawer_slide','hinge']"));
const page=fs.readFileSync('app/page.tsx','utf8');assert(page.includes('<SettingHelp'));assert(!page.includes("<p className='field-note'>{f.description}"));
console.log('Conditional controls: joinery, drawer modes, hardware, nested drilling and presets/help regressions passed.');

for(let family=0;family<schema.length;family++){
 const values=Object.fromEntries(schema[family].fields.map(f=>[f.key,f.value]));
 for(const f of schema[family].fields.filter(f=>/^(tab_count_mode|joint_tab_|target_tab_spacing|max_auto_tab_count)/.test(f.key))){
  for(const joinery of ['butt','screw','dado'])assert(inactiveReason(f,{...values,_family:family,joinery_style:joinery}),family+' '+f.key);
 }
}
check('inset_front_back_clearance',true,{front_mount_style:'overlay'});
check('inset_front_back_clearance',false,{front_mount_style:'inset_flush'});
check('drawer_bank_partition_joinery',true,{drawer_bank_count:1});
check('drawer_bank_partition_joinery',false,{drawer_bank_count:2});
check('drawer_dado_depth',true,{cabinet_contents:'doors',drawer_joinery_style:'dado'});
check('drawer_dado_depth',false,{cabinet_contents:'drawers',drawer_joinery_style:'dado'});
assert(!page.includes('showInactive'));
assert(page.includes('!inactiveReason(f,values)'));
console.log('All-family tab gates and unconditional dependency filtering passed.');
for(const [key,patch,hidden] of [
 ['carcass_slot_corner_relief',{joinery_style:'butt'},true],
 ['carcass_slot_corner_relief',{joinery_style:'tab_slot'},false],
 ['drawer_cnc_tool_diameter',{drawer_joinery_style:'tab_slot',drawer_slot_corner_relief:'none'},true],
 ['drawer_cnc_tool_diameter',{drawer_joinery_style:'tab_slot',drawer_slot_corner_relief:'dogbone'},false],
 ['drawer_bottom_slot_corner_relief',{include_drawer_divider_grid:false},true],
 ['drawer_bottom_slot_corner_relief',{include_drawer_divider_grid:true,drawer_divider_mounting:'bottom_and_perimeter'},false],
 ['joint_fit_clearance',{joinery_style:'dado'},true],
 ['drawer_dado_fit_clearance',{drawer_joinery_style:'butt',drawer_bottom_joinery:'dado'},false],
])check(key,hidden,patch);
const presented=m.exports.presentFields(schema[4].fields);
assert(!presented.some(f=>f.section.startsWith('Fronts /')));
assert.deepEqual(presented.filter(f=>f.key==='front_mount_style').map(f=>f.section),['Doors / Shared Fronts','Drawers / Shared Fronts']);
assert.equal(m.exports.settingsGroup(presented.find(f=>f.key==='drawer_bottom_cnc_tool_diameter')),'Machining / Drawer bottoms');
console.log('Material controls, clearance dependencies and shared front grouping passed.');
for(const family of schema){
 const fields=m.exports.presentFields(family.fields);
 for(const f of fields){
  if(['cabinet_mount_style','mount_mode'].includes(f.key))assert.equal(f.section,'Mounting / Mount Style');
  if(f.key==='back_style'||f.key.startsWith('back_stretcher_'))assert.equal(f.section,'Mounting / Rear Mounting');
 }
}
check('custom_side_toe_kick_cutout',false,{cabinet_mount_style:'floor',base_style:'toe_kick'},4);
check('custom_side_toe_kick_cutout',true,{cabinet_mount_style:'wall',base_style:'toe_kick'},4);
check('custom_side_toe_kick_cutout',true,{cabinet_mount_style:'floor',base_style:'flat'},4);
console.log('Mounting groups and kitchen toe-kick controls passed.');
const sectionValues={cabinet_layout_mode:'sections',section_nodes:[[-1,0,'leaf','weight',1,'drawers',3,'equal',.25,[1,1,1],'panel',0]]};
for(const key of ['section_nodes','drawer_count','drawer_height_mode','mixed_bay_count','include_face_frame_center_stile'])check(key,true,sectionValues,4);
console.log('Section-controlled layout fields are hidden.');
