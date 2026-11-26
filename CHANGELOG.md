# Claude Cabinet Workshop changelog

This is the consolidated, evidence-based history of the work delivered for this
project. It covers application changes, engine integrations, documented engine
package changes, desktop fixes and repository/hosting work. It replaces the
short release summary previously kept here.

Application versions (currently **0.24.0**) are separate from the bundled
**Modular Organization 5.3.0** package, engine family **v5**, and **MOI-4** interface
contract. Older engine labels such as v25, v29 and v34 are not application release
numbers. Historical work without a recorded application version is listed by
milestone rather than assigned an invented release number or date.

The older Sites commit IDs below are provenance references from the original
source repository; those commit objects were not imported into GitHub. GitHub
history starts with repository setup and the source import. This document records
verified changes and historical package notes, not every experiment or every
possible configuration. Imported package capabilities are identified as such.

## 0.24.0 — 2026-11-26

The modular workbench can put two drawers side by side on each level, its slides
can come from the Hardware panel's slide catalog, the pull stock is checked, and
the bundled Python package's generated schema and parameter contract are back in
step with every cabinet type, with a CI step that keeps them there (see
`docs/MODULAR_WORKBENCH.md`).

- **Two drawers side by side.** A `drawers` module two or more cells across its
  face has a new **Drawers across** choice in the Layout tab: *One wide* (as before)
  or *Two side by side* (the module row's eleventh entry, 2). A centre partition of
  carcass stock runs from the front edge to the back between the bottom and the top
  rails, located by flush through tenons (one through the bottom in the middle half
  of each cell row, clear of the registration pockets, and one 45 mm tenon through
  each top rail). Mortises get dogbones and the tenon roots T-bone reliefs; the back
  is screw-marked into the partition's rear edge (three screws), and stacking-key
  sites that would meet a rail mortise are skipped. Each column has its own drawer
  box, front (half the module width less `door_gap`) and pull, named
  `M#-DRAWER-1L` / `M#-DRAWER-1R`; in a two-cell module a box is 347.6 mm wide.
  The two slides beside the partition share it: one through hole per listed
  cabinet hole (`partition_slide_hole_diameter`, 6 mm) takes a binding post (sex
  bolt) holding the slide on each face, so the screws of two slides never meet
  inside 18 mm stock. The cut list, BOM (`drawer_partition`), DIM records
  (`DIM|PARTITION`, one `DIM|DRAWER` per column with the cell opening), hardware
  list (slide pairs per column, `slide_binding_posts`, screws), 3D schematic,
  exact render and Layout summary ("3 × 2 drawers") follow. A new starter,
  **Side-by-side drawers**, shows it. *One wide* remains the default, and existing
  designs load unchanged.
- **Checks.** `DRAWER_NARROW` (a box narrower than its sides plus 50 mm),
  `PARTITION_TENONS` (no room for the tenons), `PARTITION_RAIL` (hand slots meeting
  the partition mortises), `PARTITION_HOLES` (partition holes too large for the
  slide) are errors; `DRAWER_COLUMNS` warns when two columns are asked of a
  one-cell or `drawer_door` module, which keep one column.
- **Slide catalog for the workbench.** The Hardware step's **Drawer slides** card
  now appears for the workbench, with the same *Generic slide* / catalog model
  picker and *Fill from* templates as the other cabinet types (72 side-mount
  models). A model sets slide length, side clearance, front setback, profile
  height and, where the maker's drawing is unambiguous, the hole arrays; catalog
  values are locked until *Adjust dimensions*. The workbench uses side-mount metal
  slides only and drills every listed hole on the slide's centre line, centred on
  the drawer box, so the panel shows no mounting-method control and a model's
  mounting choice, hole-pattern mode, drilling mode and hole heights are not used
  (the package marks those four settings not applicable to the workbench; its
  `validate()` rejects a non-metal slide or legacy hole spacing with holes on).
  Catalog models that leave drilling off drill nothing. New setting
  `metal_slide_hole_rear_margin` (10 mm) replaces the fixed rear limit for holes.
  Slide hole positions stay generic arrays by design: the engine drills the arrays
  as listed, not a maker's alternative hole choices.
- **Pull stock thickness.** The five pull profiles are unchanged, and this is
  deliberate: every profile dimension (length, recess, legs, chamfers, radii) lies
  in the plane of the handle stock, so none depends on `handle_thickness`, and the
  reference draws all five for 18 mm stock with no dimension that varies with the
  sheet. Thicker stock gives the same profile, taller across the door. Everything
  that does depend on the thickness already scales with it: the pull is centred
  across the door on its hole line, the leg pilot holes are at half the stock, the
  jig block is cut from the same stock, its fence stands `handle_thickness` + 7 mm
  above the plate and its guide holes at `handle_thickness` / 2. New error
  `HANDLE_STOCK` when the stock leaves less than 3 mm around the leg pilot holes
  (`handle_thickness` < `handle_pilot_diameter` + 6).
- **Python package back in step.** `config/schema.json` and
  `tests/parameter_contract.json` are regenerated for all eight cabinet types
  (shop cart, utility, benchtop, stackable, kitchen, drawer, equipment stand,
  workbench), so the package's schema-equality and contract tests pass again.
  To get there, the drawer-height weight arrays of the shop cart, utility, kitchen,
  stackable and benchtop front ends moved from their hidden section to the end of
  *Drawers / Layout* with descriptions (values unchanged), several SCAD comments
  were shortened or completed so the Customizer parser reads them whole (stackable
  base and toe-notch, hinge fixing-hole offset, layout mode), and the schema gains
  visibility rules for section nodes, combo door height, the stackable base and
  toe notch, the workbench grid and dog-hole panels, and the tab-and-slot settings.
  The app's settings (`lib/schema.json`) take the same descriptions; the kitchen
  starters' section nodes moved to the current 14-entry default. Products (the shop
  wall and the other `public/products/` designs) read their settings from their
  SCAD files at run time and have no generated copy to refresh.
- **Package audit fixes.** Since 0.21.0 the package's audit and export tried the
  workbench-only `pocket_screw_marks` output on every cabinet type, which failed
  every non-workbench audit ("Unknown output_mode"); they now skip it where it is
  not offered. The export-frame comparison now allows for OpenSCAD's 6-significant-
  digit echo, which made the shop cart preset *3-Section Drawer Workbench* report a
  false `POCKET_OPERATION_COLLISION` (also on main).
- **Drift check in CI.** New `scripts/engine-schema.py`: `--check` fails when
  `config/schema.json`, the parameter contract or `lib/schema.json` differs from
  what the SCAD front ends produce (listing the differences); `--write` regenerates
  them, keeping the app's own presentation (units, steps, advanced flags, curated
  starters) and rebasing starters onto new defaults. The Pages build runs it and the
  package's parameter-layout tests after the parity check, and `test:release`
  runs it too.

Validation performed:

- **Python package** (Python 3.13, OpenSCAD 2021.01): the 24 unit tests pass,
  including the schema-equality and parameter-contract tests that failed before.
  `tests/run_matrix.py` audited 91 jobs (every preset and joinery variant of the
  eight cabinet types, nine of them workbench including *Side-by-side drawers*):
  0 errors, 67 PASS and 24 WARN (warnings only; the saved
  `docs/validation_matrix.json` is updated). `inspect` with a catalog slide
  profile on the workbench resolves and validates.
- **Split drawers**: the cut-layout check of the new starter passed (every part
  on a sheet, no overlaps); `tests/engine-interference.mjs` with a new hand-picked
  split-drawer case found no overlapping parts, and its random sweep now also
  draws two-column modules.
- `python3 scripts/engine-schema.py --check`, `pnpm exec tsc --noEmit` and the
  full `test:release` gate (engine-source, parity and schema checks, units,
  settings visibility, hardware with new workbench catalog assertions, v5
  integration with new drawer-column assertions, stackable-controls, sections,
  section WASM, engine fit, engine interference, layout editor, golden, hardware
  engine, product sources, products; product interference, run on its own after
  the combined run was stopped during it, rendered 61 configurations with no
  overlapping parts) and `pnpm run build:static` passed.
- `tests/golden.mjs` added the new starter; every existing snapshot matched
  unchanged.
- **Headless Chrome** at 1500 px: the *Side-by-side drawers* starter passes the
  engine checks; the Layout inspector shows **Drawers across** with the partition
  note and "Drawer levels"; the Hardware step lists 72 slide models, and choosing
  one locks its dimensions with the engine checks still passing; the instant 3D
  view shows the module's three levels of two drawers and the cut list lists
  `M2-PARTITION` and the `M2-DRAWER-#L`/`#R` parts; no console errors or
  horizontal scroll. A phone-width pass was not run.

Remaining limitations:

- `drawer_door` modules keep one drawer column, and a module has at most two
  columns.
- The partition slides need binding posts (sex bolts), listed in the hardware;
  the engine does not offer screwing two slides into one partition.
- The pull profiles and the jig's T-bone reliefs are as in 0.21.0.

## 0.23.0 — 2026-11-26

In-app 3D collision check for every design.

- **Check for intersecting parts**, under **Cut list & fit** for every cabinet
  type and every product (the media cart and the shop wall). On request, a background worker
  (`public/openscad/interference-worker.js`) renders each part (products) or each
  group of parts (cabinets: sides, caps, back, shelves, interior members, rails,
  face frame, drawers, doors, worktop, base hardware, stack base, the next module
  in a stack, slide envelopes; every workbench part) on its own in assembly
  position, compares their bounding boxes, intersects only the pairs that meet,
  and lists any pair that shares more than 1 mm³ (products) or 50 mm³ (cabinets).
  It shows progress, can be stopped, reports the time taken and marks the result
  out of date when the settings change. It needs a finished engine check of the
  current settings.
- **One definition of the jobs.** The groups and per-part jobs moved from the
  test sweeps into `lib/interference.ts`; `tests/engine-interference.mjs` and
  `tests/product-interference.mjs` now use the same jobs as the app (the cabinet
  cases intersect the same group pairs as before the move, the product cases the
  same part pairs).
- The coverage lists name the 3D check as available on demand.

Timings through the production worker in Node (one worker, as in the browser; the
browser precompiles the engine and is usually as fast or faster), on this
release's main: media cart default 6.4 s (14 parts, 43 of 91 pairs intersected),
shop wall default 1.9 s; cabinet defaults: shop cart 18.6 s, utility 5.2 s,
benchtop 6.8 s, stackable 7.1 s, kitchen 7.0 s, drawer 0.6 s, equipment stand
1.2 s, workbench 14.6 s (59 parts, 123 of 1,711 pairs intersected). In Chromium: media cart 3.9 s, shop cart 16 s.

Validation run for this release: `tsc --noEmit`; eslint on the new and changed
files (no new findings); new `tests/collision-worker.mjs` (both products' and all
eight cabinet types' defaults check clean through the production worker, a part
drawn twice is reported, malformed requests are refused); `tests/engine-interference.mjs`
(hand-picked cases: before and after the move on 0.18.0, 37 configurations and 977
pairs both times; after merging 0.22.0, 42 configurations and 1,305 pairs, clean); `tests/product-interference.mjs` (after merging 0.22.0: 61 configurations of both
products, 1,122 pairs, the same count as the suite before the move);
after merging 0.22.0 also `tests/golden.mjs` (120 starters), `engine-fit.mjs` (120 starters), `layout-editor.mjs`, `hardware-engine.mjs`,
`tests/products.mjs`, `section-wasm.mjs`, `units.cjs`, `nesting.cjs`,
`settings-visibility.cjs`, `hardware.cjs`, `v5-integration.cjs`,
`stackable-controls.cjs`, `sections.cjs`, the engine-source, product-source and
parity checks; `tests/desktop-assets.cjs` (now also lists the new worker) on a
local static build; and the check driven in Chromium at 1440 × 900 (media cart) and
390 × 844 (default cabinet), no horizontal scroll.

Limitations: the check runs one worker and is not cached; very large designs
(many workbench modules, many section members) can take minutes. Hardware is only
as complete as the engine draws it (screws and bolts are not modelled). Shared
volume below the thresholds is ignored.

## 0.22.0 — 2026-11-26

A new **Shop wall** area holds 31 French-cleat and wall-mounted shop organizers,
integrated from the owner's ShopWall OpenSCAD modules and rebuilt on the
workshop's shared SCAD core, with fit checks on every joint and a fit test
coupon to cut first (see `docs/SHOP_WALL.md`).

- **Shop wall product.** New → **Shop wall** lists one product with a grouped
  starter per module at the original preset sizes: simple shelves, jar shelves,
  spray paint display, single and double cube shelves, narrow and sandpaper
  shelves; single, double and sliding door cabinets, 3- and 4-drawer cabinets;
  chisel, clamp, hammer, screwdriver, plier, router bit and circular saw racks;
  simple and double drill stations, single and double shelf drill stands;
  closed lid, screw, shallow storage and glove boxes; hook panel, material
  storage stand, paper towel holder and wrench holder; and a fit test coupon.
  One engine file (`public/products/shop_wall/shop_wall.scad`) builds them all;
  choosing a module (as a starter or under **Module**) loads its sizes and
  module settings and keeps the mount, stock, joinery, machining and sheet
  settings.
- **Module settings.** Shelves, bays, drawers, lip height, compartments, tool
  slots or holes (count, width, length, spacing, rows, shank allowance,
  staggered second row), saw guard slot, bin grid and front height, glove slot,
  hooks, brackets, dowel and clearance, wrench slots and rise, and the
  door/drawer/lid gap. Each shows only where it applies; elsewhere it is listed
  under "settings not in use" with the reason (for example the cleat choice
  without a French cleat, or CNC hooks on a hook panel, which has no side
  panels). Labels follow the module and count buttons use the SCAD ranges.
- **Wall mount.** French cleat with CNC side hooks (cut into the side panels,
  passing through notches in the back) or a beveled hanger board and spacer
  screwed to the back, with the mating wall rail cut as a part (length, stud
  spacing and screw size are settings); or screws through the back, or none.
- **Shared core.** Tabs come from the core tab planner (`joinery.scad`) and
  slots, slot reliefs, tab shoulder reliefs and screws beside the tabs from
  `tab_pocket.scad`, as for the cabinets. New core files:
  `seam_joinery.scad` (multi-tab seams, screws in the webs, sloped-panel
  coverage) and `wall_mount.scad` (CNC hooks, inside-corner relief along the
  bisector, rail position and hang lift, stud screw stations, adjacent rails);
  the hanger and rail bevels use `cleat.scad`. The cut-layout placement helpers
  moved from `layouts_modules.scad` into `placement.scad`, shared with the
  products (cabinet outputs unchanged). Holes smaller than the cutter go to the
  drill layout.
- **Fit checks (geometric).** Every design is checked by the engine: each tab
  against its slot (clearance on both axes, tab length and setback, cutter
  reach, corner and shoulder reliefs, web between slots), screws in solid wood
  clear of slots and openings with room for the pilot, cuts within a part not
  running into each other, the assembly order (each part goes on along its
  tabs), the back held by at least two tabs or screws, parts not sharing space,
  the French cleat (rail position, hook tip, depth and relief, notch height,
  nothing behind the wall, other rails at a stated pitch), and the module's
  own fits (doors, drawers, sliding leaves, bins, tool openings, slots, dowel,
  wrench slots). Errors block the export as for the cabinets.
- **Fit test coupon.** The Export view of a shop wall design has a **Fit test
  coupon** card: a tab in its slot with screws, and a short CNC hook (or
  beveled hanger) with a short rail, built with the design's stock,
  clearances, cutter, relief and bevel, checked and nested like a module, and
  downloaded as SVG and DXF per stock (cut and drill layouts).
- **Corrections to the original modules** (each in `docs/SHOP_WALL.md`): relief
  at the CNC hooks' tabs and inside corners; the back joined by the horizontal
  panels (with CNC hooks the original joined nothing to it); rear tabs kept off
  the pointed tips of sloped ribs; sliding leaves that can be lifted out of
  their bottom channel; equal shelf openings; spacer and tilt-in note for
  short modules on a beveled board; wall rail screws at the stud spacing; the
  door pull clear of the finger bore; the paper towel dowel as hardware; slot
  and hole sizes against the cutter; flat parts nested on sheets.
- **Framework.** Products can be listed under their own area in the picker,
  starters can be grouped, controls can have module-dependent labels and count
  ranges, and a product can offer a fit test coupon on the export page.

Validation performed:

- `pnpm exec tsc --noEmit`, the engine-source, parity and product-source
  checks, units, nesting, settings visibility, hardware, v5 integration,
  stackable-controls and sections (native OpenSCAD), section WASM workers,
  engine fit, layout editor, cut-layout check, hardware-engine and
  `pnpm run build:static` passed.
- Cabinet golden outputs: all 120 starters unchanged after `placement.scad`
  was split out of `layouts_modules.scad`.
- `tests/products.mjs`: snapshots added for the 32 shop wall starters (the
  media cart's are unchanged); every starter runs through the production
  workers with no engine errors, one cut outline per part matching its
  placement, sheet nesting and labels inside their parts. New unit checks
  cover the shop wall editor definition and the engine files sent to the
  workers.
- Exact 3D interference (every part rendered alone, every pair intersected):
  `tests/product-interference.mjs --random 6` passed 71 configurations (all
  starters of both products, the 16 new shop wall cases and the random
  designs). Separately, all 32 shop wall starters were swept with CNC hooks,
  with beveled boards, with screw joinery and screws through the back, and
  free standing with dog-bones in ½″ stock: no overlapping parts. The sweep
  found dividers placed one board low in the cube shelves and the boxes, which
  was fixed before the gates above were run.
- Fit checks were confirmed to fire on bad settings (a 20 mm cutter, a cleat
  taller than the module, rails every 100 mm, an oversized hook tip, too many
  tool slots, a tab setback past half the board, no layout gap, a 0.2 mm door
  gap), and the cut-layout gate caught a sliver cut off a pointed rib, fixed
  by starting rear seams where the rib has a board of wood.
- In headless Chrome at 1500 px on the static build: New → Shop wall lists the
  grouped starters; the sliding door cabinet opens, renders in 3D, passes the
  engine checks, shows its module settings with 25 settings not in use;
  Export generates the manufacturing package (2 sheets) and the fit test
  coupon, with no console errors and no horizontal scroll. This run found and
  fixed an editor check that failed when called on its own.

These are geometric checks of the model, not a physical fit test: nothing was
cut. Cut the fit test coupon with the measured stock before a full module.

Remaining limitations:

- No load rating, racking or wall-anchoring analysis and no stud finding; the
  wall rail note only says when the rail is shorter than the stud spacing.
- Hook panel hooks are each held by one glued tab (no room for a screw beside
  it). Short racks and drill stations with CNC hooks hold their side panels or
  gussets by the deck or cradle and the hook notches only, and a drill station
  then needs the screws beside the tabs.
- Short modules on a beveled board must be tilted onto the rail.
- Hinges are counted, not modelled; drawers run wood on wood. The hanger and
  rail bevels are cut on a saw after the blanks.
- The 3D interference check runs in the test suite (every starter, 16 cases
  and random designs), not live in the editor; the editor's overlap check uses
  part boxes.

## 0.21.0 — 2026-11-26

Modular workbench: the pulls now follow the reference handle set's dimensions, the
cut files spot every assembly screw, the pulls' drilling jig can be added to the
export, and the Python package covers the workbench. Nothing from the reference
files is traced or committed; every outline is generated from measured dimensions
(radii, chamfer angle, arc radii, leg widths), listed in
[docs/MODULAR_WORKBENCH.md](docs/MODULAR_WORKBENCH.md).

- **Pull profiles.** The five `handle_style` profiles are rebuilt from the
  reference dimensions: the square pull's feet are now square (only its top
  corners are rounded, 3 mm); the chamfered pull gets its 37.5° chamfers from 7.5
  and 15 mm circles; the straight bar's two legs stand 20 mm in from the ends with
  10 mm fillets (before, both legs were drawn at its left end); the traditional pull is two arcs (crown and wing)
  with tangent tips, legs leaning in at 8° and 6.5/15 mm fillets. Each profile and
  drilling block matches the reference outline to within 0.6 % of its area at a
  0.1 mm raster (the rasterisation noise). Every pull reports its size, hole
  centres and pilot holes (`DIM|HANDLE`).
- **Drilling jig** (`include_handle_jig`, off by default). A drilling block shaped
  like the chosen pull's finger recess (cut from handle stock), a 240 × 97 mm plate
  and a fence with two guide holes at 140 mm centres, half the handle stock above
  the plate (`jig_thickness` 12 mm, `handle_pilot_diameter` 3.5 mm,
  `jig_dowel_diameter` 8 mm). The parts go into the cut files and stand assembled
  beside the bench in the 3D view; the pull lies over the block with its feet
  against the fence and its leg pilots are drilled through the fence.
- **Screw marks** (`include_screw_marks`, on). A new `pocket_screw_marks`
  operation: 4.5 mm marks 1.5 mm deep on the machined faces where the assembly
  screws go: sides into the back, bottom and top rails, between their fingers;
  hinge mounting-plate screws 37 mm from the front, 32 mm apart, on both sides of
  door modules; back into the bottom; bottom down into the frame strips (78 mm
  either side of each cell centre, `frame_screw_offset`); back rail down into the
  back; top rails up into the worksurface beside the hand slots; drawer box fronts
  into the drawer faces; face panels into the module sides. On the reference
  simple cabinet the side, back, bottom and rail marks land where the plans put
  them. The count is reported (`DIM|SCREW_MARKS`); depth and frame-screw position
  are checked (`SCREW_MARK_DEPTH`, `FRAME_SCREWS`). Door handle holes stay drilled
  through.
- **Settings regrouped** to the groups the other cabinet types use for the same
  settings: sheet size under the flat layout (the app still shows it under
  sheet stock), the front gap under fronts, drawer clearances under drawer
  clearances, slides and slide drilling under their own hardware groups.
- **Python package.** `workbench` is now an eighth frontend: `api.describe()`,
  `inspect`, `preview`, `manufacture`, the exhaustive audit and the matrix script
  cover it. The workbench's engine schema entry is now the package generator's own
  output. OpenSCAD 2021 parameter files drop vectors of vectors such as the
  module rows, so every OpenSCAD call now repeats those values as `-D` literals
  (only bracketed literals of numbers, names and quoted words). The audit and
  export only run the operations the workbench offers. The common `joinery`
  setting is rejected for the workbench (its carcass joinery is fixed) and
  `material_thickness` sets the carcass stock. The schema parser reads
  multi-line array defaults.

Validation performed:

- **Shapes against the reference** (scratch tooling, nothing committed): each
  pull profile and drilling block rendered by the engine and the matching
  reference outline were rasterised at 0.1 mm and compared; the differences are
  0.06–0.6 % of the area, within the rasterisation noise. The jig fence differs
  by 0.6 %; the plate differs only at the mortise, whose reliefs are drawn
  differently. With native OpenSCAD 2021.01 a pull of each style placed on its
  jig (over the block, feet against the fence) intersects the block, plate and
  fence with zero volume.
- **Screw marks**: for the default design and every workbench starter (146 to
  320 marks each), every mark lies inside its part's material, at least 1 mm from
  any edge, and clear of every other pocket and hole operation.
- `pnpm exec tsc --noEmit`, the engine-source and parity checks, units, settings
  visibility, hardware, v5 integration (new assertions for the jig and
  screw-mark controls and the new operation), stackable-controls, sections,
  nesting, runtime integrity, desktop assets, engine fit, hardware-engine,
  cut-layout check, section WASM workers, layout editor, products and
  `pnpm run build:static` passed.
- `tests/golden.mjs --update` changed only `tests/golden/workbench.json` (report
  records and the pulls' cut outlines); all 120 starters then matched.
- `tests/engine-interference.mjs` for the three hand-picked workbench cases, now
  with the jig (chamfered, traditional and straight-bar pulls): no overlapping
  parts (631 group pairs). The full sharded sweep was left to CI.
- **Python package** (Python 3.13, OpenSCAD 2021.01, shapely 2.2): the unit
  tests run 24 tests; the new workbench tests and the eight-frontend inspection
  pass, and the two failures are the schema-equality and parameter-contract
  tests described below, which already failed before these changes. The package's exhaustive
  CUT/POCKET audit of the default design, the default with the traditional pull
  and jig, and all eight workbench presets reported no errors (shelf-span
  warnings only).
- **Headless Chrome** at 1500 px: the Hardware settings show the jig switch with
  its details inactive until it is on; with the jig on, the Exact render (8 s)
  shows it beside the bench and the cut list lists the three jig parts; the
  exported package of the drawers starter contains the `pocket_screw_marks` SVG
  and DXF files; no console errors or horizontal scroll. At 390 px the drawers
  starter's 3D, Exact render and cut list showed no console errors or horizontal
  scroll.

Remaining limitations:

- The jig's mortise and tab reliefs are the engine's T-bone reliefs, not the
  reference's arc-shaped ones, and the handle profiles' fixed dimensions do not
  scale with `handle_thickness` (the guide holes and fence height do).
- Screw marks for the drawer box fronts and face panels are an engine design; the
  reference has no cut files for those parts.
- The Python package's schema-equality and parameter-contract tests still fail for
  the cabinet types whose settings changed in earlier releases without the
  package's generated schema and contract hashes being refreshed; the workbench
  entry and its contract hash pass, and the saved validation matrix
  (`docs/validation_matrix.json`) still holds the 82 audits from before the
  workbench.

## 0.20.0 — 2026-11-26

The stackable base frame and stacked fronts now follow the user's reference
stackable plans (see `docs/STACKABLE_REFERENCE.md`, phase 3).

- **Flat-rail base frame.** A new **Stack base style** setting
  (`stack_base_style`: auto, edge rails, or flat rails and kick board).
  `flat_rails` builds the reference base:
  - side rails with the stacking recess, the rails' joints at the top, and a
    toe notch at the front (`stack_base_toe_notch_depth` × `_height`, 57.5 × 47
    mm by default);
  - two flat rails identical to the module's top stretchers;
  - an on-edge kick board directly behind the front rail, from the floor to the
    recess floor, in closed pockets (or dados, or butt with guide holes). A
    nested bottom rests on it.
  - The lowest module sits on the base exactly as it sits on another module:
    a nested bottom drops between the base's rails and sides, and the link
    screws go through the base sides.
  - `auto`, the default, picks flat rails for a nested bottom and keeps the
    edge rails otherwise, so raised designs build the same base as before.
  - The toe notch is reduced, with a `STACK_BASE_TOE_NOTCH` warning, where it
    would leave less than 10 mm in front of the kick board or below the front
    rail. A base too low for a 20 mm kick board is built without one
    (`STACK_BASE_KICK` warning).
  - The kick board is a new part, `STACK-BASE-K`, in the parts list, cut
    layout, engraving and print layouts.
- **Stacked fronts centred on the rail.** A new **Stack front seam** setting
  (`stack_front_seam`), `rail_centre` by default on stackable modules.
  - Overlay doors and drawer fronts that reach the module's bottom now start
    one reveal above the middle of the lower module's top stretcher. Those that
    reach the top stop one reveal below the middle of the module's own top
    member. Stacked fronts leave a gap of twice the edge reveal, centred on the
    stretcher, as in the reference.
  - Only the visible faces move. Drawer boxes, their openings and slides are
    unchanged. Hinges follow the doors.
  - `module_edge` keeps the previous fronts. Inset fronts are unaffected.
- **Starter outputs changed (intended).**
  - All six stackable starters have new front sizes. For example, the door
    module's door is now 398 mm tall from z = 10.475 instead of 378.95 mm from
    z = 20. Top and bottom drawer faces grow by about half a sheet; middle faces
    are unchanged.
  - "Door Module, Nested (Reference Joinery)" now has an 80 mm base and a
    2.5 mm reveal, with the flat-rail base. Its door is 470 × 610 mm from
    z = 11.5, as in the reference. Its base is 550 × 80 mm sides, 465 × 75 mm
    rails and a 465 × 62 mm kick board.
  - No other starter changed.
- **Interference test.** The stack base's sides and its rails and kick board
  are now separate groups, so the base's own joints are checked. Four cases
  were added: the nested starter, and the flat-rail base with butt-style,
  dado and through-tab joinery. The random sweep can now choose the base style
  and the front seam.

Validation performed:

- **Static and engine checks.** `pnpm exec tsc --noEmit`, the engine-source,
  parity and product-source checks, units, nesting, settings visibility (with
  assertions for the toe-notch and front-seam rules), hardware, v5
  integration, the native OpenSCAD stackable-controls and sections tests
  (OpenSCAD 2021.01), section WASM workers, engine fit, layout editor,
  hardware engine, products and `pnpm run build:static` all passed, re-run
  after merging main at 0.19.0.
- **Golden outputs.** The six stackable starters' diffs were reviewed: front
  sizes and positions only, plus the nested starter's base frame, base height
  and reveal. They were then re-recorded. All 120 starters match after merging main at
  0.19.0.
- **Cut-layout check.** A new section renders the nested starter with the
  flat-rail base and with edge rails. It confirms: rails as deep as the top
  stretchers, a 62 mm kick board, base-side outlines that differ only by the
  toe notch, and one contour per part.
- **Interference sweep.** `tests/engine-interference.mjs --all` ran locally in
  four shards: 188 configurations with no overlapping parts, 1 random design
  skipped as rejected by the engine. A flat-rail base under a raised dado
  module first showed the kick board's ends rising into the module's tongue.
  The kick board now stops at the recess floor in every case.

Remaining limitations:

- The kick board supports only a nested bottom. A raised bottom sits one
  interface depth above it.
- The app's instant drawing does not show the base frame or the moved fronts;
  the 3D model and cut files do.

## 0.19.0 — 2026-11-26

Modular workbench modules can now hold drawers, drawers over a door, or an open
front behind a framed face panel, as in the photo grid of module configurations
from the owner's reference set, and stacked modules are located by keys instead
of only being screwed down. No cut files came with those configurations, so the
drawer and face-panel construction is designed parametrically in the engine
around the reference cabinet; [docs/MODULAR_WORKBENCH.md](docs/MODULAR_WORKBENCH.md)
records the construction and the decisions.

- **New module contents.** Besides doors and open:
  - **Drawers**: one to eight equal overlay drawer fronts over the whole
    height, each with a drawer box on side-mount full-extension slides.
  - **Drawers + door**: one to eight 150 mm drawer fronts
    (`combo_drawer_height`) above a door, with shelves only below the drawers.
  - **Framed opening**: an open module behind a door-sized face panel with a
    rounded opening (40 mm border, 60 mm corner radius).
  Fronts line up with the doors (full overlay, 5 mm gaps) and carry the selected
  pull, centred.
- **Drawer boxes.** 12 mm sides, front and back with through finger joints at
  the corners, and a 12 mm bottom with tongues on all four edges in blind 6 mm
  pockets, using the shared tab-in-pocket corner reliefs. Boxes are 338.6 mm
  wide in a one-cell module (12.7 mm slide clearance per side) and as deep as
  the slide; the slide length is picked automatically (350 mm in a one-cell
  module) or set. Slide screw holes are drilled in the module sides (8 mm
  pilots) and through the box sides on the equipment stand's generic hole
  arrays. Bottom pockets and slide holes are in the new `pocket_drawer_dados`
  and `pocket_slide_holes` files of the export. Each drawer reports its
  outside, inside and opening sizes, so the drawer-fit table covers it, and the
  hardware list counts slide pairs by length.
- **Stacking keys.** A module standing on another is located by 50 × 26 mm keys
  of frame stock. Each key stands in a 14 mm pocket milled into a top rail of
  the module below and in one of the registration pockets already under the
  module above (on modules facing any way). A module stacked on a one-cell
  module gets two keys; a stacked module with fewer than two reports
  `STACK_KEYS`. `include_stack_keys` turns them off.
- **Checks.** Drawers or doors that open into another module, drawer boxes too
  low for their slides, slides that do not fit the module, no room for a door
  under the drawers, corner fingers narrower than the cutter, pulls that do not
  fit a drawer front, face-panel borders and pocket depths are errors; wide
  drawers are a warning. The side-panel notes in the parts list no longer
  mention shelf pins on modules too low to have any.
- **Layout tab.** Contents are now Doors, Drawers, Drawers + door, Open or
  Framed opening, with a drawer count. The grid labels each module (for
  example "4 drawers · 730"), and the drawing checks drawer counts against the
  module height before the engine runs. The instant 3D view draws drawer
  fronts, boxes and framed face panels.
- **Two new starters**: *Drawers, cubbies and a drawer-and-door cabinet*
  (medium 3 × 2) and *Small 2 × 2 drawer bank*.
- The default and the other reference starters keep their cut and pocket files
  unchanged; the stacked starter gains its keys and rail pockets.

Validation performed:

- `pnpm exec tsc --noEmit`, the engine-source and parity checks, units,
  settings visibility, hardware, v5 integration (new assertions for drawer
  counts, box heights, schematic ids, drawers opening into a module, too many
  drawers, no room for the door, and the visibility of the new settings),
  stackable-controls and sections passed, as did nesting, runtime integrity,
  schematic orbit, diagram depth, desktop assets, layout editor, engine fit
  (all 120 starters), hardware-engine, cut-layout check, section WASM workers,
  products, product interference and `pnpm run build:static`.
- `tests/engine-interference.mjs` for the three workbench drawer, drawer-bank
  and stacked cases: no overlapping parts (579 group pairs). The full sharded
  sweep was left to CI.
- Golden snapshots were updated for the nine workbench starters only; all 120
  starters then matched. In the
  seven existing ones only report records changed (module lines gained a drawer
  count, the machining line two depths, side-panel notes and screw totals), and
  only the stacked starter's cut layout changed (its keys and rail pockets).
- Every workbench starter, a hand-picked layout (drawers on a sideways module
  carrying a framed and a door module, single- and three-drawer modules stacked
  on a two-cell module and on one turned to the right, a two-cell drawer-and-door
  module, fit clearances) and six seeded random layouts with the new contents:
  each cut layout matched its part table, and every part rendered on its own
  and intersected with every other showed no overlap. A deliberately long
  bottom tongue and tall keys were reported as overlapping parts.
- In headless Chrome at 1500 px: the new starter's Layout tab, changing a
  module to eight drawers and to drawers + door (both problems shown), back to
  one drawer and to a framed opening, the instant 3D view, an Exact render
  (10 s) and the Cut list, with no console errors or horizontal scroll.

Remaining limitations:

- Drawers use metal side-mount slides only; the slide hole arrays are generic and
  must be checked against the purchased slides.
- Drawer fronts are screwed to the box fronts and face panels to the carcass
  edges without drilled positions; the screw-marking dimples and jigs of the
  reference are still not modelled.
- Two-cell-wide drawer modules get one wide drawer per level, not two side by
  side.

## 0.18.0 — 2026-11-26

Media cart: the limitations listed with 0.15.0, except the in-app collision
check, which follows separately.

- **Tip-over check.** The engine check now computes the cart's weight and center
  of gravity (every part's outline × thickness × sheet density, plus stated
  contents per bin, cubby and tower opening) for three loadings: empty, fully
  loaded, and loaded only in the highest bin row and tower opening. For each it
  reports the level push at the top that tips the cart forward, backward, left
  or right about its caster centers (or the bottom panel's edges without
  casters), and the downward lean on the front edge of the bins that tips it
  forward. An error is raised when the weight alone is outside the support, and a
  warning when the stated push (default 50 N) or lean (default 250 N) would tip
  it. A new **Stability** section sets the forces, the contents and the density.
  The old height-to-depth note is gone.
- **Racking.** The report lists what resists shear side to side and front to
  back, and warns when only glued butt joints do.
- **In the editor.** The drawing marks the center of gravity of the weakest
  loading and shows a stability summary (per-loading weight, weakest push and
  lean, what resists racking, and the assumptions) that opens the Stability
  settings.
- **Joinery in the instant drawing.** After the engine check, both elevations
  outline the tabs, slots and half-laps, dados and holes of the parts each view
  shows (from new `FEAT|` records in the engine report), with a legend and a
  Joinery toggle; they fade while a newer check runs.
- **Second-face dados register.** `pocket_dados_flip` is drawn for the whole
  layout turned over left to right about its vertical center line instead of
  each part flipped in its own place. Per sheet, the export turns the second-face
  contours over about the sheet's center line and adds two registration-pin holes
  on that line in the margins of `pocket_dados` and `pocket_dados_flip` (none when
  the margin is under 10 mm). The READ-ME, the sheet notes, the operation note and
  START-HERE give the order: up face, turn the sheet over onto the same pins,
  second face, turn back, drill and cut.
- **Default design has no warnings.** Holes smaller than the cutter (the 4.5 mm
  screw clearance holes with the 6.35 mm cutter) leave the cut layout and go to a
  new `drill_layout` operation (drill at the circle centers), reported as a note
  instead of a warning. Caster bolt holes stay in the cut layout.
- **Shared joinery module.** Receivers, slots and dados with their corner relief,
  and new shoulder reliefs at the roots of tabs and tongues, come from the
  engine's shared `data/scad/tab_pocket.scad`. Products can now include shared
  engine files (`engineIncludes`; the workers, tests and downloads carry them).

Validation run for this release: `tsc --noEmit`; eslint on the changed files (no
new findings); `tests/nesting.cjs` (new: second-face contours turned back to
their part and over about the sheet center, registration pins); `tests/products.mjs`
(every starter through the production workers with the new drill layout and the
second-face containment check, plus two extra configurations with dados on both
faces of the walls; golden snapshots updated and reviewed);
`tests/product-interference.mjs --all` (31 designs, 1,231 part pairs intersected, no shared volume; 6 random designs skipped as rejected); `tests/units.cjs`,
`settings-visibility.cjs`, `hardware.cjs`, `v5-integration.cjs`,
`stackable-controls.cjs`, `sections.cjs`, `section-wasm.mjs`, `golden.mjs` (118 starters unchanged), `layout-editor.mjs`,
`hardware-engine.mjs`, `engine-fit.mjs`, `cut-layout-check.mjs`, the
engine-source, product-source and parity checks; and the editor in Chromium at
1440 × 900 and 390 × 844 (stability summary and settings, joinery outlines,
center of gravity; a two-tower design with dados exported, and the per-sheet
second-face files turned back over their sheet and overlaid on the cut layout).

Limitations: the stability check is static (no rolling over a threshold, no
caster catching) and rates no joint, panel, shelf or caster strength; the
compact sorter starter (no casters, 11 kg) tips under the default 50 N push
and says so; the instant drawing shows joinery only after an engine check and
only for the parts each view sees face on or edge on; the per-design 3D
collision check is not in the app yet.

## 0.17.0 — 2026-11-26

Stackable modules can nest into the module below, as in the stackable cabinet
plans the user supplied as a reference (see `docs/STACKABLE_REFERENCE.md`,
phase 2).

- **Nested bottom.** A new **Stack bottom style** setting
  (`stack_bottom_style`, raised or nested) on stackable modules with
  tab-and-slot joinery. Raised, the default, builds exactly as before. With
  **nested**:
  - The bottom sits at the very bottom of the module, in the tongue layer, and
    runs front to back only between where the lower module's top stretchers
    end (`top_stretcher_depth` + `stack_interface_clearance` from the front and
    from the back). Stacked, it drops between the lower module's stretchers and
    sides, so modules locate front to back and side to side.
  - The bottom's side tabs stay on the full-height part of the side tongue, and
    with blind side tabs they stop in pockets as in 0.16.0.
  - The interface depth follows the sheet thickness, so the stack pitch is the
    module height less one sheet (615 mm for a 633 mm module in 18 mm sheet).
  - A structural back has no bottom tabs when the nested bottom stops short of
    it. It starts one sheet above the module's base, so in a stack it stands on
    the lower module's rear stretcher, as the reference's back does.
  - Stacked overlay doors leave a gap of twice the edge reveal (4 mm by
    default) instead of a band of about 23 mm.
- **Screws between modules.** `stack_link_screw_holes` (on by default with a
  nested bottom) drills holes of the blind-tab screw-hole diameter (4.5 mm)
  through the top of each side and each base-frame side rail, half a sheet
  below the top edge, between the stretcher and the stacking recess, for
  screws up into the edge of the bottom of the module above. In the new starter
  they fall at depths 91 and 459 mm (90 and 460 in the reference). The holes are
  in the side feature ledger, so they are checked against the other holes.
- **Checks.** A nested bottom with joinery other than tab-and-slot, or with
  partitions, is reported as an error (`STACK_NESTED_JOINERY`,
  `STACK_NESTED_PARTITIONS`); margins too shallow for the link screws give a
  warning.
- **New starter.** Stackable → **Door Module, Nested (Reference Joinery)**:
  475 × 633 × 550 mm in 18 mm sheet, tab-and-slot with blind side tabs and
  T-bone relief, 75 mm top stretchers, a structural back and a full-overlay
  door. Its parts: sides 550 × 633, stretchers 465 × 75, bottom 465 × 398.8,
  door 471 × 611, 14 mm pockets.
- **Editor.** The 3D preview, the stacked preview and the layout frame place a
  nested bottom low and use the sheet thickness as the stacking overlap. The
  interface-depth setting is shown as set by the nested bottom.
- **Interference test.** Every stackable configuration is now also checked
  against a copy of itself one stacking pitch higher, and the stack base is
  rendered in place below the module (before, its group drew the carcass
  only). Three nested cases were added. A deliberate overlap (a −10 mm edge
  reveal) was confirmed to be reported between the doors and the module above.

Validation performed:

- **Static and engine checks.** `pnpm exec tsc --noEmit`, the engine-source,
  parity and product-source checks, units, nesting, settings visibility (with
  assertions for the nested settings), hardware, v5 integration, the native
  OpenSCAD stackable-controls and sections tests (OpenSCAD 2021.01), section
  WASM workers, engine fit, layout editor, cut-layout check, hardware-engine,
  products and `pnpm run build:static` all passed.
- **Golden outputs.** `tests/golden.mjs --update` added a snapshot for the new
  starter only; the other 117 starters' outputs are unchanged. All 118 then
  matched.
- **Interference sweep.** `tests/engine-interference.mjs --all` ran locally in
  four shards with the new stacked-module group: 184 configurations with no
  overlapping parts, 1 random design skipped as rejected by the engine.
- **Starter checks.** The new starter's cut layout passed `checkCutLayout`
  (12 parts, one outline each). A nested bottom with dado joinery and one with
  two drawer banks were confirmed to report their errors.

Remaining limitations:

- The gap between stacked doors sits at the lower edge of the stretchers above
  it, not centred on them as in the reference.
- Nested stacking needs tab-and-slot joinery and a single bay.
- The stack base is unchanged: the reference's flat top rails, toe notch and
  set-back kick board that supports the bottom are not modelled.
- 45° stacking flanks, rounded outer corners, hinge-plate marks on both sides
  and a back with top tabs through rail notches are not implemented.

## 0.16.0 — 2026-11-26

Tab-and-slot carcasses can hide their tabs: the tabs entering the cabinet sides
stop in blind pockets milled into the inside faces, as in the stackable cabinet
plans the user supplied as a reference. The measured reference and the spec are
in `docs/STACKABLE_REFERENCE.md`.

- **Blind side tabs.** A new **Side tabs** setting (`side_tab_style`, through
  or blind) on shop carts, utility, benchtop, stackable and kitchen cabinets
  with tab-and-slot joinery. With **blind**, every member that enters a side
  stops in a pocket and leaves the outside face whole. The members are the
  bottom, top or top stretchers, fixed shelves, combo divider, drawer
  separators, toe kick, rear stretchers, structural back, bay shelves and
  section dividers that end at a side, and the stack base's cross rails.
  - The pocket is the sheet thickness less `blind_tab_skin` (default 4 mm, so
    14 mm in 18 mm sheet).
  - The tab is `blind_tab_end_clearance` (default 1 mm) shorter than the
    pocket, so the shoulder seats before the tab bottoms out.
  - Pockets keep the slots' shapes, corner reliefs and open edges. A pocket
    that reaches a panel edge is open there, so the part drops in from that
    side. Pockets are milled in the carcass-dado pocket operation, which now
    reports their depth. The side outlines in the cut layout have no slots.
  - Members are as much shorter as their tabs (for example 2 × 4 mm in 18 mm
    sheet), and the parts list and cut layout follow.
- **Shoulder reliefs.** With slot corner relief on, blind tabs get a T-bone
  relief of the cutter's radius beside each tab root, so the shoulder seats
  on the sharp mouth of the pocket. A relief is left off where the tab is
  flush with the member's own edge.
- **Screw holes beside the tabs.** `blind_tab_screw_holes` (on by default)
  drills through holes (`blind_tab_screw_hole_diameter`, 4.5 mm) on each
  member's mid-thickness line, in the gaps beside and between its tabs, for
  screws into the member's edge. Gaps narrower than the hole + 6 mm get none.
  The holes are in the side-panel feature ledger with the pockets, so they
  are checked against hinge, slide and shelf-pin holes.
- **Defaults.** Stackable cabinets default to blind side tabs; the other cabinet
  types keep through tabs. Through tabs, and every other joinery style, build
  exactly as before. No starter uses tab-and-slot joinery, so no starter's
  output changed: the golden outputs of all 117 starters, including the
  workbench starters from 0.14.0, are identical.
  Interior joints (partitions and dividers meeting other interior members)
  keep through tabs.
- **Shared module.** The pocket depth, tab length, pocket and shoulder reliefs
  and screw spacing are argument-only functions in the new engine file
  `public/engine/v5/src/modular_organization/data/scad/tab_pocket.scad`, which
  any cabinet type or product can include.
- The parity table lists blind side pockets, and the settings list shows the
  blind settings only when they apply.

Validation performed:

- **Static checks.** `pnpm exec tsc --noEmit`, the engine-source and parity
  checks, units, nesting, settings visibility (with new assertions for the blind
  settings in all five cabinet types), hardware, v5 integration, the native
  OpenSCAD stackable-controls and sections tests (OpenSCAD 2021.01), the
  section WASM workers, engine fit (117 starters and regressions), the layout
  editor and hardware-engine suites, and the product-source and product
  (media cart) checks all passed, re-run after merging main at 0.15.0.
- **Golden outputs.** All 117 starters match their recorded parts, reports and
  cut/pocket layouts unchanged.
- **Cut-layout check.** The check now renders a stackable door module with a
  stack base and a utility base with rear stretchers in blind mode, and
  confirms all of the following:
  - every side outline equals the side of an unjoined carcass (nothing cut
    through or notched);
  - no opening larger than a screw hole passes through a side;
  - the pockets are in the carcass-dado operation with their depth reported
    (15.05 mm in 19.05 mm stock, 14 mm in 18 mm);
  - the layout has one contour per part.
- **Interference sweep.** Before main was merged in,
  `tests/engine-interference.mjs --all` ran locally in four
  shards: 165 configurations with no overlapping parts, 1 random design skipped
  as rejected by the engine. Two bay and section cases were re-run after the
  last relief change, also clean. It includes five new blind cases (two stackable,
  utility with rear stretchers, kitchen with fixed shelves, separators and a
  structural back, and a split shop-cart bay layout), with a 2 mm skin and
  zero end clearance among them. The random sweep can now choose the side-tab
  style. Every blind tab stops inside its pocket without reaching the outside
  skin.
- **All starters in blind mode.** The 88 starters of the five cabinet types
  were evaluated with tab-and-slot joinery, blind side tabs and T-bone relief,
  with no engine errors or warnings. Four bay and section starters (shop-cart
  open service cart and compact mixed cart, the photo section cabinet, utility
  wide mixed base) also passed the cut-layout check.
- **Manual check.** The blind cut, pocket and 3D outputs of a stackable door
  module were rendered and inspected.

Remaining limitations:

- The screw holes are clearance holes only; pilot holes in the member edges are
  left to the assembler.
- Interior joints stay through.

## 0.15.0 — 2026-11-26

Your own products beside the cabinet types, starting with the media cart: a
reviewed and corrected media-storage cart with its own editor, cut files and
checks.

- **Products.** New in the New picker under **Your products**. A product has its
  own OpenSCAD engine file and its own editor, and shares the engine check, cut
  list, export page (operation SVGs, per-sheet SVG and DXF nesting, reports,
  assembly packet), saved design files and browser recovery with the cabinets.
  Its settings and defaults are read from the SCAD file's Customizer parameters.
  Saved designs carry the product id; older cabinet designs open as before.
- **Media cart.** Sloped or stepped bins in adjustable rows and columns, optional
  lower cubbies, shelf towers on either or both sides, casters. Starters: Sloped
  bins, Stepped bins, Shelf cart, Two towers, Compact sorter. The editor shows the
  settings as collapsible sections with a one-line summary each (shop details:
  materials, joinery, machining, casters, sheets), and four views: an instant
  front elevation and side profile drawn to scale with quick controls (rows,
  columns, wall profile, towers, cubbies, casters; clicking a part opens its
  section), the exact 3D model, the cut list and checks, and the assembly order
  with the hardware list.
- **Manufacturing.** Carcass and fin stock presets or measured thickness;
  crosspiece joinery and a new panel joinery setting (butt, screws, dados, tab &
  slot) with fit clearances, tab length, spacing, margin and web; dado depth
  limited to under half the stock; dog-bone or T-bone relief at closed corners;
  kerf compensation, layout gap and registration frame; screw clearance holes and
  caster bolt holes; pocket layouts for each face (`pocket_dados`,
  `pocket_dados_flip`) and engraved part labels. Every part is one flat profile
  from which the 3D model, the cut layout and the parts list are drawn.
- **Review of the original model** (docs/MEDIA_CART_REVIEW.md): panels that were
  only butted are now joined; fins half-lap every crosspiece including front and
  rear (a one-row grid no longer floats); pilots in panel edges became face
  clearance holes with pilots drilled at assembly; an assembly order is defined
  (towers built on their outer wall and slid on, walls screwed from below); on
  stepped profiles a half-lap no longer cuts the front fin segment free and the
  rear crosspiece tabs no longer sever the wall's rear post; caster mounting holes
  added and checked against the panels standing on the bottom.
- **Engine checks for the cart**: bin, cubby and tower opening minimums, room for
  tabs, slot width against the cutter, dado depth, screw sizes, caster holes and
  fit, flat-layout overlaps, sheet size, two-sided parts, and a tipping note when
  the cart is more than 2.2 times taller than deep.

Validation run for this release: `tsc --noEmit`; `tests/products.mjs` (framework
units, every starter through the production export and render workers, cut-layout
gate, per-sheet nesting, every pocket and label inside its part, golden
snapshots); `tests/product-interference.mjs --all` (5 starters, 8 hand-picked
joinery, tower and profile cases and 24 seeded random designs; every part
rendered on its own and every touching pair intersected: 31 designs and 1,231
part pairs with no shared volume; 6 random designs were skipped because the
editor or the engine rejects them, with the reason printed);
`tests/units.cjs`, `nesting.cjs`, `settings-visibility.cjs`, `hardware.cjs`,
`v5-integration.cjs`, the engine-source and parity checks; and the editor driven
in Chromium at 1440 × 900 and 390 × 844 (new design from the picker, quick
controls, 3D render, cut list, assembly, export package generated and
downloaded, design saved and reopened, recovery after reload, no horizontal
scroll at 390 px). CI also runs the product suites and shards the product sweep
with the cabinet sweep.

Limitations: no load rating, racking or tipping analysis; 3D interference is
swept in the test suite, not checked for each user design; the instant drawing
is schematic (joinery shows in the 3D model and cut files); the flip pocket pass
assumes each two-sided part is turned over within its own place in the layout.

## 0.14.0 — 2026-11-26

A new cabinet type, **Modular workbench**: a rolling base frame on a grid of
400 mm cells, cabinet modules placed on whole cells (and stacked), and a
puzzle-jointed worksurface with dog holes. It is modelled on the owner's
reference plans (three base frames, a simple cabinet module, worksurfaces and a
set of cut handles); the plans are not in the repository and no outline was
traced. Every part is generated from parameters whose defaults reproduce the
reference; [docs/MODULAR_WORKBENCH.md](docs/MODULAR_WORKBENCH.md) lists the
measured dimensions, how they were derived and the decisions taken where the
reference is silent.

- **Base frame.** Small (2 × 2), medium (3 × 2) and large (4 × 2) frames, or a
  custom grid up to 5 × 3 cells. 85 mm strips half-lap at every crossing (long
  strips slotted from the top, cross strips from the bottom, cross strips under
  the end columns or every column), with 50 × 13 mm registration tabs at every
  cell centre, tapered ends, dogbone relief, and casters under the outer
  crossings.
- **Cabinet modules.** Each module covers whole cells (one or more wide and
  deep), faces the front, back or either end, holds doors (one per cell width,
  two hinged on the outer edges when wider) or is open, and has adjustable
  shelves on 5 mm pins. Sides carry 14 mm housings for the back, bottom and top
  rail fingers; the bottom has 51 × 19 mm pockets that drop over the frame tabs;
  the top rails have hand slots under the dog-hole rows; doors get 35 mm hinge
  cups and pull holes. Modules placed on others stack (the engine warns to
  screw stacked modules down) and must be supported evenly.
- **Worksurface.** 18 mm panels with a 50 mm overhang and rounded corners,
  split on cell boundaries in the reference panel layout and joined with
  30 mm dovetail puzzle joints at 180 mm pitch, with 16 mm dog holes on a
  100 mm grid (all panels, none, or selected panels).
- **Cut handles.** Square, rounded, chamfered, straight bar and traditional
  plywood pulls (162–210 mm long, 140 mm screw centres) cut from the handle
  stock, or none.
- **Layout tab for the workbench.** A top view of the grid: click an empty cell
  to place a module, click a module to set contents, facing, hinge side,
  height, shelves and span, move it, stack a module on top (a module already
  at bench height is split into two stacked halves) or remove it; **Fill empty
  cells** completes the grid. Doors that would open into another module are
  flagged under the drawing and by the engine.
- **Seven starting points**: the medium 3 × 2 bench (default), small 2 × 2,
  large 4 × 2, doors in front with open shelving behind, stacked half-height
  modules, one simple cabinet on a 1 × 1 frame, and the medium bench in ¾″
  stock.
- Engine checks cover grid fit, support, door clearance, joint and pocket
  depths, cutter access in puzzle necks, dog holes clear of seams, hinge and
  handle fit, shelf sag on wide modules, unsupported worksurface cells, stacking
  and stock size. The instant schematic, the summary bar (bench depth),
  plain-language help and option labels, and the cut list names cover the new
  type; the Hardware tab is not shown for it.

Validation performed: `pnpm exec tsc`; engine-source and parity checks; units,
nesting, settings visibility, hardware and `tests/v5-integration.cjs` (now all
117 starters, plus workbench size, stacking, grid-fit, support and door-facing
checks and setting visibility). Golden snapshots were added for the seven
workbench starters; each starter's cut layout matched its part table (one
outer contour per part) and nested on its stock sheets. The 3D interference
check now renders every workbench part on its own and intersects each pair:
all seven starters, two hand-picked layouts (a 4 × 3 grid with modules facing
every way, stacked and two cells deep, fit clearances, cross strips under every
column) and six seeded random module layouts showed no overlapping parts, and a
deliberately shallow registration pocket and long fingers were caught. The
existing interference sweep keeps drawing from the first seven cabinet types,
so its seeded designs are unchanged. In headless Chrome at 1500 and 390 px:
choosing the type and starters, placing, filling, stacking and turning modules
(with the door-clearance message) and switching to inches; at 1500 px also the
instant and Exact 3D views, the cut list and generating the export package;
no console errors or horizontal scrolling. Not run
here: the native OpenSCAD stackable and section tests and the full
interference sweep (CI runs both).

Remaining limitations: drawer modules and the plans' screw-marking dimples and
drilling jigs are not modelled; the handle profiles are parametric
approximations at the reference sizes rather than the plans' exact curves;
casters are drawn as reference hardware; stacked modules have no registration
between them; custom three-row grids pair worksurface panels row by row, so
four panels meet at interior crossings; the Python request translators do not
cover the workbench frontend yet.

## 0.13.0 — 2026-10-16

Hardware setup starts from one choice, a new Hardware view draws the holes on
both boards a slide or hinge joins, and export has its own page.

- **Only the chosen drawer method is shown.** With metal slides selected, the
  wood-runner settings (runner sizes, registration holes, custom runner
  geometry) are no longer listed as disabled alternatives, and the reverse
  with wood runners; the same holds for fixed runners and for hinge settings
  when a cabinet has no hinges. Searching still finds them, with the change
  that would bring them into use. The unused `metal_slide_hole_diameter`
  (superseded by the cabinet-side and drawer-side diameters) is no longer
  shown, and those two diameters now show in the legacy spacing mode too.
- **Hardware panel: method, then model.** The Hardware step opens with a
  Drawer slides (Tray slides on equipment stands) card and a Hinges card. Each
  starts with how drawers run (metal slides, wood runners, none) or the hinge
  type, then the model. **Generic** keeps every dimension editable (slide
  length, setback, clearance, height, hole pattern, count, spacing, first hole,
  height and diameter on each side; hinge count, end offset, cup diameter,
  depth and edge distance, fixing holes, mounting plate position) and can be
  filled from the two generic templates. A **catalog model** (72 slides from
  Accuride, Knape & Vogt and Hettich; 8 cup hinges from Blum, Hettich, Salice and GRASS) applies the maker's
  dimensions and shows them locked under *From the maker*, with the maker's
  notes and drawing; **Adjust dimensions**, or editing a value, turns it into a
  generic model "based on" that one. Designs saved before this release are
  matched against the catalog. Reference-only models without drilling data are
  listed but cannot be selected.
- **Hardware view.** A new **Hardware** tab beside the 3D model draws, with
  dimensions, the cabinet side and the drawer box side for a chosen drawer
  (left or right), or the cabinet side's mounting plate and the door for a
  chosen door. Cabinet-side slide holes and hinge plates are the positions the
  engine drills, read from its side-panel feature ledger (the background check
  now asks the engine for its verbose report); the drawer box side and the
  door are drawn from the settings with the engine's formulas. The view says
  which holes the slide length or panel depth leaves out, when the slide is
  longer than the box, whether cabinet and drawer holes line up, and whether
  plates are level with the door's cups. "Show on the boards" in the panel
  opens it.
- **Door fixing-hole offset (engine patch).** New setting
  `hinge_door_fixing_hole_offset` (0–30 mm, default 0, shop cart, utility,
  stackable and kitchen) moves the door's fixing screw holes from the cup
  center line toward the door center, so a screw-on cup hinge whose two screws
  sit beside the cup (commonly 9.5 mm off, 45 mm apart) is drilled correctly.
  Applied to single doors and mixed-bay doors, in 3D and in the door cut
  layout. The default keeps every existing output unchanged.
- **Export page.** **Export** in the header replaces the configurator with a
  full export page (**Design** returns, keeping the generated results):
  1 Manufacturing package, 2 Review (health, parts, sheets, engine warnings,
  materials, part table, warnings, machining depths), 3 Download, plus the
  editable OpenSCAD project, beside a sticky preview with a sheet (or full
  strip) picker and an operation picker. Sheet nesting is a choice of three
  described options with the sheet size and gap, and a link to change them.

Validation performed: `pnpm exec tsc`, the engine-source and
parity checks, units, nesting, settings visibility (alternatives hidden,
diameters visible in legacy mode) and the new `tests/hardware.cjs` (catalog
choice, generic edits, panel keys, hole patterns, hinge heights and door
drilling, ledger parsing) passed. The new `tests/hardware-engine.mjs` evaluated
the 88 starters of the five cabinet types with metal slides, drilling and cup
hinges: 271 engine slide rows matched the drawers and the view's holes, 180
mounting plates were level with their doors' cups, and a 9.5 mm offset moved
the door cut layout's fixing holes 9.5 mm toward the door center (the first run
found the engine shortening slides to the drawer box depth, which the view now
does too). Section, engine-fit, layout-editor and cut-layout suites passed, and
golden outputs of all 110 starters are unchanged, so the default offset alters
nothing. Both new tests run in CI. Checked in Chromium at 1500 and 390 px:
the panel's catalog and generic flows, wood runners, search showing hidden
alternatives, the Hardware view for slides and hinges, and the export page
generating a package, previewing sheets and keeping results when returning
to the design, without console errors or horizontal scrolling. Not run here:
the native OpenSCAD stackable and section tests (no native OpenSCAD in this
environment; CI runs them) and the 3D interference sweep (CI).

Remaining limitations: the feature ledger covers the cabinet side panels only,
so slides or hinges mounted on a partition or divider are drawn from the
settings and the view says so; drawer-side holes for wood runners are not
drawn; the catalog slides all leave automatic drilling off (the makers offer
several hole and slot choices), so their view shows the slide envelope without
holes until the model is adjusted to a generic one with drilling on.

## 0.12.0 — 2026-10-15

Roadmap A, gate 3: cut files come per stock sheet, and every starter proves it
nests.

- **Per-sheet nesting.** `lib/nesting.ts` takes the engine's placement records
  (one per through-cut part), groups parts by material and thickness, and packs
  them onto the design's stock sheet (`stock_width` × `stock_height`) with a
  maximal-rectangles packer: largest part first, best short-side fit, the
  layout gap as the sheet margin, and max(layout gap, kerf, cutter diameter) as
  the spacing between parts. Parts keep the orientation the engine drew them
  in; a part that cannot fit as drawn is turned 90°, and the export offers
  "never turn" (grain as drawn) and "turn freely" as alternatives. A part that
  fits no sheet is reported, never dropped.
- **Sheet files in the manufacturing package.** Every operation layout (cut,
  pockets, engraving) is re-mapped from the strip onto each sheet, so the
  package gains `sheets/<nn>-<material>-<thickness>/<operation>.svg` and
  `.dxf` (closed polylines, one layer per operation, the stock outline on
  `STOCK`), `sheets/nesting.json` with every placement, and `PROBLEMS.txt`
  only when something did not fit. The SVGs use the engine's conventions
  (millimetres, y negated, a stock frame) and carry one path per part with the
  part id. The review shows the sheet count per material and the sheet
  previews; the READ-ME describes the folder.
- **Real sheet counts.** The cut list panel and the printable cut list now
  show the nested sheet count per material instead of an area estimate (the
  estimate remains the fallback for a log without placement records), and say
  how the count was obtained.
- **Golden gate 3.** `tests/golden.mjs` nests every starter at its own default
  stock and fails on an unplaced part, two parts closer than the gap, a part
  outside the usable area, a part that changed size, or a part with more or
  fewer than one outline on its sheet; each snapshot records the sheet summary,
  so a change in nesting shows up in the diff. `tests/nesting.cjs` covers
  grouping, spacing, margins, the three rotation modes, oversize parts and the
  re-mapping of an engine-style layout (frame dropped, holes travelling with
  their part, rotation applied) in SVG and DXF; it runs in CI with the unit
  tests.
- **Coverage text.** The plan panel and README list sheet nesting as checked.

Validation performed: `tests/golden.mjs --update` nested all 110 starters at their
default stock with no unplaced part, no two parts closer than the gap, nothing
outside the margin and one outline per part per sheet (the first run found two
real problems, fixed before the re-bless: tall pantry and storage sides did not
fit as drawn, hence the turn-when-needed default, and contours more than ten
metres up the strip missed their part by the engine's 0.1 mm rounding, hence
the magnitude-scaled tolerance); every snapshot gained its sheet summary and
nothing else changed. `tests/nesting.cjs`, the unit, settings-visibility,
v5-integration, parity and engine-source sync checks pass; `tsc` is clean.

Remaining limitations: the packer is a heuristic (no rotation search beyond 0°
and 90°, no remnant reuse, no grain data from the engine, so "grain as drawn"
is only as good as the strip layout); re-mapped coordinates keep the engine's
SVG precision (six significant digits, so parts more than ten metres up the
strip carry up to 0.1 mm of rounding, exactly as in the strip files); the 3D
interference sweep and the machining-feature ledger limits of 0.11.0 still
apply.

## 0.11.0 — 2026-10-15

Roadmap A, gate 2: no release ships parts that intersect in 3D, kerf
compensation is complete, and settings with physical limits now carry them.

- **3D interference sweep over everything.** `tests/engine-interference.mjs`
  renders the engine's part groups as solids (Manifold backend) and fails on any
  pair sharing more than 0.05 cm³. It now covers the worktop, base hardware
  (casters and levelers with their mounting plate), the stackable base and the
  metal-slide envelopes as their own groups, the standalone drawer family and
  the equipment stand by part kind, and runs three job lists: the hand-written
  cases (now 27, four of them hardware combinations), every one of the 110
  starters, and 24 randomized designs built from a seeded generator that
  patches choices, toggles, counts and sizes (`SEED`, default 20261015, so CI
  is reproducible). A design the engine itself rejects is skipped, since the
  app blocks its export. Flags: `--starters`, `--random N`, `--all`,
  `SHARD=i/n`; an STL extent pre-filter keeps the pairwise test affordable.
- **CI shards.** The sweep runs as its own six-shard matrix job (`sweep`) on
  every push and pull request, and the release tag now needs both `build` and
  `sweep` green. The 23-case run is no longer repeated inside `build`.
- **Kerf compensation completed.** `apply_kerf_compensation` now offsets every
  finished through-cut part by half the kerf in `placed()`: outlines grow,
  holes, slots, notches and dado openings shrink, so the parts and their
  joints come out at the listed sizes. Before, only outer rectangles and the
  metal-slide holes were compensated, so compensated slots and dados came out
  wide. Pockets and engraving are not offset. The help text for `kerf` and
  `apply_kerf_compensation` says what the switch does and when to leave it off.
- **Limits for settings that have them.** The OpenSCAD front ends declare
  customizer ranges for the overall size (50–3000 mm), stock sheet size
  (100–5000 mm), `layout_gap` (1–200 mm), `kerf` (0–10 mm) and the cutter
  diameter (0.1–50 mm); the engine schema and the app schema carry the same
  ranges. Lengths that cannot be negative (diameters, thicknesses, spacings,
  gaps, clearances, margins, sizes) get a floor of zero in the app; offsets,
  overhangs and reveals stay free. A typed value outside the range is clamped
  on commit and the field's tooltip states the range.
- **Layout gap floor in the engine.** `LAYOUT_GAP` is a Design Health error
  when `layout_gap` is under 1 mm, since touching outlines merge into one
  contour in the SVG even though no placement overlaps.
- **Coverage text.** The plan panel and README now say that
  3D intersections are swept for every starter and randomized designs in the
  test suite rather than checked for the exact design on screen, and list
  machining-feature collisions on panels other than the two sides as not yet
  checked.

Validation performed: `node tests/engine-interference.mjs --all` ran locally in
2,322 s single-threaded: 160 configurations (27 cases, all 110 starters, 23
randomized designs; one randomized design was skipped because the engine rejects
it) rendered with no overlapping parts across 1,759 intersected group pairs;
`tests/golden.mjs` still matches all 110
starters (the kerf refactor changes nothing at the default, compensation off);
`tests/cut-layout-check.mjs` adds a kerf case (1 mm kerf: 16 openings shrink by
1 mm, outlines grow by 1 mm, one contour per part) and asserts the `LAYOUT_GAP`
error at a negative gap; `tests/units.cjs` covers clamping and the derived
floors; the unit, settings-visibility, v5-integration, parity and
engine-source sync checks pass; `tsc` is clean.

Remaining limitations: the machining-feature collision ledger still covers only
the two side panels (bottoms, tops, partitions and drawer fronts are not
checked for colliding holes, dados and slots); the 3D sweep runs in the test
suite, not in the app for the design on screen; ranges exist only for the
settings listed above, the other numeric settings have a floor at most; cut
files are still one strip per operation, not sheets (gate 3).

## 0.10.0 — 2026-10-15

Roadmap A, gate 1: the flat cut layout can no longer ship fused or overlapping
parts, and every starter proves it on every push.

- **One placement table for the cut layout.** `layouts_modules.scad` now holds
  `cut_layout_placements()`, one record per through-cut part (id, position,
  width, height, colour), and the carcass, drawer, door and accessory layout
  modules place each part from that table through `placed(id)`; a part without
  a record stops the render with an assertion instead of landing somewhere
  unrecorded. The equipment stand engine, which lays its parts out in one row,
  reports the same records from its own part list.
- **PLACE records.** The BOM output echoes `PLACE|<id>|X=|Y=|W=|H=` for every
  part (lower-left corner in the strip, nominal size before kerf compensation).
  The golden snapshots keep them, and the sheet nester planned for the next
  gate will read them.
- **LAYOUT_OVERLAP.** The engine compares every pair of placement rectangles
  (widened by the kerf when kerf compensation is on) and reports
  `CHECK|ERROR|LAYOUT_OVERLAP|Parts A and B overlap by w x h mm in the flat cut
  layout.` in every output mode. The status chip shows it as a problem to fix
  and the manufacturing export refuses to produce cut, pocket or engrave
  files while it stands, exactly as for the other engine errors. The equipment
  stand reports the same code when its layout gap is not positive.
- **Drawer bottoms on their own row.** The drawer bottom used to share a row
  with the drawer box back, beside it at x = 0, so any drawer wider than about
  twice its depth fused the two outlines in the exported cut file: the
  benchtop wide 8-drawer starter exported 45 outlines for 53 parts while every
  check passed. The bottom now sits on its own row below both cross panels
  (`drawer_layout_bottom_y`), and the engrave labels, print layout and pocket
  overlays follow the same helper. That starter now exports 53 outlines.
- **No phantom drawer row.** Cabinets without drawers reserved a full drawer
  row in the strip before the door row; the door row now follows the drawer
  region only when drawers are cut, so 34 drawerless starters have shorter
  strips.
- **Cut-layout gate in the golden suite.** `tests/golden.mjs` now runs
  `tests/cut-layout-check.mjs` for all 110 starters: every BOM part has one
  PLACE record of the same size, no two rectangles overlap, and the exported
  cut SVG has exactly one outer contour per part whose extent equals that
  part's rectangle (so a fused pair, a drifted position or a part drawn larger
  than its BOM size all fail). This gate is independent of the snapshots, so
  `--update` cannot bless an overlap. Run on its own, the file proves the error
  fires: a negative layout gap produces LAYOUT_OVERLAP records and the cut
  export is blocked. CI runs both.
- **Coverage text.** The status chip summary, the "what this check covers"
  panel, the manufacturing review and the README now list the flat cut layout
  as checked; 3D part intersections and sheet nesting remain listed as not
  checked.

### Validation performed

TypeScript, `tests/units.cjs`, `tests/settings-visibility.cjs`,
`tests/v5-integration.cjs`, `tests/section-wasm.mjs`,
`tests/cut-layout-check.mjs`, `tests/engine-fit.mjs`, `tests/layout-editor.mjs`,
`tests/engine-interference.mjs` and `tests/golden.mjs` pass; the parity table
and embedded engine sources are current; the static build succeeds. The golden
snapshots were re-blessed: 92 of 110 cut layouts changed (58 starters with
drawers, where the bottom moved to its own row, and 34 without drawers, where
the phantom row went away); the equipment stand snapshots only gained PLACE
records. The cut layouts of a drawerless kitchen wall cabinet were compared
outline by outline before and after the refactor: identical apart from the
removed phantom row.

Remaining limits: the placement table covers the through-cut layout; the
pocket and engrave layouts reuse its positions but are not themselves checked
for overlap. The gate compares rectangle extents, so a part drawn with the
right extent but wrong interior features is caught by the golden fingerprint,
not by this check. Strips are still one tall column per design; per-sheet
nesting is the next gate.

CI change after the 0.10.0 merge: the first main build of 0.10.0 crashed in the
golden step with the same Node 24 V8 wasm-teardown failure as before, this time
despite `--no-memory-protection-keys`, so `build-pages.yml` now pins Node 22 for
the build job (the flag stays on as a second guard). The release is cut from the
same sources; no application code changed.

## 0.9.0 — 2026-10-15

A settings panel that shows the decisions that shape the cabinet first, explains
every setting, and says why a setting is out of use instead of hiding it. This is
the "intuitive package" roadmap (B) from the October 2026 codebase review; the
engine, exports and reliability checks are unchanged.

- **Section rail.** The section buttons became a rail beside the settings:
  cabinet sections first (Sizing, Structure, Drawers, Doors, Shelves, Dividers,
  Trays, Mounting), then **Shop details** (Materials, Hardware, Machining,
  Engine & export) collapsed until opened, or opened automatically when a part
  click or search lands there. Each entry shows the number of settings in use
  and how many more sit behind **Show advanced**; while searching it shows the
  number of matches instead. Every section has a one-line description.
- **Fewer settings in the default view.** The engine's render visibility
  toggles, calibration coupons, export frame, label sizes, reports and other
  knobs moved out of the separate Output and System sections into one
  **Engine & export** section where only the cut-layout gap and the label size
  are shown by default. Sheet width and height moved to Materials, next to the
  stock they describe. Hole patterns, plate insets, registration details, fit
  tuning, margins and similar settings are now flagged advanced
  (`lib/settings.ts`, `ADVANCED`). Default-visible settings per type at the
  default starter: shop cart 124 → 55, utility 128 → 62, benchtop 87 → 35,
  stackable 111 → 45, kitchen 136 → 72, drawer 52 → 34, equipment stand
  59 → 36. Two settings gained dependency rules: ganging settings need a ganging
  style, and "wall doors flush top" needs a wall-hung cabinet.
- **Settings not in use are shown, not hidden.** Each section ends with a
  collapsed list of the settings that do not apply to the current configuration,
  each disabled and followed by the change that brings it into use ("Select
  metal drawer slides", "Requires tab-and-slot carcass joinery"). Searching
  includes them, open, so "why can't I find X" has an answer. Settings owned by
  the Layout tab are listed only in search results, with "Set in the Layout
  tab". Saved values are kept as before.
- **Help for every setting.** 227 settings had neither a tooltip nor an engine
  description (hole patterns, slide drilling, French cleats, calibration, tab
  placement, equipment-stand sizing, drawer fit targets and more). They now have
  plain-language help, written from the engine's parameter definitions,
  defaults and resolve logic rather than measured against dimension reports;
  render visibility toggles and measured thicknesses are described by rule.
  Option labels were added for 30 more choices (relief styles, tab placement,
  drilling mode, ganging, drawer face styles, report levels) and clearer titles
  for the engine and sheet settings.
- **Lists are edited one entry at a time.** Width weights, custom tab centers,
  slide hole positions and other lists show one input per entry with a remove
  button and an **Add** button; entries tied to a bay or column count can only
  be edited. The JSON editor remains only for nested lists.
- **One 3D model tab.** Preview and Exact 3D merged into **3D model** with an
  **Instant** / **Exact** switch. Instant keeps interior, exploded and dimension
  controls; Exact keeps the OpenSCAD render with its mode and auto-update, and
  only renders while it is showing. The exact view's result survives switching
  tabs.
- **Engine kept warm.** The background check worker and the exact-render worker
  now stay alive between runs and reuse the compiled OpenSCAD module (a `warm`
  message compiles it during the first debounce), instead of spawning a worker
  and compiling 9.6 MB of WebAssembly on every edit. An edit that lands during
  a run still terminates that run. Headless Chromium on the shop cart starter:
  first check 1.1 s, following checks 0.6–0.8 s. The pre-compilation is
  browser-only: under Node (the test harness runs four short-lived workers in
  parallel) an ahead-of-time compiled module tripped a V8 JIT-page check on
  worker termination in CI on Node 24, so there the engine loads as before.
- **Honest status.** The status chip says **Engine checks passed** (or
  *Checks passed · n notes*) instead of *Parts fit · checked by OpenSCAD*, and
  its tooltip says what was checked. The Cut list & fit tab gained **What this
  check does and does not cover**: sizes, drawer and shelf fit, joinery limits
  and hardware conflicts are checked; parts intersecting in 3D, overlaps in the
  cut layout, sheet nesting, grain and edge banding are not.
- **Construction switch in the layout header.** When an arrangement makes the
  engine change construction (single column, side-by-side bays, sections), the
  Layout tab header now says **Built as: …** permanently and shows the change
  as a dismissible notice instead of a toast that disappears.
- Documentation: README walkthrough updated for the rail, the merged 3D tab and
  the coverage list.

### Validation performed

TypeScript, `tests/units.cjs`, `tests/settings-visibility.cjs`,
`tests/v5-integration.cjs`, `tests/desktop-assets.cjs`, `tests/section-wasm.mjs`,
`tests/engine-fit.mjs`, `tests/layout-editor.mjs`, `tests/golden.mjs` and
`tests/engine-interference.mjs` pass; the parity table and embedded engine
sources are current; the static build succeeds. Screenshots at 1600 px and
700 px of the rail, inactive lists, search, both 3D modes, the cut list and the
layout header were reviewed with no console errors. `tests/source-loading.cjs`
and `tests/usability.cjs` already fail on 0.8.0 (missing fixture and module)
and are not in CI.

CI change (no application change): the five engine suites in
`.github/workflows/build-pages.yml` now run with `--no-memory-protection-keys`.
After the 0.9.0 merge the hosted Node 24 runner crashed twice in V8's
`ThreadIsolation::UnregisterWasmAllocation` while tearing down a test worker
(once in the layout-editor suite, once in the golden suite); the suites
themselves had passed. The crash never reproduced locally on a CPU without
memory protection keys, so the flag is a mitigation, not a verified root-cause
fix: if CI crashes again the fallback is pinning Node 22.

CI change (no application change): the release job now requests the Windows
workflow for the tag it just created, and the Windows workflow attaches its ZIP
only on such a request; pushes are test builds. Before this, a push attached
the ZIP only when the release was tagged from that same commit, so v0.9.0 was
first published with the web build alone (the release was tagged from the CI
fix commit, which changed no desktop file). For v0.9.0 the Windows workflow
was run manually for the tag to attach the ZIP. Validation: the workflow files
parse as YAML; the dispatch path is the one used manually for v0.9.0.

Remaining limits: the advanced classification is a hand-written rule list, so
a setting someone changes often may still sit behind the switch; the visible
counts above are at each type's default starter; the Exact view renders only
while it is showing, so switching to it after edits still waits for a render;
the engine worker is recycled after any failed or cancelled run.

## 0.8.0 — 2026-10-02

Section layouts are now real construction and are available on shop carts and
utility cabinets as well as kitchen cabinets.

- **One construction for bays and sections.** Section layouts used to place
  drawers and doors in "virtual cabinets" inside loose, butt-fit divider blanks.
  The engine now builds them with the same bay construction as side-by-side bays,
  generalized to any arrangement: every section opening is a bay with its own
  height, and the bay functions (drawer stacks, doors, hinges, shelves, shelf
  pins, fronts) work per opening.
- **Joined dividers.** Vertical section dividers run between the members below
  and above them (carcass bottom/top or a horizontal divider) and horizontal
  dividers between the members beside them (carcass sides or vertical dividers),
  joined with the cabinet's joinery: dado tongues, tabs through slots, or butt
  joints with optional registration holes. Receiving dados, slots and holes are
  cut in the sides, bottom, top/stretchers and other dividers, and appear in the
  cut, pocket, print and engraving layouts and the BOM (`BAY-P…` partitions,
  `BAY-D…` dividers).
- **Opposed joints.** Where two horizontal members meet a partition from both
  faces at the same height (or two partitions meet a divider from above and
  below), their tabs share the through-slot at half length and dados keep a web.
  This also fixes side-by-side bays with fixed shelves at equal heights on both
  sides of a partition using tab-and-slot joinery: their full-length tabs
  overlapped (76 cm³ in the open service cart starter with tab-and-slot).
- **Drilled hardware.** Slide holes (or wood-rail registration holes), hinge-plate
  holes and shelf-pin rows of every section opening are drilled into the carcass
  side or partition beside it, and are part of the outer-side collision ledger
  and ganging checks. Previously they were left to be transferred during fitting.
- **Fronts.** Overlay fronts meet at the centre of each divider with the bay gap
  and cover the carcass edges at the outside; inset fronts sit inside their own
  opening. Section fronts used to stop inside each opening in every case. Face
  frames still surround section layouts; openings at the frame are sized to the
  frame opening.
- **Exact layout reports.** Section layouts now emit the same `LAYOUT` records as
  other layouts (with the tree node of each opening), so the Layout tab draws the
  engine's own fronts and shelves for sections instead of estimates.
- **Per-opening hinge side and shelf style.** Section rows gained two optional
  fields; the Layout tab now offers hinge side and fixed/adjustable shelves for
  section openings. Designs saved with twelve-field rows keep the cabinet's
  single-door hinge side and fixed shelves.
- **Sections on shop carts and utility cabinets.** Both types gained the
  `sections` layout. In the Layout tab, splitting a bay top/bottom (or a fifth
  column) now builds a section layout on these types instead of being refused.
- **New checks.** `SECTION_BOUNDARY` (an opening's drawers, shelves or hinge need
  a divider where the split has none), `SECTION_DIVIDER_ENDS` (a divider would end
  against a split without a divider), `SECTION_DOOR_SIZE`, and per-opening
  door-height warnings.
- **Tests.** Golden outputs (`tests/golden.mjs`) record the engine's parts list,
  reports and cut/pocket fingerprints for all 110 starters; this refactor
  reproduces all 109 non-section starters exactly (the photo section example
  changed as intended). Eleven extra side-by-side bay configurations (all
  joinery styles, hinges, shelf styles, inset fronts, no partitions, wall
  mounting) were also reproduced exactly, apart from the overlapping-tab fix
  above. The interference suite now checks every partition, divider and set of
  fixed shelves on its own and adds section grids, a nested face-frame layout
  with inset doors and a front rail, and the opposed-shelf bay case (23
  configurations, no overlaps). The engine-fit suite covers the new checks and
  joined sections on shop cart, utility and kitchen cabinets with tab-and-slot,
  dado and butt joinery; the layout editor suite round-trips all 88 starters and
  checks exact section fronts, hinge side, shelf style and a typed section height
  on a shop cart.
- `docs/PARITY.md`, generated by `scripts/parity.mjs` and checked in CI, lists
  which features, options and front layouts each cabinet type offers, the
  combinations the engine still refuses, and settings only some types expose.
- Documentation: the section layout guide, README and the Windows ZIP's
  start-here note describe the joined construction; the guide lists the saved
  row format and how older designs open.

Remaining limits: section openings use the bay front gap at dividers (drawer gap
within a drawer stack); wood rails and slides in openings at a face frame still
need spacer blocks to reach the carcass side, as in other face-frame layouts;
cut and pocket layouts are registered rows, not optimized sheet nests.

## 0.7.1 — 2026-10-02

Windows desktop start-up. The application itself is unchanged from 0.7.0.

- The window now opens immediately with a *Starting…* page. Previously nothing
  appeared until the app had read and hashed every runtime file (about 330 MB,
  including the 246 MB EXE) on every launch; on a first launch, with Windows
  scanning the newly extracted files, that could look like the program did
  nothing.
- Each launch now checks that every runtime file is present with the size
  recorded at build time (file metadata only) instead of reading and hashing it,
  so antivirus no longer has to scan every file, including DLLs Chromium loads
  only when needed, before the app can start. Files that are still being
  extracted (missing, short or locked) are retried for about four seconds before
  an error is shown. The full SHA-256 comparison is still made by
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
