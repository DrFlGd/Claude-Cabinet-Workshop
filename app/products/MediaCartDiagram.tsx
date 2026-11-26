'use client';
// Instant drawings of the media cart: a side profile (bin rows, crosspieces, cubbies,
// casters) and a front elevation (columns, towers, cubbies), drawn from cartModel, which
// mirrors the SCAD file. Quick controls above the drawings change the common settings;
// clicking a region opens its settings section.
import {Minus,Plus} from 'lucide-react';
import {cartModel} from '@/lib/products/media-cart';
import {formatShop} from '@/lib/units';
import type {DiagramProps} from './diagrams';

function Segmented({label,value,options,onChange}:{label:string;value:string;options:[string,string][];onChange:(v:string)=>void}){
 return <div className='pw-quick-group' role='radiogroup' aria-label={label}><span>{label}</span><div className='pw-segmented'>{options.map(([id,text])=><button key={id} type='button' role='radio' aria-checked={value===id} className={value===id?'is-active':''} onClick={()=>value!==id&&onChange(id)}>{text}</button>)}</div></div>;
}
export function Stepper({label,value,min,max,onChange,id}:{label:string;value:number;min:number;max:number;onChange:(n:number)=>void;id?:string}){
 return <div className='pw-quick-group'><span id={id?id+'-label':undefined}>{label}</span><div className='pw-stepper' role='group' aria-labelledby={id?id+'-label':undefined}>
  <button type='button' aria-label={'Fewer '+label.toLowerCase()} disabled={value<=min} onClick={()=>onChange(value-1)}><Minus size={14}/></button>
  <output aria-live='polite'>{value}</output>
  <button type='button' aria-label={'More '+label.toLowerCase()} disabled={value>=max} onClick={()=>onChange(value+1)}><Plus size={14}/></button>
 </div></div>;
}
function Toggle({label,on,onChange}:{label:string;on:boolean;onChange:(v:boolean)=>void}){
 return <button type='button' className={'pw-chip'+(on?' is-on':'')} aria-pressed={on} onClick={()=>onChange(!on)}>{label}</button>;
}

// fs: label size in model millimeters, so labels read the same at any cart size.
function Frame({w,h,title,children,lift=0,fs}:{w:number;h:number;title:string;children:React.ReactNode;lift?:number;fs:number}){
 const pad=fs*5;
 // Model coordinates: x right, z up, origin at the underside of the bottom panel.
 return <figure className='pw-drawing'>
  <figcaption>{title}</figcaption>
  <svg viewBox={`${-pad} ${-h-fs*2} ${w+pad*2} ${h+lift+fs*5}`} role='img' aria-label={title} preserveAspectRatio='xMidYMid meet' style={{fontSize:fs}}>{children}</svg>
 </figure>;
}
const R=({x,z,w,h,cls,onClick,label}:{x:number;z:number;w:number;h:number;cls:string;onClick?:()=>void;label?:string})=><rect x={x} y={-(z+h)} width={Math.max(0,w)} height={Math.max(0,h)} className={cls} onClick={onClick}>{label&&<title>{label}</title>}</rect>;
function DimH({x0,x1,z,text,fs}:{x0:number;x1:number;z:number;text:string;fs:number}){
 return <g className='pw-dim'><line x1={x0} x2={x1} y1={-z} y2={-z}/><line x1={x0} x2={x0} y1={-z-fs/3} y2={-z+fs/3}/><line x1={x1} x2={x1} y1={-z-fs/3} y2={-z+fs/3}/><text x={(x0+x1)/2} y={-z+fs*1.2} textAnchor='middle'>{text}</text></g>;
}
function DimV({x,z0,z1,text,left=false,fs}:{x:number;z0:number;z1:number;text:string;left?:boolean;fs:number}){
 return <g className='pw-dim'><line x1={x} x2={x} y1={-z0} y2={-z1}/><line x1={x-fs/3} x2={x+fs/3} y1={-z0} y2={-z0}/><line x1={x-fs/3} x2={x+fs/3} y1={-z1} y2={-z1}/><text x={x+(left?-fs/2:fs/2)} y={-(z0+z1)/2} textAnchor={left?'end':'start'} dominantBaseline='middle'>{text}</text></g>;
}

export default function MediaCartDiagram({values,units,change,focus}:DiagramProps){
 const m=cartModel(values),f=(mm:number)=>formatShop(mm,units)+(units==='mm'?'':'″');
 const casters=!!values.show_casters,lift=m.lift,fs=Math.min(64,Math.max(18,Math.max(m.width,m.depth,m.body)/28)),gap=fs*1.3;
 const set=(k:string,v:unknown)=>change(k,v);
 const shelves=(top:number)=>Array.from({length:Math.max(0,m.openings-1)},(_,k)=>m.t+(k+1)*(top-m.t)/m.openings-m.t);
 const wheel=(x:number)=>casters&&<g className='pw-caster' key={x}><rect x={x-28} y={0} width={56} height={10}/><circle cx={x} cy={lift-lift*0.32} r={lift*0.32}/></g>;
 const inset=Number(values.caster_inset)||70;
 // Side profile: front at the left.
 const wallPoly=[[0,m.t],...m.edge,[m.depth,m.t]].map(([y,z])=>`${y},${-z}`).join(' ');
 const towerTop=m.rear;
 const side=<Frame w={m.depth} h={Math.max(m.body,m.binTop)} lift={lift} fs={fs} title='Side profile (front at left)'>
  <line x1={-fs*2} x2={m.depth+fs*2} y1={lift} y2={lift} className='pw-floor'/>
  {m.tower!=='None'&&<g className='pw-ghost' onClick={()=>focus('towers')}><rect x={0} y={-towerTop} width={m.depth} height={towerTop-m.t}/>{shelves(towerTop).map(z=><line key={z} x1={0} x2={m.depth} y1={-z} y2={-z}/>)}<title>Shelf tower beyond the bins</title></g>}
  <polygon points={wallPoly} className='pw-wall' onClick={()=>focus('size')}><title>Bin side wall</title></polygon>
  <R x={0} z={0} w={m.depth} h={m.t} cls='pw-panel' label='Bottom panel'/>
  {m.lower&&<g onClick={()=>focus('cubbies')} className='pw-click'><R x={0} z={m.deck-m.t} w={m.depth} h={m.t} cls='pw-panel' label='Bin deck'/><R x={m.depth-m.t} z={m.t} w={m.t} h={m.deck-2*m.t} cls='pw-panel' label='Cubby back'/></g>}
  {Array.from({length:m.rows+1},(_,i)=><R key={i} x={m.wallY(i)} z={m.deck} w={m.t} h={m.rowZ(i)-m.deck} cls='pw-cross' onClick={()=>focus('bins')} label={`Crosspiece ${i+1}`}/>)}
  {casters&&[inset,m.depth-inset].map(y=>wheel(y))}
  <DimH x0={0} x1={m.depth} z={-lift-gap} fs={fs} text={f(m.depth)}/>
  <DimV x={-gap} z0={0} z1={m.front} left fs={fs} text={f(m.front)}/>
  <DimV x={m.depth+gap} fs={fs} z0={0} z1={Math.max(m.binTop,m.body)} text={f(Math.max(m.binTop,m.body))}/>
  {m.rows>0&&<text className='pw-note' x={(m.wallY(0)+m.wallY(1))/2+m.t/2} y={-m.deck-fs*0.6} textAnchor='middle'>{f(m.clearD)}</text>}
 </Frame>;
 // Front elevation.
 const wallH=(side:'L'|'R')=>((side==='L'?m.left:m.right)?m.rear:m.binTop)-m.t;
 const cubbyX=(k:number)=>m.x0+m.t+k*(m.cubbyW+m.t)-m.t;
 const tower=(x:number)=><g key={x} onClick={()=>focus('towers')} className='pw-click'>
  <R x={x} z={m.t} w={m.t} h={m.rear-m.t} cls='pw-panel' label='Tower outer wall'/>
  <R x={Math.min(x+m.t,x-m.towerW)} z={m.rear-m.t} w={m.towerW} h={m.t} cls='pw-panel' label='Tower top'/>
  {shelves(m.rear).filter(z=>z>m.t+1).map(z=><R key={z} x={Math.min(x+m.t,x-m.towerW)} z={z} w={m.towerW} h={m.t} cls='pw-shelf' label='Tower shelf'/>)}
 </g>;
 const front=<Frame w={m.width} h={m.body} lift={lift} fs={fs} title='Front elevation'>
  <line x1={-fs*2} x2={m.width+fs*2} y1={lift} y2={lift} className='pw-floor'/>
  <R x={0} z={0} w={m.width} h={m.t} cls='pw-panel' label='Bottom panel'/>
  {m.left&&tower(0)}{m.right&&tower(m.width-m.t)}
  <R x={m.x0} z={m.t} w={m.t} h={wallH('L')} cls='pw-wall' onClick={()=>focus('size')} label='Left bin wall'/>
  <R x={m.x1-m.t} z={m.t} w={m.t} h={wallH('R')} cls='pw-wall' onClick={()=>focus('size')} label='Right bin wall'/>
  {Array.from({length:Math.max(0,m.columns-1)},(_,c)=><R key={c} x={m.finX(c+1)} z={m.deck} w={m.ft} h={m.binTop-m.deck} cls='pw-fin' onClick={()=>focus('bins')} label={`Fin ${c+1}`}/>)}
  <R x={m.x0+m.t} z={m.deck} w={m.span} h={m.front-m.deck} cls='pw-cross' onClick={()=>focus('bins')} label='Front crosspiece'/>
  {m.lower&&<g onClick={()=>focus('cubbies')} className='pw-click'>
   <R x={m.x0+m.t} z={m.deck-m.t} w={m.span} h={m.t} cls='pw-panel' label='Bin deck'/>
   {Array.from({length:Math.max(0,m.cubbyCols-1)},(_,k)=><R key={k} x={cubbyX(k+1)} z={m.t} w={m.t} h={m.deck-2*m.t} cls='pw-panel' label={`Cubby divider ${k+1}`}/>)}
  </g>}
  {casters&&[inset,m.width-inset].map(x=>wheel(x))}
  <DimH x0={0} x1={m.width} z={-lift-gap} fs={fs} text={f(m.width)}/>
  <DimV x={m.width+gap} fs={fs} z0={-lift} z1={m.body} text={f(m.body+lift)}/>
  {m.columns>0&&<text className='pw-note' x={m.x0+m.t+m.clearW/2} y={-m.front-fs*0.6} textAnchor='middle'>{f(m.clearW)}</text>}
 </Frame>;
 const profile=m.stepped?'Stepped':'Sloped';
 return <div className='pw-diagram'>
  <div className='pw-quick' aria-label='Quick settings'>
   <Stepper id='quick-rows' label='Rows' value={m.rows} min={1} max={12} onChange={n=>set('rows',n)}/>
   <Stepper id='quick-columns' label='Columns' value={m.columns} min={1} max={12} onChange={n=>set('columns',n)}/>
   <Segmented label='Bin walls' value={profile} options={[['Sloped','Sloped'],['Stepped','Stepped']]} onChange={v=>set('bin_profile',v)}/>
   <Segmented label='Towers' value={m.tower} options={[['None','None'],['Left','Left'],['Right','Right'],['Both','Both']]} onChange={v=>set('custom_tower',v)}/>
   <div className='pw-quick-group'><span>Include</span><div className='pw-chips'><Toggle label='Lower cubbies' on={m.lower} onChange={v=>set('custom_lower_cubbies',v)}/><Toggle label='Casters' on={casters} onChange={v=>set('show_casters',v)}/></div></div>
  </div>
  <div className='pw-drawings' style={{['--pw-ratio' as string]:String(m.depth/Math.max(m.width,1))}}>
   {front}{side}
  </div>
  <p className='pw-legend'><span><i className='pw-key is-wall'/>Side walls</span><span><i className='pw-key is-cross'/>Crosspieces</span><span><i className='pw-key is-fin'/>Fins</span><span><i className='pw-key is-panel'/>Panels and shelves</span><span>Instant drawing to scale from your settings; joinery and exact cut shapes are in the 3D model and the cut files.</span></p>
 </div>;
}

