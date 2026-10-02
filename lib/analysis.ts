// Turns one OpenSCAD `bom` run (logs + report) into the plan shown in the app:
// a grouped cut list, sheet-material totals, fit checks and design issues.
// Everything here is read from engine records; nothing is re-derived from settings.
import {designHealth} from './manufacturing';

export type Issue={severity:'error'|'warning'|'note';code:string;message:string};
export type CutRow={ids:string[];name:string;category:string;material:string;thickness:number;width:number;height:number;qty:number;notes:string};
export type MaterialTotal={material:string;thickness:number;parts:number;area:number};
export type DrawerFit={id:string;opening:{w:number;h:number};box:{w:number;h:number;d:number};inside:{w:number;h:number;d:number};side:number;vertical:number;face?:{w:number;h:number};ok:boolean;problem?:string};
export type DoorFit={id:string;w:number;h:number;mount:string;hinge:string};
export type ShelfFit={id:string;style:string;span?:number;cut:number;depth:number};
export type SectionFit={id:string;w:number;h:number;contents:string};
// Front elevation reported by the engine (LAYOUT records), in cabinet coordinates:
// X from the left outside face, Z from the cabinet bottom, millimeters.
export type LayoutRect={x:number;z:number;w:number;h:number};
export type LayoutFront=LayoutRect&{id:string;kind:'drawer'|'door';bay:number;index:number;nominal?:number;open?:{z:number;h:number};hinge?:string;face?:string};
export type LayoutReport={
 cabinet:{w:number;h:number;t:number;open:LayoutRect;content:{z:number;h:number};mode:string};
 faceFrame?:{z0:number;z1:number;stile:number;bottomRail:number;topRail:number;mid?:[number,number];centerStile:number};
 bays:(LayoutRect&{index:number;type:string})[];banks:{index:number;x:number;w:number}[];doorRegion?:{z:number;h:number};
 fronts:LayoutFront[];shelves:{id:string;bay:number;x:number;w:number;z:number;style:string}[];
 members:(LayoutRect&{id:string;kind:string})[];sections:(LayoutRect&{index:number;contents:string})[];
};
export type Plan={
 outside?:{w:number;h:number;d:number};interior?:{w:number;h:number;d:number};
 cut:CutRow[];materials:MaterialTotal[];drawers:DrawerFit[];doors:DoorFit[];shelves:ShelfFit[];sections:SectionFit[];
 issues:Issue[];hardware:{id:string;qty:string;note:string}[];target?:Record<string,number>;partCount:number;layout?:LayoutReport;
 status:'PASS'|'WARN'|'ERROR'|'UNVERIFIED';
};

const PART_NAMES:Record<string,string>={
 back:'Back panel',back_structural:'Structural back',applied:'Back panel',structural:'Structural back',base_mounting_plate:'Base mounting plate',worktop:'Worktop',
 shelf_fixed:'Fixed shelf',shelf_adjustable:'Adjustable shelf',mixed_bay_partition:'Bay partition',drawer_face:'Drawer face',
 drawer_rail:'Drawer rail (cabinet side)',drawer_runner:'Drawer runner (drawer side)',drawer_side:'Drawer box side',drawer_front_box:'Drawer box front',
 drawer_back_box:'Drawer box back',drawer_bottom:'Drawer bottom',toe_kick:'Toe kick',divider:'Horizontal divider',door:'Door',
 stack_base_side:'Stack base side',stack_base_cross:'Stack base cross member',face_frame_stile:'Face-frame stile',face_frame_rail:'Face-frame rail',
 section_shelf:'Section rail or shelf',section_partition:'Section partition',side:'Side',tray:'Pull-out tray',cheek:'Tray cheek',lip:'Tray lip',
 drawer_divider_longitudinal:'Drawer divider (front to back)',drawer_divider_transverse:'Drawer divider (side to side)',cleat_stand:'French cleat (on stand)',
 cleat_wall:'French cleat (on wall)',backer:'Cleat backer',spacer:'Stabilizer',runner:'Tray runner',
};
const CARCASS_NAMES:Record<string,string>={'CS-L':'Left side','CS-R':'Right side',BOTTOM:'Bottom',TOP:'Top','TOP-F':'Front top stretcher','TOP-R':'Rear top stretcher',BASE:'Base',TOP_FRONT:'Front top rail',TOP_REAR:'Rear top rail',UPPER_SHELF:'Upper shelf'};
export const MATERIAL_NAMES:Record<string,string>={CARCASS:'Carcass',BACK:'Back',DRAWER_WALL:'Drawer boxes',DRAWER_BOTTOM:'Drawer bottoms',DRAWER_FRONT:'Drawer faces',DOOR:'Doors',FACE_FRAME:'Face frame',WOOD_RAIL:'Drawer rails',WOOD_RUNNER:'Drawer runners',WORKTOP:'Worktop',DRAWER_DIVIDER:'Drawer dividers',plywood:'Sheet stock'};
const human=(s:string)=>s.replace(/_/g,' ').replace(/^\w/,c=>c.toUpperCase());
export function partName(id:string,category:string){
 if(CARCASS_NAMES[id])return CARCASS_NAMES[id];
 if(category==='carcass')return human(id.toLowerCase());
 if(category==='horizontal')return CARCASS_NAMES[id]??human(id.toLowerCase());
 return PART_NAMES[category]??human(category);
}

// ECHO payload records ("ECHO: \"KIND|...\"") from a log; legacy multi-value echoes are flattened.
export function records(text:string){
 return [...new Set(text.split(/\r?\n/).flatMap(line=>{const m=line.match(/^ECHO: "([A-Z_]+\|.*)"\s*$/);return m?[m[1]]:[]}))];
}
function fields(record:string){
 const out:Record<string,string>={},plain:string[]=[];
 for(const p of record.split('|')){const i=p.indexOf('=');if(i>0)out[p.slice(0,i)]=p.slice(i+1);else plain.push(p)}
 return {kv:out,plain};
}
const num=(s:string|undefined)=>s===undefined||s===''?NaN:Number(s);

// Engine and OpenSCAD messages that a user should see, de-duplicated and labeled.
export function issues(text:string):Issue[]{
 const out:Issue[]=[];const seen=new Set<string>();
 const add=(i:Issue)=>{const k=i.severity+i.code+i.message;if(!seen.has(k)){seen.add(k);out.push(i)}};
 for(const c of designHealth(text).checks){
  if(c.severity==='ERROR')add({severity:'error',code:c.code,message:c.message});
  else if(c.severity==='WARN')add({severity:'warning',code:c.code,message:c.message});
 }
 for(const line of text.split(/\r?\n/)){
  let m;
  if((m=line.match(/^ERROR: (.*)$/)))add({severity:'error',code:'OPENSCAD',message:m[1]});
  else if((m=line.match(/^WARNING: (undefined operation|Ignoring unknown variable|.*could not be converted|.*undefined)(.*)$/)))
   add({severity:'error',code:'ENGINE_EVALUATION',message:'The cabinet engine evaluated an undefined value ('+(m[1]+m[2]).replace(/ in file .*$/,'')+'). Dimensions may be wrong; please report this configuration.'});
  else if((m=line.match(/^ECHO: "WARNING: ?(.*)$/)))add({severity:'warning',code:'ENGINE_NOTE',message:m[1].replace(/", ?/g,'').replace(/, "/g,'').replace(/"$/,'').replace(/\s+/g,' ').trim()});
  else if((m=line.match(/^ECHO: "WARN\|([A-Z_]+)\|?(.*)"$/)))add({severity:'warning',code:m[1],message:m[2].replace(/\|/g,' · ')});
 }
 return out;
}

export function analyse(text:string):Plan{
 const recs=records(text);
 const plan:Plan={cut:[],materials:[],drawers:[],doors:[],shelves:[],sections:[],issues:issues(text),hardware:[],partCount:0,status:designHealth(text).status as Plan['status']};
 const groups=new Map<string,CutRow>();
 for(const r of recs.filter(r=>r.startsWith('BOM|'))){
  const a=r.split('|').slice(1);
  const [id,qty,category,material,t,w,h]=a,notes=a.slice(7).join('|');
  const q=Number(qty),T=Number(t),W=Number(w),H=Number(h);
  if(![q,T,W,H].every(Number.isFinite)){plan.issues.push({severity:'error',code:'BOM_UNDEFINED',message:`Part ${id} has an undefined size (${t} × ${w} × ${h}). It is left out of the cut list.`});continue}
  plan.partCount+=q;
  const name=partName(id,category),key=JSON.stringify([name,category,material,T,W,H,notes]);
  const g=groups.get(key);
  if(g){g.ids.push(id);g.qty+=q}else groups.set(key,{ids:[id],name,category,material,thickness:T,width:W,height:H,qty:q,notes});
 }
 plan.cut=[...groups.values()];
 const totals=new Map<string,MaterialTotal>();
 for(const c of plan.cut){
  const k=c.material+'|'+c.thickness,m=totals.get(k)??{material:c.material,thickness:c.thickness,parts:0,area:0};
  m.parts+=c.qty;m.area+=c.qty*c.width*c.height;totals.set(k,m);
 }
 plan.materials=[...totals.values()].sort((a,b)=>b.area-a.area);
 const drawers=new Map<string,Partial<DrawerFit>&{id:string}>(),faces=new Map<string,{w:number;h:number}>();
 for(const r of recs){
  const {kv,plain}=fields(r);
  if(plain[0]==='DIM'&&plain[1]==='CABINET'&&plain[2]==='OUTSIDE')plan.outside={w:num(kv.W),h:num(kv.H),d:num(kv.D)};
  else if(plain[0]==='DIM'&&plain[1]==='CABINET'&&plain[2]==='CLEAR_INTERIOR')plan.interior={w:num(kv.W),h:num(kv.H),d:num(kv.D)};
  else if(plain[0]==='DIM'&&plain[1]==='equipment_stand')plan.outside={w:num(kv.W),h:num(kv.H),d:num(kv.D)};
  else if(plain[0]==='DIM'&&plain[1]==='DRAWER'&&plain[2]){
   const d=drawers.get(plain[2])??{id:plain[2]};
   if(plain[3]==='OUTSIDE')d.box={w:num(kv.W),h:num(kv.H),d:num(kv.D)};
   if(plain[3]==='INSIDE_CLEAR')d.inside={w:num(kv.W),h:num(kv.H),d:num(kv.D)};
   if(plain[3]==='OPENING'){d.opening={w:num(kv.W),h:num(kv.H)};d.side=num(kv.SIDE_CLEAR_PER_SIDE);d.vertical=num(kv.VERT_CLEAR_PER_SIDE)}
   drawers.set(plain[2],d);
  }
  else if(plain[0]==='DIM'&&plain[1]==='DRAWER_FACE'&&plain[2])faces.set(plain[2].replace(/-FACE$/,''),{w:num(kv.W),h:num(kv.H)});
  else if(plain[0]==='DIM'&&plain[1]==='DOOR'&&plain[2])plan.doors.push({id:plain[2],w:num(kv.W),h:num(kv.H),mount:kv.MOUNT??'',hinge:kv.HINGE??''});
  else if(plain[0]==='DIM'&&plain[1]==='SHELF'&&plain[2])plan.shelves.push({id:plain[2],style:kv.STYLE??'',span:kv.CLEAR_SPAN_W?num(kv.CLEAR_SPAN_W):undefined,cut:num(kv.CUT_W),depth:num(kv.D)});
  else if(plain[0]==='DIM'&&plain[1]==='SECTION'&&plain[2])plan.sections.push({id:plain[2],w:num(kv.W),h:num(kv.H),contents:kv.CONTENTS??''});
  else if(plain[0]==='HARDWARE')plan.hardware.push({id:kv.ID??'',qty:kv.QTY??'',note:[kv.UNIT,kv.LENGTH&&'length '+kv.LENGTH+' mm',kv.NOTE].filter(Boolean).join(' · ')});
  else if(plain[0]==='TARGET'&&(plain[1]==='DRAWER_INSIDE'||plain[1]==='DRAWER_DESIGN')){
   plan.target={};for(const [k,v] of Object.entries(kv))if(Number.isFinite(Number(v)))plan.target[k]=Number(v);
  }
 }
 plan.layout=layoutReport(recs);
 for(const d of drawers.values()){
  if(!d.box||!d.opening)continue;
  const side=Number.isFinite(d.side)?d.side!:0,vertical=Number.isFinite(d.vertical)?d.vertical!:0;
  const widthGap=d.opening.w-d.box.w-2*side,needH=d.box.h+2*vertical;
  let problem:string|undefined;
  if(side<0||Math.abs(widthGap)>0.05)problem='Box width plus slide clearance does not match the opening';
  else if(needH>d.opening.h+0.01)problem='Box plus vertical clearance is taller than the opening';
  plan.drawers.push({id:d.id,opening:d.opening,box:d.box,inside:d.inside??{w:NaN,h:NaN,d:NaN},side,vertical,face:faces.get(d.id),ok:!problem,problem});
 }
 if(plan.drawers.some(d=>!d.ok))for(const d of plan.drawers.filter(d=>!d.ok))
  plan.issues.push({severity:'error',code:'DRAWER_FIT',message:`Drawer ${d.id}: ${d.problem}.`});
 if(plan.issues.some(i=>i.severity==='error'))plan.status='ERROR';
 else if(plan.status==='PASS'&&plan.issues.some(i=>i.severity==='warning'))plan.status='WARN';
 return plan;
}

export function layoutReport(recs:string[]):LayoutReport|undefined{
 let report:LayoutReport|undefined;
 const rect=(kv:Record<string,string>):LayoutRect=>({x:num(kv.X),z:num(kv.Z),w:num(kv.W),h:num(kv.H)});
 const sections:LayoutReport['sections']=[];
 for(const r of recs){
  const {kv,plain}=fields(r);
  if(plain[0]==='DIM'&&plain[1]==='SECTION'&&plain[2])sections.push({...rect(kv),index:Number(plain[2].replace(/^S/,''))-1,contents:kv.CONTENTS??''});
  if(plain[0]!=='LAYOUT')continue;
  if(plain[1]==='CABINET'){report={cabinet:{w:num(kv.W),h:num(kv.H),t:num(kv.T),open:{x:num(kv.OPEN_X),z:num(kv.OPEN_Z),w:num(kv.OPEN_W),h:num(kv.OPEN_H)},content:{z:num(kv.CONTENT_Z),h:num(kv.CONTENT_H)},mode:kv.MODE??''},bays:[],banks:[],fronts:[],shelves:[],members:[],sections:[]};continue}
  if(!report)continue;
  if(plain[1]==='FACE_FRAME')report.faceFrame={z0:num(kv.Z0),z1:num(kv.Z1),stile:num(kv.STILE_W),bottomRail:num(kv.BOTTOM_RAIL_W),topRail:num(kv.TOP_RAIL_W),mid:num(kv.MID_Z0)>=0?[num(kv.MID_Z0),num(kv.MID_Z1)]:undefined,centerStile:num(kv.CENTER_STILE_W)};
  else if(plain[1]==='BAY')report.bays.push({...rect(kv),index:Number(plain[2].replace(/^B/,''))-1,type:kv.TYPE??''});
  else if(plain[1]==='BANK')report.banks.push({index:Number(plain[2].replace(/^B/,''))-1,x:num(kv.X),w:num(kv.W)});
  else if(plain[1]==='DOOR_REGION')report.doorRegion={z:num(kv.Z),h:num(kv.H)};
  else if(plain[1]==='FRONT')report.fronts.push({...rect(kv),id:plain[2],kind:kv.KIND==='door'?'door':'drawer',bay:Number(kv.BAY),index:Number(kv.INDEX),nominal:kv.NOMINAL_H?num(kv.NOMINAL_H):undefined,open:kv.OPEN_Z?{z:num(kv.OPEN_Z),h:num(kv.OPEN_H)}:undefined,hinge:kv.HINGE,face:kv.FACE});
  else if(plain[1]==='SHELF')report.shelves.push({id:plain[2],bay:Number(kv.BAY),x:num(kv.X),w:num(kv.W),z:num(kv.Z),style:kv.STYLE??''});
  else if(plain[1]==='MEMBER')report.members.push({...rect(kv),id:plain[2],kind:kv.KIND??''});
 }
 if(report)report.sections=sections;
 else if(sections.length){
  // Section layouts report their openings through DIM|SECTION; the cabinet frame comes from DIM|CABINET.
  let open:LayoutRect|undefined,w=NaN,h=NaN;
  for(const r of recs){const {kv,plain}=fields(r);if(plain[0]==='DIM'&&plain[1]==='CABINET'&&plain[2]==='OUTSIDE'){w=num(kv.W);h=num(kv.H)}if(plain[0]==='DIM'&&plain[1]==='CABINET'&&plain[2]==='FRONT_OPENING')open={x:NaN,z:num(kv.BOTTOM_Z),w:num(kv.W),h:num(kv.H)}}
  if(open&&!Number.isFinite(open.x))open.x=(w-open.w)/2;
  const root=sections.find(s=>s.index===0);
  report={cabinet:{w,h,t:NaN,open:root?{x:root.x,z:root.z,w:root.w,h:root.h}:open??{x:NaN,z:NaN,w:NaN,h:NaN},content:{z:NaN,h:NaN},mode:'sections'},bays:[],banks:[],fronts:[],shelves:[],members:[],sections};
 }
 return report;
}

export function cutListCsv(plan:Plan){
 const q=(v:unknown)=>'"'+String(v).replaceAll('"','""')+'"';
 const rows=[['Part','IDs','Qty','Material','Thickness mm','Cut W mm','Cut H mm','Notes'],...plan.cut.map(c=>[c.name,c.ids.join(' '),c.qty,MATERIAL_NAMES[c.material]??c.material,c.thickness,c.width,c.height,c.notes])];
 return rows.map(r=>r.map(q).join(',')).join('\r\n')+'\r\n';
}
