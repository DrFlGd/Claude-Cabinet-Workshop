export type Units='mm'|'in';
export const fromMillimeters=(value:number,units:Units)=>units==='in'?value/25.4:value;
export const toMillimeters=(value:number,units:Units)=>units==='in'?value*25.4:value;
export const formatDimension=(value:number,units:Units)=>fromMillimeters(value,units).toFixed(2);
// Catalog audit: counts, indices, relative weights and graduation factors have no length unit.
export function isLengthField(field:{key:string;value:any;expression?:string;options?:unknown;unit?:string}){
 if(field.options||typeof field.value==='boolean'||typeof field.value==='string')return false;
 if(field.options||/count|weights|graduated_step|circle_segments|^target_drawer_bank$/.test(field.key))return false;
 if(field.unit!==undefined)return field.unit==='mm';
 return typeof field.value==='number'||!!field.expression||(Array.isArray(field.value)&&field.value.every((v:unknown)=>typeof v==='number'));
}
export function mapLengths(value:any,convert:(n:number)=>number):any{return Array.isArray(value)?value.map(v=>mapLengths(v,convert)):typeof value==='number'?convert(value):value}
// Editing one array entry must not round-trip untouched neighbors through rounded display values.
export function restoreLengths(original:any,shown:any,edited:any,units:Units):any{
 if(Array.isArray(edited))return edited.map((v,i)=>restoreLengths(original?.[i],shown?.[i],v,units));
 return typeof edited==='number'?(edited===shown?original:toMillimeters(edited,units)):edited;
}
