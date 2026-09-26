'use client';
import { useMemo,useRef,useState } from 'react';
import { geometry,Values,Part } from '@/lib/cabinet';
import { RotateCcw,Plus,Minus,Move3D } from 'lucide-react';
import {formatDimension,Units} from '@/lib/units';
import SchematicScene from './SchematicScene';
export default function CabinetView({values,interior,exploded,dimensions,units='mm',selected,onSelect}:{selected?:string|null;onSelect?:(p:Part|null)=>void;units?:Units;values:Values;interior:boolean;exploded:boolean;dimensions:boolean}){
 const pick=useRef<((x:number,y:number)=>void)|null>(null),travel=useRef(0);
 const [angle,setAngle]=useState(-.56),[tilt,setTilt]=useState(.35),[zoom,setZoom]=useState(1);const drag=useRef<{x:number;y:number;pointerId:number}|null>(null);
 const W=Number(values.custom_cabinet_width)||650,H=Number(values.custom_cabinet_height)||700,D=Number(values.custom_cabinet_depth)||500;
 const sceneH=values._family===3?H+(Math.max(1,Math.min(8,Number(values.stack_preview_count??1)))-1)*(H-Number(values.stack_interface_depth??18)+Number(values.stack_preview_explode_gap??0)):H;
 const scale=Math.min(520/(W+D*.65),490/(sceneH+D*.4))*zoom;
 const project=(x:number,y:number,z:number)=>{x-=W/2;y-=D/2;z-=sceneH/2;const a=x*Math.cos(angle)-y*Math.sin(angle),b=x*Math.sin(angle)+y*Math.cos(angle);return [450+a*scale,350+(-b*Math.sin(tilt)-z*Math.cos(tilt))*scale,b*Math.cos(tilt)+z*Math.sin(tilt)]};
 const parts=useMemo(()=>geometry(values,interior,exploded),[values,interior,exploded]);
 const dim=(a:number[],b:number[],text:string)=>{const p=project(...a as [number,number,number]),q=project(...b as [number,number,number]);return <g><line x1={p[0]} y1={p[1]} x2={q[0]} y2={q[1]} stroke='#657981' markerStart='url(#tick)' markerEnd='url(#tick)'/><text x={(p[0]+q[0])/2} y={(p[1]+q[1])/2-10} textAnchor='middle' fill='#3a515c' fontSize='16' fontFamily='monospace' paintOrder='stroke' stroke='#edf1f2' strokeWidth='5'>{text}</text></g>};
 return <div className='model-view'><svg role='img' aria-label='Interactive schematic cabinet preview. Drag or use arrow keys to rotate.' tabIndex={0} viewBox='0 0 900 730' onPointerDown={e=>{if(!e.isPrimary||e.button!==0)return;travel.current=0;drag.current={x:e.clientX,y:e.clientY,pointerId:e.pointerId};e.currentTarget.setPointerCapture(e.pointerId)}} onPointerMove={e=>{
  const previous=drag.current;if(!previous||previous.pointerId!==e.pointerId)return;
  // Capture scalar deltas now: React may run these updates after the drag ends.
  const dx=e.clientX-previous.x,dy=e.clientY-previous.y;travel.current+=Math.abs(dx)+Math.abs(dy);
  drag.current={x:e.clientX,y:e.clientY,pointerId:e.pointerId};
  setAngle(a=>a+dx*.008);setTilt(a=>Math.max(-.15,Math.min(1.2,a+dy*.006)));
 }} onPointerUp={e=>{if(drag.current?.pointerId===e.pointerId){if(travel.current<5)pick.current?.(e.clientX,e.clientY);drag.current=null}}} onPointerCancel={e=>{if(drag.current?.pointerId===e.pointerId)drag.current=null}} onLostPointerCapture={e=>{if(drag.current?.pointerId===e.pointerId)drag.current=null}} onKeyDown={e=>{if(['ArrowLeft','ArrowRight','ArrowUp','ArrowDown'].includes(e.key)){e.preventDefault();if(e.key==='ArrowLeft')setAngle(a=>a-.1);if(e.key==='ArrowRight')setAngle(a=>a+.1);if(e.key==='ArrowUp')setTilt(a=>Math.min(1.2,a+.1));if(e.key==='ArrowDown')setTilt(a=>Math.max(-.15,a-.1))}}}>
 <defs><marker id='tick' markerWidth='10' markerHeight='10' refX='5' refY='5' orient='auto'><path d='M5 0V10' stroke='#657981'/></marker></defs>
 {dimensions&&<>{dim([0,-100,-115],[W,-100,-115],formatDimension(W,units)+' '+units)}{dim([W+100,D,0],[W+100,D,H],formatDimension(H,units)+' '+units)}{dim([W+80,0,-115],[W+80,D,-115],formatDimension(D,units)+' '+units)}</>}
 </svg><SchematicScene selected={selected} onSelect={onSelect} pickRef={pick} parts={parts} angle={angle} tilt={tilt} scale={scale} W={W} H={sceneH} D={D}/><div className='view-tools'><button title='Zoom in' aria-label='Zoom in' onClick={()=>setZoom(z=>Math.min(2,z+.1))}><Plus size={18}/></button><button title='Zoom out' aria-label='Zoom out' onClick={()=>setZoom(z=>Math.max(.5,z-.1))}><Minus size={18}/></button><span/><button title='Reset view' aria-label='Reset view' onClick={()=>{setAngle(-.56);setTilt(.35);setZoom(1)}}><RotateCcw size={17}/></button><button onClick={()=>{setAngle(0);setTilt(0)}}>Front</button></div><div className='orbit-hint'><Move3D size={15}/> Click a part to edit · drag to orbit</div></div>
}
