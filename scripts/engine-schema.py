#!/usr/bin/env python3
"""Keep every generated copy of the engine's settings in step with the SCAD front ends.

The OpenSCAD Customizer annotations of each front end (public/engine/v5/.../scad/<name>.scad)
are the source of truth. Three files are generated from them:

  public/engine/v5/src/modular_organization/data/config/schema.json
      the Python package's schema, exactly as `modular_organization.schema.build()` writes it;
  public/engine/v5/tests/parameter_contract.json
      the package's hash of every front end's defaults, ranges and options;
  lib/schema.json
      the app's settings: each field's default, formula, section, description, options,
      range and visibility rule, and every starter built from the engine presets.

`--check` (CI) fails when any of them differs from what the sources produce; `--write`
regenerates them. Presentation the app adds on its own (units, input steps, which settings
are advanced, curated starters and recipes) is kept as it is; new settings get the same
defaults the original import gave them. Products (public/products/**) read their settings
straight from their SCAD files at run time, so they have no generated copy to keep in step.
"""
import argparse, copy, hashlib, json, re, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PKG = ROOT / 'public/engine/v5'
sys.path.insert(0, str(PKG / 'src'))
from modular_organization.schema import build, parse_frontend  # noqa: E402
from modular_organization.paths import SCAD_DIR, CONFIG_DIR, FRONTENDS  # noqa: E402

CONFIG = CONFIG_DIR / 'schema.json'
CONTRACT = PKG / 'tests/parameter_contract.json'
APP = ROOT / 'lib/schema.json'
# Settings the app adds to a front end (the drawer engine reads it but does not list it).
APP_ONLY = {'drawer': {'slot_corner_relief'}}
ADVANCED_GROUPS = ['System / Reports', 'System / Interface Validation', 'Output / Export Registration', 'Hardware / Slide Drilling',
                   'Hardware / Frame Fasteners', 'Hardware / Drawer Fasteners', 'Hardware / Cleat Fasteners', 'Structure / Tab Placement']
CONTRACT_KEYS = ('value', 'expression', 'section', 'description', 'options', 'bounds', 'visibleIf')


def contract_digests():
    out = {}
    for name in FRONTENDS:
        parameters = parse_frontend(SCAD_DIR / FRONTENDS[name][0])
        signature = {p['id']: {k: p[k] for k in ('default', 'default_expression', 'range', 'enum') if k in p} for p in parameters}
        out[name] = hashlib.sha256(json.dumps(signature, sort_keys=True).encode()).hexdigest()
    return out


def contract_of(p, frontend):
    """The app field properties that must equal the engine's (as the original import mapped them)."""
    r = p.get('range')
    options = p.get('enum')
    if p['id'] == 'output_mode' and frontend['capabilities'].get('flat_3d') and options is not None and 'flat_3d' not in options:
        options = options + ['flat_3d']
    return dict(value=p['default'], expression=p.get('default_expression'), section=p['group'], description=p.get('description', ''),
                options=options, bounds=[r['min'], r['max'], r.get('step', p.get('step', 1))] if r else None, visibleIf=p.get('visible_if'))


def new_field(p, frontend):
    key, unit = p['id'], p.get('unit')
    if unit is None:
        unit = 'mm' if (p['type'] in ['number', 'array'] or p.get('default_expression')) and not re.search(
            r'count|columns|rows|index|weights|(?:^|_)ratios?(?:_|$)|factor|angle|_kg$|circle_segments|graduated_step|^target_drawer_bank$|types|styles|modes|sides', key) else 'scalar'
    c = contract_of(p, frontend)
    return dict(key=key, value=c['value'], expression=c['expression'], section=c['section'], description=c['description'], options=c['options'],
                bounds=c['bounds'], step=p.get('step'), unit=unit, visibleIf=c['visibleIf'], advanced=p['group'] in ADVANCED_GROUPS)


def typed(value, field):
    if not isinstance(value, str) or field is None or field['options'] is not None or isinstance(field['value'], str):
        return value
    return json.loads(value)


def sync_entry(entry, frontend, kind):
    """Bring one app entry's fields and starters in line with the engine; presentation is kept."""
    entry = copy.deepcopy(entry)
    old_base = next((s['values'] for s in entry['starters'] if s['id'] == entry.get('defaultStarter', 'default')), {})
    have = {f['key']: f for f in entry['fields']}
    params = frontend['parameters']
    keep = APP_ONLY.get(kind, set())
    fields = []
    for p in params:
        f = have.get(p['id'])
        if f is None:
            f = new_field(p, frontend)
        else:
            f.update(contract_of(p, frontend))
        fields.append(f)
    # app-only settings stay after the engine setting they followed
    for i, f in enumerate(entry['fields']):
        if f['key'] in keep:
            before = next((g['key'] for g in reversed(entry['fields'][:i]) if g['key'] not in keep), None)
            at = next((j + 1 for j, g in enumerate(fields) if g['key'] == before), len(fields))
            fields.insert(at, f)
    # keep the app's order for settings it already had; new ones follow the engine setting before them
    order = {f['key']: i for i, f in enumerate(entry['fields'])}
    placed = [f for f in fields if f['key'] in order]
    placed.sort(key=lambda f: order[f['key']])
    for i, f in enumerate(fields):
        if f['key'] in order:
            continue
        prev = next((g['key'] for g in reversed(fields[:i]) if g in placed), None)
        at = next((j + 1 for j, g in enumerate(placed) if g['key'] == prev), 0)
        placed.insert(at, f)
    entry['fields'] = placed
    entry['groups'] = frontend['groups']
    entry['capabilities'] = frontend['capabilities']
    by_key = {f['key']: f for f in placed}
    base = {f['key']: f['value'] for f in placed}
    presets = json.loads((SCAD_DIR / frontend['file'].replace('.scad', '.json')).read_text())['parameterSets']
    preset_group = next((s.get('group') for s in entry['starters'] if s['name'] in presets), 'Engine presets')
    starters = []
    for s in entry['starters']:
        s = copy.deepcopy(s)
        if s['id'] == entry.get('defaultStarter', 'default'):
            s['values'] = dict(base)
        elif s['name'] in presets:
            s['values'] = {**base, **{k: typed(v, by_key.get(k)) for k, v in presets[s['name']].items() if k in by_key}}
        elif old_base and all(k in s['values'] for k in old_base):
            # a full starter: its own settings over the current defaults
            s['values'] = {**base, **{k: v for k, v in s['values'].items() if k in base and (k not in old_base or v != old_base[k])}}
        else:
            s['values'] = {k: v for k, v in s['values'].items() if k in base}
        starters.append(s)
    for name, patch in presets.items():
        if any(s['name'] == name for s in starters):
            continue
        starters.append(dict(id=kind + '_' + re.sub('[^a-z0-9]+', '_', name.lower()).strip('_'), name=name,
                             values={**base, **{k: typed(v, by_key.get(k)) for k, v in patch.items() if k in by_key}}, group=preset_group))
    entry['starters'] = starters
    return entry


def generate():
    config = build(SCAD_DIR)
    app = json.loads(APP.read_text())
    out = []
    for entry in app:
        kind = entry['id']
        if kind not in config['frontends']:
            raise SystemExit(f'lib/schema.json lists {kind}, which the engine package does not register')
        out.append(sync_entry(entry, config['frontends'][kind], kind))
    missing = [k for k in config['frontends'] if k not in {e['id'] for e in app}]
    if missing:
        raise SystemExit('Engine front ends missing from lib/schema.json: ' + ', '.join(missing))
    return config, contract_digests(), out


def describe(old, new, path='', limit=12):
    """A few human-readable differences between two JSON values."""
    out = []
    def walk(a, b, p):
        if len(out) >= limit or a == b:
            return
        if isinstance(a, dict) and isinstance(b, dict):
            for k in list(a) + [k for k in b if k not in a]:
                walk(a.get(k), b.get(k), f'{p}.{k}')
        elif isinstance(a, list) and isinstance(b, list) and all(isinstance(x, dict) for x in a + b) and len(a + b):
            ka = {x.get('id', x.get('key')): x for x in a}
            kb = {x.get('id', x.get('key')): x for x in b}
            if None in ka or None in kb:
                out.append(p)
                return
            for k in list(ka) + [k for k in kb if k not in ka]:
                walk(ka.get(k), kb.get(k), f'{p}[{k}]')
            if len(out) < limit and [x for x in ka if x in kb] != [x for x in kb if x in ka]:
                out.append(p + ' (order)')
        else:
            out.append(f'{p}: {json.dumps(a)[:90]} -> {json.dumps(b)[:90]}')
    walk(old, new, path)
    return out


def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    mode = ap.add_mutually_exclusive_group(required=True)
    mode.add_argument('--check', action='store_true', help='fail when a generated file is stale')
    mode.add_argument('--write', action='store_true', help='regenerate the files')
    a = ap.parse_args()
    config, contract, app = generate()
    targets = [(CONFIG, config, json.dumps(config, indent=2)), (CONTRACT, contract, json.dumps(contract, indent=2) + '\n'),
               (APP, app, json.dumps(app, indent=2))]
    stale = []
    for path, value, text in targets:
        if path.read_text() == text:
            continue
        stale.append(path)
        if a.write:
            path.write_text(text)
        else:
            print(f'{path.relative_to(ROOT)} is stale:')
            for line in describe(json.loads(path.read_text()), value, path.name):
                print('  ' + line)
    if a.check and stale:
        print('Run: python3 scripts/engine-schema.py --write (then node scripts/sync-engine-sources.mjs)')
        sys.exit(1)
    print(('Updated ' + ', '.join(str(p.relative_to(ROOT)) for p in stale)) if a.write and stale else
          'Engine schema, parameter contract and lib/schema.json match the SCAD front ends.' if not stale else '')


if __name__ == '__main__':
    main()
