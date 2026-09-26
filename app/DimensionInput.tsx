'use client';
import {useEffect,useRef,useState} from 'react';
import {formatDimension,fromMillimeters,toMillimeters,Units} from '@/lib/units';
export default function DimensionInput({value,units,onChange,id,automatic=false,bounds}:{value:number|null;units:Units;onChange:(v:number|null)=>void;id:string;automatic?:boolean;bounds?:number[]|null}){
 const display=()=>value===null?'':formatDimension(value,units);const [draft,setDraft]=useState(display),dirty=useRef(false);
 useEffect(()=>{setDraft(display());dirty.current=false},[value,units]);
 function commit(){if(!dirty.current)return;dirty.current=false;if(draft===''&&automatic){onChange(null);return}const n=Number(draft);if(draft.trim()!==''&&Number.isFinite(n)){onChange(toMillimeters(n,units));setDraft(n.toFixed(2))}else setDraft(display())}
 return <div className='number-wrap'><input id={id} type='number' step='any' value={draft} min={bounds?fromMillimeters(bounds[0],units):undefined} max={bounds?fromMillimeters(bounds[1],units):undefined} placeholder={automatic?'Automatic':undefined} onChange={e=>{dirty.current=true;setDraft(e.target.value)}} onBlur={commit} onKeyDown={e=>{if(e.key==='Enter')e.currentTarget.blur()}}/><span>{units}</span></div>
}
