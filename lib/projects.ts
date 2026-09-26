import {defaults,families,legacyKeys,normalizeValues,schemas,Values} from './cabinet';
import type {Units} from './units';
export type Design={version:2;engine:5;engineFamily:"modular_organization";bundleRevision?:5;family:number;name:string;displayUnits:Units;values:Values};
export type Recent={id:string;updated:string;design:Design};
export const PROJECT_STORE='cabinet-workshop-projects-v1';
export function parseDesign(input:unknown):Design{
 const d=JSON.parse(JSON.stringify(input));
 if(!d||![1,2].includes(d.version)||!Number.isInteger(d.family)||d.family<0||d.family>=families.length||!d.values||Array.isArray(d.values))throw Error('Invalid cabinet design.');
 if(d.engineFamily!=="modular_organization"&&![29,30,31,32].includes(d.engine)){for(const [old,key] of Object.entries(legacyKeys))if(d.values[old]!==undefined)d.values[key]=d.values[old];if(d.family===4)d.values.cabinet_nominal_depth=d.values.kitchen_family==='wall'?304.8:609.6;}
 const v=defaults(d.family);
 if(d.engineFamily!=="modular_organization"&&d.values.edge_joinery_policy===undefined)v.edge_joinery_policy="legacy";
 if(d.family===3&&d.values.bottom_tab_placement===undefined)v.bottom_tab_placement='automatic';
 const validArray=(a:any,depth=0):boolean=>Array.isArray(a)&&depth<4&&a.length<=100&&a.every(x=>Array.isArray(x)?validArray(x,depth+1):typeof x==='number'?Number.isFinite(x):typeof x==='string'||typeof x==='boolean'||x===null);
 for(const f of schemas[d.family].fields){if(d.values[f.key]===undefined)continue;const a=d.values[f.key];if(f.expression?(a!==null&&(typeof a!=='number'||!Number.isFinite(a))):(Array.isArray(f.value)?!validArray(a):typeof a!==typeof f.value))throw Error('Invalid setting: '+f.key);if(f.options&&!f.options.includes(String(a)))throw Error('Invalid option: '+f.key);if(typeof a==='number'&&!Number.isFinite(a))throw Error('Invalid number: '+f.key);v[f.key]=a;}
 v.cabinet_preset='custom';
 return {version:2,engine:5,engineFamily:"modular_organization",bundleRevision:5,family:d.family,name:typeof d.name==='string'?d.name.slice(0,160):'Imported cabinet',displayUnits:d.displayUnits==='in'?'in':'mm',values:normalizeValues(d.family,{...v,_starter:schemas[d.family].starters.some(s=>s.id===d.values._starter)?d.values._starter:'edited'})};
}
export function recentRecords(raw:string|null):Recent[]{if(!raw)return [];const a=JSON.parse(raw);if(!Array.isArray(a))throw Error('Invalid recovery data');return a.slice(0,10).flatMap(r=>{try{if(typeof r.id!=='string'||typeof r.updated!=='string')return [];return [{id:r.id,updated:r.updated,design:parseDesign(r.design)}]}catch{return []}})}
export function upsertRecent(records:Recent[],record:Recent){return [record,...records.filter(r=>r.id!==record.id)].slice(0,10)}
