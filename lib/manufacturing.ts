export type Entry={name:string;data:string};
const columns=['ID','QTY','CATEGORY','MATERIAL','THICKNESS_MM','CUT_W_MM','CUT_H_MM','NOTES'];
const csv=(rows:string[][])=>rows.map(row=>row.map(v=>'"'+String(v).replaceAll('"','""')+'"').join(',')).join('\r\n')+'\r\n';
export function reports(text:string):Entry[]{
 const payloads=text.split(/\r?\n/).flatMap(line=>{const m=line.match(/ECHO: "((?:BOM|DIM|TARGET|INFO|WARN|ERROR)\|.*)"\s*$/);return m?[m[1]]:[]});
 const bom=payloads.filter(p=>p.startsWith('BOM|')).map(p=>{const a=p.split('|').slice(1);return [...a.slice(0,7),a.slice(7).join('|')]});
 if(bom.some(row=>row.slice(1,2).concat(row.slice(4,7)).some(v=>!v||!Number.isFinite(Number(v)))))throw Error('OpenSCAD returned undefined BOM dimensions. Check the export log and settings.');
 if(!bom.length)throw Error('OpenSCAD returned no BOM rows. No package was downloaded.');
 const dims=[...new Set(payloads.filter(p=>/^(DIM|TARGET|INFO)\|/.test(p)))];
 if(!dims.length)throw Error('OpenSCAD returned no dimension report.');
 const groups=new Map<string,string[]>();for(const row of bom){const key=JSON.stringify(row.slice(2)),existing=groups.get(key);if(existing){existing[0]+=', '+row[0];existing[1]=String(Number(existing[1])+Number(row[1]))}else groups.set(key,[...row])}
 const measurements:string[][]=[];
 for(const line of dims){const parts=line.split('|').slice(1),context=parts.filter(p=>!p.includes('='));for(const field of parts.filter(p=>p.includes('='))){const i=field.indexOf('=');measurements.push([context.join(' / '),field.slice(0,i),field.slice(i+1)])}}
 return [{name:'reports/design-health.json',data:JSON.stringify(designHealth(text),null,2)},{name:'reports/system-contract.json',data:JSON.stringify(systemContract(text),null,2)},{name:'reports/bom.csv',data:csv([columns,...bom])},{name:'reports/bom-grouped.csv',data:csv([columns,...groups.values()])},{name:'reports/dimensions.csv',data:csv([['CONTEXT','MEASUREMENT','VALUE (see field name; lengths in mm)'],...measurements])},{name:'reports/dimensions.txt',data:'OPENSCAD DIMENSION REPORT\nLengths in millimeters. W = width, D = depth, H = height.\nValues are evaluated by the cabinet engine; non-length settings retain their named units.\n\n'+dims.map(p=>p.split('|').join('  ·  ')).join('\n')+'\n'}];
}
export const operations=['cut_layout','engrave_layout','pocket_layout','pocket_carcass_dados','pocket_drawer_dados','pocket_bottom_grooves','pocket_shelf_pins','pocket_hinge_cups','pocket_face_registration','pocket_base_hardware','pocket_worktop_registration','pocket_face_frame_dados','pocket_ganging','pocket_slide_holes','pocket_divider_bottom_grooves','pocket_divider_perimeter_grooves'];

export type BomRow={id:string;qty:number;category:string;material:string;thickness:number;width:number;height:number;notes:string};
export function parseManufacturing(text:string){
 const payloads=[...new Set(text.split(/\r?\n/).flatMap(line=>{const m=line.match(/ECHO: "((?:BOM|DIM|TARGET|INFO|WARN|ERROR)\|.*)"\s*$/);return m?[m[1]]:[]}))];
 const bom:BomRow[]=payloads.filter(l=>l.startsWith('BOM|')).map(l=>{const a=l.split('|').slice(1);return {id:a[0],qty:Number(a[1]),category:a[2],material:a[3],thickness:Number(a[4]),width:Number(a[5]),height:Number(a[6]),notes:a.slice(7).join('|')}});
 const dimensions=payloads.filter(l=>/^(DIM|TARGET|INFO)\|/.test(l));
 const warnings=[...new Set(text.split(/\r?\n/).filter(l=>/WARN\||ERROR\||WARNING:|^ERROR:/.test(l)))];
 return {bom,dimensions,warnings};
}
export function operationNotes(text:string){return [...new Set(text.split(/\r?\n/).filter(l=>/depth|face|through|WARNING|WARN\||ERROR\|/i.test(l)))].map(l=>l.replace(/^ECHO: /,''))}

export function designHealth(text:string){
 const records=[...new Set(text.split(/\r?\n/).flatMap(line=>{const m=line.match(/ECHO: "((?:CHECK|COVERAGE|SYSTEM|COMPAT|INTERFACE|INTERFACE_FRAME|MODULE|KEEPOUT|FEATURE_OWNER|FEATURE)\|.*)"\s*$/);return m?[m[1]]:[]}))];
 const checks=records.filter(l=>l.startsWith('CHECK|')).map(l=>{const [,severity,code,...message]=l.split('|');return {severity,code,message:message.join('|')}});
 const errors=checks.filter(c=>c.severity==='ERROR'),warnings=checks.filter(c=>c.severity==='WARN');
 const coverage=records.filter(l=>l.startsWith('COVERAGE|'));
 return {status:errors.length?'ERROR':!checks.length?'UNVERIFIED':warnings.length?'WARN':'PASS',checks,errors,warnings,coverage,records,wholeModelAudit:'Not run in browser. Use the included v5 Python package with desktop OpenSCAD for final contour validation.'};
}

export function systemContract(text:string){
 const rows=designHealth(text).records;
 const records=(prefix:string)=>rows.filter(l=>l.startsWith(prefix+'|')).map(l=>Object.fromEntries(l.split('|').slice(1).filter(p=>p.includes('=')).map(p=>{const i=p.indexOf('=');return [p.slice(0,i).toLowerCase(),p.slice(i+1)]})));
 return {system:records('SYSTEM'),compatibility:records('COMPAT'),interfaces:records('INTERFACE'),interface_frames:records('INTERFACE_FRAME'),modules:records('MODULE'),keepouts:records('KEEPOUT'),coverage:records('COVERAGE')};
}
