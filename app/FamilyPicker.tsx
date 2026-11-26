'use client';
import {useEffect,useMemo,useState} from 'react';
import {Archive,ChefHat,Inbox,Layers3,Printer,ShoppingCart,SquareStack,ArrowRight,Grid3x3,Package} from 'lucide-react';
import {Dialog,DialogContent,DialogHeader,DialogTitle,DialogDescription} from '@/components/ui/dialog';
import {families,schemas,starterValues} from '@/lib/cabinet';
import {formatShop,Units} from '@/lib/units';
import {products,productById,productStarterValues} from '@/lib/products';

export const familyIcons=[ShoppingCart,Archive,SquareStack,Layers3,ChefHat,Inbox,Printer,Grid3x3];

function starterSize(family:number,id:string,units:Units){
 try{
  const v=starterValues(family,id);
  const d=[v.custom_cabinet_width,v.custom_cabinet_height,v.custom_cabinet_depth].map(Number);
  return d.every(n=>Number.isFinite(n)&&n>0)?d.map(n=>formatShop(n,units)).join(' × ')+(units==='mm'?' mm':''):'';
 }catch{return ''}
}

function productSize(id:string,starter:string,units:Units){
 const p=productById(id);if(!p)return '';
 const mm=p.summary(productStarterValues(p,starter)).filter(s=>s.mm!==undefined).map(s=>formatShop(s.mm!,units));
 return mm.join(' × ')+(units==='mm'?' mm':'');
}
type Entry={id:string;name:string;group?:string};
// One place to choose what to build: a cabinet type or one of your products first, then a
// starting configuration. Products (lib/products) open their own editor.
export default function FamilyPicker({open,onOpenChange,family,product,units,onChoose,onChooseProduct}:{open:boolean;onOpenChange:(o:boolean)=>void;family:number;product?:string;units:Units;onChoose:(family:number,starter:string)=>void;onChooseProduct:(id:string,starter:string)=>void}){
 const current=product?'p:'+product:'f:'+family;
 const [active,setActive]=useState(current);
 useEffect(()=>{if(open)setActive(current)},[open,current]);
 const chosenProduct=active.startsWith('p:')?productById(active.slice(2)):undefined,chosenFamily=chosenProduct?-1:Number(active.slice(2));
 const groups=useMemo(()=>{
  const map=new Map<string,Entry[]>();
  const list:Entry[]=chosenProduct?chosenProduct.starters:schemas[chosenFamily].starters,def=chosenProduct?chosenProduct.defaultStarter:schemas[chosenFamily].defaultStarter;
  for(const s of list){
   const g=s.id===def?'Start here':s.group??'Presets';
   map.set(g,[...(map.get(g)??[]),s]);
  }
  return [...map.entries()];
 },[active]);
 const title=chosenProduct?chosenProduct.name:families[chosenFamily].name;
 return <Dialog open={open} onOpenChange={onOpenChange}>
  <DialogContent className='family-dialog'>
   <DialogHeader>
    <DialogTitle>What are you building?</DialogTitle>
    <DialogDescription>Pick a cabinet type or one of your products, then a starting point. Every value stays editable afterwards; your current design remains in Recent.</DialogDescription>
   </DialogHeader>
   <div className='family-dialog-body'>
    <div className='family-grid' role='listbox' aria-label='Cabinet type'>
     {families.map((f,i)=>{const Icon=familyIcons[i];return <button key={f.name} role='option' aria-selected={active==='f:'+i} className={active==='f:'+i?'is-active':''} onClick={()=>setActive('f:'+i)}>
      <Icon size={22}/><span><strong>{f.name}</strong><small>{f.sub}</small></span>
     </button>})}
     <span className='family-group-heading'>Your products</span>
     {products.map(p=><button key={p.id} role='option' aria-selected={active==='p:'+p.id} className={active==='p:'+p.id?'is-active':''} onClick={()=>setActive('p:'+p.id)}>
      <Package size={22}/><span><strong>{p.name}</strong><small>{p.sub}</small></span>
     </button>)}
    </div>
    <div className='starter-list' aria-label={'Starting points for '+title}>
     {groups.map(([group,starters])=><section key={group}>
      <h3>{group}</h3>
      {starters.map(s=><button key={s.id} onClick={()=>chosenProduct?onChooseProduct(chosenProduct.id,s.id):onChoose(chosenFamily,s.id)}>
       <span><strong>{chosenProduct?s.name:s.id===schemas[chosenFamily].defaultStarter?'Default '+title.toLowerCase():s.name}</strong><small>{chosenProduct?productSize(chosenProduct.id,s.id,units):starterSize(chosenFamily,s.id,units)}</small></span>
       <ArrowRight size={16}/>
      </button>)}
     </section>)}
    </div>
   </div>
  </DialogContent>
 </Dialog>;
}
