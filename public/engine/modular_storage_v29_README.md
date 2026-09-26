# Modular Storage V29 — Fit-Target / Modular Drawer Sizing

> Historical engine documentation. Applies to the version named below, not the current application. See the [documentation guide](../../docs/README.md) and [consolidated changelog](../../CHANGELOG.md).


V29 adds reverse sizing: instead of choosing an outside cabinet envelope first
and accepting whatever drawer interior results, the user can specify the
required finished drawer interior width and/or depth and let the cabinet solve
its outside dimensions around that requirement.

The feature is shared by Utility, Shop Cart, Benchtop, Stackable, and Kitchen.

## Basic controls

```scad
width_basis = "outside";
// [outside, drawer_inside]

depth_basis = "outside";
// [outside, drawer_inside]

target_dimension_policy = "minimum";
// [minimum, exact]

target_dimension_mode = "direct";
// [direct, modular_grid]

target_drawer_bank = 1;

target_drawer_inside_width = 420;
target_drawer_inside_depth = 336;
```

Defaults remain `outside`, so V29 is geometry-identical to V28 until fit-target
sizing is explicitly enabled.

## Direct sizing

For an exact 420 x 336 mm finished drawer interior:

```scad
width_basis = "drawer_inside";
depth_basis = "drawer_inside";
target_dimension_policy = "exact";
target_dimension_mode = "direct";

target_drawer_inside_width = 420;
target_drawer_inside_depth = 336;
```

V29 runs the existing drawer geometry relationships backward:

```text
requested inside width
+ drawer side walls
+ slide / runner side clearance
+ bank weighting / partitions
+ carcass sides or face-frame stiles
= required cabinet width
```

and:

```text
requested inside depth
+ drawer front/back walls
+ front setback / inset-front allowance
+ drawer rear clearance
+ structural-back allowance when applicable
= required carcass depth
```

Because the inverse equations mirror the forward geometry, `exact` sizing hits
the requested finished drawer interior to normal floating-point tolerance.

## Minimum vs exact

`minimum` is conservative:

```text
requested interior = 420 mm
existing cabinet already provides 662 mm
resolved cabinet remains unchanged
```

It only grows an undersized cabinet.

`exact` may either grow or shrink the cabinet envelope to hit the target.

## Generic modular-grid sizing

V29 also includes a storage-system-agnostic modular mode:

```scad
target_dimension_mode = "modular_grid";

target_module_pitch_x = 42;
target_module_count_x = 10;
target_module_edge_clearance_x = 1;

target_module_pitch_y = 42;
target_module_count_y = 8;
target_module_edge_clearance_y = 1;
```

The finished drawer interior target is:

```text
X = pitch_x * count_x + 2 * edge_clearance_x
Y = pitch_y * count_y + 2 * edge_clearance_y
```

So the example above requests:

```text
422 x 338 mm
```

This works naturally for a 42 mm modular organizer system such as Gridfinity,
but nothing in the geometry is hard-coded to that system. Any pitch/count can
be used for parts bins, trays, batteries, fixtures, or custom organizers.

## Selected drawer bank / bay

`target_drawer_bank` is 1-based.

In a normal single-bank cabinet it should remain `1`.

For a multi-bank cabinet, V29 solves the cabinet width so the selected bank has
the requested finished drawer interior width. Other bank widths continue to
follow their configured relative width weights.

For mixed-bay layouts the selected slot must actually be a drawer bay. If it is
not, V29 does not silently choose another bay; it emits:

```text
ERROR|DRAWER_TARGET_BANK_NOT_DRAWER|...
```

## Kitchen / face-frame behavior

Kitchen sizing includes the face-frame opening in the inverse width equation.

For a legacy/non-mixed face-frame drawer bank, V29 therefore works through:

```text
drawer interior
-> drawer outside width
-> slide opening
-> required face-frame clear opening
-> overall cabinet / face-frame width
```

Depth is solved as carcass depth, while the dimension report continues to
report the finished kitchen depth including face-frame projection.

The catalog/model code remains descriptive metadata. If a B30 recipe is resized
by a fit target, its generated dimensions reflect the solved custom cabinet.

## Wood drawer slides

The existing front ends define wood-rail lengths relative to cabinet depth.

When fit-target depth sizing changes the cabinet depth, V29 carries the same
depth delta into the fixed rail and drawer-runner lengths. This prevents an
exactly downsized cabinet from retaining runners sized for the previous
envelope.

## Structured output

Whenever width or depth fit-target sizing is active, V29 emits:

```text
TARGET|DRAWER_INSIDE|BANK=1|MODE=...|POLICY=...|...
```

For modular sizing it also emits:

```text
INFO|MODULAR_TARGET|PITCH_X=...|COUNT_X=...|...
```

Example:

```text
TARGET|DRAWER_INSIDE|BANK=1|MODE=modular_grid|POLICY=exact|WIDTH_ACTIVE=true|DEPTH_ACTIVE=true|REQUESTED_W=422|ACHIEVED_W=422|REQUESTED_D=338|ACHIEVED_D=338|CONFIGURED_CABINET_W=760|RESOLVED_CABINET_W=520|CONFIGURED_CARCASS_D=610|RESOLVED_CARCASS_D=384|RESOLVED_FINISHED_D=384
```

If the solver cannot honor an active target, the web UI can key off:

```text
ERROR|DRAWER_TARGET_NO_DRAWERS|...
ERROR|DRAWER_TARGET_BANK_NOT_DRAWER|...
ERROR|DRAWER_TARGET_UNMET|...
WARN|DRAWER_TARGET_BANK_CLAMPED|...
```

## Web UI suggestion

A concise web control can be:

```text
Size width by:
  Outside cabinet
  Drawer interior

Size depth by:
  Outside cabinet
  Drawer interior

Target mode:
  Direct dimensions
  Modular grid

Policy:
  Minimum
  Exact
```

When `modular_grid` is selected, show pitch, module count, and edge clearance.

The resulting solved outside cabinet dimensions should be displayed as
read-only calculated values alongside the requested interior target.

## Current scope

V29 solves drawer-interior WIDTH and DEPTH.

Drawer-inside-driven HEIGHT is intentionally not included yet. Height interacts
with drawer count, height weighting, separators, face gaps, toe-kicks, and
combo door regions, so it is better added as a separate, explicit vertical
sizing model rather than hidden inside this horizontal solver.

## Existing V28 features

V29 preserves:
- all 34 native OpenSCAD recipes;
- cabinet ganging / alignment;
- face-frame back dados;
- mixed bays;
- true inset/flush fronts;
- structured dimension reporting;
- BOM and manufacturing exports;
- exact shared CUT / POCKET / ENGRAVE registration.

## Validation summary

- all five default assemblies are pixel-identical to V28;
- all five default CUT layouts are unchanged;
- all 34 native presets compile;
- exact drawer-interior sizing validated in all five cabinet families;
- modular 42 mm pitch sizing validated;
- selected-bank sizing validated;
- non-drawer mixed-bay errors validated;
- face-frame kitchen inverse sizing validated;
- minimum policy validated;
- shared CUT / POCKET / ENGRAVE registration validated with sizing enabled.
