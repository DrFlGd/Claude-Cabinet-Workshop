// Per-sheet nesting of the engine's flat cut layout.
//
// The engine lays every through-cut part out in one tall strip and records where
// each part sits (PLACE|id|X=|Y=|W=|H=, engine coordinates, y up). This module
// groups those parts by material and thickness, places them on stock sheets with
// a guillotine free-rectangle packer (largest part first, best short-side fit),
// and re-maps every operation layout (cut, pocket, engrave) from strip
// coordinates to sheet coordinates, one SVG and one DXF per sheet per operation.
// Parts keep the orientation the engine drew them in unless rotation is allowed,
// so grain stays as designed by default.
export type Placement={id:string;x:number;y:number;w:number;h:number};
export type Part={id:string;qty:number;category:string;material:string;thickness:number;w:number;h:number};
// rotate: 'never' keeps every part as the engine drew it (grain as designed), 'needed'
// turns a part only when it cannot fit the sheet as drawn, 'free' lets the packer choose.
export type Rotate='never'|'needed'|'free';
export type NestOptions={sheetW:number;sheetH:number;margin:number;gap:number;rotate:Rotate};
export type SheetPlacement={id:string;x:number;y:number;w:number;h:number;rot:0|90;src:Placement};
export type Sheet={index:number;material:string;thickness:number;w:number;h:number;placements:SheetPlacement[];used:number};
export type Unplaced={id:string;material:string;thickness:number;w:number;h:number;reason:string};
export type NestResult={sheets:Sheet[];unplaced:Unplaced[];options:NestOptions};
type Rect={x:number;y:number;w:number;h:number};

const PLACE=/^PLACE\|([^|]+)\|X=(-?[\d.]+)\|Y=(-?[\d.]+)\|W=(-?[\d.]+)\|H=(-?[\d.]+)/;
const EPS=0.001;

// PLACE and BOM records from a list of echo payloads (KIND|...).
export function placementRecords(records:string[]):Placement[]{
 const out:Placement[]=[];
 for(const r of records){const m=r.match(PLACE);if(m)out.push({id:m[1],x:+m[2],y:+m[3],w:+m[4],h:+m[5]})}
 return out;
}
export function partRecords(records:string[]):Part[]{
 const out:Part[]=[];
 for(const r of records){if(!r.startsWith('BOM|'))continue;const f=r.split('|');out.push({id:f[1],qty:+f[2],category:f[3],material:f[4],thickness:+f[5],w:+f[6],h:+f[7]})}
 return out;
}

// Nesting options from the design's own settings: the stock sheet, the layout gap as
// the sheet margin, and a part spacing that covers the gap, the kerf and the cutter.
export function nestOptions(values:Record<string,any>,rotate:Rotate='needed'):NestOptions{
 const n=(k:string,d:number)=>{const v=Number(values[k]);return Number.isFinite(v)&&v>0?v:d};
 const gap=n('layout_gap',20);
 return {sheetW:n('stock_width',2440),sheetH:n('stock_height',1220),margin:gap,gap:Math.max(gap,n('kerf',0),n('cnc_tool_diameter',0),n('router_bit_diameter',0)),rotate};
}

const lexLess=(a:number[],b:number[])=>{for(let k=0;k<a.length;k++)if(a[k]!==b[k])return a[k]<b[k];return false};
function pruneFree(rects:Rect[]){
 const kept=rects.filter(r=>r.w>0.5&&r.h>0.5);
 return kept.filter((a,i)=>!kept.some((b,j)=>j!==i&&b.x<=a.x+EPS&&b.y<=a.y+EPS&&b.x+b.w>=a.x+a.w-EPS&&b.y+b.h>=a.y+a.h-EPS&&(j<i||b.w*b.h>a.w*a.h+EPS)));
}

type Working=Sheet&{free:Rect[];margin:number};
function newSheet(index:number,material:string,thickness:number,o:NestOptions):Working{
 const m=Math.min(o.margin,Math.min(o.sheetW,o.sheetH)/3);
 return {index,material,thickness,w:o.sheetW,h:o.sheetH,placements:[],used:0,margin:m,free:[{x:m,y:m,w:Math.max(0,o.sheetW-2*m),h:Math.max(0,o.sheetH-2*m)}]};
}
function tryPlace(p:Placement,sheet:Working,o:NestOptions,rotations:(0|90)[]){
 type Best={i:number;rot:0|90;w:number;h:number;score:number[]};
 let best:Best|null=null;
 for(const rot of rotations){
  const w=rot?p.h:p.w,h=rot?p.w:p.h;
  sheet.free.forEach((r,i)=>{
   // The part needs its gap on the right and top too, unless that side is the usable edge of the sheet.
   const fitsW=w+o.gap<=r.w+EPS||(w<=r.w+EPS&&r.x+r.w>=sheet.w-sheet.margin-EPS),fitsH=h+o.gap<=r.h+EPS||(h<=r.h+EPS&&r.y+r.h>=sheet.h-sheet.margin-EPS);
   if(!fitsW||!fitsH)return;
   // Best short-side fit, then least wasted area, then lowest and leftmost, then unrotated.
   const score=[Math.min(r.w-w,r.h-h),r.w*r.h-w*h,r.y,r.x,rot];
   if(!best||lexLess(score,best.score))best={i,rot,w,h,score};
  });
 }
 const b=best as Best|null; // assigned inside the forEach callback, which narrowing cannot see
 if(!b)return false;
 const r=sheet.free[b.i];
 sheet.placements.push({id:p.id,x:r.x,y:r.y,w:b.w,h:b.h,rot:b.rot,src:p});sheet.used+=b.w*b.h;
 // Maximal rectangles: the part's footprint (part plus gap on its right and top) is
 // cut out of every free rectangle it touches, so free rectangles never overlap a part.
 const F={x:r.x,y:r.y,w:b.w+o.gap,h:b.h+o.gap},next:Rect[]=[];
 for(const f of sheet.free){
  if(F.x>=f.x+f.w-EPS||F.x+F.w<=f.x+EPS||F.y>=f.y+f.h-EPS||F.y+F.h<=f.y+EPS){next.push(f);continue}
  next.push({x:f.x,y:f.y,w:F.x-f.x,h:f.h},{x:F.x+F.w,y:f.y,w:f.x+f.w-F.x-F.w,h:f.h},{x:f.x,y:f.y,w:f.w,h:F.y-f.y},{x:f.x,y:F.y+F.h,w:f.w,h:f.y+f.h-F.y-F.h});
 }
 sheet.free=pruneFree(next);
 return true;
}

// Places every part that has a placement record. Parts are grouped by material and
// thickness; each group gets as many sheets as it needs. A part larger than the
// usable sheet (in either orientation when rotation is allowed) is reported, not dropped.
export function nest(parts:Part[],placements:Placement[],options:NestOptions):NestResult{
 const o={...options,gap:Math.max(0,options.gap),margin:Math.max(0,options.margin)};
 const byId=new Map(parts.map(p=>[p.id,p]));
 const items=placements.filter(p=>byId.has(p.id)).sort((a,b)=>b.w*b.h-a.w*a.h||a.id.localeCompare(b.id,undefined,{numeric:true}));
 const groups=new Map<string,Placement[]>();
 for(const p of items){const part=byId.get(p.id)!,k=part.material+'|'+part.thickness.toFixed(3);(groups.get(k)??groups.set(k,[]).get(k)!).push(p)}
 const sheets:Working[]=[],unplaced:Unplaced[]=[];
 for(const [,list] of [...groups.entries()].sort((a,b)=>a[0].localeCompare(b[0]))){
  const part=byId.get(list[0].id)!,own:Working[]=[];
  for(const p of list){
   const square=Math.abs(p.w-p.h)<=EPS,usable=(d:number)=>d-2*Math.min(o.margin,Math.min(o.sheetW,o.sheetH)/3);
   const fitsAsDrawn=p.w<=usable(o.sheetW)+EPS&&p.h<=usable(o.sheetH)+EPS;
   const rotations:(0|90)[]=square?[0]:o.rotate==='free'?[0,90]:o.rotate==='needed'&&!fitsAsDrawn?[90]:[0];
   if(own.some(s=>tryPlace(p,s,o,rotations)))continue;
   const s=newSheet(sheets.length+own.length+1,part.material,part.thickness,o);
   if(tryPlace(p,s,o,rotations))own.push(s);
   else unplaced.push({id:p.id,material:part.material,thickness:part.thickness,w:p.w,h:p.h,reason:`${p.w} x ${p.h} mm does not fit the ${o.sheetW} x ${o.sheetH} mm sheet inside a ${o.margin} mm margin${o.rotate==='never'?' (rotation off)':''}.`});
  }
  sheets.push(...own);
 }
 return {sheets:sheets.map(({free:_f,margin:_m,...s})=>s),unplaced,options:o};
}

// ---- re-mapping the engine's layouts onto sheets ----
type Poly=[number,number][];
// Closed subpaths of OpenSCAD's SVG export as polygons in engine coordinates (y up).
export function svgPolygons(svg:string):Poly[]{
 const polys:Poly[]=[];
 for(const m of svg.matchAll(/<path[^>]*\sd="([^"]+)"/g)){
  for(const sp of m[1].split(/(?=M)/)){
   const nums=[...sp.matchAll(/-?\d+(?:\.\d+)?(?:e-?\d+)?/g)].map(x=>+x[0]);
   const pts:Poly=[];for(let i=0;i+1<nums.length;i+=2)pts.push([nums[i],-nums[i+1]]);
   if(pts.length>=3)polys.push(pts);
  }
 }
 return polys;
}
const bbox=(pts:Poly)=>{let x0=Infinity,y0=Infinity,x1=-Infinity,y1=-Infinity;for(const [x,y] of pts){x0=Math.min(x0,x);y0=Math.min(y0,y);x1=Math.max(x1,x);y1=Math.max(y1,y)}return {x0,y0,x1,y1}};
const num=(v:number)=>String(Math.round(v*1000)/1000);

// Polygons of one operation layout, re-mapped to one sheet: every subpath whose
// extent lies within a placed part's strip rectangle (widened by `slack`, the kerf
// compensation) moves with that part. Subpaths outside every part, such as the
// registration frame, are left out. Returns one entry per part with its polygons.
export function sheetPolygons(svg:string,sheet:Sheet,slack=0){
 const polys=svgPolygons(svg);
 const out:{id:string;polys:Poly[]}[]=sheet.placements.map(p=>({id:p.id,polys:[]}));
 for(const poly of polys){
  const b=bbox(poly);
  // OpenSCAD writes six significant digits, so a contour high up the strip can sit
  // 0.1 mm outside its placement rectangle; the tolerance grows with the coordinate.
  const t=slack+0.05+1e-5*Math.max(Math.abs(b.x1),Math.abs(b.y1));
  const k=sheet.placements.findIndex(p=>b.x0>=p.src.x-t&&b.y0>=p.src.y-t&&b.x1<=p.src.x+p.src.w+t&&b.y1<=p.src.y+p.src.h+t);
  if(k<0)continue;
  const p=sheet.placements[k];
  out[k].polys.push(poly.map(([x,y])=>{const rx=x-p.src.x,ry=y-p.src.y;return p.rot?[p.x+(p.src.h-ry),p.y+rx]:[p.x+rx,p.y+ry]}) as Poly);
 }
 return out;
}

// One sheet's layout for one operation, in the engine's SVG convention (millimetres,
// y negated, one path per part) with a registration frame around the stock.
export function sheetSvg(svg:string,sheet:Sheet,operation:string,slack=0){
 const parts=sheetPolygons(svg,sheet,slack);
 const d=(polys:Poly[])=>polys.map(pts=>'M '+pts.map(([x,y])=>num(x)+','+num(-y)).join(' L ')+' z').join('\n');
 const W=sheet.w,H=sheet.h,f=0.2;
 const frame=`M 0,0 L ${num(W)},0 L ${num(W)},${num(-H)} L 0,${num(-H)} z\nM ${num(f)},${num(-f)} L ${num(f)},${num(-(H-f))} L ${num(W-f)},${num(-(H-f))} L ${num(W-f)},${num(-f)} z`;
 return `<?xml version="1.0" standalone="no"?>\n<svg width="${num(W)}mm" height="${num(H)}mm" viewBox="0 ${num(-H)} ${num(W)} ${num(H)}" xmlns="http://www.w3.org/2000/svg" version="1.1">\n<title>${esc(operation)} · sheet ${sheet.index} · ${esc(sheet.material)} ${num(sheet.thickness)} mm</title>\n<path id="stock-frame" d="\n${frame}\n" fill="none" stroke="#7a8c94" stroke-width="0.5"/>\n`+
  parts.filter(p=>p.polys.length).map(p=>`<path id="${esc(p.id)}" d="\n${d(p.polys)}\n" fill="lightgray" stroke="black" stroke-width="0.5"/>`).join('\n')+'\n</svg>\n';
}

// The same sheet as a minimal DXF (millimetres, closed LWPOLYLINE per contour, one
// layer per operation, the stock outline on layer STOCK).
export function sheetDxf(svg:string,sheet:Sheet,operation:string,slack=0){
 const parts=sheetPolygons(svg,sheet,slack),lines:string[]=['0','SECTION','2','HEADER','9','$ACADVER','1','AC1015','9','$INSUNITS','70','4','0','ENDSEC','0','SECTION','2','ENTITIES'];
 const poly=(pts:Poly,layer:string)=>{lines.push('0','LWPOLYLINE','8',layer,'90',String(pts.length),'70','1');for(const [x,y] of pts)lines.push('10',num(x),'20',num(y))};
 poly([[0,0],[sheet.w,0],[sheet.w,sheet.h],[0,sheet.h]],'STOCK');
 const layer=operation.toUpperCase().replace(/[^A-Z0-9]+/g,'-');
 for(const p of parts)for(const pts of p.polys)poly(pts,layer);
 lines.push('0','ENDSEC','0','EOF');
 return lines.join('\r\n')+'\r\n';
}

// A JSON record of where every part went, for CAM operators and for re-checking.
export function nestingReport(result:NestResult){
 return JSON.stringify({schema:'claude-cabinet-workshop-nesting-v1',units:'mm',options:result.options,sheets:result.sheets.map(s=>({sheet:s.index,material:s.material,thickness:s.thickness,width:s.w,height:s.h,utilization:Math.round(1000*s.used/(s.w*s.h))/1000,parts:s.placements.map(p=>({id:p.id,x:p.x,y:p.y,width:p.w,height:p.h,rotation:p.rot}))})),unplaced:result.unplaced},null,2);
}

// Short summary line, e.g. "3 sheets: 2 × CARCASS 18 mm, 1 × BACK 6 mm".
export function nestingSummary(result:NestResult,name=(m:string)=>m){
 const counts=new Map<string,number>();
 for(const s of result.sheets){const k=`${name(s.material)} ${num(s.thickness)} mm`;counts.set(k,(counts.get(k)??0)+1)}
 const n=result.sheets.length;
 return `${n} sheet${n===1?'':'s'}${n?': '+[...counts].map(([k,c])=>`${c} × ${k}`).join(', '):''}${result.unplaced.length?` · ${result.unplaced.length} part${result.unplaced.length===1?'':'s'} too large for the sheet`:''}`;
}

// Problems with a nesting result (empty when it is sound): every part placed, no two
// parts closer than the gap, nothing outside the sheet margin, and, when the cut
// layout is given, exactly one outline per part on each sheet.
export function checkNesting(result:NestResult,parts:Part[],cutSvg?:string,slack=0){
 const problems:string[]=[];
 const ids=new Set(parts.map(p=>p.id)),placed=new Set<string>();
 for(const u of result.unplaced)problems.push(`${u.id} not placed: ${u.reason}`);
 for(const s of result.sheets){
  const m=Math.min(result.options.margin,Math.min(s.w,s.h)/3);
  for(const p of s.placements){
   if(placed.has(p.id))problems.push(`${p.id} placed twice`);placed.add(p.id);
   if(p.x<m-EPS||p.y<m-EPS||p.x+p.w>s.w-m+EPS||p.y+p.h>s.h-m+EPS)problems.push(`${p.id} leaves the usable area of sheet ${s.index}`);
   const sw=p.rot?p.src.h:p.src.w,sh=p.rot?p.src.w:p.src.h;
   if(Math.abs(sw-p.w)>EPS||Math.abs(sh-p.h)>EPS)problems.push(`${p.id} changed size on sheet ${s.index}`);
  }
  for(let i=0;i<s.placements.length;i++)for(let j=i+1;j<s.placements.length;j++){
   const a=s.placements[i],b=s.placements[j],g=result.options.gap-EPS;
   if(a.x<b.x+b.w+g&&b.x<a.x+a.w+g&&a.y<b.y+b.h+g&&b.y<a.y+a.h+g)problems.push(`${a.id} and ${b.id} are closer than ${result.options.gap} mm on sheet ${s.index}`);
  }
  if(cutSvg)for(const p of sheetPolygons(cutSvg,s,slack)){
   const outer=p.polys.filter(a=>!p.polys.some(b=>b!==a&&encloses(b,a)));
   if(outer.length!==1)problems.push(`${p.id} has ${outer.length} outlines on sheet ${s.index}`);
  }
 }
 for(const id of ids)if(!placed.has(id)&&!result.unplaced.some(u=>u.id===id))problems.push(`${id} has no placement`);
 return problems;
}
function encloses(q:Poly,p:Poly){
 const a=bbox(q),b=bbox(p);
 return a.x0<=b.x0+EPS&&a.y0<=b.y0+EPS&&a.x1>=b.x1-EPS&&a.y1>=b.y1-EPS&&(a.x1-a.x0)*(a.y1-a.y0)>(b.x1-b.x0)*(b.y1-b.y0)&&inside(p[0],q);
}
function inside([px,py]:[number,number],poly:Poly){
 let c=false;
 for(let i=0,j=poly.length-1;i<poly.length;j=i++){const [xi,yi]=poly[i],[xj,yj]=poly[j];if((yi>py)!==(yj>py)&&px<(xj-xi)*(py-yi)/(yj-yi)+xi)c=!c}
 return c;
}
const esc=(s:string)=>s.replace(/[&<>"]/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[c]!));
