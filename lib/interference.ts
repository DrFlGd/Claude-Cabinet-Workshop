// Collision check jobs: a design split into parts or groups of parts, each one the design's
// engine source set to draw only that part or group in assembly position. The interference
// worker (public/openscad/interference-worker.js) renders every job on its own, compares their
// extents and intersects the pairs that meet. Correctly fitted parts only touch; any shared
// volume means two parts would occupy the same space.
//
// The same jobs drive the test sweeps (tests/engine-interference.mjs and
// tests/product-interference.mjs), so the app checks a design the way the suite does.
export type CollisionJob={name:string;source:string};
type Values=Record<string,unknown>;
type Field={key:string};
// What the job builders need to know about a cabinet type.
export type CabinetEngine={id:string;fields:Field[];configure:(values:Values)=>string};

// Replace one top-level assignment (`key = value;`) of an OpenSCAD source.
export const setAssignment=(source:string,key:string,value:unknown)=>source.replace(new RegExp('^('+key+'\\s*=\\s*)[^;]+;','m'),(_m,p)=>p+JSON.stringify(value)+';');

// ---- cabinets (engine v5) ----
export const SHOW_FLAGS=['show_carcass_sides','show_carcass_bottom','show_carcass_top','show_toe_kick','show_base_hardware','show_worktop','show_back_construction','show_combo_divider','show_shelves','show_door_hinge_partitions','show_drawer_separators','show_drawer_bank_partitions','show_mixed_bay_partitions','show_drawer_slide_parts','show_stack_base'];
export type Group={on?:string[];code:string;envelopes?:boolean;when?:(v:Values)=>boolean};
const drawers=(parity:number)=>`if (has_drawers) for (b=[0:active_drawer_bank_count()-1]) if (drawer_bank_drawer_count(b) > 0) for (i=[0:drawer_bank_drawer_count(b)-1]) if ((i+b)%2==${parity}) { drawer_box(i,b); if (show_drawer_slide_parts) drawer_mounted_wood_slides(i,b); }`;
export const CABINET_GROUPS:Record<string,Group>={
 sides:{on:['show_carcass_sides'],code:'carcass();'},
 caps:{on:['show_carcass_bottom','show_carcass_top','show_toe_kick'],code:'carcass();'},
 back:{on:['show_back_construction'],code:'carcass();'},
 shelves:{on:['show_shelves'],code:'carcass();'},
 // Horizontal and vertical interior members are separate groups so partition tabs and
 // tongues are checked against the divider and separators that receive them.
 horizontals:{on:['show_combo_divider','show_drawer_separators'],code:'carcass();'},
 verticals:{on:['show_door_hinge_partitions','show_drawer_bank_partitions','show_mixed_bay_partitions'],code:'carcass();'},
 rails:{on:['show_drawer_slide_parts'],code:'carcass();'},
 frame:{on:[],code:'face_frame_assembly_3d();'},
 drawersA:{on:['show_drawer_slide_parts'],code:drawers(0)},
 drawersB:{on:['show_drawer_slide_parts'],code:drawers(1)},
 doors:{on:[],code:'doors();'},
 // Hardware and accessories.
 worktop:{on:['show_worktop'],code:'carcass();'},
 base:{on:['show_base_hardware'],code:'carcass();'},
 // The stack base sits below the module (in module coordinates, at -stack_first_module_z),
 // and a second module sits one stacking pitch above it: the stacking interface, the
 // nested bottom and the fronts must clear the module below.
 // Its sides and its rails/kick board are separate groups, so their joints are checked too.
 stackBaseSides:{on:['show_stack_base'],code:'if (stackable_mode) translate([0,0,-stack_first_module_z]) stack_base_sides_3d();'},
 stackBaseMembers:{on:['show_stack_base'],code:'if (stackable_mode) translate([0,0,-stack_first_module_z]) stack_base_members_3d();'},
 stackUpper:{on:SHOW_FLAGS.filter(k=>k!=='show_stack_base'),code:'if (stackable_mode) translate([0,0,stack_module_pitch]) cabinet_unit_assembly();'},
 // The slide envelope is the space a metal slide needs between the drawer box and the
 // cabinet side or partition; nothing else may enter it.
 slideEnvelopes:{on:['show_drawer_slide_parts'],envelopes:true,code:'carcass();',when:v=>v.drawer_mount==='metal_slides'},
};
// The standalone drawer renders drawer boxes only.
const DRAWER_GROUPS:Record<string,Group>={drawersA:CABINET_GROUPS.drawersA,drawersB:CABINET_GROUPS.drawersB};
// The equipment stand has its own engine; its parts are grouped by kind from its part table.
const standGroup=(kinds:string[]):Group=>({code:`for(p=parts) if(${kinds.map(k=>`p[1]=="${k}"`).join('||')}) if(p[1]=="runner") translate([0,0,tz(p[5])-runner_height]) assemble_part(p); else assemble_part(p);`});
const STAND_GROUPS:Record<string,Group>={
 sides:standGroup(['side']),horizontals:standGroup(['horizontal']),trays:standGroup(['tray','lip']),cheeks:standGroup(['cheek']),
 backs:standGroup(['back','structural','applied']),runners:standGroup(['runner']),cleats:standGroup(['cleat_stand','cleat_wall']),backers:standGroup(['backer','spacer','shim']),
 slides:{code:'if(slide_type=="side_mount") for(i=[0:N-1]) for(s=[0:1]) { translate([s==0 ? t : W-t-sg,tray_inset+metal_slide_front_setback,slide_z(i)-metal_slide_envelope_height/2]) cube([sg/2,metal_slide_length,metal_slide_envelope_height]); translate([s==0 ? t+sg/2 : W-t-sg/2,tray_inset+metal_slide_front_setback-ext,slide_z(i)-metal_slide_envelope_height/2]) cube([sg/2,metal_slide_length,metal_slide_envelope_height]); }'},
};
// Interior members of bay and section layouts, from the engine's LAYOUT report.
export function layoutMembers(report:string){
 const ids=(re:RegExp)=>[...new Set([...report.matchAll(re)].map(m=>+m[1]-1))];
 return {vm:ids(/LAYOUT\|MEMBER\|MB(\d+)/g),hm:ids(/LAYOUT\|MEMBER\|SD(\d+)/g),fs:ids(/LAYOUT\|SHELF\|B(\d+)-SH\d+\|[^"\n]*STYLE=fixed/g)};
}
// The groups of a cabinet design. report: its bom-mode engine report (BOM and LAYOUT
// records). split: each partition, section divider and bay's fixed shelves on its own, so
// members that meet from opposite faces of another member are checked against each other;
// 'auto' splits whenever the design has such members.
export function cabinetGroups(engine:CabinetEngine,report:string,split:boolean|'auto'='auto'):Record<string,Group>{
 if(engine.id==='equipment_stand')return {...STAND_GROUPS};
 if(engine.id==='drawer')return {...DRAWER_GROUPS};
 if(engine.id==='workbench'){
  // Every part of the workbench's part table on its own, plus the casters.
  const ids=[...new Set([...report.matchAll(/BOM\|([^|"\n]+)\|/g)].map(m=>m[1]))];
  return {...Object.fromEntries(ids.map(id=>[id,{code:`render_ids([${JSON.stringify(id)}]);`}])),casters:{code:'casters();'}};
 }
 const groups={...CABINET_GROUPS},m=layoutMembers(report);
 if(split===true||split==='auto'&&m.vm.length+m.hm.length+m.fs.length>0){
  groups.verticals={on:['show_door_hinge_partitions','show_drawer_bank_partitions'],code:'carcass();'};
  groups.horizontals={on:['show_drawer_separators'],code:'carcass();'};
  groups.shelves={on:[],code:'for (b=[0:layout_bay_count-1]) if (mixed_bay_has_adjustable_shelves(b)) for (s=[1:mixed_bay_shelf_count(b)]) mixed_bay_adjustable_shelf_3d(b,mixed_bay_shelf_z(b,s));'};
  for(const p of m.vm)groups['partition'+(p+1)]={on:[],code:`mixed_bay_partition_3d(${p});`};
  for(const h of m.hm)groups['divider'+(h+1)]={on:[],code:`section_divider_3d(${h});`};
  for(const b of m.fs)groups['fixedShelves'+(b+1)]={on:[],code:`for (s=[1:mixed_bay_shelf_count(${b})]) mixed_bay_fixed_shelf_3d(${b},mixed_bay_shelf_z(${b},s),s);`};
 }
 return groups;
}
// One job per group: the design with only that group's parts switched on, drawn by the
// group's code after a probe output mode that draws nothing of its own. The equipment stand
// draws its flat layout for any mode but bom, so bom is its probe.
export function cabinetJobs(engine:CabinetEngine,values:Values,report:string,split:boolean|'auto'='auto'):CollisionJob[]{
 const keys=new Set(engine.fields.map(f=>f.key));
 return Object.entries(cabinetGroups(engine,report,split)).filter(([,g])=>!g.when||g.when(values)).map(([name,g])=>{
  const v:Values={...values,output_mode:engine.id==='equipment_stand'?'bom':'__probe__',show_metal_slide_envelopes:!!g.envelopes};
  for(const k of SHOW_FLAGS)if(keys.has(k))v[k]=(g.on??[]).includes(k);
  return {name,source:engine.configure(v)+'\n'+g.code+'\n'};
 });
}
// Pairs that may legitimately share volume in a cabinet check: none. Shared volume is reported
// above this many mm³ (0.05 cm³), which absorbs mesh round-off on curved hardware.
export const CABINET_THRESHOLD=50;

// ---- products ----
// One job per part: the product's assembly with only that part drawn (render_part, under
// Hidden in the product's SCAD file), plus its casters when it has them. report: the
// bom-mode engine report, whose BOM records list the parts.
export function productJobs(source:string,report:string,casters=false):CollisionJob[]{
 const ids=[...new Set([...report.matchAll(/BOM\|([^|"\n]+)\|/g)].map(m=>m[1]))];
 const assembly=setAssignment(source,'output_mode','assembly');
 return [...ids,...(casters?['CASTERS']:[])].map(id=>({name:id,source:setAssignment(assembly,'render_part',id)}));
}
export const PRODUCT_THRESHOLD=1;
