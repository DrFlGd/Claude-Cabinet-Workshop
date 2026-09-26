# Modular Organization v3

Modular Organization v3 is the first **composition release** of the fork that began from Modular Storage v35. V1 introduced physical interfaces; V2 hardened compatibility signatures and exhaustive manufacturing validation; V3 adds a versioned project graph and a resolver that can compose multiple independently generated modules without moving geometry authority out of OpenSCAD.

## Architecture

V3 deliberately separates responsibilities:

- **Project/web layer:** module identity, relationships, transforms, project state, and future undo/redo or constraint solving.
- **Resolver (`modular_organization_project.py`):** compiles a `.morg` graph, asks OpenSCAD for module/interface contracts, verifies compatibility, resolves placement, and emits a resolved project plus assembly preview.
- **OpenSCAD:** remains authoritative for cabinet/drawer geometry, physical interface signatures, feature/keepout validation, BOM, CUT/POCKET/ENGRAVE outputs, and per-module manufacturing geometry.

The project model is therefore:

```text
project -> modules + relationships -> parts -> interfaces + frames -> features / keepouts
```

## MORG-1 project format

`modular_organization_project_schema_v3.json` defines the first project format, **MORG-1**. The package also includes `modular_organization_module_registry_v3.json` for web/configurator discovery.

V3 supports these module types:

- `openscad`: any of the six existing Modular Organization frontends;
- `box`: a project-layer rectangular primitive; and
- `span_worktop`: a derived worktop sized across already-resolved support modules.

V3 supports these graph relationships:

- `mate`: connects two compatible external OpenSCAD interfaces and resolves placement from their interface frames;
- `contains`: places a child module at a parent-local offset and records that overlap as intentional.

The included `examples/workbench_pair_v3.morg` demonstrates two stackable cabinets ganged together, a standalone drawer contained in the left cabinet, and one derived worktop spanning both cabinets.

## MOI-3 interface contract

MOI-3 retains the complete MOI-2 geometry signatures and validation coverage and adds two composition records:

```text
MODULE|KIND=...|W=...|D=...|H=...|COORD=...
INTERFACE_FRAME|ID=...|OX=...|OY=...|OZ=...|UX=...|...|NZ=...
```

`MODULE` gives the resolver a conservative module envelope. `INTERFACE_FRAME` gives each external stack/ganging interface a module-local origin, two in-plane axes, and an outward normal. The resolver compares the existing `STANDARD`, mating `ROLE`, and full compatibility `KEY` before it is allowed to use a frame.

This means a side-gang connection with 6 mm and 10 mm dowels still fails before placement, while matching interfaces can determine the adjacent module transform automatically.

### Placement scope

V3 automatically resolves **translation plus orthogonal Z rotation** (`0/90/180/270`). It does not claim arbitrary 3-D mating yet. That limitation is explicit in `project_health.json`; incompatible or unsupported relationships fail instead of being approximated.

## Project resolver

Resolve the example without rendering expensive STL geometry:

```bash
python modular_organization_project.py \
  examples/workbench_pair_v3.morg \
  -o build/workbench
```

This writes:

```text
resolved_project.json
project_health.json
assembly_preview.scad
```

The preview uses resolved module envelopes by default, which is fast and useful for a website/service integration test.

Use `--render-modules` when true OpenSCAD assembly STL geometry is wanted. That mode renders each generated module separately and builds an import-based combined assembly preview; complex cabinets can take substantially longer than the contract-only project pass.

## Validation semantics

V3 preserves the V2 rule that **green does not imply more coverage than the report actually performed**.

Project Health covers:

- MORG-1 graph structure and resolution;
- OpenSCAD semantic/Design Health checks from every generated module;
- complete current MOI stack/ganging compatibility keys;
- interface-frame mating/alignment;
- support-height checks for derived worktops; and
- conservative project-level module AABB overlap detection.

Per-module final CUT/POCKET contour validation remains the responsibility of `modular_organization_validate.py` or `modular_organization_export_package.py`, which performs the exhaustive manufacturing-geometry audit introduced in V2. V3 does **not** claim structural/load analysis, CAM/toolpath verification, arbitrary mesh-vs-mesh assembly collision, or motion-envelope validation.

## Manufacturing workflow

The existing manufacturing exporter remains available:

```bash
python modular_organization_export_package.py \
  modular_organization_stackable_v3.scad \
  --json modular_organization_stackable_v3.json \
  --preset "2 Drawer" \
  -o two_drawer_stackable.zip
```

Its `system_contract.json` now also captures `MODULE` and `INTERFACE_FRAME` records in addition to interfaces, keepouts, features, and coverage statements.

## Main files

```text
modular_organization_project.py
modular_organization_project_schema_v3.json
modular_organization_module_registry_v3.json
modular_organization_interface_contract_v3.json
examples/workbench_pair_v3.morg

modular_organization_core_v3.scad
modular_organization_layouts_v3.scad
modular_organization_utility_v3.scad
modular_organization_shop_cart_v3.scad
modular_organization_benchtop_v3.scad
modular_organization_stackable_v3.scad
modular_organization_kitchen_v3.scad
modular_organization_drawer_v3.scad

modular_organization_schema_v3.json
modular_organization_hardware_v3.json
modular_organization_nest.py
modular_organization_validate.py
modular_organization_export_package.py
```

See `MIGRATION_V2_TO_V3.md`, `RELEASE_V3.md`, and `VALIDATION_V3.txt` for the exact delta and regression checks.
