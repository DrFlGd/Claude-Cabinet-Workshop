// Unit checks for lib/nesting.ts: grouping, spacing, margins, rotation, oversize parts,
// and the re-mapping of an engine layout onto sheets.
const fs=require('node:fs'),assert=require('node:assert/strict'),ts=require('typescript');
function compile(path){const m={exports:{}};new Function('require','module','exports',ts.transpileModule(fs.readFileSync(path,'utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2022}}).outputText)(require,m,m.exports);return m.exports}
const N=compile('lib/nesting.ts');

const part=(id,material,t,w,h)=>({id,qty:1,category:'x',material,thickness:t,w,h});
const place=(id,x,y,w,h)=>({id,x,y,w,h});
const o={sheetW:1000,sheetH:500,margin:10,gap:5,rotate:'never'};

// 1. Grouping by material and thickness; parts sorted by area; nothing closer than the gap.
const parts=[part('A','CARCASS',18,400,300),part('B','CARCASS',18,400,300),part('C','BACK',6,900,400),part('D','CARCASS',12,100,100),part('E','CARCASS',18,560,170)];
const places=[place('A',0,0,400,300),place('B',420,0,400,300),place('C',0,320,900,400),place('D',0,740,100,100),place('E',0,860,560,170)];
const r=N.nest(parts,places,o);
assert.deepEqual(N.checkNesting(r,parts),[]);
assert.equal(r.sheets.length,3);
assert.deepEqual(r.sheets.map(s=>s.material+' '+s.thickness+' '+s.placements.length),['BACK 6 1','CARCASS 12 1','CARCASS 18 3']);
const s18=r.sheets[2];assert.equal(s18.placements[0].id,'A');assert.equal(s18.placements[0].x,10);assert.equal(s18.placements[0].y,10);
assert.equal(s18.placements[1].x,415); // A's width plus the 5 mm gap
assert.equal(N.nestingSummary(r),'3 sheets: 1 × BACK 6 mm, 1 × CARCASS 12 mm, 1 × CARCASS 18 mm');

// 2. A part that only fits rotated is placed when rotation is allowed and reported otherwise.
const tall=[part('T','CARCASS',18,300,900)],tallPlace=[place('T',0,0,300,900)];
const no=N.nest(tall,tallPlace,o);assert.equal(no.sheets.length,0);assert.equal(no.unplaced.length,1);assert.match(no.unplaced[0].reason,/rotation off/);
assert.equal(N.checkNesting(no,tall).length,1);
const yes=N.nest(tall,tallPlace,{...o,rotate:'free'});assert.equal(yes.unplaced.length,0);assert.equal(yes.sheets[0].placements[0].rot,90);assert.equal(yes.sheets[0].placements[0].w,900);assert.equal(yes.sheets[0].placements[0].h,300);
assert.deepEqual(N.checkNesting(yes,tall),[]);
const need=N.nest(tall,tallPlace,{...o,rotate:'needed'});assert.equal(need.unplaced.length,0);assert.equal(need.sheets[0].placements[0].rot,90);
const fits=N.nest([part('F','CARCASS',18,300,200)],[place('F',0,0,300,200)],{...o,rotate:'needed'});assert.equal(fits.sheets[0].placements[0].rot,0); // drawn orientation kept when it fits

// 3. Free rectangles never overlap a placed part: many mixed sizes stay apart by the gap.
const many=[],manyPlaces=[];let y=0;
for(let i=0;i<40;i++){const w=60+(i*37)%300,h=40+(i*53)%200;many.push(part('P'+i,'CARCASS',18,w,h));manyPlaces.push(place('P'+i,0,y,w,h));y+=h+5}
for(const rotate of ['never','needed','free']){const m=N.nest(many,manyPlaces,{...o,rotate});assert.deepEqual(N.checkNesting(m,many),[],'rotate '+rotate);assert.equal(m.unplaced.length,0)}

// 4. Re-mapping: an engine-style layout (y negated, one path, registration frame) lands on the
// sheet with the frame dropped, holes travelling with their part, and rotation applied.
const strip=`<svg viewBox="-20 -1060 940 1080" xmlns="http://www.w3.org/2000/svg"><path d="
M 920,-1059.9 L -20,-1059.9 L -20,20 L 920,20 z
M -19.8,-1059.7 L 919.8,-1059.7 L 919.8,19.8 L -19.8,19.8 z
M 400,-300 L 0,-300 L 0,0 L 400,0 z
M 50,-60 L 40,-60 L 40,-50 L 50,-50 z
M 820,-300 L 420,-300 L 420,0 L 820,0 z
"/></svg>`;
const two=[part('A','CARCASS',18,400,300),part('B','CARCASS',18,400,300)],twoPlaces=[place('A',0,0,400,300),place('B',420,0,400,300)];
const n2=N.nest(two,twoPlaces,{...o,rotate:'free'});
const mapped=N.sheetPolygons(strip,n2.sheets[0]);
assert.equal(mapped.length,2);assert.equal(mapped[0].polys.length,2);assert.equal(mapped[1].polys.length,1);
assert.deepEqual(N.checkNesting(n2,two,strip),[]);
const svg=N.sheetSvg(strip,n2.sheets[0],'cut_layout');
assert.match(svg,/viewBox="0 -500 1000 500"/);assert.match(svg,/id="A"/);assert.match(svg,/id="B"/);assert.match(svg,/id="stock-frame"/);
const hole=mapped[0].polys[1];const a=n2.sheets[0].placements[0];
// unrotated: the hole keeps its offset; rotated 90°: (rx,ry) -> (h-ry, rx)
assert.deepEqual(hole.map(([x,y])=>[x-a.x,y-a.y]).sort(),(a.rot?[[240,40],[240,50],[250,40],[250,50]]:[[40,50],[40,60],[50,50],[50,60]]).sort());
const dxf=N.sheetDxf(strip,n2.sheets[0],'cut_layout');
assert.equal((dxf.match(/LWPOLYLINE/g)||[]).length,4);assert.match(dxf,/\r\n8\r\nCUT-LAYOUT\r\n/);assert.match(dxf,/\r\n8\r\nSTOCK\r\n/);

// 5. Options come from the design's settings; the spacing covers gap, kerf and cutter.
const opt=N.nestOptions({stock_width:1220,stock_height:610,layout_gap:8,kerf:0.2,cnc_tool_diameter:12.7});
assert.deepEqual(opt,{sheetW:1220,sheetH:610,margin:8,gap:12.7,rotate:'needed'});
assert.equal(N.nestOptions({}).sheetW,2440);
console.log('Nesting: grouping, spacing, margins, rotation, oversize parts, re-mapped layouts, SVG and DXF passed.');
