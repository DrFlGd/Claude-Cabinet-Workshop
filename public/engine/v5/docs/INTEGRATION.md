# Python engine integration

For a Python/server integration, use `modular_organization.api` as the application boundary. The package is an engine, not an HTTP server or deployed website.

| Function | Input | Result |
|---|---|---|
| `describe()` | None | Copy of generated UI schema |
| `inspect(frontend, ...)` | Packaged frontend/preset/hardware ID, typed `parameters` and `common` | Status, checks, BOM, dimensions, interfaces, runtime warnings |
| `preview(frontend, output, ..., view='assembly')` | Same configuration; host-owned STL path; assembly or flat_3d | STL path, warnings, compiled configuration |
| `manufacture(frontend, output, ...)` | Same configuration; host-owned ZIP path | Path after successful audit and atomic replacement |
| `compose(project)` | MORG-1 JSON | Resolved modules, transforms, compatibility and project diagnostics |

The frontend IDs are `utility`, `shop_cart`, `benchtop`, `stackable`, `kitchen`, `drawer`, and `equipment_stand`. `common.material_thickness` switches the frontend to custom stock and preserves decimals. `common.joinery` accepts butt, screw, dado and tab_slot. `common.tray_thickness` applies to equipment stands. Native controls remain available under `parameters`; conflicting common/native controls are rejected.

Use schema `capabilities` to show supported controls. Computed defaults are OpenSCAD expressions: omit them from requests unless overridden with a typed value. Never evaluate `default_expression` in JavaScript. Display dependent controls using `visible_if`; omission preserves generator defaults. Native preset and hardware identifiers come from packaged catalogs.

Run synchronous CAD operations in a bounded worker queue. Allocate a private job directory and host-generated output names for each request. Set `MO_OPENSCAD_TIMEOUT_SECONDS` (default 120, maximum 1800); this bounds each renderer invocation, not a whole manufacturing job. Apply total-job deadlines, concurrency, CPU/memory and output quotas in the hosting layer. Configure authentication, access control, cancellation, rate limits and artifact retention there. No browser framework is required.

Do not expose advanced CLI raw SCAD paths, arbitrary preset files, `-D` expressions, executable paths or filesystem outputs to request clients. Only packaged frontend names and validated JSON belong at the HTTP boundary. Catch ValueError for invalid configuration and RuntimeError for renderer/export failures. Inspect semantic ERROR statuses before presenting a design as valid. Some expensive inputs may pass typed validation but fail geometric validation; that is intentional.

Manufacturing ZIPs contain registered CUT, POCKET and ENGRAVE exports, reports, configuration snapshots and conservative rectangular sheet planning. Preview STL is for visualization; assembled touching parts can yield non-manifold STL warnings. Use operation-separated manufacturing geometry for fabrication.

Project checks cover orthogonal Z rotation, translation, interface matching, logical organizers and conservative bounding boxes. They do not simulate arbitrary motion or structural loads. Equipment slide/load data are hardware metadata, not a wall-anchor or anti-tip calculation.

For section rendering, use each frontend’s ordered `groups` list and parameter `group` values. `parameter_layout` defines the vocabulary and category ordering for all modules. Generic clients can preserve that native order. Cabinet Workshop adds intentional presentation rules in its web adapter: Fronts is regrouped into Doors/Drawers, material-specific machining is grouped by material, and dependencies/advanced controls are filtered.

## Browser integration distinction

Cabinet Workshop's browser rendering runs bundled OpenSCAD WASM workers rather
than calling this Python API. Its source/schema adapter and browser export review
are separate from the native Python manufacturing audit. Passing browser Design
Health must not be reported as completion of the native final-contour audit.
