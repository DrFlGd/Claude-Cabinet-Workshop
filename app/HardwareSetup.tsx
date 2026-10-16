'use client';
// Hardware section of the settings panel. Drawer slides and hinges each start with one choice
// (how drawers run; which hinge), then the model: a generic one whose every dimension is
// editable, or a catalog model whose maker-defined dimensions are shown read-only until the
// user chooses to adjust them. Settings of the alternatives not chosen are not shown at all.
import {ReactNode} from 'react';
import {Eye,Lock,PencilRuler} from 'lucide-react';
import {Select,SelectTrigger,SelectValue,SelectContent,SelectItem,SelectGroup,SelectLabel,SelectSeparator} from '@/components/ui/select';
import {Values} from '@/lib/cabinet';
import {optionLabel} from '@/lib/help';
import {catalogFor,selection,chooseModel,chooseGeneric,Category,Profile,SLIDE_BODY,SLIDE_HOLES,HINGE_PLACEMENT,HINGE_DOOR,HINGE_CABINET,isWoodRunnerKey,isFixedRunnerKey,GENERIC} from '@/lib/hardware';

type FieldFor=(key:string,opts?:{locked?:boolean})=>ReactNode|null;
type Props={family:number;values:Values;keys:string[];options:(key:string)=>string[]|null;active:(key:string)=>boolean;fieldFor:FieldFor;apply:(patch:Values,message:string)=>void;onView:(kind:'slides'|'hinges')=>void};

const METHOD_LABELS:Record<string,string>={metal_slides:'Metal slides',wood_rails:'Wood runners',side_mount:'Metal slides',fixed_runner:'Fixed runners',euro_35mm:'35 mm cup hinge',screw_holes:'Screw-on hinge'};
const label=(key:string,o:string)=>o==='none'?(key==='hinge_style'?'No hinges':'No slides'):METHOD_LABELS[o]??optionLabel(key,o)??o.replace(/_/g,' ');

function Method({k,props,title}:{k:string;props:Props;title:string}){
 const opts=props.options(k)??[],value=String(props.values[k]);
 return <div className='hw-method'><span>{title}</span><div className='segmented' role='radiogroup' aria-label={title}>
  {opts.map(o=><button key={o} role='radio' aria-checked={value===o} className={value===o?'is-active':''} onClick={()=>value!==o&&props.apply({[k]:o},label(k,o)+' selected')}>{label(k,o)}</button>)}
 </div></div>;
}
function Fields({title,keys,props,locked,note}:{title:string;keys:string[];props:Props;locked?:boolean;note?:string}){
 const shown=keys.filter(k=>props.keys.includes(k)&&props.active(k)).map(k=>props.fieldFor(k,{locked})).filter(Boolean);
 if(!shown.length)return null;
 return <section className='hw-group'><h4>{title}</h4>{note&&<p className='field-note'>{note}</p>}{shown}</section>;
}
function ModelPicker({category,props}:{category:Category;props:Props}){
 const {family,values,apply}=props,{models,templates,reference}=catalogFor(family,category),sel=selection(values,family,category);
 const noun=category==='hinge'?'hinge':'slide';
 const byMaker=models.reduce((m,p)=>m.set(p.manufacturer,[...(m.get(p.manufacturer)??[]),p]),new Map<string,Profile[]>());
 const current=sel.mode==='catalog'?sel.profile.id:GENERIC;
 const pick=(id:string)=>{
  if(id===GENERIC){if(sel.mode!=='generic')apply(chooseGeneric(category,sel.profile),'Generic '+noun+': every dimension is editable');return}
  const p=models.find(x=>x.id===id);if(p)apply(chooseModel(category,p),p.label+' selected');
 };
 return <div className='hw-model'>
  <span>{category==='hinge'?'Hinge model':'Slide model'}</span>
  <Select value={current} onValueChange={pick}>
   <SelectTrigger className='choice' aria-label={category==='hinge'?'Hinge model':'Slide model'}><SelectValue/></SelectTrigger>
   <SelectContent>
    <SelectItem value={GENERIC}>Generic {noun} · enter every dimension</SelectItem>
    {[...byMaker].map(([maker,list])=><SelectGroup key={maker}><SelectSeparator/><SelectLabel>{maker}</SelectLabel>{list.map(p=><SelectItem key={p.id} value={p.id}>{p.label}</SelectItem>)}</SelectGroup>)}
   </SelectContent>
  </Select>
  {sel.mode==='catalog'?<div className='hw-catalog'>
   <p><strong>{sel.profile.manufacturer} · {sel.profile.family}</strong> {sel.profile.model}</p>
   <p className='field-note'><Lock size={12}/> Maker-defined dimensions are locked. {sel.profile.verification.notes}</p>
   {typeof sel.profile.source?.url==='string'&&/^https:\/\//.test(sel.profile.source.url)&&<a target='_blank' rel='noreferrer' href={sel.profile.source.url}>Maker's drawing</a>}
   <button onClick={()=>apply(chooseGeneric(category,sel.profile),'Generic '+noun+' based on '+sel.profile.label+': every dimension is editable')}><PencilRuler size={14}/>Adjust dimensions</button>
  </div>:<div className='hw-generic'>
   <p className='field-note'>{sel.basedOn?<>Started from <strong>{sel.basedOn.label}</strong>{sel.changed?.length?' and edited':''}. </>:null}Enter the dimensions from your {noun}'s drawing. The Hardware view shows where each hole lands.</p>
   {templates.length>0&&<div className='hw-templates'><span>Fill from</span>{templates.map(t=><button key={t.id} onClick={()=>apply({...t.apply,...chooseGeneric(category,t)},t.label+' dimensions filled in')}>{t.label.replace(/^Generic /,'')}</button>)}</div>}
  </div>}
  {reference.length>0&&<details className='hw-reference'><summary>{reference.length} more {noun} model{reference.length===1?'':'s'} in the library without drilling data</summary><p className='field-note'>The engine cannot represent their mounting yet, so they cannot be selected.</p><ul>{reference.map(p=><li key={p.id}>{p.label}</li>)}</ul></details>}
 </div>;
}
export default function HardwareSetup(props:Props){
 const {family,values,keys,active}=props;
 const mountKey=family===6?'slide_type':'drawer_mount',slides=keys.includes(mountKey)&&active(mountKey);
 const metal=family===6?values.slide_type!=='fixed_runner':values.drawer_mount==='metal_slides';
 const hinges=keys.includes('hinge_style')&&active('hinge_style');
 const slideSel=selection(values,family,'drawer_slide'),hingeSel=selection(values,family,'hinge');
 const locked=(s:typeof slideSel,key:string)=>s.mode==='catalog'&&Object.hasOwn(s.profile.apply??{},key);
 const split=(s:typeof slideSel,list:string[])=>[list.filter(k=>!locked(s,k)),list.filter(k=>locked(s,k))];
 if(!slides&&!hinges)return null;
 return <div className='hardware-setup'>
  {slides&&<section className='hw-card'>
   <header><h3>{family===6?'Tray slides':'Drawer slides'}</h3><button className='link-button' onClick={()=>props.onView('slides')}><Eye size={14}/>Show on the boards</button></header>
   <Method k={mountKey} props={props} title={family===6?'How trays run':'How drawers run'}/>
   {metal&&<>
    <ModelPicker category='drawer_slide' props={props}/>
    {(()=>{const [bodyFree,bodyLocked]=split(slideSel,SLIDE_BODY),[holesFree,holesLocked]=split(slideSel,SLIDE_HOLES);return <>
     <Fields title='Slide' keys={bodyFree} props={props}/>
     <Fields title='Mounting holes' keys={holesFree} props={props} note={values.include_metal_slide_holes===false?undefined:'Cabinet-side holes are measured from the front of the side panel; drawer-side holes from the front of the drawer box. Heights are from the bottom of the drawer box.'}/>
     <Fields title='From the maker' keys={[...bodyLocked,...holesLocked]} props={props} locked/>
    </>})()}
   </>}
   {family!==6&&values.drawer_mount==='wood_rails'&&<Fields title='Wood runners' keys={keys.filter(isWoodRunnerKey)} props={props}/>}
   {family===6&&values.slide_type==='fixed_runner'&&<Fields title='Fixed runners' keys={keys.filter(isFixedRunnerKey)} props={props}/>}
  </section>}
  {hinges&&<section className='hw-card'>
   <header><h3>Hinges</h3>{values.hinge_style!=='none'&&<button className='link-button' onClick={()=>props.onView('hinges')}><Eye size={14}/>Show on the boards</button>}</header>
   <Method k='hinge_style' props={props} title='Hinge type'/>
   {values.hinge_style!=='none'&&<>
    {values.hinge_style==='euro_35mm'&&<ModelPicker category='hinge' props={props}/>}
    <Fields title='Placement on the door' keys={HINGE_PLACEMENT} props={props}/>
    {(()=>{const sel=values.hinge_style==='euro_35mm'?hingeSel:{mode:'generic'} as const,[doorFree,doorLocked]=split(sel,HINGE_DOOR),[cabFree,cabLocked]=split(sel,HINGE_CABINET);return <>
     <Fields title='Door drilling' keys={doorFree} props={props}/>
     <Fields title='Cabinet side (mounting plate)' keys={cabFree} props={props}/>
     <Fields title='From the maker' keys={[...doorLocked,...cabLocked]} props={props} locked/>
    </>})()}
   </>}
  </section>}
 </div>;
}
