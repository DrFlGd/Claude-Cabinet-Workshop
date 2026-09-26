# Migration: Modular Storage V28 -> V29

V29 is additive.

No V28 public configuration key was removed or renamed.

Existing recipes and saved V28-style configurations retain the same geometry
because both sizing axes default to the existing outside-envelope behavior:

```scad
width_basis = "outside";
depth_basis = "outside";
```

## New public inputs

```text
width_basis
depth_basis
target_dimension_policy
target_dimension_mode
target_drawer_bank
target_drawer_inside_width
target_drawer_inside_depth

target_module_pitch_x
target_module_count_x
target_module_edge_clearance_x
target_module_pitch_y
target_module_count_y
target_module_edge_clearance_y
```

## New structured records

```text
TARGET|DRAWER_INSIDE|...
INFO|MODULAR_TARGET|...
ERROR|DRAWER_TARGET_NO_DRAWERS|...
ERROR|DRAWER_TARGET_BANK_NOT_DRAWER|...
ERROR|DRAWER_TARGET_UNMET|...
WARN|DRAWER_TARGET_BANK_CLAMPED|...
```

The schema `outputs` section now advertises `TARGET|` and `INFO|` prefixes.

## Web interface

A V28 web UI may continue sending outside dimensions exactly as before.

To use V29 reverse sizing:
1. set either `width_basis` or `depth_basis` to `drawer_inside`;
2. choose `minimum` or `exact`;
3. choose `direct` or `modular_grid`;
4. send the target values;
5. read the solved envelope from `DIM|CABINET|OUTSIDE` and the verification
   from `TARGET|DRAWER_INSIDE`.

## Kitchen note

When a kitchen face-frame cabinet is depth-sized from a drawer target,
`DIM|KITCHEN|NOMINAL_D_IN` now reports the solved finished depth rather than the
original configured nominal-depth input.
