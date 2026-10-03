# Section layouts

Section layouts are available on **shop carts**, **utility cabinets** and
**kitchen cabinets**. Open the **Layout** tab, click an opening in the front
view, then use **Split side by side** or **Split top / bottom**. Splits can
contain more splits, so upper and lower dividers need not line up. When an
arrangement can only be built as nested sections (for example doors side by side
below a drawer, different splits in neighbouring columns, or more than four
columns), the editor switches the cabinet to **Sections** and says so; simpler
arrangements keep the single-column or side-by-side bay construction. The panel
title names the selected opening, for example *Top › Column 2*.

Each opening holds a drawer bank, one or two doors, or open shelves. A drawer
bank has its own count and equal, graduated or custom-weighted heights; weights
run from top to bottom. Door and open openings can hold adjustable or fixed
shelves, and a single door can be hinged on either side.

Drag a divider to resize the openings on both sides of it, or type a width or
height in the panel. Typed sizes in a section layout become fixed clear-opening
dimensions (marked *Fixed*; **Make proportional** releases them); dragged sizes
are proportional, so they scale with the cabinet. At least one child per split
stays proportional. Divider thickness is subtracted before space is shared out.
The tree allows 31 nodes and eight nesting levels; clear openings must be at
least 60 mm, and the engine also rejects drawer boxes and doors that would be too
small.

For a row of columns choose full-depth panels or no divider; for a column of rows
also an 80 mm front rail. **Remove this opening** gives its space to a neighbour
and removes a split that is left with one opening; Undo restores it.

## Construction

Section layouts use the same construction as side-by-side bays, generalized to
any arrangement of openings:

- **Dividers are joined.** A vertical divider (partition) runs between the
  members below and above it — the carcass bottom and top, or a horizontal
  divider — and is joined into them with the cabinet's joinery (dado tongue,
  tabs through slots, or butt joints with optional registration holes).
  A horizontal divider runs between the carcass sides or partitions beside it and
  is joined into them like a fixed shelf. Every receiving dado, slot and
  registration hole is in the cut and pocket layouts.
- **Opposed joints.** Where two dividers or shelves meet a member from opposite
  faces at the same place (for example a grid whose dividers line up), their tabs
  share one through-slot and are each half as long, and dados stay shallow enough
  to leave a web between them.
- **Hardware is drilled.** Drawer slide holes (or wood-rail registration holes),
  hinge-plate holes and shelf-pin rows for each opening are drilled into the
  carcass side or partition on each side of it. Partitions are drilled through so
  one row serves the openings on both faces; shelf pins that would meet a hinge
  plate are left out, as on the outer sides.
- **Fronts.** Overlay fronts meet at the centre of each divider with the bay front
  gap, and cover the carcass edges at the outside like any other layout. Inset
  fronts sit inside their own opening with the edge reveal. Drawer boxes always
  stay inside their opening.
- **Face frames.** An outer face frame can surround the layout. Openings at the
  frame are sized to the frame opening (drawer boxes clear the stiles and rails),
  while dividers and shelves run to the carcass. The frame's middle rail and
  center stile are not used in a section layout.

The engine reports every opening, front, shelf and divider as `LAYOUT` records,
so the Layout tab draws the exact fronts. Parts are named like bays: openings are
`B1`, `B2` … in tree order, partitions `BAY-P1` …, horizontal dividers `BAY-D1` ….
Cut, pocket and engraving layouts place dividers in their own rows; they are not
optimized sheet nests.

A split without a divider gives its openings nothing to mount to: the engine
reports an error if a drawer bank, shelves or a hinge needs that side, or if a
divider would end against it.

## Saved designs

Each section row is `[parent, order, axis, size mode, size, contents, count,
drawer heights, graduated step, height weights, divider, shelves behind doors,
hinge side, shelf style]`. Designs saved before hinge side and shelf style were
added have twelve fields; they keep the cabinet's single-door hinge side and
fixed shelves. Earlier versions built section dividers as loose butt-fit blanks;
those designs now open with joined dividers and drilled hardware, and fronts
that meet at the divider centres.

## Photo example

In the cabinet picker (**New** or **Change**), choose **Kitchen cabinet → Section layouts →
Photo example · six drawers and paired doors**. This opens the Layout tab. The included arrangement is:

- Upper left: two drawers, with a smaller upper drawer.
- Upper middle: paired doors in one wide opening.
- Upper right: two drawers, matching the left bank.
- Lower row: two wide drawers beneath the upper three columns.

The example uses an illustrative 1500 × 850 × 600 mm nominal envelope, a 90 mm
base elevation, 1:2:1 upper width weights and equal lower widths. These are not
measurements from the photograph. It reproduces the layout, using the existing
plain fronts; decorative frame-and-panel fronts and pulls in the photograph are
not reproduced.

[Importable web configuration](../examples/photo-section-cabinet.cabinet.json)
can be loaded through Open design. For native OpenSCAD, open
[photo_section_cabinet.scad](../public/engine/v5/examples/photo_section_cabinet.scad)
with the bundled engine directory intact. Change its output_mode to assembly,
flat_3d, bom or an existing cut/pocket/engraving operation.
