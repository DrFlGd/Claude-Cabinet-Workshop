# Shared Cabinet Generator — V25 Segmented Back-Dado Face Frames

> Historical engine documentation. Applies to the version named below, not the current application. See the [documentation guide](../../docs/README.md) and [consolidated changelog](../../CHANGELOG.md).


Files:
- `parametric_kitchen_cabinet_v2.scad`
- `parametric_utility_cabinet_v57.scad`
- `parametric_shop_cart_v13.scad`
- `parametric_benchtop_drawer_cabinet_v29.scad`
- `parametric_stackable_cabinet_v7.scad`
- `cabinet_core_v25.scad`
- `cabinet_layouts_v25.scad`
- `export_cabinet_bom.py`

## New Kitchen V2 face-frame construction

Kitchen V1 already manufactured the facing as separate hardwood stiles/rails.
V25 adds a positive-registration back-dado option:

```scad
face_frame_construction = "segmented_back_dado";
// [segmented_surface, segmented_back_dado]

face_frame_back_dado_depth = 6.35;
face_frame_back_dado_clearance = 0.20;
```

Kitchen V2 defaults to `segmented_back_dado`.

## What "segmented" means

The perimeter facing remains four economical strips:
- left stile
- right stile
- top rail
- bottom rail

A drawer-over-doors cabinet also needs the existing horizontal mid rail, so
that configuration has one additional strip. The optional center stile remains
a separate surface-mounted member because there is not necessarily a matching
structural cabinet partition behind it.

This avoids cutting a full hardwood front panel just to leave a narrow frame.

## Back dado / rabbet geometry

The four perimeter pieces are pocketed from the BACK:

- left stile receives the left carcass side front edge
- right stile receives the right carcass side front edge
- top rail receives the front top panel or front top stretcher
- bottom rail receives the cabinet-bottom front edge
- the automatic combo mid rail receives the combo-divider front edge

Because those structural edges meet the edge of each strip, the actual
machined feature is an edge-open back rabbet/dado.

The pocket width is:

```text
carcass material thickness + face_frame_back_dado_clearance
```

The default 3/4-in carcass and 0.20 mm clearance therefore make a 19.25 mm
receiver.

## Nominal kitchen depth remains correct

A 3/4-in face-frame strip with a 1/4-in back dado only projects 1/2 in ahead of
the plywood carcass:

```text
19.05 - 6.35 = 12.70 mm projection
```

Kitchen V2 automatically adjusts plywood carcass depth so the FINISHED cabinet
still remains exactly the selected nominal depth.

Default B30:

```text
nominal finished depth = 609.60 mm (24 in)
face-frame projection  =  12.70 mm
plywood carcass depth  = 596.90 mm
```

Switching back to:

```scad
face_frame_construction = "segmented_surface";
```

restores the V1 geometry: the full 19.05 mm face frame projects ahead of the
carcass and the plywood side resolves to 590.55 mm.

The V2 `segmented_surface` compatibility mode was regression-tested
pixel-identical to Kitchen V1.

## Assembly geometry

The frame itself is shifted rearward by the dado depth and the actual pocket
volume is removed from the frame strips, so the carcass front edges physically
nest inside the modeled facing. This is not only a CAM annotation.

Overlay and inset/flush doors/drawer fronts continue to reference the visible
front surface of the face frame.

## Manufacturing output

New dedicated output:

```scad
output_mode = "pocket_face_frame_dados";
```

The same back pockets are also included in:

```scad
output_mode = "pocket_layout";
```

CUT / POCKET / carcass-dado / face-frame-dado / ENGRAVE files retain the same
shared export bounds.

The dedicated face-frame operation is explicitly a BACK-SIDE machining
operation.

`print_layout` subtracts the dado pockets from the 3D face-frame strips so they
can be visually inspected.

## BOM / dimensions

Face-frame BOM notes now distinguish:
- `segmented_surface`
- `segmented_back_dado`

and report the dado depth where applicable.

The structured DIM report adds:
- face-frame construction
- back-dado depth
- back-dado clearance
- visible face-frame projection

## Validation

Kitchen V2:
- default B30 assembly with segmented back-dado facing
- surface-segmented compatibility mode
- dedicated back-dado pocket output
- combined pocket output
- carcass dado output
- CUT
- ENGRAVE
- PRINT with modeled back pockets
- BOM notes
- DIM report
- 24-in finished-depth preservation

Regression:
- Kitchen V2 `segmented_surface` is pixel/CUT identical to Kitchen V1
- Utility V56 -> V57 defaults unchanged
- Shop Cart V12 -> V13 defaults unchanged
- Benchtop V28 -> V29 defaults unchanged
- Stackable V6 -> V7 defaults unchanged
