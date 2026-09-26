#!/usr/bin/env python3
from pathlib import Path
import argparse, copy, json, re, sys
from .paths import SCAD_DIR, CONFIG_DIR
ROOT=CONFIG_DIR
CAT='hardware.json'; RES='hardware_resolved.json'; IDX='hardware_native_presets.json'
FRONTENDS={'utility':'utility.scad','shop_cart':'shop_cart.scad','benchtop':'benchtop.scad','stackable':'stackable.scad','kitchen':'kitchen.scad','drawer':'drawer.scad'}

def merge(a,b):
    o=copy.deepcopy(a)
    for k,v in b.items():
        if k=='extends': continue
        if isinstance(v,dict) and isinstance(o.get(k),dict): o[k]=merge(o[k],v)
        else:o[k]=copy.deepcopy(v)
    return o

def resolve(doc):
    ids=[p['id'] for p in doc['profiles']]
    if len(ids)!=len(set(ids)): raise ValueError('duplicate hardware profile id')
    raw={p['id']:p for p in doc['profiles']}; done={}; active=set()
    def one(pid):
        if pid in done:return done[pid]
        if pid not in raw:raise ValueError('unknown extends '+pid)
        if pid in active:raise ValueError('inheritance cycle '+pid)
        active.add(pid); p=raw[pid]; q=merge(one(p['extends']),p) if 'extends' in p else copy.deepcopy(p); q['id']=pid; done[pid]=q; active.remove(pid); return q
    return [one(p['id']) for p in doc['profiles']]

def public_names(path):
    names=set(); section=''
    for raw in path.read_text().splitlines():
        s=raw.strip(); m=re.match(r'/\* \[(.*?)\] \*/',s)
        if m: section=m.group(1); continue
        a=re.match(r'([A-Za-z_][A-Za-z0-9_]*)\s*=.*;',s)
        if a and section!='Hidden' and not section.startswith('Resolved'): names.add(a.group(1))
    return names

def validate(doc,ps,root):
    if doc.get('catalog_version')!=2 or doc.get('units')!='mm': raise ValueError('catalog_version=2 and units=mm required')
    ids=[p['id'] for p in ps]
    if len(ids)!=len(set(ids)):raise ValueError('duplicate id')
    pubs={k:public_names(SCAD_DIR/f) for k,f in FRONTENDS.items()}
    for p in ps:
        if p.get('category') not in {'drawer_slide','hinge'}:raise ValueError('bad category '+p['id'])
        status=p.get('geometry_support',{}).get('status','partial')
        if status not in {'native','partial','metadata_only'}:raise ValueError(f'{p["id"]}: bad geometry_support status {status}')
        if status=='metadata_only':
            if p.get('apply'):raise ValueError(f'{p["id"]}: metadata_only profile must not contain apply')
            if p.get('targets'):raise ValueError(f'{p["id"]}: metadata_only profile must not contain targets')
            continue
        if not p.get('apply'):raise ValueError('empty apply '+p['id'])
        for target in p.get('targets',[]):
            if target not in FRONTENDS:raise ValueError(f'{p["id"]}: bad target {target}')
            missing=[k for k in p['apply'] if k not in pubs[target]]
            if missing:raise ValueError(f'{p["id"]}: apply keys not public in {target}: {missing}')

def preset_value(v):
    if isinstance(v,bool):return 'true' if v else 'false'
    if v is None:return 'undef'
    if isinstance(v,(list,tuple)):return json.dumps(v,separators=(',',':'))
    return str(v)


def main():
    ap=argparse.ArgumentParser(); ap.add_argument('--root',type=Path,default=ROOT); ap.add_argument('--check',action='store_true'); a=ap.parse_args()
    doc=json.loads((a.root/CAT).read_text()); ps=resolve(doc); validate(doc,ps,a.root)
    if a.check:
        meta=sum(1 for p in ps if p.get('geometry_support',{}).get('status')=='metadata_only')
        print(f'OK: {len(ps)} hardware profiles ({len(ps)-meta} machining, {meta} metadata-only)'); return
    rd=copy.deepcopy(doc); rd['profiles']=ps; (a.root/RES).write_text(json.dumps(rd,indent=2)); idx={}
    print(f'Generated {RES}; profiles={len(ps)}')
if __name__=='__main__':
    try:main()
    except Exception as e:print('ERROR:',e,file=sys.stderr);raise
