// A product is a design with its own OpenSCAD engine file and its own editor, beside the
// cabinet types. It supplies its SCAD source, the settings it exposes (grouped into
// sections, with labels and when each applies), starting points, a quick validation and
// the files that go into the manufacturing package. Everything else (engine check, cut
// list, nesting, per-sheet SVG/DXF, export page, recovery) is shared with the cabinets.
import type {Values} from '../cabinet';
import type {Units} from '../units';

// One OpenSCAD Customizer parameter as declared in the product's SCAD file.
export type ScadParam={key:string;value:string|number|boolean;options?:string[];min?:number;max?:number;step?:number;section:string;help:string};

export type ProductControl={
 key:string;label:string;help?:string;
 // A label that depends on the design (for example the opening a rack's module holds).
 labelFor?:(v:Values)=>string;
 // count: the range of the − and + buttons (1 to 12 when absent).
 min?:number;max?:number;
 // length: millimeters shown in the chosen units; count: whole numbers with − and + buttons.
 kind?:'length'|'number'|'count'|'choice'|'toggle';
 options?:Record<string,string>;
 advanced?:boolean;
 // Why the control does not apply to these values, or null when it does.
 when?:(v:Values)=>string|null;
};
export type ProductSection={id:string;title:string;blurb?:string;shop?:boolean;controls:ProductControl[];summary?:(v:Values,units:Units)=>string};
export type ProductStarter={id:string;name:string;description?:string;group?:string;values:Values};

// What the shared engine views need to run a design: the worker file name, its source
// with the settings applied, the extra engine files, and the outputs it supports.
export type EngineTarget={
 id:string;label:string;filename:string;
 sources:{name:string;text:string}[];
 source:(v:Values)=>string;
 validate:(v:Values)=>string[];
 renderModes:{id:string;label:string}[];
 exportModes:string[];
 // Editable project files (SCAD, design file, notes) added to downloads.
 projectFiles:(v:Values,name:string,units:Units)=>{name:string;data:string}[];
 // Printable assembly packet; the cabinet packet is used when absent.
 packet?:(name:string,v:Values,text:string,units:Units)=>string;
 // Sheet nesting and layout settings live in this section of the editor.
 sheetSection?:string;
 // A small test piece cut with the design's stock, clearances and cutter, offered on the
 // export page: its source has the same settings with the coupon chosen.
 coupon?:{label:string;note:string;source:(v:Values)=>string};
};

export type Product={
 id:string;name:string;sub:string;code:string;
 file:string;source:string;params:ScadParam[];
 // Shared engine modules the SCAD file `use`s, as keys of lib/engine-sources.json. They are
 // written next to the product under engine/ (the file includes ../../engine/<key>).
 engineIncludes?:string[];
 // Where the picker lists it ("Your products" when absent).
 area?:string;
 // START-HERE.txt of the OpenSCAD project download.
 startHere?:string;
 // A fit test coupon: the module_type value that builds it, and what it is for.
 coupon?:{module:string;label:string;note:string};
 sections:ProductSection[];
 starters:ProductStarter[];defaultStarter:string;
 renderModes:{id:string;label:string}[];exportModes:string[];
 validate:(v:Values)=>string[];
 // Settings that change together with another one (for example a tower choice that only
 // the Custom shape honours switches the shape to Custom).
 linked?:(key:string,value:unknown,v:Values)=>Values;
 // Headline figures for the summary bar.
 summary:(v:Values)=>{label:string;mm?:number;text?:string}[];
 assemblySteps:(v:Values)=>string[];
 coverage:{checked:string[];notChecked:string[]};
 sheetSection:string;
};
