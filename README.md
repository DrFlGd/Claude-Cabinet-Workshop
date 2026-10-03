# Claude Cabinet Workshop

A browser-based cabinet planner built on a parametric OpenSCAD engine. Choose a
shop cart, utility cabinet, benchtop drawer unit, stackable module, kitchen
cabinet, standalone drawer or equipment stand, set its size and contents, and get
an engine-calculated cut list, fit report, exact 3D model and CNC-ready SVG
layouts. Everything runs locally in the browser with bundled OpenSCAD WebAssembly.

This repository is a fork of Cabinet Workshop 0.5.2. Version 0.6.0 focused on
plan accuracy (parts that actually fit together) and a simpler workflow; 0.7.0
adds the visual layout editor. See the [changelog](CHANGELOG.md) for the full
list of changes and how they were verified.

Application version: **0.7.1**. Bundled engine: **Modular Organization 5.3.0**
(engine family v5, interface MOI-4) with the patches recorded in the changelog.
[Documentation guide](docs/README.md).

## Use a release

Download `claude-cabinet-workshop-web-v<version>.zip` from the latest GitHub
release, unzip it and serve the folder over HTTP, for example:

```sh
python3 -m http.server 8080 --directory claude-cabinet-workshop-web-v0.7.1
```

Then open http://localhost:8080/. The release build uses relative paths, so it
also works from any sub-folder of an existing web server. Do not open
`index.html` directly from disk (`file://`); the OpenSCAD workers need HTTP.

On Windows you can instead download
`Claude-Cabinet-Workshop-v<version>-Windows-x64.zip` from the same release,
extract all of it into a new folder and run `Cabinet Workshop.exe`. It is an
unsigned portable test build (Windows may warn about an unrecognized app; choose
**More info → Run anyway**) and needs no web server. Its window opens at once
with a *Starting…* page while the program files are checked; see the
[desktop notes](desktop/README.md).

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
2. **Arrange the front in the Layout tab.** The **Layout** tab (the first tab
   for shop carts, utility, benchtop, stackable and kitchen cabinets) shows the
   cabinet front to scale. Click an opening to select it; the panel beside the
   drawing sets its contents (drawers, doors or open shelves), the number of
   drawers, doors and shelves, shelf type, hinge side and drawer heights. Drag a
   divider between openings, or the line between two drawers, to resize them
   (sizes snap to 1 mm or 1/16 in), or type exact widths, heights and drawer
   front heights. **Split side by side** adds a bay or drawer column, **Drawers
   over doors** adds a drawer row above doors, and shop carts, utility and
   kitchen cabinets can split any opening top/bottom or left/right. The editor
   picks the engine construction that can build the arrangement (single column,
   side-by-side bays or sections), keeps the current one when it still can, and
   says why an
   arrangement is not possible for a cabinet type. Fronts are drawn at the
   positions the engine reports; dashed fronts are estimates while it
   recalculates.
3. **Work through the settings.** The section buttons follow the order you
   would design in: Sizing, Structure, Drawers, Doors, Shelves and so on, then
   the shop details (Materials, Hardware, Machining, Output). Each button shows
   how many settings apply to the current layout; sections with nothing to set
   are hidden. **Find any setting** searches names and help text; counts, bays
   and drawer heights are set in the Layout tab and the search points there.
   Advanced settings stay behind the per-section switch.
4. **Watch the checks.** After every change OpenSCAD recalculates the design
   in the background. The status chip above the preview says whether all parts
   fit, lists notes, or names the problems to fix.
5. **Read the plans.** The **Cut list & fit** tab lists every part grouped by
   material and thickness, sheet-goods totals with an approximate sheet count,
   a drawer fit table (opening, box, usable inside size and clearances), doors,
   shelves and any hardware the engine reports. Copy or download the list as
   CSV, or print it.
6. **Check the geometry.** **Preview** is an instant schematic for orientation
   and part selection. **Exact 3D** is the real OpenSCAD model, including
   joinery, holes and grooves; it re-renders automatically after edits.
7. **Export.** **Export** generates the operation SVGs (through cuts, pockets,
   engraving), reports, a printable assembly packet and the editable OpenSCAD
   project. Exports are blocked while the engine reports an error.

### Units and dimensions

Switch between millimeters and inches in the header. Values are always stored in
millimeters at full precision. Dimension fields accept decimals, fractions and
explicit units: `23 1/2`, `23-1/2"`, `3/4 in`, `600 mm`, `60 cm`, `2' 3"`. In
inch mode the cut list shows sizes to the nearest 1/32 in; hover a size for the
exact millimeter value. CSV exports keep full millimeter precision.

### Section layouts

Shop carts, utility and kitchen cabinets support a single column, side-by-side
bays and **Sections**: nested top/bottom and left/right splits with independent
drawers, doors and shelves, made in the Layout tab. Section dividers are joined
with the carcass joinery and each opening's slides, hinges and shelf pins are
drilled into the members around it; see the
[section layout guide](docs/SECTION_LAYOUTS.md). On kitchen cabinets, face frames
are supported for single-column and section layouts. Behind a face frame,
independent bays may hold open shelves, overlay doors, or drawers in a middle
bay; for other arrangements behind a face frame the Layout tab builds the
cabinet as sections instead.

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
build; the Windows workflow then adds its smoke-tested portable Windows build to
the same release.
