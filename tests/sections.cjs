const fs=require('fs'),assert=require('assert/strict'),ts=require('typescript'),cp=require('child_process'),path=require('path');
function load(name,deps={}){const m={exports:{}};new Function('require','module','exports',ts.transpileModule(fs.readFileSync('lib/'+name+'.ts','utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2022,esModuleInterop:true}}).outputText)(n=>deps[n],m,m.exports);return m.exports}
const s=load('sections'),c=load('cabinet',{'./sections':s,'./schema.json':require('../lib/schema.json'),'./engine-sources.json':require('../lib/engine-sources.json')}),p=load('projects',{'./cabinet':c,'./sections':s});
const example=require('../examples/photo-section-cabinet.cabinet.json'),design=p.parseDesign(example),v=design.values,a=v.section_nodes;
assert.deepEqual(a,s.photoSections());assert.deepEqual(c.validate(v),[]);assert.deepEqual(p.parseDesign(JSON.parse(JSON.stringify(design))).values.section_nodes,a);
for(const bad of [null,[],[s.leaf(),null],[s.leaf(),{}]])assert(s.treeErrors(bad).length);
const bad=s.photoSections();bad[3][0]=3;assert(s.treeErrors(bad).length);assert.throws(()=>p.parseDesign({...example,values:{...example.values,section_nodes:bad}}));
assert.deepEqual([...s.selectedSectionIds(a,0)],[0,1,2,3,4,5,6,7]);
assert.deepEqual([...s.selectedSectionIds(a,1)],[1,3,4,5]);
assert.deepEqual([...s.selectedSectionIds(a,2)],[2,6,7]);
assert.deepEqual([...s.selectedSectionIds(a,4)],[4]);
const t=c.thickness(v),rects=s.sectionRects(a,s.sectionRoot(v,t),t),panels=s.sectionPanels(a,rects,t,580);
assert.equal(panels.length,4);assert.equal(new Set(panels.map(p=>p.id)).size,4);
assert(rects[6].w>rects[3].w*2);assert.equal(rects[3].h,rects[4].h);assert(rects[6].z<rects[3].z);
const parts=c.geometry(v,false,false);assert.equal(parts.filter(p=>p.name==='Drawer front').length,6);assert.equal(parts.filter(p=>p.name==='Door').length,2);
const fixed=s.photoSections();fixed[3][3]='mm';fixed[3][4]=300;const fr=s.sectionRects(fixed,s.sectionRoot(v,t),t);assert.equal(fr[3].w,300);assert(Math.abs(fr[4].w/fr[5].w-2)<1e-9);
const collapsed=s.collapseSection(a,1);assert.deepEqual(s.treeErrors(collapsed),[]);assert.equal(collapsed.length,5);
for(const count of [1,2,3,4]){const converted=s.convertBays({cabinet_layout_mode:'mixed_bays',mixed_bay_count:count,mixed_bay_types:['drawers','doors','open','drawers'],mixed_bay_drawer_counts:[2,1,1,3]});assert.deepEqual(s.treeErrors(converted),[]);assert.equal(converted.filter(n=>n[2]==='leaf').length,count)}
const tmp=fs.mkdtempSync(path.join(process.cwd(),'.section-test-'));
try{
 fs.cpSync('public/engine/v5/src/modular_organization/data/scad',tmp,{recursive:true});
 const native=(values,mode,ext='echo')=>{fs.writeFileSync(path.join(tmp,'kitchen.scad'),c.applySettings(c.engineSources[c.schemas[4].file],4,{...values,output_mode:mode,include_shared_export_bounding_box:true}));const out=path.join(tmp,mode+'.'+ext),r=cp.spawnSync('openscad',['-o',out,path.join(tmp,'kitchen.scad')],{encoding:'utf8',timeout:60000});const log=ext==='echo'?fs.readFileSync(out,'utf8'):r.stderr;assert.equal(r.status,0,log);assert(!/^ERROR:|^WARNING:|ECHO: "ERROR\||CHECK\|ERROR/m.test(log),log);return {log,data:fs.readFileSync(out,'utf8')}};
 const bom=native(v,'bom').log,rows=bom.split('\n').filter(l=>l.includes('BOM|')&&!l.includes('BOM|ID|'));
 assert.equal(rows.filter(l=>l.includes('|drawer_face|')).length,6);assert.equal(rows.filter(l=>l.includes('|door|')).length,2);assert.equal(rows.filter(l=>/\|section_(partition|shelf)\|/.test(l)).length,4);
 const ids=rows.map(l=>l.split('|')[1]);assert.equal(new Set(ids).size,ids.length);assert(bom.includes('SECTION_SUPPORTS'));assert(bom.includes('SECTION_MACHINING'));
 const dims=[...bom.matchAll(/DIM\|SECTION\|S(\d+)\|X=([\d.]+)\|Z=([\d.]+)\|W=([\d.]+)\|H=([\d.]+)/g)];assert.equal(dims.length,5);for(const m of dims){const r=rects[Number(m[1])-1];for(const [i,k] of [[2,'x'],[3,'z'],[4,'w'],[5,'h']])assert(Math.abs(Number(m[i])-r[k])<.002)}
 const cut=native(v,'cut_layout','svg').data,pocket=native({...v,hinge_style:'euro_35mm'},'pocket_hinge_cups','svg').data;assert.equal(cut.match(/viewBox="([^"]+)/)[1],pocket.match(/viewBox="([^"]+)/)[1]);assert((cut.match(/M /g)||[]).length>=40);assert((pocket.match(/M /g)||[]).length>=4);
 native(v,'assembly','csg');native(v,'flat_3d','csg');
 const shelves=s.photoSections();shelves[3][5]='open';shelves[3][6]=3;shelves[4][11]=2;const sb=native({...v,section_nodes:shelves},'bom').log;assert.equal(sb.split('\n').filter(l=>l.includes('|section_shelf|')).length,6);
 // Hidden legacy combo settings must not create a divider or machining in Sections mode.
 const door=s.leaf(-1,0,'doors',2),zero={...v,section_nodes:[door],cabinet_contents:'combo',door_shelf_count:5,shelf_style:'fixed'};
 for(const count of [0,1,3,0]){const node=structuredClone(door);node[11]=count;const values={...zero,section_nodes:[node]};const report=native(values,'bom').log;
  assert(!report.includes('BOM|DIV|'),'Legacy combo divider leaked into section layout');
  assert.equal(report.split('\n').filter(l=>l.includes('|section_shelf|')).length,count);
  assert.equal(c.geometry(values,true,false).filter(p=>p.id.includes('-SH-')).length,count);
 }
 const clean={...zero,cabinet_contents:'drawers'};
 for(const [mode,ext] of [['assembly','csg'],['flat_3d','csg'],['cut_layout','svg'],['pocket_carcass_dados','svg']])assert.equal(native(zero,mode,ext).data,native(clean,mode,ext).data,'Hidden combo settings changed '+mode);
 const invalid=s.photoSections();invalid[3][3]='mm';invalid[3][4]=3000;fs.writeFileSync(path.join(tmp,'kitchen.scad'),c.applySettings(c.engineSources[c.schemas[4].file],4,{...v,section_nodes:invalid}));const failure=cp.spawnSync('openscad',['-o',path.join(tmp,'invalid.csg'),path.join(tmp,'kitchen.scad')],{encoding:'utf8'});assert(/ERROR: Assertion/.test(failure.stderr));
 console.log('Sections: tree validation, saved designs, nested/fixed geometry, mixed-bay conversion, native BOM/counts, matching export registration, shelves, assembly/flat output and invalid-size rejection passed.');
}finally{fs.rmSync(tmp,{recursive:true,force:true})}
