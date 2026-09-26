// Regression: React may evaluate functional updates after pointer-up clears the drag ref.
const fs=require('node:fs');
const assert=require('node:assert/strict');
const ts=require('typescript');
const source=fs.readFileSync('app/CabinetView.tsx','utf8');
const compiled=ts.transpileModule(source,{compilerOptions:{module:ts.ModuleKind.CommonJS,jsx:ts.JsxEmit.ReactJSX,target:ts.ScriptTarget.ES2022,esModuleInterop:true}}).outputText;
function mount(){const state=[],queued=[];const react={useState(value){const i=state.length;state.push(value);return [value,next=>queued.push(()=>state[i]=typeof next==='function'?next(state[i]):next)]},useRef:current=>({current}),useMemo:f=>f()};const mod={exports:{}};new Function('require','module','exports',compiled)(name=>name==='react'?react:name==='@/lib/cabinet'?{geometry:()=>[]}:name==='@/lib/units'?{formatDimension:n=>n.toFixed(2)}:name==='lucide-react'?{}:name==='./SchematicScene'?{default:()=>null}:require(name),mod,mod.exports);const view=mod.exports.default({values:{},interior:false,exploded:false,dimensions:false});return {events:view.props.children[0].props,state,flush(){while(queued.length)queued.shift()()}}}
const m=mount();const event=(x,y,id=1)=>({clientX:x,clientY:y,pointerId:id,button:0,isPrimary:true,currentTarget:{setPointerCapture(){}}});
m.events.onPointerDown(event(100,100));m.events.onPointerMove(event(125,150));m.events.onPointerUp(event(125,150));m.flush();assert(Math.abs(m.state[0]-(-.36))<1e-10);assert(Math.abs(m.state[1]-.65)<1e-10);
for(const [end,limit] of [[100000,1.2],[-100000,-.15]]){const m=mount();m.events.onPointerDown(event(100,100));for(let i=1;i<=100;i++)m.events.onPointerMove(event(100,100+(end-100)*i/100));m.events.onPointerCancel(event(100,end));m.flush();assert.equal(m.state[1],limit);assert(m.state.every(Number.isFinite))}
console.log('Queued pointer updates survive release/cancel and both vertical limits.');
