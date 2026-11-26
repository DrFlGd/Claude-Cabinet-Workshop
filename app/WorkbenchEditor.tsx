'use client';
// Layout tab of the modular workbench: a top view of the base frame's grid. Click an empty cell
// to place a cabinet module, click a module to edit it; modules placed on top of others stack.
import {useState} from 'react';
import {ArrowDown,ArrowLeft,ArrowRight,ArrowUp,Info,Layers,Minus,Plus,Trash2,Grid3x3,Eraser} from 'lucide-react';
import {Values} from '@/lib/cabinet';
import * as WB from '@/lib/workbench';
import {Units,formatShop} from '@/lib/units';
import DimensionInput from './DimensionInput';

const FACING_LABEL:Record<WB.Facing,string>={front:'Front',back:'Back',left:'Left end',right:'Right end'};
type Row=WB.ModuleRow;

function Stepper({label,value,min,max,onChange}:{label:string;value:number;min:number;max:number;onChange:(n:number)=>void}){
 return <div className='lay-field lay-stepper'><span>{label}</span><div>
  <button type='button' aria-label={'Fewer '+label.toLowerCase()} disabled={value<=min} onClick={()=>onChange(value-1)}><Minus size={15}/></button>
  <output aria-live='polite'>{value}</output>
  <button type='button' aria-label={'More '+label.toLowerCase()} disabled={value>=max} onClick={()=>onChange(value+1)}><Plus size={15}/></button>
 </div></div>;
}
function Segmented<T extends string>({label,value,options,onChange,className=''}:{label:string;value:T;options:[T,string][];onChange:(v:T)=>void;className?:string}){
 return <div className='lay-field'><span>{label}</span><div className={'segmented '+className} role='radiogroup' aria-label={label}>
  {options.map(([o,text])=><button key={o} type='button' role='radio' aria-checked={value===o} className={value===o?'is-active':''} onClick={()=>value!==o&&onChange(o)}>{text}</button>)}
 </div></div>;
}

export default function WorkbenchEditor({values,units,apply}:{values:Values;units:Units;apply:(patch:Values)=>void}){
 const g=WB.grid(values),C=g.C,list=WB.modules(values),rows=WB.rows(values),size=WB.size(values),problems=WB.problems(values);
 const [sel,setSel]=useState(0);
 const index=list.length?Math.min(sel,list.length-1):-1,m=index>=0?list[index]:undefined;
 const fmt=(n:number)=>formatShop(n,units)+(units==='mm'?' mm':'″');
 const commit=(next:Row[],select?:number)=>{apply({modules:next.map(r=>[...r])});if(select!==undefined)setSel(select)};
 const edit=(i:number,patch:Partial<Record<number,any>>)=>commit(rows.map((r,j)=>j===i?Object.assign([...r],patch) as Row:r));
 const tc=Number(values.carcass_thickness)||18,minH=2*tc+(Number(values.top_rail_width)||75);
 const benchTop=size.moduleTop;
 // Facing for a new module: towards the nearest open edge of the frame.
 const facingFor=(c:number,r:number):WB.Facing=>r===0?'front':r===g.rows-1?'back':c===0?'left':c===g.cols-1?'right':'front';
 const newRow=(c:number,r:number,height:number):Row=>[c,r,1,1,Math.round(height),'door',1,facingFor(c,r),c<g.cols/2?'left':'right',3,1];
 function addAt(c:number,r:number){commit([...rows,newRow(c,r,list.length?benchTop-WB.baseHeight(values):730)],rows.length)}
 // A module below the bench height gets a module filling the gap; one at the bench height is
 // split into two stacked halves so the worksurface stays where it is.
 function stackOn(k:WB.Module){
  const gap=benchTop-k.top,half=Math.floor(k.height/2);
  const add=(h:number):Row=>[k.col,k.row,k.spanX,k.spanY,Math.round(h),k.contents,0,k.facing,k.hinge,k.drawers,k.columns];
  if(gap>=minH)return commit([...rows,add(gap)],rows.length);
  if(half>=minH)return commit([...rows.map((r,j)=>j===k.index?Object.assign([...r],{4:half,6:Math.min(r[6],1)}) as Row:r),add(k.height-half)],rows.length);
  commit([...rows,add(minH)],rows.length);
 }
 function remove(i:number){commit(rows.filter((_,j)=>j!==i),Math.max(0,i-1))}
 function fill(){
  const added:Row[]=[];
  for(let r=0;r<g.rows;r++)for(let c=0;c<g.cols;c++)if(!list.some(k=>WB.covers(k,c,r)))added.push(newRow(c,r,list.length?benchTop-WB.baseHeight(values):730));
  if(added.length)commit([...rows,...added],rows.length);
 }
 // Clicking a cell selects the top module there; clicking again walks down its stack.
 function pick(c:number,r:number){
  const stack=list.filter(k=>WB.covers(k,c,r)).sort((a,b)=>b.z-a.z);
  if(!stack.length)return addAt(c,r);
  const at=stack.findIndex(k=>k.index===index);
  setSel(stack[at>=0?(at+1)%stack.length:0].index);
 }
 // Top view in mm: x along the frame, y up the page = towards the back.
 const pad=Math.max(size.overhang,30)+40,vw=g.length+2*pad,vh=g.depth+2*pad+40;
 const X=(x:number)=>pad+x,Y=(y:number)=>pad+g.depth-y;
 const inset=Number(values.frame_rail_inset)||60;
 const crossCols=values.frame_cross_members==='every_column'?Array.from({length:g.cols},(_,c)=>c):g.cols===1?[0]:[0,g.cols-1];
 const level=(k:WB.Module)=>list.filter(o=>o.index!==k.index&&o.top<=k.z+0.01&&o.col<k.col+k.spanX&&k.col<o.col+o.spanX&&o.row<k.row+k.spanY&&k.row<o.row+o.spanY).length;
 const order=[...list].sort((a,b)=>a.z-b.z||a.index-b.index);
 const stackHere=m?list.filter(k=>k.col<m.col+m.spanX&&m.col<k.col+k.spanX&&k.row<m.row+m.spanY&&m.row<k.row+k.spanY).sort((a,b)=>a.z-b.z):[];
 const doors=m?WB.doorCount(m,C):0,drawers=m?WB.drawerCount(m):0,columns=m?WB.drawerColumns(m,C):1;
 // Short description of a module's front, for the grid and the inspector.
 const describe=(k:WB.Module)=>k.contents==='drawers'?(WB.drawerColumns(k,C)===2?`${k.drawers} × 2 drawers`:`${k.drawers} drawer${k.drawers===1?'':'s'}`):k.contents==='drawer_door'?`${k.drawers} drawer${k.drawers===1?'':'s'} + door`:WB.CONTENTS_LABEL[k.contents];
 const title=(k:WB.Module)=>k.contents==='door'?(doors===2?'Two-door':'Door')+' cabinet':k.contents==='drawers'?'Drawer cabinet':k.contents==='drawer_door'?'Drawer and door cabinet':k.contents==='framed'?'Framed open cabinet':'Open cabinet';
 return <div className='lay wb'>
  <div className='lay-stage'>
   <div className='lay-head'><div><strong>{g.cols} × {g.rows} grid · {fmt(C)} cells</strong><span>Top view, front at the bottom. Click an empty cell to place a cabinet module; click a module to edit it, click again to step down its stack.</span></div>
    <div className='wb-tools'><button type='button' onClick={fill} disabled={Array.from({length:g.cols*g.rows}).every((_,i)=>list.some(k=>WB.covers(k,i%g.cols,Math.floor(i/g.cols))))}><Grid3x3 size={15}/>Fill empty cells</button>{list.length>0&&<button type='button' onClick={()=>commit([],0)}><Eraser size={15}/>Clear</button>}</div>
   </div>
   <svg className='lay-svg wb-svg' viewBox={`0 0 ${vw} ${vh}`} role='group' aria-label='Workbench grid, top view'>
    {values.include_worksurface!==false&&list.length>0&&<rect className='wb-top' x={X(-size.overhang)} y={Y(g.depth+size.overhang)} width={g.length+2*size.overhang} height={g.depth+2*size.overhang} rx={Number(values.worksurface_corner_radius)||0}/>}
    {Array.from({length:g.rows},(_,r)=>[r*C+inset,r*C+C-inset]).flat().map(y=><line key={'l'+y} className='wb-strip' x1={X(0)} x2={X(g.length)} y1={Y(y)} y2={Y(y)}/>)}
    {crossCols.flatMap(c=>[c*C+inset,c*C+C-inset]).map(x=><line key={'c'+x} className='wb-strip' x1={X(x)} x2={X(x)} y1={Y(0)} y2={Y(g.depth)}/>)}
    {Array.from({length:g.rows},(_,r)=>Array.from({length:g.cols},(_,c)=>{const empty=!list.some(k=>WB.covers(k,c,r));return <g key={c+'-'+r} className={'wb-cell'+(empty?' is-empty':'')} role='button' tabIndex={0} aria-label={empty?`Place a module in column ${c+1}, row ${r+1}`:`Select the module in column ${c+1}, row ${r+1}`} onClick={()=>pick(c,r)} onKeyDown={e=>{if(e.key==='Enter'||e.key===' '){e.preventDefault();pick(c,r)}}}>
     <rect x={X(c*C)+4} y={Y(r*C+C)+4} width={C-8} height={C-8} rx={10}/>
     {empty&&<text x={X(c*C+C/2)} y={Y(r*C+C/2)} textAnchor='middle' dominantBaseline='middle' fontSize={C*0.09}>+ module</text>}
    </g>}))}
    {order.map(k=>{const lv=level(k),pad=14+lv*16,x=X(k.col*C)+pad,y=Y((k.row+k.spanY)*C)+pad,w=k.spanX*C-2*pad,h=k.spanY*C-2*pad,fs=Math.min(C*0.085,w/6);
     const face=k.facing==='front'?[x,y+h,x+w,y+h]:k.facing==='back'?[x,y,x+w,y]:k.facing==='left'?[x,y,x,y+h]:[x+w,y,x+w,y+h];
     return <g key={k.index} className={'wb-module'+(k.index===index?' is-selected':'')+(k.contents==='open'||k.contents==='framed'?' is-open':'')} pointerEvents='none'>
      <rect x={x} y={y} width={w} height={h} rx={6}/>
      <line className='wb-face' x1={face[0]} y1={face[1]} x2={face[2]} y2={face[3]}/>
      <text x={x+w/2} y={y+h/2-fs*0.6} textAnchor='middle' fontSize={fs} fontWeight={700}>M{k.index+1}{lv?' · on M'+(list.filter(o=>o.top<=k.z+0.01&&o.col<k.col+k.spanX&&k.col<o.col+o.spanX&&o.row<k.row+k.spanY&&k.row<o.row+o.spanY).sort((a,b)=>b.top-a.top)[0].index+1):''}</text>
      <text x={x+w/2} y={y+h/2+fs*0.7} textAnchor='middle' fontSize={fs*0.8}>{describe(k)} · {formatShop(k.height,units)}</text>
     </g>})}
    <text className='wb-front' x={X(g.length/2)} y={Y(-size.overhang)+34} textAnchor='middle' fontSize={26}>FRONT</text>
   </svg>
   {problems.length>0?<div className='lay-problems' role='alert'><Info size={16}/><div>{problems.map(p=><p key={p}>{p}</p>)}</div></div>
   :<p className='lay-hint'><Info size={14}/>Bench height {fmt(size.h)} to the worksurface top{list.some(k=>k.top<benchTop-0.01)?'; the worksurface rests on the tallest modules':''}. Modules sit on the frame's registration tabs; stacked modules sit on loose keys in the top rails below.</p>}
  </div>
  <aside className='lay-inspector'>
   {!m?<header><h3>No modules yet</h3><p>Click a cell of the grid to place the first cabinet module.</p></header>:<>
    <header><span className='eyebrow'>MODULE {index+1} OF {list.length}</span><h3>{title(m)}</h3>
     <p>{fmt(WB.moduleSize(m,C).w)} wide × {fmt(WB.moduleSize(m,C).d)} deep × {fmt(m.height)} high{m.z>WB.baseHeight(values)+0.01&&<span className='lay-badge'><Layers size={11}/>Stacked</span>}</p></header>
    {stackHere.length>1&&<div className='lay-field'><span>Stack in these cells</span><div className='segmented'>{stackHere.map(k=><button key={k.index} type='button' className={k.index===index?'is-active':''} onClick={()=>setSel(k.index)}>M{k.index+1}</button>)}</div></div>}
    <Segmented label='Contents' className='wb-contents' value={m.contents} options={WB.CONTENTS.map(c=>[c,WB.CONTENTS_LABEL[c]] as [WB.Contents,string])} onChange={v=>edit(index,{5:v})}/>
    {drawers>0&&<Stepper label={columns===2?'Drawer levels':'Drawers'} value={m.drawers} min={1} max={8} onChange={n=>edit(index,{9:n})}/>}
    {WB.canSplitDrawers(m,C)&&<Segmented label='Drawers across' value={String(columns) as '1'|'2'} options={[['1','One wide'],['2','Two side by side']]} onChange={v=>edit(index,{10:Number(v)})}/>}
    {columns===2&&<p className='field-note'>A centre partition carries the inner slides of both drawers on each level.</p>}
    <Segmented label='Faces' value={m.facing} options={WB.FACINGS.map(f=>[f,FACING_LABEL[f]] as [WB.Facing,string])} onChange={v=>edit(index,{7:v})}/>
    {doors===1&&<Segmented label='Hinged on the' value={m.hinge} options={[['left','Left'],['right','Right']]} onChange={v=>edit(index,{8:v})}/>}
    {doors===2&&<p className='field-note'>Two doors, hinged on the outer edges.</p>}
    {m.contents==='framed'&&<p className='field-note'>A face panel with a rounded opening covers the front.</p>}
    <div className='lay-field'><span>Height</span><DimensionInput id='wb-height' value={m.height} units={units} bounds={[minH,2400,1]} onChange={v=>v!==null&&edit(index,{4:v})}/>
     {Math.abs(m.top-benchTop)>0.5&&<button type='button' className='link-button' onClick={()=>edit(index,{4:Math.max(minH,benchTop-m.z)})}>Match the bench height ({fmt(benchTop-m.z)})</button>}</div>
    {m.contents!=='drawers'&&<Stepper label={m.contents==='drawer_door'?'Shelves behind the door':'Shelves'} value={m.shelves} min={0} max={8} onChange={n=>edit(index,{6:n})}/>}
    <Stepper label='Cells wide' value={m.spanX} min={1} max={Math.max(1,g.cols-m.col)} onChange={n=>edit(index,{2:n})}/>
    <Stepper label='Cells deep' value={m.spanY} min={1} max={Math.max(1,g.rows-m.row)} onChange={n=>edit(index,{3:n})}/>
    <div className='lay-field'><span>Move</span><div className='wb-move'>
     <button type='button' aria-label='Move left' disabled={m.col<=0} onClick={()=>edit(index,{0:m.col-1})}><ArrowLeft size={15}/></button>
     <button type='button' aria-label='Move towards the front' disabled={m.row<=0} onClick={()=>edit(index,{1:m.row-1})}><ArrowDown size={15}/></button>
     <button type='button' aria-label='Move towards the back' disabled={m.row+m.spanY>=g.rows} onClick={()=>edit(index,{1:m.row+1})}><ArrowUp size={15}/></button>
     <button type='button' aria-label='Move right' disabled={m.col+m.spanX>=g.cols} onClick={()=>edit(index,{0:m.col+1})}><ArrowRight size={15}/></button>
    </div></div>
    <div className='lay-actions'>
     <button type='button' onClick={()=>stackOn(m)}><Layers size={15}/>Stack a module on top</button>
     <button type='button' className='is-danger' onClick={()=>remove(index)}><Trash2 size={15}/>Remove M{index+1}</button>
    </div>
   </>}
  </aside>
 </div>;
}
