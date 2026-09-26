# Migration: Modular Organization v2 -> v3

> Historical engine documentation. Applies to the version named below, not the current application. See the [documentation guide](../../docs/README.md) and [consolidated changelog](../../CHANGELOG.md).


V3 is a composition-layer extension, not a geometry rewrite. Existing V2 cabinet/drawer parameters, manufacturing modes, MOI-STACK-1 / MOI-GANG-1 / MOI-JOINT-1 / MOI-DRAWER-1 standards, hardware profiles, and exhaustive manufacturing validation behavior are retained.

The engine/package filenames advance from `_v2` to `_v3`. The top-level interface contract advances from `MOI-2` to `MOI-3`; compatibility key schema remains KSV=2 because the physical stack/ganging key fields did not change.

New machine-readable records are `MODULE|` and `INTERFACE_FRAME|`. Consumers that ignore unknown record prefixes continue to work. Consumers that check the top-level contract ID should accept `MOI-3`.

V3 adds the separate MORG-1 project graph. Existing single-module OpenSCAD workflows do not need to adopt `.morg` projects.
