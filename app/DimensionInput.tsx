'use client';
import {useEffect,useRef,useState} from 'react';
import {formatFraction,formatInput,parseDimension,Units} from '@/lib/units';
// Text entry so inch users can type fractions (23 1/2, 3/4") or override the unit (600 mm). Values commit on blur/Enter.
export default function DimensionInput({value,units,onChange,id,automatic=false,bounds}:{value:number|null;units:Units;onChange:(v:number|null)=>void;id:string;automatic?:boolean;bounds?:number[]|null}){
 const display=()=>value===null?'':formatInput(value,units);
 const [draft,setDraft]=useState(display),[invalid,setInvalid]=useState(false),dirty=useRef(false);
 useEffect(()=>{setDraft(display());setInvalid(false);dirty.current=false},[value,units]);
 function commit(){
  if(!dirty.current)return;
  dirty.current=false;
  if(draft.trim()===''&&automatic){setInvalid(false);onChange(null);return}
  const mm=parseDimension(draft,units);
  if(Number.isFinite(mm)){setInvalid(false);onChange(mm);setDraft(formatInput(mm,units))}
  else{setInvalid(true);setDraft(display())}
 }
 const range=bounds?`Range ${formatInput(bounds[0],units)}–${formatInput(bounds[1],units)} ${units}. `:'';
 const hint=units==='in'?'Decimals or fractions (23 1/2). Add mm to enter metric.':'Millimeters. Add in or " to enter inches (23 1/2 in).';
 const fraction=units==='in'&&value!==null&&Math.abs(value)>=0.75?' ≈ '+formatFraction(value)+'″. ':' ';
 return <div className={'number-wrap'+(invalid?' is-invalid':'')} title={(range+fraction+hint).trim()}>
  <input id={id} type='text' inputMode={units==='in'?'text':'decimal'} autoComplete='off' spellCheck={false} value={draft} aria-invalid={invalid||undefined}
   placeholder={automatic?'Automatic':undefined}
   onChange={e=>{dirty.current=true;setInvalid(false);setDraft(e.target.value)}} onBlur={commit} onKeyDown={e=>{if(e.key==='Enter')e.currentTarget.blur()}}/>
  <span>{units}</span>
 </div>;
}
