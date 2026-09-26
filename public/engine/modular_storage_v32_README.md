# Modular Storage V32 — recipe-style hardware catalog

> Historical engine documentation. Applies to the version named below, not the current application. See the [documentation guide](../../docs/README.md) and [consolidated changelog](../../CHANGELOG.md).


V32 refactors the hardware database so slides and hinges behave like recipes:
select/apply hardware once, then edit the ordinary dimensions and drilling
settings directly.

## Canonical hardware database

```text
modular_storage_hardware_v2.json
modular_storage_hardware_resolved_v2.json
modular_storage_hardware_schema_v2.json
hardware_profile_template_v2.json
```

The V2 catalog contains 16 example profiles: eight drawer slides and eight
concealed-hinge configurations/references.

The web configurator should list profiles from the resolved JSON and merge the
selected profile's `apply` object into the current canonical design.

## Native OpenSCAD use

Running `generate_modular_storage_hardware.py` adds hardware patch parameter
sets to each normal same-basename Customizer JSON. For example the Utility
preset dropdown contains both cabinet recipes and entries such as:

```text
Slide — Accuride 3832E 500 mm
Slide — KV 8400 20 in (508 mm)
Hinge — Hettich Sensys 8645i 110° / overlay screw-on
```

After applying one, the ordinary settings remain the source of truth.

## Explicit slide patterns

V32 keeps the historic regular-spacing mode unchanged and adds an explicit
array mode for hardware-specific drilling:

```scad
metal_slide_hole_pattern_mode = "legacy_spacing";
// [legacy_spacing, explicit_array]

metal_slide_cabinet_holes_x = [37,133,229,325];
metal_slide_drawer_holes_x = [37,133,229,325];
metal_slide_cabinet_hole_diameter = 5;
metal_slide_drawer_hole_diameter = 5;
```

`hardware_drilling_mode = minimum | recommended | all` controls how an explicit
array is reduced for machining.

## Hinge safety controls

```scad
hinge_door_fixing_enabled = true;
hinge_plate_holes_enabled = true;
```

These are ordinary settings. Manufacturer profiles whose fixing details do not
map safely to the current through-hole model turn the relevant operation off
instead of guessing.

## Included manufacturer examples

The catalog now includes reference/partial profiles for Accuride 3832E, Knape
& Vogt 8400, Hettich KA 5632, Blum CLIP top BLUMOTION, Hettich Sensys 8645i,
Salice Silentia+ Series 100, and GRASS Tiomos 110, plus generic fully-machined
baseline profiles.

Source URLs and verification notes are stored with each catalog item. Partial
profiles only apply the dimensions that are safe for the current engine.

## Compatibility

All V31 defaults are unchanged, and all 39 existing native recipes still
compile. See `MIGRATION_V31_TO_V32.md` and `VALIDATION_V32.txt`.

## Stackable bottom tab placement

When `joinery_style = "tab_slot"` on the stackable frontend, the cabinet bottom
now defaults to `bottom_tab_placement = "stack_safe"`. The first and last tabs
are biased into the full-height front/rear stacking pads rather than landing on
the rounded stacking-interface shoulders. For explicit control, select
`bottom_tab_placement = "custom"` and provide `bottom_tab_custom_centers` as
millimeter center locations measured from the front cabinet edge.
