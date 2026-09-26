// A fresh worker per operation bounds memory and allows immediate cancellation.
self.onmessage=async({data})=>{
 const logs=[];const log=line=>logs.push(String(line));
 try{
  const {filename,source,sources,mode}=data;
  const organization=/^modular_organization_(shop_cart|utility|benchtop|stackable|kitchen|drawer)_v3\.scad$/.test(filename);
  const names=organization?["modular_organization_core_v3.scad","modular_organization_layouts_v3.scad"]:[`modular_storage_core_v${filename.endsWith("_v32.scad")?32:29}.scad`,`modular_storage_layouts_v${filename.endsWith("_v32.scad")?32:29}.scad`];
  const allowed=['bom','cut_layout','engrave_layout','pocket_layout','pocket_carcass_dados','pocket_drawer_dados','pocket_bottom_grooves','pocket_shelf_pins','pocket_hinge_cups','pocket_face_registration','pocket_base_hardware','pocket_worktop_registration','pocket_face_frame_dados','pocket_ganging'];
  if(!allowed.includes(mode)||!organization&&!/^modular_storage_(shop_cart|utility|benchtop|stackable|kitchen|drawer)_v(29|32)\.scad$/.test(filename)||typeof source!=='string'||source.length>1000000||!Array.isArray(sources)||sources.length!==2||!names.every(name=>sources.some(f=>f.name===name&&typeof f.text==='string'&&f.text.length<1000000)))throw Error('Invalid export request.');
  const {default:OpenSCAD}=await import('./openscad.js');
  let font;if(mode==='engrave_layout'){const r=await fetch(new URL('./DejaVuSans.ttf',self.location.href));if(!r.ok)throw Error('Could not load the engraving font. Check your connection and try again.');font=new Uint8Array(await r.arrayBuffer());}
  const engine=await OpenSCAD({noInitialRun:true,locateFile:path=>new URL(path,self.location.href).href,print:log,printErr:log});
  if(font){engine.FS.mkdirTree('/fonts');engine.FS.writeFile('/fonts/DejaVuSans.ttf',font);}
  for(const f of sources)engine.FS.writeFile('/'+f.name,f.text);
  engine.FS.writeFile('/'+filename,source);
  const path=mode==='bom'?'/report.echo':'/layout.svg';
  const code=engine.callMain(['/'+filename,'-D','output_mode='+JSON.stringify(mode),'-D','dimension_report="full"','-D','system_contract_report="summary"','-D','validation_report="verbose"','-D','interface_keepout_policy="enforce"','-o',path]);
  let output='';try{output=engine.FS.readFile(path,{encoding:'utf8'})}catch{}
  const all=logs.join('\n')+'\n'+(mode==='bom'?output:'');
  if(/(^|\n)ERROR:|ECHO: "ERROR\|/.test(all)){if(mode==='bom')logs.push(output);throw Error('OpenSCAD rejected '+mode+'. See the export log.');}
  if(mode!=='bom'&&/CHECK\|ERROR\|/.test(all))throw Error('Manufacturing blocked by Design Health errors. See the export log.');
  // An operation with no enabled features may have no geometry at all.
  const empty=mode!=='bom'&&/Current top level object is empty/.test(all)&&!output;
  if(!empty&&(code!==0||!output))throw Error('OpenSCAD could not export '+mode+'. See the export log.');
  if(mode!=='bom'&&!empty&&!output.includes('<svg'))throw Error('OpenSCAD returned an invalid SVG.');
  self.postMessage({type:'result',output,logs,empty});
 }catch(e){self.postMessage({type:'error',error:e instanceof Error?e.message:String(e),logs})}
};
