# Development notes — v3

The project graph is intentionally outside OpenSCAD. OpenSCAD emits facts about generated physical modules; it does not own mutable project state.

`modular_organization_project.py` is a reference resolver/service implementation suitable for porting to or invoking from a web backend. It reads MORG-1, materializes each OpenSCAD module contract, resolves relationships, and emits deterministic resolved state.

Interface frames are module-local. For `stack.top/bottom` and `side_gang.left/right`, V3 emits origin/U/V/outward-normal data. The resolver requires the frame origins to coincide, U/V axes to align, and outward normals to oppose after placement.

The resolver only searches 0/90/180/270-degree Z rotations. This keeps the first contract deterministic and safe for the cabinet-like modules currently exposed. A future MOI revision can extend the same frame records to arbitrary rigid transforms without changing their semantic meaning.

Project collision currently uses module AABBs and suppresses declared `contains` pairs. This is a coarse assembly check, not a replacement for the per-module exhaustive CUT/POCKET validator.
