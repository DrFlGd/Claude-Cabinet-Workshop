// Media cart: the shop media holder (sloped or stepped bins, lower cubbies, side shelf
// towers) as a Cabinet Workshop product. The SCAD file is the engine; this module adds the
// editor's labels and grouping, starting points, quick checks and the geometry the instant
// elevation drawings use (the same formulas as the SCAD file).
import type {Values} from '../cabinet';
import {formatShop,type Units} from '../units';
import type {Product,ProductControl} from './types';
import {scadParams} from './scad-params';
import sources from './product-sources.json';

export const MEDIA_CART_FILE='products/media_cart/media_cart.scad';
const source=(sources as Record<string,string>)[MEDIA_CART_FILE];
const params=scadParams(source);

const NOMINAL:Record<string,number>={'1/8_nominal':3.175,'1/4_nominal':6.35,'3/8_nominal':9.525,'1/2_nominal':12.7,'5/8_nominal':15.875,'3/4_nominal':19.05,'1_nominal':25.4};
const stockLabels:Record<string,string>={custom_mm:'Measured thickness (enter mm)',...Object.fromEntries(Object.entries(NOMINAL).map(([k,mm])=>[k,k.replace('_nominal','″ nominal')+` (${mm} mm)`]))};
const joinery={butt:'Butt (glue only)',screw:'Screws',dado:'Dado (housed)',tab_slot:'Tab & slot'};

// Resolved construction, mirroring the SCAD file's shape logic.
export function cartModel(v:Values){
 const n=(k:string,d=0)=>{const x=Number(v[k]);return Number.isFinite(x)?x:d};
 const stock=(key:string,measured:number)=>v[key]==='custom_mm'?measured:NOMINAL[v[key]]??measured;
 const t=stock('carcass_stock',n('material_thickness',18));
 const ft=v.fin_stock==='match_carcass'?t:stock('fin_stock',n('custom_fin_thickness',12));
 const custom=v.shape==='custom',shelfCart=v.shape==='shelf_cart';
 const stepped=v.bin_profile==='Auto'?v.shape==='stepped_bins':v.bin_profile==='Stepped';
 const tower:string=custom?String(v.custom_tower):shelfCart?'Right':'None';
 const lower=custom?!!v.custom_lower_cubbies:!shelfCart;
 const left=tower==='Left'||tower==='Both',right=tower==='Right'||tower==='Both';
 const width=n('width',900),depth=n('depth',600),front=n('front_height',350),rear=n('rear_height',950);
 const rows=Math.max(1,Math.round(n('rows',3))),columns=Math.max(1,Math.round(n('columns',3)));
 const cubbyH=n('cubby_height',125),cubbyCols=Math.max(1,Math.round(n('cubby_columns',3)));
 const towerW=n('tower_width',185),openings=Math.max(1,Math.round(n('tower_openings',5)));
 const x0=left?towerW+t:0,x1=width-(right?towerW+t:0),span=x1-x0-2*t;
 const deck=lower?2*t+cubbyH:t,pitch=(depth-t)/rows,colPitch=(span+ft)/columns;
 const lastRise=v.back_flush_with_top_entrance?rows-1:rows;
 const rowZ=(i:number)=>front+(rear-front)*Math.min(i,lastRise)/rows,wallY=(i:number)=>i*pitch;
 const finX=(c:number)=>x0+t-ft+c*colPitch;
 const edge:[number,number][]=[[0,front],...(stepped?Array.from({length:Math.max(0,lastRise)},(_,k)=>k+1).flatMap(i=>[[wallY(i),rowZ(i-1)],[wallY(i),rowZ(i)]] as [number,number][]):lastRise>0?[[wallY(lastRise),rowZ(lastRise)] as [number,number]]:[]),[depth,rowZ(rows)]];
 const binTop=rowZ(rows),body=left||right?rear:binTop,lift=v.show_casters?n('caster_height',85):0;
 return {t,ft,custom,stepped,tower,lower,left,right,width,depth,front,rear,rows,columns,cubbyH,cubbyCols,towerW,openings,x0,x1,span,deck,pitch,colPitch,rowZ,wallY,finX,edge,binTop,body,lift,
  clearW:colPitch-ft,clearD:pitch-t,towerOpening:(rear-t)/openings-t,cubbyW:(span+t)/cubbyCols-t};
}

const notCustom=(v:Values)=>v.shape==='custom'?null:'Applies to the Custom shape; choosing it here switches the shape to Custom';
const usesStyle=(style:string)=>(v:Values)=>v.joinery_style===style||v.panel_joinery===style?null:`Used with ${(joinery as Record<string,string>)[style].toLowerCase()} joinery`;
const usesScrews=(v:Values)=>v.joinery_style==='screw'||v.panel_joinery!=='butt'?null:'Used when any joint is screwed (walls are screwed to the bottom unless panel joinery is butt)';
const usesTabs=(v:Values)=>v.joinery_style==='tab_slot'||v.joinery_style==='screw'||v.panel_joinery!=='butt'&&v.panel_joinery!=='dado'?null:'Used by tab & slot and screw joints';
const casters=(v:Values)=>v.show_casters?null:'Turn casters on';
// A length with its unit, for the section summaries.
const len=(mm:number,u:Units)=>formatShop(mm,u)+(u==='mm'?' mm':'″');
const L=(key:string,label:string,help?:string,extra:Partial<ProductControl>={}):ProductControl=>({key,label,help,kind:'length',...extra});

export const mediaCart:Product={
 id:'media_cart',name:'Media cart',sub:'Adjustable bins, lower cubbies and side shelf towers',code:'MC / P1',
 file:MEDIA_CART_FILE,source,params,
 engineIncludes:['v5/src/modular_organization/data/scad/tab_pocket.scad'],
 defaultStarter:'sloped_bins',
 starters:[
  {id:'sloped_bins',name:'Sloped bins',description:'3 × 3 sloped bins over lower cubbies, on casters',values:{shape:'sloped_bins'}},
  {id:'stepped_bins',name:'Stepped bins',description:'Bins whose walls step up row by row',values:{shape:'stepped_bins'}},
  {id:'shelf_cart',name:'Shelf cart',description:'Sloped bins with a shelf tower on the right',values:{shape:'shelf_cart'}},
  {id:'double_tower',name:'Two towers',description:'Bins between two shelf towers, cubbies below',values:{shape:'custom',custom_tower:'Both',custom_lower_cubbies:true,bin_profile:'Stepped',width:1200,rows:4,columns:2,tower_openings:6}},
  {id:'compact_sorter',name:'Compact sorter',description:'Small stepped sorter in ½″ stock, no casters',values:{shape:'custom',custom_tower:'None',custom_lower_cubbies:false,bin_profile:'Stepped',width:600,depth:400,front_height:220,rear_height:520,rows:2,columns:4,carcass_stock:'1/2_nominal',show_casters:false}},
 ],
 sections:[
  {id:'shape',title:'Shape',blurb:'Start from a reference shape. Towers and lower cubbies are chosen in Custom; the quick buttons above the drawing switch to Custom for you.',controls:[
   {key:'shape',label:'Reference shape',kind:'choice',options:{sloped_bins:'Sloped bins',stepped_bins:'Stepped bins',shelf_cart:'Shelf cart (right tower)',custom:'Custom'}},
   {key:'bin_profile',label:'Bin wall profile',kind:'choice',options:{Auto:'Follow the shape',Stepped:'Stepped',Sloped:'Sloped'},help:'Stepped walls rise in a step at every crosspiece; sloped walls run in a straight line from the front to the back.'},
   {key:'custom_tower',label:'Shelf towers',kind:'choice',options:{None:'None',Left:'Left',Right:'Right',Both:'Both sides'},when:notCustom},
   {key:'custom_lower_cubbies',label:'Lower cubbies',kind:'toggle',when:notCustom},
  ],summary:v=>{const m=cartModel(v);return `${m.stepped?'Stepped':'Sloped'} bins${m.tower!=='None'?` · ${m.tower==='Both'?'two towers':m.tower.toLowerCase()+' tower'}`:''}${m.lower?' · cubbies':''}`}},
  {id:'size',title:'Size',blurb:'Width includes any tower. Heights are measured from the underside of the bottom panel; casters add their height.',controls:[
   L('width','Overall width'),L('depth','Depth'),
   L('front_height','Front height','Top of the front crosspiece: the lowest bin entrance.'),
   L('rear_height','Rear height','Top of the back of the bins and of the towers. The rise between bin entrances follows from the front and rear heights.'),
   {key:'back_flush_with_top_entrance',label:'End the bins level with the last entrance',kind:'toggle',help:'The back of the bins stops level with the last row entrance instead of rising one more step. Towers keep the full rear height.'},
  ],summary:(v,u)=>{const m=cartModel(v);return `${formatShop(m.width,u)} × ${formatShop(m.depth,u)} × ${len(m.body+m.lift,u)}`}},
  {id:'bins',title:'Bins',blurb:'Rows run front to back, columns side to side. Each row\'s entrance is higher than the one in front of it.',controls:[
   {key:'rows',label:'Rows (front to back)',kind:'count'},{key:'columns',label:'Columns',kind:'count'},
  ],summary:(v,u)=>{const m=cartModel(v);return `${m.rows} × ${m.columns} · ${formatShop(m.clearW,u)} × ${len(m.clearD,u)} clear`}},
  {id:'cubbies',title:'Lower cubbies',controls:[
   L('cubby_height','Cubby clear height',undefined,{when:v=>cartModel(v).lower?null:'Turn lower cubbies on (Custom shape) or use Sloped or Stepped bins'}),
   {key:'cubby_columns',label:'Cubby columns',kind:'count',when:v=>cartModel(v).lower?null:'Turn lower cubbies on'},
  ],summary:(v,u)=>{const m=cartModel(v);return m.lower?`${m.cubbyCols} × ${len(m.cubbyW,u)} wide`:'None'}},
  {id:'towers',title:'Side towers',blurb:'A tower shares the bins\' side wall and holds evenly spaced shelves.',controls:[
   L('tower_width','Tower clear width',undefined,{when:v=>cartModel(v).tower!=='None'?null:'Add a tower (Shelf cart or Custom shape)'}),
   {key:'tower_openings',label:'Tower openings',kind:'count',when:v=>cartModel(v).tower!=='None'?null:'Add a tower'},
  ],summary:(v,u)=>{const m=cartModel(v);return m.tower==='None'?'None':`${m.openings} openings · ${len(m.towerOpening,u)} high`}},
  {id:'stability',title:'Stability',blurb:'The engine check finds the push at the top and the lean on the front edge that would tip the cart, empty, fully loaded and loaded only at the top, and warns below the forces you set here. The drawing shows the result and the center of gravity.',controls:[
   {key:'stability_push_force',label:'Push or pull at the top (N)',kind:'number',help:'A level force at the top edge, in each direction. 50 N is a firm one-handed push (about 5 kg).'},
   {key:'stability_lean_force',label:'Lean on the front edge (N)',kind:'number',help:'Downward force on the front edge of the bins, for example someone leaning on it. Only tips a cart whose front support is behind that edge.'},
   {key:'bin_load',label:'Contents per bin (kg)',kind:'number'},
   {key:'cubby_load',label:'Contents per cubby (kg)',kind:'number',when:v=>cartModel(v).lower?null:'Turn lower cubbies on'},
   {key:'shelf_load',label:'Contents per tower opening (kg)',kind:'number',when:v=>cartModel(v).tower!=='None'?null:'Add a tower'},
   {key:'material_density',label:'Sheet density (kg/m³)',kind:'number',advanced:true,help:'Plywood is about 500 to 700 kg/m³, MDF about 750.'},
  ],summary:v=>`${v.stability_push_force} N push · ${v.stability_lean_force} N lean · ${v.bin_load} kg per bin`},
  {id:'materials',title:'Materials',shop:true,blurb:'Measure your sheets: nominal plywood is rarely its nominal thickness.',controls:[
   {key:'carcass_stock',label:'Carcass stock',kind:'choice',options:stockLabels},
   L('material_thickness','Measured carcass thickness',undefined,{when:v=>v.carcass_stock==='custom_mm'?null:'Choose measured thickness'}),
   {key:'fin_stock',label:'Fin (bin divider) stock',kind:'choice',options:{match_carcass:'Same as carcass',...stockLabels}},
   L('custom_fin_thickness','Measured fin thickness',undefined,{when:v=>v.fin_stock==='custom_mm'?null:'Choose measured thickness for the fins'}),
  ],summary:(v,u)=>{const m=cartModel(v);return `${len(m.t,u)} carcass${m.ft!==m.t?` · ${len(m.ft,u)} fins`:''}`}},
  {id:'joinery',title:'Joinery',shop:true,blurb:'Fins and crosspieces always join with opposing half-laps. Side walls stand on the bottom panel and are screwed from below unless panel joinery is butt.',controls:[
   {key:'joinery_style',label:'Crosspieces to side walls',kind:'choice',options:joinery},
   {key:'panel_joinery',label:'Floors, deck, cubbies and towers',kind:'choice',options:joinery},
   L('joint_fit_clearance','Tab & half-lap fit clearance','Total extra width and length of every tab receiver and half-lap slot.'),
   L('dado_depth','Dado depth',undefined,{when:usesStyle('dado')}),
   L('dado_fit_clearance','Dado fit clearance','Total extra groove width across the housed panel.',{when:usesStyle('dado')}),
   L('tab_length','Tab length',undefined,{when:usesTabs,advanced:true}),
   L('tab_spacing','Tab spacing',undefined,{when:usesTabs,advanced:true}),
   L('tab_edge_margin','Tab edge margin',undefined,{when:usesTabs,advanced:true}),
   L('minimum_joint_web','Minimum web between receivers',undefined,{when:usesTabs,advanced:true}),
   L('screw_clearance_diameter','Screw clearance hole',undefined,{when:usesScrews}),
   L('screw_pilot_diameter','Pilot hole (drilled at assembly)',undefined,{when:usesScrews,advanced:true}),
   L('screw_pilot_depth','Pilot depth',undefined,{when:usesScrews,advanced:true}),
  ],summary:v=>`${(joinery as Record<string,string>)[v.joinery_style]??v.joinery_style} · ${(joinery as Record<string,string>)[v.panel_joinery]??v.panel_joinery}`},
  {id:'machining',title:'Machining',shop:true,blurb:'Relief lets square parts seat in slots and dados cut with a round cutter.',controls:[
   L('cnc_tool_diameter','CNC cutter diameter'),
   {key:'slot_corner_relief',label:'Inside-corner relief',kind:'choice',options:{none:'None (CAM adds relief)',dogbone:'Dog-bone',t_bone:'T-bone'}},
   {key:'apply_kerf_compensation',label:'Compensate for kerf',kind:'toggle'},
   L('kerf','Kerf width',undefined,{when:v=>v.apply_kerf_compensation?null:'Turn kerf compensation on'}),
   {key:'circle_segments',label:'Circle smoothness (segments)',kind:'number',advanced:true},
  ],summary:(v,u)=>`${len(Number(v.cnc_tool_diameter),u)} cutter · ${v.slot_corner_relief==='none'?'no relief':v.slot_corner_relief==='t_bone'?'T-bones':'dog-bones'}`},
  {id:'mobility',title:'Casters',shop:true,controls:[
   {key:'show_casters',label:'Casters',kind:'toggle'},
   L('caster_height','Floor to bottom panel',undefined,{when:casters}),
   L('caster_inset','Caster center from edges',undefined,{when:casters}),
   L('caster_hole_spacing_x','Bolt spacing side to side',undefined,{when:casters}),
   L('caster_hole_spacing_y','Bolt spacing front to back',undefined,{when:casters}),
   L('caster_hole_diameter','Bolt hole diameter','Zero leaves the bottom panel undrilled.',{when:casters}),
  ],summary:(v,u)=>v.show_casters?`${len(Number(v.caster_height),u)} high`:'None'},
  {id:'sheets',title:'Sheets & layout',shop:true,blurb:'Stock sheet size and spacing used by the cut layout and the per-sheet nesting.',controls:[
   L('stock_width','Sheet width'),L('stock_height','Sheet height'),L('layout_gap','Gap between parts'),
   {key:'include_shared_export_bounding_box',label:'Registration frame in layouts',kind:'toggle'},
   L('engrave_label_size','Engraved label size',undefined,{advanced:true}),
  ],summary:(v,u)=>`${formatShop(Number(v.stock_width),u)} × ${len(Number(v.stock_height),u)}`},
 ],
 renderModes:[{id:'assembly',label:'Full assembly'},{id:'flat_3d',label:'Flat parts · exact 3D'}],
 exportModes:['cut_layout','drill_layout','pocket_layout','pocket_dados','pocket_dados_flip','engrave_layout'],
 linked(key,value,v){
  // Tower and cubby choices only apply to the Custom shape: switch to it, keeping the look.
  if((key==='custom_tower'||key==='custom_lower_cubbies')&&v.shape!=='custom'){
   const m=cartModel(v);
   return {shape:'custom',custom_tower:m.tower,custom_lower_cubbies:m.lower,bin_profile:v.bin_profile==='Auto'?(m.stepped?'Stepped':'Sloped'):v.bin_profile};
  }
  return {};
 },
 validate(v){
  const m=cartModel(v),e:string[]=[];
  if(!(m.t>0&&m.t<=50))e.push('Carcass thickness must be more than 0 and at most 50 mm.');
  if(!(m.ft>0&&m.ft<=50))e.push('Fin thickness must be more than 0 and at most 50 mm.');
  if(!(m.width>=300&&m.width<=2400))e.push('Width must be between 300 and 2,400 mm.');
  if(!(m.depth>=200&&m.depth<=1200))e.push('Depth must be between 200 and 1,200 mm.');
  if(!(m.rear>=m.front))e.push('Rear height must be at least the front height.');
  if(!(m.rear<=2000))e.push('Rear height must be at most 2,000 mm.');
  for(const k of ['rows','columns','cubby_columns','tower_openings'])if(!Number.isInteger(Number(v[k]))||Number(v[k])<1||Number(v[k])>12)e.push(`${k.replace('_',' ')} must be a whole number from 1 to 12.`);
  if(m.span<60)e.push('The towers leave too little width for the bins.');
  else if(m.clearW<20)e.push('Each bin needs at least 20 mm clear width: use fewer columns or a wider cart.');
  if(m.clearD<20)e.push('Each bin needs at least 20 mm clear depth: use fewer rows or a deeper cart.');
  if(m.front-m.deck<Math.max(2*m.t,30))e.push('The front height leaves too little crosspiece above the bin floor.');
  for(const [k,label,max] of [['stability_push_force','The push at the top',1000],['stability_lean_force','The lean on the front',2000],['bin_load','Contents per bin',100],['cubby_load','Contents per cubby',100],['shelf_load','Contents per tower opening',100]] as const)
   if(!(Number(v[k])>=0&&Number(v[k])<=max))e.push(`${label} must be from 0 to ${max.toLocaleString('en-US')}.`);
  if(!(Number(v.material_density)>=200&&Number(v.material_density)<=1500))e.push('Sheet density must be from 200 to 1,500 kg/m³.');
  return e;
 },
 summary(v){const m=cartModel(v);return [{label:'WIDTH',mm:m.width},{label:'HEIGHT',mm:m.body+m.lift},{label:'DEPTH',mm:m.depth},{label:'BINS',text:`${m.rows} × ${m.columns}`}]},
 assemblySteps(v){
  const m=cartModel(v),glue='Dry-fit first, then glue each joint as you go.';
  const steps=[glue,'Lay the bottom panel flat, face up.'];
  if(m.lower)steps.push('Stand the cubby dividers and the cubby back on the bottom panel (their tabs drop into its slots).','Lower the bin deck onto the cubby dividers and back, engaging their top tabs.');
  steps.push(`Stand the ${m.rows+1} crosspieces on the ${m.lower?'deck':'bottom panel'}, front (lowest) to back (tallest), slots facing up.`);
  if(m.columns>1)steps.push(`Drop the ${m.columns-1} fin${m.columns>2?'s':''} into the crosspiece half-laps from above; the fins' bottom tabs enter the ${m.lower?'deck':'bottom panel'}.`);
  steps.push('Slide the left and right bin walls on from the sides over the crosspiece'+(m.lower?', deck and cubby-back':'')+' tabs.','Screw up through the bottom panel into the bottom edges of the walls through the holes drilled from drill_layout (drill the pilots on assembly).');
  if(m.tower!=='None')steps.push('Build each tower on its outer wall laid flat: fit the back, the shelves and the cap, then stand it up and slide it onto the shared bin wall. Screw its wall and back to the bottom panel from below.');
  if(v.show_casters)steps.push('Bolt the four casters to the bottom panel through the drilled holes.');
  return steps;
 },
 coverage:{
  checked:['Bin, cubby and tower opening sizes against minimums','Tip-over: the push at the top and the lean on the front that tip the cart, empty, fully loaded and top loaded, from its center of gravity and its caster or footprint support','Racking: which parts and joints resist side-to-side and front-to-back shear, with a warning where only glued butt joints do','Holes smaller than the cutter go to a separate drill layout; second-face dados are laid out for the sheet turned over, with registration pins','Joint fit: tab, dado, screw and half-lap clearances for the measured stock','Room for tabs and screws on walls that carry joints on both faces','Slot widths against the cutter, corner relief at closed corners','Caster bolt holes clear of every panel standing on the bottom','Flat cut layout: every part has its own place and no two outlines overlap','Sheet nesting: every part placed on the stock sheet with the layout gap, one SVG and DXF per sheet in the package'],
  notChecked:['Parts intersecting in 3D for this exact design (every starter and a seeded set of random designs are swept in the test suite)','Strength: load rating of joints, panels, shelves and casters; dynamic loads such as rolling over a threshold','Grain direction and edge banding'],
 },
 sheetSection:'sheets',
};
