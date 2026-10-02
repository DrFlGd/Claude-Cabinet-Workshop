# Claude Cabinet Workshop

A browser-based cabinet planner built on a parametric OpenSCAD engine. Choose a
shop cart, utility cabinet, benchtop drawer unit, stackable module, kitchen
cabinet, standalone drawer or equipment stand, set its size and contents, and get
an engine-calculated cut list, fit report, exact 3D model and CNC-ready SVG
layouts. Everything runs locally in the browser with bundled OpenSCAD WebAssembly.

This repository is a fork of Cabinet Workshop 0.5.2. Version 0.6.0 focuses on
plan accuracy (parts that actually fit together) and a simpler workflow; see the
[changelog](CHANGELOG.md) for the full list of fixes and how they were verified.

Application version: **0.6.0**. Bundled engine: **Modular Organization 5.3.0**
(engine family v5, interface MOI-4) with the patches recorded in the changelog.
[Documentation guide](docs/README.md).

## Use a release

Download `claude-cabinet-workshop-web-v<version>.zip` from the latest GitHub
release, unzip it and serve the folder over HTTP, for example:

```sh
python3 -m http.server 8080 --directory claude-cabinet-workshop-web-v0.6.0
```

Then open http://localhost:8080/. The release build uses relative paths, so it
also works from any sub-folder of an existing web server. Do not open
`index.html` directly from disk (`file://`); the OpenSCAD workers need HTTP.

## Run from source

Use Node 24 and pnpm 11.25.0:

```sh
pnpm install --frozen-lockfile
pnpm run dev:static
```

Open the HTTP address printed by Vite. See [HOSTING.md](HOSTING.md) for static
builds and GitHub Pages, and [development notes](docs/DEVELOPMENT.md) for tests.

## Design a cabinet

1. **Pick what to build.** The cabinet-type card at the top of the settings
   panel shows the current type and starting point. **Change** (or **New** in
   the header) opens the picker: choose a type, then one of 110 starting
   points, including 48 standard US kitchen sizes. The previous design stays in
   **Recent**.
2. **Work through the sections.** The section buttons follow the order you
   would design in: Sizing, Structure, Drawers, Doors, Shelves and so on, then
   the shop details (Materials, Hardware, Machining, Output). Each button shows
   how many settings apply to the current layout; sections with nothing to set
   are hidden. **Find any setting** searches names and help text. Advanced
   settings stay behind the per-section switch.
3. **Watch the checks.** After every change OpenSCAD recalculates the design
   in the background. The status chip above the preview says whether all parts
   fit, lists notes, or names the problems to fix.
4. **Read the plans.** The **Cut list & fit** tab lists every part grouped by
   material and thickness, sheet-goods totals with an approximate sheet count,
   a drawer fit table (opening, box, usable inside size and clearances), doors,
   shelves and any hardware the engine reports. Copy or download the list as
   CSV, or print it.
5. **Check the geometry.** **Preview** is an instant schematic for orientation
   and part selection. **Exact 3D** is the real OpenSCAD model, including
   joinery, holes and grooves; it re-renders automatically after edits.
6. **Export.** **Export** generates the operation SVGs (through cuts, pockets,
   engraving), reports, a printable assembly packet and the editable OpenSCAD
   project. Exports are blocked while the engine reports an error.

### Units and dimensions

Switch between millimeters and inches in the header. Values are always stored in
millimeters at full precision. Dimension fields accept decimals, fractions and
explicit units: `23 1/2`, `23-1/2"`, `3/4 in`, `600 mm`, `60 cm`, `2' 3"`. In
inch mode the cut list shows sizes to the nearest 1/32 in; hover a size for the
exact millimeter value. CSV exports keep full millimeter precision.

### Kitchen layouts

Kitchen cabinets support a single column, side-by-side bays and **Sections**
(nested top/bottom and left/right splits with independent drawers, doors and
shelves; see the [section layout guide](docs/SECTION_LAYOUTS.md)). Face frames
are supported for single-column and section layouts. Behind a face frame,
independent bays may hold open shelves, overlay doors, or drawers in a middle
bay; drawers in the first or last bay and inset fronts are reported as errors
instead of being drawn with colliding parts.

## Accuracy and its limits

Each change is evaluated by the same OpenSCAD engine that produces the
manufacturing files. Its checks cover drawer boxes against their openings,
slides and runners against box heights, machining features on the side panels,
divider grids and interface keep-outs. The test suite additionally renders
sub-assemblies of representative designs and confirms that no two parts occupy
the same space.

The schematic preview is approximate. Browser layouts are not CNC toolpaths and
do not include the Python final-contour audit. Hardware drilling defaults are
starting points; verify them against the hardware you buy. Geometry checks are
not load or stability certification. Always measure real sheet thickness and
make a test cut before production.

Machining controls are grouped by carcass, drawer box, drawer bottom and drawer
divider, each with its own relief style and cutter where applicable; see
[machining semantics](public/engine/v5/docs/MACHINING.md). The exported source
includes the v5 Python package for desktop inspection and manufacturing; see the
[engine README](public/engine/v5/README.md) and
[integration guide](public/engine/v5/docs/INTEGRATION.md).

## Saving

**Save** downloads a portable design file; **Open** loads one. Autosave and the
ten most recent designs are kept in this browser only, not in the cloud. Older
design files are migrated where supported.

## Releases and evidence

[CHANGELOG.md](CHANGELOG.md) contains the consolidated history, validation
performed and known limits. Pushing a new version to `main` builds and tests the
site, tags `v<version>` and publishes a GitHub release with the portable web
build. Windows packaging (`desktop/`) is a separate test deliverable.
