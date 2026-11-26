// Instant drawings per product, shown in the product editor's Drawing tab. A product
// without one opens on its 3D model instead.
import type {ComponentType} from 'react';
import type {Values} from '@/lib/cabinet';
import type {Units} from '@/lib/units';
import MediaCartDiagram from './MediaCartDiagram';
// records: the latest engine check's records (joinery, stability), stale while a newer check
// runs for the current values.
export type DiagramProps={values:Values;units:Units;change:(key:string,value:unknown)=>void;focus:(section:string)=>void;records?:string[];stale?:boolean};
export const diagrams:Record<string,ComponentType<DiagramProps>>={media_cart:MediaCartDiagram};
