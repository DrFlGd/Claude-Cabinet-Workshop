'use client';
// Hardware view: where each drawer slide or hinge is drilled, on both boards it joins. The
// cabinet side shows the holes the engine reports in its side-panel feature ledger; the drawer
// box side and the door are drawn from the same settings the engine drills them with. Every
// edit redraws at once; cabinet-side positions are confirmed when the engine check finishes.
import {useMemo,useState,ReactNode} from 'react';
import {Info,LoaderCircle,CheckCircle2,TriangleAlert} from 'lucide-react';
import type {Values} from '@/lib/cabinet';
import {records} from '@/lib/analysis';
import type {Analysis} from './useEngineAnalysis';
import {formatShop,type Units} from '@/lib/units';
import * as H from '@/lib/hardware';

type Kind='slides'|'hinges';
type Dim={x1:number;y1:number;x2:number;y2:number;label:string;offset:number};
const round=(n:number)=>Math.round(n*100)/100;

// One board, drawn in millimeters with its front edge on the left: x runs from the front edge
// toward the back (or across a door), z up from the bottom edge.
function Board({title,note,w,h,children,dims,front='Front'}:{title:string;note:string;w:number;h:number;children:ReactNode;dims:Dim[];front?:string}){
 const size=Math.max(w,h),font=Math.max(size/34,8),pad=Math.max(size*0.08,font*3.2),right=Math.max(...dims.map(d=>d.x1===d.x2?d.offset:0),0)*font*1.6+font*5;
 const line=(d:Dim,i:number)=>{
  const horizontal=Math.abs(d.y1-d.y2)<1e-6,o=d.offset*font*1.6;
  const [x1,y1,x2,y2]=horizontal?[d.x1,h-d.y1+o,d.x2,h-d.y2+o]:[d.x1+o,h-d.y1,d.x2+o,h-d.y2];
  const mx=(x1+x2)/2,my=(y1+y2)/2,t=font*0.45;
  return <g key={i} className='hw-dim'>
   <line x1={x1} y1={y1} x2={x2} y2={y2}/>
   {horizontal?<><line x1={x1} y1={y1-t} x2={x1} y2={y1+t}/><line x1={x2} y1={y2-t} x2={x2} y2={y2+t}/></>:<><line x1={x1-t} y1={y1} x2={x1+t} y2={y1}/><line x1={x2-t} y1={y2} x2={x2+t} y2={y2}/></>}
   <text x={horizontal?mx:mx+(d.offset<0?-1:1)*font*0.4} y={horizontal?my-font*0.35:my} fontSize={font} textAnchor={horizontal?'middle':d.offset<0?'end':'start'} dominantBaseline={horizontal?'auto':'middle'}>{d.label}</text>
  </g>;
 };
 return <figure className='hw-board'>
  <figcaption><strong>{title}</strong><span>{note}</span></figcaption>
  <svg viewBox={`${-pad-Math.max(0,...dims.map(d=>d.x1===d.x2&&d.offset<0?-d.offset*font*1.6+font*5:0))} ${-pad} ${w+pad+right+Math.max(0,...dims.map(d=>d.x1===d.x2&&d.offset<0?-d.offset*font*1.6+font*5:0))} ${h+2*pad}`} role='img' aria-label={title}>
   <rect className='hw-panel' x={0} y={0} width={w} height={h}/>
   <text className='hw-front' x={-font*0.5} y={h/2} fontSize={font*0.85} textAnchor='middle' transform={`rotate(-90 ${-font*0.5} ${h/2})`}>{front}</text>
   {children}
   {dims.map(line)}
  </svg>
 </figure>;
}
const Hole=({x,z,d,h,min,className,title}:{x:number;z:number;d:number;h:number;min:number;className?:string;title:string})=><circle className={'hw-hole '+(className??'')} cx={x} cy={h-z} r={Math.max(d/2,min)}><title>{title}</title></circle>;

// Dimension chain along a row of holes: front edge to the first hole, then the spacing.
function rowDims(ys:number[],z:number,fmt:(n:number)=>string,offset:number,from=0):Dim[]{
 if(!ys.length)return [];
 const out:Dim[]=[{x1:from,y1:z,x2:ys[0],y2:z,label:fmt(ys[0]-from),offset}];
 const gaps=ys.slice(1).map((y,i)=>y-ys[i]),even=gaps.length>0&&gaps.every(g=>Math.abs(g-gaps[0])<0.01);
 if(even&&gaps.length>1)out.push({x1:ys[0],y1:z,x2:ys[ys.length-1],y2:z,label:gaps.length+' × '+fmt(gaps[0]),offset});
 else ys.slice(1).forEach((y,i)=>out.push({x1:ys[i],y1:z,x2:y,y2:z,label:fmt(y-ys[i]),offset}));
 return out;
}

export default function HardwareView({family,values,units,analysis,kind,setKind}:{family:number;values:Values;units:Units;analysis:Analysis;kind:Kind;setKind:(k:Kind)=>void}){
 const fmt=(n:number)=>formatShop(round(n),units)+(units==='mm'?' mm':'');
 const fresh=!!analysis.plan&&analysis.planKey===analysis.key,plan=analysis.plan;
 const features=useMemo(()=>H.sideFeatures(records(analysis.log||'')),[analysis.log]);
 const metal=family===6?values.slide_type!=='fixed_runner':values.drawer_mount==='metal_slides';
 const drawers=useMemo(()=>H.drawerRefs(plan),[plan]),doors=useMemo(()=>H.doorRefs(plan),[plan]);
 const hasSlides=metal&&(drawers.length>0||features.some(f=>f.source==='metal_slide'));
 const hasHinges=values.hinge_style&&values.hinge_style!=='none'&&doors.length>0;
 const view:Kind=kind==='hinges'&&hasHinges?'hinges':hasSlides?'slides':hasHinges?'hinges':kind;
 const [part,setPart]=useState<'CS-L'|'CS-R'>('CS-L');
 const [drawerId,setDrawerId]=useState<string|null>(null),[doorId,setDoorId]=useState<string|null>(null);
 const side=plan?.cut.find(c=>c.ids.includes(part)),sideD=side?.width??plan?.outside?.d??0,sideH=side?.height??plan?.outside?.h??0;
 const status=<p className='hw-status' role='status'>{analysis.state==='running'||analysis.state==='waiting'?<><LoaderCircle size={14} className='spin'/>Recalculating; the cabinet side shows the last engine positions.</>:fresh?<><CheckCircle2 size={14}/>Cabinet-side holes are the engine's own positions.</>:analysis.state==='invalid'?<><TriangleAlert size={14}/>Fix the dimensions to see hardware positions.</>:null}</p>;
 const sideSwitch=<div className='segmented hw-side' role='radiogroup' aria-label='Cabinet side'>{(['CS-L','CS-R'] as const).map(p=><button key={p} role='radio' aria-checked={part===p} className={part===p?'is-active':''} onClick={()=>setPart(p)}>{p==='CS-L'?'Left side':'Right side'}</button>)}</div>;
 const header=<div className='hw-toolbar'>
  <div className='segmented' role='radiogroup' aria-label='Hardware'>
   <button role='radio' aria-checked={view==='slides'} className={view==='slides'?'is-active':''} disabled={!hasSlides} onClick={()=>setKind('slides')}>Drawer slides</button>
   <button role='radio' aria-checked={view==='hinges'} className={view==='hinges'?'is-active':''} disabled={!hasHinges} onClick={()=>setKind('hinges')}>Hinges</button>
  </div>
  {status}
 </div>;
 if(!hasSlides&&!hasHinges)return <div className='hardware-view'>{header}<div className='hw-empty'><Info size={18}/><p>{!plan?'Waiting for the first engine check.':values.drawer_mount==='wood_rails'?'This design runs its drawers on wood runners, which are cut parts rather than hardware; they are drawn in the cut layout. Choose metal slides or add a hinged door to see hardware here.':'This design has no metal drawer slides or hinged doors. Choose them in Shop details › Hardware.'}</p></div></div>;

 if(view==='slides'){
  const rows=family===5?[]:H.cabinetSlideRows(values,features,drawers,part,sideD);
  const drawer=drawers.find(d=>d.id===drawerId)??drawers.find(d=>rows.some(r=>r.drawer===d.id))??drawers[0];
  const row=rows.find(r=>r.drawer===drawer?.id);
  const setback=Number(values.metal_slide_front_setback),len=Number(values.metal_slide_length),env=Number(values.metal_slide_envelope_height);
  const cabZ=Number(values.metal_slide_cabinet_hole_z_from_drawer_bottom),drwZ=Number(values.metal_slide_drawer_hole_z_from_drawer_bottom);
  const box=drawer?.box,dHoles=box?H.drawerSideHoles(values,box.d):[];
  const minR=(n:number)=>Math.max(n,1)/90;
  const cabinetBoard=family!==5&&sideD>0&&sideH>0?<Board title={(part==='CS-L'?'Left':'Right')+' cabinet side · inside face'} note={rows.some(r=>r.engine)?'Holes as the engine drills them':'Estimated from the settings'} w={sideD} h={sideH}
   dims={row?[...rowDims(row.holes.map(h=>h.y),row.z,fmt,1.2),{x1:sideD,y1:0,x2:sideD,y2:row.z,label:fmt(row.z),offset:1.2}]:[]}>
   {rows.map(r=><g key={r.id} className={'hw-item '+(r.drawer===drawer?.id?'is-selected':'')} onClick={()=>r.drawer&&setDrawerId(r.drawer)}>
    <rect className='hw-body' x={setback} y={sideH-r.bottom-env} width={Math.max(0,Math.min(len,sideD-setback))} height={env}><title>{'Slide for drawer '+(r.drawer??'')}</title></rect>
    <line className='hw-datum' x1={0} x2={sideD} y1={sideH-r.bottom} y2={sideH-r.bottom}/>
    {r.holes.map((h,i)=><Hole key={i} x={h.y} z={h.z} d={h.d} h={sideH} min={minR(sideD)} className={r.engine?'':'is-estimate'} title={`Ø${round(h.d)} mm · ${fmt(h.y)} from the front · ${fmt(h.z)} up`}/>)}
   </g>)}
  </Board>:null;
  const drawerBoard=box?<Board title={'Drawer '+drawer.id+' · box side, outside face'} note='Drawn from the slide settings' w={box.d} h={box.h} front='Box front'
   dims={[...rowDims(dHoles.filter(h=>h.drilled).map(h=>h.y),0,fmt,1.2),...(dHoles.length?[{x1:box.d,y1:0,x2:box.d,y2:drwZ,label:fmt(drwZ),offset:1.2}]:[])]}>
   <g className='hw-item is-selected'>
    <rect className='hw-body' x={setback} y={Math.max(0,box.h-env)} width={Math.max(0,Math.min(len,box.d-setback))} height={Math.min(env,box.h)}/>
    {dHoles.map((h,i)=><Hole key={i} x={h.y} z={h.z} d={h.d} h={box.h} min={minR(box.d)} className={h.drilled?'':'is-skipped'} title={h.drilled?`Ø${round(h.d)} mm · ${fmt(h.y)} from the box front · ${fmt(h.z)} up`:`Not drilled: ${fmt(h.y)} is past the slide or the box, less the rear margin`}/>)}
   </g>
  </Board>:null;
  const cab=row?.holes.map(h=>round(h.y))??[],drw=dHoles.filter(h=>h.drilled).map(h=>round(h.y));
  const aligned=row&&cab.length===drw.length&&cab.every((y,i)=>Math.abs(y-drw[i])<0.01)&&Math.abs(cabZ-drwZ)<0.01;
  const overlong=box&&setback+len>box.d+0.01,overside=sideD>0&&setback+len>sideD+0.01;
  return <div className='hardware-view'>
   {header}
   <div className='hw-pickers'>
    {family!==5&&sideSwitch}
    <label>Drawer<select value={drawer?.id??''} onChange={e=>setDrawerId(e.target.value)}>{drawers.map(d=><option key={d.id} value={d.id}>{d.id}{rows.some(r=>r.drawer===d.id)?'':family===5?'':' · not on this side'}</option>)}</select></label>
   </div>
   <div className='hw-boards'>{cabinetBoard}{drawerBoard}</div>
   <ul className='hw-facts'>
    {!values.include_metal_slide_holes&&<li><Info size={14}/>Slide drilling is off, so only the slide bodies are drawn. Turn on mounting holes in the Hardware settings to drill them.</li>}
    {row&&<li>{aligned?<CheckCircle2 size={14}/>:<Info size={14}/>}Cabinet side: {cab.length} hole{cab.length===1?'':'s'} {fmt(cabZ)} above the drawer bottom. Drawer side: {drw.length} hole{drw.length===1?'':'s'} {fmt(drwZ)} above it.{aligned?' The two rows line up.':' The rows differ, as some slides’ cabinet and drawer members do; check against the maker’s drawing.'}</li>}
    {drawer&&!row&&family!==5&&<li><Info size={14}/>Drawer {drawer.id} is not against this side; its slides mount on the partition beside it, drilled with the same pattern.</li>}
    {dHoles.some(h=>!h.drilled)&&<li><TriangleAlert size={14}/>{dHoles.filter(h=>!h.drilled).length} drawer-side hole{dHoles.filter(h=>!h.drilled).length===1?' is':'s are'} not drilled because {dHoles.filter(h=>!h.drilled).length===1?'it lies':'they lie'} beyond the slide or the box, less the {fmt(Number(values.metal_slide_hole_rear_margin))} rear margin.</li>}
    {overlong&&<li><TriangleAlert size={14}/>The slide ({fmt(len)} from {fmt(setback)} back) is longer than the drawer box ({fmt(box.d)}).</li>}
    {overside&&<li><TriangleAlert size={14}/>The slide runs past the back of the cabinet side ({fmt(sideD)}).</li>}
   </ul>
  </div>;
 }

 const plates=H.cabinetHingePlates(features,part);
 const door=doors.find(d=>d.id===doorId)??doors.find(d=>(d.hinge==='left')===(part==='CS-L'))??doors[0];
 const drill=door?H.doorDrilling(values,door.w,door.h,door.hinge):{cups:[],fixing:[]};
 const mine=door?H.platesForDoor(plates,door):[];
 const doorZs=door?H.hingeHeights(values,door.h).map(z=>round(door.z+z)):[];
 const matched=mine.length===doorZs.length&&mine.every((p,i)=>Math.abs(p.z-doorZs[i])<0.5);
 const minR=(n:number)=>Math.max(n,1)/90;
 const cupEdge=Number(values.hinge_cup_center_from_door_edge);
 const cabinetBoard=sideD>0&&sideH>0?<Board title={(part==='CS-L'?'Left':'Right')+' cabinet side · inside face'} note={plates.length?'Mounting-plate holes as the engine drills them':'No mounting-plate holes on this side'} w={sideD} h={sideH}
  dims={mine.length?[{x1:0,y1:mine[0].z,x2:mine[0].y,y2:mine[0].z,label:fmt(mine[0].y),offset:-1.2},...mine.map((p,i)=>({x1:sideD,y1:0,x2:sideD,y2:p.z,label:fmt(p.z),offset:1.2+3.2*i}))]:[]}>
  {door&&<line className='hw-door-band' x1={0} x2={0} y1={sideH-door.z} y2={sideH-door.z-door.h}><title>{'Door '+door.id+' height'}</title></line>}
  {plates.map(p=><g key={p.id} className={'hw-item '+(mine.includes(p)?'is-selected':'')}>
   <line className='hw-plate' x1={p.y} x2={p.y} y1={sideH-Math.min(...p.holes.map(h=>h.z))} y2={sideH-Math.max(...p.holes.map(h=>h.z))}/>
   {p.holes.map((h,i)=><Hole key={i} x={h.y} z={h.z} d={h.d} h={sideH} min={minR(sideD)} title={`Ø${round(h.d)} mm · ${fmt(h.y)} from the front · ${fmt(h.z)} up`}/>)}
  </g>)}
 </Board>:null;
 const fixOffset=Number(values.hinge_door_fixing_hole_offset??0),dir=door?.hinge==='left'?1:-1;
 const doorBoard=door?<Board title={'Door '+door.id+' · seen from the front'} note={'Hinged on the '+door.hinge+'; cups and fixing holes are drilled in the back face'} w={door.w} h={door.h} front={door.hinge==='left'?'Hinge edge':'Free edge'}
  dims={drill.cups.length||drill.fixing.length?[
   {x1:door.hinge==='left'?0:door.w-cupEdge,y1:door.h,x2:door.hinge==='left'?cupEdge:door.w,y2:door.h,label:fmt(cupEdge),offset:-1.2},
   ...(fixOffset>0&&drill.fixing.length?[{x1:drill.fixing[0].x-dir*fixOffset,y1:0,x2:drill.fixing[0].x,y2:0,label:fmt(fixOffset),offset:1.2}]:[]),
   ...H.hingeHeights(values,door.h).map((z,i)=>({x1:door.hinge==='left'?door.w:0,y1:0,x2:door.hinge==='left'?door.w:0,y2:z,label:fmt(z),offset:(door.hinge==='left'?1:-1)*(1.2+3.2*i)})),
  ]:[]}>
  <g className='hw-item is-selected'>
   {drill.cups.map((c,i)=><Hole key={'c'+i} x={c.x} z={c.z} d={c.d} h={door.h} min={minR(door.w)} className='is-cup' title={`Cup Ø${round(c.d)} mm · ${fmt(cupEdge)} from the hinge edge · ${fmt(c.z)} up`}/>)}
   {drill.fixing.map((c,i)=><Hole key={'f'+i} x={c.x} z={c.z} d={c.d} h={door.h} min={minR(door.w)} title={`Fixing hole Ø${round(c.d)} mm · ${fmt(c.z)} up`}/>)}
  </g>
 </Board>:null;
 return <div className='hardware-view'>
  {header}
  <div className='hw-pickers'>
   {sideSwitch}
   <label>Door<select value={door?.id??''} onChange={e=>{const d=doors.find(x=>x.id===e.target.value);setDoorId(e.target.value);if(d)setPart(d.hinge==='left'?'CS-L':'CS-R')}}>{doors.map(d=><option key={d.id} value={d.id}>{d.id} · hinged {d.hinge}</option>)}</select></label>
  </div>
  <div className='hw-boards'>{cabinetBoard}{doorBoard}</div>
  <ul className='hw-facts'>
   {door&&mine.length>0&&<li>{matched?<CheckCircle2 size={14}/>:<TriangleAlert size={14}/>}{matched?`Each of the ${mine.length} mounting plates sits level with its cup on door ${door.id}.`:`The mounting plates on this side (${mine.map(p=>fmt(p.z)).join(', ')}) do not match the cup heights on door ${door.id} (${doorZs.map(fmt).join(', ')}).`}</li>}
   {door&&!mine.length&&<li><Info size={14}/>{values.hinge_plate_holes_enabled===false?'Mounting-plate drilling is off.':`Door ${door.id} is not hinged on this side${plates.length?'':' or its plates mount on a partition'}.`}</li>}
   {values.hinge_style==='euro_35mm'&&values.hinge_door_fixing_enabled&&fixOffset===0&&<li><Info size={14}/>The door fixing holes are on the cup's center line. Most screw-on cup hinges need them 9.5 mm toward the middle of the door; set the fixing-hole offset from your hinge's drawing.</li>}
   {values.hinge_style==='euro_35mm'&&!values.hinge_door_fixing_enabled&&<li><Info size={14}/>Door fixing holes are not drilled; the hinge's own screws or wings locate it in the cup.</li>}
  </ul>
 </div>;
}
