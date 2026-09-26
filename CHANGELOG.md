# Changelog

## 0.4.0 — 2026-09-25

Application release; OpenSCAD package remains 5.3.0 (v5 / MOI-4).
Imported from published Sites source 8f6ca7a4dcc1ded679ce9104226e543aaa2135d9.

- Highlight advanced settings and move front settings into Doors/Drawers.
- Add carcass, drawer box, bottom and divider relief styles/cutter diameters.
- Filter dependent settings and joint clearances by active features.
- Retain startup dimension fix, hardware selectors, tooltips and schematic toolbar fixes.
- Retain stackable drawer-bank/open-section and kitchen multi-bay fixes.
- Add a reproducible static build with repository-relative worker/font paths.
- Replace the obsolete ZIP import workflow and superseded comparison notes.
- Exclude generated outputs and accidentally retained geometry-test files.

Validation: production build, TypeScript, integration/visibility/stackable tests,
native relief geometry isolation and browser OpenSCAD worker rendering passed.
Browser visual QA and Windows executable launch were not performed.
Kitchen mixed bays remain full-height columns, without split top/bottom layouts.

## 0.3.1 — historical desktop baseline

Startup dimension classification and desktop diagnostic fixes. This release
record comes from the repository's earlier package comparison; no old desktop
binary is rebuilt or included in 0.4.0.

## Version policy

Use semantic application versions in package.json, VERSION and this changelog.
Patch releases fix bugs; minor releases add compatible features; major releases
make breaking changes. Keep the OpenSCAD package version separate. Each release
commit is named `Release vX.Y.Z`; the GitHub workflow creates the matching tag
after the build passes. Existing release tags are preserved. Never rewrite released history.
