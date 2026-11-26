// Modular workbench (cabinet type 7): the grid, module placement and stacking rules of
// engine/.../workbench.scad, mirrored for the instant schematic, the Layout tab and input checks.
// The engine remains the authority; its Design Health report repeats every check made here.
export type Values=Record<string,any>;
export type Facing='front'|'back'|'left'|'right';
export type Contents='door'|'open'|'drawers'|'drawer_door'|'framed';
export type ModuleRow=[number,number,number,number,number,Contents,number,Facing,'left'|'right',number,1|2];
export type Module={index:number;col:number;row:number;spanX:number;spanY:number;height:number;contents:Contents;shelves:number;facing:Facing;hinge:'left'|'right';drawers:number;columns:1|2;z:number;top:number};
export const FACINGS:Facing[]=['front','back','left','right'];
export const CONTENTS:Contents[]=['door','drawers','drawer_door','open','framed'];
export const CONTENTS_LABEL:Record<Contents,string>={door:'Doors',drawers:'Drawers',drawer_door:'Drawers + door',open:'Open',framed:'Framed opening'};
const hasDrawers=(c:Contents)=>c==='drawers'||c==='drawer_door';
export const drawerCount=(m:Module)=>hasDrawers(m.contents)?m.drawers:0;
export const doorCount=(m:Module,C:number)=>m.contents==='door'||m.contents==='drawer_door'?(moduleSize(m,C).w<=C+0.01?1:2):0;
export const opens=(m:Module,C:number)=>doorCount(m,C)>0||drawerCount(m)>0;
// Two drawers side by side (with a centre partition) on an all-drawer module two or more cells wide, as the engine's dcols().
export const canSplitDrawers=(m:Module,C:number)=>m.contents==='drawers'&&moduleSize(m,C).w>=2*C-0.01;
export const drawerColumns=(m:Module,C:number):1|2=>m.columns===2&&canSplitDrawers(m,C)?2:1;
export const FRAME_SIZES:Record<string,[number,number]>={small:[2,2],medium:[3,2],large:[4,2]};
const num=(x:unknown,d:number)=>{const n=Number(x);return Number.isFinite(n)?n:d};

export function grid(v:Values){
 const C=num(v.cell_size,400),preset=FRAME_SIZES[v.frame_size];
 const cols=preset?preset[0]:Math.max(1,Math.min(5,Math.round(num(v.grid_columns,3))));
 const rows=preset?preset[1]:Math.max(1,Math.min(3,Math.round(num(v.grid_rows,2))));
 return {C,cols,rows,length:cols*C,depth:rows*C};
}
// Same defaults and clamps as the engine's norm_module().
export function normalizeRow(m:unknown):ModuleRow{
 const a=Array.isArray(m)?m:[];
 const at=(i:number,d:any)=>a[i]===undefined||a[i]===null?d:a[i];
 const f=at(7,'front');
 return [Math.max(0,Math.floor(num(at(0,0),0))),Math.max(0,Math.floor(num(at(1,0),0))),Math.max(1,Math.floor(num(at(2,1),1))),Math.max(1,Math.floor(num(at(3,1),1))),
  num(at(4,730),730),(CONTENTS.includes(at(5,'door'))?at(5,'door'):'door') as Contents,Math.max(0,Math.min(8,Math.floor(num(at(6,1),1)))),(FACINGS.includes(f)?f:'front') as Facing,at(8,'right')==='left'?'left':'right',
  Math.max(1,Math.min(8,Math.floor(num(at(9,3),3)))),at(10,1)===2?2:1];
}
export const rows=(v:Values):ModuleRow[]=>(Array.isArray(v.modules)?v.modules:[]).filter(Array.isArray).map(normalizeRow);
const overlap=(a:Module,b:Module)=>a.col<b.col+b.spanX&&b.col<a.col+a.spanX&&a.row<b.row+b.spanY&&b.row<a.row+a.spanY;
export const covers=(m:Module,c:number,r:number)=>c>=m.col&&c<m.col+m.spanX&&r>=m.row&&r<m.row+m.spanY;
export const baseHeight=(v:Values)=>num(v.caster_height,75)+num(v.frame_height,85);
// Modules in list order; each rests on the highest earlier module under its cells (or the frame).
export function modules(v:Values):Module[]{
 const zb=baseHeight(v),out:Module[]=[];
 rows(v).forEach((r,index)=>{
  const m:Module={index,col:r[0],row:r[1],spanX:r[2],spanY:r[3],height:r[4],contents:r[5],shelves:r[6],facing:r[7],hinge:r[8],drawers:r[9],columns:r[10],z:zb,top:0};
  m.z=Math.max(zb,...out.filter(o=>overlap(o,m)).map(o=>o.top));m.top=m.z+m.height;out.push(m);
 });
 return out;
}
export const sideways=(m:Module)=>m.facing==='left'||m.facing==='right';
// Width across the module's face and depth front to back, in mm.
export const moduleSize=(m:Module,C:number)=>({w:(sideways(m)?m.spanY:m.spanX)*C,d:(sideways(m)?m.spanX:m.spanY)*C});
export function stackTop(v:Values,c:number,r:number,list=modules(v)){return Math.max(baseHeight(v),...list.filter(m=>covers(m,c,r)).map(m=>m.top))}
// Overall size including the worksurface overhang, frame and casters.
export function size(v:Values){
 const g=grid(v),list=modules(v),ws=v.include_worksurface!==false,ov=ws?num(v.worksurface_overhang,50):0;
 const top=list.length?Math.max(...list.map(m=>m.top)):baseHeight(v)+730;
 return {w:g.length+2*ov,d:g.depth+2*ov,h:top+(ws?num(v.worksurface_thickness,18):0),frameTop:baseHeight(v),moduleTop:top,overhang:ov};
}
// Cells directly in front of a module's face.
export function frontCells(m:Module):[number,number][]{
 if(m.facing==='front')return Array.from({length:m.spanX},(_,i)=>[m.col+i,m.row-1]);
 if(m.facing==='back')return Array.from({length:m.spanX},(_,i)=>[m.col+i,m.row+m.spanY]);
 if(m.facing==='left')return Array.from({length:m.spanY},(_,j)=>[m.col-1,m.row+j]);
 return Array.from({length:m.spanY},(_,j)=>[m.col+m.spanX,m.row+j]);
}
// Drawer bands, (j = 0 is the top drawer): [z0,z1] of each drawer's share of the module height, as the engine's drawer_band().
export function drawerBands(m:Module,v:Values):[number,number][]{
 const n=drawerCount(m),p=m.contents==='drawers'?m.height/n:num(v.combo_drawer_height,150);
 return Array.from({length:n},(_,j)=>[m.height-(j+1)*p,m.height-j*p]);
}
export const doorBandTop=(m:Module,v:Values)=>m.contents==='drawer_door'?m.height-m.drawers*num(v.combo_drawer_height,150):m.height;
// Drawer box heights, as the engine's dbox_h().
export function drawerBoxHeights(m:Module,v:Values){
 const tc=num(v.carcass_thickness,18),vc=num(v.drawer_vertical_clearance,20);
 return drawerBands(m,v).map(([a,b])=>Math.min(m.height-tc,b)-Math.max(tc,a)-vc);
}
// Plain-language problems that stop the engine from building the layout (the engine's CHECK|ERRORs).
export function problems(v:Values):string[]{
 const g=grid(v),list=modules(v),out:string[]=[],tc=num(v.carcass_thickness,18),rail=num(v.top_rail_width,75),zb=baseHeight(v);
 if(!list.length&&v.include_worksurface!==false)out.push('Place at least one module: the worksurface rests on the modules.');
 for(const m of list){
  const id='M'+(m.index+1);
  if(m.col+m.spanX>g.cols||m.row+m.spanY>g.rows)out.push(`${id} does not fit the ${g.cols} × ${g.rows} grid.`);
  const cells=[];for(let i=0;i<m.spanX;i++)for(let j=0;j<m.spanY;j++)cells.push([m.col+i,m.row+j]);
  if(cells.some(([c,r])=>Math.abs(Math.max(zb,...list.filter(o=>o.index<m.index&&covers(o,c,r)).map(o=>o.top))-m.z)>0.01))out.push(`${id} is not fully supported: the cells under it end at different heights.`);
  if(m.height<2*tc+rail||m.height>2400)out.push(`${id} height must be between ${2*tc+rail} and 2400 mm.`);
  if(opens(m,g.C))for(const o of list)if(o!==m&&o.z<m.top-0.01&&o.top>m.z+0.01&&frontCells(m).some(([c,r])=>covers(o,c,r)))out.push(`${id}'s ${drawerCount(m)?'drawers':'doors'} open into M${o.index+1}; turn it to face an open side.`);
  if(drawerCount(m)){
   const need=Math.max(num(v.metal_slide_envelope_height,45)+4,num(v.drawer_bottom_inset,8)+num(v.drawer_bottom_thickness,12)+10);
   if(Math.min(...drawerBoxHeights(m,v))<need)out.push(`${id} is too low for ${m.drawers} drawers; use fewer drawers or a taller module.`);
   if(m.contents==='drawer_door'&&doorBandTop(m,v)<tc+2*rail)out.push(`${id} has no room for a door below its ${m.drawers} drawer${m.drawers===1?'':'s'}.`);
  }
 }
 return out;
}
export type SchematicPart={id:string;name:string;x:number;y:number;z:number;w:number;d:number;h:number;color:string;group:string};
// Approximate parts for the instant schematic, with the engine's part ids.
export function schematic(v:Values,interior:boolean,explode:boolean):SchematicPart[]{
 const g=grid(v),C=g.C,parts:SchematicPart[]=[];
 const tf=num(v.frame_thickness,18),tc=num(v.carcass_thickness,18),td=num(v.door_thickness,18),ts=num(v.shelf_thickness,12),tw=num(v.worksurface_thickness,18),th=num(v.handle_thickness,18);
 const zf=num(v.caster_height,75),hf=num(v.frame_height,85),inset=num(v.frame_rail_inset,60),rail=num(v.top_rail_width,75),gap=num(v.door_gap,5),ex=explode?60:0;
 const add=(id:string,name:string,x:number,y:number,z:number,w:number,d:number,h:number,color:string,group:string)=>{if(w>0&&d>0&&h>0)parts.push({id,name,x,y,z,w,d,h,color,group})};
 const longY=Array.from({length:g.rows},(_,r)=>[r*C+inset,r*C+C-inset]).flat();
 const crossCols=v.frame_cross_members==='every_column'?Array.from({length:g.cols},(_,c)=>c):g.cols===1?[0]:[0,g.cols-1];
 const crossX=crossCols.flatMap(c=>[c*C+inset,c*C+C-inset]);
 longY.forEach((y,i)=>add('FR-L'+(i+1),'Base frame strip',0,y-tf/2,zf-ex,g.length,tf,hf,'#a57a4b','frame'));
 crossX.forEach((x,i)=>add('FR-C'+(i+1),'Base frame cross strip',x-tf/2,0,zf-ex,tf,g.depth,hf,'#a57a4b','frame'));
 if(v.show_hardware!==false&&zf>0)for(const x of [crossX[0],crossX[crossX.length-1]])for(const y of [longY[0],longY[longY.length-1]])add(`CASTER-${x}-${y}`,'Caster',x-20,y-25,-ex,40,50,zf,'#344144','hardware');
 const list=modules(v);
 for(const m of list){
  const {w:W,d:D}=moduleSize(m,C),H=m.height,x0=m.col*C,y0=m.row*C,id='M'+(m.index+1)+'-';
  // Local (x across the face, y from the face back, z up) to world, as the engine's mmatrix().
  const world=(x:number,y:number):[number,number]=>m.facing==='back'?[x0+W-x,y0+D-y]:m.facing==='left'?[x0+y,y0+W-x]:m.facing==='right'?[x0+D-y,y0+x]:[x0+x,y0+y];
  const box=(pid:string,name:string,x:number,y:number,z:number,w:number,d:number,h:number,color:string,group:string)=>{
   const [ax,ay]=world(x,y),[bx,by]=world(x+w,y+d);add(id+pid,name,Math.min(ax,bx),Math.min(ay,by),m.z+z+ex*(m.index%2?1:0.5),Math.abs(bx-ax),Math.abs(by-ay),h,color,group)};
  box('SIDE-L','Module side',0,td,0,tc,D-td,H,'#bd8e59','carcass');box('SIDE-R','Module side',W-tc,td,0,tc,D-td,H,'#bd8e59','carcass');
  box('BOTTOM','Module bottom',tc,td,0,W-2*tc,D-td,tc,'#bd8e59','carcass');box('BACK','Module back',tc,D-tc,tc,W-2*tc,tc,H-tc,'#a0784e','back');
  box('RAIL-F','Front top rail',tc,td,H-tc,W-2*tc,rail,tc,'#bd8e59','carcass');box('RAIL-B','Back top rail',tc,D-tc-rail,H-tc,W-2*tc,rail,tc,'#bd8e59','carcass');
  const zone=doorBandTop(m,v),fronts=!interior&&v.show_doors!==false,pull=v.handle_style!=='none',hTop=num(v.handle_top_offset,72.5);
  if(m.contents!=='drawers')for(let i=1;i<=m.shelves;i++)box('SHELF-'+i,'Adjustable shelf',tc,td+20,tc+(zone-2*tc)*i/(m.shelves+1),W-2*tc,D-td-tc-25,ts,'#c7a272','shelf');
  const nd=doorCount(m,C);
  if(nd&&fronts){
   const dw=W/nd-gap,dh=zone-gap;
   for(let j=0;j<nd;j++){
    const x=j*W/nd+gap/2,hingeLeft=nd===1?m.hinge==='left':j===0;
    box('DOOR-'+(j+1),'Door',x,-ex*0.6,gap/2,dw,td,dh,'#d4b182','front');
    if(pull){const u=hingeLeft?dw-num(v.handle_edge_offset,117.5):num(v.handle_edge_offset,117.5);box('HANDLE-'+(j+1),'Pull',x+u-70,-th-ex*0.6,gap/2+dh-hTop-12,140,th,24,'#6d5034','hardware')}
   }
  }
  // Face panel of a framed module, drawn as the four borders around its opening.
  if(m.contents==='framed'&&fronts){const b=num(v.face_opening_border,40),fw=W-gap,fh=H-gap,y=-ex*0.6;
   box('FACE','Face panel',gap/2,y,gap/2,fw,td,b,'#d4b182','front');box('FACE-TOP','Face panel',gap/2,y,gap/2+fh-b,fw,td,b,'#d4b182','front');
   box('FACE-L','Face panel',gap/2,y,gap/2+b,b,td,fh-2*b,'#d4b182','front');box('FACE-R','Face panel',gap/2+fw-b,y,gap/2+b,b,td,fh-2*b,'#d4b182','front')}
  if(drawerCount(m)){
   const sc=num(v.metal_slide_clearance_per_side,12.7),vc=num(v.drawer_vertical_clearance,20),room=D-td-tc-num(v.drawer_rear_clearance,5);
   const fit=[250,300,350,400,450,500,550,600,650,700].filter(s=>s<=room),slide=num(v.metal_slide_length,0)>0?num(v.metal_slide_length,0):fit.length?Math.max(...fit):100;
   const n=drawerColumns(m,C),cellW=n===2?(W-3*tc)/2:W-2*tc;
   if(n===2)box('PARTITION','Drawer partition',W/2-tc/2,td,0,tc,D-td-tc,H,'#bd8e59','carcass');
   drawerBands(m,v).forEach(([a,b],j)=>{for(let c=0;c<n;c++){
    const id='DRAWER-'+(j+1)+(n===2?(c?'R':'L'):'')+'-',z0=Math.max(tc,a)+vc/2,bh=Math.min(H-tc,b)-Math.max(tc,a)-vc,out=interior?0:ex*0.4;
    const bx=c?W/2+tc/2+sc:tc+sc,fw=W/n-gap,fx=c*W/n+gap/2;
    box(id+'BOX','Drawer box',bx,td-out,z0,cellW-2*sc,Math.max(100,slide),bh,'#e0c79c','drawer');
    if(fronts){
     const fh=b-a-gap;box(id+'FACE','Drawer face',fx,-ex*0.6-out,a+gap/2,fw,td,fh,'#d4b182','front');
     if(pull)box(id+'HANDLE','Pull',fx+fw/2-70,-th-ex*0.6-out,a+gap/2+fh-Math.min(hTop,fh/2)-12,140,th,24,'#6d5034','hardware');
    }
   }});
  }
 }
 const s=size(v);
 if(v.include_worksurface!==false&&v.show_worksurface!==false&&!interior&&list.length)add('TOP','Worksurface',-s.overhang,-s.overhang,s.moduleTop+ex*2.5,g.length+2*s.overhang,g.depth+2*s.overhang,tw,'#d8b079','worktop');
 // The schematic's envelope starts at the worksurface edge.
 return parts.map(p=>({...p,x:p.x+s.overhang,y:p.y+s.overhang}));
}
