# Hardware Catalog V2 — one-time configuration patches

`modular_storage_hardware_v2.json` is the canonical hardware database.

V32 deliberately makes hardware work like cabinet recipes:

```text
hardware catalog entry
        ↓
apply ordinary configuration values once
        ↓
editable canonical cabinet/drawer configuration
        ↓
shared geometry
```

There is no persistent `drawer_slide_profile` or `hinge_profile` geometry mode.
After a hardware preset is applied, the resulting dimensions and drilling values
are ordinary Customizer/configurator settings and may be edited normally.

## Adding a profile

Copy an object from `hardware_profile_template_v2.json` into the catalog's
`profiles` array. Give it a stable lowercase `id`, metadata, a list of target
frontends, source/verification information, and an `apply` object.

Then run:

```bash
python generate_modular_storage_hardware.py --root . --check
python generate_modular_storage_hardware.py --root .
```

The generator validates that every `apply` key is a public setting on every
listed target frontend, expands `extends`, writes
`modular_storage_hardware_resolved_v2.json`, and adds native OpenSCAD
Customizer parameter sets to the matching same-basename JSON files.

Normal OpenSCAD use does not require Python.

## Slide patches

For traditional regular hole patterns, existing legacy controls remain:

```scad
metal_slide_first_hole_from_front
metal_slide_hole_spacing
metal_slide_hole_count
```

For real hardware with irregular patterns, V32 adds canonical arrays:

```scad
metal_slide_hole_pattern_mode = "explicit_array";
metal_slide_cabinet_holes_x = [37,133,229,325,421];
metal_slide_drawer_holes_x = [37,133,229,325,421];
metal_slide_cabinet_hole_diameter = 5;
metal_slide_drawer_hole_diameter = 5;
hardware_drilling_mode = "recommended";
```

`minimum`, `recommended`, and `all` operate on the explicit array. Legacy
spacing remains unchanged by default, preserving V31 geometry.

If a manufacturer's documentation does not support a single safe automatic
hole pattern, a profile should set `include_metal_slide_holes=false` rather
than inventing coordinates.

## Hinge patches

Hinge entries patch the existing cup and mounting-plate controls. V32 adds two
ordinary safety switches:

```scad
hinge_door_fixing_enabled = true;
hinge_plate_holes_enabled = true;
```

Manufacturer profiles can disable unsupported operations while still applying
verified cup diameter/depth/position or cabinet style. This prevents a partial
profile from inheriting stale drilling from a previously applied profile.

## Verification metadata

`verification` and `source` are catalog/UI metadata; they do not control
geometry. Use `manufacturer_partial` when only a safe subset of the technical
sheet maps to the current machining model.

The web UI should present manufacturer/family/model and verification status,
then apply the `apply` object to the current canonical design state. Saved
designs should store the resulting canonical settings, not require the hardware
profile to remain active.
