# Media cart: review of the original model

The media cart product (`public/products/media_cart/media_cart.scad`) is based on a
standalone OpenSCAD model, "Shop media holder" (250 lines): sloped or stepped bin
rows over optional lower cubbies, optional shelf towers on either side, casters,
stock presets with measured thickness, and butt, screw, dado or tab-and-slot joints
between the bin crosspieces and the side walls.

The original renders cleanly and its parts do not intersect in any of its presets
(checked by rendering each part separately with the bundled OpenSCAD and
intersecting every pair). It is an assembly model only: there is no parts list, no
flat cut layout and no machining output, and several joints could not be made or
assembled as drawn. This note lists each problem found and what the product engine
does instead.

## Problems and corrections

| # | Original | Problem | Correction |
|---|---|---|---|
| 1 | Bottom, bin deck, cubby dividers, cubby back, tower back, shelves and cap butt against each other | Nothing holds them: no joint, no fastener, no glue face location | New **Panel joinery** setting (butt, screw, dado, tab & slot) for every joint that is not a crosspiece. Each joint is defined once and cuts matching tabs and receivers, dados and tongues, or screw clearance holes in both parts. |
| 2 | Fins (bin dividers) run between the front and rear crosspieces and butt them | Fins are only held by the inner crosspiece half-laps; with one row they have no lap at all and float | Fins run the full depth and half-lap **every** crosspiece, front and rear included, so a one-row grid is still locked. Fins also tab into the deck or bottom panel. |
| 3 | Tab-and-slot receivers for the front and rear crosspieces sit at the wall edge, widened by the fit clearance | The receiver breaks out of the wall edge by half the clearance, leaving a thin sliver or an open notch | Edge receivers are kept as deliberate open notches flush with the wall edge (the crosspiece face finishes flush with the wall), drawn as one closed outline in the cut layout. |
| 4 | Screw joints bore pilot holes into the edge of the receiving panel | A pilot in a panel edge cannot be cut on a flat sheet | Clearance holes are cut through the face of the joined part; the pilot is listed as drilled at assembly (diameter and depth in the hardware list and in the packet). Holes smaller than the cutter (the 4.5 mm screw clearance holes with the default 6.35 mm cutter) leave the cut layout and go to their own `drill_layout` operation, drilled at the circle centers; holes at least as large as the cutter (caster bolts) stay in the cut layout. |
| 5 | Slots and receivers have square inside corners | A round cutter leaves radii that stop square parts seating | Dog-bone or T-bone relief (or none, for CAM-added relief) at every closed inside corner of receivers, half-lap slots and dados, sized from the cutter diameter. |
| 6 | Tabs are at most one stock thickness long, at fixed places | Too short to locate and too weak for long joints | Tab length, spacing, edge margin and the minimum web between receivers are settings. Joints too short for a tab are reported (error on the receiving side, glue-only warning on a part that yields to another joint). |
| 7 | Dado depth is only checked against the full stock thickness | A panel with dados on both faces (shared tower wall) needs each dado under half the thickness | Dado depth must be under half the thickness of the part it is cut into. Two-sided parts get a second operation (`pocket_dados_flip`), laid out for the whole sheet turned over (see Second-face dados below). |
| 8 | Towers share the bin side wall and are joined to it like the bins | With every joint tabbed, no assembly order exists: the shelves and tower back would have to enter the shared wall from two directions at once | Assembly order is part of the design: each tower is built on its own outer wall (back, shelves, cap), stood up and slid onto the shared wall; its wall and back are screwed to the bottom from below. The assembly steps and packet give this order. |
| 9 | Side walls stand on the bottom panel with tabs into it | Walls must arrive sideways last (over the crosspiece and deck tabs), so they cannot also drop into bottom slots | Walls are screwed up through the bottom panel (pilots drilled at assembly) unless panel joinery is butt. |
| 10 | Stepped profile: half-laps at mid-height of each row | At a step the half-lap of the low front fin segment cut it free of the rest of the fin (default stepped preset: 350 mm segment, lap to 355.5 mm) | On stepped profiles each lap is taken to half the **lower** of the two rows it joins, so every fin stays one piece. |
| 11 | Stepped profile: rear crosspiece tabs cut into the wall's rear post | The post is one stock thickness wide; tab receivers severed it | On profile walls, crosspiece tabs stop below the step, keeping the post whole. |
| 12 | Casters are drawn but not attached | No bolt holes, no hardware list | Four bolt holes per caster (spacing, inset and diameter are settings), with checks that they clear every panel standing on the bottom and fit inside it; casters and bolts are listed as hardware. |
| 13 | No parts list or cut files | Cannot be cut without redrawing every part | Every part is one flat 2D profile; the 3D assembly, the flat cut layout (with kerf compensation and a registration frame), pocket layouts per face, engraved labels and the parts list (BOM, PLACE, DIM, CHECK and HARDWARE records) all come from that profile, so the shared cut list, nesting, per-sheet SVG/DXF and checks work as for the cabinets. |

## Choices made where the original was ambiguous

- **Panel joinery is a separate setting** from the crosspiece joinery, with tab &
  slot as the default for both. The original's single joinery setting only covered
  crosspieces.
- **Open edge notches** for the front and rear crosspiece receivers are kept (item 3)
  rather than moving the crosspieces inward, so the outside dimensions and the flush
  front of the original are unchanged.
- **Walls screwed from below** (item 9). Gluing alone was rejected because the walls
  carry the crosspiece joints; tabs into the bottom were rejected because of the
  assembly direction.
- **Two-sided dados** are cut from both faces with a flip operation rather than
  forbidding dado joinery on shared tower walls.
- **Shared joinery primitives.** Receivers, slots and dados with their dog-bone or
  T-bone relief, and the shoulder reliefs at tab and tongue roots, come from the
  engine's shared module `data/scad/tab_pocket.scad` (the same one the stackable
  cabinets' blind tabs use), so the relief geometry is defined once.
- **Casters**: 4-bolt plate casters with a 75 × 75 mm bolt pattern and 8.5 mm holes
  by default; the original gave only a caster height.
- Overall dimensions, the bin geometry (row pitch, column pitch, entrance heights,
  the flush-back option) and the shape presets follow the original exactly.

## Second-face dados

A part with dados on both faces is machined on one sheet in two passes. The flip
layout is not a per-part mirror: the whole layout (and, after nesting, the whole
sheet) is drawn turned over left to right about its vertical center line. Each
sheet that has second-face pockets gets two registration-pin holes on that center
line, in the top and bottom margins, in both `pocket_dados` and
`pocket_dados_flip`. The order, also written in the package's READ-ME and the
operation notes:

1. Machine `pocket_dados` (it drills the pin holes); pin the sheet to the bed.
2. Turn the whole sheet over left to right, onto the same pins (they lie on the
   flip line, so they land on themselves), and machine `pocket_dados_flip`.
3. Turn it back onto the pins; run `drill_layout` and `cut_layout`.

With a sheet margin under 10 mm there is no room for pins; the notes say to mark
the center line on both faces and the bed instead. The export test checks that
every second-face contour, turned back, lands inside its part on its sheet.

## Stability and racking

The engine check computes, for the cart empty, fully loaded and loaded only in
the highest bin row and tower opening:

- the weight and center of gravity: every part's outline × thickness × the sheet
  density (600 kg/m³ by default), plus the stated contents (5 kg per bin, cubby and
  tower opening by default) at the center of each space;
- the level push at the top of the cart that tips it forward, backward, left or
  right: weight × the horizontal distance from the center of gravity to the
  tipping edge ÷ the push height above the floor. The tipping edges are the caster
  centers (casters locked, level floor) or the edges of the bottom panel without
  casters;
- the downward lean on the front edge of the bins that tips it forward, when the
  front support is behind that edge.

An error is raised when the weight alone is outside the support, and a warning
when a stated push (50 N by default, a firm one-handed push) or lean (250 N)
would tip it. The editor's **Stability** section sets those forces, the contents
and the density; the drawing shows the center of gravity of the weakest loading
and a summary with the per-loading results and these assumptions. The default
sloped-bins cart holds a 75 N push backward empty (the weakest case) and a
1,932 N lean. The compact sorter starter (no casters, 520 mm tall, 11 kg) tips
under a 50 N push and is reported with a warning that suggests fastening it.

Racking: the report lists what resists shear side to side (the crosspieces and
their joints, the cubby back, the tower backs) and front to back (the side walls
screwed to the bottom, the fins' half-laps, the cubby dividers, the tower walls),
and warns when only glued butt joints resist it in either direction.

## Not covered

No load rating of joints, panels, shelves or casters, no dynamic loads (rolling
over a threshold, a caster catching), no grain direction or edge banding, and no
CAM verification of the exported contours.
