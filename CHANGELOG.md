# Cabinet Workshop changelog

This is the consolidated, evidence-based history of the work delivered for this
project. It covers application changes, engine integrations, documented engine
package changes, desktop fixes and repository/hosting work. It replaces the
short release summary previously kept here.

Application versions (currently **0.5.2**) are separate from the bundled
**Modular Organization 5.3.0** package, engine family **v5**, and **MOI-4** interface
contract. Older engine labels such as v25, v29 and v34 are not application release
numbers. Historical work without a recorded application version is listed by
milestone rather than assigned an invented release number or date.

The older Sites commit IDs below are provenance references from the original
source repository; those commit objects were not imported into GitHub. GitHub
history starts with repository setup and the source import. This document records
verified changes and historical package notes, not every experiment or every
possible configuration. Imported package capabilities are identified as such.

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
