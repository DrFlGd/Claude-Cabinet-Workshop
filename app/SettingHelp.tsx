'use client';
import {useState} from 'react';
import {Info} from 'lucide-react';
import {Tooltip,TooltipContent,TooltipProvider,TooltipTrigger} from '@/components/ui/tooltip';
export default function SettingHelp({id,title,help,advanced=false}:{id:string;title:string;help:string;advanced?:boolean}){
 const [open,setOpen]=useState(false);
 if(!help)return <span className='setting-label'><label htmlFor={id}>{title}</label>{advanced&&<span className='advanced-badge'>Advanced</span>}</span>;
 return <TooltipProvider><Tooltip open={open} onOpenChange={setOpen}><span className='setting-label' onMouseEnter={()=>setOpen(true)} onMouseLeave={()=>setOpen(false)}><label htmlFor={id}>{title}</label>{advanced&&<span className='advanced-badge'>Advanced</span>}<TooltipTrigger asChild><button type='button' className='setting-info' aria-label={'Help: '+title} onClick={()=>setOpen(true)}><Info size={16}/></button></TooltipTrigger></span><TooltipContent className='setting-tooltip' side='right' sideOffset={8}>{help}</TooltipContent></Tooltip></TooltipProvider>;
}
