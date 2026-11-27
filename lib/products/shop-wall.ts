// Shop wall: French-cleat and wall-mounted shop organizers (shelves, door and drawer
// cabinets, tool racks, drill stations, boxes and holders) as one Cabinet Workshop product.
// One SCAD engine (public/products/shop_wall/shop_wall.scad) builds every module on the
// shared core: the tab planner and slot reliefs (joinery.scad, tab_pocket.scad,
// seam_joinery.scad), cleats and CNC side hooks (cleat.scad, wall_mount.scad) and the
// cut-layout placement table (placement.scad). This module adds the editor's labels and
// grouping, one starter per module with its starting sizes, quick checks and the summary.
import type {Values} from '../cabinet';
import {formatShop,type Units} from '../units';
import type {Product,ProductControl,ProductStarter} from './types';
import {scadParams} from './scad-params';
import sources from './product-sources.json';

export const SHOP_WALL_FILE='products/shop_wall/shop_wall.scad';
const source=(sources as Record<string,string>)[SHOP_WALL_FILE];
const params=scadParams(source);
const param=(k:string)=>params.find(p=>p.key===k);

const NOMINAL:Record<string,number>={'1/8_nominal':3.175,'1/4_nominal':6.35,'3/8_nominal':9.525,'1/2_nominal':12.7,'5/8_nominal':15.875,'3/4_nominal':19.05,'1_nominal':25.4};
const nominalLabel=(k:string)=>k.replace('_nominal','″ nominal')+` (${NOMINAL[k]} mm)`;
const stockLabels:Record<string,string>={custom_mm:'Measured thickness (enter mm)',...Object.fromEntries(Object.keys(NOMINAL).map(k=>[k,nominalLabel(k)]))};
const cleatLabels:Record<string,string>={match_carcass:'Same as carcass',custom_mm:'Measured thickness (enter mm)',...Object.fromEntries(['1/2_nominal','5/8_nominal','3/4_nominal','1_nominal'].map(k=>[k,nominalLabel(k)]))};
// Role stocks: the options each role's SCAD setting lists, labeled.
const roleLabels=(key:string):Record<string,string>=>Object.fromEntries((params.find(p=>p.key===key)?.options??[]).map(o=>[o,o==='by_mount'?'By mount (½″ on side hooks or free standing, carcass on screws)':o==='match_carcass'?'Same as carcass':stockLabels[o]??o]));

// Modules, grouped as the picker shows them, with the family the engine builds them as.
type Module={id:string;name:string;family:string;group:string;description:string};
const M=(id:string,name:string,family:string,group:string,description:string):Module=>({id,name,family,group,description});
export const SHOP_WALL_MODULES:Module[]=[
 M('simple_shelves','Simple shelves','display','Shelves and displays','One open shelf between sloped side brackets'),
 M('jar_shelves','Jar shelves','display','Shelves and displays','Narrow tower of lipped shelves for jars'),
 M('spray_paint_display','Spray paint display','display','Shelves and displays','Lipped shelf for a row of cans'),
 M('single_cube_shelf','Single cube shelf','cubby','Shelves and displays','One open cube'),
 M('double_cube_shelf','Double cube shelf','cubby','Shelves and displays','Two cubes side by side with a divider'),
 M('narrow_shelves','Narrow shelves','cubby','Shelves and displays','Tall narrow box with fixed shelves'),
 M('sandpaper_shelf','Sandpaper shelf','cubby','Shelves and displays','Narrow box with many shallow shelves for sheets'),
 M('single_door_cabinet','Single door cabinet','doors','Cabinets','Inset door with a pull and a finger bore'),
 M('double_door_cabinet','Double door cabinet','doors','Cabinets','Two inset doors'),
 M('sliding_door_cabinet','Sliding door cabinet','doors','Cabinets','Two bypass leaves in top and bottom guide channels'),
 M('three_drawer_cabinet','3-drawer cabinet','drawers','Cabinets','Three drawer boxes on wood dividers'),
 M('four_drawer_cabinet','4-drawer cabinet','drawers','Cabinets','Four drawer boxes on wood dividers'),
 M('chisel_rack','Chisel rack','rack','Tool racks','Deck with open slots for chisels'),
 M('clamp_rack','Clamp rack','rack','Tool racks','Deep deck with open slots for bar clamps'),
 M('hammer_rack','Hammer rack','rack','Tool racks','Deck with round holes for hammer handles'),
 M('screwdriver_rack','Screwdriver rack','rack','Tool racks','Deck with one or two staggered rows of shaft holes'),
 M('plier_stand','Plier stand','stand','Tool racks','Closed stand with slots for plier handles'),
 M('router_bit_stand','Router bit stand','stand','Tool racks','Closed stand with rows of shank holes'),
 M('circular_saw_stand','Circular saw stand','rack','Tool racks','Deck with a slot for the saw guard'),
 M('simple_drill_station','Simple drill station','drill_simple','Drill stations','Slotted cradle on two gussets for one drill'),
 M('double_drill_station','Double drill station','drill_simple','Drill stations','Slotted cradle for two drills'),
 M('single_shelf_drill_stand','Single shelf drill stand','drill_cabinet','Drill stations','Drill cradle under a top shelf'),
 M('double_shelf_drill_stand','Double shelf drill stand','drill_cabinet','Drill stations','Drill cradle under two compartments'),
 M('closed_lid_box','Closed lid box','box','Boxes and bins','Divided box with a hinged lid'),
 M('screw_box','Screw box','box','Boxes and bins','Open divided bins with a low front'),
 M('shallow_storage_box','Shallow storage box','box','Boxes and bins','One open bin with a low front'),
 M('glove_box','Glove box','glove','Boxes and bins','Closed box with a pull-out slot in the front'),
 M('hook_panel','Hook panel','hooks','Holders','Back board with shaped hooks'),
 M('material_storage_stand','Material storage stand','brackets','Holders','Lipped deck on brackets for offcuts and stock'),
 M('paper_towel_holder','Paper towel holder','towel','Holders','Two cheeks and a dowel'),
 M('wrench_holder','Wrench holder','wrench','Holders','Two cheeks with sloped wrench slots'),
 M('fit_coupon','Fit test coupon','coupon','Fit test','One tab in its slot and a short hook or hanger on a short rail, to cut before a module'),
];
export const shopWallModule=(id:unknown)=>SHOP_WALL_MODULES.find(m=>m.id===id)??SHOP_WALL_MODULES[0];

// Starting sizes and settings of each module (the original Customizer presets, in mm).
const inch=(x:number)=>Math.round(x*25.4*1000)/1000;
const size=(w:number,d:number,h:number)=>({width:inch(w),depth:inch(d),height:inch(h)});
const PRESETS:Record<string,Values>={
 simple_shelves:{...size(20,7,6),display_shelves:1},
 jar_shelves:{...size(8,5,20),display_shelves:4,lip_height:inch(0.75)},
 spray_paint_display:{...size(19,5.5,8),display_shelves:1,lip_height:inch(0.75)},
 single_cube_shelf:{...size(12,10,12),bay_count:1},
 double_cube_shelf:{...size(24,10,12),bay_count:2},
 narrow_shelves:{...size(7,6,18),interior_shelves:2},
 sandpaper_shelf:{...size(7,7,18),interior_shelves:7},
 single_door_cabinet:{...size(12,9,14),interior_shelves:1},
 double_door_cabinet:{...size(24,11,18),interior_shelves:1},
 sliding_door_cabinet:{...size(24,12,17),interior_shelves:1},
 three_drawer_cabinet:{...size(15,12,14),drawer_count:3},
 four_drawer_cabinet:{...size(15,12,18),drawer_count:4},
 chisel_rack:{...size(16,3.5,5),tool_count:5,tool_width:inch(0.85)},
 clamp_rack:{...size(16,8,6),tool_count:5,tool_width:inch(0.7)},
 hammer_rack:{...size(14,4.5,5),tool_count:4,tool_width:inch(1.2)},
 screwdriver_rack:{...size(16,4,5),tool_count:7,tool_width:10,second_row:true},
 plier_stand:{...size(16,5,7),tool_count:5,tool_width:inch(0.68)},
 router_bit_stand:{...size(16,4,5),tool_count:8,tool_rows:2,tool_width:inch(0.25),bit_fit_allowance:inch(0.025)},
 circular_saw_stand:{...size(13,13,9),saw_guard_width:inch(2.25),saw_guard_offset:inch(2.5)},
 simple_drill_station:{...size(6,8,5),tool_count:1,tool_width:inch(1.65)},
 double_drill_station:{...size(10,8,5),tool_count:2,tool_width:inch(1.65)},
 single_shelf_drill_stand:{...size(15,9,9),tool_count:3,tool_width:inch(1.65),upper_shelf_count:1},
 double_shelf_drill_stand:{...size(22,10,15),tool_count:4,tool_width:inch(1.65),upper_shelf_count:2},
 closed_lid_box:{...size(17,10,8),box_columns:3,box_rows:2},
 screw_box:{...size(16,9,5),box_columns:3,box_rows:2,front_height_fraction:0.52},
 shallow_storage_box:{...size(13,8,5),front_height_fraction:0.52},
 glove_box:{...size(12,5.5,7)},
 hook_panel:{...size(19,3.5,6),hook_count:5},
 material_storage_stand:{...size(30,10,10),bracket_count:2,lip_height:inch(0.75)},
 paper_towel_holder:{...size(14,8,7),dowel_diameter:inch(0.875),rod_clearance:inch(0.03)},
 wrench_holder:{...size(7,5.5,17),wrench_levels:8,tool_width:inch(0.4),wrench_rise:inch(0.38)},
 fit_coupon:{...size(8,4,6)},
};
// Settings that belong to one module: reset to the engine defaults when the module changes.
const MODULE_KEYS=['width','depth','height','interior_shelves','bay_count','drawer_count','display_shelves','lip_height','upper_shelf_count','tool_count','tool_width','slot_length','tool_pitch','tool_rows','bit_fit_allowance','second_row','box_columns','box_rows','front_height_fraction','aperture_height','aperture_length','hook_count','bracket_count','dowel_diameter','rod_clearance','wrench_levels','wrench_rise','saw_guard_width','saw_guard_offset'];
const moduleValues=(id:string):Values=>({...Object.fromEntries(MODULE_KEYS.map(k=>[k,param(k)?.value])),module_type:id,...PRESETS[id]});

// Part roles with their own stock, the modules that have them, and their labels.
type Role='back'|'drawer_box'|'drawer_front'|'drawer_bottom'|'door'|'sliding_door'|'divider'|'trim';
const DRAWERS=['three_drawer_cabinet','four_drawer_cabinet'];
const ROLES:{role:Role;key:string;custom:string;label:string;short:string;help:string;modules?:string[]}[]=[
 {role:'back',key:'back_stock',custom:'custom_back_thickness',label:'Back stock',short:'back',help:'By mount: ½″ (or the carcass, if thinner) where the CNC side hooks carry the module or it stands free; the carcass where it hangs on screws through the back (beveled hanger, screws through the back, hook panel).'},
 {role:'drawer_box',key:'drawer_box_stock',custom:'custom_drawer_box_thickness',label:'Drawer box stock',short:'drawer boxes',help:'Drawer sides and backs.',modules:DRAWERS},
 {role:'drawer_front',key:'drawer_front_stock',custom:'custom_drawer_front_thickness',label:'Drawer front stock',short:'drawer fronts',help:'One-piece fronts, flush with the carcass, with the finger pull; the sides tab into them.',modules:DRAWERS},
 {role:'drawer_bottom',key:'drawer_bottom_stock',custom:'custom_drawer_bottom_thickness',label:'Drawer bottom stock',short:'drawer bottoms',help:'The drawer walls stand on the bottom with their tabs in its slots, glued: a bottom under twice the screw hole takes no screws.',modules:DRAWERS},
 {role:'door',key:'door_stock',custom:'custom_door_thickness',label:'Door and lid stock',short:'doors and lids',help:'Inset hinged doors and the box lid.',modules:['single_door_cabinet','double_door_cabinet','closed_lid_box']},
 {role:'sliding_door',key:'sliding_door_stock',custom:'custom_sliding_door_thickness',label:'Sliding door stock',short:'sliding leaves',help:'The guide channels are the leaf thickness plus the gap each side.',modules:['sliding_door_cabinet']},
 {role:'divider',key:'divider_stock',custom:'custom_divider_thickness',label:'Bin divider stock',short:'bin dividers',help:'Long and cross dividers of divided boxes.',modules:['closed_lid_box','screw_box']},
 {role:'trim',key:'trim_stock',custom:'custom_trim_thickness',label:'Lip and guide strip stock',short:'lips and strips',help:'Retaining lips on display shelves and the material stand, and the sliding-door guide strips.',modules:['jar_shelves','spray_paint_display','material_storage_stand','sliding_door_cabinet']},
];
const roleUsed=(r:typeof ROLES[number])=>(v:Values)=>v.module_type==='fit_coupon'?'The fit coupon tests the stocks of the module it is cut for':r.modules&&!r.modules.includes(String(v.module_type))?'Not used by the '+shopWallModule(v.module_type).name.toLowerCase():null;

// Resolved construction, mirroring the SCAD file.
export function wallModel(v:Values){
 const n=(k:string,d=0)=>{const x=Number(v[k]);return Number.isFinite(x)?x:d};
 const stock=(key:string,measured:number)=>v[key]==='custom_mm'?measured:NOMINAL[String(v[key])]??-1;
 const mod=shopWallModule(v.module_type),family=mod.family,coupon=family==='coupon';
 const t=stock('carcass_stock',n('material_thickness',18));
 const ct=v.cleat_stock==='match_carcass'?t:stock('cleat_stock',n('custom_cleat_thickness',19.05));
 const W=n('width'),D=n('depth'),H=n('height'),ch=n('cleat_height',63.5),angle=n('bevel_angle',45);
 const cleat=v.mount==='french_cleat'||coupon,cnc=cleat&&v.cleat_strategy==='cnc_hooks'&&family!=='hooks';
 // Stock of each part role, as the SCAD file resolves it (docs/SHOP_WALL.md).
 const role=(key:string,measured:string,d:number)=>v[key]==='match_carcass'?t:stock(key,n(measured,d));
 const backCarries=(cleat&&!cnc)||v.mount==='direct_screws'||family==='hooks';
 const bt=v.back_stock==='by_mount'?(backCarries?t:Math.min(t,12.7)):role('back_stock','custom_back_thickness',12);
 const roles:Record<Role,number>={back:bt,drawer_box:role('drawer_box_stock','custom_drawer_box_thickness',12),drawer_front:role('drawer_front_stock','custom_drawer_front_thickness',18),
  drawer_bottom:role('drawer_bottom_stock','custom_drawer_bottom_thickness',6),door:role('door_stock','custom_door_thickness',12),sliding_door:role('sliding_door_stock','custom_sliding_door_thickness',6),
  divider:role('divider_stock','custom_divider_thickness',12),trim:role('trim_stock','custom_trim_thickness',12)};
 const rise=ct*Math.tan(angle*Math.PI/180),gap=n('cleat_vertical_gap');
 return {mod,family,coupon,t,ct,W,D,H,ch,angle,cleat,cnc,beveled:cleat&&!cnc,rise,railZ:H-2*ch+rise-gap,wallDepth:D+(cleat?ct:0),
  I:W-2*t,F:D-bt,bt,roles,tool:n('cnc_tool_diameter',6.35),fit:n('joint_fit_clearance',0.3)};
}

const family=(...f:string[])=>(v:Values)=>f.includes(wallModel(v).family)?null:'Not used by the '+wallModel(v).mod.name.toLowerCase();
const modules=(...ids:string[])=>(v:Values)=>ids.includes(String(v.module_type))?null:'Not used by the '+wallModel(v).mod.name.toLowerCase();
const both=(...f:((v:Values)=>string|null)[])=>(v:Values)=>{for(const x of f){const r=x(v);if(r)return r}return null};
const cleatOnly=(v:Values)=>wallModel(v).cleat?null:'Used with a French cleat mount';
const cncOnly=(v:Values)=>{const m=wallModel(v);return !m.cleat?'Used with a French cleat mount':m.family==='hooks'?'Hook panels have no side panels to cut hooks into':m.cnc?null:'Used with CNC side hooks'};
const beveledOnly=(v:Values)=>{const m=wallModel(v);return !m.cleat?'Used with a French cleat mount':m.beveled?null:'Used with a beveled hanger board'};
const railOnly=(v:Values)=>{const m=wallModel(v);return !m.cleat?'Used with a French cleat mount':v.include_wall_rail||m.coupon?null:'Turn on Cut the wall rail'};
const tabs=(v:Values)=>v.joinery_style==='tab_slot'?null:'Used with tab and slot joinery';
const screws=(v:Values)=>v.joinery_style==='screw'||v.joint_screws?null:'Turn on screws beside the tabs, or use screw joinery';
const len=(mm:number,u:Units)=>formatShop(mm,u)+(u==='mm'?' mm':'″');
const L=(key:string,label:string,help?:string,extra:Partial<ProductControl>={}):ProductControl=>({key,label,help,kind:'length',...extra});
const C=(key:string,label:string,when?:(v:Values)=>string|null,help?:string):ProductControl=>({key,label,help,kind:'count',min:param(key)?.min,max:param(key)?.max,when});
const TOOL_LABEL:Record<string,string>={chisel_rack:'Chisel slot width',clamp_rack:'Clamp slot width',hammer_rack:'Hammer hole diameter',screwdriver_rack:'Shaft hole diameter',plier_stand:'Plier slot width',router_bit_stand:'Bit shank diameter',simple_drill_station:'Drill neck slot width',double_drill_station:'Drill neck slot width',single_shelf_drill_stand:'Drill neck slot width',double_shelf_drill_stand:'Drill neck slot width',wrench_holder:'Wrench slot width'};
const COUNT_LABEL:Record<string,string>={chisel_rack:'Chisel slots',clamp_rack:'Clamp slots',hammer_rack:'Hammer holes',screwdriver_rack:'Holes in the front row',plier_stand:'Plier slots',router_bit_stand:'Holes per row',simple_drill_station:'Drill slots',double_drill_station:'Drill slots',single_shelf_drill_stand:'Drill slots',double_shelf_drill_stand:'Drill slots'};
const toolModules=Object.keys(COUNT_LABEL);
const slotModules=['chisel_rack','clamp_rack','plier_stand','circular_saw_stand','simple_drill_station','double_drill_station','single_shelf_drill_stand','double_shelf_drill_stand','wrench_holder'];

const starters:ProductStarter[]=SHOP_WALL_MODULES.map(m=>({id:m.id,name:m.name,description:m.description,group:m.group,values:moduleValues(m.id)}));

export const shopWall:Product={
 id:'shop_wall',name:'Shop wall',sub:'French-cleat shelves, cabinets, racks, boxes and holders',code:'SW / P2',area:'Shop wall',
 file:SHOP_WALL_FILE,source,params,
 engineIncludes:['tab_pocket','joinery','seam_joinery','cleat','wall_mount','placement'].map(n=>`v5/src/modular_organization/data/scad/${n}.scad`),
 defaultStarter:'simple_shelves',
 starters,
 sections:[
  {id:'module',title:'Module',blurb:'Choose what to hang on the wall. Choosing a module loads its starting sizes; mount, stock, joinery and machining settings are kept.',controls:[
   {key:'module_type',label:'Module',kind:'choice',options:Object.fromEntries(SHOP_WALL_MODULES.map(m=>[m.id,`${m.name} · ${m.group}`]))},
  ],summary:v=>wallModel(v).mod.name},
  {id:'size',title:'Size',blurb:'Outside sizes of the body. Depth runs from the wall side of the back to the front; a French cleat adds its thickness behind.',controls:[
   L('width','Width'),L('depth','Depth'),L('height','Height','The body height; a lid pull or lip may rise above it.'),
  ],summary:(v,u)=>{const m=wallModel(v);return `${formatShop(m.W,u)} × ${formatShop(m.D,u)} × ${len(m.H,u)}`}},
  {id:'contents',title:'Shelves, drawers and openings',blurb:'What the module holds. Settings that do not apply to the chosen module are listed under Not in use.',controls:[
   C('interior_shelves','Interior shelves',modules('narrow_shelves','sandpaper_shelf','single_door_cabinet','double_door_cabinet','sliding_door_cabinet'),'Fixed shelves between the bottom and top, with equal openings.'),
   C('bay_count','Bays',family('cubby'),'Side-by-side cubes (cube shelves).'),
   C('drawer_count','Drawers',family('drawers')),
   C('display_shelves','Shelves',modules('jar_shelves','spray_paint_display','simple_shelves'),'Counting the bottom shelf.'),
   L('lip_height','Lip height','The retaining lip along the front of each shelf or deck.',{when:modules('jar_shelves','spray_paint_display','material_storage_stand')}),
   C('upper_shelf_count','Compartments above the cradle',family('drill_cabinet')),
   {key:'tool_count',label:'Openings',labelFor:v=>COUNT_LABEL[String(v.module_type)]??'Openings',kind:'count',min:param('tool_count')?.min,max:param('tool_count')?.max,when:modules(...toolModules)},
   L('tool_width','Opening width',undefined,{labelFor:v=>TOOL_LABEL[String(v.module_type)]??'Opening width',when:modules(...Object.keys(TOOL_LABEL))}),
   C('tool_rows','Rows of holes',modules('router_bit_stand')),
   L('bit_fit_allowance','Allowance over the shank','Added to the shank for the hole diameter.',{when:modules('router_bit_stand')}),
   {key:'second_row',label:'Staggered second row',kind:'toggle',help:'A second row with one fewer hole, behind the gaps of the first.',when:modules('screwdriver_rack')},
   L('slot_length','Slot length','From the front edge. Zero sizes it from the depth.',{when:modules(...slotModules)}),
   L('tool_pitch','Spacing (centre to centre)','Zero spreads the openings evenly across the width.',{when:modules(...toolModules),advanced:true}),
   L('saw_guard_width','Saw guard slot width',undefined,{when:modules('circular_saw_stand')}),
   L('saw_guard_offset','Slot from the left side','Left side of the slot from the left outside face.',{when:modules('circular_saw_stand')}),
   C('box_columns','Bin columns',modules('closed_lid_box','screw_box')),
   C('box_rows','Bin rows',modules('closed_lid_box','screw_box')),
   {key:'front_height_fraction',label:'Front height (share of the box height)',kind:'number',when:modules('screw_box','shallow_storage_box')},
   L('aperture_height','Glove slot height','Zero uses 42 % of the height.',{when:family('glove')}),
   L('aperture_length','Glove slot length','Zero uses 78 % of the inside width.',{when:family('glove')}),
   C('hook_count','Hooks',family('hooks')),
   C('bracket_count','Brackets',family('brackets')),
   L('dowel_diameter','Dowel diameter',undefined,{when:family('towel')}),
   L('rod_clearance','Dowel hole clearance','Added to the dowel for its holes.',{when:family('towel')}),
   C('wrench_levels','Wrench slots',family('wrench')),
   L('wrench_rise','Slot rise','How much each slot rises from its back end to the front, so wrenches stay put.',{when:family('wrench')}),
   L('fit_gap','Door, drawer and lid gap','Clearance around doors, drawer boxes, sliding leaves and lids.',{when:v=>['doors','drawers'].includes(wallModel(v).family)||v.module_type==='closed_lid_box'?null:'Used by doors, drawers and lids'}),
  ],summary:v=>{const m=wallModel(v),f=m.family;
   return f==='drawers'?`${v.drawer_count} drawers`:f==='doors'?`${v.interior_shelves} shelves`:f==='cubby'?(v.module_type.toString().includes('cube')?`${v.bay_count} bays`:`${v.interior_shelves} shelves`):f==='display'?`${v.display_shelves} shelves`:
    toolModules.includes(String(v.module_type))?`${v.tool_count} openings`:f==='box'?(v.module_type==='shallow_storage_box'?'One bin':`${v.box_columns} × ${v.box_rows} bins`):f==='hooks'?`${v.hook_count} hooks`:f==='brackets'?`${v.bracket_count} brackets`:f==='wrench'?`${v.wrench_levels} slots`:m.mod.name}},
  {id:'mount',title:'Wall mount',blurb:'A French cleat hangs the module on a beveled wall rail: either hooks cut into the side panels on the CNC, or a beveled hanger board screwed to the back. The wall rail is cut with the module.',controls:[
   {key:'mount',label:'Mount',kind:'choice',options:{french_cleat:'French cleat',direct_screws:'Screws through the back',none:'None (free standing)'},when:v=>wallModel(v).coupon?'The fit coupon always has a cleat section':null},
   {key:'cleat_strategy',label:'Cleat',kind:'choice',options:{cnc_hooks:'CNC side hooks',beveled_board:'Beveled hanger board'},when:v=>{const m=wallModel(v);return !m.cleat?'Used with a French cleat mount':m.family==='hooks'?'Hook panels have no side panels to cut hooks into; they hang from a beveled board':null}},
   {key:'include_wall_rail',label:'Cut the wall rail',kind:'toggle',when:cleatOnly},
   L('cleat_height','Cleat height',undefined,{when:cleatOnly}),
   {key:'bevel_angle',label:'Bevel angle (degrees)',kind:'number',when:cleatOnly},
   L('cleat_vertical_gap','Gap between the bevels','Zero: the bevels bear on each other.',{when:cleatOnly,advanced:true}),
   L('hook_tip_radius','Hook tip rounding',undefined,{when:cncOnly,advanced:true}),
   L('cleat_end_inset','Hanger inset from the sides',undefined,{when:beveledOnly}),
   L('wall_rail_length','Wall rail length','Zero cuts it as long as the module (or its hanger).',{when:railOnly}),
   L('wall_rail_pitch','Spacing of the other rails on your wall','For the collision check behind the module. Zero: one rail.',{when:cleatOnly}),
   L('wall_screw_spacing','Stud spacing',undefined,{when:v=>v.mount==='direct_screws'?null:railOnly(v)}),
   L('wall_screw_diameter','Wall screw diameter',undefined,{when:v=>v.mount==='direct_screws'?null:railOnly(v)}),
  ],summary:v=>{const m=wallModel(v);return !m.cleat?(v.mount==='direct_screws'?'Screws through the back':'None'):`${m.cnc?'CNC side hooks':'Beveled hanger'} · ${m.angle}°`}},
  {id:'materials',title:'Materials',shop:true,blurb:'Measure your sheets: nominal plywood is rarely its nominal thickness. Each part role has its own stock: tabs, slots, channels, drawer boxes, hooks and screws follow the thickness of each part, and the cut layout nests every thickness on its own sheets. Settings for parts the chosen module does not have are listed under Not in use.',controls:[
   {key:'carcass_stock',label:'Carcass stock',kind:'choice',options:stockLabels},
   L('material_thickness','Measured carcass thickness',undefined,{when:v=>v.carcass_stock==='custom_mm'?null:'Choose measured thickness'}),
   {key:'cleat_stock',label:'Cleat and rail stock',kind:'choice',options:cleatLabels,when:cleatOnly},
   L('custom_cleat_thickness','Measured cleat thickness',undefined,{when:v=>cleatOnly(v)??(v.cleat_stock==='custom_mm'?null:'Choose measured thickness for the cleat')}),
   ...ROLES.flatMap(r=>[
    {key:r.key,label:r.label,help:r.help,kind:'choice',options:roleLabels(r.key),when:roleUsed(r)} as ProductControl,
    L(r.custom,`Measured ${r.short} thickness`,undefined,{when:v=>roleUsed(r)(v)??(v[r.key]==='custom_mm'?null:`Choose measured thickness for the ${r.short}`)}),
   ]),
  ],summary:(v,u)=>{const m=wallModel(v),other=ROLES.filter(r=>!roleUsed(r)(v)&&Math.abs(m.roles[r.role]-m.t)>0.001).map(r=>`${len(m.roles[r.role],u)} ${r.short}`);
   return [`${len(m.t,u)} carcass`,...other,...(m.cleat&&m.ct!==m.t?[`${len(m.ct,u)} cleat`]:[])].join(' · ')}},
  {id:'joinery',title:'Joinery',shop:true,blurb:'Tabs are planned along every joint by the workshop\'s tab planner, the same as the cabinets. Slots get corner reliefs, tabs get shoulder reliefs, and screws go in the wood beside the tabs.',controls:[
   {key:'joinery_style',label:'Joints',kind:'choice',options:{tab_slot:'Tab and slot',screw:'Butt joints with screws'}},
   L('joint_fit_clearance','Slot fit clearance','Total extra width and length of every slot over its tab.',{when:tabs}),
   L('tab_setback','Tab setback','Tabs stop this far short of the outside face.',{when:tabs}),
   {key:'joint_screws',label:'Screws beside the tabs',kind:'toggle',when:tabs},
   L('joint_tab_width','Tab width',undefined,{when:tabs,advanced:true}),
   {key:'tab_count_mode',label:'Tab count',kind:'choice',options:{adaptive:'From the joint length',fixed:'Fixed number'},when:tabs,advanced:true},
   C('joint_tab_count','Tabs per joint',v=>tabs(v)??(v.tab_count_mode==='fixed'?null:'Used with a fixed tab count')),
   L('target_tab_spacing','Joint length per tab',undefined,{when:v=>tabs(v)??(v.tab_count_mode==='adaptive'?null:'Used with an adaptive tab count'),advanced:true}),
   C('max_auto_tab_count','Most tabs per joint',v=>tabs(v)??(v.tab_count_mode==='adaptive'?null:'Used with an adaptive tab count')),
   L('joint_tab_edge_margin','Tab edge margin',undefined,{when:tabs,advanced:true}),
   L('minimum_joint_web','Minimum wood between slots',undefined,{when:tabs,advanced:true}),
   L('screw_clearance_diameter','Screw clearance hole',undefined,{when:screws}),
   L('screw_pilot_diameter','Pilot hole (drilled at assembly)',undefined,{when:screws,advanced:true}),
   L('screw_pilot_depth','Pilot depth',undefined,{when:screws,advanced:true}),
  ],summary:(v,u)=>v.joinery_style==='screw'?'Butt joints with screws':`Tab and slot · ${len(Number(v.joint_fit_clearance),u)} fit${v.joint_screws?' · screws':''}`},
  {id:'machining',title:'Machining',shop:true,blurb:'The cutter sets the corner reliefs of slots, tab shoulders and hooks, and the smallest opening cut rather than drilled.',controls:[
   L('cnc_tool_diameter','CNC cutter diameter'),
   {key:'slot_corner_relief',label:'Inside-corner relief',kind:'choice',options:{none:'None (CAM adds relief)',dogbone:'Dog-bone',t_bone:'T-bone'}},
   {key:'apply_kerf_compensation',label:'Compensate for kerf',kind:'toggle'},
   L('kerf','Kerf width',undefined,{when:v=>v.apply_kerf_compensation?null:'Turn kerf compensation on'}),
   {key:'circle_segments',label:'Circle smoothness (segments)',kind:'number',advanced:true},
  ],summary:(v,u)=>`${len(Number(v.cnc_tool_diameter),u)} cutter · ${v.slot_corner_relief==='none'?'no relief':v.slot_corner_relief==='t_bone'?'T-bones':'dog-bones'}`},
  {id:'sheets',title:'Sheets & layout',shop:true,blurb:'Stock sheet size and spacing used by the cut layout and the per-sheet nesting.',controls:[
   L('stock_width','Sheet width'),L('stock_height','Sheet height'),L('layout_gap','Gap between parts'),
   {key:'include_shared_export_bounding_box',label:'Registration frame in layouts',kind:'toggle'},
   L('engrave_label_size','Engraved label size',undefined,{advanced:true}),
  ],summary:(v,u)=>`${formatShop(Number(v.stock_width),u)} × ${len(Number(v.stock_height),u)}`},
 ],
 renderModes:[{id:'assembly',label:'Module and wall rail'},{id:'flat_3d',label:'Flat parts · exact 3D'}],
 exportModes:['cut_layout','drill_layout','engrave_layout'],
 startHere:'Shop wall: open products/shop_wall/shop_wall.scad in OpenSCAD 2021.01 or later (keep the engine folder beside the products folder; it holds the shared joinery, cleat and layout files). All selected settings are applied.\n\nSet output_mode to assembly for the module on its wall rail, cut_layout for through cuts, drill_layout for holes smaller than the cutter (drill at the circle centers), engrave_layout for part labels, or bom for the parts list. Export SVG or DXF from OpenSCAD. Bevel the hanger and wall rail blanks on a saw after cutting. Set module_type to fit_coupon to cut a fit test coupon with the same stock, clearances, cutter and bevel.\n',
 coupon:{module:'fit_coupon',forKey:'coupon_for',label:'Fit test coupon',note:'One tab in its slot with screws (and one tab plate per other stock the module\'s tabs come from), and a short CNC hook (or beveled hanger) on a short wall rail, cut from the same stock with the same clearances, cutter, relief and bevel as this design. Cut it before the module: the tab should slide in by hand, and the hook should drop over the rail and sit flat against it.'},
 linked(key,value){
  // Choosing a module loads its starting sizes and module settings; shop settings stay.
  if(key==='module_type'&&PRESETS[String(value)])return {...moduleValues(String(value)),_starter:String(value)};
  return {};
 },
 validate(v){
  const m=wallModel(v),e:string[]=[];
  if(!(m.t>0&&m.t<=50))e.push('Carcass thickness must be more than 0 and at most 50 mm.');
  if(m.cleat&&!(m.ct>0&&m.ct<=50))e.push('Cleat thickness must be more than 0 and at most 50 mm.');
  for(const r of ROLES)if(!roleUsed(r)(v)&&!(m.roles[r.role]>=1&&m.roles[r.role]<=50))e.push(`${r.label} must be a listed preset or a measured thickness from 1 to 50 mm.`);
  for(const k of ['width','depth','height']){const p=param(k)!,x=Number(v[k]);if(!(x>=p.min!&&x<=p.max!))e.push(`${k[0].toUpperCase()+k.slice(1)} must be between ${p.min} and ${p.max} mm.`)}
  if(!m.coupon&&!(m.W>=3*m.t+20&&m.D>=2*m.t+20&&m.H>=3*m.t+20))e.push('The module is too small for its stock: make it at least three boards plus 20 mm wide and high.');
  for(const s of shopWall.sections)for(const c of s.controls)if(c.kind==='count'&&!c.when?.(v)){const x=Number(v[c.key]);if(!Number.isInteger(x)||x<(c.min??1)||x>(c.max??12))e.push(`${c.label} must be a whole number from ${c.min??1} to ${c.max??12}.`)}
  if(!(m.fit>=0&&m.fit<m.t/4))e.push('Slot fit clearance must be at least 0 and less than a quarter of the stock.');
  if(!(m.tool>0))e.push('The cutter diameter must be more than 0.');
  if(m.cleat&&!m.coupon){
   if(!(m.ch>m.rise+10&&m.H>m.ch+m.t))e.push(`The cleat must be more than its bevel rise plus 10 mm high and lower than the module.`);
   else if(m.railZ<0)e.push('The wall rail would reach below the module: use a shorter cleat or a taller module.');
   else if(m.cnc&&m.H-m.ch-m.t-m.fit/2-Math.max(m.tool,m.t/2)<2*m.tool+12)e.push('The module is too short for CNC side hooks with this cleat: use a shorter cleat, a taller module or a beveled hanger board.');
  }
  return e;
 },
 summary(v){const m=wallModel(v);return [{label:'WIDTH',mm:m.W},{label:'HEIGHT',mm:m.H},{label:'DEPTH',mm:m.wallDepth},{label:'MODULE',text:m.mod.name}]},
 assemblySteps(v){
  const m=wallModel(v),f=m.family,steps=['Dry-fit first, then glue each tab joint as you go. Drill the edge pilots for the screws at assembly, through the screw holes.'];
  const back=m.cnc?'Push the back on from behind over the rear tabs; the side panels\' hooks pass through the notches at its top.':'Push the back on from behind over the rear tabs.';
  if(f==='coupon')return ['Push the tab into its slot by hand: it should slide in with light pressure and sit flush with the far face (less the tab setback).',`${m.cnc?'Drop the hook':'Bevel the hanger and the rail blank on a saw, then drop the hanger'} over the rail: the bevels should bear and the faces sit flat against each other.`,'Adjust the slot fit clearance, cutter diameter or bevel angle until the coupon fits, then cut the module.'];
  if(f==='hooks')steps.push('Lay the back flat, face up.',`Push the ${v.hook_count} hooks onto it, their rear tabs into its slots.`);
  else if(f==='drill_simple')steps.push('Lay the drill cradle upside down.','Fit the two gussets into its underside, top tabs into its slots.',back);
  else if(f==='brackets')steps.push('Lay the deck upside down.',`Fit the ${v.bracket_count} brackets into its underside.`,'Turn it over and drop the lip into the slots along the front.',back);
  else if(f==='towel'||f==='wrench')steps.push('Push the two cheeks onto the back, rear tabs into its slots.',...(f==='towel'?['Slide the dowel through both cheeks.']:[]));
  else if(f==='box'||f==='glove'){
   steps.push('Lay the bottom flat.');
   if(f==='box'&&v.module_type!=='shallow_storage_box')steps.push('Stand the bin dividers in the bottom\'s slots.');
   steps.push('Stand the front in the bottom\'s slots.','Slide the two sides on from the left and right over the bottom and front tabs.',back);
   if(v.module_type==='closed_lid_box')steps.push('Glue the pull into the lid, then hinge the lid at the top of the back.');
  }else if(String(v.module_type).includes('cube')){
   steps.push('Lay the bottom flat.');if(Number(v.bay_count)>1)steps.push('Stand the dividers in its slots.');steps.push('Lower the top onto the divider tabs.','Slide the sides on from the left and right.',back);
  }else{
   steps.push('Lay the left side flat, inside face up.','Stand the bottom, top, shelves'+(f==='drawers'?' and drawer dividers':f==='display'?'':'')+' in its slots.','Lower the right side onto their tabs.',back);
   if(f==='display'&&v.module_type!=='simple_shelves')steps.push('Drop the lips into the slots along the front of each shelf.');
   if(f==='doors'&&v.module_type==='sliding_door_cabinet')steps.push('Fit the guide strips into the top and bottom, then lift each leaf into its top channel and drop it into the bottom one.');
   else if(f==='doors')steps.push('Glue each pull into its door, then hinge the doors on their outer edges.');
   if(f==='drawers')steps.push('Build each drawer: sides into the front, then the back, then drop the box onto its bottom, the walls\' tabs into its slots. Glue the bottom (brads hold a thin bottom while the glue sets). Slide the drawers in.');
  }
  if(m.cleat)steps.push(m.cnc?'Screw the wall rail into studs, bevel up and toward the wall; lift the module over it and let the side hooks drop onto it.':'Screw the hanger (and spacer) to the back from inside. Screw the wall rail into studs, bevel up; lift the module over it and let the hanger drop onto it.');
  else if(v.mount==='direct_screws')steps.push('Screw the back to the wall through its holes, into studs or rated anchors.');
  return steps;
 },
 coverage:{
  checked:['Every tab against its slot: clearance on both axes, tab length against the panel it passes through, cutter reach and corner reliefs','Shoulder reliefs beside every tab and at the hooks\' inside corners','Screw holes in solid wood, clear of slots, notches and openings, with room for the pilot in the edge','Each part at its own role stock: tabs as long as the part they enter, slots as wide as the part they take, channels, drawer boxes and the back depth from those thicknesses; parts too thin for a countersink or an edge pilot are glued instead of screwed, and tabs need 3 mm of engagement','Assembly order: each part goes on along its tabs','French cleat: rail position, hook depth and tip, notch height, nothing behind the wall, other rails on the wall','Doors, drawers, sliding leaves and bins clear their openings with the gap setting','Flat cut layout and sheet nesting: every part placed once, no overlapping outlines','Parts intersecting in 3D for this exact design, on demand: Check for intersecting parts above (every starter and a seeded set of random designs are also swept in the test suite)'],
  notChecked:['A physical cut: these are geometric checks. Cut the fit test coupon (Export) before a full module','Load rating, wall anchoring and stud location'],
 },
 sheetSection:'sheets',
};
