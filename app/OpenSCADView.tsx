'use client';
import {assetUrl} from '@/lib/asset-url';
import {useEffect,useRef,useState} from 'react';
import {Box,Play,Square,RotateCcw,Info,Check,LoaderCircle} from 'lucide-react';
import {Select,SelectTrigger,SelectValue,SelectContent,SelectItem} from '@/components/ui/select';
import {configuredSource,renderSources,families,schemas,validate,Values,Part} from '@/lib/cabinet';
import {partAtPoint} from '@/lib/selection';
import type {BufferGeometry,Material,WebGLRenderer} from 'three';

function MeshView({bytes,active,selected,parts,onSelect}:{bytes:ArrayBuffer;active:boolean;selected?:Part;parts:Part[];onSelect?:(p:Part|null)=>void}){
 const selection=useRef({selected,parts,onSelect});selection.current={selected,parts,onSelect};
 const host=useRef<HTMLDivElement>(null),reset=useRef<()=>void>(()=>{});const [error,setError]=useState('');
 useEffect(()=>{if(!active||!host.current)return;const container=host.current;let disposed=false,cleanup=()=>{};setError('');
 (async()=>{const [T,{STLLoader},{OrbitControls}]=await Promise.all([import('three'),import('three/examples/jsm/loaders/STLLoader.js'),import('three/examples/jsm/controls/OrbitControls.js')]);if(disposed)return;
 let renderer:WebGLRenderer;try{renderer=new T.WebGLRenderer({antialias:true,alpha:true})}catch{throw Error('3D rendering is unavailable in this browser. The schematic preview is still available.')}
 const geometries:BufferGeometry[]=[],materials:Material[]=[];const scene=new T.Scene();scene.background=new T.Color('#edf1f2');
 const camera=new T.PerspectiveCamera(36,1,.1,100000);camera.up.set(0,0,1);const controls=new OrbitControls(camera,renderer.domElement);controls.enableDamping=true;
 const geometry=new STLLoader().parse(bytes);geometries.push(geometry);geometry.computeVertexNormals();geometry.computeBoundingBox();const bounds=geometry.boundingBox!;const center=bounds.getCenter(new T.Vector3()),size=bounds.getSize(new T.Vector3());const span=Math.max(size.x,size.y,size.z,1);
 const material=new T.MeshStandardMaterial({color:'#c7a175',roughness:.78,metalness:0,side:T.DoubleSide});materials.push(material);const cabinetMesh=new T.Mesh(geometry,material);scene.add(cabinetMesh);
 const edges=new T.EdgesGeometry(geometry,32);geometries.push(edges);const edgeMaterial=new T.LineBasicMaterial({color:'#6a5744',transparent:true,opacity:.25});materials.push(edgeMaterial);scene.add(new T.LineSegments(edges,edgeMaterial));
 scene.add(new T.HemisphereLight('#ffffff','#74828b',2.3));const light=new T.DirectionalLight('#fff6e9',3.3);light.position.set(center.x+span,center.y-span,center.z+span*2);scene.add(light);const fill=new T.DirectionalLight('#ddeaff',1.6);fill.position.set(center.x-span,center.y+span,center.z+span);scene.add(fill);
 const grid=new T.GridHelper(span*3,30,'#b7c8ce','#d7e0e3');grid.rotation.x=Math.PI/2;grid.position.set(center.x,center.y,bounds.min.z-.5);scene.add(grid);geometries.push(grid.geometry);materials.push(...(Array.isArray(grid.material)?grid.material:[grid.material]));
 renderer.setPixelRatio(Math.min(window.devicePixelRatio,2));renderer.outputColorSpace=T.SRGBColorSpace;container.appendChild(renderer.domElement);renderer.domElement.setAttribute('aria-label','OpenSCAD rendered cabinet. Drag to orbit, scroll to zoom, arrow keys to rotate.');renderer.domElement.tabIndex=0;
 const fit=()=>{const distance=span/(2*Math.tan(camera.fov*Math.PI/360))*1.5/Math.min(camera.aspect,1);camera.near=Math.max(.01,span/10000);camera.far=span*100;camera.position.copy(center).add(new T.Vector3(1,-1.7,1.1).normalize().multiplyScalar(distance));controls.target.copy(center);camera.updateProjectionMatrix();controls.update()};reset.current=fit;
 const resize=()=>{const width=container.clientWidth,height=container.clientHeight;if(!width||!height)return;renderer.setSize(width,height);camera.aspect=width/height;camera.updateProjectionMatrix()};resize();fit();const observer=new ResizeObserver(resize);observer.observe(container);
 const onKey=(event:KeyboardEvent)=>{if(!['ArrowLeft','ArrowRight','ArrowUp','ArrowDown'].includes(event.key))return;event.preventDefault();const offset=camera.position.clone().sub(controls.target);if(event.key==='ArrowLeft'||event.key==='ArrowRight')offset.applyAxisAngle(new T.Vector3(0,0,1),event.key==='ArrowLeft'?.1:-.1);else{const right=new T.Vector3().crossVectors(offset,camera.up).normalize();offset.applyAxisAngle(right,event.key==='ArrowUp'?.08:-.08)}camera.position.copy(controls.target).add(offset);controls.update()};renderer.domElement.addEventListener('keydown',onKey);
 let down:{x:number;y:number}|null=null;const pointerDown=(e:PointerEvent)=>{down={x:e.clientX,y:e.clientY}};const pointerUp=(e:PointerEvent)=>{if(!down||Math.hypot(e.clientX-down.x,e.clientY-down.y)>5){down=null;return}down=null;const rect=renderer.domElement.getBoundingClientRect(),ray=new T.Raycaster();ray.setFromCamera(new T.Vector2((e.clientX-rect.left)/rect.width*2-1,-(e.clientY-rect.top)/rect.height*2+1),camera);const hit=ray.intersectObject(cabinetMesh)[0];selection.current.onSelect?.(hit?partAtPoint(selection.current.parts,hit.point):null)};renderer.domElement.addEventListener('pointerdown',pointerDown);renderer.domElement.addEventListener('pointerup',pointerUp);
 const guide=new T.Box3Helper(new T.Box3(),0x159d91);scene.add(guide);geometries.push(guide.geometry);materials.push(guide.material as Material);
 let frame=0;const animate=()=>{const p=selection.current.selected;guide.visible=!!p;if(p)guide.box.set(new T.Vector3(p.x,p.y,p.z),new T.Vector3(p.x+p.w,p.y+p.d,p.z+p.h));frame=requestAnimationFrame(animate);controls.update();renderer.render(scene,camera)};animate();cleanup=()=>{cancelAnimationFrame(frame);observer.disconnect();controls.dispose();geometries.forEach(g=>g.dispose());materials.forEach(m=>m.dispose());renderer.dispose();renderer.domElement.remove();reset.current=()=>{}};
 })().catch(e=>{if(!disposed)setError(e.message)});return()=>{disposed=true;cleanup()};
 },[bytes,active]);
 return <div className='native-mesh'><div ref={host} className='mesh-canvas'/>{error&&<div className='native-empty'><Info/><p>{error}</p></div>}<button className='mesh-reset' onClick={()=>reset.current()}><RotateCcw size={16}/>Reset view</button><span className='mesh-hint'>Drag to orbit · scroll to zoom · arrow keys to rotate</span></div>
}

type Result={bytes:ArrayBuffer;key:string;seconds:number;family:number;mode:string;warnings:number};
export default function OpenSCADView({family,values,active,selected,parts,onSelect}:{family:number;values:Values;active:boolean;selected?:Part;parts:Part[];onSelect?:(p:Part|null)=>void}){
 const [mode,setMode]=useState('assembly'),[result,setResult]=useState<Result|null>(null),[running,setRunning]=useState(false),[stage,setStage]=useState(''),[error,setError]=useState(''),[logs,setLogs]=useState<string[]>([]),[elapsed,setElapsed]=useState(0);
 const worker=useRef<Worker|null>(null),controller=useRef<AbortController|null>(null),sequence=useRef(0),timeout=useRef<ReturnType<typeof setTimeout>|null>(null);
 const key=JSON.stringify({family,values,mode}),stale=!!result&&result.key!==key,errors=validate(values);
 const stop=()=>{sequence.current++;worker.current?.terminate();worker.current=null;controller.current?.abort();controller.current=null;if(timeout.current)clearTimeout(timeout.current);timeout.current=null};
 useEffect(()=>()=>stop(),[]);
 const supported=schemas[family].fields.find(f=>f.key==='output_mode')?.options??[];
 useEffect(()=>{if(!supported.includes(mode))setMode('assembly')},[family,mode]);
 // Keep the exact view current while it is visible: re-render shortly after edits settle.
 // A failed or cancelled render is not retried until the settings change again.
 const [auto,setAuto]=useState(true),attempted=useRef('');
 useEffect(()=>{
  if(!auto||!active||running||errors.length||(result&&!stale)||attempted.current===key)return;
  const t=setTimeout(()=>render(),result?900:150);
  return ()=>clearTimeout(t);
 },[auto,active,key,running,result,stale,errors.length]);
 useEffect(()=>{if(!running)return;setElapsed(0);const start=Date.now();const id=setInterval(()=>setElapsed(Math.floor((Date.now()-start)/1000)),1000);return()=>clearInterval(id)},[running]);
 async function render(){
  attempted.current=key;stop();const id=sequence.current;const snapshot={family,key,mode};controller.current=new AbortController();setRunning(true);setError('');setLogs([]);setStage('Preparing cabinet…');
 timeout.current=setTimeout(()=>{if(sequence.current!==id)return;stop();setRunning(false);setError('Rendering stopped after 3 minutes. Try carcass only, or reduce circle segments in Advanced.')},180000);
 try{const source=await configuredSource(family,values,controller.current.signal);if(sequence.current!==id)return;
 const job=new Worker(assetUrl('/openscad/render-worker.js'),{type:'module'});worker.current=job;
 job.onmessage=({data})=>{if(sequence.current!==id)return;
 if(data.type==='stage')setStage(data.stage);
 if(data.type==='log')setLogs(l=>[...l.slice(-149),data.line]);
 if(data.type==='result'){const bytes=data.output as ArrayBuffer;if(!(bytes instanceof ArrayBuffer)||bytes.byteLength<84){setError('OpenSCAD returned an empty model.')}else{setResult({bytes,key:snapshot.key,family:snapshot.family,mode:snapshot.mode,seconds:data.elapsed/1000,warnings:(data.logs??[]).filter((s:string)=>/^WARNING:/.test(s)).length})}stop();setRunning(false)}
 if(data.type==='error'){setError(data.error||'Rendering failed.');setLogs(data.logs??[]);stop();setRunning(false)}
 };
 job.onerror=()=>{if(sequence.current!==id)return;setError('Could not run OpenSCAD. Check your connection and try again.');stop();setRunning(false)};
 job.postMessage({filename:schemas[family].file,source,mode,sources:renderSources});
 }catch(e){if(sequence.current!==id)return;setError(e instanceof Error?e.message:'Rendering failed.');stop();setRunning(false)}
 }
 return <div className='native-render'><div className='native-toolbar'><Select value={mode} onValueChange={setMode}><SelectTrigger aria-label='OpenSCAD render contents' className='native-mode'><SelectValue/></SelectTrigger><SelectContent>{[['assembly','Full assembly'],['flat_3d','Flat parts · exact 3D'],['carcass_only','Carcass only'],['drawers_only','Drawers only']].filter(([id])=>supported.includes(id)).map(([id,label])=><SelectItem key={id} value={id}>{label}</SelectItem>)}</SelectContent></Select><span className='native-status' role='status'>{running?`${stage} ${elapsed}s`:error?'Render needs attention':stale?(auto?'Updating shortly…':'Settings changed · update render'):result?'Render current':'Ready to render'}</span><label className='auto-render'><input type='checkbox' checked={auto} onChange={e=>setAuto(e.target.checked)}/>Auto-update</label>{running?<button className='render-cancel' onClick={()=>{stop();setRunning(false);setError('Render cancelled. Your previous result is retained.')}}><Square size={14}/>Cancel</button>:<button className='primary' disabled={errors.length>0} onClick={render}><Play size={15}/>{result?'Update render':'Render cabinet'}</button>}</div>
 {result?<MeshView bytes={result.bytes} active={active} selected={!stale&&mode==='assembly'&&family<6?selected:undefined} parts={!stale&&mode==='assembly'&&family<6?parts:[]} onSelect={!stale&&mode==='assembly'&&family<6?onSelect:undefined}/>:<div className='native-empty'><span className='native-empty-icon'>{running?<LoaderCircle className='render-spinner' size={32}/>:<Box size={32}/>}</span><h2>{running?'Building your cabinet':'Render the actual cabinet geometry'}</h2><p>{running?'You can keep editing while OpenSCAD works.':'OpenSCAD uses the engine files, including joinery, holes, and structural details.'}</p>{!running&&<small>The engine downloads on first use. The Preview tab remains your instant schematic.</small>}</div>}
 {running&&result&&<div className='render-progress'><LoaderCircle className='render-spinner' size={17}/><span>Showing the previous result while rendering…</span></div>}
 {(error||errors.length>0)&&<div className='render-error' role='alert'><Info size={16}/><span>{error||errors.join(' ')}</span></div>}
 {selected&&!stale&&mode==='assembly'&&<p className='selection-note'>Selection guide: {selected.name}. Bounds and click selection are approximate; the OpenSCAD mesh remains the manufacturing geometry.</p>}<div className={'native-result-bar '+(stale?'is-stale':'')}>{result?<><span>{stale?<Info size={14}/>:<Check size={14}/>} {families[result.family].name} · {result.mode.replaceAll('_',' ')} · {result.seconds.toFixed(1)}s{result.warnings?` · ${result.warnings} warning(s)`:''}</span><small>{stale?'Previous settings':'OpenSCAD / Manifold'}</small></>:<span>OpenSCAD runs locally in your browser.</span>}</div>
 <details className='render-log'><summary>Render log {logs.length>0&&`(${logs.length})`}<a href={assetUrl('/openscad/NOTICE.txt')} target='_blank' rel='noreferrer'>Engine & license</a></summary><pre>{logs.length?logs.join('\n'):'Render a cabinet to see OpenSCAD messages here.'}</pre></details></div>
}
