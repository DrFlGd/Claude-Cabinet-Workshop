# Claude Cabinet Workshop changelog

This is the consolidated, evidence-based history of the work delivered for this
project. It covers application changes, engine integrations, documented engine
package changes, desktop fixes and repository/hosting work. It replaces the
short release summary previously kept here.

Application versions (currently **0.7.1**) are separate from the bundled
**Modular Organization 5.3.0** package, engine family **v5**, and **MOI-4** interface
contract. Older engine labels such as v25, v29 and v34 are not application release
numbers. Historical work without a recorded application version is listed by
milestone rather than assigned an invented release number or date.

The older Sites commit IDs below are provenance references from the original
source repository; those commit objects were not imported into GitHub. GitHub
history starts with repository setup and the source import. This document records
verified changes and historical package notes, not every experiment or every
possible configuration. Imported package capabilities are identified as such.

## 0.7.1 — 2026-10-02

Windows desktop start-up. The application itself is unchanged from 0.7.0.

- The window now opens immediately with a *Starting…* page. Previously nothing
  appeared until the app had read and hashed every runtime file (about 330 MB,
  including the 246 MB EXE) on every launch; on a first launch, with Windows
  scanning the newly extracted files, that could look like the program did
  nothing.
- Each launch now checks that every runtime file is present, readable and the
  size recorded at build time, instead of hashing it. Files that are still being
  extracted or scanned (missing, short or locked) are retried for about four
  seconds before an error is shown. The full SHA-256 comparison is still made by
  the packaged smoke test and on request through **Help → Verify program
  files…**.
- Start-up errors say what happened and what to do: a file still in use
  (extraction or antivirus), a missing file, or a damaged or mismatched file,
  with the file name and the system error code. A start-up log of the last
  launch is saved in the user profile (**Help → Open start-up log**).
- Starting the EXE again while it runs brings the open window to the front.
  START-HERE.txt describes the start-up and the SmartScreen prompt for this
  unsigned build.

Validation: `tests/runtime-integrity.cjs` covers the quick and full checks, size
and hash mismatches, missing files, a file that appears and grows while the check
waits, manifests from earlier builds and path traversal. The Windows workflow
additionally verifies the packaged manifest with both checks and launches the
packaged EXE for the smoke test. The start-up page, retry timing and error
dialogs were not exercised on a desktop interactively.

## 0.7.0 — 2026-10-02

Adds a visual layout editor: the cabinet front is designed by clicking, dragging
and typing sizes instead of through bay arrays and dropdowns.

### Layout editor

- New **Layout** tab, the first tab for shop carts, utility, benchtop, stackable
  and kitchen cabinets. It draws the cabinet front to scale with dimension chains
  (overall size, bay widths, row heights). Click an opening to select it; the
  panel beside the drawing sets its contents (drawers, doors or open shelves),
  the number of drawers, doors and shelves, shelf type, hinge side and drawer
  heights (equal, graduated or custom, with one front height per drawer).
- Drag the divider between two openings, or the line between two drawers, to
  resize them; a label shows both sizes while dragging and sizes snap to 1 mm or
  1/16 in. Typed widths, row heights, drawer front heights and the door height of
  a drawers-over-doors cabinet come out exactly in the engine (checked by the new
  test suite). **Split side by side**, **Drawers over doors** (kitchen: **Split
  top / bottom**) and **Remove this opening** change the arrangement; Ctrl+Z
  undoes any edit.
- The editor chooses the engine construction that can build the arrangement:
  a single column (drawers, doors, drawers over doors, or side-by-side drawer
  columns with joined partitions), up to four side-by-side bays with joined
  partitions, or, for kitchen cabinets only, nested sections. The current
  construction is kept whenever it can still build the edit, and a note appears
  when it changes. Arrangements a cabinet type cannot build are refused with the
  reason (for example stacking openings inside a bay of a shop cart, or doors
  side by side in a stackable module). Kitchen bays behind a face frame that
  would put drawers in an end bay are built as sections instead of failing.
- Fronts, shelves, dividers and the face frame are drawn at the positions the
  engine reports. Until the engine has recalculated after an edit, fronts are
  dashed estimates and the status reads *Recalculating exact sizes*.
- Bay, drawer-count, door-count, shelf-count and drawer-height settings are no
  longer listed in the settings panel; the Structure section and search results
  for them point to the Layout tab. The Structure-step section editor is
  replaced by the Layout tab (the photo example opens there).

### Engine

- New `LAYOUT|…` report records give the exact front-view position of every bay
  or drawer column, drawer and door front, shelf, partition and divider, and the
  face frame. They are report lines only; no geometry changes.
- New `combo_door_height` (mm, 0 = automatic) for shop carts, utility and kitchen
  cabinets sets the door region of a drawers-over-doors cabinet directly instead
  of the fixed three drawer-heights proportion; the drawer stack keeps at least
  40 mm per drawer.
- The existing per-bay and per-bank drawer height arrays
  (`mixed_bay_drawer_height_weights`, `drawer_bank_height_weights`) are now
  settable from the app, so each bay or drawer column can have its own heights.

### Release automation

- The Windows test build workflow attaches its smoke-tested portable build
  (`Claude-Cabinet-Workshop-v<version>-Windows-x64.zip`) to the GitHub release
  tagged at the commit it built, and also runs when `VERSION` changes so each
  release gets one. Started manually with a release tag, it builds that tag's
  sources and attaches the ZIP to that release (this added the 0.6.0 Windows
  ZIP). Existing assets are never replaced, and BUILD-INFO.json records the
  commit the build came from. The Windows smoke test now exercises the Layout
  tab.

### Validation performed

- `tests/layout-editor.mjs` (new, in the release suite and CI): all 88 starters
  of the five cabinet types round-trip through the editor without moving any
  front; 75 openings computed by the editor match the engine's report; typed bay
  width (300 mm), drawer front height (120 mm), door height (500 mm) and a bank
  width land within 0.01 mm in the engine; a dragged drawer/door boundary sets
  the door region the engine reports; column splits, a stackable door module,
  kitchen sections and refusals behave as described.
- 80 random sequences of one to four editor edits on random starters (SEED 11),
  each evaluated by the engine: no undefined values, failed evaluations or front
  count mismatches; the only errors were the reported fit errors that appear when
  edits make drawers too small for their slides or boxes.
- Engine fit suite (110 starters and regressions) and interference suite (now 18
  designs, adding custom door heights with overlay and inset fronts) pass.
- Browser checks on the development server and the static build: dragging a bay
  divider and a drawer line, typing a bay width and drawer height, switching a
  bay to a right-hinged door, adding bays, inch display, undo; kitchen B36
  drawer/door boundary drag, typed door height and a sections split with no
  errors; utility, benchtop and stackable flows; 390 px phone layout; search
  hint; the desktop smoke test's layout steps.
- Static-app TypeScript check (Sites-only modules excluded locally), unit,
  settings visibility, v5 integration and section WASM tests, static build. The
  stackable and section tests that call native OpenSCAD were run locally through
  the bundled OpenSCAD WebAssembly build with the same command-line arguments;
  CI runs them with native OpenSCAD. A Windows test build of this change passed
  the packaged-EXE smoke test (including the new Layout tab steps) before release.

### Known limits

- At most four bays or drawer columns. Only kitchen cabinets can stack openings
  inside a bay; other types offer drawers over doors across the full width.
- Bay widths and drawer heights are stored as proportions, so they scale when
  the cabinet size changes; sizes typed into a kitchen sections layout become
  fixed millimeters.
- Exact typed sizes use the engine's latest report; a size typed while it is
  still recalculating uses the estimate. Sections layouts show estimated fronts
  (the engine reports their openings, not each front).
- Widths of three or four doors across one opening stay in the Doors settings
  (door width weights). The desktop app was not tested interactively.

## 0.6.0 — 2026-10-02

First release of the Claude Cabinet Workshop fork (forked from Cabinet Workshop
0.5.2). The focus is plans whose parts actually fit together, and a simpler path
from "what am I building" to a cut list.

### Fit and accuracy fixes in the bundled engine

These were found by evaluating every starter, every single-option variation of
each cabinet type and randomised option mixes with the production OpenSCAD
worker, and by rendering sub-assemblies of real designs and intersecting them
(two parts must never occupy the same space).

- **Face frames (kitchen default).** Back-dadoed stiles were not pocketed where
  the bottom and top panels pass behind them, leaving a 19 × 6.35 mm overlap at
  every frame corner; shelves, the combo divider and drawer separators also ran
  into the frame. Stiles now carry bottom/top cross pockets (3D model, face-frame
  pocket layout and BOM note), and those interior members start behind the
  frame's back face, so their depth is reduced by the dado depth (default
  kitchen shelf 586.9 → 580.55 mm). The mid-rail back pocket is no longer cut
  because nothing enters it.
- **Drawers behind a face-frame mid rail.** Drawer boxes were placed from the
  carcass divider, 6 mm below the top of the mid rail they must pass. Box openings
  now start above (or stop below) the rail; the default kitchen drawer box changes
  from 152.9 to 136.8 mm tall.
- **Short drawer stacks.** A fixed 40 mm minimum box height made neighbouring
  boxes overlap when openings were shorter (the "Shallow parts 6-drawer" starter
  overlapped by 1.3 mm per drawer). The minimum is now the bottom inset plus bottom
  thickness plus 10 mm, and new errors report a box that cannot fit its opening
  (DRAWER_BOX_FIT), side-mount slides taller than the box (SLIDE_HEIGHT) and wood
  runners that reach above the box (RUNNER_HEIGHT).
- **Rear stretchers.** Drawer boxes, shelves, dividers and drawer-bank partitions
  extended into the rear stretchers (1.5 mm in the wide benchtop starter); they now
  stop at the stretchers' front face.
- **Wood rails and runners** could be longer than the space behind their front
  setback (the benchtop default rails passed 2.5 mm through the back). Rails are
  limited to the rear construction and runners to the back of the drawer box.
- **Standalone drawers** sized from the inside (inside-clear or modular grid) read
  a stock thickness before the engine had assigned it, so the wood-rail length was
  undefined (the BOM showed `undef`); inset faces had the same problem. The values
  are now resolved from the stock inputs.
- **Hinges and shelf pins.** Turning on 35 mm cup or screw-on hinges in the default
  kitchen produced blocking machining-collision errors because front shelf-pin holes
  landed on hinge-plate holes. Pins that would come within 2 mm of a plate hole are
  omitted (standard shop practice) in the 3D model, cut and pocket layouts,
  partitions and the collision ledger.
- **Partitions** (door-hinge, independent-bay and drawer-bank) took their height from
  the face-frame opening, stopping short of the bottom and top panels their joinery
  enters. They now run between the carcass panels and are notched behind face-frame
  rails.
- **Partition joinery at a set-back combo divider.** When the drawers-over-doors
  divider starts behind inset fronts (already the case in 0.5.2) or behind a face
  frame, the door-hinge partitions' top joinery and the drawer-bank partitions'
  bottom tabs were still laid out from the carcass front. Tabs missed their slots
  (14.7 cm³ of overlap in a tab-and-slot B36 combo) and dado tongues hung in front
  of the divider into the inset doors. Partition joinery now covers exactly the
  depth band that the divider's slots and dados are cut in, in the 3D model and
  the cut layouts.
- **Inset doors with three or more doors** overlapped the door-hinge partitions;
  they now close against each partition with the normal reveal. Inset door pairs
  with a face-frame center stile are split the same way.
- **combo_auto mid rail** was also added to door-only cabinets, on top of the doors;
  it now exists only for drawers-over-doors. The **center stile** is used only for a
  pair of doors (ending at the mid rail in combos) instead of crossing drawer fronts.
- Combinations the engine cannot lay out are reported instead of drawn colliding:
  drawers in the first or last independent bay behind a face frame, inset fronts in
  independent bays behind a face frame, a custom mid rail crossing inset fronts,
  drawer separators with side-by-side drawer banks (the full-width separators
  passed straight through the bank partitions; DRAWER_SEPARATOR_BANKS), and
  independent bays with partitions turned off while drawers, shelves or hinges
  need them (shelf tabs reached into the neighbouring drawers;
  MIXED_BAY_PARTITIONS, previously only a console warning).
- The stackable "bottom plane" warning fired for every dado carcass although the
  lift is intentional; the check now allows for it, and the bottom elevation uses
  the same interface-depth limit as the rest of the engine.

### Workflow and interface

- The cabinet type is always visible in a card at the top of the settings; **New**
  and **Change** open a picker with all seven types and their 110 starting points
  (with sizes). The hidden Setup rail is gone and units moved to the header.
- Settings sections are buttons in design order (Sizing, Structure, Drawers, Doors,
  Shelves, … then Materials, Hardware, Machining, Output, System), each with a count
  of applicable settings; sections with nothing to set are hidden. Sizing no longer
  repeats the width/height/depth fields shown by the fit guide.
- OpenSCAD now checks the design in the background after every edit. A status chip
  shows whether parts fit, notes to review or problems to fix.
- New **Cut list & fit** tab built from the engine's BOM and dimension reports:
  parts grouped by material and thickness with plain names, sheet-goods area and an
  approximate sheet count, a drawer fit table (opening, box, usable inside size,
  clearances), doors, shelves, section openings and reported hardware. Copy or
  download as CSV, or print.
- Fitted sizing ("objects in drawers", standalone drawers, equipment stands) appears
  automatically; the separate Calculate button is gone. **Exact 3D** re-renders
  automatically after edits (can be turned off).
- Dimension fields accept fractions and units (`23 1/2`, `3/4"`, `600 mm`, `60 cm`,
  `2' 3"`). Inch values keep four decimals instead of two; inch cut lists show sizes
  to the nearest 1/32 in. Invalid entries are marked instead of silently reverting.
- Plain-language help for about 100 commonly used settings, clearer option names
  (for example "3/4″ nominal (19.05 mm)", "Drawers over doors", "Wood runners") and
  help text included in search. Choosing fixed runners on an equipment stand sets
  tray travel to zero automatically.
- Section-editor labels scale with the panel and use the selected units.
- Manufacturing exports are blocked by any plan error, including undefined engine
  values and drawer-fit failures, not only by engine CHECK errors.
- Keyboard undo/redo (Ctrl/⌘+Z, Ctrl/⌘+Shift+Z or Ctrl+Y). Phones show the preview
  first, then the settings. The Design Health panel and Design summary tab were
  folded into the status chip and the cut list.

### Repository, tests and releases

- `scripts/sync-engine-sources.mjs` keeps lib/engine-sources.json (what the browser
  renders) in step with public/engine; the release suite fails when they differ.
- New `tests/engine-fit.mjs` (every starter plus regression configurations through
  the production worker) and `tests/engine-interference.mjs` (pairwise intersection
  of rendered sub-assemblies for 16 representative designs; carcass sides,
  bottom/top, dividers and partitions are rendered separately so joinery is
  checked against the part that receives it).
  Run with `pnpm run test:engine`; both are part of `test:release`, and CI runs
  each suite as its own step.
- CI builds a portable release (relative base path) and, for a new version on main,
  tags it and publishes a GitHub release with the zipped site. Pages builds use
  `/Claude-Cabinet-Workshop/`.

### Validation performed

- Locally: static-app TypeScript check (Sites-only modules excluded because their
  packages were not installed in the review environment), units, settings
  visibility, v5 integration, section WASM worker, engine fit and engine
  interference suites, and the static production build (also built with a
  relative base and served from a sub-folder).
- Audit sweeps against the final engine: single-option variations of every family
  (952 runs) with no undefined values or unreported errors; pairwise sub-assembly
  intersection of 87 starters of the shop cart, utility, benchtop, stackable and
  kitchen types (the section-layout starter is covered by the section tests) and
  of 120 randomised option mixes, where every remaining overlap coincided with an
  engine error shown to the user. Earlier sweep rounds found the issues fixed
  above.
- Browser check of the built site: default design reports that all parts fit;
  turning off the bay partitions shows the new MIXED_BAY_PARTITIONS problem.
- Browser screenshots of the main flows at 1440 × 900 and 390 × 844 (picker,
  section editor, cut list in mm and inches, exact 3D, fitted sizing).
- The stackable and section native-OpenSCAD tests run in CI only (no native
  OpenSCAD in the review environment); CI must pass before the release is tagged.

### Known limits

- Independent bays behind a face frame support open bays, overlay doors and
  drawers in middle bays only; use Sections for framed drawer layouts.
- Section layouts report section openings in the fit table, not per-drawer boxes.
- The Python package checks (`modular_organization_validate.py`, matrix tests) were
  not re-run. Hardware hole patterns remain starting points to verify against the
  purchased hardware; geometry checks are not load or stability certification.
- Stackable modules with connector-only ganging and wood slides report an
  INTERFACE_KEEPOUT_CONFLICT (the connector keep-outs overlap the wood-slide
  features on the sides); choose another ganging style or drawer mount.
- The Windows package is built by its CI workflow; the desktop app was not
  manually tested for this release.

## 0.5.2 — 2026-09-28

- Rebuilt the Windows portable distribution with runtime integrity verification.
  The executable, DLLs, Chromium resource/locale packs and snapshots are checked
  against a packaging-time SHA-256 manifest before the window opens. Missing or
  mixed-version files now produce a clear extraction error instead of silently
  opening a potentially broken interface. Extract releases into a new folder.
- Added a startup check for browser default styles and Windows regression checks
  for hidden document metadata/style elements and correct header placement.
  Packaged tests now capture WINDOWS-LAYOUT.png for visual review.
- Investigation: the reported raw-CSS/title display was not reproduced by the
  clean Windows package; its new layout assertions passed before application
  changes. Damaged or mismatched runtime resources remain a suspected cause,
  not a confirmed diagnosis of the user's installation. No cosmetic CSS rule
  was added to hide the symptom.
- Validation: Windows build 36410571467 passed with normal launch graphics
  settings and a visible window. All 68 runtime files passed verification;
  metadata/header layout checks, section selection and the photo assembly render
  passed. Reviewed the captured window: no exposed CSS/title text, and Design
  Health and the section organizer displayed correctly. ZIP CRC verification and
  intact/mismatched/missing-runtime tests passed. Build and Pages run 36410571460
  passed the full release suite and static build; website deployment was skipped.
  Confirmation on the originally affected Windows installation is still needed.

## 0.5.1 — 2026-09-27

- Fixed an unwanted horizontal panel in Sections mode: hidden legacy Combo
  contents could still emit its drawer-over-door divider even when a door section
  specified zero shelves. Sections now suppress that legacy divider, its receiver
  machining, BOM/engraving entry and layout allocation. Explicit section dividers
  remain; per-opening shelf counts, including zero, are respected.
- Removed redundant section navigation buttons below the organizer diagram.
  Diagram clicking and the Selected section dropdown remain, as do split actions.
- Selecting a parent highlights all descendant openings, including nested splits;
  selecting a leaf highlights only that opening. Added accessible pressed states.
- Updated the section guide and Windows test build to v0.5.1.
- Regression coverage checks zero/one/three/zero shelves and identical native
  assembly, flat, cut and pocket output regardless of hidden legacy Combo settings;
  selection coverage checks whole-cabinet, parent and leaf membership. The Windows
  smoke check exercises dropdown and diagram selection in the packaged app.
- Validation passed: TypeScript, the release regression suite, native OpenSCAD
  shelf/layout checks, static production build, and Windows EXE startup, dropdown/
  diagram highlighting and photo-example rendering. The portable ZIP passed CRC
  verification; manual visual testing remains outside the automated checks.

## Windows test package — 2026-09-27 (application 0.5.0)

- Restored reproducible Windows x64 portable packaging in `desktop/`, using the
  same v0.5.0 static renderer, section editor and photo example as the website.
- Included the local OpenSCAD WASM runtime, engine assets and photo configuration;
  no website hosting or separate OpenSCAD installation is required.
- Packaging derives its version from package.json, verifies the Electron 44.4.3
  runtime checksum/archive CRCs/PE architecture and requires an empty destination.
  Runtime licenses and supporting files remain together in the portable ZIP.
- Added version information under Help → About and a renderer-crash error dialog.
  Documented extraction, rebuilding and separate desktop autosave storage.
- Validation: static renderer compilation, offline asset routing/build contents,
  production worker section tests, runtime checksum and archive verification.
  A Windows GitHub workflow launches the packaged EXE, checks UI startup and renders
  the photo example through its local protocol. The artifact includes the result;
  the EXE startup and photo rendering passed on the Windows runner. This does not
  replace manual interactive testing. ZIP creation reads the built folder in place
  to avoid Windows rename locks left by recently exited application processes.
- This unsigned test distribution is a folder containing an EXE and dependencies,
  not a single-file executable or installer. Application version remains 0.5.0.

## 0.5.0 — 2026-09-27

- Added kitchen **Sections** mode with nested left/right and top/bottom splits.
  Upper and lower rows can have different divider positions. Legacy and mixed-bay
  configurations retain their original modes; selecting Sections converts mixed
  columns into an editable tree, or creates a starting layout from legacy contents.
- Added a selectable front diagram, parent breadcrumbs, section selector, split
  actions and divider dragging. Clear openings support proportional weights or
  fixed metric/inch dimensions, with at least one flexible child per split.
- Each leaf supports its own drawer bank, paired/single doors, or open shelves.
  Drawer count and equal/graduated/custom height weights are independent per bank.
  Door sections can contain shelves. Paired doors do not add a center divider;
  drawer counts do not automatically add separator shelves.
- Added full-depth split panels, horizontal 80 mm front rails and nonstructural
  layout boundaries. Shared panels are emitted once; nested splits terminate at
  their parent. The outer face-frame middle rail/center stile are suppressed in
  Sections mode to avoid crossing independently defined openings.
- Added bounded tree validation (31 nodes, eight nesting levels), clear-opening
  checks, malformed-import rejection and native drawer/door clearance assertions.
  Saved JSON preserves the tree; Undo/Redo includes section edits.
- Hid global layout/count/height controls superseded by the section editor and
  derives door/drawer visibility from leaf contents. Weighted drawer divisions
  appear in the editor; dragging accounts for SVG scaling and letterboxing.
- Reused existing native drawer/door modules per opening, separating reusable
  layout modules from top-level reports. Added section supports to assembly,
  flat parts, BOM and registered machining layers, SEC-prefixed part identities,
  engraving, section dimensions and machining-depth records.
- Added **Photo example · six drawers and paired doors** to the kitchen starters
  (110 starters total), plus importable JSON and a directly openable native SCAD
  example. The upper row has two drawers / paired doors / two drawers; the lower
  row has two wider drawers. Its 1500 × 850 × 600 mm dimensions are illustrative,
  not measured from the photo; decorative frame-and-panel fronts are not modeled.
- Preserved the example in the application recipe catalog/importer. Updated the
  generated schema, native parameter signature, embedded sources and worker file
  manifest. Added the section layout guide and development/test instructions.
- Construction limits: interior section supports are butt-fit blanks requiring
  brackets, cleats or shop-drilled fastening. Cabinet-side slide/hinge/shelf-pin
  drilling is transferred during fitting. Fronts fit within clear openings;
  overlay controls depth, not coverage over dividers. Hardware/material settings
  remain shared. Registered export bands are not optimized sheet nests.
- Validation: TypeScript and the static production build passed; all release tests
  passed, including new tree, persistence, fixed sizing, mixed conversion, native
  counts/BOM, shelves, SVG registration and invalid-dimension tests. Production
  WASM workers passed photo assembly, flat parts, BOM, cut, hinge-pocket and
  engraving exports. Default native BOMs matched the previous source across all
  seven families after the layout refactor. No interactive browser visual QA is claimed.

## Documentation update — 2026-09-26

- Expanded the changelog to cover the development history and detailed fixes.
- Added source references, validation scope and current limitations.
- Cleaned the README/hosting guide and added a documentation index and development guide.
- Corrected native-vs-web grouping, per-material relief and browser-vs-Python API guidance.
- Marked historical reports/versioned engine notes explicitly and synchronized embedded documentation.
- Documentation only; application version remains 0.4.1.

## 0.4.2 — 2026-09-26

- Moved cabinet mount style and equipment mount mode into Mounting / Mount Style.
- Moved existing back-panel and rear-stretcher controls into Mounting / Rear Mounting.
  Rear mounting describes existing rear construction; no new wall-fastener or
  cabinet French-cleat system is implied. Door/drawer front mount style remains
  with its front settings.
- Exposed kitchen toe-kick height, setback, bottom elevation and side-cutout mode
  (None/Left/Right/Both) in native public controls and the generated web schema.
- Kept toe-kick controls under Structure / Base, visible for a floor-mounted
  toe-kick base; hid floor-base selection for wall cabinets.
- Synchronized native schema, embedded engine source and kitchen contract signature.
- Added mounting-group/visibility coverage and checked native cutout geometry.
- Ongoing changes are recorded here with each release.

## 0.4.1 — 2026-09-25

GitHub release commit: `f7106b7ac6f88e53a16ec8522f2119e2bce3417e`.

- Added a definition for **Face frame mid rail mode** to setting help: the mid
  rail is a horizontal crosspiece between the frame's top and bottom rails.
- Explained each mode: **None** omits the rail; **Combo auto** centers it at the
  top of the door region, typically between lower doors and upper drawers;
  **Custom** uses the entered center height measured from the cabinet base.
- Explained that the mid rail requires face-frame construction.
- Classified both **kerf width** and **apply kerf compensation** as advanced
  controls across applicable families. Their saved values and geometry semantics
  remain unchanged. Searching still follows the existing advanced-search behavior.
- Updated package.json, VERSION and release references in the README/hosting guide.
- Local settings checks and TypeScript validation passed before the push.

## 0.4.0 — 2026-09-25

The GitHub import consolidated the current web application, including the
pre-import fixes detailed below. Source baseline:
`8f6ca7a4dcc1ded679ce9104226e543aaa2135d9` from Sites.
Initial GitHub release commit: `0d61f1414012d589e9dea94781d6f7d67f8610fb`;
CI dependency follow-up: `1880f4cf24d09738d0ea1188c7edebd8a3732759`.

### Advanced controls and settings organization

- Added an **Advanced** badge, gold border and light background to advanced fields
  so enabling advanced controls makes the additional settings identifiable.
- Removed the top-level **Fronts** category in the web interface.
- Moved drawer-front controls into **Drawers / Fronts** and door gap into
  **Doors / Fronts**.
- Exposed shared front-construction settings in both applicable Doors and Drawers
  sections. Both views edit the same underlying value; help identifies them as
  shared rather than implying independent door/drawer construction settings.
- Updated part-selection navigation so drawer fronts open Drawers and door parts
  open Doors. Gave repeated shared controls section-specific element IDs.
- Grouped machining controls by carcass, drawer boxes, drawer bottoms and drawer
  dividers while retaining appropriate shared and equipment-specific settings.

### Material-specific slot relief

- Added relief style and cutter-diameter overrides for supported slot-bearing
  materials: carcass, drawer box, drawer divider and drawer bottom.
- Added `carcass_slot_corner_relief` / `carcass_cnc_tool_diameter`,
  `drawer_slot_corner_relief` / `drawer_cnc_tool_diameter`,
  `divider_slot_corner_relief` / `divider_cnc_tool_diameter`, and
  `drawer_bottom_slot_corner_relief` / `drawer_bottom_cnc_tool_diameter` where
  supported by the frontend.
- Supported shared-style inheritance, None, Dogbone and T-bone selections.
  A cutter override of zero inherits the shared cutter diameter.
- Defaulted carcass, drawer-box and divider styles to inherit. Drawer-bottom
  capture grooves default to None to preserve their prior geometry.
- Routed shared relief primitives through the material receiving the cut, so a
  smaller drawer cutter does not change the carcass relief.
- Applied material-aware cutters to frame relief cuts and drawer tab-slot relief
  reach calculations. Added relief-capable drawer-bottom divider capture geometry
  in both flat cuts and 3D pockets.
- Kept equipment side-panel relief and its router-bit controls separate.
- Showed per-material controls only when the relevant joinery/divider feature is
  active; hid cutter overrides when the effective relief style is None.
- Made tab-fit, dado-fit and depth controls conditional on the selected joints.
  Drawer dado clearance remains available when the bottom uses a dado even if
  the drawer side joints do not.
- Updated native controls, generated schemas, embedded engine sources and reviewed
  parameter-contract signatures together.

### Source repository, static hosting and versioning

- Imported actual source files into `DrFlGd/Cabinet-Workshop`, preserving the
  repository's existing history instead of uploading a ZIP or rewriting history.
- Replaced the obsolete checksum-pinned ZIP import/deploy workflow.
- Removed superseded FEEDBACK-VERIFICATION.md and PACKAGE-COMPARISON.md from the
  working tree; their earlier versions remain in Git history.
- Removed accidentally retained temporary geometry-test output from the import.
- Added ignore rules for generated static builds, Python caches, TypeScript build
  caches and temporary geometry-test directories.
- Retained engine sources, compatibility code, required runtime files, licenses,
  examples, tests and useful Markdown documentation.
- Added a standalone React/Vite entry point and `dev:static` / `build:static`
  commands; retained the original Sites build configuration.
- Added visible startup/import failure handling to the static entry point.
- Made worker, license and engraving-font URLs work under a repository subpath.
  Configured GitHub builds for `/Cabinet-Workshop/`.
- Added a self-contained historical-schema fixture so migration checks no longer
  depend on a commit available only in the old Sites repository.
- Added CI for dependency installation, TypeScript, release checks and static
  builds, including installation of native OpenSCAD for geometry checks.
- Added a Pages artifact and an explicit manual deployment option. Ordinary
  pushes build/check the app without publishing the Pages site.
- Added VERSION, semantic application versioning, release notes and automatic
  immutable version tags after successful main-branch builds.
- Documented local builds, static serving, GitHub Pages setup and the distinction
  between repository privacy and website visibility in HOSTING.md.
- GitHub's corrected build and version-tag jobs passed for 0.4.0. The initial
  run lacked native OpenSCAD; the follow-up commit supplied that dependency.

## Pre-import web fixes included in 0.4.0

These were delivered as Sites updates before the GitHub release. They were not
separate numbered application releases.

### Startup and field typing

- Fixed dimensional-field classification so schema unit metadata does not turn
  enum strings, booleans, counts or relative weights into physical lengths.
- Prevented the startup failure caused by formatting values such as `outside`
  through numeric `.toFixed()` conversion.
- Corrected schema units and retained decimal measured-stock input, millimeter
  storage, and metric/inch presentation without rounding saved values.

### Hardware, labels and help

- Moved wood rail thickness into Hardware rather than Materials in the web schema.
- Made slide and hinge preset selectors available together, removing the extra
  hardware-category dropdown step.
- Kept presets as one-time patches to editable settings.
- Changed displayed labels **legacy spacing** to **Manual spacing** and
  **explicit_array** to **Manufacturer defined**, retaining internal enum values
  for compatibility with saved designs and the engine.
- Replaced always-visible setting descriptions with an information icon and
  tooltip help, available from the label/icon and focusable help control.
- Removed the non-editable model-code control from configuration settings.

### Dependent-control visibility

- Hid drawer weighting until custom-weight height mode is selected and graduated
  step controls until graduated mode is selected.
- Applied corresponding height-mode dependencies to independent bays and banks.
- Hid tab count, tab spacing, tab width and tab-placement controls until their
  applicable tab-and-slot carcass joinery is selected; distinguished fixed count
  from adaptive-spacing controls.
- Hid drawer hardware when no drawers are present; distinguished metal slides
  from wood runners and gated drilling details behind their enable switches.
- Hid hinge-specific cup, plate and fixing controls when those features are off;
  applied matching dependencies to handles and registration holes.
- Gated overlay/inset, face-frame, toe-kick, back/stretcher, separator, caster,
  leveler, worktop, shelf-hole, equipment and French-cleat detail controls.
- Hid measured-stock fields unless custom stock is selected, and kerf width
  unless compensation is enabled.
- Removed the Show inactive override so dependency filtering consistently applies.
  Hiding a field retains its value instead of discarding the user's configuration.

### Kitchen independent bays

- Exposed mixed-bay width weights, front gap and partition controls in native
  kitchen parameters and the web schema.
- Supplied defaults for all four bay types/weights and enabled partitions by
  default so configured bays can produce their separating panels.
- Fixed the missing/hidden controls behind independent-bay rendering problems.
- Verified representative two-, three- and four-bay native/browser-worker renders.
- Added an explicit explanation that independent bays are full-height columns,
  numbered left to right, and that Bay count activates bays 3 and 4.
- Did **not** add arbitrary split top/bottom bay composition; the requested mixed
  upper-drawer/lower-door arrangement remains outside this layout model.

### Stackable cabinet controls

- Routed drawer modules through the native drawer-bank layout instead of the
  mixed-bay route that bypassed bank settings.
- Normalized module/content values so stale imported settings cannot leave drawer
  modules behaving like open modules.
- Exposed the effective shelf-count control for open and door modules: zero
  shelves gives one open section, with one additional section per added shelf.
- Hid ineffective mixed-bay controls and irrelevant drawer-bank settings for
  stackable open/door modules.
- Kept schematic counts, exported source and controls consistent across repeated
  open → drawers → door transitions.

### Schematic toolbar

- Changed toolbar placement to prevent Show interior, Exploded, Dimensions and
  Inspect geometry controls from overlapping nearby text.

Provenance: Sites commits `4f104a3`, `0fa7c31`, `2290e36`, `4d8c807`, `665bb21`,
and `8f6ca7a`; focused checks live in tests/settings-visibility.cjs,
tests/kitchen-bays.cjs, tests/layout-controls.cjs, tests/stackable-controls.cjs
and tests/material-relief.py.

## 0.3.1 — historical desktop startup fix

This section is reconstructed from the earlier package-comparison record, not
from a rebuilt desktop release in the current repository.

- Fixed the dimensional-classification startup crash described above.
- Added a bootstrap loading message, dynamic-import failure reporting and a React
  startup error boundary with a reload action.
- Added Electron startup logging, asset/navigation/crash diagnostics, error dialogs,
  and menu actions for developer tools and the startup log.
- Advanced desktop packaging metadata from 0.3.0 to 0.3.1 and regenerated its static
  web bundle; added startup regression checks and repair documentation.
- The historical validation note reported 13,807 scalar dimensional configurations.
  That figure is historical evidence, not a new test run for this documentation.
- No new Windows executable or Windows launch verification is included in 0.4.x.

## Earlier web application milestones

### Initial configuration workspace and visualization

- Built the React/TypeScript cabinet workspace from the shared OpenSCAD engine,
  including family selection, editable settings and a quick schematic.
- Added cancellable OpenSCAD WebAssembly rendering in a separate worker alongside
  the schematic, render stages/logs, and bundled runtime/license files.
- Fixed orbit interaction after pointer release/cancellation and used depth-tested
  panels/edges to stop hidden parts bleeding through the schematic.
- Added the five-family v25 integration, starter recipes and component settings.
- Embedded engine source text with the application and preserved legacy render
  paths so older open tabs/designs were not dependent on replaced source URLs.
- Removed unused starter artwork and generated compiler cache.

Source commits: `c6cfc99`, `2062e95`, `14d8771`, `11fb1ec`, `b09716a`, `ab1fc59`,
`cc656ad`.

### Sizing, editing and recovery

- Integrated v29 reverse sizing from desired drawer-interior dimensions, using
  direct dimensions or modular-grid targets with minimum/exact policies.
- Added engine-based fit results reporting requested/achieved sizes and the solved
  cabinet envelope; height remains an outside-envelope dimension.
- Added metric/inch display with two-decimal presentation and full-precision
  millimeter storage, including arrays and automatic expression-backed defaults.
- Added local autosave, recovery, ten recent designs, portable design JSON import
  and export, and migration of older design formats/parameter aliases.
- Added replacement/unsaved-work protection for family, starter, import and reset
  actions, together with undo/redo and guided editing.
- Added part selection and related-setting navigation. Native combined-mesh part
  guides are approximate rather than per-part CAD selection.
- Expanded the settings workspace, corrected printable assembly-face depth order,
  and repaired mobile settings placement and narrow-screen controls.

Source commits: `1778886`, `9f77436`, `1c6804a`, `2bc1fe2`, `680c7ff`.

### Manufacturing review and engine/catalog integrations

- Added a frozen manufacturing-review snapshot with BOM quantities/cut sizes,
  warnings, SVG operation outputs, depth/face notes and logs before download.
- Invalidated review after edits and cancelled active export work on dismissal.
- Included configured SCAD, source resources, design JSON, CSV/text reports and a
  printable HTML assembly packet with schematic guides and part identifiers.
- Integrated the v34-era bundle, standalone drawer family and hardware recipes.
- Restored the application-owned standard kitchen catalog and preserved it across
  subsequent engine imports.
- Integrated Modular Organization v3 and Design Health. Manufacturing checks use
  current configuration, surface warnings and block semantic CHECK errors.
- Added compatibility/source-bundle, catalog, recovery, unit and schematic tests.
- Organized hardware and machining by their actual scope; removed generated Python
  caches from engine distribution.
- Integrated the nested v5 Python/SCAD package, equipment-stand family and equipment
  hardware catalog, bringing the current app to seven families and 109 starters,
  including 48 application-owned standard kitchen configurations.
- Updated source export, worker allowlists and schema-driven capabilities for the
  nested package and its supported manufacturing/report modes.

Source commits: `1778886`, `0a91a74`, `5d08ac0`, `4c7d6d1`, `c67c22f`, `d606da1`,
`fbb9c58`. Earlier intermediate catalog counts are not the current starter count.

## Documented engine-package evolution

The following summarizes bundled release/migration/review documents. These are
engine capabilities and package work integrated into the app, not claims that
every capability has a dedicated web interface.

### Storage v29: drawer-interior target sizing

- Added outside-vs-drawer-interior width/depth bases, minimum/exact targets, modular
  pitch/count/edge-clearance inputs and target-bank selection.
- Added TARGET/INFO records and explicit invalid/unmet-target diagnostics.
- Preserved outside-envelope defaults and corrected solved kitchen nominal-depth
  reporting for drawer-target sizing.

Source: [V28 → V29 migration](public/engine/MIGRATION_V28_TO_V29.md).

### Storage v32: editable hardware recipes

- Replaced persistent slide/hinge profile resolution with one-time `apply` patches
  to canonical settings; removed public profile-ID geometry parameters.
- Added explicit member hole arrays and separate cabinet/drawer hole diameters.
- Retained the earlier spacing/count mode as a compatibility default.

Source: [V31 → V32 migration](public/engine/MIGRATION_V31_TO_V32.md).

### Modular Organization v3: composition

- Added MORG-1 project JSON/schema, module registry, MODULE and INTERFACE_FRAME
  records, rigid mates, contains relationships and derived span worktops.
- Added conservative envelope collision checks, optional per-module STL rendering
  and assembly previews; carried module/frame records into manufacturing contracts.
- Limited automatic mating to translation and orthogonal Z rotation.

Sources: [v3 release](public/engine/RELEASE_V3.md),
[v2 → v3 migration](public/engine/MIGRATION_V2_TO_V3.md).

### Equipment stands and v5 package review

- Integrated pull-out equipment stands, tray/hardware controls, optional
  skeletonized sides and French-cleat mounting alongside cabinet/drawer families.
- Refactored loose scripts into an installable Python package with centralized
  resource paths and website-facing API/CLI entry points.
- Split shared core responsibilities into resolution/contracts, frame geometry
  and drawer geometry; shared joinery primitives with equipment stands.
- Standardized decimal material-thickness controls and common stock normalization.
- Distinguished plain butt geometry from screw-guide joinery; kept carcass and
  drawer joinery separate and supported the old equipment joinery key as an alias.
- Fixed stackable bottom dados intersecting reserved stacking geometry.
- Added bounded renderer execution and error detection even when OpenSCAD returns
  a zero exit code after reporting errors.
- Unified preset handling; validated/copied project input; checked safe IDs,
  duplicate IDs, references and cycles; rejected fractional orthogonal rotations.
- Required complete interface identity/standard/role records and rejected duplicate
  hardware IDs instead of silently overwriting them.
- Fixed exact-fit nesting edge gaps and duplicate free-rectangle pruning.
- Rejected invalid BOM dimensions/quantities and handled zero quantities correctly.
- Expanded DXF arc bulges for audits and rejected unsupported entities/empty cuts.
- Gated manufacturing publication on audit success and used temporary output plus
  atomic replacement to protect previously valid exports.
- Removed redundant recipe/hardware-preset copies, historical snapshots, nested
  export archives and one-off scripts while retaining production resources,
  examples, tests and documentation.

Sources: [package review](public/engine/v5/docs/REVIEW.md),
[package README](public/engine/v5/README.md),
[migration](public/engine/v5/docs/MIGRATION.md).

### Engine 5.3.0: consistent parameter organization

- Standardized section order across all seven native frontends and generated schema.
- Added the parameter-layout contract, ordered group lists and schema-v7 metadata.
- Enforced recognized section order, unique public IDs and consistent shared-key
  groups during generation; documented conventions for future modules.
- Preserved public parameter names, defaults, ranges, enums and native presets
  during this organizational change; hid internal standalone_drawer_mode.
- Preserved OpenSCAD expression evaluation order around derived controls.
- Later web presentation changes (Fronts regrouping and wood-runner placement)
  are adapter behavior; the original native section contract remains documented.

Source: [parameter conventions](public/engine/v5/docs/PARAMETER_CONVENTIONS.md).

## Validation scope and remaining limitations

- Application checks cover field dependencies, migrations, units, source bundles,
  presets, finite schematic geometry and stackable module transitions. Production
  builds and TypeScript checks have been run for the relevant releases.
- Native relief tests verify that each material's cutter changes its own geometry
  while unrelated cutters leave it unchanged; None and T-bone also differ.
- Browser OpenSCAD worker verification included representative kitchen multi-bay
  and stackable-bank renders. Earlier v5 integration notes record default-family,
  kitchen/equipment-preset and representative manufacturing checks.
- These are release-specific checks, not a claim that every historical test was
  rerun for every change or every parameter combination has been validated.
- Supervised browser visual QA was unavailable during the recent releases.
  A successful worker/build test does not establish that preview service health
  or every browser interaction has been tested.
- Windows launch testing was not available; no new desktop binary is promised by
  a web/source release.
- Legacy kitchen Mixed bays remain full-height columns. Sections mode adds nested
  splits, with the butt-fit support and shared-hardware limits listed in 0.5.0.
- The schematic is approximate; it does not reproduce all joints, pockets, cleat
  bevels or cutouts. Exact OpenSCAD geometry remains authoritative.
- SVG layouts and rectangular nesting are not CNC toolpaths. Browser Design Health
  is not the Python final-contour audit or structural/load certification.
- Local autosave/recent designs are browser-local, not cloud backups.
- The bundled engine's own review and machining documents describe additional
  finite-coverage and manufacturing constraints.

## Version policy

Keep the application version synchronized in package.json and VERSION and add a
release entry here. Patch versions fix bugs or make small compatible changes;
minor versions add compatible features; major versions introduce breaking changes.
Keep the engine package/interface versions separate. Documentation-only history
expansions do not require an application version bump.

Name release commits `Release vX.Y.Z`. The GitHub workflow tags new application
versions after a successful main-branch build and preserves existing tags.
Do not rewrite released history. Pages publication remains a separate manual
workflow option; a source push/version tag is not a hosting deployment.
