'use client';
// Front-elevation layout editor: click an opening to edit it, drag the boundaries
// between openings or drawers, and type exact sizes. Every edit is written back as
// ordinary engine settings (lib/layout.ts); fronts are drawn from the engine's own
// LAYOUT report once it has recalculated, so what you see is what will be cut.
import {useEffect,useMemo,useRef,useState} from 'react';
import {Columns2,Rows2,Trash2,Minus,Plus,Lock,Info,TriangleAlert,LoaderCircle,MousePointerClick} from 'lucide-react';
import {toast} from 'sonner';
import type {Values} from '@/lib/cabinet';
import type {LayoutReport} from '@/lib/analysis';
import type {Analysis} from './useEngineAnalysis';
import DimensionInput from './DimensionInput';
import {formatShop,type Units} from '@/lib/units';
import * as L from '@/lib/layout';

type Drag={kind:'split'|'drawer';path:L.Path;index:number;axis:'x'|'z';start:number;mmPerPx:number;sizes:number[];tree:L.LayoutNode;moved:boolean};
type Live={x:number;z:number;text:string}|null;

const modeNotes:Record<L.Mode,string>={
 legacy:'Openings share the full width; partitions and dividers are joined to the carcass.',
 mixed_bays:'Full-height bays separated by joined partitions.',
 sections:'Openings in any arrangement. Dividers are joined like bay partitions, and each opening’s slides, hinges and shelf pins are drilled into the members around it.',
};

export default function LayoutEditor({family,values,units,analysis,apply}:{family:number;values:Values;units:Units;analysis:Analysis;apply:(patch:Values)=>void}){
 const p=L.profile(family)!;
 const current=analysis.plan&&analysis.planKey===analysis.key?analysis.plan.layout:undefined;
 // While the engine recalculates a layout-only edit, the previous report still
 // describes the cabinet frame (outside size, opening, reveals).
 const envelope=L.envelopeKey(family,values);
 const last=useRef<{envelope:string;report:LayoutReport}|null>(null);
 if(current)last.current={envelope,report:current};
 const frameReport=current??(last.current?.envelope===envelope?last.current.report:undefined);
 const frame=useMemo(()=>L.frameFor(family,values,frameReport),[family,values,frameReport]);
 const [draft,setDraftState]=useState<L.LayoutNode|null>(null);
 const draftRef=useRef<L.LayoutNode|null>(null);
 const setDraft=(t:L.LayoutNode|null)=>{draftRef.current=t;setDraftState(t)};
 const committed=useMemo(()=>L.fromValues(family,values,current,frame),[family,values,current,frame]);
 const tree=draft??committed;
 const mode=L.currentMode(family,values);
 const report=draft?undefined:current;
 const g=useMemo(()=>tree?L.geometry(family,values,tree,frame,report):null,[family,values,tree,frame,report]);
 const [selected,setSelected]=useState('');
 const [hover,setHover]=useState<string|null>(null);
 const [live,setLive]=useState<Live>(null);
 const drag=useRef<Drag|null>(null);
 const svg=useRef<SVGSVGElement>(null);
 const [mmPerPx,setMmPerPx]=useState(1);
 useEffect(()=>{
  const el=svg.current;if(!el)return;
  const measure=()=>{const m=el.getScreenCTM();if(m&&m.a)setMmPerPx(1/m.a)};
  measure();const o=new ResizeObserver(measure);o.observe(el);return ()=>o.disconnect();
 },[frame.w,frame.h]);
 if(!tree||!g)return null;
 const cell=g.cells.find(c=>L.pathKey(c.path)===selected)??g.cells[0];
 const path=cell.path,node=cell.node,key=L.pathKey(path);
 const parentPath=path.slice(0,-1),parent=path.length?L.nodeAt(tree,parentPath) as L.Split:undefined;
 const combo=L.shape(tree)==='combo'&&mode==='legacy';
 const fronts=(c:L.Cell)=>L.frontsFor(c,values,report,mode);
 const fmt=(mm:number)=>formatShop(mm,units)+(units==='mm'?' mm':'');
 const short=(mm:number)=>units==='mm'?String(Math.round(mm)):formatShop(mm,units);
 const snap=(mm:number)=>units==='in'?Math.round(mm/1.5875)*1.5875:Math.round(mm);

 // ---- writing edits ----
 const check=(next:L.LayoutNode|L.Failure):string=>{
  if('error' in next)return next.error;
  const m=L.toValues(family,values,next,current,frame);
  return 'error' in m?m.error:'';
 };
 function commit(next:L.LayoutNode|L.Failure,select?:L.Path){
  setDraft(null);setLive(null);
  if('error' in next){toast.error(next.error);return}
  const m=L.toValues(family,values,next,current,frame);
  if('error' in m){toast.error(m.error);return}
  apply(m.patch);
  for(const n of m.notes)toast.info(n);
  if(m.mode!==mode)toast.info(m.mode==='sections'?'Built as a section layout: openings in any arrangement with joined dividers.':m.mode==='mixed_bays'?'Built as side-by-side bays with joined partitions.':'Built as a single cabinet layout with joined dividers.');
  if(select)setSelected(L.pathKey(select));
 }

 // ---- dragging ----
 function begin(e:React.PointerEvent,kind:Drag['kind'],hpath:L.Path,index:number,axis:'x'|'z',sizes:number[]){
  e.preventDefault();e.stopPropagation();
  const m=svg.current?.getScreenCTM();
  drag.current={kind,path:hpath,index,axis,start:axis==='x'?e.clientX:e.clientY,mmPerPx:m?1/(axis==='x'?m.a:m.d):1,sizes,tree:tree!,moved:false};
  svg.current?.setPointerCapture(e.pointerId);
  if(kind==='drawer')setSelected(L.pathKey(hpath));
 }
 function move(e:React.PointerEvent){
  const d=drag.current;if(!d)return;
  const px=(d.axis==='x'?e.clientX:e.clientY)-d.start;
  if(Math.abs(px)>2)d.moved=true;
  if(!d.moved)return;
  const a=d.sizes[d.index-1],b=d.sizes[d.index],min=d.kind==='drawer'?40:60;
  const delta=Math.max(min-a,Math.min(b-min,snap(a+px*d.mmPerPx)-a));
  if(d.kind==='split'){
   setDraft(L.moveBoundary(d.tree,d.path,d.index,delta,d.sizes,min));
  }else{
   setDraft(L.setDrawerHeights(d.tree,d.path,d.sizes.map((h,i)=>i===d.index-1?h+delta:i===d.index?h-delta:h)));
  }
  const pt=svg.current?.createSVGPoint();
  if(pt&&svg.current){pt.x=e.clientX;pt.y=e.clientY;const q=pt.matrixTransform(svg.current.getScreenCTM()!.inverse());setLive({x:q.x,z:frame.h-q.y,text:short(a+delta)+' | '+short(b-delta)})}
 }
 function end(cancel=false){
  const d=drag.current;drag.current=null;
  if(!d)return;
  if(cancel||!d.moved||!draftRef.current){setDraft(null);setLive(null);return}
  commit(draftRef.current);
 }

 // ---- drawing helpers (SVG y grows downward; engine z grows upward) ----
 const W=frame.w,H=frame.h,span=Math.max(W,H),pad=span*0.03,band=span*0.1;
 const y=(z:number)=>H-z;
 const px=(n:number)=>n*mmPerPx;
 const font=(n:number)=>px(n);
 const rectProps=(r:{x:number;z:number;w:number;h:number})=>({x:r.x,y:y(r.z+r.h),width:Math.max(0,r.w),height:Math.max(0,r.h)});
 const ff=frameReport?.faceFrame;
 const members=report?report.members.filter(m=>m.kind==='divider'||m.kind==='separator'):[];

 // Bottom and right dimension chains for the top-level split.
 const chainX=tree.kind==='x'?L.childSizes(g,tree,[]).map((s,i)=>({i,rect:g.rects.get(String(i))!,s})):[];
 const chainZ=tree.kind==='z'?L.childSizes(g,tree,[]).map((s,i)=>({i,rect:g.rects.get(String(i))!,s})):[];

 // ---- inspector values ----
 const inBay=!!parent&&parent.kind==='x'&&mode!=='sections'&&!(combo&&path.length===2);
 const maxDrawers=mode==='sections'?8:inBay?p.maxBayDrawers:p.maxDrawers;
 const maxDoors=mode==='sections'||inBay?Math.min(2,p.maxBayDoors||p.maxDoors):p.maxDoors;
 const nodeFronts=fronts(cell);
 const heights=nodeFronts.filter(f=>f.kind==='drawer').map(f=>f.nominal);
 const sizes=parent?L.childSizes(g,tree,parentPath):[];
 const index=path.at(-1)??0;
 const exact=!!report&&nodeFronts.every(f=>f.exact);
 const doorFront=combo&&key==='1'?nodeFronts.find(f=>f.kind==='door'):undefined;
 const sizeLabel=!parent?null:parent.kind==='x'?'Width':combo?(index===0?'Drawer area height':'Door height'):'Height';
 const sizeValue=!parent?0:doorFront?doorFront.h:parent.kind==='x'?cell.rect.w:cell.rect.h;
 function typeSize(mm:number|null){
  if(mm===null||!parent)return;
  const region=doorFront?mm-(doorFront.h-cell.rect.h):mm;
  commit(L.setChildSize(tree!,parentPath,index,region,sizes,mode==='sections'),path);
 }
 const name=openingName(tree,path,mode,combo);
 const can=(next:L.LayoutNode|L.Failure)=>{const why=check(next);return {disabled:!!why,title:why||undefined}};
 const count=(n:number)=>L.setLeaf(tree,path,{count:n});
 const shelves=(n:number)=>L.setLeaf(tree,path,{shelves:n});
 const errors=analysis.plan&&analysis.planKey===analysis.key?analysis.plan.issues.filter(i=>i.severity==='error'):[];
 const busy=analysis.state==='waiting'||analysis.state==='running';
 const label=(()=>{const m=L.toValues(family,values,tree,current,frame);return 'error' in m?'':m.label})();

 return <div className='lay'>
  <div className='lay-stage'>
   <div className='lay-head'>
    <div><strong>{label||'Layout'}</strong><span>{modeNotes[mode]}</span></div>
    <span className={'lay-state'+(busy?' is-busy':'')}>{busy?<><LoaderCircle size={14} className='spin'/>Recalculating exact sizes…</>:current?<>Sizes from the engine</>:<>Waiting for the engine</>}</span>
   </div>
   <svg ref={svg} className='lay-svg' viewBox={`${-pad} ${-pad} ${W+2*pad+band} ${H+2*pad+band}`} role='group' aria-label='Cabinet front layout. Select an opening to edit it.'
    onPointerMove={move} onPointerUp={()=>end()} onPointerCancel={()=>end(true)} onPointerLeave={()=>{if(!drag.current)setHover(null)}}>
    <rect className='lay-carcass' x={0} y={0} width={W} height={H}/>
    <rect className='lay-opening' {...rectProps(frame.open)}/>
    {ff&&<g className='lay-frame'>
     <rect x={0} y={y(ff.z1)} width={ff.stile} height={ff.z1-ff.z0}/>
     <rect x={W-ff.stile} y={y(ff.z1)} width={ff.stile} height={ff.z1-ff.z0}/>
     <rect x={ff.stile} y={y(ff.z0+ff.bottomRail)} width={W-2*ff.stile} height={ff.bottomRail}/>
     <rect x={ff.stile} y={y(ff.z1)} width={W-2*ff.stile} height={ff.topRail}/>
     {report?.faceFrame?.mid&&<rect x={ff.stile} y={y(report.faceFrame.mid[1])} width={W-2*ff.stile} height={report.faceFrame.mid[1]-report.faceFrame.mid[0]}/>}
    </g>}
    {/* split gaps = partitions / dividers */}
    {[...g.gaps.entries()].flatMap(([k,gap])=>{
     if(!gap)return [];
     const sp=L.nodeAt(tree,k?k.split('.').map(Number):[]) as L.Split;
     return sp.children.slice(1).map((_,i)=>{const a=g.rects.get(k?k+'.'+i:String(i))!,r=g.rects.get(k?k+'.'+(i+1):String(i+1))!;
      return sp.kind==='x'?<rect key={k+'g'+i} className='lay-member' x={a.x+a.w} y={y(a.z+a.h)} width={Math.max(0,r.x-a.x-a.w)} height={a.h}/>:<rect key={k+'g'+i} className='lay-member' x={a.x} y={y(a.z)} width={a.w} height={Math.max(0,a.z-r.z-r.h)}/>});
    })}
    {members.map(m=><rect key={m.id} className='lay-member' {...rectProps(m)}/>)}
    {/* open shelves */}
    {g.cells.filter(c=>c.node.contents==='open').flatMap(c=>shelfLines(c,report,frame.t,mode).map((z,i)=><rect key={L.pathKey(c.path)+'s'+i} className='lay-shelf' x={c.rect.x} y={y(z+frame.t)} width={c.rect.w} height={frame.t}/>))}
    {/* fronts */}
    {g.cells.flatMap(c=>fronts(c).map(f=>{
     const k=L.pathKey(c.path)+f.id,cx=f.x+f.w/2,top=f.z+f.h;
     if(f.kind==='drawer')return <g key={k} className={'lay-front'+(f.exact?'':' is-predicted')}><rect {...rectProps(f)} rx={px(2)}/><rect className='lay-pull' x={cx-Math.min(60,f.w*0.18)} y={y(top-Math.min(f.h*0.28,45))} width={Math.min(120,f.w*0.36)} height={px(3.5)} rx={px(1.5)}/>{px(13)<f.h&&<text className='lay-front-size' x={f.x+px(7)} y={y(f.z+f.h)+px(14)} fontSize={font(10.5)}>{short(f.nominal)}</text>}</g>;
     const hingeLeft=f.hinge!=='right',hx=hingeLeft?f.x:f.x+f.w,ox=hingeLeft?f.x+f.w:f.x;
     return <g key={k} className={'lay-front is-door'+(f.exact?'':' is-predicted')}><rect {...rectProps(f)} rx={px(2)}/><polyline className='lay-swing' points={`${ox},${y(top)} ${hx},${y(f.z+f.h/2)} ${ox},${y(f.z)}`}/><rect className='lay-pull' x={ox+(hingeLeft?-px(9):px(5.5))} y={y(f.z+f.h*0.62)} width={px(3.5)} height={Math.min(120,f.h*0.18)} rx={px(1.5)}/></g>;
    }))}
    {/* shelves behind doors */}
    {g.cells.filter(c=>c.node.contents==='doors'&&c.node.shelves>0).flatMap(c=>shelfLines(c,report,frame.t,mode).map((z,i)=><line key={L.pathKey(c.path)+'hs'+i} className='lay-hidden-shelf' x1={c.rect.x+px(4)} x2={c.rect.x+c.rect.w-px(4)} y1={y(z+frame.t/2)} y2={y(z+frame.t/2)}/>))}
    {/* openings: selection targets and labels */}
    {g.cells.map(c=>{
     const k=L.pathKey(c.path),sel=k===key,hov=hover===k,r=c.rect,text=L.describe(c.node),size=short(c.rect.w)+' × '+short(c.rect.h);
     const fs=Math.min(font(13),r.w/Math.max(6,text.length*0.62));
     return <g key={'cell'+k} className={'lay-cell'+(sel?' is-selected':'')+(hov?' is-hover':'')} data-layout-cell={k} data-section-id={c.node.ref?.section} role='button' tabIndex={0} aria-pressed={sel}
      aria-label={`${openingName(tree,c.path,mode,combo)}: ${text}, ${fmt(r.w)} wide, ${fmt(r.h)} high`}
      onPointerDown={e=>{if(e.button===0)setSelected(k)}} onPointerEnter={()=>setHover(k)} onFocus={()=>setSelected(k)}
      onKeyDown={e=>{if(e.key==='Enter'||e.key===' '){e.preventDefault();setSelected(k)}}}>
      <rect className='lay-hit' {...rectProps(r)}/>
      {(sel||hov)&&<rect className='lay-outline' x={r.x+px(1.5)} y={y(r.z+r.h)+px(1.5)} width={Math.max(0,r.w-px(3))} height={Math.max(0,r.h-px(3))} rx={px(3)}/>}
      {r.w>px(40)&&r.h>px(26)&&<g className='lay-label' transform={`translate(${r.x+r.w/2},${y(r.z+r.h/2)})`}>
       <rect x={-Math.min(r.w*0.45,Math.max(text.length,size.length)*fs*0.33+px(8))} y={-fs*1.25} width={2*Math.min(r.w*0.45,Math.max(text.length,size.length)*fs*0.33+px(8))} height={fs*2.6} rx={px(4)}/>
       <text y={-fs*0.15} textAnchor='middle' fontSize={fs} fontWeight={600}>{text}</text>
       <text y={fs*1.05} textAnchor='middle' fontSize={fs*0.82} className='lay-label-size'>{size}</text>
      </g>}
     </g>;
    })}
    {/* drawer boundaries (drag to change drawer heights) */}
    {g.cells.filter(c=>c.node.contents==='drawers'&&c.node.count>1).flatMap(c=>{
     const list=fronts(c),hs=list.map(f=>f.nominal);
     return list.slice(1).map((f,i)=>{const above=list[i],z=(above.z+f.z+f.h)/2;
      return <g key={'dh'+L.pathKey(c.path)+i} className='lay-handle is-drawer' onPointerDown={e=>begin(e,'drawer',c.path,i+1,'z',hs)}>
       <line x1={c.rect.x} x2={c.rect.x+c.rect.w} y1={y(z)} y2={y(z)}/>
       <rect className='lay-grip' x={c.rect.x+c.rect.w/2-px(14)} y={y(z)-px(2.5)} width={px(28)} height={px(5)} rx={px(2.5)}/>
      </g>});
    })}
    {/* opening boundaries */}
    {g.handles.map(h=>{
     const hp=h.path,s=L.childSizes(g,tree,hp),x1=h.axis==='x'?h.at:h.from,x2=h.axis==='x'?h.at:h.to,z1=h.axis==='x'?h.from:h.at,z2=h.axis==='x'?h.to:h.at;
     return <g key={'h'+L.pathKey(hp)+'-'+h.index} className={'lay-handle is-'+h.axis} data-layout-handle={L.pathKey(hp)+'/'+h.index} onPointerDown={e=>begin(e,'split',hp,h.index,h.axis,s)}>
      <line x1={x1} x2={x2} y1={y(z1)} y2={y(z2)}/>
      {h.axis==='x'?<rect className='lay-grip' x={h.at-px(3)} y={y((z1+z2)/2)-px(16)} width={px(6)} height={px(32)} rx={px(3)}/>:<rect className='lay-grip' x={(x1+x2)/2-px(16)} y={y(h.at)-px(3)} width={px(32)} height={px(6)} rx={px(3)}/>}
     </g>;
    })}
    {/* dimension chains */}
    <g className='lay-dims'>
     <DimX x0={0} x1={W} at={H+pad+band*0.72} label={short(W)} font={font(11)} tick={px(5)}/>
     {chainX.length>1&&chainX.map(c=><DimX key={c.i} x0={c.rect.x} x1={c.rect.x+c.rect.w} at={H+pad+band*0.28} label={short(c.s)} font={font(11)} tick={px(5)} onClick={()=>setSelected(String(c.i))}/>)}
     <DimZ z0={0} z1={H} at={W+pad+band*0.72} H={H} label={short(H)} font={font(11)} tick={px(5)}/>
     {chainZ.length>1&&chainZ.map(c=><DimZ key={c.i} z0={c.rect.z} z1={c.rect.z+c.rect.h} at={W+pad+band*0.28} H={H} label={short(c.s)} font={font(11)} tick={px(5)} onClick={()=>setSelected(String(c.i))}/>)}
    </g>
    {live&&<g className='lay-live' transform={`translate(${live.x},${y(live.z)})`}><rect x={px(10)} y={-px(26)} width={px(live.text.length*7.2+14)} height={px(22)} rx={px(4)}/><text x={px(17)} y={-px(10.5)} fontSize={font(12)}>{live.text}</text></g>}
   </svg>
   <p className='lay-hint'><MousePointerClick size={14}/>Click an opening to edit it. Drag a divider or the line between two drawers to resize; type exact sizes in the panel. Ctrl+Z undoes.</p>
  </div>

  <aside className='lay-inspector' aria-label='Selected opening'>
   <header>
    <span className='eyebrow' id='layout-inspector-title'>{name}</span>
    <h3>{L.describe(node)}</h3>
    <p>Opening {fmt(cell.rect.w)} × {fmt(cell.rect.h)}{exact?'':' (estimate)'}{node.fixed&&<span className='lay-badge' title='This size stays fixed when the cabinet is resized'><Lock size={11}/>Fixed</span>}</p>
   </header>

   <div className='lay-field'>
    <span>Contents</span>
    <div className='segmented' role='radiogroup' aria-label='Contents'>
     {(['drawers','doors','open'] as const).map(c=>{const next=L.changeContents(tree,path,c,p,inBay,cell.rect.w),state=c===node.contents?{disabled:false,title:undefined}:can(next);
      return <button key={c} role='radio' aria-checked={node.contents===c} className={node.contents===c?'is-active':''} {...state} onClick={()=>node.contents!==c&&commit(next,path)}>{c==='drawers'?'Drawers':c==='doors'?'Doors':'Open'}</button>})}
    </div>
   </div>

   {node.contents!=='open'&&<Stepper label={node.contents==='drawers'?'Drawers':'Doors'} value={node.count} min={1} max={node.contents==='drawers'?maxDrawers:maxDoors} make={count} can={can} commit={n=>commit(n,path)}/>}
   {node.contents!=='drawers'&&p.maxShelves>0&&<Stepper label={node.contents==='doors'?'Shelves behind the doors':'Shelves'} value={node.shelves} min={0} max={mode==='sections'?8:p.maxShelves} make={shelves} can={can} commit={n=>commit(n,path)}/>}
   {node.contents!=='drawers'&&node.shelves>0&&family!==3&&<div className='lay-field'><span>Shelf type</span><div className='segmented'>{(['adjustable','fixed'] as const).map(s=><button key={s} aria-pressed={node.shelfStyle===s} className={node.shelfStyle===s?'is-active':''} onClick={()=>node.shelfStyle!==s&&commit(L.setLeaf(tree,path,{shelfStyle:s}),path)}>{s==='fixed'?'Fixed':'Adjustable'}</button>)}</div></div>}
   {node.contents==='doors'&&node.count===1&&p.hinge&&<div className='lay-field'><span>Hinge side</span><div className='segmented'>{(['left','right'] as const).map(s=><button key={s} aria-pressed={node.hinge===s} className={node.hinge===s?'is-active':''} onClick={()=>node.hinge!==s&&commit(L.setLeaf(tree,path,{hinge:s}),path)}>{s==='left'?'Left':'Right'}</button>)}</div></div>}

   {node.contents==='drawers'&&node.count>1&&<div className='lay-field'>
    <span>Drawer heights</span>
    <div className='segmented'>{(['equal','graduated','custom_weights'] as const).map(m=><button key={m} aria-pressed={node.heightMode===m} className={node.heightMode===m?'is-active':''} onClick={()=>node.heightMode!==m&&commit(L.setLeaf(tree,path,m==='custom_weights'?{heightMode:m,weights:heights.map(h=>Math.round(h*1000)/1000)}:{heightMode:m}),path)}>{m==='equal'?'Equal':m==='graduated'?'Graduated':'Custom'}</button>)}</div>
    {node.heightMode==='graduated'&&<label className='lay-inline'>Each drawer taller by<input type='number' min={0.05} max={2} step={0.05} value={node.step} onChange={e=>{const v=e.target.valueAsNumber;if(Number.isFinite(v)&&v>=0)commit(L.setLeaf(tree,path,{step:v}),path)}}/><small>× top height</small></label>}
    <div className='lay-drawers'>
     <small>Front heights, top to bottom{exact?'':' (estimate until the engine recalculates)'}</small>
     {heights.map((h,i)=><label key={i}><span>{i+1}</span><DimensionInput id={`layout-drawer-${key}-${i}`} value={Math.round(h*1000)/1000} units={units} onChange={mm=>mm!==null&&commit(L.setDrawerHeight(tree,path,i,mm,heights),path)}/></label>)}
    </div>
   </div>}

   {sizeLabel&&<div className='lay-field'>
    <span>{sizeLabel}{mode==='sections'?' (fixed when typed)':''}</span>
    <DimensionInput id='layout-size' value={Math.round(sizeValue*1000)/1000} units={units} onChange={typeSize}/>
    {node.fixed&&<button className='link-button' onClick={()=>commit(L.moveBoundary(tree,parentPath,index>0?index:1,0,sizes,0),path)}>Make proportional</button>}
   </div>}
   {!parent&&<p className='lay-note'>This opening fills the cabinet front. Change the overall size in Sizing.</p>}

   {parent&&parent.kind==='x'&&(mode==='mixed_bays'||mode==='sections')&&<div className='lay-field'>
    <span>{mode==='sections'?'Dividers in this row':'Bay partitions'}</span>
    <div className='segmented'>{(['panel','none'] as const).map(d=>{const next=L.setDivider(tree,parentPath,d);return <button key={d} aria-pressed={parent.divider===d} className={parent.divider===d?'is-active':''} {...(parent.divider===d?{}:can(next))} onClick={()=>parent.divider!==d&&commit(next,path)}>{d==='panel'?'Full-depth panels':'None'}</button>})}</div>
   </div>}
   {parent&&parent.kind==='z'&&mode==='sections'&&<div className='lay-field'>
    <span>Dividers in this column</span>
    <div className='segmented'>{(['panel','rail','none'] as const).map(d=>{const next=L.setDivider(tree,parentPath,d);return <button key={d} aria-pressed={parent.divider===d} className={parent.divider===d?'is-active':''} onClick={()=>parent.divider!==d&&commit(next,path)}>{d==='panel'?'Panels':d==='rail'?'Front rails':'None'}</button>})}</div>
   </div>}

   <div className='lay-actions'>
    {(()=>{const next=L.splitColumns(tree,path,parent?.kind==='x'?sizes:undefined),state=can(next);return <button {...state} onClick={()=>commit(next,parent?.kind==='x'?[...parentPath,index+1]:[...path,1])}><Columns2 size={15}/>Split side by side</button>})()}
    {(()=>{const next=L.splitRows(tree,path,p,cell.rect.h),state=can(next);return <button {...state} onClick={()=>commit(next,[...path,0])}><Rows2 size={15}/>{p.nested?'Split top / bottom':'Drawers over doors'}</button>})()}
    {parent&&(()=>{const next=L.removeOpening(tree,path,sizes),state=can(next);return <button className='is-danger' {...state} onClick={()=>commit(next,parent.children.length>2?[...parentPath,Math.max(0,index-1)]:parentPath)}><Trash2 size={15}/>Remove this opening</button>})()}
   </div>
   {(()=>{const reasons=[can(L.splitColumns(tree,path,parent?.kind==='x'?sizes:undefined)).title,can(L.splitRows(tree,path,p,cell.rect.h)).title].filter(Boolean);return reasons.length?<p className='lay-note'><Info size={13}/>{reasons[0]}</p>:null})()}

   {errors.length>0&&<div className='lay-problems' role='status'><TriangleAlert size={15}/><div>{errors.slice(0,2).map(e=><p key={e.code+e.message}>{e.message}</p>)}{errors.length>2&&<p>…and {errors.length-2} more in Cut list & fit.</p>}</div></div>}
  </aside>
 </div>;
}

function openingName(tree:L.LayoutNode,path:L.Path,mode:L.Mode,combo:boolean){
 if(!path.length)return 'Whole front';
 const parts:string[]=[];let n:L.LayoutNode=tree;
 path.forEach((i,depth)=>{
  const s=n as L.Split,count=s.children.length;
  if(s.kind==='x')parts.push((mode==='mixed_bays'?'Bay ':mode==='sections'?'Column ':'Drawer column ')+(i+1));
  else if(combo&&depth===0)parts.push(i===0?'Drawers above':'Doors below');
  else parts.push(i===0?'Top':i===count-1?'Bottom':'Row '+(i+1));
  n=s.children[i];
 });
 return parts.join(' › ');
}

// Shelf bottoms (z) for an open or door opening: engine positions when reported, else even spacing.
function shelfLines(c:L.Cell,report:LayoutReport|undefined,t:number,mode:L.Mode):number[]{
 const n=c.node.shelves;
 if(!n)return [];
 if(report&&c.node.ref){
  const sec=c.node.ref.section!==undefined?report.bays.find(b=>b.section===c.node.ref!.section):undefined;
  const bay=mode==='sections'?(sec?sec.index+1:undefined):c.node.ref.bay!==undefined?c.node.ref.bay+1:c.node.ref.doors?0:undefined;
  const list=bay===undefined?[]:report.shelves.filter(s=>s.bay===bay).map(s=>s.z);
  if(list.length===n)return list;
 }
 return Array.from({length:n},(_,i)=>c.rect.z+c.rect.h*(i+1)/(n+1)-t/2);
}

function Stepper({label,value,min,max,make,can,commit}:{label:string;value:number;min:number;max:number;make:(n:number)=>L.LayoutNode;can:(n:L.LayoutNode)=>{disabled:boolean;title?:string};commit:(n:L.LayoutNode)=>void}){
 const down=value>min?can(make(value-1)):{disabled:true,title:undefined},up=value<max?can(make(value+1)):{disabled:true,title:`At most ${max}`};
 return <div className='lay-field lay-stepper'>
  <span>{label}</span>
  <div><button aria-label={'Fewer '+label.toLowerCase()} {...down} onClick={()=>commit(make(value-1))}><Minus size={15}/></button><output aria-live='polite'>{value}</output><button aria-label={'More '+label.toLowerCase()} {...up} onClick={()=>commit(make(value+1))}><Plus size={15}/></button></div>
 </div>;
}

function DimX({x0,x1,at,label,font,tick,onClick}:{x0:number;x1:number;at:number;label:string;font:number;tick:number;onClick?:()=>void}){
 return <g className={'lay-dim'+(onClick?' is-link':'')} onClick={onClick}>
  <line x1={x0} x2={x1} y1={at} y2={at}/><line x1={x0} x2={x0} y1={at-tick} y2={at+tick}/><line x1={x1} x2={x1} y1={at-tick} y2={at+tick}/>
  <text x={(x0+x1)/2} y={at-tick*0.6} textAnchor='middle' fontSize={font}>{label}</text>
 </g>;
}
function DimZ({z0,z1,at,H,label,font,tick,onClick}:{z0:number;z1:number;at:number;H:number;label:string;font:number;tick:number;onClick?:()=>void}){
 const y0=H-z0,y1=H-z1,mid=(y0+y1)/2;
 return <g className={'lay-dim'+(onClick?' is-link':'')} onClick={onClick}>
  <line x1={at} x2={at} y1={y0} y2={y1}/><line x1={at-tick} x2={at+tick} y1={y0} y2={y0}/><line x1={at-tick} x2={at+tick} y1={y1} y2={y1}/>
  <text x={at+tick*0.8} y={mid} fontSize={font} dominantBaseline='middle' transform={`rotate(90 ${at+tick*0.8} ${mid})`} textAnchor='middle'>{label}</text>
 </g>;
}
