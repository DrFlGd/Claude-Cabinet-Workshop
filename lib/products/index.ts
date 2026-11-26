// Product registry. A new product adds its SCAD file under public/products/<id>/, runs
// `node scripts/sync-product-sources.mjs`, lists its frontend in public/openscad/product-files.js,
// and adds a definition module (see media-cart.ts) to the list below.
import type {Values} from '../cabinet';
import type {Units} from '../units';
import type {EngineTarget,Product} from './types';
import {applyParams} from './scad-params';
import {mediaCart} from './media-cart';
import {productPacket} from './packet';

export const products:Product[]=[mediaCart];
export const productById=(id:string|null|undefined)=>products.find(p=>p.id===id);
export function productDefaults(p:Product):Values{return Object.fromEntries(p.params.map(x=>[x.key,x.value]))}
export function productStarterValues(p:Product,id:string):Values{
 const s=p.starters.find(x=>x.id===id)??p.starters.find(x=>x.id===p.defaultStarter)!;
 return {...productDefaults(p),...s.values,_starter:s.id};
}
export const productSource=(p:Product,v:Values)=>applyParams(p.source,p.params,v);
export const PRODUCT_DESIGN_META={version:2 as const,engine:5 as const,engineFamily:'modular_organization' as const,bundleRevision:5 as const};
export function productDesignFile(p:Product,v:Values,name:string,units:Units){
 return JSON.stringify({...PRODUCT_DESIGN_META,family:0,product:p.id,name,displayUnits:units,values:v},null,2);
}
// Saved values are checked against the product's SCAD parameters: known keys only,
// matching types, listed options.
export function parseProductValues(p:Product,input:Record<string,unknown>):Values{
 const v=productDefaults(p);
 for(const x of p.params){
  const a=input[x.key];if(a===undefined)continue;
  if(typeof a!==typeof x.value||(typeof a==='number'&&!Number.isFinite(a)))throw Error('Invalid setting: '+x.key);
  if(x.options&&!x.options.includes(String(a)))throw Error('Invalid option: '+x.key);
  v[x.key]=a;
 }
 v._starter=p.starters.some(s=>s.id===input._starter)?input._starter:'edited';
 return v;
}
export function productTarget(p:Product):EngineTarget{
 return {
  id:p.id,label:p.name,filename:p.file,sources:[],
  source:v=>productSource(p,v),validate:p.validate,
  renderModes:p.renderModes,exportModes:p.exportModes,sheetSection:p.sheetSection,
  projectFiles:(v,name,units)=>[
   {name:p.file,data:productSource(p,v)},
   {name:'design.cabinet.json',data:productDesignFile(p,v,name,units)},
   {name:'START-HERE.txt',data:`${p.name}: open ${p.file} in OpenSCAD 2021.01 or later. All selected settings are applied.\n\nSet output_mode to assembly for the 3D model, cut_layout for through cuts, pocket_dados for dados on the face that is up, pocket_dados_flip for dados on the other face (turn the part over left to right), engrave_layout for part labels, or bom for the parts list. Export SVG or DXF from OpenSCAD. All layouts share one registration frame.\n`},
  ],
  packet:(name,v,text,units)=>productPacket(p,name,v,text,units),
 };
}
