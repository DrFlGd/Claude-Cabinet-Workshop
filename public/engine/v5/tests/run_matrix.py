import concurrent.futures,json,time
from pathlib import Path
from modular_organization.validation import run_audit
from modular_organization.paths import FRONTENDS,SCAD_DIR
jobs=[]
for m,(scad,presets) in FRONTENDS.items():
 for preset in json.loads((SCAD_DIR/presets).read_text())['parameterSets']:jobs.append((m,preset,{}))
 for j in ('butt','screw','dado','tab_slot'):
  jobs.append((m,None,{'drawer_joinery_style' if m=='drawer' else 'joinery_style':j}))
def one(job):
 m,p,d=job;st=time.time()
 try:
  audit=run_audit(SCAD_DIR/FRONTENDS[m][0],param_json=SCAD_DIR/FRONTENDS[m][1] if p else None,preset=p,defines=[k+'='+json.dumps(v) for k,v in d.items()])
  out={'module':m,'preset':p,'parameters':d,'status':audit['status'],'summary':audit.get('summary',{}),'errors':[x for x in audit['issues'] if x['severity']=='ERROR'],'seconds':round(time.time()-st,2)}
 except Exception as exc:out={'module':m,'preset':p,'parameters':d,'status':'ERROR','errors':[str(exc)]}
 print(json.dumps(out),flush=True);return out
with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:results=list(pool.map(one,jobs))
(Path(__file__).resolve().parents[1]/'docs/validation_matrix.json').write_text(json.dumps(results,indent=2))
print('DONE',len(results),'errors',sum(x['status']=='ERROR' for x in results),flush=True)
