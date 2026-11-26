# Claude Cabinet Workshop

A browser-based cabinet planner built on a parametric OpenSCAD engine. Choose a
shop cart, utility cabinet, benchtop drawer unit, stackable module, kitchen
cabinet, standalone drawer, equipment stand or modular workbench (or one of your
own products, such as the media cart), set its size and contents, and get
an engine-calculated cut list, fit report, exact 3D model and CNC-ready SVG
layouts. Everything runs locally in the browser with bundled OpenSCAD WebAssembly.

This repository is a fork of Cabinet Workshop 0.5.2. Version 0.6.0 focused on
plan accuracy (parts that actually fit together) and a simpler workflow; 0.7.0
adds the visual layout editor. See the [changelog](CHANGELOG.md) for the full
list of changes and how they were verified.

Application version: **0.20.0**. Bundled engine: **Modular Organization 5.3.0**
(engine family v5, interface MOI-4) with the patches recorded in the changelog.
[Documentation guide](docs/README.md).

## Use a release

Download `claude-cabinet-workshop-web-v<version>.zip` from the latest GitHub
release, unzip it and serve the folder over HTTP, for example:

```sh
python3 -m http.server 8080 --directory claude-cabinet-workshop-web-v0.20.0
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
   the header) opens the picker: choose a type, then one of 120 starting
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
   For the **modular workbench** the Layout tab is a top view of the base
   frame's grid instead: click an empty cell to place a cabinet module, click a
   module to set its contents (doors, drawers, drawers over a door, open, or a
   framed opening), the number of drawers, the side it faces, hinge side,
   height, shelves and how many cells it spans, move it, stack a module on top
   (a module at bench height is split into two stacked halves; stacked modules
   are located by loose keys in the top rails below) or remove it.
   **Fill empty cells** completes the grid. See
   [the workbench design note](docs/MODULAR_WORKBENCH.md).
3. **Work through the settings.** The section rail follows the order you
   would design in: Sizing, Structure, Drawers, Doors, Shelves and so on. The
   shop details (Materials, Hardware, Machining, Engine & export) are collapsed
   under **Shop details** until you need them. Each section shows how many
   settings apply to the current layout and how many more are behind its
   **Show advanced** switch; sections with nothing to set are hidden. Settings
   that do not apply to the current configuration are listed at the end of each
   section, disabled, with the change that would bring them into use.
   **Find any setting** searches names and help text across every section,
   including settings not in use; counts, bays and drawer heights are set in
   the Layout tab and the search points there.
   **Hardware** starts with one choice per kind: how drawers run (metal
   slides, wood runners or none) and which hinge. Only the settings of the
   chosen method are shown; runner settings stay out of the way while metal
   slides are selected (search still finds them). Then pick a slide or hinge
   model: a catalog model fills in and locks the maker's dimensions (**Adjust
   dimensions** unlocks them), and **Generic** makes every dimension editable:
   hole spacing, count, setback, height, diameters, hinge positions, cup and
   fixing-hole drilling and the mounting plate.
4. **Watch the checks.** After every change OpenSCAD recalculates the design
   in the background. The status chip above the preview says whether the
   engine's checks passed, lists notes, or names the problems to fix. The
   **Cut list & fit** tab says what those checks cover (sizes, drawer and shelf
   fit, joinery limits, hardware conflicts, and the flat cut layout, where
   every part has its own place and no two outlines may overlap) and what they
   do not yet cover for your exact design (parts intersecting in 3D, which the
   test suite sweeps for every starter and randomized designs).
5. **Read the plans.** The **Cut list & fit** tab lists every part grouped by
   material and thickness, sheet-goods totals with an approximate sheet count,
   a drawer fit table (opening, box, usable inside size and clearances), doors,
   shelves and any hardware the engine reports. Copy or download the list as
   CSV, or print it.
6. **Check the geometry.** The **3D model** tab has two modes. **Instant** is a
   schematic that updates as you type, for orientation and part selection.
   **Exact** is the real OpenSCAD model, including joinery, holes and grooves;
   it re-renders automatically after edits while it is showing.
   The **Hardware** tab draws the slide or hinge holes on both boards they
   join, with dimensions: the cabinet side and the drawer box side for a
   slide, the cabinet side (mounting plate) and the door for a hinge. Choose
   the left or right side and the drawer or door; the cabinet-side holes are
   the positions the engine drills, and the view flags holes that the slide
   length or panel depth leaves out and plates that do not line up with the
   door's cups.
7. **Export.** **Export** in the header opens the export page (**Design**
   returns to the configurator with the results kept). It generates the operation SVGs (through cuts, pockets,
   engraving), the same operations nested per stock sheet (one folder per sheet
   with an SVG and a DXF per operation, using the sheet size and layout gap
   from the settings; parts keep their drawn orientation unless you allow
   them to turn), reports, a printable assembly packet and the editable
   OpenSCAD project. The page shows the review (health, parts, sheets,
   warnings) beside a preview of each sheet or the full strip per operation. Exports are blocked while the engine reports an error.

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

With tab-and-slot joinery, **Side tab style: Blind pockets (hidden)** stops the tabs in pockets milled
into the inside faces of the sides, so the outsides stay clean, with shoulder
reliefs and screw holes beside the tabs (the default on stackable modules).
Stackable modules can also set **Stack bottom style: Nested in the module below**: the bottom sits
low, between the top stretchers and sides of the module below, so stacked
modules locate in both directions and screw together through the lower
module's sides. The **Door Module, Nested (Reference Joinery)** starter builds
one this way. Its base frame follows the same plans (**Stack base style: Flat
rails and kick board**): flat rails like the module's top stretchers, a toe notch
and a kick board that carries the bottom, so the lowest module sits on the base as
on another module. Stacked doors and drawer fronts cover half of the stretcher
between them, so the gap between stacked fronts is centred on it (**Stack front
seam**). See the [stackable reference](docs/STACKABLE_REFERENCE.md).

## Your products: the media cart

**New → Your products → Media cart** opens a product with its own editor: sloped
or stepped bin rows in adjustable rows and columns, optional lower cubbies and
shelf towers on either or both sides, on casters. Settings are collapsible
sections, each with a one-line summary; the shop details (materials and measured
thickness, crosspiece and panel joinery with fit clearances, corner relief and
cutter, kerf, casters, sheet size and layout gap) are grouped below. The
**Drawing** tab shows a to-scale front elevation and side profile with quick
controls (rows, columns, wall profile, towers, cubbies, casters); click a part to
open its settings. Once the engine check has run, the drawing also outlines the
joinery (tabs, slots and half-laps, dados, holes) and marks the center of
gravity, with a stability summary below: the push at the top and the lean on the
front that would tip the cart, empty, loaded and top loaded, against the forces
and contents set in **Stability**, and what resists racking. **3D model** renders
the exact engine geometry, **Cut list & fit** lists every part with the engine's
checks, and **Assembly** gives the order of assembly and the hardware.
**Export** produces the same manufacturing package as for the cabinets: cut,
drill (holes smaller than the cutter), pocket and engraving layouts, per-sheet
SVG and DXF, reports, an assembly packet and the editable SCAD file. Dados on a
part's second face are laid out for the whole sheet turned over left to right
about its center line, with registration-pin holes on that line; the READ-ME
gives the order.
How the original model was reviewed and corrected is in
[the media cart review](docs/MEDIA_CART_REVIEW.md); adding another product is
described in [development notes](docs/DEVELOPMENT.md#products).

## Accuracy and its limits

Each change is evaluated by the same OpenSCAD engine that produces the
manufacturing files. Its checks cover drawer boxes against their openings,
slides and runners against box heights, machining features on the side panels,
divider grids and interface keep-outs. **Check for intersecting parts** (under
**Cut list & fit**, for every cabinet type and for the media cart) renders the
design's parts or groups of parts one at a time in a background worker, skips
pairs whose bounding boxes are apart and intersects the rest, then lists any two
parts that would occupy the same space. It runs only when asked: a few seconds
for the default media cart and about 1 to 20 seconds for each cabinet type's
default design, longer for large designs. The test suite runs the same check on
every starter and on seeded random designs.

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
build; the release job then requests the Windows workflow for that tag, which
adds its smoke-tested portable Windows build to the same release.
