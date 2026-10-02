export type Units='mm'|'in';
export const fromMillimeters=(value:number,units:Units)=>units==='in'?value/25.4:value;
export const toMillimeters=(value:number,units:Units)=>units==='in'?value*25.4:value;
export const formatDimension=(value:number,units:Units)=>fromMillimeters(value,units).toFixed(2);
// Editable values keep enough precision to round-trip shop clearances (0.2 mm is 0.0079 in) without trailing zeros.
export function formatInput(value:number,units:Units){
 const n=fromMillimeters(value,units);
 return String(Number(n.toFixed(units==='in'?4:2)));
}
// Shop display for inches: nearest 1/32 in as a mixed fraction (23 5/8). Millimeters keep up to two decimals (19.05).
export function formatFraction(mm:number,denominator=32){
 const inches=Math.abs(mm)/25.4,total=Math.round(inches*denominator),whole=Math.floor(total/denominator);
 let num=total%denominator,den=denominator;
 while(num&&num%2===0){num/=2;den/=2}
 const text=whole&&num?whole+' '+num+'/'+den:num?num+'/'+den:String(whole);
 return (mm<0&&text!=='0'?'-':'')+text;
}
export function formatShop(mm:number,units:Units){
 return units==='in'?formatFraction(mm)+'″':String(Number(mm.toFixed(2)));
}
// Accepts the current display unit or an explicit suffix: 600, 600 mm, 60 cm, 23.5, 23 1/2, 23-1/2", 3/4 in, 2' 3 1/2".
export function parseDimension(text:string,units:Units):number{
 let s=text.trim().toLowerCase().replace(/[″”“]/g,'"').replace(/[′’‘]/g,"'").replace(/,/g,'.');
 if(!s)return NaN;
 const sign=s.startsWith('-')?-1:1;
 if(sign<0)s=s.slice(1).trim();
 let feet=0,unit:'mm'|'cm'|'m'|'in'|null=null;
 const ft=s.match(/^(\d+(?:\.\d+)?)\s*(?:'|ft|feet|foot)\s*(.*)$/);
 if(ft){feet=Number(ft[1]);s=ft[2].trim();unit='in';if(!s)return sign*feet*304.8}
 const suffix=s.match(/^(.*?)\s*(mm|cm|m|inches|inch|in|")$/);
 if(suffix){s=suffix[1].trim();unit=suffix[2]==='"'||suffix[2].startsWith('in')?'in':suffix[2] as 'mm'|'cm'|'m'}
 const m=s.match(/^(\d+(?:\.\d*)?|\.\d+)?(?:(?:\s+|-)?(\d+)\s*\/\s*(\d+))?$/);
 if(!m||(m[1]===undefined&&m[2]===undefined)||(m[3]!==undefined&&Number(m[3])===0))return NaN;
 const n=Number(m[1]??0)+(m[2]!==undefined?Number(m[2])/Number(m[3]):0);
 if(!Number.isFinite(n))return NaN;
 const mm=unit==='in'?n*25.4+feet*304.8:unit==='cm'?n*10:unit==='m'?n*1000:unit==='mm'?n:toMillimeters(n,units);
 return sign*mm;
}
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
