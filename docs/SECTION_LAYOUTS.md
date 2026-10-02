# Kitchen section layouts

Choose **Kitchen cabinet** and open the **Layout** tab. Click an opening in the
front view, then use **Split side by side** or **Split top / bottom**. Splits can
contain more splits, so upper and lower dividers need not align. When an
arrangement can only be built as nested sections (for example doors side by side
below a drawer, or different splits in neighbouring columns), the editor switches
the cabinet to **Sections** and says so; simpler arrangements keep the single
column or side-by-side bay construction, which has joined dividers. The panel
title names the selected opening, for example *Top › Column 2*.

Each opening contains a drawer bank, one or two doors, or open shelves. A drawer
bank has its own count and equal, graduated or custom-weighted heights. Weights
run from top to bottom. Door openings can contain shelves. Paired doors share one
opening without an automatic center partition. Adding drawers does not add shelves.

Drag a divider to resize adjacent openings, or type a width or height in the
panel. Typed sizes in a sections layout become fixed clear-opening dimensions
(marked *Fixed*; **Make proportional** releases them); dragged sizes are
proportional, so they scale with the cabinet. At least one child per split
remains proportional. Split panel thickness is subtracted before allocating
space. The tree allows 31 nodes and eight nesting levels; clear openings must be
at least 60 mm, and native checks also reject undersized drawer boxes and doors.

For a row of columns choose full-depth panels or no physical divider; for a
column of rows also an 80 mm front support rail. **Remove this opening** gives its
space to a neighbour and removes a split that is left with one opening; Undo
restores it. Old saved designs keep their layout mode. Global hardware, materials
and machining settings still apply; per-opening hardware presets are not
implemented.

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

## Construction and export limits

The outer carcass and drawer boxes use existing joinery/machining settings.
Interior section dividers, rails and shelves are **butt-fit blanks**. Their receiver
joints and fastening holes are not generated. Fit suitable brackets, cleats or
shop-drilled fasteners, and transfer cabinet-side slide, hinge and shelf-pin holes
during fitting. A logical boundary provides no structural or hardware support.
Warnings accompany these limitations in the editor and exported reports.

Fronts fit within each clear opening; overlay controls only their depth placement,
not coverage across section dividers. An outer face frame can surround the layout;
its global middle rail and center stile are suppressed in Sections mode. Section
supports are separate parts, not decorative face-frame joinery.

BOM and engraving use SEC-prefixed identities. Native cut, pocket and engraving
exports use separate registered bands per opening; these are not optimized sheet
nests. Preserve registration between operations, then remove the dummy outer frame
and nest in CAM. Section machining depths are included in the logs. The schematic
is approximate; review native geometry and all machining operations before cutting.
