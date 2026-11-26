'use client';
// Editor for a product (lib/products): its settings as a column of collapsible sections,
// each with a one-line summary, beside a drawing, the exact 3D model, the cut list with
// the engine's checks, and the assembly order. The engine check, cut list, export page and
// recovery are the ones the cabinets use, pointed at the product's SCAD file.
import {useEffect,useMemo,useState} from 'react';
import {Box,ChevronDown,ChevronRight,Check,EyeOff,Hammer,Info,ListChecks,PencilRuler,Redo2,RotateCcw,Undo2,Package} from 'lucide-react';
import {Select,SelectTrigger,SelectValue,SelectContent,SelectItem} from '@/components/ui/select';
import {Tabs,TabsList,TabsTrigger,TabsContent} from '@/components/ui/tabs';
import {Switch} from '@/components/ui/switch';
import type {Values} from '@/lib/cabinet';
import type {Product,ProductControl,ProductSection} from '@/lib/products/types';
import {productTarget} from '@/lib/products';
import {records} from '@/lib/analysis';
import {formatDimension,type Units} from '@/lib/units';
import DimensionInput from '../DimensionInput';
import SettingHelp from '../SettingHelp';
import OpenSCADView from '../OpenSCADView';
import PlanPanel,{StatusChip} from '../PlanPanel';
import type {Analysis} from '../useEngineAnalysis';
import {diagrams} from './diagrams';
import {Stepper} from './MediaCartDiagram';

type Props={
 product:Product;values:Values;units:Units;analysis:Analysis&{rerun:()=>void};name:string;
 change:(key:string,value:unknown)=>void;
 undo:()=>void;redo:()=>void;canUndo:boolean;canRedo:boolean;
 onChangeType:()=>void;onStarter:(id:string)=>void;onReset:()=>void;
 openSection:string|null;setOpenSection:(id:string|null)=>void;
};

function Control({c,values,units,change}:{c:ProductControl;values:Values;units:Units;change:(k:string,v:unknown)=>void}){
 const value=values[c.key],reason=c.when?.(values)??null,id='product-'+c.key,off=!!reason;
 const toggle=c.kind==='toggle'||typeof value==='boolean';
 return <div className={'field'+(off?' is-inactive':'')+(toggle?' toggle-field':'')} aria-disabled={off||undefined}>
  {c.kind==='count'?<Stepper id={id} label={c.label} value={Number(value)} min={1} max={12} onChange={n=>change(c.key,n)}/>:<>
   <SettingHelp id={id} title={c.label} help={c.help??''} advanced={c.advanced}/>
   {toggle?<Switch id={id} checked={!!value} onCheckedChange={v=>change(c.key,v)}/>:
    c.kind==='choice'||c.options?<Select value={String(value)} onValueChange={v=>change(c.key,v)}><SelectTrigger id={id} className='choice'><SelectValue/></SelectTrigger><SelectContent>{Object.entries(c.options??{}).map(([k,l])=><SelectItem key={k} value={k}>{l}</SelectItem>)}</SelectContent></Select>:
    c.kind==='length'?<DimensionInput id={id} value={Number(value)} units={units} onChange={v=>{if(v!==null)change(c.key,v)}}/>:
    <input id={id} type='number' value={Number(value)} onChange={e=>{if(e.target.value!==''&&Number.isFinite(e.target.valueAsNumber))change(c.key,e.target.valueAsNumber)}}/>}
  </>}
  {reason&&<small className='inactive-reason'>{reason}</small>}
 </div>;
}

function SectionCard({s,open,onToggle,values,units,change}:{s:ProductSection;open:boolean;onToggle:()=>void;values:Values;units:Units;change:(k:string,v:unknown)=>void}){
 const [advanced,setAdvanced]=useState(false);
 const active=s.controls.filter(c=>!c.when?.(values)),inactive=s.controls.filter(c=>c.when?.(values));
 const hidden=active.filter(c=>c.advanced).length;
 const shown=active.filter(c=>advanced||!c.advanced);
 return <section className={'pw-section'+(open?' is-open':'')} id={'pw-section-'+s.id}>
  <button type='button' className='pw-section-head' aria-expanded={open} aria-controls={'pw-body-'+s.id} onClick={onToggle}>
   <ChevronRight size={16} className={open?'turned':''}/>
   <span><strong>{s.title}</strong>{s.summary&&<small>{s.summary(values,units)}</small>}</span>
  </button>
  {open&&<div className='pw-section-body' id={'pw-body-'+s.id}>
   {s.blurb&&<p className='section-blurb'>{s.blurb}</p>}
   {hidden>0&&<label className='advanced-control'><Switch checked={advanced} onCheckedChange={setAdvanced}/>Show advanced <span>{hidden}</span></label>}
   {shown.map(c=><Control key={c.key} c={c} values={values} units={units} change={change}/>)}
   {inactive.length>0&&<details className='inactive-settings'>
    <summary><EyeOff size={15}/>{inactive.length} setting{inactive.length===1?'':'s'} not in use</summary>
    {inactive.map(c=><Control key={c.key} c={c} values={values} units={units} change={change}/>)}
   </details>}
  </div>}
 </section>;
}

export default function ProductWorkspace({product,values,units,analysis,name,change,undo,redo,canUndo,canRedo,onChangeType,onStarter,onReset,openSection,setOpenSection}:Props){
 const Diagram=diagrams[product.id];
 const [tab,setTab]=useState(Diagram?'drawing':'model');
 const [shopOpen,setShopOpen]=useState(false);
 const target=useMemo(()=>productTarget(product),[product]);
 const errors=product.validate(values);
 // Opening a section from the drawing brings it into view (and opens the shop group).
 useEffect(()=>{if(!openSection)return;requestAnimationFrame(()=>{const el=document.getElementById('pw-section-'+openSection),box=el?.closest('.pw-sections') as HTMLElement|null;if(!el)return;if(box&&box.scrollHeight>box.clientHeight)box.scrollTo({top:el.offsetTop-8,behavior:'smooth'});else el.scrollIntoView({block:'nearest',behavior:'smooth'})})},[openSection]);
 const starter=values._starter&&values._starter!=='edited'?product.starters.find(s=>s.id===values._starter):null;
 const plan=analysis.plan&&analysis.planKey===analysis.key?analysis.plan:null;
 const issueCount=plan?plan.issues.filter(i=>i.severity==='error').length:0;
 // The drawing shows the joinery and stability of the newest engine check, faded while a
 // check for the current values runs.
 const recs=useMemo(()=>analysis.log?records(analysis.log):[],[analysis.log]),recsStale=analysis.planKey!==analysis.key;
 const hardware=plan?recs.filter(r=>r.startsWith('HARDWARE|')).map(r=>Object.fromEntries(r.split('|').slice(1).map(x=>{const i=x.indexOf('=');return [x.slice(0,i),x.slice(i+1)]}))):[];
 const fmt=(mm:number)=>formatDimension(mm,units);
 const main=product.sections.filter(s=>!s.shop),shop=product.sections.filter(s=>s.shop);
 // The shop group shows while one of its sections is open (for example from Change sheet size).
 const shopShown=shopOpen||shop.some(s=>s.id===openSection);
 const card=(s:ProductSection)=><SectionCard key={s.id} s={s} open={openSection===s.id} onToggle={()=>setOpenSection(openSection===s.id?null:s.id)} values={values} units={units} change={change}/>;
 return <div className='workspace cw-workspace pw-workspace'>
  <aside className='config cw-config pw-config' aria-label={product.name+' settings'}>
   <div className='config-top'>
    <div className='type-card'>
     <span className='type-icon'><Package size={22}/></span>
     <div><span className='eyebrow'>YOUR PRODUCT</span><strong>{product.name}</strong><small>{starter?'Starter · '+starter.name:'Custom configuration'}</small></div>
     <button onClick={onChangeType} aria-label='Change product, cabinet type or starter'>Change<ChevronDown size={15}/></button>
    </div>
    <div className='starter-row'>
     <label htmlFor='product-starter'>Starting point</label>
     <Select value={String(values._starter??'edited')} onValueChange={onStarter}>
      <SelectTrigger id='product-starter' className='choice starter-choice'><SelectValue/></SelectTrigger>
      <SelectContent>
       <SelectItem value='edited' disabled>Custom · edited configuration</SelectItem>
       {product.starters.map(s=><SelectItem key={s.id} value={s.id}>{s.name}</SelectItem>)}
      </SelectContent>
     </Select>
     <button className='icon-button' title='Restore the default starter' aria-label='Reset to defaults' onClick={onReset}><RotateCcw size={16}/></button>
    </div>
   </div>
   <div className='pw-sections'>
    {main.map(card)}
    <button type='button' className='pw-shop-toggle' aria-expanded={shopShown} onClick={()=>{if(shopShown&&shop.some(s=>s.id===openSection))setOpenSection(null);setShopOpen(!shopShown)}}><ChevronRight size={14} className={shopShown?'turned':''}/>Shop details<small>materials, joinery, machining, casters, sheets</small></button>
    {shopShown&&shop.map(card)}
   </div>
   <div className='config-footer'><span>{product.name} engine</span><strong>{product.file.split('/').pop()}</strong></div>
  </aside>
  <section className='design-surface'>
   <div className='surface-header'>
    <div><div className='eyebrow'>{product.code} <span>/</span> PRODUCT DESIGN</div><h1>{name||product.name}</h1></div>
    <div className='surface-tools'>
     <StatusChip analysis={analysis} onClick={()=>setTab('plan')}/>
     <div className='history'><button onClick={undo} disabled={!canUndo} aria-label='Undo' title='Undo (Ctrl+Z)'><Undo2 size={18}/></button><button onClick={redo} disabled={!canRedo} aria-label='Redo' title='Redo (Ctrl+Shift+Z)'><Redo2 size={18}/></button></div>
    </div>
   </div>
   <Tabs value={tab} onValueChange={setTab} className='view-tabs'>
    <div className='canvas-toolbar'>
     <TabsList className='view-switch pw-view-switch'>
      {Diagram&&<TabsTrigger value='drawing'><PencilRuler size={16}/>Drawing</TabsTrigger>}
      <TabsTrigger value='model'><Box size={16}/>3D model</TabsTrigger>
      <TabsTrigger value='plan'><ListChecks size={16}/>Cut list & fit{issueCount>0&&<span className='tab-badge'>{issueCount}</span>}</TabsTrigger>
      <TabsTrigger value='assembly'><Hammer size={16}/>Assembly</TabsTrigger>
     </TabsList>
     <span className='schematic-label'>{tab==='drawing'?'Instant elevations · click a part to edit it':tab==='model'?'OpenSCAD geometry · joinery, holes and dados':tab==='assembly'?'Order of assembly and hardware':'Engine-calculated parts'}</span>
    </div>
    {Diagram&&<TabsContent value='drawing' className='pw-drawing-content'>
     {errors.length?<div className='validation-panel'><Info/><h2>Check your dimensions</h2>{errors.map(e=><p key={e}>{e}</p>)}</div>:<Diagram values={values} units={units} change={change} focus={setOpenSection} records={recs} stale={recsStale}/>}
    </TabsContent>}
    <TabsContent value='model' forceMount hidden={tab!=='model'} className='model-content'>
     <div className='native-content'><OpenSCADView family={0} values={values} active={tab==='model'} parts={[]} target={target}/></div>
    </TabsContent>
    <TabsContent value='plan' className='plan-content'>
     <PlanPanel analysis={analysis} units={units} name={name} values={values} coverage={product.coverage} sheetsWhere='Sheets & layout under Shop details'/>
    </TabsContent>
    <TabsContent value='assembly' className='plan-content'>
     <div className='plan pw-assembly'>
      <h3 className='plan-heading'>Assembly order</h3>
      <ol>{product.assemblySteps(values).map((s,i)=><li key={i}>{s}</li>)}</ol>
      <h3 className='plan-heading'>Hardware</h3>
      {hardware.length?<ul className='hardware-list'>{hardware.map((h,i)=><li key={i}><strong>{h.QTY}</strong> {String(h.ID).replaceAll('_',' ')}{h.NOTE&&<small>{h.NOTE}</small>}</li>)}</ul>:<p className='field-note'>{analysis.state==='failed'?analysis.error:'Counted by the engine check…'}</p>}
      <p className='field-note'>The printable assembly packet in the export holds this order with the parts list and the engine&rsquo;s notes.</p>
     </div>
    </TabsContent>
   </Tabs>
   <div className='summary-bar'>
    {product.summary(values).map(s=><div key={s.label}><span>{s.label}</span><strong>{s.mm!==undefined?<>{fmt(s.mm)}<small>{units}</small></>:s.text}</strong></div>)}
    <div className='status'>{errors.length?<><Info size={17}/>Check dimensions</>:<><Check size={17}/>Input ranges checked</>}</div>
   </div>
  </section>
 </div>;
}
