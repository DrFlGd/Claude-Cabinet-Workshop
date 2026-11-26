'use client';
// Instant drawings of the media cart: a side profile (bin rows, crosspieces, cubbies,
// casters) and a front elevation (columns, towers, cubbies), drawn from cartModel, which
// mirrors the SCAD file. Over them, from the latest engine check: the joinery (tabs,
// receivers, half-laps, dados, holes) as outlines and the center of gravity, with the
// tip-over and racking result below. Quick controls above the drawings change the common
// settings; clicking a region opens its settings section.
import {useMemo,useState} from 'react';
import {Minus,Plus,Check,TriangleAlert,ChevronRight} from 'lucide-react';
import {cartModel} from '@/lib/products/media-cart';
import {cartReport,weakest,type CartFeature,type CartReport} from '@/lib/products/cart-report';
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


// Joinery outlines of the parts a view shows, projected onto it (u: x in the front
// elevation, y in the side profile). Half-lap slots run past the top of their crosspiece in
// the engine; they are clipped to the part.
function Joinery({features,view,top}:{features:CartFeature[];view:'front'|'side';top:(part:string)=>number}){
 return <g className='pw-joinery' aria-hidden='true'>{features.map((f,i)=>{
  const u=view==='front'?f.x:f.y,z1=Math.min(f.z[1],top(f.part));
  if(z1<=f.z[0])return null;
  return <rect key={i} x={u[0]} y={-z1} width={Math.max(0.5,u[1]-u[0])} height={z1-f.z[0]} className={'pw-j-'+f.type}/>;
 })}</g>;
}
// Which features each view shows: those of the parts it sees face on (the front
// crosspiece; the left bin wall), every feature of the horizontal panels (seen edge on, a
// receiver or hole shows across the panel's thickness) and the tabs of the parts it cuts
// through. Parts hidden behind others are left out.
const UPRIGHT_SIDE=/^(SIDE_[LR]|FIN_\d+|CUBBY_DIV_\d+|TOWER_[LR])$/,UPRIGHT_FRONT=/^(CROSS_\d+|CUBBY_BACK|TOWER_[LR]_BACK)$/;
const inFront=(f:CartFeature)=>f.part==='CROSS_1'||!UPRIGHT_FRONT.test(f.part)&&(!UPRIGHT_SIDE.test(f.part)||f.type==='add');
const inSide=(f:CartFeature)=>f.part==='SIDE_L'||!UPRIGHT_SIDE.test(f.part)&&(!UPRIGHT_FRONT.test(f.part)||f.type==='add');
function Gravity({u,z,fs,label}:{u:number;z:number;fs:number;label:string}){
 const r=fs*0.55;
 return <g className='pw-cg'><title>{label}</title><circle cx={u} cy={-z} r={r}/><path d={`M ${u} ${-z} L ${u+r} ${-z} A ${r} ${r} 0 0 1 ${u} ${-z+r} Z M ${u} ${-z} L ${u-r} ${-z} A ${r} ${r} 0 0 1 ${u} ${-z-r} Z`}/></g>;
}
function Stability({report,stale,focus}:{report:CartReport;stale:boolean;focus:(s:string)=>void}){
 const [open,setOpen]=useState(false);
 const b=report.basis;if(!b||!report.cases.length)return null;
 const rows=report.cases.map(c=>({c,w:weakest(c)}));
 const worst=rows.reduce((a,x)=>x.w.force<a.w.force?x:a);
 const leans=rows.filter(x=>x.c.lean!==null),worstLean=leans.length?leans.reduce((a,x)=>x.c.lean!<a.c.lean!?x:a):null;
 const tips=worst.w.force<=0,pushOk=worst.w.force>=b.push,leanOk=!worstLean||worstLean.c.lean!>=b.lean,ok=!tips&&pushOk&&leanOk;
 const n=(v:number)=>Math.round(v).toLocaleString();
 const head=tips?`Tips ${worst.w.text} on its own (${worst.c.label.toLowerCase()})`:ok?`Stable: holds a ${n(b.push)} N push at the top${worstLean?` and a ${n(b.lean)} N lean on the front`:''}`:
  !pushOk?`A ${n(b.push)} N push tips it ${worst.w.text} (${worst.c.label.toLowerCase()}, holds ${n(worst.w.force)} N)`:`A ${n(b.lean)} N lean on the front tips it forward (${worstLean!.c.label.toLowerCase()}, holds ${n(worstLean!.c.lean!)} N)`;
 return <section className={'pw-stability'+(ok?' is-ok':' is-warn')+(stale?' is-stale':'')} aria-label='Stability'>
  <button type='button' className='pw-stability-head' aria-expanded={open} onClick={()=>setOpen(!open)}>
   {ok?<Check size={16}/>:<TriangleAlert size={16}/>}<span>{head}{stale&&<small> · updating</small>}</span><ChevronRight size={15} className={open?'turned':''}/>
  </button>
  {open&&<div className='pw-stability-body'>
   <table><thead><tr><th>Loading</th><th>Weight</th><th>Weakest push</th><th>Front lean</th></tr></thead><tbody>
    {rows.map(({c,w})=><tr key={c.id}><td>{c.label}</td><td>{c.mass.toFixed(1)} kg</td><td className={w.force<b.push?'is-bad':''}>{n(w.force)} N {w.text}</td><td className={c.lean!==null&&c.lean<b.lean?'is-bad':''}>{c.lean===null?'cannot tip':n(c.lean)+' N'}</td></tr>)}
   </tbody></table>
   {report.racking&&<p><strong>Racking.</strong> Side to side: {report.racking.side}. Front to back: {report.racking.front}.</p>}
   <p className='pw-assumptions'><strong>Assumes</strong> a level floor{b.lift>0?' with the casters locked':''}; the cart tips about the {b.lift>0?'caster centers':'edges of the bottom panel'}. Push: {n(b.push)} N level at the top ({n(b.pushZ)} mm up), in each direction. Lean: {n(b.lean)} N straight down on the front edge of the bins. Weight from the panels at {n(b.density)} kg/m³ (casters and hardware left out) plus {b.binLoad} kg per bin, {b.cubbyLoad} kg per cubby and {b.shelfLoad} kg per tower opening at their centers. Joint and panel strength is not rated.</p>
   <button type='button' className='pw-link' onClick={()=>focus('stability')}>Change the loads and forces</button>
  </div>}
 </section>;
}

export default function MediaCartDiagram({values,units,change,focus,records=[],stale=false}:DiagramProps){
 const m=cartModel(values),f=(mm:number)=>formatShop(mm,units)+(units==='mm'?'':'″');
 const casters=!!values.show_casters,lift=m.lift,fs=Math.min(64,Math.max(18,Math.max(m.width,m.depth,m.body)/28)),gap=fs*1.3;
 const set=(k:string,v:unknown)=>change(k,v);
 const shelves=(top:number)=>Array.from({length:Math.max(0,m.openings-1)},(_,k)=>m.t+(k+1)*(top-m.t)/m.openings-m.t);
 const wheel=(x:number)=>casters&&<g className='pw-caster' key={x}><rect x={x-28} y={0} width={56} height={10}/><circle cx={x} cy={lift-lift*0.32} r={lift*0.32}/></g>;
 const inset=Number(values.caster_inset)||70;
 const [show,setShow]=useState({joinery:true,cg:true});
 const report=useMemo(()=>cartReport(records),[records]);
 const partTop=(part:string)=>{const k=part.match(/^CROSS_(\d+)$/);return k?m.rowZ(Number(k[1])-1):Math.max(m.body,m.binTop)};
 const features=show.joinery?report.features:[];
 // The center of gravity of the loading with the smallest tipping push.
 const cg=show.cg&&report.cases.length?report.cases.reduce((a,c)=>weakest(c).force<weakest(a).force?c:a):null;
 const cgLabel=cg?`Center of gravity, ${cg.label.toLowerCase()}: ${cg.mass.toFixed(1)} kg`:'';
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
  <Joinery features={features.filter(inSide)} view='side' top={partTop}/>
  {cg&&<Gravity u={cg.com[1]} z={cg.com[2]-lift} fs={fs} label={cgLabel}/>}
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
  <Joinery features={features.filter(inFront)} view='front' top={partTop}/>
  {cg&&<Gravity u={cg.com[0]} z={cg.com[2]-lift} fs={fs} label={cgLabel}/>}
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
   <div className='pw-quick-group'><span>Show</span><div className='pw-chips'><Toggle label='Joinery' on={show.joinery} onChange={v=>setShow({...show,joinery:v})}/><Toggle label='Center of gravity' on={show.cg} onChange={v=>setShow({...show,cg:v})}/></div></div>
  </div>
  <div className={'pw-drawings'+(stale?' is-stale':'')} style={{['--pw-ratio' as string]:String(m.depth/Math.max(m.width,1))}}>
   {front}{side}
  </div>
  <p className='pw-legend'><span><i className='pw-key is-wall'/>Side walls</span><span><i className='pw-key is-cross'/>Crosspieces</span><span><i className='pw-key is-fin'/>Fins</span><span><i className='pw-key is-panel'/>Panels and shelves</span>
   {show.joinery&&<><span><i className='pw-key is-add'/>Tabs</span><span><i className='pw-key is-slot'/>Slots and half-laps</span><span><i className='pw-key is-pocket'/>Dados</span><span><i className='pw-key is-hole'/>Holes</span></>}
   {cg&&<span><svg className='pw-key-cg' viewBox='-6 -6 12 12' aria-hidden='true'><circle r='5'/><path d='M0 0L5 0A5 5 0 0 1 0 5ZM0 0L-5 0A5 5 0 0 1 0-5Z'/></svg>Center of gravity</span>}
   <span>{(show.joinery||show.cg)&&!records.length?'Joinery and the center of gravity appear after the engine check. ':stale&&(show.joinery||show.cg)?'Joinery is from the previous engine check until this one finishes. ':''}Instant drawing to scale; exact cut shapes are in the 3D model and the cut files.</span></p>
  <Stability report={report} stale={stale} focus={focus}/>
 </div>;
}

