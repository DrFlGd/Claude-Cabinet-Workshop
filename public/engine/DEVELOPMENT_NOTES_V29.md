# Development Notes — V29

## Solver architecture

V29 preserves `cabinet_width` / `cabinet_depth` as the public configured
envelope inputs.

The shared core derives:

```text
resolved_cabinet_width
resolved_cabinet_depth
```

The geometry and reporting layers use those resolved dimensions.

When both sizing bases are `outside`, the resolved dimensions equal the public
inputs exactly. This is what preserves V28 regressions.

## Why algebraic inversion

The feature does not introduce a generic iterative constraint solver.

It directly inverts the same equations used by:
- drawer bank opening width;
- drawer outer width;
- drawer wall thickness;
- slide/runner side clearance;
- drawer box depth;
- front setback;
- back clearance;
- structural back consumption;
- face-frame clear opening.

That makes the result deterministic, fast, and easy for the web configurator
to predict and validate.

## Mixed-bay policy

Never silently move a target from a non-drawer bay to a drawer bay.

Emit a structured error so the user/project layer can make the choice.

## Future vertical sizing

Drawer-inside height should be a separate V30+ feature.

Vertical inversion needs an explicit policy for:
- all drawers vs selected drawer;
- equal / graduated / weighted stacks;
- combo drawer-over-door layouts;
- separators;
- face gaps and vertical clearances;
- toe-kick / base effects.

Do not bury those choices inside the current horizontal solver.
