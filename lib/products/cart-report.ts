// The media cart engine's report, read from the records of an engine check (lib/analysis
// records()): the static tip-over results with the loads and support they assume, what
// resists racking, and every joinery feature in body coordinates for the instant drawing.
export type TipCase={id:string;label:string;mass:number;com:[number,number,number];
 // Horizontal force at the top that just tips the cart, per direction (N).
 tip:{front:number;back:number;left:number;right:number};
 // Downward force on the front edge of the bins that just tips it forward; null when the
 // edge is over the support.
 lean:number|null};
export type StabilityBasis={push:number;lean:number;pushZ:number;support:[number,number,number,number];density:number;binLoad:number;cubbyLoad:number;shelfLoad:number;lift:number};
export type CartFeature={part:string;type:'add'|'slot'|'pocket'|'hole';x:[number,number];y:[number,number];z:[number,number];d:number};
export type CartReport={cases:TipCase[];basis:StabilityBasis|null;racking:{side:string;front:string}|null;features:CartFeature[]};

const CASE_LABELS:Record<string,string>={empty:'Empty',loaded:'Fully loaded',top_loaded:'Top row loaded'};
const kv=(r:string)=>Object.fromEntries(r.split('|').flatMap(p=>{const i=p.indexOf('=');return i>0?[[p.slice(0,i),p.slice(i+1)]]:[]}));
const num=(s:string|undefined)=>{const n=Number(s);return Number.isFinite(n)?n:NaN};

export function cartReport(records:string[]):CartReport{
 const out:CartReport={cases:[],basis:null,racking:null,features:[]};
 for(const r of records){
  if(r.startsWith('DIM|MEDIA_CART|STABILITY|')){
   const f=kv(r),lean=num(f.LEAN_FRONT);
   out.cases.push({id:f.CASE,label:CASE_LABELS[f.CASE]??f.CASE,mass:num(f.MASS),com:[num(f.COM_X),num(f.COM_Y),num(f.COM_Z)],
    tip:{front:num(f.TIP_FRONT),back:num(f.TIP_BACK),left:num(f.TIP_LEFT),right:num(f.TIP_RIGHT)},lean:lean>=0?lean:null});
  }else if(r.startsWith('DIM|MEDIA_CART|STABILITY_BASIS|')){
   const f=kv(r),s=String(f.SUPPORT??'').split(',').map(Number);
   out.basis={push:num(f.PUSH),lean:num(f.LEAN),pushZ:num(f.PUSH_Z),support:[s[0],s[1],s[2],s[3]],density:num(f.DENSITY),binLoad:num(f.BIN_LOAD),cubbyLoad:num(f.CUBBY_LOAD),shelfLoad:num(f.SHELF_LOAD),lift:num(f.LIFT)};
  }else if(r.startsWith('DIM|MEDIA_CART|RACKING|')){
   const f=kv(r);out.racking={side:f.SIDE_TO_SIDE??'',front:f.FRONT_TO_BACK??''};
  }else if(r.startsWith('FEAT|')){
   const [,part,type,...n]=r.split('|'),v=n.map(Number);
   if((type==='add'||type==='slot'||type==='pocket'||type==='hole')&&v.length>=7&&v.every(Number.isFinite))
    out.features.push({part,type,x:[v[0],v[1]],y:[v[2],v[3]],z:[v[4],v[5]],d:v[6]});
  }
 }
 return out;
}

// The weakest direction of one loading: the smallest tipping push and where it tips.
export function weakest(c:TipCase){
 const dirs:[keyof TipCase['tip'],string][]=[['front','forward'],['back','backward'],['left','to the left'],['right','to the right']];
 return dirs.map(([k,text])=>({key:k,text,force:c.tip[k]})).reduce((a,b)=>b.force<a.force?b:a);
}
