# Review and changes

> Historical verification/change record for the stated package or patch. Results are not a fresh validation of subsequent changes. For current API and machining behavior see [Integration](INTEGRATION.md) and [Machining](MACHINING.md).

The review covered the seven frontend definitions, shared CAD geometry, preset and hardware catalogs, Python scripts, export flow, project composition, schema generation and package layout.

| Finding | Change |
|---|---|
| Fractional thickness controls inconsistent | Explicit decimal controls and common stock normalization across all seven modules |
| Butt/screw labels and machining differ | Distinct semantics, shared carcass mapping, drawer screw guides and equipment alias migration |
| Stackable bottom dado intersects stacking shoulders | Raised the dado-jointed bottom above reserved geometry; retained the validation check |
| Duplicate tab-slot geometry logic | Shared joinery primitives between core and equipment |
| Scripts depend on loose directory layout | Installable package, centralized resource paths and relative imports |
| OpenSCAD may return zero on errors; renders unbounded | Shared error detection and per-process timeout |
| Project preset name diverged from parameter writer | Unified Request preset; examples verified against effective configuration |
| Project input could be mutated; IDs used in paths | Deep copy, schema/type validation, safe IDs, duplicate/cycle/reference checks |
| Fractional rotations silently truncated | Reject non-integer orthogonal rotations |
| Incomplete interface records could match | Require identity, standard and role |
| Duplicate hardware IDs overwritten | Fail explicitly during resolution |
| Nesting exact-fit parts rejected; duplicate free areas deleted | Correct edge-gap handling and duplicate rectangle pruning |
| Invalid BOM dimensions/quantities silently tolerated | Explicit failures and correct zero-quantity handling |
| DXF arc bulges/unknown geometry under-audited | Expand bulges and reject unsupported entities/empty CUT layouts |
| Failed export could replace good output | Audit gate and unique temporary publication directory; atomic replacement |
| Repeated historical data and preset copies | Lean source tree with native design presets and catalog-driven hardware |

## Intentional feature differences

| Family | Joinery control | Back/brace features | Specialized interfaces |
|---|---|---|---|
| Cabinets/cart/bench/stackable/kitchen | Carcass plus separate drawer controls | Frontend-specific cabinet back modes | Stack/gang/worktop and cabinet features where supported |
| Standalone drawer | Drawer control | Drawer bottom and organizer, no cabinet back | Drawer/organizer |
| Equipment stand | Frame control | Full back, panel back, stretchers | Equipment tray, French cleat, floor and equipment stack |

The schema reports capabilities rather than pretending every module supports every feature. The shared core remains substantial because interface contracts, dimensions and manufacturing features depend on the same resolved geometry; splitting it further requires a separate compatibility effort.

## Remaining limits

Validation establishes geometric/manufacturing checks, not structural certification. Slide rating, wall fasteners, tip resistance and equipment motion require application-specific engineering. Nesting plans use bounding rectangles, not optimized contour toolpaths. CNC feed/speed, compensation and fixturing remain CAM responsibilities. Automated coverage is finite (presets and joint modes), not proof of every parameter combination. Website deployment and resource isolation belong to the integrating application. Existing source provenance/licensing must be reviewed before redistribution.

## 5.3 organization follow-up

All native frontends and generated web controls now share the ordered section contract in `parameter_layout.json`. Hardware categories are separated, machining controls are grouped by their actual scope, and derived internal code is hidden. Schema generation enforces shared-ID grouping, recognized section order and unique public IDs. PARAMETER_CONVENTIONS.md defines the required pattern for future modules.
