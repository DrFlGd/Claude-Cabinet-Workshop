// Drawer-slide and hinge hardware: which catalog model a design uses, which settings a generic
// model exposes, and where the engine drills the mounting holes on each pair of mating boards.
// Hole positions mirror the engine (core/resolve.scad, core/drawers.scad); the cabinet-side
// holes are read from the engine's own side-panel feature ledger when it is available.
import catalog from './hardware.json';
import equipmentCatalog from './equipment-hardware.json';
import type {Plan} from './analysis';

export type Values=Record<string,any>;
export type Category='drawer_slide'|'hinge';
export type Profile={id:string;category:string;manufacturer:string;family:string;model:string;label:string;targets?:string[]|null;
 verification:{status:string;notes?:string};apply?:Record<string,any>|null;source?:Record<string,any>;geometry_support?:{status:string;notes?:string};mounting_specs?:Record<string,any>};
const FAMILY_IDS=['shop_cart','utility','benchtop','stackable','kitchen','drawer','equipment_stand'];
export const PROFILE_KEY:Record<Category,string>={drawer_slide:'_slide_profile',hinge:'_hinge_profile'};
export const GENERIC='generic';

// Catalog entries for this cabinet type. Models with a settings patch can be selected; the rest
// are reference data only (the engine cannot represent their mounting yet).
export function catalogFor(family:number,category:Category){
 const target=FAMILY_IDS[family];
 const all=((family===6?equipmentCatalog.profiles:catalog.profiles) as Profile[]).filter(p=>p.category===category&&(!p.targets||p.targets.includes(target)));
 const usable=all.filter(p=>p.apply&&Object.keys(p.apply).length);
 return {
  models:usable.filter(p=>p.manufacturer!=='Generic'),
  templates:usable.filter(p=>p.manufacturer==='Generic'),
  reference:all.filter(p=>!p.apply||!Object.keys(p.apply).length),
 };
}
const same=(a:unknown,b:unknown):boolean=>Array.isArray(a)||Array.isArray(b)
 ?Array.isArray(a)&&Array.isArray(b)&&a.length===b.length&&a.every((x,i)=>same(x,b[i]))
 :typeof a==='number'||typeof b==='number'?Math.abs(Number(a)-Number(b))<1e-6:a===b;
// Keys of a profile's patch that this design no longer matches.
export function profileDifferences(values:Values,p:Profile){return Object.entries(p.apply??{}).filter(([k,v])=>values[k]!==undefined&&!same(values[k],v)).map(([k])=>k)}

export type Selection={mode:'generic';basedOn?:Profile;changed?:string[]}|{mode:'catalog';profile:Profile};
// The model a design uses. A catalog model stays selected while every setting it patched still
// has the catalog value; once one is edited the design is generic, "based on" that model.
// Designs saved before the choice existed are matched against the catalog.
export function selection(values:Values,family:number,category:Category):Selection{
 const {models,templates}=catalogFor(family,category),id=values[PROFILE_KEY[category]];
 if(id===GENERIC){const basedOn=[...models,...templates].find(p=>p.id===values[PROFILE_KEY[category]+'_base']);return basedOn?{mode:'generic',basedOn}:{mode:'generic'}}
 const chosen=models.find(p=>p.id===id);
 if(chosen){const changed=profileDifferences(values,chosen);return changed.length?{mode:'generic',basedOn:chosen,changed}:{mode:'catalog',profile:chosen}}
 if(id===undefined){const match=models.find(p=>!profileDifferences(values,p).length);if(match)return {mode:'catalog',profile:match}}
 return {mode:'generic'};
}
// Patch that selects a catalog model (its settings plus the remembered choice).
export const chooseModel=(category:Category,p:Profile)=>({...(p.apply??{}),[PROFILE_KEY[category]]:p.id,[PROFILE_KEY[category]+'_base']:undefined});
// Patch that switches to a generic model, keeping every current dimension editable.
export const chooseGeneric=(category:Category,basedOn?:Profile)=>({[PROFILE_KEY[category]]:GENERIC,[PROFILE_KEY[category]+'_base']:basedOn?.id});

// Settings a generic drawer slide exposes, in the order a maker's drawing lists them.
export const SLIDE_BODY=['metal_slide_length','metal_slide_clearance_per_side','metal_slide_front_setback','metal_slide_envelope_height','slide_supported_travel','slide_load_rating_kg','equipment_mass_kg'];
export const SLIDE_HOLES=['include_metal_slide_holes','metal_slide_hole_pattern_mode','metal_slide_first_hole_from_front','metal_slide_hole_spacing','metal_slide_hole_count','metal_slide_cabinet_holes_x','metal_slide_drawer_holes_x','hardware_drilling_mode','metal_slide_cabinet_hole_diameter','metal_slide_drawer_hole_diameter','metal_slide_cabinet_hole_z_from_drawer_bottom','metal_slide_drawer_hole_z_from_drawer_bottom','metal_slide_hole_rear_margin','slide_drill_depth'];
export const HINGE_PLACEMENT=['hinge_count','hinge_end_offset'];
export const HINGE_DOOR=['hinge_cup_diameter','hinge_cup_depth','hinge_cup_center_from_door_edge','hinge_door_fixing_enabled','hinge_door_fixing_hole_diameter','hinge_door_fixing_hole_spacing','hinge_door_fixing_hole_offset'];
export const HINGE_CABINET=['hinge_plate_holes_enabled','hinge_plate_hole_diameter','hinge_plate_center_from_front','hinge_plate_hole_spacing'];
export const isWoodRunnerKey=(k:string)=>/^(wood_|custom_wood_|standalone_.*wood)/.test(k)||k==='include_wood_slide_registration_holes';
export const isFixedRunnerKey=(k:string)=>/^runner_/.test(k);
// Every setting the hardware panel presents; the Hardware section lists the rest as usual.
export const HARDWARE_PANEL_KEYS=(k:string)=>['drawer_mount','slide_type','hinge_style','metal_slide_hole_diameter',...SLIDE_BODY,...SLIDE_HOLES,...HINGE_PLACEMENT,...HINGE_DOOR,...HINGE_CABINET].includes(k)||isWoodRunnerKey(k)||isFixedRunnerKey(k);

// --- Hole positions -------------------------------------------------------------------------
// Even spacing or the maker's list; a listed pattern is thinned by the drilling mode.
export function selectHoles(holes:number[],mode='recommended'){
 if(holes.length<=2||mode==='all')return holes;
 if(mode==='minimum')return [holes[0],holes[holes.length-1]];
 return holes.length<=3?holes:[holes[0],holes[Math.floor((holes.length-1)/2)],holes[holes.length-1]];
}
export function slideHoles(v:Values,board:'cabinet'|'drawer'){
 if(v.metal_slide_hole_pattern_mode==='explicit_array')return selectHoles((board==='cabinet'?v.metal_slide_cabinet_holes_x:v.metal_slide_drawer_holes_x)??[],v.hardware_drilling_mode);
 const n=Math.max(1,Math.round(Number(v.metal_slide_hole_count)||0));
 return Array.from({length:n},(_,i)=>Number(v.metal_slide_first_hole_from_front)+i*Number(v.metal_slide_hole_spacing));
}
export type Hole={y:number;z:number;d:number;drilled:boolean};
// Holes on the outside face of a drawer-box side, from the box front (y) and box bottom (z).
// A hole beyond the slide (or the box) minus the rear margin is not drilled, as in the engine.
export function drawerSideHoles(v:Values,boxDepth:number):Hole[]{
 if(!v.include_metal_slide_holes)return [];
 const setback=Number(v.metal_slide_front_setback),limit=Math.min(Number(v.metal_slide_length),boxDepth)-Number(v.metal_slide_hole_rear_margin);
 return slideHoles(v,'drawer').map(x=>({y:setback+x,z:Number(v.metal_slide_drawer_hole_z_from_drawer_bottom),d:Number(v.metal_slide_drawer_hole_diameter),drilled:setback+x<=limit}));
}
// Hinge heights from the bottom of a door of height h.
export function hingeHeights(v:Values,h:number){
 const n=Math.max(0,Math.round(Number(v.hinge_count)||0)),e=Number(v.hinge_end_offset);
 if(n<=0)return [];
 return n===1?[h/2]:Array.from({length:n},(_,j)=>e+j*(h-2*e)/(n-1));
}
export type DoorDrilling={cups:{x:number;z:number;d:number}[];fixing:{x:number;z:number;d:number}[]};
// Cups and fixing holes on the inside face of a door, x from the door's left edge as seen from
// the front, z from its bottom edge.
export function doorDrilling(v:Values,w:number,h:number,hingeSide:'left'|'right'):DoorDrilling{
 if(!v.hinge_style||v.hinge_style==='none')return {cups:[],fixing:[]};
 const c=Number(v.hinge_cup_center_from_door_edge),cx=hingeSide==='left'?c:w-c,dir=hingeSide==='left'?1:-1;
 const zs=hingeHeights(v,h),s=Number(v.hinge_door_fixing_hole_spacing)/2,fx=cx+dir*Number(v.hinge_door_fixing_hole_offset??0);
 return {
  cups:v.hinge_style==='euro_35mm'?zs.map(z=>({x:cx,z,d:Number(v.hinge_cup_diameter)})):[],
  fixing:v.hinge_door_fixing_enabled?zs.flatMap(z=>[{x:fx,z:z-s,d:Number(v.hinge_door_fixing_hole_diameter)},{x:fx,z:z+s,d:Number(v.hinge_door_fixing_hole_diameter)}]):[],
 };
}

// --- Engine side-panel features -------------------------------------------------------------
// FEATURE records (system report "verbose") list every hole the engine drills in a cabinet side:
// Y is the distance from the side's front edge, Z the height, R the radius.
export type SideFeature={id:string;part:string;kind:string;source:string;y:number;z:number;d:number};
export function sideFeatures(recs:string[]):SideFeature[]{
 const out:SideFeature[]=[];
 for(const r of recs){
  if(!r.startsWith('FEATURE|'))continue;
  const kv:Record<string,string>={};for(const p of r.split('|').slice(1)){const i=p.indexOf('=');if(i>0)kv[p.slice(0,i)]=p.slice(i+1)}
  // Equipment stands report their slide holes in their own format (X along the depth, Y up).
  if(kv.OWNER&&kv.X!==undefined){out.push({id:kv.ID,part:kv.OWNER==='SIDE_L'?'CS-L':'CS-R',kind:'through_hole',source:'metal_slide',y:Number(kv.X),z:Number(kv.Y),d:Number(kv.D)});continue}
  if(kv.SHAPE!=='circle')continue;
  out.push({id:kv.ID,part:kv.PART,kind:kv.KIND,source:kv.SOURCE,y:Number(kv.CY),z:Number(kv.CZ),d:2*Number(kv.R)});
 }
 return out.filter(f=>[f.y,f.z,f.d].every(Number.isFinite));
}
// Slide holes on one cabinet side, grouped per slide (one row of holes per drawer).
export function slideRows(features:SideFeature[],part:string){
 const rows=new Map<string,SideFeature[]>();
 for(const f of features.filter(f=>f.part===part&&/slide/.test(f.source))){const key=f.id.match(/^(.*?\.\d+)\.-?\d+(?:\.\d+)?$/)?.[1]??f.id;rows.set(key,[...(rows.get(key)??[]),f])}
 return [...rows].map(([id,holes])=>({id,holes:holes.sort((a,b)=>a.y-b.y),z:holes[0].z}));
}

// --- Scenes for the Hardware view -------------------------------------------------------------
export type DrawerRef={id:string;x:number;w:number;bottom:number;box:{w:number;h:number;d:number}};
// Drawers with their box size and the height of the box bottom above the cabinet bottom
// (opening bottom plus the vertical running clearance, as the engine places the box).
export function drawerRefs(plan:Plan|null|undefined):DrawerRef[]{
 if(!plan)return [];
 const fronts=new Map((plan.layout?.fronts??[]).filter(f=>f.kind==='drawer').map(f=>[f.id,f]));
 return plan.drawers.map(d=>{const f=fronts.get(d.id),openZ=f?.open?.z??f?.z;return {id:d.id,x:f?.x??0,w:f?.w??d.opening.w,bottom:openZ===undefined?NaN:openZ+(Number.isFinite(d.vertical)?d.vertical:0),box:d.box}});
}
export type DoorRef={id:string;x:number;z:number;w:number;h:number;hinge:'left'|'right'};
export function doorRefs(plan:Plan|null|undefined):DoorRef[]{
 const fronts=(plan?.layout?.fronts??[]).filter(f=>f.kind==='door');
 if(fronts.length)return fronts.map(f=>({id:f.id,x:f.x,z:f.z,w:f.w,h:f.h,hinge:f.hinge==='right'?'right':'left'}));
 return (plan?.doors??[]).map(d=>({id:d.id,x:0,z:0,w:d.w,h:d.h,hinge:d.hinge==='right'?'right':'left'}));
}
// Drawers whose slides mount on this cabinet side: the column nearest that side.
export function drawersOnSide(drawers:DrawerRef[],part:string){
 if(!drawers.length)return [];
 const left=part==='CS-L',edge=left?Math.min(...drawers.map(d=>d.x)):Math.max(...drawers.map(d=>d.x+d.w));
 return drawers.filter(d=>Math.abs((left?d.x:d.x+d.w)-edge)<1);
}
export type SlideRow={id:string;drawer?:string;bottom:number;z:number;holes:{y:number;z:number;d:number}[];engine:boolean};
// One row per slide on a cabinet side. Hole positions come from the engine's feature ledger when it
// has reported them; otherwise (holes off, or before the first check) they are worked out from the
// settings the same way the engine does and marked as estimates.
export function cabinetSlideRows(v:Values,features:SideFeature[],drawers:DrawerRef[],part:string,sideDepth:number):SlideRow[]{
 const cabZ=Number(v.metal_slide_cabinet_hole_z_from_drawer_bottom),setback=Number(v.metal_slide_front_setback);
 const limit=Math.min(Number(v.metal_slide_length),sideDepth)-Number(v.metal_slide_hole_rear_margin);
 const estimated:SlideRow[]=drawersOnSide(drawers,part).filter(d=>Number.isFinite(d.bottom)).map(d=>({id:'estimate.'+d.id,drawer:d.id,bottom:d.bottom,z:d.bottom+cabZ,engine:false,
  holes:v.include_metal_slide_holes?slideHoles(v,'cabinet').map(x=>setback+x).filter(y=>y<=limit).map(y=>({y,z:d.bottom+cabZ,d:Number(v.metal_slide_cabinet_hole_diameter)})):[]}));
 const engine=slideRows(features.filter(f=>f.source==='metal_slide'),part);
 if(!engine.length)return estimated;
 const rows=engine.map(r=>{const bottom=r.z-cabZ,match=estimated.find(e=>Math.abs(e.bottom-bottom)<1);return {id:r.id,drawer:match?.drawer,bottom,z:r.z,engine:true,holes:r.holes.map(h=>({y:h.y,z:h.z,d:h.d}))}});
 return [...rows,...estimated.filter(e=>!rows.some(r=>r.drawer===e.drawer))].sort((a,b)=>b.bottom-a.bottom);
}
export type HingePlate={id:string;y:number;z:number;holes:{y:number;z:number;d:number}[]};
// Mounting-plate holes on a cabinet side, one entry per hinge (its holes' midpoint).
export function cabinetHingePlates(features:SideFeature[],part:string):HingePlate[]{
 const plates=new Map<string,SideFeature[]>();
 for(const f of features.filter(f=>f.part===part&&/hinge_plate/.test(f.source))){const key=f.id.replace(/\.[12]$/,'');plates.set(key,[...(plates.get(key)??[]),f])}
 return [...plates].map(([id,h])=>({id,y:h.reduce((s,x)=>s+x.y,0)/h.length,z:h.reduce((s,x)=>s+x.z,0)/h.length,holes:h.map(x=>({y:x.y,z:x.z,d:x.d}))})).sort((a,b)=>a.z-b.z);
}
// Plates on the cabinet side that belong to a door: hinge heights within the door's height.
export function platesForDoor(plates:HingePlate[],door:DoorRef){return plates.filter(p=>p.z>=door.z-0.5&&p.z<=door.z+door.h+0.5)}
