'use client';
import {useState,useEffect,useRef} from 'react';
import {Box,Download,Undo2,Redo2,Ruler,Layers,Check,FolderOpen,Save,ArrowUpRight,Search,Info,RotateCcw,ListChecks,FilePlus2,History,XCircle,ChevronDown} from 'lucide-react';
import {Select,SelectTrigger,SelectValue,SelectContent,SelectItem} from '@/components/ui/select';
import {Tabs,TabsList,TabsTrigger,TabsContent} from '@/components/ui/tabs';
import {Switch} from '@/components/ui/switch';
import {Dialog,DialogContent,DialogHeader,DialogTitle,DialogDescription} from '@/components/ui/dialog';
import {Toaster,toast} from 'sonner';
import {defaults,schemas,families,label,thickness,validate,exportBundle,download,Values,starterValues,normalizeValues,geometry,Part} from '@/lib/cabinet';
import SectionEditor from './SectionEditor';
import {convertBays} from '@/lib/sections';
import CabinetView from './CabinetView';
import OpenSCADView from './OpenSCADView';
import ManufacturingExport from './ManufacturingExport';
import FitTargetResult,{solvedDimensions} from './FitTargetResult';
import DimensionInput from './DimensionInput';
import SettingHelp from './SettingHelp';
import FamilyPicker,{familyIcons} from './FamilyPicker';
import PlanPanel,{StatusChip} from './PlanPanel';
import useEngineAnalysis from './useEngineAnalysis';
import {Units,formatDimension,formatInput,formatShop,isLengthField,mapLengths,restoreLengths} from '@/lib/units';
import {partSection} from '@/lib/selection';
import useProjects from './useProjects';
import {parseDesign,Design} from '@/lib/projects';
import HardwarePicker from './HardwarePicker';
import FitGuide,{guideKeys} from './FitGuide';
import {HELP,optionLabel} from '@/lib/help';
import {sectionOrder,shopSections,sectionFor,settingsGroup,isAdvanced,inactiveReason,presentFields,linkedChanges} from '@/lib/settings';
const titles:Record<string,string>={custom_cabinet_width:'Width',custom_cabinet_height:'Height',custom_cabinet_depth:'Depth',custom_top_style:'Top construction',back_style:'Back construction',joinery_style:'Carcass joinery',carcass_stock:'Carcass stock',custom_carcass_thickness:'Measured thickness',base_style:'Base style',include_worktop:'Add worktop',worktop_thickness:'Worktop thickness',cabinet_layout_mode:'Layout',custom_cabinet_contents:'Contents',custom_drawer_count:'Drawer count',custom_door_count:'Door count',mixed_bay_count:'Number of bays',bottom_width_style:'Bottom panel',cnc_tool_diameter:'CNC cutter diameter',slot_corner_relief:'Shared slot relief',side_relief:'Side-panel relief',router_bit_diameter:'CNC cutter diameter'};
const NOMINAL:Record<string,number>={'1/8':3.175,'1/4':6.35,'3/8':9.525,'1/2':12.7,'5/8':15.875,'3/4':19.05,'1':25.4};
const pretty=(s:string)=>{
 const nominal=s.match(/^(\d+(?:\/\d+)?)_nominal$/);
 if(nominal)return nominal[1]+'″ nominal ('+NOMINAL[nominal[1]]+' mm)';
 return ({'legacy_spacing':'Manual spacing','explicit_array':'Manufacturer defined','structural_panel':'Structural panel','panel':'Applied thin panel','tab_slot':'Tab & slot','butt':'Butt joint','dado':'Dado','mixed_bays':'Independent bays','legacy':'Full-width layout','sections':'Sections (split openings)','custom_mm':'Measured thickness (enter mm)','custom':'Custom','metal_slides':'Metal slides','wood_rails':'Wood runners','inset_flush':'Inset (flush)','face_frame':'Face frame','frameless':'Frameless'} as Record<string,string>)[s]||label(s);
};
function Choice({value,onChange,options,id,field}:{value:string;onChange:(s:string)=>void;options:string[];id?:string;field?:string}){return <Select value={value} onValueChange={onChange}><SelectTrigger id={id} className='choice'><SelectValue/></SelectTrigger><SelectContent>{options.map(o=><SelectItem value={o} key={o}>{(field&&optionLabel(field,o))||pretty(o)}</SelectItem>)}</SelectContent></Select>}
function ArrayField({value,onChange,id,fieldKey,units,length,activeCount}:{value:any[];onChange:(v:any)=>void;id:string;fieldKey:string;units:Units;length:boolean;activeCount?:number}){
 const active=activeCount===undefined?value:value.slice(0,activeCount);
 const displayed=length?mapLengths(active,n=>Number(formatInput(n,units))):active;
 const [draft,setDraft]=useState(JSON.stringify(displayed));const [error,setError]=useState(false);useEffect(()=>setDraft(JSON.stringify(displayed)),[value,units,activeCount]);
 const options=fieldKey==='mixed_bay_types'?['drawers','door','open']:fieldKey.includes('shelf_styles')?['fixed','adjustable']:fieldKey.includes('hinge_sides')?['left','right']:fieldKey.includes('height_modes')?['equal','graduated','custom_weights']:null;
 const flat=value.every(v=>typeof v==='number'||typeof v==='string');
 const update=(i:number,v:any)=>{const a=[...value];a[i]=v;onChange(a)};
 return <>{flat&&<div className='array-grid'>{active.map((v,i)=><label key={i} htmlFor={id+'-'+i}>{fieldKey.startsWith('mixed_bay')?'Bay':fieldKey.startsWith('drawer_bank')?'Bank':'Position'} {i+1}{options?<Choice id={id+'-'+i} value={String(v)} options={Array.from(new Set([...options,String(v)]))} onChange={v=>update(i,v)}/>:length&&typeof v==='number'?<DimensionInput id={id+'-'+i} value={v} units={units} onChange={v=>update(i,v)}/>:<input id={id+'-'+i} type={typeof v==='number'?'number':'text'} step='any' value={v} onChange={e=>{if(typeof v==='number'){if(e.target.value!==''&&Number.isFinite(e.target.valueAsNumber))update(i,e.target.valueAsNumber)}else update(i,e.target.value)}}/>}</label>)}</div>}<details className='array-source' open={!flat}><summary>{flat?(activeCount===undefined?'Edit full array':'Edit active entries'):'Edit rows of values'}{length?' ('+units+')':''}</summary><input id={id} className={error?'invalid':''} value={draft} onChange={e=>setDraft(e.target.value)} onBlur={()=>{try{const a=JSON.parse(draft);if(!Array.isArray(a)||a.length>30||(activeCount!==undefined&&a.length!==activeCount))throw Error();setError(false);if(draft!==JSON.stringify(displayed))onChange([...(length?restoreLengths(active,displayed,a,units):a),...(activeCount===undefined?[]:value.slice(activeCount))])}catch{setError(true)}}}/></details>{error&&<small className='error'>Enter a JSON array, for example [1, 1, 2].</small>}</>
}
const DESIGN_META={version:2 as const,engine:5 as const,engineFamily:'modular_organization' as const,bundleRevision:5 as const};
export default function Home(){
 const [family,setFamily]=useState(0),[values,setValues]=useState<Values>(()=>defaults(0)),[step,setStep]=useState('Sizing'),[interior,setInterior]=useState(false),[exploded,setExploded]=useState(false),[dimensions,setDimensions]=useState(true),[tab,setTab]=useState('model'),[query,setQuery]=useState(''),[exportOpen,setExportOpen]=useState(false),[busy,setBusy]=useState(false),[projectName,setProjectName]=useState('Workshop cart');
 const [units,setUnits]=useState<Units>('mm');
 const stockThickness=family===5?thickness(values,'drawer_stock','custom_drawer_material_thickness'):thickness(values);
 const fmt=(n:number)=>formatDimension(n,units);
 const [selected,setSelected]=useState<string|null>(null);
 const [pickerOpen,setPickerOpen]=useState(false);
 const [advanced,setAdvanced]=useState<Record<string,boolean>>({});
 const [past,setPast]=useState<Values[]>([]),[future,setFuture]=useState<Values[]>([]);
 const input=useRef<HTMLInputElement>(null);
 const current=useRef({family,values});
 current.current={family,values};
 const analysis=useEngineAnalysis(family,values);
 const solved=solvedDimensions(family,analysis);
 const fitActive=family>=5||values.width_basis==='drawer_inside'||values.depth_basis==='drawer_inside';
 const previewValues=fitActive&&solved?{...values,custom_cabinet_width:solved.RESOLVED_CABINET_W,custom_cabinet_height:solved.RESOLVED_CABINET_H??values.custom_cabinet_height,custom_cabinet_depth:solved.RESOLVED_CARCASS_D}:values;
 const selectable=[...new Map([...geometry(previewValues,false,false),...geometry(previewValues,true,false)].map(p=>[p.id,p])).values()];
 const selectedPart=selectable.find(p=>p.id===selected);
 const selectPart=(p:Part|null)=>{setSelected(p?.id??null);if(p){setStep(partSection(p));setQuery('')}};
 const fields=presentFields(schemas[family].fields),errors=validate(values);
 const record=(next:(v:Values)=>Values)=>{setPast(p=>[...p.slice(-49),values]);setFuture([]);setValues(v=>normalizeValues(family,{...next(v),_starter:'edited'}))};
 const change=(key:string,val:any)=>record(v=>({...v,...(key==='cabinet_layout_mode'&&val==='sections'?{section_nodes:convertBays(v),width_basis:'outside',depth_basis:'outside'}:{}),...linkedChanges(key,val,v),[key]:val}));
 function startDesign(n:number,starter:string){
  setFamily(n);setValues(starterValues(n,starter,defaults(n)));setPast([]);setFuture([]);
  setProjectName(schemas[n].starters.find(p=>p.id===starter&&p.id!==schemas[n].defaultStarter)?.name??families[n].name);
  setStep(starter==='photo_section_cabinet'?'Structure':'Sizing');setQuery('');setSelected(null);setPickerOpen(false);
  toast.success('New design started — review the size and materials');
 }
 const undo=()=>{if(past.length){setFuture(f=>[values,...f]);setValues(past[past.length-1]);setPast(p=>p.slice(0,-1))}},
  redo=()=>{if(future.length){setPast(p=>[...p,values]);setValues(future[0]);setFuture(f=>f.slice(1))}};
 useEffect(()=>{
  const onKey=(e:KeyboardEvent)=>{
   const target=e.target as HTMLElement|null;
   if(!(e.ctrlKey||e.metaKey)||e.altKey||target?.closest('input,textarea,[contenteditable=true]'))return;
   if(e.key.toLowerCase()==='z'&&!e.shiftKey){e.preventDefault();undo()}
   else if(e.key.toLowerCase()==='y'||(e.key.toLowerCase()==='z'&&e.shiftKey)){e.preventDefault();redo()}
  };
  window.addEventListener('keydown',onKey);return ()=>window.removeEventListener('keydown',onKey);
 });
 useEffect(()=>{
  const context=(document as any).modelContext;
  if(!context?.registerTool)return;
  const lifecycle=new AbortController();
  Promise.resolve(context.registerTool({name:'read_cabinet_configuration',description:'Read the current cabinet family, parameters and envelope validation.',inputSchema:{type:'object',properties:{},additionalProperties:false},annotations:{readOnlyHint:true},execute:()=>({...current.current,validation:validate(current.current.values)})},{signal:lifecycle.signal})).catch(()=>{});
  return ()=>lifecycle.abort();
 },[]);
 const guidedKeys=step==='Sizing'&&family<5?guideKeys(values):new Set<string>();
 function field(f:typeof fields[number]){
  const key=f.key,value=values[key],id='field-'+key+'-'+sectionFor(f);
  return <div className={'field '+(isAdvanced(f)?'is-advanced ':'')+(typeof value==='boolean'?'toggle-field':'')} key={key}>
   <SettingHelp advanced={isAdvanced(f)} id={id} title={family===3&&key==='door_shelf_count'?'Shelf count':titles[key]??label(key)} help={[family===3&&key==='door_shelf_count'?'Number of internal shelves. Zero shelves makes one open section; each added shelf creates another section.':HELP[key]??f.description,f.expression?'Leave blank to calculate automatically ('+f.expression+').':''].filter(Boolean).join(' ')}/>
   {isLengthField(f)&&!Array.isArray(value)?<DimensionInput id={id} value={value} units={units} automatic={!!f.expression} bounds={f.bounds} onChange={v=>change(key,v)}/>:
    typeof value==='boolean'?<Switch id={id} checked={value} onCheckedChange={v=>change(key,v)}/>:
    f.options?<Choice id={id} field={key} value={String(value)} onChange={v=>change(key,typeof f.value==='number'?Number(v):v)} options={f.options}/>:
    Array.isArray(value)?<ArrayField id={id} activeCount={key.startsWith('mixed_bay_')?Number(values.mixed_bay_count):key.startsWith('drawer_bank_')?Number(values.drawer_bank_count):undefined} fieldKey={key} units={units} length={isLengthField(f)} value={value} onChange={v=>change(key,v)}/>:
    typeof value==='number'?<div className='number-wrap'><input id={id} type='number' value={value} step={f.bounds?.[2]??0.1} min={f.bounds?.[0]} max={f.bounds?.[1]} onChange={e=>{if(e.target.value!==''&&Number.isFinite(e.target.valueAsNumber))change(key,e.target.valueAsNumber)}}/></div>:
    <input id={id} value={String(value??'')} onChange={e=>change(key,e.target.value)}/>}
  </div>;
 }
 async function exportFiles(){
  if(errors.length)return;
  setBusy(true);
  try{download(await exportBundle(family,values),'cabinet-workshop.zip');toast.success('OpenSCAD project downloaded');setExportOpen(false)}
  catch(e){toast.error(String(e))}
  finally{setBusy(false)}
 }
 function save(){
  download(new Blob([JSON.stringify({...DESIGN_META,displayUnits:units,family,name:projectName,values},null,2)],{type:'application/json'}),(projectName.replace(/[^a-z0-9_-]+/gi,'-')||'design')+'.cabinet.json');
  projects.markSaved();
  toast.success('Design downloaded to your device');
 }
 function restoreDesign(d:Design){setUnits(d.displayUnits);setFamily(d.family);setValues(d.values);setStep('Sizing');setProjectName(d.name);setPast([]);setFuture([]);setSelected(null)}
 const projects=useProjects({...DESIGN_META,family,name:projectName,displayUnits:units,values},restoreDesign);
 async function load(file?:File){
  if(!file)return;
  try{
   if(file.size>1000000)throw Error();
   const d=parseDesign(JSON.parse(await file.text()));
   projects.guard(()=>{restoreDesign(d);projects.markSaved(d);toast.success('Design opened')});
  }catch{toast.error('This file is not a valid Cabinet Workshop design.')}
  finally{if(input.current)input.current.value=''}
 }
 const visibleFields=fields.filter(f=>!['cabinet_preset','kitchen_model_code'].includes(f.key));
 // A section appears only when at least one of its settings applies to the current layout.
 const steps=sectionOrder.filter(name=>name==='Hardware'||name===step||visibleFields.some(f=>sectionFor(f)===name&&!inactiveReason(f,values)));
 const activeCount=(name:string)=>visibleFields.filter(f=>sectionFor(f)===name&&!inactiveReason(f,values)&&(advanced[name]||!isAdvanced(f))).length;
 const sectionFields=visibleFields.filter(f=>sectionFor(f)===step&&!guidedKeys.has(f.key));
 const advancedCount=sectionFields.filter(f=>!inactiveReason(f,values)&&isAdvanced(f)).length;
 const filtered=(query.trim()?visibleFields:sectionFields).filter(f=>!inactiveReason(f,values)&&(query.trim()||advanced[sectionFor(f)]||!isAdvanced(f))&&(f.key+' '+(titles[f.key]??label(f.key))+' '+f.section+' '+(HELP[f.key]??'')+' '+f.description).toLowerCase().includes(query.trim().toLowerCase()));
 const groups=Array.from(new Set(filtered.map(settingsGroup)));
 function chooseStarter(id:string){
  setPast(p=>[...p.slice(-49),values]);setFuture([]);
  setValues(starterValues(family,id,values));
  if(id==='photo_section_cabinet'){setStep('Structure');setQuery('')}
  setProjectName(schemas[family].starters.find(p=>p.id===id)?.name??families[family].name);
  toast.success('Starter loaded — review dimensions and materials');
 }
 const starterName=values._starter&&values._starter!=='edited'?(values._starter===schemas[family].defaultStarter?'Default configuration':schemas[family].starters.find(s=>s.id===values._starter)?.name):null;
 const FamilyIcon=familyIcons[family];
 const issueCount=analysis.plan&&analysis.planKey===analysis.key?analysis.plan.issues.filter(i=>i.severity==='error').length:0;
 const outside=analysis.plan&&analysis.planKey===analysis.key?analysis.plan.outside:undefined;
 const interiorDepth=analysis.plan&&analysis.planKey===analysis.key&&analysis.plan.interior?analysis.plan.interior.d:previewValues.custom_cabinet_depth-(values.back_style==='structural_panel'?thickness(values):0);
 const shown={w:outside?.w??previewValues.custom_cabinet_width,h:outside?.h??previewValues.custom_cabinet_height,d:outside?.d??previewValues.custom_cabinet_depth};
 return <main>
  {projects.dialogs}
  <Toaster position='bottom-right'/>
  <FamilyPicker open={pickerOpen} onOpenChange={setPickerOpen} family={family} units={units} onChoose={(n,s)=>projects.guard(()=>startDesign(n,s))}/>
  <header className='app-header'>
   <a href='./' className='brand'><span className='brand-icon'><Box size={24}/></span><div>Cabinet<span>WORKSHOP</span></div></a>
   <div className='header-project'><span className='separator'/><input aria-label='Design name' value={projectName} onChange={e=>setProjectName(e.target.value)}/><span className='draft' role='status'>{projects.status}</span></div>
   <div className='units-toggle' role='radiogroup' aria-label='Display units'>
    {(['mm','in'] as const).map(u=><button key={u} role='radio' aria-checked={units===u} className={units===u?'is-active':''} onClick={()=>setUnits(u)}>{u==='mm'?'mm':'inch'}</button>)}
   </div>
   <div className='header-actions'>
    <button onClick={()=>setPickerOpen(true)} title='Start a new design'><FilePlus2 size={17}/><span>New</span></button>
    <button onClick={projects.openRecent} title='Recent designs on this browser'><History size={17}/><span>Recent</span></button>
    <button onClick={()=>input.current?.click()} title='Open a saved design file'><FolderOpen size={17}/><span>Open</span></button>
    <button onClick={save} title='Download this design as a file'><Save size={17}/><span>Save</span></button>
    <button className='primary' onClick={()=>setExportOpen(true)}><Download size={17}/><span>Export</span></button>
   </div>
   <input type='file' accept='.json' ref={input} hidden onChange={e=>load(e.target.files?.[0])}/>
  </header>
  <div className='workspace cw-workspace'>
   <aside className='config cw-config' aria-label='Cabinet settings'>
    <div className='type-card'>
     <span className='type-icon'><FamilyIcon size={22}/></span>
     <div><span className='eyebrow'>CABINET TYPE</span><strong>{families[family].name}</strong><small>{starterName?'Starter · '+starterName:'Custom configuration'}</small></div>
     <button onClick={()=>setPickerOpen(true)} aria-label='Change cabinet type or starter'>Change<ChevronDown size={15}/></button>
    </div>
    <div className='starter-row'>
     <label htmlFor='starter'>Starting point</label>
     <Select value={values._starter??'edited'} onValueChange={id=>projects.guard(()=>chooseStarter(id))}>
      <SelectTrigger id='starter' className='choice starter-choice'><SelectValue/></SelectTrigger>
      <SelectContent>
       <SelectItem value='edited' disabled>Custom · edited configuration</SelectItem>
       {schemas[family].starters.map(p=><SelectItem key={p.id} value={p.id}>{p.id===schemas[family].defaultStarter?'Default configuration':p.name}</SelectItem>)}
      </SelectContent>
     </Select>
     <button className='icon-button' title='Restore the default settings for this cabinet type' aria-label='Reset to defaults' onClick={()=>projects.guard(()=>{setPast(p=>[...p,values]);setFuture([]);setValues(defaults(family));toast.success('Default settings restored')})}><RotateCcw size={16}/></button>
    </div>
    <nav className='step-nav' aria-label='Settings sections'>
     {steps.map(name=><button key={name} data-settings-step={name} aria-current={step===name&&!query.trim()?'step':undefined} className={(step===name&&!query.trim()?'is-active ':'')+(shopSections.includes(name)?'is-shop':'')} onClick={()=>{setStep(name);setQuery('')}}>
      {name}{name!=='Hardware'&&<small>{activeCount(name)}</small>}
     </button>)}
    </nav>
    <div className='search-field cw-search'><Search size={16}/><input placeholder='Find any setting…' aria-label='Search all settings' value={query} onChange={e=>setQuery(e.target.value)}/>{query&&<button className='clear-search' aria-label='Clear search' onClick={()=>setQuery('')}><XCircle size={15}/></button>}</div>
    <div key={step+(query?'-q':'')} className='config-scroll'>
     <div className='settings-heading'><h2>{query.trim()?'Search results':step}</h2><span>{query.trim()?filtered.length+' match'+(filtered.length===1?'':'es'):step==='Hardware'?'Preset library':activeCount(step)+' settings'}</span></div>
     {!query.trim()&&advancedCount>0&&<label className='advanced-control'><Switch checked={!!advanced[step]} onCheckedChange={v=>setAdvanced(a=>({...a,[step]:v}))}/>Show advanced <span>{advancedCount}</span></label>}
     {!query.trim()&&step==='Hardware'&&<HardwarePicker query={query} family={family} apply={patch=>{record(v=>({...v,...patch}));toast.success('Hardware settings applied — all values remain editable')}}/>}
     {!query.trim()&&step==='Sizing'&&family<5&&<FitGuide family={family} values={values} units={units} change={change} patch={patch=>record(v=>({...v,...patch}))}/>}
     {!query.trim()&&step==='Machining'&&<p className='field-note'>Shared settings provide defaults. Material-specific relief and cutter diameters appear with the relevant joints below. A diameter of 0 inherits the shared cutter. Use None where CAM adds relief.</p>}
     {!query.trim()&&family===4&&step==='Structure'&&values.cabinet_layout_mode==='sections'&&<SectionEditor values={values} thickness={stockThickness} units={units} change={nodes=>change('section_nodes',nodes)}/>}
     {!query.trim()&&family===4&&step==='Structure'&&values.cabinet_layout_mode==='mixed_bays'&&<div className='note'><Info size={17}/><p>Independent bays are full-height columns, numbered left to right. Increase Bay count to use bays 3 and 4. Each column contains drawers, a door, or open shelves; switch to Sections to split openings horizontally and vertically.</p></div>}
     {groups.map(group=><section key={group} className='settings-group'><h3>{query.trim()?group:group.split(' / ').slice(1).join(' / ')}</h3>{filtered.filter(f=>settingsGroup(f)===group).map(f=>field(f))}</section>)}
     {filtered.length===0&&(query.trim()||step!=='Hardware')&&<p className='muted'>{query?'No matching visible settings. Settings that do not apply to this layout are hidden.':step==='Sizing'&&guidedKeys.size?'':'Turn on advanced settings to see the controls in this section.'}</p>}
    </div>
    <div className='config-footer'><span>Modular Organization engine</span><strong>v5 · MOI-4</strong></div>
   </aside>
   <section className='design-surface'>
    <div className='surface-header'>
     <div><div className='eyebrow'>{families[family].code} <span>/</span> PARAMETRIC DESIGN</div><h1>{projectName||families[family].name}</h1></div>
     <div className='surface-tools'>
      <StatusChip analysis={analysis} onClick={()=>setTab('plan')}/>
      <div className='history'><button onClick={undo} disabled={!past.length} aria-label='Undo' title='Undo (Ctrl+Z)'><Undo2 size={18}/></button><button onClick={redo} disabled={!future.length} aria-label='Redo' title='Redo (Ctrl+Shift+Z)'><Redo2 size={18}/></button></div>
     </div>
    </div>
    <FitTargetResult units={units} family={family} values={values} analysis={analysis}/>
    <Tabs value={tab} onValueChange={setTab} className='view-tabs'>
     <div className='canvas-toolbar'>
      <TabsList className='view-switch'>
       <TabsTrigger value='model'><Box size={16}/>Preview</TabsTrigger>
       <TabsTrigger value='render'><Layers size={16}/>Exact 3D</TabsTrigger>
       <TabsTrigger value='plan'><ListChecks size={16}/>Cut list & fit{issueCount>0&&<span className='tab-badge'>{issueCount}</span>}</TabsTrigger>
      </TabsList>
      <span className='schematic-label'>{tab==='model'?'Instant schematic · approximate':tab==='render'?'OpenSCAD geometry':'Engine-calculated parts'}</span>
     </div>
     <TabsContent value='model' className='model-content'>
      <div className='display-controls'>
       <select id='part-selector' aria-label='Edit a component' value={selectedPart?.id??''} onChange={e=>selectPart(selectable.find(p=>p.id===e.target.value)??null)}>
        <option value=''>Edit a component…</option>
        {selectable.map(p=><option key={p.id} value={p.id}>{p.name} · {p.id}</option>)}
       </select>
       <label><Switch checked={interior} onCheckedChange={setInterior}/>Interior</label>
       <label><Switch checked={exploded} onCheckedChange={setExploded}/>Exploded</label>
       <button className={dimensions?'selected':''} onClick={()=>setDimensions(v=>!v)} aria-pressed={dimensions}><Ruler size={16}/><span>Dimensions</span></button>
      </div>
      {errors.length?<div className='validation-panel'><Info/><h2>Check your dimensions</h2>{errors.map(e=><p key={e}>{e}</p>)}</div>:<CabinetView selected={selected} onSelect={selectPart} units={units} values={previewValues} interior={interior} exploded={exploded} dimensions={dimensions}/>}
      <div className='model-caption'><span className='material-dot'/>{formatShop(stockThickness,units)}{units==='mm'?' mm':''} {family===5?'drawer wall':'carcass'} stock<span className='caption-divider'/> {pretty(family===5?values.drawer_joinery_style:(values.joinery_style??'butt'))}<button className='link-button' onClick={()=>setTab('render')}>Joinery, holes and grooves are in Exact 3D <ArrowUpRight size={14}/></button></div>
     </TabsContent>
     <TabsContent value='render' forceMount hidden={tab!=='render'} className='native-content'>
      <OpenSCADView selected={fitActive&&!solved?undefined:selectedPart} parts={fitActive&&!solved?[]:selectable} onSelect={selectPart} family={family} values={values} active={tab==='render'}/>
     </TabsContent>
     <TabsContent value='plan' className='plan-content'>
      <PlanPanel analysis={analysis} units={units} name={projectName} values={values}/>
     </TabsContent>
    </Tabs>
    <div className='summary-bar'>
     <div><span>WIDTH</span><strong>{fmt(shown.w)}<small>{units}</small></strong></div>
     <div><span>HEIGHT</span><strong>{fmt(shown.h)}<small>{units}</small></strong></div>
     <div><span>{family===5?'BOX DEPTH':family===6?'FRAME DEPTH':'CARCASS DEPTH'}</span><strong>{fmt(shown.d)}<small>{units}</small></strong></div>
     <div className='depth-metric' hidden={family>=5}><span>INTERIOR DEPTH</span><strong>{fmt(interiorDepth)}<small>{units}</small></strong></div>
     <div className='status'>{errors.length?<><Info size={17}/>Check dimensions</>:outside?<><Check size={17}/>Engine-resolved size</>:<><Check size={17}/>Input ranges checked</>}</div>
    </div>
   </section>
  </div>
  <Dialog open={exportOpen} onOpenChange={setExportOpen}>
   <DialogContent className='export-dialog'>
    <DialogHeader><span className='export-icon'><Download/></span><DialogTitle>Take your design to the workshop</DialogTitle><DialogDescription>Generate manufacturing files or download your editable OpenSCAD project. Sources, SVGs and manufacturing reports use millimeters.</DialogDescription></DialogHeader>
    <ManufacturingExport units={units} family={family} values={values} name={projectName} invalid={!!errors.length}/>
    <div className='export-includes'><h3>OpenSCAD project · ZIP</h3><p><Check size={16}/> Your selected cabinet and all current settings</p><p><Check size={16}/> Shared geometry and manufacturing layouts</p><p><Check size={16}/> BOM export script and editable design file</p></div>
    <div className='note'><Info size={18}/><p>Open the included .scad file in OpenSCAD to render exact geometry and export cut, pocket, engraving, or BOM outputs. The cut list tab and the manufacturing package above evaluate the same engine directly in your browser.</p></div>
    {errors.map(e=><p className='error' key={e}>{e}</p>)}
    <button className='primary download-button' disabled={busy||!!errors.length} onClick={exportFiles}><Download size={18}/>{busy?'Preparing project…':'Download project'}</button>
   </DialogContent>
  </Dialog>
 </main>;
}
