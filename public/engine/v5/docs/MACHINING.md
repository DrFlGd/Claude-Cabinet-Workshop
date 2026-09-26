# Manufacturing semantics

CUT is through geometry. POCKET files are separate blind machining operations; their depth and intended face are in the reports. ENGRAVE holds labels. Preserve the shared generator registration frame when importing operations into CAM; do not independently center each layer.

Screw mode supplies face guide holes for the selected joint family. Mating edge pilots, screw selection and installation remain separate shop operations. Butt mode supplies plain geometry unless an explicit legacy registration setting requests guides. Tab-slot uses the shared spacing and relief implementation; confirm fit using actual stock and a coupon. Dado depth must remain within available material.

Equipment backs support full back, panel back and multiple stretchers. Skeletonized sides retain slide/cleat feature zones; rejected combinations must be adjusted rather than bypassing validation. French cleat bevels require the stated angle and thickness; 2D outlines alone do not machine angled bevels. Follow the feature notes in the generated package.

Equipment slide metadata and generic mounting guides must be checked against the purchased hardware drawing. Extending a tray changes loading and tip behavior. Geometric clearance checks do not certify the stand, anchors, substrate or stacking connection.

The exporter rejects failing audits, renderer errors and oversized sheet-planning parts. Warnings remain visible in reports. Sheet planning groups stock by material and thickness, permits rotation unless grain-locked and uses bounding rectangles with inter-part gaps. It is a purchasing/layout estimate, not nested machine-ready G-code.
