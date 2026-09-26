import copy
import json
import subprocess
import unittest
from pathlib import Path
from unittest.mock import patch
from modular_organization import api
from modular_organization.configuration import compile_config, validate_project
from modular_organization.paths import FRONTENDS
from modular_organization.nesting import Part, Rect, nest_parts, _split_free_rectangles
from modular_organization.runtime import run_scad

ROOT = Path(__file__).resolve().parents[1]

class BoundaryTests(unittest.TestCase):
    def test_fractional_stock_all_frontends(self):
        for name in FRONTENDS:
            with self.subTest(name=name):
                c=compile_config(name,common={'material_thickness':18.35,'joinery':'screw'})
                self.assertIn(18.35,c['parameters'].values())
    def test_reject_unknown_frontend(self):
        with self.assertRaises(ValueError):compile_config('../utility')
    def test_reject_raw_expression(self):
        with self.assertRaises(ValueError):compile_config('equipment_stand',parameters={'material_thickness':'18;echo(1)'})
    def test_reject_nonfinite(self):
        with self.assertRaises(ValueError):compile_config('equipment_stand',common={'material_thickness':float('nan')})
    def test_reject_operation_override(self):
        with self.assertRaises(ValueError):compile_config('utility',parameters={'output_mode':'assembly'})
    def test_reject_conflicting_aliases(self):
        with self.assertRaises(ValueError):compile_config('equipment_stand',common={'joinery':'screw'},parameters={'joinery_style':'butt'})
    def test_legacy_joinery(self):
        c=compile_config('equipment_stand',parameters={'joinery_type':'tab_slot'})
        self.assertEqual(c['parameters']['joinery_style'],'tab_slot');self.assertTrue(c['warnings'])
    def test_schema_copy(self):
        a=api.describe();a['frontends'].clear();self.assertEqual(len(api.describe()['frontends']),7)
    def test_zero_exit_renderer_error(self):
        with patch('modular_organization.runtime.subprocess.run',return_value=subprocess.CompletedProcess([],0,'','ERROR: invalid')):
            self.assertNotEqual(run_scad(['openscad']).returncode,0)
    def test_timeout(self):
        with patch('modular_organization.runtime.subprocess.run',side_effect=subprocess.TimeoutExpired('openscad',1)):
            with self.assertRaises(RuntimeError):run_scad(['openscad'])
    def test_project_traversal(self):
        p=json.loads((ROOT/'examples/workbench_pair.morg').read_text());p['modules'][0]['id']='../escape'
        with self.assertRaises(ValueError):validate_project(p)
    def test_duplicate_ids(self):
        p=json.loads((ROOT/'examples/workbench_pair.morg').read_text());p['modules'][1]['id']=p['modules'][0]['id']
        with self.assertRaises(ValueError):validate_project(p)

class NestingTests(unittest.TestCase):
    def test_exact_fit(self):
        sheets,oversize=nest_parts([Part('a','ply',18,100,100)],100,100,0,6)
        self.assertFalse(oversize);self.assertEqual(len(sheets),1)
    def test_duplicate_free_rectangles(self):
        self.assertEqual(len(_split_free_rectangles([Rect(0,0,10,10)]*2,Rect(20,20,1,1))),1)
    def test_invalid_dimensions(self):
        with self.assertRaises(ValueError):nest_parts([Part('a','ply',18,float('nan'),10)])
    def test_placement_bounds_and_separation(self):
        sheets,oversize=nest_parts([Part(str(i),'ply',18,30,20) for i in range(12)],100,100,5,3)
        self.assertFalse(oversize)
        for sheet in sheets:
            for i,a in enumerate(sheet.placements):
                self.assertLessEqual(a.x+a.width,95);self.assertLessEqual(a.y+a.height,95)
                for b in sheet.placements[i+1:]:
                    self.assertTrue(a.x+a.width+3<=b.x or b.x+b.width+3<=a.x or a.y+a.height+3<=b.y or b.y+b.height+3<=a.y)

class EngineTests(unittest.TestCase):
    def test_all_frontends_fractional_screw_metadata(self):
        for name in FRONTENDS:
            with self.subTest(name=name):
                r=api.inspect(name,common={'material_thickness':18.35,'joinery':'screw'})
                self.assertNotEqual(r['status'],'ERROR',r['checks']);self.assertTrue(r['bom']);self.assertFalse(r['runtime_warnings'])
    def test_project_examples_and_immutability(self):
        for path in (ROOT/'examples').glob('*.morg'):
            with self.subTest(path=path.name):
                p=json.loads(path.read_text());before=copy.deepcopy(p);r=api.compose(p)
                self.assertEqual(r['summary']['errors'],0,r);self.assertEqual(p,before)
    def test_saved_matrix(self):
        matrix=json.loads((ROOT/'docs/validation_matrix.json').read_text())
        self.assertEqual(len(matrix),82);self.assertFalse([x for x in matrix if x['status']=='ERROR'])

if __name__=='__main__':unittest.main()
