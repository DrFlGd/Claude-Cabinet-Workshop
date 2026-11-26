// Reads the OpenSCAD Customizer parameters of a product's SCAD file: every top-level
// `key = value; // [options]` before the Hidden section, its section and the comment lines
// above it. Product defaults therefore live only in the SCAD file.
import type {ScadParam} from './types';

function literal(text:string):string|number|boolean|undefined{
 const s=text.trim();
 if(s==='true')return true;
 if(s==='false')return false;
 if(/^"(?:[^"\\]|\\.)*"$/.test(s))return JSON.parse(s);
 if(/^-?\d+(?:\.\d+)?(?:e-?\d+)?$/i.test(s))return Number(s);
 return undefined;
}

export function scadParams(source:string):ScadParam[]{
 const out:ScadParam[]=[];let section='',help:string[]=[];
 for(const raw of source.split(/\r?\n/)){
  const line=raw.trim();
  const sec=line.match(/^\/\*\s*\[([^\]]+)\]\s*\*\/$/);
  if(sec){section=sec[1];help=[];if(section==='Hidden')break;continue}
  if(!section)continue;
  if(line.startsWith('//')){help.push(line.replace(/^\/\/\s?/,''));continue}
  const m=line.match(/^([A-Za-z_][A-Za-z0-9_]*)\s*=\s*([^;]+);\s*(?:\/\/\s*\[([^\]]*)\])?/);
  if(!m){help=[];continue}
  const value=literal(m[2]);
  if(value===undefined){help=[];continue}
  const p:ScadParam={key:m[1],value,section,help:help.join(' ')};
  if(m[3]!==undefined){
   const range=m[3].split(':').map(Number);
   if(m[3].includes(':')&&range.every(Number.isFinite)){p.min=range[0];p.max=range[range.length-1];if(range.length===3)p.step=range[1]}
   else p.options=m[3].split(',').map(o=>o.trim().split(':')[0]).filter(Boolean);
  }
  out.push(p);help=[];
 }
 return out;
}

// Applies values to the SCAD source by rewriting each parameter's assignment, the same way
// the cabinet engine files are configured. Unknown keys are ignored.
export function applyParams(source:string,params:ScadParam[],values:Record<string,unknown>){
 for(const p of params){
  const v=values[p.key];
  if(v===undefined||v===null)continue;
  source=source.replace(new RegExp('^('+p.key+'\\s*=\\s*)[^;]+;','m'),(_m,prefix)=>prefix+JSON.stringify(v)+';');
 }
 return source;
}
