# Fork: Modular Storage v35 -> Modular Organization

Modular Organization is a deliberate fork of Modular Storage v35. The storage
line remains a cabinet/drawer generator; the organization line adds a public
physical-interface model so independently generated modules can declare how
they mate, what geometry they reserve, and which machining features they own.

The fork began at **Modular Organization v1 / MOI-1**. **Modular Organization
v2 / MOI-2** retains the same parent lineage but hardens compatibility and
validation after the first interface implementation exposed incomplete
signatures and bottom-only feature coverage.

## What remains inherited

The production foundation is still Modular Storage v35: the six frontends,
location-aware joinery, stack-safe tabs, open-edge dogbone/T-bone behavior,
hardware library, BOM/dimensions, nesting planner, and CUT / POCKET / ENGRAVE
manufacturing layouts.

## What the fork changes

The public model is:

```text
project -> assemblies -> parts -> interfaces -> features / keepouts
```

Machine-readable records include:

```text
SYSTEM
COMPAT
INTERFACE
KEEPOUT
FEATURE_OWNER
FEATURE
COVERAGE
EXPORT_FRAME
CHECK
```

The initial physical standards remain `MOI-STACK-1`, `MOI-GANG-1`,
`MOI-JOINT-1`, and `MOI-DRAWER-1`. MOI-2 uses key schema `KSV=2` and signs all
current geometry-driving fields for external interfaces.

## Current compatibility identity

```text
engine_family = modular_organization
engine_version = 2
forked_from = modular_storage_v35 / engine 35
interface_contract = MOI-2
```

The OpenSCAD output retains `API_COMPAT|MODULAR_STORAGE|...` so migration code
can identify the parent lineage. New integrations should consume the Modular
Organization identity, MOI records, and `COVERAGE|...` scope declarations.

## V2 validation boundary

OpenSCAD now maintains an exhaustive ledger of all current outer cabinet-side
holes, blind pockets, and carcass joints and performs depth-aware feature /
keepout and feature / feature checks. `modular_organization_validate.py`
independently audits every final contour emitted by CUT and all registered
POCKET modes. The manufacturing exporter runs that audit automatically.

This is exhaustive **within generated manufacturing geometry and current MOI
signatures**. It is not structural/load engineering, material-defect analysis,
or CAM/toolpath verification.

Future releases can extend the same model to wall rails, work surfaces, bins,
trays, accessory panels, casters, plinths, standardized mounting grids, and
room/project-level composition without another architecture reset.
