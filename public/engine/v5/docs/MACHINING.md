# Manufacturing semantics

CUT is through geometry. POCKET files are separate blind machining operations; their depth and intended face are in the reports. ENGRAVE holds labels. Preserve the shared generator registration frame when importing operations into CAM; do not independently center each layer.

Screw mode supplies face guide holes for the selected joint family. Mating edge pilots, screw selection and installation remain separate shop operations. Butt mode supplies plain geometry unless an explicit legacy registration setting requests guides. Tab-slot uses the shared spacing and relief implementation; confirm fit using actual stock and a coupon. Dado depth must remain within available material.

Equipment backs support full back, panel back and multiple stretchers. Skeletonized sides retain slide/cleat feature zones; rejected combinations must be adjusted rather than bypassing validation. French cleat bevels require the stated angle and thickness; 2D outlines alone do not machine angled bevels. Follow the feature notes in the generated package.

Equipment slide metadata and generic mounting guides must be checked against the purchased hardware drawing. Extending a tray changes loading and tip behavior. Geometric clearance checks do not certify the stand, anchors, substrate or stacking connection.

The exporter rejects failing audits, renderer errors and oversized sheet-planning parts. Warnings remain visible in reports. Sheet planning groups stock by material and thickness, permits rotation unless grain-locked and uses bounding rectangles with inter-part gaps. It is a purchasing/layout estimate, not nested machine-ready G-code.

## Material-specific slot relief

Where supported, use carcass_, drawer_, divider_ and drawer_bottom_ prefixes with
slot_corner_relief and cnc_tool_diameter. Relief options are inherit, none,
dogbone and t_bone. Inherit uses the shared slot_corner_relief; diameter zero uses
the shared cnc_tool_diameter. Drawer-bottom relief defaults to none, while other
material styles default to inherit. Controls apply to existing slot/capture cuts;
they do not add relief to every possible dado or to parts without those cuts.

The material receiving the cut determines its relief/cutter. Drawer-bottom divider
capture therefore uses the bottom override, not the divider cutter. A different
drawer cutter does not change carcass relief. Equipment side_relief and its router
bit remain independent. Use none when relief is supplied separately in CAM.

Joint-fit clearance is relevant to tabs; dado-fit/depth controls are relevant to
dados. A drawer with dado bottom capture can still need drawer dado clearance
when its side joinery differs. The web adapter hides irrelevant controls and keeps
saved values. Kerf width and compensation are advanced web settings.
