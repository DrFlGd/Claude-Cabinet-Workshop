# Modular Organization v3 — Composition release

> Historical engine documentation. Applies to the version named below, not the current application. See the [documentation guide](../../docs/README.md) and [consolidated changelog](../../CHANGELOG.md).


V3 adds the first project-level assembly graph while keeping OpenSCAD as the geometry authority.

Highlights:

- MORG-1 versioned project JSON (`.morg`) plus JSON Schema.
- Module registry for website/configurator discovery.
- `MODULE|` envelope and `INTERFACE_FRAME|` physical frame records from OpenSCAD.
- Rigid `mate` relationships resolved from compatible interface contracts.
- `contains` relationships for nested organization modules.
- Derived multi-support `span_worktop` modules.
- Conservative project-level module-envelope collision checking.
- Optional per-module OpenSCAD STL rendering and generated assembly preview.
- Manufacturing package system contracts now include module/frame records.
- MOI-2 exhaustive compatibility and manufacturing-validation behavior retained.

V3 automatic mating is deliberately limited to translation and orthogonal Z rotation. General constraints, motion envelopes, structural analysis, and arbitrary mesh collision are future work.
