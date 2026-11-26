# Stackable cabinet reference: measured joinery and how CCW follows it

This note records what was measured from a set of CNC plans for a stackable
workshop cabinet (a cube module with a door, a matching base frame and handle
blanks) that the user supplied as a reference, and the spec CCW implements from
it. The plans themselves are not in this repository: only dimensions derived from
them are recorded here, and CCW generates all geometry from its own parameters.

## Method

- **Source files.** The 475 mm wide module, nested for a 1220 × 1220 mm bed:
  metric 18 mm and 12 mm DXFs and the base-frame DXFs. The 400 mm and 550 mm
  versions and the imperial set were used to check which dimensions are
  parametric.
- **Measurement.** Every LWPOLYLINE and CIRCLE was dumped with its vertices,
  bulges and radii. Distances were measured between vertices, arc centres and
  circle centres. Nothing was scaled off an image.
- **Toolpath roles.** All geometry is on layer 0, so the role of each outline
  (through cut, 14 mm pocket, 12 mm cup, 10 mm shelf pin, 1.5 mm mark) was taken
  from the colours in the toolpath-specification PDFs.
- **Orientation.** Orientation was confirmed by the screw holes, the rail pockets
  and the rendered assembly photos. In the DXF the top edge of a side is y = 0.

## Measured geometry (18 mm sheet, 475 mm module)

### Sides

| Feature | Measurement |
|---|---|
| Body | 550 deep × 615 tall |
| Bottom tongue | 18 mm (= T) tongue; 633 mm tall overall |
| Top ears | At depth 0–98.8 and 451.2–550 |
| Top recess | Between the ears, 18 mm deep; floor 129.2–420.8 |
| Bottom tongue profile | Same as the recess, with zero nominal clearance |
| Profile flanks | 45° with r = 15 fillets |
| Outer corners | r = 3 |

- **Stacking.** The upper module's sides rest on the lower module's ears, and its
  tongue sits in the lower module's recess.
- **Stack pitch.** The pitch is the 615 mm body height.

### Pockets (blind, milled into the inside face)

All pockets are 14 mm deep in 18 mm sheet, which leaves a 4 mm skin. Every pocket
is open to a panel edge, so its part drops in from that side.

| Pocket | Size | Position | Open to |
|---|---|---|---|
| Top-rail pockets | 25 along the depth × 18 | Depth 25–50 and 500–525 | Top edge |
| Bottom-panel pockets | 100 × 18 | In the tongue, depth 225–325 | Bottom edge |
| Back pocket | 12 (back thickness) × 60 | Centred on the height | Back edge |

Closed pocket corners are relieved with an arc of r ≈ 3.35, a 6.7 mm relief for
a 6 mm (1/4 in) bit.

### Top rails (front and back)

- **Size.** 75 × 439 mm (interior width = W − 2T), laid flat and flush with the
  side tops in the ears.
- **End tabs.** Each end has a tab 25 wide, at depth 25–50 of the rail, and
  13 mm long. That stops 1 mm short of the 14 mm pocket floor. The rail is 465 =
  439 + 2 × 13 long overall.
- **Shoulder reliefs.** Tab roots have T-bone shoulder reliefs: a circle of
  r ≈ 3.35 centred on the shoulder line, one radius outside the tab edge. Without
  them the cutter's round inside corner would stop the shoulder short of the
  pocket mouth.
- **Back rail.** The back rail has two 12 × 50 notches for the back panel's top
  tabs. It also has three holes 6 mm from its back edge, for screws down into the
  back panel.

### Bottom

- **Size.** 400 × 439 mm, with a 100 × 13 tab at each end.
- **Height.** It sits in the tongue layer, with its underside flush with the
  tongue bottom, 18 mm below the side body.
- **Front to back.** It spans depth 75–475, exactly between the module-below's
  rails (75 + 400 + 75 = 550).
- **Registration.** In a stack the bottom therefore nests into the lower module's
  top. It is located front to back by the rails and left to right by the lower
  sides' inside faces.

### Back (12 mm)

- **Body.** 597 × 439 mm.
- **Tabs.** It has 60 × 13 side tabs at mid-height and two 18 × 50 top tabs that
  pass through the back-rail notches flush with the top.
- **Support.** It rests on the lower module's back rail and does not join the
  bottom.

### Shelf (12 mm)

- **Size.** 488 × 439 mm with r = 5 corners. The drawing shows zero clearance to
  the sides.
- **Shelf pins.** 5 mm holes, 10 deep, on a 50 mm pitch: seven rows at heights
  180–480, at depths 62 and 425 from the back.

### Door (18 mm)

- **Size.** 610 × 470 mm (W − 5), full overlay, r = 5 corners.
- **Hinges.** 35 mm cups, 12 mm deep, centred 21 mm from the hinge edge and
  63.5 mm from the ends.
- **Hinge-plate marks.** 1.5 mm deep marks 37 mm from the front, 32 mm apart, on
  both sides of the cabinet, so the door can hang either way.
- **Position.** The door spans heights 11.5–621.5 measured down from the module
  top. Stacked doors therefore leave a 5 mm gap, centred on the rail
  mid-thickness 9 mm below the top.

### Screws

All screw holes are 4.5 mm, through, for 1-1/4 in screws.

| Location | Positions |
|---|---|
| Ears (h = 9, the rail mid-thickness) | Depths 12.5 and 62.5, beside the rail tab, and 487.5 and 537.5 |
| Ears, into the upper module's bottom edge | Depths 90 and 460 |
| Back edge (depth 6) | h 152.25 and 480.75 |
| Tongue (h 624) | Depths 165 and 385 |

### Base frame (18 mm, 80 tall)

- **Sides.** 550 long, with the same top profile, rail pockets and ear screw
  holes as a module top, plus a front toe notch 57.5 deep × 47 tall.
- **Rails.** Two flat 75 mm rails, identical to a module's top rails.
- **Kick board.** A set-back on-edge kick board, 62 tall at depth 75–93, joined
  with 25 mm tabs into closed pockets. Its top is level with the recess floor, so
  it supports the module bottom.

### What changes with size and units

- **Module widths.** The 400, 475 and 550 mm modules change only the parts that
  run across the width:
  - interior: W − 2T
  - rails and bottom: W − 2T + 26
  - door: W − 5
- **Imperial set.** The imperial plans are the metric geometry converted. Only
  the thickness-driven features are rescaled: the tongue (= T), the pocket width
  (T + relief) and the back pocket (Tb + 2).

### Assembly sequence (from the plans)

1. Fit the back and bottom tabs into one side, then add the other side.
2. Drop the rails into the open-top pockets and screw through the ears.
3. Set the module on the base frame or on the module below and screw through the
   ears into it.
4. Fit the hinges and the handle.

## Derived rules

| Rule | Reference value | CCW setting |
|---|---|---|
| Pocket depth | T − 4 mm skin | `blind_tab_skin` (default 4) |
| Tab length | pocket depth − 1 mm | `blind_tab_end_clearance` (default 1) |
| Pocket corner relief | cutter radius at closed corners | existing `slot_corner_relief` / `cnc_tool_diameter` |
| Tab-root relief | circle of cutter radius on the shoulder, one radius outside the tab | applied with blind tabs when slot relief is on |
| Screws beside tabs | 4.5 mm through holes in the side, on the member's mid-thickness | `blind_tab_screw_holes`, `blind_tab_screw_hole_diameter` (4.5) |
| Fit | tab width + joint clearance | existing `joint_fit_clearance` |

## Gap list (reference has, CCW lacked)

1. **Hidden blind tabs.** CCW's tab-and-slot joints went through the sides and
   showed outside, and nothing could drop in from an open pocket edge.
2. **Shoulder reliefs at tab roots.** CCW relieved only the slots, not the
   male tabs.
3. **Screw holes beside the tabs.** CCW's tab-and-slot carcass had none.
4. **Stack registration in both directions.** The reference's bottom nests
   between the lower module's rails and sides. CCW's tongue registers front to
   back only.
5. **Screws between modules.** CCW drilled no holes for screwing one module to
   the next.
6. **Fronts that continue across the stack seam.** The reference leaves a
   uniform 5 mm gap centred on the rail. CCW leaves a band of about 23 mm between
   stacked doors.
7. **Interface depth tied to the sheet.** In the reference the interface depth
   equals T, and the bottom and rails fill the interface layer.
8. **Base frame.** The reference base has flat top rails identical to a
   module's top, a toe notch, and a set-back kick board that supports the bottom.
9. **Smaller differences:**
   - 45° self-centring flanks instead of CCW's S-curve;
   - hinge-plate marks on both sides;
   - rounded outer corners;
   - a back panel that rests on the lower rail with its top tabs through rail
     notches.

## What CCW implements

### Phase 1: blind side tabs (this release)

- **New setting.** `side_tab_style` = `through` | `blind` is available on shop
  carts, utility, benchtop, stackable and kitchen cabinets with tab-and-slot
  joinery. Stackable cabinets default to `blind`; the others keep `through`.
- **Tabs and pockets.** With `blind`, every cross member that enters a side has
  tabs of length tp_tab_length(T, skin, end clearance). The members are the
  bottom, top or top stretchers, fixed shelves, combo divider, drawer separators,
  toe kick, rear stretchers, structural back, bay shelves and section dividers
  that end at a side, and the base-frame cross rails. The tabs stop in pockets
  tp_pocket_depth(T, skin) deep, milled from the inside face.
  - The pockets are the same shapes as the through slots, including their corner
    reliefs and open edges. They are cut in the carcass-dado pocket operation
    (`pocket_carcass_dados`, with its depth echoed), not the cut layout.
  - The side outlines are those of an unjoined carcass, apart from round holes.
- **Shoulder reliefs.** When slot relief is on, blind tabs get the reference's
  shoulder reliefs. A relief is left off where the tab edge is flush with the
  member's own edge.
- **Screw holes.** With `blind_tab_screw_holes`, the sides get through holes on
  each member's mid-thickness line, at the centres of the gaps beside and
  between the tabs. A gap narrower than the hole + 6 mm gets no hole.
- **Shared code.** The primitives are in
  `public/engine/v5/src/modular_organization/data/scad/tab_pocket.scad`. They
  take arguments only and read no cabinet setting.

### Phase 2 (planned)

- **Nested stacking.** The bottom sits between the lower module's stretchers and
  sides, giving registration in both directions.
- **Interface depth tied to T.**
- **Inter-module screw holes.**
- **Base frame.** Flat top stretchers and a supporting kick board.
- **Fronts across the stack seam.** Fronts sized to a uniform gap centred on the
  rail.
- **Stack interference check.** A test that a module placed on another does not
  intersect it.

## Ambiguities and how they were resolved

- **Shelf clearance.** The 12 mm shelf is drawn with zero side clearance (488 ×
  439 between 439 mm faces). CCW keeps its adjustable-shelf side clearance; a
  zero-clearance shelf cannot be inserted.
- **Screw count.** The materials list gives 27 × 1-1/4 in screws: 21 in the
  carcass, 4 to the module below and 2 for the handle. Counting the holes for
  the carcass step gives 19. CCW does not copy a screw count; it drills the holes
  its own rules call for and lists them.
- **Door position.** The door spans 11.5–621.5 from the module top. This was read
  as a deliberate 5 mm gap centred on the rail between stacked modules (2.5 mm
  either side of the joint at 9 mm below the top), not a reveal to the module's
  own top edge.
- **Through or blind as the default.** Blind is the stackable default, because a
  stack shows its sides and the reference hides every tab. The other cabinet
  types keep through tabs by default, so their starters and saved designs build
  exactly as before. No starter uses tab-and-slot joinery, so no starter's
  output changed.
- **Interior joints.** Partitions and dividers that join other interior members
  keep through tabs. Both faces of a partition can receive members, and the
  reference has no interior joints to follow.
