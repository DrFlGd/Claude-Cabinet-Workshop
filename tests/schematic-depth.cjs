// Exercise the real schematic scene with Three.js geometry/camera and a renderer spy.
const fs=require('node:fs'),assert=require('node:assert/strict'),ts=require('typescript'),THREE=require('three');
function compile(path,deps={}){const m={exports:{}};const js=ts.transpileModule(fs.readFileSync(path,'utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,jsx:ts.JsxEmit.ReactJSX,target:ts.ScriptTarget.ES2022,esModuleInterop:true}}).outputText;new Function('require','module','exports',js)(n=>deps[n]??require(n),m,m.exports);return m.exports}
const cabinet=compile('lib/cabinet.ts',{'./schema.json':require('../lib/schema.json')});
async function sceneFor(parts,angle=-.56,tilt=.35){let scene,camera;const effects=[];const host={clientWidth:900,clientHeight:730,appendChild(){}};let refIndex=0;
 const react={useRef:v=>({current:refIndex++===0?host:v}),useState:v=>[v,()=>{}],useEffect:f=>effects.push(f)};
 class Renderer{constructor(){this.domElement={remove(){}}}setPixelRatio(){}setClearColor(){}setSize(){}setViewport(){}dispose(){}render(s,c){scene=s;camera=c;s.updateMatrixWorld(true);c.updateMatrixWorld(true)}}
 global.window={devicePixelRatio:1};global.ResizeObserver=class{observe(){}disconnect(){}};
 const component=compile('app/SchematicScene.tsx',{react,three:{...THREE,WebGLRenderer:Renderer}}).default;
 const scale=Math.min(520/(650+500*.65),490/(700+500*.4));component({parts,angle,tilt,scale,W:650,H:700,D:500});const cleanup=effects.map(f=>f());await new Promise(r=>setImmediate(r));assert(scene,'Scene rendered');return {scene,camera,scale,cleanup:()=>cleanup.forEach(f=>f?.())};}
(async()=>{const values=cabinet.defaults(0),parts=cabinet.geometry(values,false,false);
 for(const [angle,tilt] of [[-.56,.35],[-.9,.6],[-.4,1.2]]){
 const {scene,camera,scale,cleanup}=await sceneFor(parts,angle,tilt);const meshes=[];scene.traverse(o=>{if(o.isMesh)meshes.push(o);if(o.isLineSegments)assert(o.material.depthTest,'Hidden lines must respect depth')});
 for(const mesh of meshes)for(const m of mesh.material){assert(m.depthTest&&m.depthWrite&&!m.transparent,'Panels must occlude hidden faces')}
 const target=new THREE.Vector3(630,350,parts.find(p=>p.group==='shelf').z+9);const projected=target.clone().project(camera);const ray=new THREE.Raycaster();ray.setFromCamera(new THREE.Vector2(projected.x,projected.y),camera);const hits=ray.intersectObjects(meshes);assert.equal(hits[0].object.userData.partId,'SIDE-R');
 const underTop=new THREE.Vector3(325,250,699).project(camera);ray.setFromCamera(new THREE.Vector2(underTop.x,underTop.y),camera);assert.equal(ray.intersectObjects(meshes)[0].object.userData.partId,'WORKTOP');
 // SVG dimension positions must stay aligned with the orthographic mesh projection.
 for(const p of [new THREE.Vector3(0,-100,-115),new THREE.Vector3(750,500,700)]){const v=p.clone().sub(new THREE.Vector3(325,250,350)),a=v.x*Math.cos(angle)-v.y*Math.sin(angle),b=v.x*Math.sin(angle)+v.y*Math.cos(angle);const expected=[450+a*scale,350+(-b*Math.sin(tilt)-v.z*Math.cos(tilt))*scale];const ndc=p.clone().project(camera);assert(Math.abs((ndc.x+1)*450-expected[0])<1e-6);assert(Math.abs((1-ndc.y)*365-expected[1])<1e-6)}
 cleanup();}
 console.log('Side and top panels occlude interior shelves; faces/edges depth-tested; dimensions align at multiple orbit angles.');
})().catch(e=>{console.error(e);process.exit(1)});
