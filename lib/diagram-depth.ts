import type {Part} from './cabinet';
export type Point=[number,number,number];
export type Face={points:Point[];original:Point[];axis:0|1|2;offset:number;id:string;shade:number};
export const viewDirection:Point=[.55,-.82,.3339];
export const projectPoint=([x,y,z]:Point):[number,number]=>[x*.82+y*.55,-z-y*.32+x*.13];
const epsilon=1e-7;
// BSP partitions faces in 3D, so crossing projections and long panels are ordered
// correctly. Splits are clipped in SVG instead of outlining artificial seams.
export function depthOrderedFaces(parts:{part:Part;id:string}[]):Face[]{
 const faces=parts.flatMap(({part:p,id})=>{
  const v:Point[]=[[p.x,p.y,p.z],[p.x+p.w,p.y,p.z],[p.x+p.w,p.y+p.d,p.z],[p.x,p.y+p.d,p.z],[p.x,p.y,p.z+p.h],[p.x+p.w,p.y,p.z+p.h],[p.x+p.w,p.y+p.d,p.z+p.h],[p.x,p.y+p.d,p.z+p.h]];
  return [[0,1,5,4],[1,2,6,5],[4,5,6,7]].map((indices,shade)=>{const points=indices.map(i=>v[i]),axis=([1,0,2] as const)[shade];return {points,original:points,axis,offset:points[0][axis],id,shade}});
 });
 function order(list:Face[]):Face[]{
  if(!list.length)return [];
  const plane=list[0],back:Face[]=[],front:Face[]=[],same:Face[]=[];
  for(const face of list){const ds=face.points.map(p=>p[plane.axis]-plane.offset),positive=ds.some(d=>d>epsilon),negative=ds.some(d=>d< -epsilon);
   if(!positive&&!negative){same.push(face);continue}if(!negative){front.push(face);continue}if(!positive){back.push(face);continue}
   const a:Point[]=[],b:Point[]=[];
   for(let i=0;i<face.points.length;i++){const p=face.points[i],q=face.points[(i+1)%face.points.length],d=ds[i],e=ds[(i+1)%ds.length];if(d>=-epsilon)a.push(p);if(d<=epsilon)b.push(p);if((d>epsilon&&e< -epsilon)||(d< -epsilon&&e>epsilon)){const t=d/(d-e),hit=p.map((n,j)=>n+(q[j]-n)*t) as Point;a.push(hit);b.push(hit)}}
   if(a.length>=3)front.push({...face,points:a});if(b.length>=3)back.push({...face,points:b});
  }
  return viewDirection[plane.axis]>0?[...order(back),...same,...order(front)]:[...order(front),...same,...order(back)];
 }
 return order(faces);
}
