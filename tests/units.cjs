const fs=require('node:fs'),assert=require('node:assert/strict'),ts=require('typescript');
function compile(path,deps={}){const m={exports:{}};new Function('require','module','exports',ts.transpileModule(fs.readFileSync(path,'utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,jsx:ts.JsxEmit.ReactJSX,target:ts.ScriptTarget.ES2022,esModuleInterop:true}}).outputText)(n=>deps[n]??require(n),m,m.exports);return m.exports}
const u=compile('lib/units.ts');assert.equal(u.toMillimeters(24,'in'),609.5999999999999);assert.equal(u.formatDimension(609.6,'in'),'24.00');assert.equal(u.formatDimension(596.90000000001,'mm'),'596.90');
const fields=require('../lib/schema.json').flatMap(s=>s.fields);
for(const key of ['mixed_bay_width_weights','drawer_graduated_step','target_drawer_bank','target_module_count_x','circle_segments'])assert(!u.isLengthField(fields.find(f=>f.key===key)),key);
for(const key of ['cabinet_width','target_module_pitch_x','wood_rail_depth','calibration_fit_offsets','face_frame_custom_mid_rail_z'])assert(u.isLengthField(fields.find(f=>f.key===key)),key);
assert.deepEqual(u.restoreLengths([.2,.35],[.01,.01],[.01,.02],'in'),[.2,.508]);
let cursor=0,slots=[],effects=[],changes=[];
const react={useState(initial){const i=cursor++;if(!(i in slots))slots[i]=typeof initial==='function'?initial():initial;return [slots[i],v=>slots[i]=v]},useRef(initial){const i=cursor++;return slots[i]??(slots[i]={current:initial})},useEffect(f,deps){const i=cursor++;if(!slots[i]||deps.some((x,j)=>x!==slots[i][j])){slots[i]=deps;effects.push(f)}}};
const Input=compile('app/DimensionInput.tsx',{react,'@/lib/units':u}).default;
let props={value:19.05,units:'in',id:'test',onChange:v=>changes.push(v)};
function render(){cursor=0;let out=Input(props);if(effects.length){effects.splice(0).forEach(f=>f());cursor=0;out=Input(props)}return out.props.children[0].props}
assert.equal(render().value,'0.75');render().onBlur();assert.deepEqual(changes,[]);
props={...props,value:.2};assert.equal(render().value,'0.0079');render().onBlur();assert.deepEqual(changes,[]);
for(let i=0;i<10;i++){props={...props,units:i%2?'in':'mm'};render().onBlur()}assert.deepEqual(changes,[]);
render().onChange({target:{value:'0.125'}});assert.equal(render().value,'0.125');render().onBlur();assert.equal(changes[0],3.175);
props={...props,value:null,automatic:true};assert.equal(render().value,'');render().onChange({target:{value:'1'}});render().onBlur();assert.equal(changes.at(-1),25.4);
// Shop-friendly entry and display: fractions, explicit units and feet.
const near=(a,b)=>assert(Math.abs(a-b)<1e-9,a+' != '+b);
near(u.parseDimension('23 1/2','in'),596.9);near(u.parseDimension('23-1/2"','mm'),596.9);near(u.parseDimension('3/4','in'),19.05);
near(u.parseDimension('600','mm'),600);near(u.parseDimension('600 mm','in'),600);near(u.parseDimension('60cm','in'),600);
near(u.parseDimension("2' 3 1/2\"",'mm'),698.5);near(u.parseDimension('2ft','mm'),609.6);near(u.parseDimension('-0.2','mm'),-0.2);
near(u.parseDimension('.5 in','mm'),12.7);for(const bad of ['','abc','1/0','2 3','1//2'])assert(Number.isNaN(u.parseDimension(bad,'in')),bad);
assert.equal(u.formatFraction(596.9),'23 1/2');assert.equal(u.formatFraction(19.05),'3/4');assert.equal(u.formatFraction(600),'23 5/8');assert.equal(u.formatFraction(0.2),'0');
assert.equal(u.formatInput(19.05,'in'),'0.75');assert.equal(u.formatInput(650,'mm'),'650');assert.equal(u.formatInput(0.2,'in'),'0.0079');
render().onChange({target:{value:'abc'}});render().onBlur();assert.equal(changes.length,2);
console.log('Fraction/feet/unit-suffix parsing and shop formatting passed.');
console.log('Metric/inch conversion, trimmed input display, untouched precision, array precision, dimensional classification and input editing passed.');
