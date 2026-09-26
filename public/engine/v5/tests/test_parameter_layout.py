"""Conventions required of each registered frontend, including future additions."""
import hashlib
import json
import re
import unittest
from pathlib import Path
from modular_organization.schema import build, parse_frontend
from modular_organization.paths import SCAD_DIR, CONFIG_DIR, FRONTENDS

ROOT=Path(__file__).resolve().parents[1]

class ParameterLayoutTests(unittest.TestCase):
    def test_schema_matches_sources_and_layout(self):
        generated=build(SCAD_DIR)
        self.assertEqual(generated,json.loads((CONFIG_DIR/'schema.json').read_text()))
        for name,frontend in generated['frontends'].items():
            with self.subTest(frontend=name):
                raw=parse_frontend(SCAD_DIR/FRONTENDS[name][0])
                self.assertEqual([(p['id'],p['group']) for p in raw],[(p['id'],p['group']) for p in frontend['parameters']])
                self.assertTrue(frontend['groups'][0].startswith('Materials /'))
                self.assertEqual(next(p['group'] for p in raw if p['id']=='output_mode'),'Output / View')
    def test_preserved_parameter_contract(self):
        baseline=json.loads((ROOT/'tests/parameter_contract.json').read_text())
        for name in FRONTENDS:
            parameters=parse_frontend(SCAD_DIR/FRONTENDS[name][0])
            signature={p['id']:{k:p[k] for k in ('default','default_expression','range','enum') if k in p} for p in parameters}
            digest=hashlib.sha256(json.dumps(signature,sort_keys=True).encode()).hexdigest()
            self.assertEqual(digest,baseline[name],name)
    def test_hardware_and_relief_categories(self):
        for name in FRONTENDS:
            for p in parse_frontend(SCAD_DIR/FRONTENDS[name][0]):
                if p['id'].startswith('hinge_'):self.assertEqual(p['group'],'Hardware / Hinges')
                if p['id']=='slot_corner_relief':self.assertEqual(p['group'],'Machining / Shared Slot Relief')
                if p['id']=='side_relief':self.assertEqual(p['group'],'Machining / Side Panels')
                if p['id'] in ('router_bit_diameter','cnc_tool_diameter'):self.assertEqual(p['group'],'Machining / Tool and Kerf')
                self.assertNotIn('Hidden',p['group'])
    def test_no_function_definitions_before_public_controls(self):
        for name in FRONTENDS:
            source=(SCAD_DIR/FRONTENDS[name][0]).read_text()
            first=re.search(r'^(?:function|module)\s',source,re.M)
            if first:
                self.assertFalse(re.search(r'/\* \[(?!Hidden\])[^]]+\] \*/',source[first.start():]),name)
