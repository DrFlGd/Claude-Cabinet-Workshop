# Modular Organization 5.3

Parametric cabinetry, drawers and pull-out equipment stands, with OpenSCAD geometry and a Python integration API. Seven frontends share manufacturing, validation, hardware and composition services.

## Install

Install OpenSCAD on the worker host and ensure `openscad` is on PATH. Use Python 3.10 or newer, then from this directory:

```sh
python -m pip install .
modular-organization schema -o schema.json
modular-organization inspect --request examples/equipment_request.json -o inspection.json
modular-organization manufacture --request examples/equipment_request.json -o manufacturing.zip
```

OpenSCAD is a separate executable dependency. Python dependencies are declared in `pyproject.toml`. Development verification used Python 3.12 and OpenSCAD 2021.01; other supported Python versions need your CI verification.

## Python API

```python
from modular_organization import api

request = {
    "frontend": "equipment_stand",
    "common": {"material_thickness": 18.35, "tray_thickness": 15.25,
               "joinery": "tab_slot"},
}
inspection = api.inspect(**request)
if inspection["status"] != "ERROR":
    api.preview(output="preview.stl", **request)
    api.manufacture(output="manufacturing.zip", **request)
```

Use `api.describe()` for frontend parameters, capabilities and presets. Use `api.compose(project_json)` for MORG-1 composition. PASS/WARN/ERROR indicate geometric checks; review WARN records. A successful inspection is not a replacement for the full manufacturing audit.

## Package organization

- `src/modular_organization/api.py`: website-facing entrypoints.
- `configuration.py`, `schema.py`, `runtime.py`, `paths.py`: typed requests, UI schema, bounded renderer invocation and resources.
- `project.py`, `interfaces.py`: composition and compatibility.
- `bom.py`, `validation.py`, `export.py`, `nesting.py`: production outputs and checks.
- `hardware.py`, `equipment_hardware.py`: hardware catalog resolution.
- `data/scad/`: seven frontends, companion presets, shared geometry. `core/` separates resolution/contracts, frame geometry and drawer geometry.
- `data/config/`: schema, contracts, module registry and hardware catalogs.
- `examples/`, `tests/`, `docs/`: integration inputs, regressions and review evidence.

OpenSCAD Customizer users can open frontends in `data/scad/` directly. Keep their relative includes and companion JSON files together.

## Verification

```sh
python -m unittest discover -s tests -v
python tests/run_matrix.py
python -m modular_organization.hardware --check
```

The matrix regenerates 82 manufacturing audits and requires OpenSCAD. It is more expensive than the regression suite. See [review](docs/REVIEW.md), [integration](docs/INTEGRATION.md), [migration](docs/MIGRATION.md) and [machining](docs/MACHINING.md).

No structural certification or engineering load guarantee is provided by these geometric checks. Confirm material, hardware, loads and installation for the intended use. Distribution licensing and ownership should be confirmed before public publication; this cleanup does not assign a new license.

Parameter sections are now consistent in native OpenSCAD and web schema. See [parameter conventions](docs/PARAMETER_CONVENTIONS.md) for the standard required of future modules.
