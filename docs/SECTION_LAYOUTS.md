# Kitchen section layouts

Choose **Kitchen cabinet → Structure → Cabinet layout mode → Sections**.
Click an opening in the front diagram, then split it left/right or top/bottom.
Splits can contain more splits, so upper and lower dividers need not align.
Select parents using the Selected section menu; all descendant openings highlight
together. Click an individual opening to select just that section.

Each opening contains a drawer bank, one or two doors, or open shelves. A drawer
bank has its own count and equal, graduated or custom-weighted heights. Weights
run from top to bottom. Door openings can contain shelves. Paired doors share one
opening without an automatic center partition. Adding drawers does not add shelves.

Drag a divider to resize adjacent openings, or use proportional weights and fixed
clear-opening dimensions. Fixed dimensions follow the current metric/inch display.
At least one child per split must remain proportional. Split panel thickness is
subtracted before allocating space. Dragging changes both adjacent sizes to weights.
The tree allows 31 nodes and eight nesting levels; clear openings must be at least
60 mm, and native checks also reject undersized drawer boxes and doors.

Choose full-depth panels, an 80 mm front support rail for horizontal splits, or a
logical boundary with no physical divider. Replace split with one opening removes
its descendants; Undo restores them. Legacy and Mixed bays remain available and
old saved designs retain their original mode. Selecting Sections converts mixed
columns and creates an initial layout from legacy contents; inspect sizes before
using it. Re-selecting Sections creates a fresh conversion; save or Undo to recover
an earlier tree. Global hardware, materials and machining settings still apply;
per-opening hardware presets are not implemented.

## Photo example

In the kitchen starter list, choose **Section layouts → Photo example · six drawers
and paired doors**. This opens the Structure editor. The included arrangement is:

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
