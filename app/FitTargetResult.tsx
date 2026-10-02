'use client';
import {LoaderCircle} from 'lucide-react';
import {Values} from '@/lib/cabinet';
import {Units,formatShop} from '@/lib/units';
import type {Analysis} from './useEngineAnalysis';
// Fitted sizing is solved by OpenSCAD. The background engine check already returns the TARGET record,
// so the result appears automatically after each edit instead of behind a separate button.
export function solvedDimensions(family:number,analysis:Analysis):Record<string,number>|null{
 const p=analysis.plan;
 if(!p||analysis.planKey!==analysis.key)return null;
 if(family===6)return p.outside?{RESOLVED_CABINET_W:p.outside.w,RESOLVED_CARCASS_D:p.outside.d,RESOLVED_FINISHED_D:p.outside.d,RESOLVED_CABINET_H:p.outside.h}:null;
 const t=p.target;
 if(!t)return null;
 if(family===5)return {...t,RESOLVED_CABINET_W:t.OUTSIDE_W,RESOLVED_CARCASS_D:t.OUTSIDE_D,RESOLVED_FINISHED_D:t.OUTSIDE_D,RESOLVED_CABINET_H:t.OUTSIDE_H,ACHIEVED_W:t.INSIDE_W,ACHIEVED_D:t.INSIDE_D};
 return ['RESOLVED_CABINET_W','RESOLVED_CARCASS_D','ACHIEVED_W','ACHIEVED_D'].every(k=>Number.isFinite(t[k]))?t:null;
}
export default function FitTargetResult({family,values,units,analysis}:{units:Units;family:number;values:Values;analysis:Analysis}){
 const active=family>=5||values.width_basis==='drawer_inside'||values.depth_basis==='drawer_inside';
 if(!active)return null;
 const r=solvedDimensions(family,analysis),f=(n:number)=>formatShop(n,units)+(units==='mm'?' mm':'');
 const busy=analysis.state==='waiting'||analysis.state==='running';
 return <div className='fit-result' role='status'>
  {!r?<p>{busy?<><LoaderCircle size={14} className='render-spinner'/> Solving the fitted size with OpenSCAD…</>:analysis.error||'The engine did not return a fitted size for these settings.'}</p>
  :family===5?<p><strong>Drawer box</strong> outside {f(r.OUTSIDE_W)} W × {f(r.OUTSIDE_H)} H × {f(r.OUTSIDE_D)} D · usable inside {f(r.INSIDE_W)} × {f(r.INSIDE_H)} × {f(r.INSIDE_D)}. The enclosure is reference only.</p>
  :family===6?<p><strong>Frame</strong> {f(r.RESOLVED_CABINET_W)} W × {f(r.RESOLVED_CABINET_H)} H × {f(r.RESOLVED_CARCASS_D)} D, solved around the equipment.</p>
  :<>
   <p><strong>Fitted cabinet</strong> {f(r.RESOLVED_CABINET_W)} W × {f(values.cabinet_height)} H × {f(r.RESOLVED_FINISHED_D??r.RESOLVED_CARCASS_D)} D</p>
   <table className='fit-comparison'><thead><tr><th>Drawer inside</th><th>Requested</th><th>Achieved</th></tr></thead><tbody>
    {([['Width','REQUESTED_W','ACHIEVED_W','width_basis'],['Depth','REQUESTED_D','ACHIEVED_D','depth_basis']] as const).map(([t,req,ach,basis])=><tr key={t}>
     <td>{t}</td><td>{values[basis]==='drawer_inside'&&Number.isFinite(r[req])?f(r[req]):'Outside sizing'}</td><td>{f(r[ach])}</td>
    </tr>)}
   </tbody></table>
  </>}
 </div>;
}
