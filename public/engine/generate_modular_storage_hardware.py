#!/usr/bin/env python3
from pathlib import Path
import argparse, copy, json, re, sys
ROOT=Path(__file__).resolve().parent
CAT='modular_storage_hardware_v2.json'; RES='modular_storage_hardware_resolved_v2.json'; IDX='modular_storage_hardware_native_presets_v2.json'
FRONTENDS={'utility':'modular_storage_utility_v32.scad','shop_cart':'modular_storage_shop_cart_v32.scad','benchtop':'modular_storage_benchtop_v32.scad','stackable':'modular_storage_stackable_v32.scad','kitchen':'modular_storage_kitchen_v32.scad','drawer':'modular_storage_drawer_v32.scad'}

def merge(a,b):
    o=copy.deepcopy(a)
    for k,v in b.items():
        if k=='extends': continue
        if isinstance(v,dict) and isinstance(o.get(k),dict): o[k]=merge(o[k],v)
        else:o[k]=copy.deepcopy(v)
    return o

def resolve(doc):
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
    pubs={k:public_names(root/f) for k,f in FRONTENDS.items()}
    for p in ps:
        if p.get('category') not in {'drawer_slide','hinge'}:raise ValueError('bad category '+p['id'])
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

def build_native(root,ps):
    idx={'catalog_version':2,'semantics':'one-time editable hardware patches','frontends':{}}
    for kind,fn in FRONTENDS.items():
        jp=root/fn.replace('.scad','.json'); d=json.loads(jp.read_text()); sets=d.setdefault('parameterSets',{})
        for n in list(sets):
            if n.startswith('Slide — ') or n.startswith('Hinge — '): del sets[n]
        added={}
        for p in ps:
            if kind not in p.get('targets',[]):continue
            prefix='Slide' if p['category']=='drawer_slide' else 'Hinge'
            name=f'{prefix} — {p["label"]}'
            sets[name]={k:preset_value(v) for k,v in p['apply'].items()}; added[name]=p['id']
        jp.write_text(json.dumps(d,indent=2))
        idx['frontends'][kind]={'scad':fn,'preset_file':jp.name,'hardware_sets':added}
    (root/IDX).write_text(json.dumps(idx,indent=2)); return idx

def main():
    ap=argparse.ArgumentParser(); ap.add_argument('--root',type=Path,default=ROOT); ap.add_argument('--check',action='store_true'); a=ap.parse_args()
    doc=json.loads((a.root/CAT).read_text()); ps=resolve(doc); validate(doc,ps,a.root)
    if a.check: print(f'OK: {len(ps)} hardware patches'); return
    rd=copy.deepcopy(doc); rd['profiles']=ps; (a.root/RES).write_text(json.dumps(rd,indent=2)); idx=build_native(a.root,ps)
    print(f'Generated {RES}, {IDX}; profiles={len(ps)}')
if __name__=='__main__':
    try:main()
    except Exception as e:print('ERROR:',e,file=sys.stderr);raise
