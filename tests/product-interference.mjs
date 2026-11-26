// Physical fit check of the products (lib/products, public/products): every part is
// rendered on its own in assembly position with the bundled OpenSCAD WASM, and every pair
// of parts whose extents meet is intersected. Correctly fitted parts only touch (zero
// volume); any shared volume means two parts would occupy the same space. Casters are a
// part of their own, so the bottom panel and its fasteners are checked against them.
//
// Jobs: every starter of every product, hand-picked cases that exercise each joinery,
// tower and profile path, and (--random N or --all) a seeded random sweep that patches
// starters with choices, counts and sizes the product's own editor check accepts.
//
//   node tests/product-interference.mjs              starters and hand-picked cases
//   node tests/product-interference.mjs --all        plus 24 random designs
//   SHARD=1/6 node tests/product-interference.mjs --all   one sixth of that job list
//   CASES='[["media_cart","stepped_bins",{"rows":1}]]' node ...   ad-hoc configurations
import fs from 'node:fs';
import {loadProducts} from './product-load.mjs';
const root=new URL('../',import.meta.url);
const P=loadProducts();
globalThis.self??={location:{href:'http://test/openscad/x.js'}};
globalThis.fetch=async url=>{const p=new URL(String(url),'http://test').pathname;try{return new Response(fs.readFileSync(new URL('public'+p,root)),{headers:{'Content-Type':p.endsWith('.wasm')?'application/wasm':'text/plain'}})}catch{return new Response('',{status:404})}};
const {default:OpenSCAD}=await import(new URL('public/openscad/openscad.js',root).href);
async function scad(files,main,args,out){
 const logs=[];const e=await OpenSCAD({noInitialRun:true,locateFile:p=>'http://test/openscad/'+p,print:l=>logs.push(String(l)),printErr:l=>logs.push(String(l))});
 for(const [n,d] of Object.entries(files))e.FS.writeFile('/'+n,d);
 try{e.callMain(['/'+main,'--backend=Manifold',...args])}catch{}
 let data=null;try{data=e.FS.readFile(out)}catch{}
 return {logs,data};
}
function volume(buf){
 if(!buf||buf.length<84)return 0;const dv=new DataView(buf.buffer,buf.byteOffset,buf.byteLength),n=dv.getUint32(80,true);let v=0;
 for(let i=0;i<n;i++){const o=84+i*50+12,p=[];for(let k=0;k<9;k++)p.push(dv.getFloat32(o+k*4,true));v+=(p[0]*(p[4]*p[8]-p[5]*p[7])-p[1]*(p[3]*p[8]-p[5]*p[6])+p[2]*(p[3]*p[7]-p[4]*p[6]))/6}
 return Math.abs(v);
}
function extent(buf){
 const dv=new DataView(buf.buffer,buf.byteOffset,buf.byteLength),n=dv.getUint32(80,true),lo=[Infinity,Infinity,Infinity],hi=[-Infinity,-Infinity,-Infinity];
 for(let i=0;i<n;i++){const o=84+i*50+12;for(let k=0;k<9;k++){const v=dv.getFloat32(o+k*4,true),a=k%3;if(v<lo[a])lo[a]=v;if(v>hi[a])hi[a]=v}}
 return {lo,hi};
}
const meet=(a,b)=>[0,1,2].every(k=>a.lo[k]<b.hi[k]-0.01&&b.lo[k]<a.hi[k]-0.01);
const hook=(s,k,v)=>s.replace(new RegExp('^('+k+'\\s*=\\s*)[^;]+;','m'),(_m,p)=>p+JSON.stringify(v)+';');

async function overlaps(p,values){
 const source=P.productSource(p,values);
 const bom=await scad({'m.scad':hook(source,'output_mode','bom')},'m.scad',['-o','/o.echo'],'/o.echo');
 const text=bom.logs.join('\n')+'\n'+(bom.data?new TextDecoder().decode(bom.data):'');
 const errors=[...text.matchAll(/CHECK\|ERROR\|[^"\n]*/g)].map(m=>m[0]);
 if(errors.length)return {errors};
 const ids=[...new Set([...text.matchAll(/BOM\|([^|]+)\|/g)].map(m=>m[1]))],stl={},ext={};
 for(const id of [...ids,'CASTERS']){
  const r=await scad({'m.scad':hook(hook(source,'output_mode','assembly'),'render_part',id)},'m.scad',['--export-format=binstl','-o','/o.stl'],'/o.stl');
  const bad=r.logs.filter(l=>/^ERROR|^WARNING: (undefined operation|Ignoring unknown variable)/.test(l));
  if(bad.length)return {errors:bad.map(l=>id+': '+l)};
  if(r.data&&r.data.length>84){stl[id]=r.data;ext[id]=extent(r.data)}
  else if(id!=='CASTERS')return {errors:[id+': renders empty']};
 }
 const names=Object.keys(stl),bad={};let pairs=0;
 for(let i=0;i<names.length;i++)for(let j=i+1;j<names.length;j++){
  if(!meet(ext[names[i]],ext[names[j]]))continue;
  pairs++;
  const r=await scad({'a.stl':stl[names[i]],'b.stl':stl[names[j]],'i.scad':'intersection(){import("/a.stl");import("/b.stl");}'},'i.scad',['--export-format=binstl','-o','/o.stl'],'/o.stl');
  const v=volume(r.data);if(v>1)bad[names[i]+'×'+names[j]]=+v.toFixed(1);
 }
 return {errors:[],bad,parts:names.length,pairs};
}

// Hand-picked cases: each joinery for crosspieces and panels, both towers with every
// panel joinery, one-row grids (fins locked only by the front and rear laps), stepped
// profiles with and without the flush back, thin fins and imperial stock.
const CASES=[
 ['media_cart','sloped_bins',{joinery_style:'dado',panel_joinery:'dado',shape:'custom',custom_tower:'Both'}],
 ['media_cart','sloped_bins',{joinery_style:'screw',panel_joinery:'screw',shape:'custom',custom_tower:'Left'}],
 ['media_cart','sloped_bins',{joinery_style:'tab_slot',panel_joinery:'dado',shape:'custom',custom_tower:'Right'}],
 ['media_cart','sloped_bins',{joinery_style:'butt',panel_joinery:'butt',show_casters:false}],
 ['media_cart','stepped_bins',{rows:1,columns:4,back_flush_with_top_entrance:true}],
 ['media_cart','stepped_bins',{fin_stock:'custom_mm',custom_fin_thickness:12,panel_joinery:'dado'}],
 ['media_cart','shelf_cart',{carcass_stock:'1/2_nominal',slot_corner_relief:'t_bone',joinery_style:'dado'}],
 ['media_cart','compact_sorter',{joinery_style:'dado',dado_depth:4}],
];
function rng(seed){let a=seed>>>0;return()=>{a=(a+0x6D2B79F5)>>>0;let t=a;t=Math.imul(t^(t>>>15),t|1);t^=t+Math.imul(t^(t>>>7),t|61);return((t^(t>>>14))>>>0)/4294967296}}
const CHOICES=['shape','bin_profile','custom_tower','joinery_style','panel_joinery','carcass_stock','fin_stock','slot_corner_relief'];
const TOGGLES=['custom_lower_cubbies','back_flush_with_top_entrance','show_casters'];
const COUNTS={rows:[1,5],columns:[1,5],cubby_columns:[1,4],tower_openings:[2,7]};
const SIZES={width:[500,1400],depth:[350,800],rear_height:[600,1300],front_height:[150,450],cubby_height:[90,220],tower_width:[120,280]};
function randomDesign(random,p){
 const pick=list=>list[Math.floor(random()*list.length)],param=k=>p.params.find(x=>x.key===k);
 const starter=pick(p.starters).id,patch={},n=2+Math.floor(random()*5);
 for(let i=0;i<n;i++){
  const kind=random();
  if(kind<0.45){const k=pick(CHOICES);patch[k]=pick(param(k).options)}
  else if(kind<0.6){patch[pick(TOGGLES)]=random()<0.5}
  else if(kind<0.8){const k=pick(Object.keys(COUNTS)),[a,b]=COUNTS[k];patch[k]=a+Math.floor(random()*(b-a+1))}
  else{const k=pick(Object.keys(SIZES)),[a,b]=SIZES[k];patch[k]=Math.round(a+random()*(b-a))}
 }
 return [starter,patch];
}
const argv=process.argv.slice(2),flag=n=>argv.includes(n),after=n=>{const i=argv.indexOf(n);return i>=0?argv[i+1]:undefined};
const only=process.env.CASES?JSON.parse(process.env.CASES):null;
let jobs=only?only.map(([product,starter,patch])=>({label:'case',product,starter,patch:patch??{}})):[];
if(!only){
 for(const p of P.products)for(const s of p.starters)jobs.push({label:'starter',product:p.id,starter:s.id,patch:{}});
 for(const [product,starter,patch] of CASES)jobs.push({label:'case',product,starter,patch});
 const count=flag("--all")?24:Number(after('--random')??0);
 if(count>0){const random=rng(Number(process.env.SEED??20261126));for(let k=0;k<count;k++)for(const p of P.products){const [starter,patch]=randomDesign(random,p);jobs.push({label:'random',product:p.id,starter,patch,optional:true})}}
}
if(process.env.SHARD){const [i,n]=process.env.SHARD.split('/').map(Number);jobs=jobs.filter((_,k)=>k%n===i-1)}

const started=Date.now();let failures=0,checked=0,skipped=0,pairs=0;
for(const j of jobs){
 const p=P.productById(j.product),name=`${j.product}:${j.starter} ${JSON.stringify(j.patch)}`;
 let values={...P.productStarterValues(p,j.starter),...j.patch};
 for(const [k,v] of Object.entries(j.patch))values={...values,...(p.linked?.(k,v,values)??{})};
 // Random designs the editor would refuse are skipped, as are those the engine rejects.
 const quick=p.validate(values);
 if(j.optional&&quick.length){skipped++;console.log(`skip ${name}: ${quick[0]}`);continue}
 const t0=Date.now();
 try{
  const r=await overlaps(p,values);
  if(r.errors.length){
   if(j.optional){skipped++;console.log(`skip ${name}: engine rejects it (${r.errors.slice(0,2).join('; ')})`);continue}
   failures++;console.log(`FAIL ${name}: ${r.errors.slice(0,3).join('; ')}`);continue;
  }
  checked++;pairs+=r.pairs;
  if(Object.keys(r.bad).length){failures++;console.log(`FAIL ${name}: overlapping parts ${JSON.stringify(r.bad)} mm³`)}
  else console.log(`ok ${name}: ${r.parts} parts, ${r.pairs} pairs (${Math.round((Date.now()-t0)/1000)} s)`);
 }catch(e){failures++;console.log(`FAIL ${name}: ${e.message}`)}
}
const seconds=Math.round((Date.now()-started)/1000);
if(failures){console.log(`Product interference: ${failures} of ${checked+failures} configurations have overlapping parts or failed to render (${seconds} s).`);process.exitCode=1}
else console.log(`Product interference: ${checked} configurations render with no overlapping parts (${pairs} part pairs intersected${skipped?`, ${skipped} random designs skipped as rejected`:''}; ${seconds} s).`);
