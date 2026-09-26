const fs=require('fs'),ts=require('typescript'),assert=require('assert/strict');const m={exports:{}};new Function('module','exports',ts.transpileModule(fs.readFileSync('lib/diagram-depth.ts','utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2022}}).outputText)(m,m.exports);const {depthOrderedFaces,projectPoint,viewDirection}=m.exports;
function part(id,x,y,z,w,d,h){return {id,part:{id,x,y,z,w,d,h}}}
function inside(p,polygon){let sign=0;for(let i=0;i<polygon.length;i++){const a=polygon[i],b=polygon[(i+1)%polygon.length],cross=(b[0]-a[0])*(p[1]-a[1])-(b[1]-a[1])*(p[0]-a[0]);if(Math.abs(cross)<1e-6)return false;const s=Math.sign(cross);if(sign&&s!==sign)return false;sign=s}return true}
const cases=[
 [part('SL',-80,0,0,12,400,120),part('SR',460,0,0,12,400,120),part('BOT',0,0,-80,380,400,6),part('FR',0,-70,0,380,12,120),part('FACE',0,-180,0,420,18,150),part('BK',0,470,0,380,12,120)],
 [part('low',0,0,-100,600,500,18),part('high',0,0,100,600,500,18),part('side',250,-50,-150,18,650,400)],
 [part('wide',-200,80,0,900,20,120),part('deep',100,-200,20,20,900,100)]
];let checked=0;
for(const parts of cases){const faces=depthOrderedFaces(parts),points=faces.flatMap(f=>f.points.map(projectPoint)),minX=Math.min(...points.map(p=>p[0])),maxX=Math.max(...points.map(p=>p[0])),minY=Math.min(...points.map(p=>p[1])),maxY=Math.max(...points.map(p=>p[1]));for(let x=minX+.371;x<maxX;x+=7.37)for(let y=minY+.529;y<maxY;y+=6.13){const hits=faces.filter(f=>inside([x,y],f.points.map(projectPoint)));if(!hits.length)continue;const base=[x/.82,0,.13*x/.82-y];const depth=f=>(f.offset-base[f.axis])/viewDirection[f.axis];assert(Math.abs(depth(hits.at(-1))-Math.max(...hits.map(depth)))<1e-5,'Painter order must agree with nearest surface');checked++}}
assert(checked>5000);console.log(checked+' projected points agree with exact face depths, including drawer bottoms and crossing panels.');
