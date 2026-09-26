import schema from './schema.json';
import bundledSources from './engine-sources.json';
export const engineSources:Record<string,string>=bundledSources;
export const renderSources=Object.entries(engineSources).filter(([name])=>name.endsWith('.scad')).map(([name,text])=>({name,text}));
export type Values=Record<string,any>;
import type {Field} from './settings';
export type Starter={id:string;name:string;values:Values;group?:string};
export const families=[{name:'Shop cart',sub:'Mobile storage & workbenches',code:'SC / MO5'},{name:'Utility cabinet',sub:'Floor & wall cabinets',code:'UC / MO5'},{name:'Benchtop drawers',sub:'Small parts, organized',code:'BT / MO5'},{name:'Stackable cabinet',sub:'Interlocking storage modules',code:'ST / MO5'},{name:'Kitchen cabinet',sub:'US nominal base, wall & pantry sizes',code:'KC / MO5'},{name:'Standalone drawer',sub:'Replacement drawers & custom storage',code:'DR / MO5'},{name:'Equipment stand',sub:'Pull-out trays, printer towers & French cleats',code:'ES / MO5'}];
export const schemas=schema as unknown as {id:string;file:string;groups:string[];capabilities:Record<string,boolean|string>;fields:Field[];defaultStarter:string;starters:Starter[]}[];
// Legacy aliases are confined to the schematic adapter. Public inputs remain direct.
export const legacyKeys:Record<string,string>={custom_cabinet_width:'cabinet_width',custom_cabinet_height:'cabinet_height',custom_cabinet_depth:'cabinet_depth',custom_cabinet_contents:'cabinet_contents',custom_drawer_count:'drawer_count',custom_door_count:'door_count',custom_top_style:'top_style',custom_shelf_style:'shelf_style',custom_door_shelf_count:'door_shelf_count',custom_module_type:'module_type'};
export function normalizeValues(family:number,values:Values):Values{
 const v:Values={...values,_family:family};
 // Older kitchen recipes only supplied one bay. Extend missing entries while
 // preserving every explicitly configured type and width weight.
 if(family===4&&v.cabinet_layout_mode==='mixed_bays'){
  const count=Math.max(1,Math.min(4,Number(v.mixed_bay_count)||1));
  for(const [key,fallback] of [['mixed_bay_types','drawers'],['mixed_bay_width_weights',1]] as const){
   const entries=Array.isArray(v[key])?[...v[key]]:[];
   while(entries.length<count)entries.push(key==='mixed_bay_types'?(entries.at(-1)??fallback):fallback);
   v[key]=entries;
  }
 }
 for(const [old,key] of Object.entries(legacyKeys))if(v[key]!==undefined)v[old]=v[key];
 if(family===4){const frame=v.front_facing_style==='face_frame'?thickness(v,'face_frame_stock','custom_face_frame_thickness'):0;const dado=frame&&v.face_frame_construction==='segmented_back_dado'?Math.min(Math.max(.5,Number(v.face_frame_back_dado_depth)),Math.max(.5,frame-.5)):0;v.custom_cabinet_depth=Math.max(50,Number(v.cabinet_nominal_depth)-frame+dado)}
 if(family===5){const t=thickness(v,'drawer_stock','custom_drawer_material_thickness'),bt=thickness(v,'drawer_bottom_stock','custom_drawer_bottom_thickness'),basis=v.drawer_design_basis;
 const clearance=v.drawer_mount==='metal_slides'?v.metal_slide_clearance_per_side:v.drawer_mount==='wood_rails'?Number(v.wood_rail_thickness)+Number(v.wood_rail_side_clearance):v.drawer_free_fit_clearance_per_side;
 const setback=v.drawer_face_style==='inset_flush'?Math.max(v.front_setback,thickness(v,'drawer_front_stock','custom_drawer_front_thickness')+Math.max(0,v.drawer_face_back_clearance)):v.front_setback;
 const w=basis==='enclosure'?v.enclosure_opening_width-2*clearance:basis==='inside_clear'?v.target_box_inside_width+2*t:basis==='modular_grid'?v.drawer_module_pitch_x*Math.max(1,Math.round(v.drawer_module_count_x))+2*Math.max(0,v.drawer_module_edge_clearance_x)+2*t:v.target_box_outside_width;
 const d=basis==='enclosure'?v.enclosure_usable_depth-setback-v.drawer_back_clearance:basis==='inside_clear'?v.target_box_inside_depth+2*t:basis==='modular_grid'?v.drawer_module_pitch_y*Math.max(1,Math.round(v.drawer_module_count_y))+2*Math.max(0,v.drawer_module_edge_clearance_y)+2*t:v.target_box_outside_depth;
 const h=basis==='outside_box'?v.target_box_outside_height:basis==='inside_clear'?v.target_box_inside_height+v.drawer_bottom_inset+bt:basis==='modular_grid'?v.drawer_module_inside_height+v.drawer_bottom_inset+bt:v.enclosure_height_mode==='fill_opening'?v.enclosure_opening_height-2*Math.max(0,v.drawer_vertical_clearance):v.enclosure_height_mode==='inside_clear'?v.enclosure_target_inside_height+v.drawer_bottom_inset+bt:v.enclosure_target_box_height;
 Object.assign(v,{custom_cabinet_width:w,custom_cabinet_depth:d,custom_cabinet_height:h,custom_cabinet_contents:'drawers'});
 }
 if(family===6){const t=Number(v.material_thickness),tt=Number(v.tray_thickness),sg=v.slide_type==='fixed_runner'?2:Number(v.metal_slide_clearance_per_side),pitch=tt+Number(v.device_height)+Number(v.top_clearance)+t;Object.assign(v,{custom_cabinet_width:v.sizing_mode==='equipment'?Number(v.device_width)+2*Number(v.side_clearance)+4*t+2*sg:Number(v.overall_width),custom_cabinet_depth:v.sizing_mode==='equipment'?Number(v.tray_inset)+Math.max(Number(v.device_depth)+(v.tray_lip_height>0?t:0)+(v.rear_cable_opening?Number(v.cable_opening_depth):0),Number(v.metal_slide_length)+Number(v.metal_slide_front_setback))+Number(v.rear_clearance)+t:Number(v.overall_depth),custom_cabinet_height:v.sizing_mode==='equipment'?t+Number(v.base_gap)+Number(v.tray_count)*pitch+(v.upper_bay_enabled?Number(v.upper_bay_height)+t:0):Number(v.overall_height)});}
 if(family===2)v.custom_cabinet_contents='drawers';
 if(family===3)Object.assign(v,{custom_cabinet_contents:v.module_type,cabinet_contents:v.module_type==='drawers'?'drawers':'doors',shelf_style:'adjustable',cabinet_layout_mode:v.module_type==='drawers'?'legacy':'mixed_bays',mixed_bay_count:1,mixed_bay_types:[v.module_type],mixed_bay_width_weights:[1],mixed_bay_drawer_counts:[v.drawer_count],mixed_bay_shelf_counts:[v.door_shelf_count??1],mixed_bay_door_counts:[1],custom_top_style:'stretchers',base_style:'flat',include_worktop:false});
 return v;
}
export function starterValues(family:number,id:string,current?:Values):Values{const base=current??Object.fromEntries(schemas[family].fields.map(f=>[f.key,f.value]));const starter=schemas[family].starters.find(s=>s.id===id);return normalizeValues(family,{...base,...(starter?.values??{}),_starter:id})}
export const defaults=(family:number):Values=>starterValues(family,schemas[family].defaultStarter);
export const label=(s:string)=>s.replace(/^custom_/,'').replace(/_/g,' ').replace(/\b\w/,c=>c.toUpperCase());
export function thickness(v:Values,key='carcass_stock',custom='custom_carcass_thickness') {if(v._family===6&&key==='carcass_stock')return Number(v.material_thickness);const n:Record<string,number>={'1/8_nominal':3.175,'1/4_nominal':6.35,'3/8_nominal':9.525,'1/2_nominal':12.7,'5/8_nominal':15.875,'3/4_nominal':19.05,'1_nominal':25.4};return n[v[key]]??Number(v[custom]??18)}
export function validate(v:Values){if(v._family===6)return [...(!Number.isInteger(v.tray_count)||v.tray_count<1||v.tray_count>4?['Tray count must be a whole number from 1 to 4.']:[]),...['width','height','depth'].filter(k=>!Number.isFinite(v['custom_cabinet_'+k])||v['custom_cabinet_'+k]<=0).map(k=>'Stand '+k+' must be positive.')];if(v._family===5)return ['width','height','depth'].filter(k=>!Number.isFinite(v['custom_cabinet_'+k])||v['custom_cabinet_'+k]<=0).map(k=>'Drawer '+k+' must resolve to a positive dimension.');const errors:string[]=[];for(const k of ['width','height','depth']){const n=Number(v['custom_cabinet_'+k]);if(!Number.isFinite(n)||n<100||n>3000)errors.push(label(k)+' must be between 100 and 3,000 mm.')}const t=thickness(v);if(t<=0||t>50)errors.push('Carcass thickness must be greater than 0 and at most 50 mm.');const bays=v.cabinet_layout_mode==='mixed_bays'?Number(v.mixed_bay_count):1;if(v.width_basis!=='drawer_inside'&&v.custom_cabinet_width< (bays+1)*t+bays*60)errors.push('Increase width to leave room for each bay.');return errors}
export type Part={id:string;name:string;x:number;y:number;z:number;w:number;d:number;h:number;color:string;group:string};
export function geometry(v:Values,interior:boolean,explode:boolean):Part[]{
 if(v._family===3&&v.module_type==='drawers'){const n=Math.max(1,Math.min(4,Number(v.drawer_bank_count)||1));v={...v,cabinet_layout_mode:'mixed_bays',mixed_bay_count:n,mixed_bay_types:Array(n).fill('drawers'),mixed_bay_width_weights:v.drawer_bank_width_weights,include_mixed_bay_partitions:true,mixed_bay_drawer_counts:Array.from({length:n},(_,i)=>v.drawer_bank_layout_mode==='independent'?(v.drawer_bank_drawer_counts?.[i]??v.drawer_count):v.drawer_count)}}

 const W=Number(v.custom_cabinet_width)||650,H=Number(v.custom_cabinet_height)||700,D=Number(v.custom_cabinet_depth)||500,t=thickness(v),parts:Part[]=[];
 const add=(id:string,name:string,x:number,y:number,z:number,w:number,d:number,h:number,color='#bd8e59',group='carcass')=>{if(w>0&&d>0&&h>0)parts.push({id,name,x,y,z,w,d,h,color,group})};
 if(v._family===5){const wall=thickness(v,'drawer_stock','custom_drawer_material_thickness'),bottom=thickness(v,'drawer_bottom_stock','custom_drawer_bottom_thickness'),e=explode?50:0;
 add('D1-SL','Left drawer side',-e,0,0,wall,D,H,'#bd8e59','drawer');add('D1-SR','Right drawer side',W-wall+e,0,0,wall,D,H,'#bd8e59','drawer');
 add('D1-FR','Drawer box front',wall,-e,0,W-2*wall,wall,H,'#bd8e59','drawer');add('D1-BK','Drawer box back',wall,D-wall+e,0,W-2*wall,wall,H,'#bd8e59','drawer');
 add('D1-BOT','Drawer bottom',wall,wall,Number(v.drawer_bottom_inset)-e,W-2*wall,D-2*wall,bottom,'#dbbf96','drawer');
 if(v.drawer_face_style!=='none'&&!interior){const ft=thickness(v,'drawer_front_stock','custom_drawer_front_thickness');add('D1-FACE','Decorative drawer face',0,-ft-e*2,0,v.drawer_face_size_mode==='custom'?v.custom_drawer_face_width:W,ft,v.drawer_face_size_mode==='custom'?v.custom_drawer_face_height:H,'#d4b182','front')}
 return parts;
 }
 if(v._family===6){const e=explode?60:0,tt=Number(v.tray_thickness),sg=v.slide_type==='fixed_runner'?2:Number(v.metal_slide_clearance_per_side),pitch=tt+Number(v.device_height)+Number(v.top_clearance)+t,td=D-Number(v.tray_inset)-Number(v.rear_clearance)-t,tw=W-2*t-2*sg;
 add('SIDE_L','Left side (solid envelope)',-e,0,0,t,D,H);add('SIDE_R','Right side (solid envelope)',W-t+e,0,0,t,D,H);add('BASE','Base',t,0,-e,W-2*t,D,t);
 if(!interior){if(v.top_style==='panel')add('TOP','Top',t,0,H-t+e,W-2*t,D,t);else{add('TOP_FRONT','Front top rail',t,0,H-t+e,W-2*t,v.back_rail_height,t);add('TOP_REAR','Rear top rail',t,D-v.back_rail_height,H-t+e,W-2*t,v.back_rail_height,t);}}
 if(v.upper_bay_enabled)add('UPPER_SHELF','Upper shelf',t,0,H-v.upper_bay_height-t,W-2*t,D,t);
 if(v.back_style==='panel'||v.back_style==='structural_panel')add(v.back_style==='panel'?'PANEL_BACK':'STRUCTURAL_BACK','Back',v.back_style==='panel'?0:t,D-(v.back_style==='panel'?0:t)+e,v.back_style==='panel'?0:t,v.back_style==='panel'?W:W-2*t,v.back_style==='panel'?v.custom_back_thickness:t,v.back_style==='panel'?H:H-2*t,'#a67d4c','back');
 const extension=v.slide_type==='fixed_runner'?0:Math.min(Math.max(0,Number(v.preview_extension)),Number(v.tray_extension));
 for(let i=0;i<Math.max(0,Math.min(4,Number(v.tray_count)));i++){const z=t+Number(v.base_gap)+i*pitch,y=Number(v.tray_inset)-extension-e;
 add('TRAY_'+(i+1),'Pull-out tray '+(i+1),t+sg,y,z,tw,td,tt,'#dbbf96','tray');add('CHEEK_L_'+(i+1),'Left tray cheek',t+sg,y,z+tt,t,td,v.tray_cheek_height,'#bd8e59','tray');add('CHEEK_R_'+(i+1),'Right tray cheek',W-t-sg-t,y,z+tt,t,td,v.tray_cheek_height,'#bd8e59','tray');if(v.tray_lip_height>0)add('LIP_'+(i+1),'Tray lip',2*t+sg,y,z+tt,tw-2*t,t,v.tray_lip_height,'#bd8e59','tray');}
 return parts;}
 const ex=explode?65:0,base=v._family===3?Number(v.stack_interface_depth??18):v.base_style==='toe_kick'?Number(v.custom_toe_kick_height??100):0;
 const back=v.back_style==='structural_panel'?t:v.back_style==='panel'?thickness(v,'back_stock','custom_back_thickness'):0;
 if(v.show_carcass_sides!==false){add('SIDE-L','Left side',-ex,0,0,t,D,H);add('SIDE-R','Right side',W-t+ex,0,0,t,D,H)}
 if(v.show_carcass_bottom!==false)add('BOTTOM','Bottom',v.bottom_width_style==='full_width'?0:t,0,base-ex,v.bottom_width_style==='full_width'?W:W-2*t,D,t);
 if(v.show_carcass_top!==false){if(v.custom_top_style==='full')add('TOP','Top',t,0,H-t+ex,W-2*t,D,t);else {add('TOP-F','Front stretcher',t,0,H-t+ex,W-2*t,70,t);add('TOP-R','Rear stretcher',t,D-70,H-t+ex,W-2*t,70,t)}}
 if(v.show_back_construction!==false){if(back)add('BACK','Back',t,D-back+ex,base+t,W-2*t,back,H-base-2*t,'#a0784e','back');else if(v.back_style==='stretchers'){add('BACK-U','Upper back rail',t,D-t,H-90,W-2*t,t,90);add('BACK-L','Lower back rail',t,D-t,base+t,W-2*t,t,90)}}
 if(v.include_worktop&&v.show_worktop!==false)add('WORKTOP','Worktop',-Number(v.worktop_side_overhang??20),-Number(v.worktop_front_overhang??25),H+ex*2,W+2*Number(v.worktop_side_overhang??20),D+Number(v.worktop_front_overhang??25)+Number(v.worktop_back_overhang??10),Number(v.worktop_thickness??38),'#d8b079','worktop');
 const mixed=v.cabinet_layout_mode==='mixed_bays',count=mixed?Math.max(1,Math.min(4,Number(v.mixed_bay_count))):1;
 const partitionThickness=mixed&&v.include_mixed_bay_partitions!==false?t:0;
 const weights=Array.from({length:count},(_,i)=>Math.max(.1,Number(v.mixed_bay_width_weights?.[i]??1))),total=weights.reduce((a,b)=>a+b,0);let x=t;
 for(let i=0;i<count;i++){
  const w=(W-2*t-(count-1)*partitionThickness)*weights[i]/total,type=mixed?v.mixed_bay_types?.[i]??'open':v.custom_cabinet_contents??'drawers';
  if(i&&partitionThickness&&v.show_mixed_bay_partitions!==false)add('DIV-'+i,'Bay divider',x-t,0,base+t,t,D-back,H-base-2*t);
  const dh=H-base-2*t;
  const draw=(z:number,height:number,n:number)=>{n=Math.max(1,Math.min(10,n));for(let j=0;j<n;j++){const h=height/n; const yy=explode?-ex*(j+1)/2:0;
   if(v.show_drawer_faces!==false&&!interior)add(`FRONT-${i}-${j}`,'Drawer front',x-7,-t-3+yy,z+j*h+2,w+14,t,h-4,'#d4b182','front');
   if(interior||explode){add(`DB-${i}-${j}`,'Drawer bottom',x+13,12+yy,z+j*h+12,w-26,Math.max(20,D-back-45),6,'#dbbf96','drawer');add(`DL-${i}-${j}`,'Drawer side',x+13,12+yy,z+j*h+18,12,Math.max(20,D-back-45),Math.max(10,h-45),'#cba77a','drawer');add(`DR-${i}-${j}`,'Drawer side',x+w-25,12+yy,z+j*h+18,12,Math.max(20,D-back-45),Math.max(10,h-45),'#cba77a','drawer')}
   if(!interior)add(`HANDLE-${i}-${j}`,'Pull',x+w/2-35,-t-14+yy,z+j*h+h*.6,70,10,7,'#394446','hardware');
  }};
  const shelves=(n:number,height=dh)=>{if(v.show_shelves!==false)for(let j=1;j<=Math.min(8,n);j++)add(`SHELF-${i}-${j}`,'Shelf',x,4,base+t+height*j/(n+1),w,D-back-8,t,'#c7a272','shelf')};
  if(type==='drawers'||type==='drawer')draw(base+t,dh,Number(mixed?v.mixed_bay_drawer_counts?.[i]??4:v.custom_drawer_count??4));
  else if(type==='combo'){draw(base+t+dh*.65,dh*.35,Number(v.custom_drawer_count??2));if(!interior)add('DOOR-'+i,'Door',x,-t-3,base+t,w,t,dh*.65-3,'#d4b182','front');shelves(Number(v.custom_door_shelf_count??1),dh*.65)}
  else {shelves(Number(mixed?v.mixed_bay_shelf_counts?.[i]??2:v.custom_door_shelf_count??1));if((type==='door'||type==='doors')&&!interior&&v.show_doors!==false){const n=Number(mixed?v.mixed_bay_door_counts?.[i]??1:v.custom_door_count??2);for(let j=0;j<n;j++){add(`DOOR-${i}-${j}`,'Door',x+j*w/n,-t-3,base+t,w/n-3,t,dh,'#d4b182','front');add(`PULL-${i}-${j}`,'Pull',x+j*w/n+w/n-30,-t-15,base+dh*.65,7,10,75,'#394446','hardware')}}}
  x+=w+partitionThickness;
 }
 if(v.show_base_hardware!==false&&(v.base_style==='casters'||v.base_style==='leveling_feet')){const h=Number(v.base_style==='casters'?v.caster_height??100:v.leveler_height??30);for(let a=0;a<2;a++)for(let b=0;b<2;b++){const x=a?W-75:40,y=b?D-75:40;add(`BASE-${a}-${b}`,'Base hardware',x,y,-h,35,45,h*.7,'#344144','hardware');add(`MOUNT-${a}-${b}`,'Mount',x-8,y-8,-h*.3,51,61,h*.3,'#707b7b','hardware')}}
 if(base&&v.base_style==='toe_kick')add('TOE','Toe kick',t,Number(v.custom_toe_kick_setback??65),0,W-2*t,t,base,'#8d6c49');if(v.front_facing_style==='face_frame'){const ft=thickness(v,'face_frame_stock','custom_face_frame_thickness'),dd=v.face_frame_construction==='segmented_back_dado'?Math.min(Math.max(.5,Number(v.face_frame_back_dado_depth)),Math.max(.5,ft-.5)):0,fw=Number(v.face_frame_side_stile_width??38.1),tr=Number(v.face_frame_top_rail_width??38.1),br=Number(v.face_frame_bottom_rail_width??38.1);add('FRAME-L','Face-frame stile',0,-ft+dd,base,fw,ft,H-base,'#a57a4b','frame');add('FRAME-R','Face-frame stile',W-fw,-ft+dd,base,fw,ft,H-base,'#a57a4b','frame');add('FRAME-T','Face-frame rail',fw,-ft+dd,H-tr,W-2*fw,ft,tr,'#a57a4b','frame');add('FRAME-B','Face-frame rail',fw,-ft+dd,base,W-2*fw,ft,br,'#a57a4b','frame');}
 if(v._family===3){const one=[...parts],count=Math.max(1,Math.min(8,Number(v.stack_preview_count??1))),step=H-Number(v.stack_interface_depth??18)+Number(v.stack_preview_explode_gap??0);for(let i=1;i<count;i++)for(const p of one)parts.push({...p,id:p.id+'-stack-'+i,z:p.z+i*step});}
 return parts;
}
export function applySettings(source:string,family:number,v:Values){
 for(const f of schemas[family].fields){const val=v[f.key];if(val!==undefined&&val!==null)source=source.replace(new RegExp('^('+f.key+'\\s*=\\s*)[^;]+;','m'),(_m,p)=>p+JSON.stringify(val)+';')}
 return source;
}
export async function configuredSource(family:number,v:Values,signal?:AbortSignal){
 signal?.throwIfAborted();return applySettings(engineSources[schemas[family].file],family,v);
}
export async function exportBundle(family:number,v:Values){
 const files=Object.keys(engineSources);
 const entries=files.map(name=>({name,data:name===schemas[family].file?applySettings(engineSources[name],family,v):engineSources[name]}));
 entries.push({name:'design.cabinet.json',data:JSON.stringify({version:2,engine:5,engineFamily:"modular_organization",bundleRevision:5,family,values:v},null,2)},{name:'START-HERE.txt',data:'Keep all files together. Open '+schemas[family].file+' in OpenSCAD. All selected settings are applied. The web Schematic view is approximate; the OpenSCAD render view evaluates actual 3D geometry. Use desktop OpenSCAD for manufacturing outputs.\n\nSet output_mode to assembly for inspection, cut_layout for through cuts, pocket_layout for blind machining, engrave_layout for labels, or bom for the bill of materials. Render and export SVG/DXF from OpenSCAD. Install Python dependencies with pip install ./v5. Use python -m modular_organization manufacture --help for desktop packages with the final CUT/POCKET contour audit; python -m modular_organization audit --help for standalone validation; python -m modular_organization bom --help for BOM conversion. Cut and pocket outputs share a registration frame. Confirm stock thickness and fit with test coupons.\n'});
 return zip(entries);
}
export function zip(files:{name:string,data:string}[]){const enc=new TextEncoder(),chunks:Uint8Array[]=[],central:Uint8Array[]=[];let offset=0;const crc=(b:Uint8Array)=>{let c=0xffffffff;for(const x of b){c^=x;for(let i=0;i<8;i++)c=c&1?0xedb88320^(c>>>1):c>>>1}return(c^0xffffffff)>>>0};for(const f of files){const name=enc.encode(f.name),data=enc.encode(f.data),check=crc(data);const a=new Uint8Array(30+name.length+data.length),v=new DataView(a.buffer);v.setUint32(0,0x04034b50,true);v.setUint16(4,20,true);v.setUint32(14,check,true);v.setUint32(18,data.length,true);v.setUint32(22,data.length,true);v.setUint16(26,name.length,true);a.set(name,30);a.set(data,30+name.length);chunks.push(a);const b=new Uint8Array(46+name.length),w=new DataView(b.buffer);w.setUint32(0,0x02014b50,true);w.setUint16(4,20,true);w.setUint16(6,20,true);w.setUint32(16,check,true);w.setUint32(20,data.length,true);w.setUint32(24,data.length,true);w.setUint16(28,name.length,true);w.setUint32(42,offset,true);b.set(name,46);central.push(b);offset+=a.length}const end=new Uint8Array(22),e=new DataView(end.buffer);e.setUint32(0,0x06054b50,true);e.setUint16(8,files.length,true);e.setUint16(10,files.length,true);e.setUint32(12,central.reduce((a,b)=>a+b.length,0),true);e.setUint32(16,offset,true);return new Blob([...chunks,...central,end] as BlobPart[],{type:'application/zip'})}
export function download(data:Blob,name:string){const url=URL.createObjectURL(data),a=document.createElement('a');a.href=url;a.download=name;a.click();setTimeout(()=>URL.revokeObjectURL(url),1000)}
