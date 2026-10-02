'use client';
import {useEffect,useMemo,useState} from 'react';
import {Archive,ChefHat,Inbox,Layers3,Printer,ShoppingCart,SquareStack,ArrowRight} from 'lucide-react';
import {Dialog,DialogContent,DialogHeader,DialogTitle,DialogDescription} from '@/components/ui/dialog';
import {families,schemas,starterValues} from '@/lib/cabinet';
import {formatShop,Units} from '@/lib/units';

export const familyIcons=[ShoppingCart,Archive,SquareStack,Layers3,ChefHat,Inbox,Printer];

function starterSize(family:number,id:string,units:Units){
 try{
  const v=starterValues(family,id);
  const d=[v.custom_cabinet_width,v.custom_cabinet_height,v.custom_cabinet_depth].map(Number);
  return d.every(n=>Number.isFinite(n)&&n>0)?d.map(n=>formatShop(n,units)).join(' × ')+(units==='mm'?' mm':''):'';
 }catch{return ''}
}

// One place to choose what to build: cabinet type first, then a starting configuration.
export default function FamilyPicker({open,onOpenChange,family,units,onChoose}:{open:boolean;onOpenChange:(o:boolean)=>void;family:number;units:Units;onChoose:(family:number,starter:string)=>void}){
 const [active,setActive]=useState(family);
 useEffect(()=>{if(open)setActive(family)},[open,family]);
 const groups=useMemo(()=>{
  const map=new Map<string,typeof schemas[number]['starters']>();
  for(const s of schemas[active].starters){
   const g=s.id===schemas[active].defaultStarter?'Start here':s.group??'Presets';
   map.set(g,[...(map.get(g)??[]),s]);
  }
  return [...map.entries()];
 },[active]);
 return <Dialog open={open} onOpenChange={onOpenChange}>
  <DialogContent className='family-dialog'>
   <DialogHeader>
    <DialogTitle>What are you building?</DialogTitle>
    <DialogDescription>Pick a cabinet type, then a starting point. Every value stays editable afterwards; your current design remains in Recent.</DialogDescription>
   </DialogHeader>
   <div className='family-dialog-body'>
    <div className='family-grid' role='listbox' aria-label='Cabinet type'>
     {families.map((f,i)=>{const Icon=familyIcons[i];return <button key={f.name} role='option' aria-selected={active===i} className={active===i?'is-active':''} onClick={()=>setActive(i)}>
      <Icon size={22}/><span><strong>{f.name}</strong><small>{f.sub}</small></span>
     </button>})}
    </div>
    <div className='starter-list' aria-label={'Starting points for '+families[active].name}>
     {groups.map(([group,starters])=><section key={group}>
      <h3>{group}</h3>
      {starters.map(s=><button key={s.id} onClick={()=>onChoose(active,s.id)}>
       <span><strong>{s.id===schemas[active].defaultStarter?'Default '+families[active].name.toLowerCase():s.name}</strong><small>{starterSize(active,s.id,units)}</small></span>
       <ArrowRight size={16}/>
      </button>)}
     </section>)}
    </div>
   </div>
  </DialogContent>
 </Dialog>;
}
