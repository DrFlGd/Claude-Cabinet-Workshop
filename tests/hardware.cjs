// Hardware model choice, generic settings and hole positions (lib/hardware.ts).
const fs=require('fs'),assert=require('assert/strict'),ts=require('typescript'),path=require('path');
const load=file=>{const m={exports:{}};new Function('require','module','exports',ts.transpileModule(fs.readFileSync(file,'utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2022,resolveJsonModule:true,esModuleInterop:true}}).outputText)(n=>require(path.resolve('lib',n)),m,m.exports);return m.exports};
const H=load('lib/hardware.ts'),schema=require('../lib/schema.json');
const base=f=>({...Object.fromEntries(schema[f].fields.map(x=>[x.key,x.value])),_family:f});

// Catalog: selectable models carry a settings patch; generic templates and reference-only models are kept apart.
const {models,templates,reference}=H.catalogFor(1,'drawer_slide');
assert(models.length>50&&models.every(p=>p.apply&&p.manufacturer!=='Generic'));
assert(templates.length===2&&templates.every(p=>p.manufacturer==='Generic'));
assert(reference.length>0&&reference.every(p=>!p.apply));
assert(H.catalogFor(1,'hinge').models.every(p=>p.category==='hinge'));
assert(H.catalogFor(6,'drawer_slide').models.every(p=>p.targets.includes('equipment_stand')));

// Choosing a model locks it while its settings match; editing one makes the design generic, based on it.
const accuride=models.find(p=>p.id==='accuride_3832e_450');
let v={...base(1),...H.chooseModel('drawer_slide',accuride)};
assert.equal(H.selection(v,1,'drawer_slide').mode,'catalog');
v={...v,metal_slide_length:500};
let s=H.selection(v,1,'drawer_slide');assert.equal(s.mode,'generic');assert.equal(s.basedOn.id,accuride.id);assert.deepEqual(s.changed,['metal_slide_length']);
v={...v,metal_slide_length:450,...H.chooseGeneric('drawer_slide',accuride)};
s=H.selection(v,1,'drawer_slide');assert.equal(s.mode,'generic');assert.equal(s.basedOn.id,accuride.id);
// Designs saved before the choice existed are matched against the catalog; a non-matching one is generic.
assert.equal(H.selection({...base(1),...accuride.apply},1,'drawer_slide').mode,'catalog');
assert.equal(H.selection(base(1),1,'drawer_slide').mode,'generic');

// Panel-owned keys cover slides, runners and hinges but not handles or casters.
for(const k of ['drawer_mount','metal_slide_length','metal_slide_cabinet_hole_diameter','wood_rail_height','custom_wood_rail_depth','hinge_door_fixing_hole_offset','runner_width','metal_slide_hole_diameter'])assert(H.HARDWARE_PANEL_KEYS(k),k);
for(const k of ['handle_hole_diameter','caster_height','single_door_hinge_side'])assert(!H.HARDWARE_PANEL_KEYS(k),k);

// Hole patterns, as the engine computes them.
assert.deepEqual(H.slideHoles({metal_slide_hole_pattern_mode:'legacy_spacing',metal_slide_first_hole_from_front:37,metal_slide_hole_spacing:96,metal_slide_hole_count:4},'cabinet'),[37,133,229,325]);
const listed={metal_slide_hole_pattern_mode:'explicit_array',metal_slide_cabinet_holes_x:[10,20,30,40,50],metal_slide_drawer_holes_x:[5,15]};
assert.deepEqual(H.slideHoles({...listed,hardware_drilling_mode:'recommended'},'cabinet'),[10,30,50]);
assert.deepEqual(H.slideHoles({...listed,hardware_drilling_mode:'minimum'},'cabinet'),[10,50]);
assert.deepEqual(H.slideHoles({...listed,hardware_drilling_mode:'all'},'cabinet'),[10,20,30,40,50]);
assert.deepEqual(H.slideHoles(listed,'drawer'),[5,15]);
const slide={include_metal_slide_holes:true,metal_slide_hole_pattern_mode:'legacy_spacing',metal_slide_first_hole_from_front:37,metal_slide_hole_spacing:96,metal_slide_hole_count:5,metal_slide_front_setback:3,metal_slide_length:450,metal_slide_hole_rear_margin:20,metal_slide_drawer_hole_z_from_drawer_bottom:22.5,metal_slide_drawer_hole_diameter:5};
assert.deepEqual(H.drawerSideHoles(slide,500).map(h=>[h.y,h.drilled]),[[40,true],[136,true],[232,true],[328,true],[424,true]]);
assert.deepEqual(H.drawerSideHoles(slide,400).map(h=>h.drilled),[true,true,true,true,false]);
assert.deepEqual(H.drawerSideHoles({...slide,include_metal_slide_holes:false},500),[]);

// Hinges: heights from the door bottom, cups from the hinge edge, fixing holes offset toward the door center.
assert.deepEqual(H.hingeHeights({hinge_count:3,hinge_end_offset:100},600),[100,300,500]);
assert.deepEqual(H.hingeHeights({hinge_count:1,hinge_end_offset:100},600),[300]);
const hinge={hinge_style:'euro_35mm',hinge_count:2,hinge_end_offset:100,hinge_cup_diameter:35,hinge_cup_center_from_door_edge:22.5,hinge_door_fixing_enabled:true,hinge_door_fixing_hole_spacing:45,hinge_door_fixing_hole_diameter:3,hinge_door_fixing_hole_offset:9.5};
let d=H.doorDrilling(hinge,400,700,'left');
assert.deepEqual(d.cups.map(c=>[c.x,c.z]),[[22.5,100],[22.5,600]]);
assert.deepEqual(d.fixing.map(c=>[c.x,c.z]),[[32,77.5],[32,122.5],[32,577.5],[32,622.5]]);
d=H.doorDrilling(hinge,400,700,'right');assert.deepEqual([d.cups[0].x,d.fixing[0].x],[377.5,368]);
assert.equal(H.doorDrilling({...hinge,hinge_style:'screw_holes'},400,700,'left').cups.length,0);
assert.equal(H.doorDrilling({...hinge,hinge_style:'none'},400,700,'left').fixing.length,0);

// Engine feature records: circles on side panels, grouped one row per slide; equipment-stand format too.
const recs=['FEATURE|ID=metal_slide.left.1.37.5|PART=CS-L|KIND=through_hole|INTERFACE=hardware.slide|X0=0|X1=18|Y0=38|Y1=43|Z0=759|Z1=764|SHAPE=circle|CY=40.5|CZ=761.7|R=2.5|OP=cut_layout|SOURCE=metal_slide',
 'FEATURE|ID=metal_slide.left.1.133|PART=CS-L|KIND=through_hole|INTERFACE=hardware.slide|X0=0|X1=18|Y0=0|Y1=0|Z0=0|Z1=0|SHAPE=circle|CY=136|CZ=761.7|R=2.5|OP=cut_layout|SOURCE=metal_slide',
 'FEATURE|ID=metal_slide.left.B2.1.37|PART=CS-L|KIND=through_hole|INTERFACE=hardware.slide|X0=0|X1=18|Y0=0|Y1=0|Z0=0|Z1=0|SHAPE=circle|CY=40|CZ=300|R=2.5|OP=cut_layout|SOURCE=metal_slide',
 'FEATURE|ID=hinge_plate.left.1.1|PART=CS-L|KIND=through_hole|INTERFACE=hardware.hinge|X0=0|X1=18|Y0=0|Y1=0|Z0=0|Z1=0|SHAPE=circle|CY=37|CZ=186|R=2.5|OP=cut_layout|SOURCE=hinge_plate',
 'FEATURE|ID=hinge_plate.left.1.2|PART=CS-L|KIND=through_hole|INTERFACE=hardware.hinge|X0=0|X1=18|Y0=0|Y1=0|Z0=0|Z1=0|SHAPE=circle|CY=37|CZ=218|R=2.5|OP=cut_layout|SOURCE=hinge_plate',
 'FEATURE|ID=joint.dado|PART=CS-L|KIND=dado_pocket|SHAPE=rect|CY=|CZ=|R=0',
 'FEATURE|ID=slide_hole.1.0.37|OWNER=SIDE_L|OP=pocket_slide_holes|X=40|Y=120|D=5|DEPTH=8'];
const f=H.sideFeatures(recs);assert.equal(f.length,6);
assert.deepEqual(H.slideRows(f,'CS-L').map(r=>[r.id,r.holes.length]),[['metal_slide.left.1',2],['metal_slide.left.B2.1',1],['slide_hole.1',1]]);
const plates=H.cabinetHingePlates(f,'CS-L');assert.deepEqual(plates.map(p=>[p.id,p.y,p.z]),[['hinge_plate.left.1',37,202]]);
assert.equal(H.platesForDoor(plates,{id:'D',x:0,z:102,w:300,h:470,hinge:'left'}).length,1);
assert.equal(H.platesForDoor(plates,{id:'D',x:0,z:400,w:300,h:470,hinge:'left'}).length,0);

// Drawers against a side: the column nearest it.
const drawers=[{id:'A',x:20,w:300,bottom:0,box:{}},{id:'B',x:330,w:300,bottom:0,box:{}},{id:'C',x:20,w:300,bottom:200,box:{}}];
assert.deepEqual(H.drawersOnSide(drawers,'CS-L').map(d=>d.id),['A','C']);
assert.deepEqual(H.drawersOnSide(drawers,'CS-R').map(d=>d.id),['B']);
console.log('Hardware: catalog choice, generic edits, panel keys, slide and hinge hole positions, feature ledger parsing passed.');
