# Migrating earlier v5 packages

The package refactor was introduced in 5.2.0. MORG-1 project and MOI-4 interface identities remain unchanged. Frontend source names are now versionless and resources live inside the Python package. Replace script-path imports with package imports or `modular-organization` CLI commands. Keep the SCAD resource tree intact.

`butt` means plain butt geometry, without implicitly requesting carcass screw guides. `screw` uses butt geometry plus generated face guide holes. Existing butt defaults remain unchanged; the legacy explicit registration-hole switch is still honored. Equipment `joinery_type` is now `joinery_style`; the Python API accepts the old key with a deprecation warning. Update native OpenSCAD preset JSON manually if it uses that old key.

Cabinet `joinery_style` concerns carcass joints; drawer joinery remains separately controlled by `drawer_joinery_style`. The standalone drawer maps `common.joinery` to the latter. Equipment butt mode disables frame screw guides; slides, cleats and tray hardware retain their required features. Face guides do not produce mating edge pilot bores automatically.

Use `common.material_thickness` to set actual fractional stock consistently. Native cabinet controls also require choosing custom stock; changing a hidden/computed resolved thickness directly is unsupported. Decimal sliders are annotated in all frontends. `flat_3d` is the common flat preview mode; legacy `print_layout` remains supported where it previously existed.

Native frontend JSON files are the authoritative design preset source. Redundant hardware-preset copies and recipe copies were removed. Select hardware IDs through the API/catalog instead. The raw hardware catalog and resolved runtime catalog are intentionally both retained: run the hardware resolver when editing inheritance, followed by equipment hardware generation and schema generation.

Historical release notes, old review snapshots, nested export archives, screenshots, duplicate generators and one-off patch scripts are excluded from this package. Useful examples, contracts, schemas, production code and verification evidence remain. External consumers referencing old filenames need to migrate; arbitrary historical script filenames are not shimmed.

## 5.3.0 parameter organization

All seven SCAD frontends now use the ordered section vocabulary in PARAMETER_CONVENTIONS.md. The generated web schema follows the exact same source order, exposes each frontend's `groups` list and includes `parameter_layout` metadata (schema version 7). Integrations that key UI sections by old group labels need to adopt the new labels. Parameter names, default expressions, ranges, enum values and native presets are unchanged.

One internal resolver flag, `standalone_drawer_mode`, is no longer incorrectly exposed in the schema. It remains an internal constant; remove any attempt to send it as a public request parameter. Hidden dependency assignments may occur between public controls to preserve OpenSCAD evaluation order. Empty categories are omitted by each module.
