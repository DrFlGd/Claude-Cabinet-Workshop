// Layout editor model.
//
// The editor works on a tree of openings: a leaf holds drawers, doors or open
// shelves; a split divides its rectangle into side-by-side columns ('x') or
// stacked rows ('z', top first). The tree is always derived from the design
// values (fromValues) and written back as ordinary engine settings (toValues),
// choosing the engine construction that can build it:
//   legacy      one column of drawers or doors, drawers over doors, or
//               side-by-side drawer banks (joined partitions and dividers)
//   mixed_bays  up to four full-height bays of drawers, doors or open shelves
//               (joined bay partitions)
//   sections    kitchen only: any nested arrangement (interior dividers are
//               butt-fit blanks; see docs/SECTION_LAYOUTS.md)
// The current construction is kept whenever it can still build the edited
// layout, so an edit never silently changes how an existing design is joined.
import {schemas,thickness,type Values} from './cabinet';
import type {LayoutRect,LayoutReport} from './analysis';
import {treeErrors,type SectionNode} from './sections';
import {LAYOUT_KEYS} from './settings';
export {LAYOUT_KEYS};

export type Contents='drawers'|'doors'|'open';
export type HeightMode='equal'|'graduated'|'custom_weights';
export type Ref={bay?:number;bank?:number;doors?:boolean;section?:number};
export type Leaf={kind:'leaf';contents:Contents;count:number;shelves:number;shelfStyle:'fixed'|'adjustable';heightMode:HeightMode;step:number;weights:number[];hinge:'left'|'right';size:number;fixed:boolean;ref?:Ref};
export type Split={kind:'x'|'z';divider:'panel'|'rail'|'none';children:LayoutNode[];size:number;fixed:boolean;auto?:boolean;ref?:Ref};
export type LayoutNode=Leaf|Split;
export type Path=number[];
export type Mode='legacy'|'mixed_bays'|'sections';
export type Mapping={patch:Values;mode:Mode;label:string;notes:string[]};
export type Failure={error:string};

export type Profile={family:number;contents:Contents[];columnContents:Contents[];maxColumns:number;combo:boolean;nested:boolean;maxDrawers:number;maxBayDrawers:number;maxDoors:number;maxBayDoors:number;maxShelves:number;hinge:boolean;name:string};

export function profile(family:number):Profile|null{
 const all:Contents[]=['drawers','doors','open'];
 switch(family){
  case 0:return {family,contents:all,columnContents:all,maxColumns:4,combo:true,nested:false,maxDrawers:12,maxBayDrawers:8,maxDoors:4,maxBayDoors:2,maxShelves:6,hinge:true,name:'shop cart'};
  case 1:return {family,contents:all,columnContents:all,maxColumns:4,combo:true,nested:false,maxDrawers:8,maxBayDrawers:8,maxDoors:4,maxBayDoors:2,maxShelves:6,hinge:true,name:'utility cabinet'};
  case 2:return {family,contents:['drawers'],columnContents:['drawers'],maxColumns:4,combo:false,nested:false,maxDrawers:12,maxBayDrawers:12,maxDoors:0,maxBayDoors:0,maxShelves:0,hinge:false,name:'benchtop unit'};
  case 3:return {family,contents:all,columnContents:['drawers'],maxColumns:4,combo:false,nested:false,maxDrawers:8,maxBayDrawers:8,maxDoors:1,maxBayDoors:1,maxShelves:6,hinge:false,name:'stackable module'};
  case 4:return {family,contents:all,columnContents:all,maxColumns:4,combo:true,nested:true,maxDrawers:8,maxBayDrawers:8,maxDoors:4,maxBayDoors:2,maxShelves:8,hinge:true,name:'kitchen cabinet'};
  default:return null;
 }
}

// ---------- small helpers ----------
const num=(x:unknown,d:number)=>{const n=Number(x);return Number.isFinite(n)?n:d};
const int=(x:unknown,d:number,lo:number,hi:number)=>Math.max(lo,Math.min(hi,Math.round(num(x,d))));
const r3=(n:number)=>Math.round(n*1000)/1000;
const clone=<T,>(x:T):T=>JSON.parse(JSON.stringify(x));
const heightMode=(x:unknown):HeightMode=>x==='graduated'||x==='custom_weights'?x:'equal';
const contentsOf=(x:unknown):Contents=>/door/.test(String(x))?'doors':/drawer/.test(String(x))?'drawers':'open';
function row(x:unknown,count:number){
 const a=(Array.isArray(x)?x:[]).map(Number).map(n=>Number.isFinite(n)&&n>0?n:1);
 while(a.length<count)a.push(1);
 return a.slice(0,Math.max(1,count));
}
function padded(x:unknown,len:number,fill:unknown){const a=Array.isArray(x)?clone(x):[];while(a.length<len)a.push(clone(fill));return a}
export function leaf(contents:Contents,count:number,extra:Partial<Leaf>={}):Leaf{
 return {kind:'leaf',contents,count,shelves:0,shelfStyle:'adjustable',heightMode:'equal',step:0.35,weights:Array(Math.max(1,count)).fill(1),hinge:'left',size:1,fixed:false,...extra};
}
export const pathKey=(p:Path)=>p.join('.');
export function nodeAt(root:LayoutNode,path:Path):LayoutNode|undefined{
 let n:LayoutNode|undefined=root;
 for(const i of path){if(!n||n.kind==='leaf')return undefined;n=n.children[i]}
 return n;
}
function update(root:LayoutNode,path:Path,fn:(n:LayoutNode)=>LayoutNode):LayoutNode{
 if(!path.length)return fn(clone(root));
 const next=clone(root) as Split;
 let parent:Split=next;
 for(let k=0;k<path.length-1;k++)parent=parent.children[path[k]] as Split;
 parent.children[path.at(-1)!]=fn(parent.children[path.at(-1)!]);
 return next;
}
export function leaves(root:LayoutNode,path:Path=[]):{path:Path;node:Leaf}[]{
 return root.kind==='leaf'?[{path,node:root}]:root.children.flatMap((c,i)=>leaves(c,[...path,i]));
}
export function describe(n:LayoutNode):string{
 if(n.kind!=='leaf')return n.kind==='x'?n.children.length+' side by side':n.children.length+' stacked';
 const s=n.shelves?` · ${n.shelves} shel${n.shelves===1?'f':'ves'}`:'';
 if(n.contents==='drawers')return `${n.count} drawer${n.count===1?'':'s'}`;
 if(n.contents==='doors')return `${n.count} door${n.count===1?'':'s'}${s}`;
 return n.shelves?`Open${s}`:'Open';
}
export function drawerWeights(n:Leaf){
 return Array.from({length:n.count},(_,i)=>n.heightMode==='graduated'?Math.max(0.05,1+i*n.step):n.heightMode==='custom_weights'?Math.max(0.05,n.weights[i]??1):1);
}
export function currentMode(family:number,v:Values):Mode{
 if(family===4&&v.cabinet_layout_mode==='sections')return 'sections';
 if([0,1,4].includes(family)&&v.cabinet_layout_mode==='mixed_bays')return 'mixed_bays';
 return 'legacy';
}

// ---------- values -> tree ----------
// `report` is the engine report for exactly these values (or undefined); `frame`
// may come from an earlier report of the same cabinet envelope.
export function fromValues(family:number,v:Values,report?:LayoutReport,frame?:Frame):LayoutNode|null{
 if(!profile(family))return null;
 const mode=currentMode(family,v);
 if(mode==='sections'&&!treeErrors(v.section_nodes).length)return fromSections(v.section_nodes);
 if(mode==='mixed_bays')return fromBays(v);
 return fromLegacy(family,v,report,frame??frameFor(family,v,report));
}

function fromBays(v:Values):LayoutNode{
 const k=int(v.mixed_bay_count,1,1,4);
 const bays=Array.from({length:k},(_,i):Leaf=>{
  const c=contentsOf(v.mixed_bay_types?.[i]);
  const count=c==='drawers'?int(v.mixed_bay_drawer_counts?.[i],4,1,12):c==='doors'?int(v.mixed_bay_door_counts?.[i],1,1,2):0;
  return leaf(c,count,{
   shelves:c==='drawers'?0:int(v.mixed_bay_shelf_counts?.[i],0,0,12),
   shelfStyle:v.mixed_bay_shelf_styles?.[i]==='fixed'?'fixed':'adjustable',
   heightMode:heightMode(v.mixed_bay_drawer_height_modes?.[i]),
   step:num(v.mixed_bay_drawer_graduated_steps?.[i],0.35),
   weights:row(v.mixed_bay_drawer_height_weights?.[i],count),
   hinge:v.mixed_bay_door_hinge_sides?.[i]==='right'?'right':'left',
   size:Math.max(0.05,num(v.mixed_bay_width_weights?.[i],1)),
   ref:{bay:i},
  });
 });
 if(k===1)return {...bays[0],size:1};
 return {kind:'x',divider:v.include_mixed_bay_partitions===false?'none':'panel',children:bays,size:1,fixed:false};
}

function drawerStack(family:number,v:Values):LayoutNode{
 const k=family===3&&v.module_type!=='drawers'?1:int(v.drawer_bank_count,1,1,4);
 const independent=k>1&&v.drawer_bank_layout_mode==='independent';
 const banks=Array.from({length:k},(_,b):Leaf=>{
  const count=int(independent?v.drawer_bank_drawer_counts?.[b]??v.drawer_count:v.drawer_count,1,1,12);
  return leaf('drawers',count,{
   heightMode:heightMode(independent?v.drawer_bank_height_modes?.[b]:v.drawer_height_mode),
   step:num(independent?v.drawer_bank_graduated_steps?.[b]:v.drawer_graduated_step,0.35),
   weights:row(independent?v.drawer_bank_height_weights?.[b]:v.drawer_height_weights,count),
   size:Math.max(0.05,num(v.drawer_bank_width_weights?.[b],1)),
   ref:{bank:b},
  });
 });
 return k===1?{...banks[0],size:1}:{kind:'x',divider:'panel',children:banks,size:1,fixed:false};
}

function fromLegacy(family:number,v:Values,report:LayoutReport|undefined,frame:Frame):LayoutNode{
 if(family===2)return drawerStack(family,v);
 if(family===3){
  if(v.module_type==='door')return leaf('doors',1,{shelves:int(v.door_shelf_count,0,0,12),ref:{bay:0}});
  if(v.module_type==='open')return leaf('open',0,{shelves:int(v.door_shelf_count,0,0,12),ref:{bay:0}});
  return drawerStack(family,v);
 }
 const doors=():Leaf=>{
  const n=int(v.door_count,2,0,4);
  return n===0
   ?leaf('open',0,{shelves:int(v.door_shelf_count,0,0,12),shelfStyle:v.shelf_style==='fixed'?'fixed':'adjustable',ref:{doors:true}})
   :leaf('doors',n,{shelves:int(v.door_shelf_count,0,0,12),shelfStyle:v.shelf_style==='fixed'?'fixed':'adjustable',hinge:v.single_door_hinge_side==='right'?'right':'left',ref:{doors:true}});
 };
 if(v.cabinet_contents==='doors')return doors();
 if(v.cabinet_contents!=='combo')return drawerStack(family,v);
 const top=drawerStack(family,v),bottom=doors();
 const content=frame.content.h;
 let door=report?.doorRegion?.h;
 if(!Number.isFinite(door)){
  const lead=top.kind==='leaf'?top:top.children[0] as Leaf,n=lead.count,gap=num(v.drawer_gap,3);
  door=num(v.combo_door_height,0)>0?num(v.combo_door_height,0):(content-gap*n)*3/(drawerWeights(lead).reduce((a,b)=>a+b,0)+3);
 }
 top.size=Math.max(1,content-door!);bottom.size=Math.max(1,door!);
 return {kind:'z',divider:'panel',children:[top,bottom],size:1,fixed:false,auto:!(num(v.combo_door_height,0)>0)};
}

export function fromSections(nodes:SectionNode[]):LayoutNode{
 const build=(i:number):LayoutNode=>{
  const n=nodes[i],kids=nodes.map((c,j)=>({c,j})).filter(x=>x.c[0]===i).sort((a,b)=>a.c[1]-b.c[1]);
  if(n[2]==='leaf'){
   const c=n[5];
   return leaf(c,c==='open'?0:n[6],{shelves:c==='open'?n[6]:c==='doors'?n[11]:0,heightMode:n[7],step:n[8],weights:row(n[9],n[6]),size:n[4],fixed:n[3]==='mm',ref:{section:i}});
  }
  return {kind:n[2],divider:n[10],children:kids.map(x=>build(x.j)),size:n[4],fixed:n[3]==='mm',ref:{section:i}};
 };
 return build(0);
}

export function toSections(root:LayoutNode):SectionNode[]{
 const out:SectionNode[]=[];
 const add=(n:LayoutNode,parent:number,order:number)=>{
  const i=out.length;
  if(n.kind==='leaf'){
   const count=n.contents==='open'?Math.min(8,n.shelves):n.count;
   out.push([parent,order,'leaf',n.fixed?'mm':'weight',r3(n.size),n.contents,count,n.heightMode,n.step,row(n.weights,Math.max(1,n.contents==='drawers'?n.count:1)).map(r3),'panel',n.contents==='doors'?n.shelves:0]);
  }else{
   out.push([parent,order,n.kind,n.fixed?'mm':'weight',r3(n.size),'open',0,'equal',0.25,[1],n.kind==='x'&&n.divider==='rail'?'panel':n.divider,0]);
   n.children.forEach((c,k)=>add(c,i,k));
  }
 };
 add(root,-1,0);
 out[0][3]='weight';out[0][4]=1;
 return out;
}

// ---------- tree -> values ----------
type Shape='single'|'columns'|'combo'|'nested';
export function shape(root:LayoutNode):Shape{
 if(root.kind==='leaf')return 'single';
 if(root.kind==='x'&&root.children.every(c=>c.kind==='leaf'))return 'columns';
 if(root.kind==='z'&&root.children.length===2){
  const [top,bottom]=root.children;
  const drawers=(n:LayoutNode)=>n.kind==='leaf'?n.contents==='drawers':n.kind==='x'&&n.children.length<=4&&n.children.every(c=>c.kind==='leaf'&&c.contents==='drawers');
  if(bottom.kind==='leaf'&&bottom.contents==='doors'&&drawers(top))return 'combo';
 }
 return 'nested';
}

function keepSchemaKeys(family:number,patch:Values){
 const keys=new Set(schemas[family].fields.map(f=>f.key));
 return Object.fromEntries(Object.entries(patch).filter(([k])=>keys.has(k)));
}

function legacyMapping(family:number,v:Values,root:LayoutNode,frame:Frame):Mapping|Failure{
 const p=profile(family)!,s=shape(root),notes:string[]=[];
 let stack:LayoutNode|undefined,doors:Leaf|undefined;
 if(s==='single'){
  const n=root as Leaf;
  if(n.contents==='drawers')stack=n;
  else if(family===3){
   if(n.contents==='doors'&&n.count>1)return {error:'A stackable door module has one door.'};
   return {patch:keepSchemaKeys(family,{module_type:n.contents==='doors'?'door':'open',door_shelf_count:Math.min(p.maxShelves,n.shelves)}),mode:'legacy',label:n.contents==='doors'?'Door module':'Open module',notes};
  }
  else if(n.contents==='doors')doors=n;
  else return {error:'open'};
 }
 else if(s==='columns'){
  if(!(root as Split).children.every(c=>(c as Leaf).contents==='drawers'))return {error:'Side-by-side openings of this '+p.name+' must all be drawers.'};
  stack=root;
 }
 else if(s==='combo'){
  if(!p.combo)return {error:'This '+p.name+' cannot put drawers over doors.'};
  stack=(root as Split).children[0];doors=(root as Split).children[1] as Leaf;
 }
 else return {error:'nested'};
 const patch:Values={};
 if([0,1,4].includes(family)){patch.cabinet_layout_mode='legacy';patch.cabinet_contents=stack&&doors?'combo':stack?'drawers':'doors'}
 if(family===3)patch.module_type='drawers';
 if(stack){
  const banks=(stack.kind==='leaf'?[stack]:stack.children) as Leaf[],k=banks.length;
  if(k>p.maxColumns)return {error:`Use at most ${p.maxColumns} drawer columns.`};
  if(banks.some(b=>b.count>p.maxDrawers))return {error:`Use at most ${p.maxDrawers} drawers per column.`};
  const same=banks.every(b=>b.count===banks[0].count&&b.heightMode===banks[0].heightMode&&(b.heightMode!=='graduated'||b.step===banks[0].step)&&(b.heightMode!=='custom_weights'||drawerWeights(b).every((w,i)=>Math.abs(w-drawerWeights(banks[0])[i])<1e-6)));
  patch.drawer_bank_count=k;
  if(k>1)patch.drawer_bank_width_weights=padded(v.drawer_bank_width_weights,4,1).map((w:number,i:number)=>i<k?r3(banks[i].size):w);
  patch.drawer_bank_layout_mode=k>1&&!same?'independent':'shared';
  const lead=banks[0];
  patch.drawer_count=lead.count;
  patch.drawer_height_mode=lead.heightMode;
  patch.drawer_graduated_step=lead.step;
  patch.drawer_height_weights=padded(v.drawer_height_weights,Math.max(4,lead.count),1).map((w:number,i:number)=>i<lead.count?r3(lead.weights[i]??1):w);
  if(k>1&&!same){
   patch.drawer_bank_drawer_counts=padded(v.drawer_bank_drawer_counts,4,4).map((c:number,i:number)=>i<k?banks[i].count:c);
   patch.drawer_bank_height_modes=padded(v.drawer_bank_height_modes,4,'equal').map((m:string,i:number)=>i<k?banks[i].heightMode:m);
   patch.drawer_bank_graduated_steps=padded(v.drawer_bank_graduated_steps,4,0.35).map((g:number,i:number)=>i<k?banks[i].step:g);
   patch.drawer_bank_height_weights=padded(v.drawer_bank_height_weights,4,Array(8).fill(1)).map((r:number[],i:number)=>i<k?padded(row(banks[i].weights,banks[i].count).map(r3),8,1):r);
  }
  if(k>1&&v.include_drawer_separators){patch.include_drawer_separators=false;notes.push('Drawer separators were turned off: full-width separators cannot cross the drawer-bank partitions.')}
 }
 if(doors){
  if(doors.count>p.maxDoors)return {error:`Use at most ${p.maxDoors} doors across one opening.`};
  patch.door_count=doors.count;patch.door_shelf_count=Math.min(p.maxShelves,doors.shelves);patch.shelf_style=doors.shelfStyle;
  if(doors.count===1)patch.single_door_hinge_side=doors.hinge;
 }
 if(stack&&doors){
  const z=root as Split,[top,bottom]=z.children,total=top.size+bottom.size;
  patch.combo_door_height=z.auto?0:r3(Math.max(1,frame.content.h*bottom.size/total));
 }
 const banks=stack?.kind==='x'?stack.children.length:1;
 const label=stack&&doors?(banks>1?`Drawers over doors · ${banks} drawer columns`:'Drawers over doors'):stack?(banks>1?`${banks} drawer columns with partitions`:'Single drawer column'):'Door cabinet';
 return {patch:keepSchemaKeys(family,patch),mode:'legacy',label,notes};
}

function bayMapping(family:number,v:Values,root:LayoutNode):Mapping|Failure{
 const p=profile(family)!,s=shape(root);
 if(![0,1,4].includes(family)||(s!=='single'&&s!=='columns'))return {error:'nested'};
 const bays=(s==='single'?[root]:(root as Split).children) as Leaf[],k=bays.length;
 if(k>4)return {error:'Use at most four side-by-side bays.'};
 if(bays.some(b=>b.contents==='doors'&&b.count>2))return {error:'A bay holds one or two doors. Split it into two bays for more doors.'};
 if(bays.some(b=>b.contents==='drawers'&&b.count>p.maxBayDrawers))return {error:`Use at most ${p.maxBayDrawers} drawers per bay.`};
 if(family===4&&v.front_facing_style==='face_frame'&&k>1){
  if(bays[0].contents==='drawers'||bays[k-1].contents==='drawers')return {error:'frame-ends'};
  if(v.front_mount_style==='inset_flush'&&bays.some(b=>b.contents!=='open'))return {error:'frame-inset'};
 }
 const type=(b:Leaf)=>b.contents==='drawers'?'drawers':b.contents==='doors'?'door':'open';
 const set=<T,>(key:string,fill:T,fn:(b:Leaf)=>T|undefined)=>padded(v[key],4,fill).map((x:T,i:number)=>{const val=i<k?fn(bays[i]):undefined;return val===undefined?x:val});
 const patch:Values={
  cabinet_layout_mode:'mixed_bays',mixed_bay_count:k,
  mixed_bay_types:set('mixed_bay_types','open',type),
  mixed_bay_width_weights:k>1?set('mixed_bay_width_weights',1,b=>r3(b.size)):padded(v.mixed_bay_width_weights,4,1),
  mixed_bay_drawer_counts:set('mixed_bay_drawer_counts',4,b=>b.contents==='drawers'?b.count:undefined),
  mixed_bay_door_counts:set('mixed_bay_door_counts',1,b=>b.contents==='doors'?b.count:undefined),
  mixed_bay_shelf_counts:set('mixed_bay_shelf_counts',0,b=>b.contents==='drawers'?undefined:Math.min(p.maxShelves,b.shelves)),
  mixed_bay_shelf_styles:set('mixed_bay_shelf_styles','adjustable',b=>b.contents==='drawers'?undefined:b.shelfStyle),
  mixed_bay_drawer_height_modes:set('mixed_bay_drawer_height_modes','equal',b=>b.contents==='drawers'?b.heightMode:undefined),
  mixed_bay_drawer_graduated_steps:set('mixed_bay_drawer_graduated_steps',0.35,b=>b.contents==='drawers'?b.step:undefined),
  mixed_bay_drawer_height_weights:set('mixed_bay_drawer_height_weights',Array(8).fill(1),b=>b.contents==='drawers'?padded(row(b.weights,b.count).map(r3),8,1):undefined),
  mixed_bay_door_hinge_sides:set('mixed_bay_door_hinge_sides','left',b=>b.contents==='doors'&&b.count===1?b.hinge:undefined),
 };
 if(s==='columns')patch.include_mixed_bay_partitions=(root as Split).divider!=='none';
 const label=k===1?(bays[0].contents==='open'?'Open cabinet':'Single bay'):`${k} side-by-side bays`+((root as Split).divider==='none'?' without partitions':' with partitions');
 return {patch:keepSchemaKeys(family,patch),mode:'mixed_bays',label,notes:[]};
}

function sectionMapping(family:number,root:LayoutNode):Mapping|Failure{
 if(family!==4)return {error:'nested'};
 const nodes=toSections(root),errors=treeErrors(nodes);
 if(errors.length)return {error:errors[0]};
 const leafCount=nodes.filter(n=>n[2]==='leaf').length;
 return {patch:{cabinet_layout_mode:'sections',section_nodes:nodes,width_basis:'outside',depth_basis:'outside'},mode:'sections',label:`Sections · ${leafCount} opening${leafCount===1?'':'s'}`,notes:['Interior section dividers and shelves are butt-fit blanks: fit cleats, brackets or shop-drilled fasteners.']};
}

const explain:Record<string,string>={
 nested:'This cabinet type cannot stack openings inside a bay. Use side-by-side bays, or drawers over doors across the full width. Kitchen cabinets support any arrangement.',
 open:'Open openings need the bay layout.',
 'frame-ends':'Behind a face frame, drawers cannot sit in the first or last bay.',
 'frame-inset':'Inset fronts cannot be used for bays behind a face frame.',
};

// Choose the construction for a tree: keep the current one when it can build the
// layout, otherwise the first that can (joined construction before sections).
function profileError(p:Profile,root:LayoutNode):string|undefined{
 const what=(c:Contents)=>c==='open'?'open shelves':c;
 for(const {node} of leaves(root))if(!p.contents.includes(node.contents))return `A ${p.name} cannot hold ${what(node.contents)}.`;
 if(root.kind!=='leaf'&&leaves(root).some(l=>!p.columnContents.includes(l.node.contents)))return `Side-by-side openings of a ${p.name} must all be drawers.`;
 for(const {node} of leaves(root)){
  if(node.contents!=='drawers'&&node.shelves>p.maxShelves)return `Use at most ${p.maxShelves} shelves in one opening.`;
  if(node.contents==='drawers'&&node.count<1)return 'A drawer opening needs at least one drawer.';
  if(node.contents==='doors'&&node.count<1)return 'A door opening needs at least one door.';
 }
}

export function toValues(family:number,v:Values,root:LayoutNode,report?:LayoutReport,frameIn?:Frame):Mapping|Failure{
 const p=profile(family);
 if(!p)return {error:'This cabinet type has no layout editor.'};
 const bad=profileError(p,root);
 if(bad)return {error:bad};
 const frame=frameIn??frameFor(family,v,report);
 const order:Mode[]=[currentMode(family,v),'legacy','mixed_bays','sections'];
 const reasons:string[]=[];
 for(const mode of [...new Set(order)]){
  const r=mode==='legacy'?legacyMapping(family,v,root,frame):mode==='mixed_bays'?bayMapping(family,v,root):sectionMapping(family,root);
  if(!('error' in r))return r;
  reasons.push(r.error);
 }
 const specific=reasons.find(r=>!explain[r]&&r!=='nested');
 return {error:specific??explain[reasons.find(r=>explain[r]&&r!=='nested')??'nested']};
}
export function canBuild(family:number,v:Values,root:LayoutNode,report?:LayoutReport,frame?:Frame){return !('error' in toValues(family,v,root,report,frame))}

// ---------- geometry ----------
export type Frame={w:number;h:number;t:number;open:LayoutRect;inner:{x:number;w:number};content:{z:number;h:number}};
export function estimateFrame(family:number,v:Values):Frame{
 const t=thickness(v),W=num(v.custom_cabinet_width??v.cabinet_width,600),H=num(v.custom_cabinet_height??v.cabinet_height,700);
 const frame=family===4&&v.front_facing_style==='face_frame';
 const base=family===3?num(v.stack_interface_depth,18):(family===4||family===1)&&v.cabinet_mount_style!=='wall'&&v.base_style==='toe_kick'?num(v.custom_bottom_above_toe??v.custom_toe_kick_height,100):0;
 const left=frame?num(v.face_frame_side_stile_width,38.1):t,bottom=base+(frame?num(v.face_frame_bottom_rail_width,38.1):t),top=H-(frame?num(v.face_frame_top_rail_width,38.1):t);
 const reveal=num(v.front_edge_reveal,2);
 return {w:W,h:H,t,open:{x:left,z:bottom,w:W-2*left,h:top-bottom},inner:{x:t,w:W-2*t},content:{z:bottom+reveal,h:top-bottom-2*reveal}};
}
export function frameFor(family:number,v:Values,report?:LayoutReport):Frame{
 const c=report?.cabinet;
 if(c&&[c.w,c.h,c.open.x,c.open.z,c.open.w,c.open.h].every(Number.isFinite)){
  const t=Number.isFinite(c.t)?c.t:thickness(v),est=estimateFrame(family,v);
  return {w:c.w,h:c.h,t,open:c.open,inner:{x:t,w:c.w-2*t},content:Number.isFinite(c.content.h)?c.content:est.content};
 }
 return estimateFrame(family,v);
}

export type Cell={path:Path;node:Leaf;rect:LayoutRect};
export type Handle={path:Path;index:number;axis:'x'|'z';at:number;from:number;to:number};
export type Geometry={root:LayoutRect;cells:Cell[];handles:Handle[];rects:Map<string,LayoutRect>;gaps:Map<string,number>};

export function geometry(family:number,v:Values,root:LayoutNode,frame:Frame,report?:LayoutReport):Geometry{
 const mode=currentMode(family,v),combo=shape(root)==='combo'&&mode==='legacy';
 const rects=new Map<string,LayoutRect>(),gaps=new Map<string,number>(),cells:Cell[]=[],handles:Handle[]=[];
 let base:LayoutRect=mode==='mixed_bays'?{x:frame.inner.x,z:frame.open.z,w:frame.inner.w,h:frame.open.h}:frame.open;
 if(combo)base={x:frame.open.x,z:frame.content.z,w:frame.open.w,h:frame.content.h};
 const walk=(n:LayoutNode,path:Path,r:LayoutRect)=>{
  const key=pathKey(path);
  // Bind openings to the engine's own report when it describes this exact design.
  const ref=n.ref;
  if(report&&ref){
   const bay=ref.bay!==undefined?report.bays.find(b=>b.index===ref.bay):undefined;
   const bank=ref.bank!==undefined?report.banks.find(b=>b.index===ref.bank):undefined;
   const sec=ref.section!==undefined?report.sections.find(s=>s.index===ref.section):undefined;
   if(bay)r={...r,x:bay.x,w:bay.w};
   if(bank)r={...r,x:bank.x,w:bank.w};
   if(sec)r={x:sec.x,z:sec.z,w:sec.w,h:sec.h};
   if(ref.doors&&report.doorRegion&&combo)r={...r,z:report.doorRegion.z,h:report.doorRegion.h};
  }
  rects.set(key,r);
  if(n.kind==='leaf'){cells.push({path,node:n,rect:r});return}
  const gap=combo&&!path.length?0:n.divider==='none'?0:frame.t;
  gaps.set(key,gap);
  const along=n.kind==='x'?r.w:r.h,available=along-gap*(n.children.length-1);
  const fixed=n.children.filter(c=>c.fixed).reduce((a,c)=>a+c.size,0),weights=n.children.filter(c=>!c.fixed).reduce((a,c)=>a+c.size,0);
  let offset=0;
  n.children.forEach((c,i)=>{
   const size=c.fixed?c.size:(available-fixed)*c.size/Math.max(1e-9,weights);
   const cr=n.kind==='x'?{x:r.x+offset,z:r.z,w:size,h:r.h}:{x:r.x,z:r.z+r.h-offset-size,w:r.w,h:size};
   if(i>0)handles.push(n.kind==='x'?{path,index:i,axis:'x',at:r.x+offset-gap/2,from:r.z,to:r.z+r.h}:{path,index:i,axis:'z',at:r.z+r.h-offset+gap/2,from:r.x,to:r.x+r.w});
   walk(c,[...path,i],cr);
   offset+=size+gap;
  });
 };
 walk(root,[],base);
 // Move handles onto the engine-reported boundaries when available.
 for(const h of handles){
  const a=rects.get(pathKey([...h.path,h.index-1])),b=rects.get(pathKey([...h.path,h.index]));
  if(a&&b)h.at=h.axis==='x'?(a.x+a.w+b.x)/2:(a.z+b.z+b.h)/2;
 }
 return {root:base,cells,handles,rects,gaps};
}

// Child sizes along a split, in millimeters, as currently laid out.
export function childSizes(g:Geometry,root:LayoutNode,path:Path):number[]{
 const n=nodeAt(root,path);
 if(!n||n.kind==='leaf')return [];
 return n.children.map((_,i)=>{const r=g.rects.get(pathKey([...path,i]))!;return n.kind==='x'?r.w:r.h});
}

// Fronts of one opening: the engine's exact rectangles when available, else a prediction.
export type Front={id:string;kind:'drawer'|'door';x:number;z:number;w:number;h:number;nominal:number;hinge?:string;exact:boolean};
export function frontsFor(cell:Cell,v:Values,report?:LayoutReport,mode:Mode='legacy'):Front[]{
 const n=cell.node,r=cell.rect;
 if(report&&n.ref&&mode!=='sections'){
  const bayNo=n.ref.bay!==undefined?n.ref.bay+1:n.ref.bank!==undefined?n.ref.bank+1:n.ref.doors?0:undefined;
  if(bayNo!==undefined){
   const kind=n.contents==='drawers'?'drawer':'door';
   const list=report.fronts.filter(f=>f.kind===kind&&f.bay===bayNo).sort((a,b)=>a.index-b.index);
   if(list.length)return list.map(f=>({id:f.id,kind:f.kind,x:f.x,z:f.z,w:f.w,h:f.h,nominal:f.nominal??f.h,hinge:f.hinge,exact:true}));
  }
 }
 const reveal=num(v.front_edge_reveal,2),gap=num(n.contents==='drawers'?v.drawer_gap:v.door_gap,3);
 if(n.contents==='drawers'){
  const w=drawerWeights(n),sum=w.reduce((a,b)=>a+b,0),avail=r.h-2*reveal-gap*(n.count-1);
  let z=r.z+r.h-reveal;
  return w.map((x,i)=>{const h=avail*x/sum;z-=h;const f={id:'D'+(i+1),kind:'drawer' as const,x:r.x+reveal,z,w:r.w-2*reveal,h,nominal:h,exact:false};z-=gap;return f});
 }
 if(n.contents==='doors'){
  const each=(r.w-2*reveal-gap*(n.count-1))/n.count;
  return Array.from({length:n.count},(_,i)=>({id:'DOOR'+(i+1),kind:'door' as const,x:r.x+reveal+i*(each+gap),z:r.z+reveal,w:each,h:r.h-2*reveal,nominal:r.h-2*reveal,hinge:n.count===1?n.hinge:i===0?'left':'right',exact:false}));
 }
 return [];
}

// ---------- edits (each returns a new tree) ----------
export function setLeaf(root:LayoutNode,path:Path,patch:Partial<Leaf>):LayoutNode{
 return update(root,path,n=>{
  if(n.kind!=='leaf')return n;
  const next={...n,...patch};
  if(patch.count!==undefined&&next.contents==='drawers')next.weights=row(next.weights,next.count);
  return next;
 });
}
export function changeContents(root:LayoutNode,path:Path,contents:Contents,p:Profile,inBay:boolean,widthMm:number):LayoutNode{
 return update(root,path,n=>{
  if(n.kind!=='leaf'||n.contents===contents)return n;
  const maxDoors=inBay?p.maxBayDoors:p.maxDoors;
  const count=contents==='drawers'?Math.min(inBay?p.maxBayDrawers:p.maxDrawers,3):contents==='doors'?Math.min(maxDoors,widthMm>600?2:1):0;
  return {...n,contents,count,shelves:contents==='drawers'?0:n.shelves||(contents==='open'?2:1),heightMode:'equal',weights:Array(Math.max(1,count)).fill(1)};
 });
}
// Side by side: a new column after this opening (inside its row of columns when it has one).
export function splitColumns(root:LayoutNode,path:Path,sizes?:number[]):LayoutNode{
 const parentPath=path.slice(0,-1),parent=path.length?nodeAt(root,parentPath):undefined;
 if(parent&&parent.kind==='x'){
  const i=path.at(-1)!;
  return update(root,parentPath,n=>{
   const s=n as Split,kids=s.children.map((c,k)=>({...c,size:sizes?.[k]??c.size,fixed:false}));
   const half=kids[i].size/2,copy={...clone(kids[i]),size:half,ref:undefined};
   kids[i]={...kids[i],size:half};
   kids.splice(i+1,0,copy);
   return {...s,children:kids};
  });
 }
 return update(root,path,n=>{
  const a={...clone(n),size:1,fixed:false},b={...clone(n),size:1,fixed:false,ref:undefined};
  delete (a as any).ref;
  return {kind:'x',divider:'panel',children:[a,b],size:n.size,fixed:n.fixed,ref:n.kind==='leaf'?undefined:n.ref};
 });
}
// Stacked: drawers over doors for a whole-width opening, or two rows for kitchen sections.
export function splitRows(root:LayoutNode,path:Path,p:Profile,heightMm:number):LayoutNode{
 return update(root,path,n=>{
  if(n.kind!=='leaf')return n;
  const lead=heightMm>0?Math.min(0.35*heightMm,Math.max(150,heightMm*0.25)):1;
  const top=n.contents==='drawers'?{...n,count:Math.min(n.count,2),weights:row(n.weights,Math.min(n.count,2)),size:lead,fixed:false,ref:undefined}:leaf('drawers',1,{size:lead});
  const bottom=n.contents==='doors'?{...n,size:Math.max(1,heightMm-lead),fixed:false,ref:undefined}:leaf('doors',Math.min(p.maxDoors,2),{shelves:1,size:Math.max(1,heightMm-lead)});
  return {kind:'z',divider:'panel',children:[top,bottom],size:n.size,fixed:n.fixed};
 });
}
export function removeOpening(root:LayoutNode,path:Path,sizes?:number[]):LayoutNode{
 if(!path.length)return root;
 const parentPath=path.slice(0,-1),i=path.at(-1)!;
 return update(root,parentPath,n=>{
  const s=n as Split,kids=s.children.map((c,k)=>({...c,size:sizes?.[k]??c.size,fixed:sizes?false:c.fixed}));
  const removed=kids.splice(i,1)[0],neighbour=Math.min(i,kids.length-1);
  if(sizes||!removed.fixed)kids[neighbour]={...kids[neighbour],size:kids[neighbour].size+removed.size};
  if(kids.length===1)return {...kids[0],size:s.size,fixed:s.fixed,ref:kids[0].ref};
  return {...s,children:kids};
 });
}
// Resize the two openings on either side of a boundary; sizes are the current mm sizes.
export function moveBoundary(root:LayoutNode,path:Path,index:number,deltaMm:number,sizes:number[],min=60):LayoutNode{
 return update(root,path,n=>{
  const s=n as Split,a=index-1,b=index;
  const d=Math.max(min-sizes[a],Math.min(sizes[b]-min,deltaMm));
  const kids=s.children.map((c,k)=>({...c,size:k===a?sizes[a]+d:k===b?sizes[b]-d:c.fixed?c.size:sizes[k],fixed:k===a||k===b?false:c.fixed}));
  return {...s,children:kids,auto:false};
 });
}
// Set one opening's size exactly; its unlocked siblings share the remainder in proportion.
export function setChildSize(root:LayoutNode,path:Path,index:number,mm:number,sizes:number[],lock:boolean,min=60):LayoutNode|Failure{
 const n=nodeAt(root,path);
 if(!n||n.kind==='leaf')return {error:'Nothing to resize.'};
 const total=sizes.reduce((a,b)=>a+b,0),others=n.children.map((c,k)=>k===index?0:lock&&c.fixed?0:sizes[k]).reduce((a,b)=>a+b,0);
 const locked=n.children.map((c,k)=>k!==index&&lock&&c.fixed?sizes[k]:0).reduce((a,b)=>a+b,0);
 const rest=total-locked-mm;
 if(!(mm>=min))return {error:`Openings must be at least ${min} mm.`};
 if(n.children.length>1&&rest<min*(n.children.length-1-n.children.filter((c,k)=>k!==index&&lock&&c.fixed).length))return {error:'That leaves too little room for the other openings.'};
 return update(root,path,s=>({...(s as Split),auto:false,children:(s as Split).children.map((c,k)=>k===index?{...c,size:mm,fixed:lock}:lock&&c.fixed?c:{...c,size:others>0?sizes[k]*rest/others:rest,fixed:false})}));
}
// Drawer front heights (nominal, mm) inside one drawer opening.
export function setDrawerHeights(root:LayoutNode,path:Path,heights:number[]):LayoutNode{
 return setLeaf(root,path,{heightMode:'custom_weights',weights:heights.map(h=>r3(Math.max(1,h)))});
}
export function setDrawerHeight(root:LayoutNode,path:Path,index:number,mm:number,heights:number[],min=40):LayoutNode|Failure{
 const total=heights.reduce((a,b)=>a+b,0),others=total-heights[index],rest=total-mm;
 if(!(mm>=min))return {error:`Drawer fronts must be at least ${min} mm tall.`};
 if(heights.length>1&&rest<min*(heights.length-1))return {error:'That leaves too little room for the other drawers.'};
 if(heights.length===1)return {error:'A single drawer fills its opening; resize the opening instead.'};
 return setDrawerHeights(root,path,heights.map((h,i)=>i===index?mm:h*rest/others));
}
export function setDivider(root:LayoutNode,path:Path,divider:Split['divider']):LayoutNode{
 return update(root,path,n=>n.kind==='leaf'?n:{...n,divider});
}

// Everything except the layout: unchanged by layout edits, so an earlier engine report's
// cabinet frame stays valid while the engine recalculates.
export function envelopeKey(family:number,v:Values){
 return JSON.stringify([family,Object.entries(v).filter(([k])=>!LAYOUT_KEYS.has(k)&&!LAYOUT_KEYS.has(k.replace(/^custom_/,''))&&!k.startsWith('_')).sort(([a],[b])=>a<b?-1:1)]);
}
