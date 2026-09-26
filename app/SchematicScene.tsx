'use client';
import {useEffect,useRef,useState} from 'react';
import type {Part} from '@/lib/cabinet';
import type * as Three from 'three';
type Props={parts:Part[];angle:number;tilt:number;scale:number;W:number;H:number;D:number;selected?:string|null;onSelect?:(part:Part|null)=>void;pickRef?:{current:((x:number,y:number)=>void)|null}};
export default function SchematicScene(props:Props){
 const host=useRef<HTMLDivElement>(null),latest=useRef(props),draw=useRef<()=>void>(()=>{});latest.current=props;const [error,setError]=useState('');
 useEffect(()=>{let cancelled=false,cleanup=()=>{};
 import('three').then(T=>{if(cancelled||!host.current)return;const container=host.current;
 const renderer=new T.WebGLRenderer({alpha:true,antialias:true});renderer.setPixelRatio(Math.min(window.devicePixelRatio,2));renderer.outputColorSpace=T.SRGBColorSpace;renderer.setClearColor(0,0);container.appendChild(renderer.domElement);
 const scene=new T.Scene(),group=new T.Group();scene.add(group);const camera=new T.OrthographicCamera();camera.up.set(0,0,1);
 const gridPoints=[];for(let n=-500;n<=1300;n+=100)gridPoints.push(n,-500,-115,n,1300,-115,-500,n,-115,1300,n,-115);
 const gridGeometry=new T.BufferGeometry();gridGeometry.setAttribute('position',new T.Float32BufferAttribute(gridPoints,3));const gridMaterial=new T.LineBasicMaterial({color:'#d5dfe1',depthTest:true,depthWrite:false});const grid=new T.LineSegments(gridGeometry,gridMaterial);scene.add(grid);
 let lastParts:Part[]|null=null,lastSelected:string|null|undefined;const geometries:Three.BufferGeometry[]=[],materials:Three.Material[]=[];
 const clear=()=>{group.clear();geometries.splice(0).forEach(g=>g.dispose());materials.splice(0).forEach(m=>m.dispose())};
 draw.current=()=>{const {parts,angle,tilt,scale,W,H,D}=latest.current;const width=container.clientWidth,height=container.clientHeight;if(!width||!height)return;
 if(parts!==lastParts||latest.current.selected!==lastSelected){clear();lastParts=parts;lastSelected=latest.current.selected;for(const p of parts){
  const geometry=new T.BoxGeometry(p.w,p.d,p.h);geometries.push(geometry);
  // Opaque faces write fragment depth; hidden edges must pass the same depth test.
  const faceMaterials=[.18,.1,.24,0,-.1,.15].map(shade=>{const color=new T.Color(p.id===latest.current.selected?'#35afa3':p.color);color.lerp(new T.Color(shade<0?'white':'black'),Math.abs(shade));const m=new T.MeshBasicMaterial({color,depthTest:true,depthWrite:true,polygonOffset:true,polygonOffsetFactor:1,polygonOffsetUnits:1});materials.push(m);return m});
  const mesh=new T.Mesh(geometry,faceMaterials);mesh.position.set(p.x+p.w/2,p.y+p.d/2,p.z+p.h/2);mesh.userData.partId=p.id;group.add(mesh);
  const edges=new T.EdgesGeometry(geometry);geometries.push(edges);const lineMaterial=new T.LineBasicMaterial({color:'#624f3e',depthTest:true,depthWrite:false});materials.push(lineMaterial);const outline=new T.LineSegments(edges,lineMaterial);outline.position.copy(mesh.position);outline.renderOrder=1;group.add(outline);
 }}
 const target=new T.Vector3(W/2,D/2,H/2);const distance=Math.max(W,H,D,1000)*10;
 camera.position.copy(target).add(new T.Vector3(-Math.sin(angle)*Math.cos(tilt),-Math.cos(angle)*Math.cos(tilt),Math.sin(tilt)).multiplyScalar(distance));camera.lookAt(target);
 camera.left=-450/scale;camera.right=450/scale;camera.top=350/scale;camera.bottom=-380/scale;camera.near=.1;camera.far=distance*3;camera.updateProjectionMatrix();
 renderer.setSize(width,height,false);const fit=Math.min(width/900,height/730),vw=900*fit,vh=730*fit;renderer.setViewport((width-vw)/2,(height-vh)/2,vw,vh);renderer.render(scene,camera);
 };
 if(props.pickRef)props.pickRef.current=(x,y)=>{const rect=container.getBoundingClientRect(),fit=Math.min(rect.width/900,rect.height/730),vw=900*fit,vh=730*fit;const nx=((x-rect.left-(rect.width-vw)/2)/vw)*2-1,ny=-((y-rect.top-(rect.height-vh)/2)/vh)*2+1;if(Math.abs(nx)>1||Math.abs(ny)>1)return;camera.updateMatrixWorld();const ray=new T.Raycaster();ray.setFromCamera(new T.Vector2(nx,ny),camera);const hit=ray.intersectObjects(group.children.filter(o=>o instanceof T.Mesh))[0];latest.current.onSelect?.(latest.current.parts.find(p=>p.id===hit?.object.userData.partId)??null)};
 const observer=new ResizeObserver(()=>draw.current());observer.observe(container);draw.current();cleanup=()=>{observer.disconnect();if(props.pickRef)props.pickRef.current=null;draw.current=()=>{};clear();gridGeometry.dispose();gridMaterial.dispose();renderer.dispose();renderer.domElement.remove()};
 }).catch(()=>{if(!cancelled)setError('The schematic needs WebGL. Enable hardware acceleration or try another browser.')});return()=>{cancelled=true;cleanup()};
 },[]);
 useEffect(()=>draw.current(),[props]);
 return <div className='schematic-scene' ref={host}>{error&&<p role='alert' className='schematic-render-error'>{error}</p>}</div>
}
