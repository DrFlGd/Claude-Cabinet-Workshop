# Parameter organization standard — version 1

All seven native OpenSCAD frontends and the generated schema use the native section contract. The Cabinet Workshop web adapter intentionally regroups some controls as described below. `data/config/parameter_layout.json` defines the ordered vocabulary. Omit sections that do not apply; do not invent controls merely to fill a section.

| Order | Category | Contents |
|---|---|---|
| 1 | Materials | Stock selectors, then measured thicknesses, including tray, back and cleat stock; wood-runner thickness is under Hardware |
| 2 | Machining | Cutter and kerf, shared slot relief, side-panel relief, frame/drawer joint fits and depths, divider grooves, face-frame machining |
| 3 | Sizing | Envelope, fit targets, modular grid |
| 4 | Structure | Layout, top, back/braces, base, worktop, frame joinery, tab placement, drawer joinery |
| 5 | Fronts, Doors, Shelves, Drawers, Dividers, Trays | Component layout, reveals, dimensions and clearances |
| 6 | Mounting | Stacking, ganging, French cleats |
| 7 | Hardware | Separate hinge, slide, slide-drilling, wood-runner, handle, frame/drawer-fastener, face-registration, base, worktop, ganging and cleat-fastener sections |
| 8 | Output | View selector, visibility, flat layout, labels, calibration, export registration |
| 9 | System | Reports and interface-validation policy |

Use the exact full labels from `parameter_layout.json` for OpenSCAD `/* [Category / Section] */` headers. Generic clients may use each frontend's ordered `groups` array or source order. Cabinet Workshop applies explicit presentation rules in lib/settings.ts. Schema version 7 adds the layout contract and ordered group lists.

## Placement rules

- A shared parameter ID belongs to the same group in every frontend. Names and defaults remain compatible; differences in supported features are intentional.
- Keep stock selectors in Materials / Stock and thickness controls in Materials / Measured Thickness, except wood-runner controls grouped with Hardware / Wood Runners. Preserve decimal steps, units and custom-stock behavior.
- Joinery selection and tab placement belong under Structure; tool compensation, machining fit allowances and pocket depths belong under Machining.
- Put every exposed dogbone/T-bone selector under Machining. The existing `slot_corner_relief` is a shared control, so label it Shared Slot Relief. Do not imply that it independently controls drawers or frame parts. Stand `side_relief` is separate and belongs under Side Panels. Material-specific relief and cutter overrides now exist within the applicable native machining groups; the web adapter presents them by material.
- Separate hinge settings from slides. Slide selection/envelope belongs in Slides; drilling patterns and drill depth belong in Slide Drilling. Hardware hole diameters remain beside their patterns, not in the general cutter section.
- Keep output selection in Output / View, not under System. Diagnostics belong in System / Reports; visibility switches belong in Output / Visibility.
- Keep explanatory comments immediately above the parameter they describe. Preserve enum comments and numeric ranges.

## OpenSCAD dependency rule

OpenSCAD variable expressions depend on source order. Reordering headings alone is not enough: a runner thickness derived from resolved panel thickness must still evaluate after that resolver.

Place literal controls before computed controls within a section. Most internal resolution code and functions belong after the public controls under an actual `[Hidden]` header. Minimal hidden assignments needed by a computed public default may appear immediately before that control, followed by its public section header again. Customizer reuses that section; the schema's group list deduplicates it. Functions stay after public declarations so Customizer can discover all controls. Do not label an internal section with a human phrase ending in "Hidden"; use the actual `[Hidden]` directive and a normal comment.

The original 5.3.0 organization change also hid the internal `standalone_drawer_mode` flag, previously accidentally serialized as a public control. It remains defined internally. That organization-only change preserved actual user parameter names, default expressions, ranges and enum values. Later bay/relief patches deliberately added controls and updated contract signatures.

## Adding a module

1. Register the frontend and companion preset file in `paths.FRONTENDS`.
2. Use the ordered section vocabulary; reuse existing parameter IDs when semantics match.
3. Keep hidden calculations separate and respect dependencies. New calculated defaults require metadata and geometry checks.
4. Extend capability metadata and typed common mappings only for features the new module supports.
5. Run `python -m modular_organization.schema`. Generation rejects unknown/out-of-order groups, duplicate public IDs and inconsistent grouping of shared IDs.
6. Run the regression suite and manufacturing matrix. Add reviewed compatibility signatures to `tests/parameter_contract.json` for the new frontend, and update preset/matrix expectations deliberately.

The contract signature tests protect existing names, defaults, ranges and choices. They should change only when an intentional public parameter change is reviewed, not merely to make a test pass.

## Cabinet Workshop web presentation

The web adapter moves Fronts into Doors/Drawers, duplicates shared front controls
as views of the same underlying value, and groups Machining by receiving material.
It filters inactive controls without deleting their saved values, marks kerf
compensation/width as advanced, and supplies help for face-frame mid-rail modes.
These UI rules do not rename engine keys or alter the native Customizer grouping.
