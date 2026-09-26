# Hardware Catalog V3 — configuration patches + mounting-spec library

> Historical engine documentation. Applies to the version named below, not the current application. See the [documentation guide](../../docs/README.md) and [consolidated changelog](../../CHANGELOG.md).


`modular_organization_hardware_v3.json` is the canonical hardware database inherited by Modular Organization v3 from the v35 parent line.

The catalog now has two jobs:

```text
manufacturer hardware record
        ↓
mounting_specs + source/verification metadata
        ↓
if the inherited geometry can represent the hardware safely:
    apply ordinary configuration values once
        ↓
editable cabinet/drawer configuration
        ↓
shared geometry
```

There is still no persistent `drawer_slide_profile` or `hinge_profile` geometry mode. After a supported hardware preset is applied, its dimensions and drilling values are normal Customizer/configurator settings and may be edited.

## Geometry support levels

Every resolved record has `geometry_support.status`:

- `native` — project/reference geometry maps directly to the inherited geometry.
- `partial` — a safe subset maps to the inherited geometry, such as side-slide clearance/length/envelope or a hinge cup bore. Unsupported drilling is deliberately disabled rather than guessed.
- `metadata_only` — manufacturer planning data is stored for the website/library, but no machining preset is generated. Use this for concealed/undermount runners, face-frame hinges, half-overlay applications, or any product whose mounting model the current engine cannot yet represent safely.

`metadata_only` records intentionally have no `targets` and no `apply` object.

## Adding a profile

Copy an object from `hardware_profile_template_v3.json` into the catalog `profiles` array. Give it a stable lowercase `id`, manufacturer/family/model metadata, `mounting_specs`, source/verification information, and a support status.

For `native` or `partial` records, also provide target frontends and an `apply` object. Then run:

```bash
python generate_modular_organization_hardware.py --root . --check
python generate_modular_organization_hardware.py --root .
```

The generator validates public `apply` keys, expands `extends`, writes `modular_organization_hardware_resolved_v3.json`, and adds native OpenSCAD Customizer parameter sets. `metadata_only` entries remain visible in the resolved database and index but are skipped for machining presets.

Normal OpenSCAD use does not require Python.

## Slide patches

For traditional regular hole patterns, existing legacy controls remain:

```scad
metal_slide_first_hole_from_front
metal_slide_hole_spacing
metal_slide_hole_count
```

For hardware with a single verified irregular pattern, the current engine supports explicit arrays:

```scad
metal_slide_hole_pattern_mode = "explicit_array";
metal_slide_cabinet_holes_x = [37,133,229,325,421];
metal_slide_drawer_holes_x = [37,133,229,325,421];
metal_slide_cabinet_hole_diameter = 5;
metal_slide_drawer_hole_diameter = 5;
hardware_drilling_mode = "recommended";
```

If a manufacturer's rail offers several valid mounting slots/holes and the generator cannot choose safely, use `include_metal_slide_holes=false`. Length, side clearance, and envelope height can still be applied.

Concealed/undermount runners are currently stored as `metadata_only` because they typically require drawer-width formulas, underside clips/catches, rear hooks, notches, and/or system-line drilling that the side-mount model does not represent.

## Hinge patches

Hinge entries patch the existing cup and mounting-plate controls. the current engine includes two safety switches:

```scad
hinge_door_fixing_enabled = true;
hinge_plate_holes_enabled = true;
```

Manufacturer profiles can disable unsupported operations while still applying verified cup diameter/depth/position or front style. This prevents a partial profile from inheriting stale drilling from a previously applied profile.

The current engine does not encode a lateral offset for hinge cup fixing wings. Therefore manufacturer patterns such as `45 x 9.5` or `52 x 5.5` are retained in `mounting_specs`, while fixing holes stay disabled unless the geometry model can express the complete pattern.

## Verification and source metadata

`verification`, `source`, and `mounting_specs` are catalog/UI metadata; they do not directly control geometry. Manufacturer records should carry a traceable source URL and retrieval date.

The web UI should show manufacturer/family/model, source/verification, geometry support status, and mounting specs. For `native`/`partial` entries it may apply the `apply` patch to the current design. For `metadata_only` entries it should show the planning data but disable automatic machining until the relevant geometry is implemented.

Saved designs should store resulting canonical design settings rather than requiring a hardware profile to remain active.
