// Flat, bounded tree shared with native OpenSCAD. Indices are stable until a subtree is removed.
// [parent, order, axis, size mode, size, contents, count, height mode, graduated step,
//  height weights, divider, shelves behind doors, hinge side, shelf style]. The last two
// are optional: designs saved before they existed have twelve fields.
export type SectionNode=[number,number,'leaf'|'x'|'z','weight'|'mm',number,'drawers'|'doors'|'open',number,'equal'|'graduated'|'custom_weights',number,number[],'panel'|'rail'|'none',number,('left'|'right')?,('fixed'|'adjustable')?];
export type Rect={id:number;x:number;z:number;w:number;h:number};
export const leaf=(parent=-1,order=0,type:SectionNode[5]='drawers',count=3):SectionNode=>[parent,order,'leaf','weight',1,type,count,'equal',.25,Array(Math.max(1,count)).fill(1),'panel',0,'left','adjustable'];
export const photoSections=():SectionNode[]=>[
 [-1,0,'z','weight',1,'open',0,'equal',.25,[1],'panel',0],
 [0,0,'x','weight',2,'open',0,'equal',.25,[1],'panel',0],
 [0,1,'x','weight',1,'open',0,'equal',.25,[1],'panel',0],
 [1,0,'leaf','weight',1,'drawers',2,'custom_weights',.25,[.8,1.2],'panel',0],
 [1,1,'leaf','weight',2,'doors',2,'equal',.25,[1],'panel',0],
 [1,2,'leaf','weight',1,'drawers',2,'custom_weights',.25,[.8,1.2],'panel',0],
 [2,0,'leaf','weight',1,'drawers',1,'equal',.25,[1],'panel',0],
 [2,1,'leaf','weight',1,'drawers',1,'equal',.25,[1],'panel',0],
];
export function treeErrors(value:unknown):string[]{
 if(!Array.isArray(value)||value.length<1||value.length>31)return ['Use between 1 and 31 section nodes.'];
 const a=value as SectionNode[];
 if(a.some(n=>!Array.isArray(n)||(n.length!==12&&n.length!==14)))return ['Each section must contain twelve or fourteen fields.'];
 for(let i=0;i<a.length;i++){
  const n=a[i];
  if(!Array.isArray(n)||(n.length===14&&(!['left','right'].includes(n[12] as string)||!['fixed','adjustable'].includes(n[13] as string)))||!Number.isInteger(n[0])||(i===0?n[0]!==-1:n[0]<0||n[0]>=i)||!Number.isInteger(n[1])||n[1]<0||!['leaf','x','z'].includes(n[2])||!['weight','mm'].includes(n[3])||!Number.isFinite(n[4])||n[4]<=0||!['drawers','doors','open'].includes(n[5])||!Number.isInteger(n[6])||n[6]<0||n[6]>8||!['equal','graduated','custom_weights'].includes(n[7])||!Number.isFinite(n[8])||n[8]<0||!Array.isArray(n[9])||n[9].length>8||n[9].some(w=>!Number.isFinite(w)||w<=0)||!['panel','rail','none'].includes(n[10])||!Number.isInteger(n[11])||n[11]<0||n[11]>8)return ['Invalid section '+(i+1)+'.'];
  if(n[2]==='x'&&n[10]==='rail')return ['Vertical splits need a panel or no divider.'];
  const children=a.map((c,j)=>({c,j})).filter(x=>x.c[0]===i);
  if(n[2]==='leaf'?(children.length!==0):(children.length<2||children.every(x=>x.c[3]==='mm')))return ['A split needs at least two children and one flexible size.'];
  if(children.some((_,j)=>children.filter(x=>x.c[1]===j).length!==1))return ['Section order must be consecutive.'];
  let p=i,depth=0;while(p>0){p=a[p][0];if(++depth>8)return ['Use no more than eight nesting levels.'];}
  if(n[2]==='leaf'&&((n[5]==='doors'&&(n[6]<1||n[6]>2))||(n[5]==='drawers'&&(n[6]<1||(n[7]==='custom_weights'&&n[9].length<n[6])))))return ['Check the drawer/door count and height weights for section '+(i+1)+'.'];
 }
 return [];
}
export function sectionRects(a:SectionNode[],root:Omit<Rect,'id'>,t:number):Rect[]{
 if(treeErrors(a).length)return [];
 const out:Rect[]=[{...root,id:0}];
 for(let i=1;i<a.length;i++){
  const n=a[i],p=out[n[0]],parent=a[n[0]],kids=a.map((c,j)=>({c,j})).filter(x=>x.c[0]===n[0]).sort((a,b)=>a.c[1]-b.c[1]),gap=parent[10]==='none'?0:t;
  const available=(parent[2]==='x'?p.w:p.h)-gap*(kids.length-1),fixed=kids.filter(x=>x.c[3]==='mm').reduce((s,x)=>s+x.c[4],0),total=kids.filter(x=>x.c[3]==='weight').reduce((s,x)=>s+x.c[4],0);
  const span=(c:SectionNode)=>c[3]==='mm'?c[4]:(available-fixed)*c[4]/total;
  const size=span(n),offset=kids.filter(x=>x.c[1]<n[1]).reduce((s,x)=>s+span(x.c)+gap,0);
  out[i]=parent[2]==='x'?{id:i,x:p.x+offset,z:p.z,w:size,h:p.h}:{id:i,x:p.x,z:p.z+p.h-offset-size,w:p.w,h:size};
 }
 return out;
}
export function sectionRoot(v:Record<string,any>,t:number){
 const W=Number(v.cabinet_width),H=Number(v.cabinet_height),base=v.cabinet_mount_style!=='wall'&&v.base_style==='toe_kick'?Number(v.custom_bottom_above_toe??v.custom_toe_kick_height??0):0;
 const frame=v.front_facing_style==='face_frame',left=frame?Number(v.face_frame_side_stile_width):t,bottom=base+(frame?Number(v.face_frame_bottom_rail_width):t),top=H-(frame?Number(v.face_frame_top_rail_width):t);
 return {x:left,z:bottom,w:W-2*left,h:top-bottom};
}
export function sectionPanels(a:SectionNode[],rects:Rect[],t:number,depth:number){
 const parts:{id:string;x:number;z:number;w:number;h:number;d:number}[]=[];
 rects.forEach((r,i)=>{
  const n=a[i];
  if(i>0){const p=a[n[0]],pr=rects[n[0]];if(n[1]>0&&p[10]!=='none')parts.push(p[2]==='x'?{id:`SEC-${n[0]+1}-DIV-${n[1]}`,x:r.x-t,z:pr.z,w:t,h:pr.h,d:depth}:{id:`SEC-${n[0]+1}-DIV-${n[1]}`,x:pr.x,z:r.z+r.h,w:pr.w,h:t,d:p[10]==='rail'?Math.min(80,depth):depth});}
  if(n[2]==='leaf'&&n[5]!=='drawers'){const count=n[5]==='open'?n[6]:n[11];for(let j=1;j<=count;j++)parts.push({id:`SEC-${i+1}-SH-${j}`,x:r.x,z:r.z+r.h*j/(count+1)-t/2,w:r.w,h:t,d:depth-10});}
 });return parts;
}
export function convertBays(v:Record<string,any>):SectionNode[]{
 const hinge=(x:unknown):'left'|'right'=>x==='right'?'right':'left',style=(x:unknown):'fixed'|'adjustable'=>x==='fixed'?'fixed':'adjustable';
 if(v.cabinet_layout_mode!=='mixed_bays'){
  const doors=(n:SectionNode)=>{n[11]=Number(v.door_shelf_count)||0;n[12]=hinge(v.single_door_hinge_side);n[13]=style(v.shelf_style);return n};
  if(v.cabinet_contents==='combo'){const root=leaf();root[2]='z';const top=leaf(0,0,'drawers',Number(v.drawer_count)||2),bottom=doors(leaf(0,1,'doors',Math.min(2,Number(v.door_count)||2)));top[4]=1;bottom[4]=2;return [root,top,bottom];}
  const type=v.cabinet_contents==='doors'?'doors':v.cabinet_contents==='open'?'open':'drawers';
  const n=leaf(-1,0,type,Number(type==='doors'?Math.min(2,Number(v.door_count)||1):type==='open'?v.door_shelf_count:v.drawer_count)||(type==='open'?0:1));
  return [type==='doors'?doors(n):n];
 }
 const count=Math.max(1,Math.min(4,Number(v.mixed_bay_count)||1));
 const nodes:SectionNode[]=[leaf()];nodes[0][2]='x';nodes[0][10]=v.include_mixed_bay_partitions===false?'none':'panel';
 for(let i=0;i<count;i++){const type=/door/.test(v.mixed_bay_types?.[i])?'doors':/drawer/.test(v.mixed_bay_types?.[i])?'drawers':'open';const n=leaf(0,i,type,Number(type==='drawers'?v.mixed_bay_drawer_counts?.[i]:type==='doors'?v.mixed_bay_door_counts?.[i]:v.mixed_bay_shelf_counts?.[i])|| (type==='open'?0:1));n[4]=Number(v.mixed_bay_width_weights?.[i])||1;n[7]=v.mixed_bay_drawer_height_modes?.[i]??'equal';n[8]=v.mixed_bay_drawer_graduated_steps?.[i]??.25;n[9]=v.mixed_bay_drawer_height_weights?.[i]??Array(Math.max(1,n[6])).fill(1);n[11]=type==='doors'?Number(v.mixed_bay_shelf_counts?.[i])||0:0;n[12]=hinge(v.mixed_bay_door_hinge_sides?.[i]);n[13]=style(v.mixed_bay_shelf_styles?.[i]);nodes.push(n);}
 if(count===1){nodes[1][0]=-1;nodes[1][1]=0;return [nodes[1]];}
 return nodes;
}
export function collapseSection(a:SectionNode[],id:number):SectionNode[]{
 const remove=new Set<number>();a.forEach((n,i)=>{if(i!==id&&(n[0]===id||remove.has(n[0])))remove.add(i)});
 const kept=a.map((_,i)=>i).filter(i=>!remove.has(i)),map=new Map(kept.map((i,j)=>[i,j]));
 return kept.map(i=>{const n=structuredClone(a[i]);n[0]=n[0]===-1?-1:map.get(n[0])!;if(i===id)n[2]='leaf';return n});
}

// Parents precede children, so one pass includes every level of a selected subtree.
export function selectedSectionIds(nodes:SectionNode[],id:number):Set<number>{
 const selected=new Set<number>();
 if(id>=0&&id<nodes.length){selected.add(id);nodes.forEach((n,i)=>{if(selected.has(n[0]))selected.add(i)});}
 return selected;
}
