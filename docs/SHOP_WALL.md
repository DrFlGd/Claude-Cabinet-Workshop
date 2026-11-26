# Shop wall: French-cleat organizers

The **Shop wall** area of the app holds 31 wall-mounted shop organizers (shelves,
cubbies, door and drawer cabinets, tool racks, drill stations, boxes and holders)
plus a fit test coupon. They are based on the owner's "ShopWall" OpenSCAD modules
(31 design files sharing a construction library with an inch Customizer, a board
model, a tab/slot planner, CNC side hooks and beveled cleats) and rebuilt on the
workshop's own SCAD core.

- Engine: `public/products/shop_wall/shop_wall.scad` (one file, `module_type` picks
  the module).
- Editor definition: `lib/products/shop-wall.ts` (sections, labels, when each setting
  applies, one starter per module, quick checks, summary, assembly order).
- Shared core it includes, from `public/engine/v5/src/modular_organization/data/scad/`:
  `joinery.scad`, `tab_pocket.scad`, `seam_joinery.scad`, `cleat.scad`,
  `wall_mount.scad`, `placement.scad`.

## Why a product, in its own area

Each organizer is a small design with its own few settings (tool slots, bin grid,
drawer count, dowel size) on a common construction: panels joined by tabs and
slots, a back, and a wall mount. The product framework (`lib/products`) already
gives an engine like this the shared engine check, cut list, Export view, sheet
nesting, per-sheet SVG/DXF, recovery, golden snapshots and the 3D interference
sweep, and lets the editor show only the settings that matter. A cabinet type was
rejected: the cabinet settings model carcass bays and would need a large
hand-written schema for 31 unrelated layouts. The picker lists the product under
its own **Shop wall** heading, so the organizers read as a separate area of the
workshop with their own editor, while the Export view, cut list and checks are the
ones the cabinets use.

All 31 modules share one engine file rather than 31 files, so a fix to the
construction (a relief, a joint rule, a check) applies to every module at once, and
switching modules keeps the stock, joinery, machining and mount settings.

## Modules and their own settings

Starter sizes are the original presets (inches converted to mm; the editor shows
either unit). Settings not listed here (size, mount, stock, joinery, machining,
sheets) are common to every module.

| Group | Module | Starter W × D × H (in) | Module settings |
|---|---|---|---|
| Shelves and displays | Simple shelves | 20 × 7 × 6 | Shelves |
| | Jar shelves | 8 × 5 × 20 | Shelves, lip height |
| | Spray paint display | 19 × 5.5 × 8 | Shelves, lip height |
| | Single cube shelf | 12 × 10 × 12 | Bays |
| | Double cube shelf | 24 × 10 × 12 | Bays |
| | Narrow shelves | 7 × 6 × 18 | Interior shelves |
| | Sandpaper shelf | 7 × 7 × 18 | Interior shelves |
| Cabinets | Single / double door cabinet | 12 × 9 × 14 / 24 × 11 × 18 | Interior shelves, door gap |
| | Sliding door cabinet | 24 × 12 × 17 | Interior shelves, gap |
| | 3- / 4-drawer cabinet | 15 × 12 × 14 / 15 × 12 × 18 | Drawers, gap |
| Tool racks | Chisel rack | 16 × 3.5 × 5 | Slots, slot width, slot length, spacing |
| | Clamp rack | 16 × 8 × 6 | Slots, slot width, slot length, spacing |
| | Hammer rack | 14 × 4.5 × 5 | Holes, hole diameter, spacing |
| | Screwdriver rack | 16 × 4 × 5 | Holes, hole diameter, staggered second row, spacing |
| | Plier stand | 16 × 5 × 7 | Slots, slot width, slot length, spacing |
| | Router bit stand | 16 × 4 × 5 | Holes per row, rows, shank diameter, allowance |
| | Circular saw stand | 13 × 13 × 9 | Guard slot width and position, slot length |
| Drill stations | Simple / double drill station | 6 × 8 × 5 / 10 × 8 × 5 | Drill slots, neck width, slot length |
| | Single / double shelf drill stand | 15 × 9 × 9 / 22 × 10 × 15 | Drill slots, neck width, compartments above |
| Boxes and bins | Closed lid box | 17 × 10 × 8 | Bin columns and rows, lid gap |
| | Screw box | 16 × 9 × 5 | Bin columns and rows, front height |
| | Shallow storage box | 13 × 8 × 5 | Front height |
| | Glove box | 12 × 5.5 × 7 | Slot height and length |
| Holders | Hook panel | 19 × 3.5 × 6 | Hooks |
| | Material storage stand | 30 × 10 × 10 | Brackets, lip height |
| | Paper towel holder | 14 × 8 × 7 | Dowel diameter, hole clearance |
| | Wrench holder | 7 × 5.5 × 17 | Slots, slot width, slot rise, slot length |
| Fit test | Fit test coupon | — | (uses the design's stock, clearances, cutter and bevel) |

Settings that do not apply stay visible under "settings not in use" with the reason
(for example *Cleat: Used with a French cleat mount*, or *Hook panels have no side
panels to cut hooks into*). Choosing a module loads its starter sizes and module
settings; mount, stock, joinery, machining and sheet settings are kept. Labels follow
the module (the opening width reads *Chisel slot width*, *Bit shank diameter*, *Drill
neck slot width* and so on).

## How the modules use the core

| Concern | Core used | In the shop wall engine |
|---|---|---|
| Stock and cleat thickness | Nominal presets and measured thickness, as the cabinets | `carcass_stock`, `material_thickness`, `cleat_stock` |
| Tabs along a joint | `joinery.scad` tab planner (`effective_tab_count`, `tab_width_for`, `tab_center`; settings `joint_tab_width`, `target_tab_spacing`, `joint_tab_edge_margin`, `minimum_joint_web`, `tab_count_mode`, `joint_tab_count`, `max_auto_tab_count`) | Every seam is one record; `seam_joinery.scad` splits it into segments, keeps a cutter radius clear at each end and asks the planner for the tabs |
| Slots and their corner relief | `tab_pocket.scad` `tp_pocket_2d` (dog-bone or T-bone, open walls left square) | Every slot, open-edge notch and hook notch |
| Tab shoulder relief | `tab_pocket.scad` `tp_tab_root_reliefs_2d` | Beside every tab |
| Screws | `tab_pocket.scad` `tp_web_centres` via `sj_screws` | Clearance holes in the webs beside the tabs; pilots drilled at assembly |
| Holes smaller than the cutter | The products' drill layout (as the media cart) | Screw holes, wall rail screw holes and small tool holes go to `drill_layout` (drill at the circle centres) instead of the cut layout |
| Beveled cleat and wall rail | `cleat.scad` `mo_cleat_profile` | Hanger (stand half) and wall rail (wall half), cut as blanks and beveled on a saw |
| CNC side hooks | `wall_mount.scad` (new) | Hook outline with a rounded tip, the inside-corner relief for the rail's lip, rail position, hang lift, stud screw stations, other rails on the wall |
| Cut layout | `placement.scad` (moved out of `layouts_modules.scad`) | One placement table, kerf compensation, PLACE records, overlap check |
| Kerf, layout gap, cutter, sheet size | Same settings as the cabinets | Nesting and per-sheet SVG/DXF by `lib/nesting.ts` |
| Reports | BOM, PLACE, DIM, CHECK and HARDWARE records parsed by `lib/analysis.ts` | Cut list, Hardware list, design health, packet |

New shared core added for this work: `seam_joinery.scad` (multi-tab seam planning on
the core planner, screws beside tabs, coverage of a sloped panel along a seam,
polygon helpers) and `wall_mount.scad` (CNC side hooks, inside-corner relief along a
corner's bisector, beveled-rail geometry, stud screw stations, adjacent rails).
`placement.scad` is the cabinets' placement code moved verbatim into its own file so
the products can include it; the cabinet golden snapshots are unchanged.

## Review of the original modules

All 31 presets, with CNC side hooks and with beveled boards, and 20 variants were
rendered part by part with the bundled OpenSCAD and every pair of parts intersected:
none of the originals has intersecting parts. (Overlaps reported for the paper towel
holder came from the review harness drawing the dowel in every part's render, not
from the model.) No unit mistakes of consequence were found: inch values are
converted once and the exported geometry is in mm. The problems below are about
joints that would not fit or assemble, parts that cannot be cut as drawn, and
missing manufacturing output.

| # | Original | Problem | Correction | Modules |
|---|---|---|---|---|
| 1 | CNC hooked side panels: rear tabs and the step where the hook passes the back | No shoulder relief and no relief in the inside corner: the cutter's radius stops the panel seating against the back | T-bone shoulder reliefs beside every tab; the hook's inside corner and the notch step get a relief cut along the corner's bisector (`wm_corner_relief`), checked to stay above the back notch | Every module with side panels |
| 2 | With CNC hooks no joint holds the back (ribs join the back only without CNC hooks; shelves never do) | The back is held only by friction in the hook notches | Every horizontal panel tabs into the back; side panels, dividers and cheeks do too where their rear edge below the hook has room. A check requires at least two tabs or screws into the back | All with a back |
| 3 | Sloped or pointed ribs (rack sides, gussets, hooks, towel cheeks): rear tabs start at the pointed tip | The tab and its shoulder relief cut off a sliver of the tip (found by the cut-layout gate: two outlines for one part) | A rib's rear seam starts where it has at least a board thickness (or two cutter widths) of wood | Racks, drill stations, hook panel, towel and wrench holders |
| 4 | Sliding doors: leaves sit in 3/4″ deep bottom channels with 1/16″ lift | The leaves cannot be lifted out of the bottom channel, so they cannot be fitted or removed | Bottom strips half a board (or the screw pilot) high, top strips deep enough to lift a leaf clear of the bottom strips and still keep it in the top channel; leaves shortened to match | Sliding door cabinet |
| 5 | Interior shelves spaced over H − 3t | Openings are unequal with two or more shelves (sandpaper shelf: 1.22″ middle vs 1.97″ end openings) | Equal clear openings | Narrow and sandpaper shelves, door cabinets |
| 6 | Beveled board: lower spacer full board thickness | On modules shorter than about 2 × cleat + bevel rise (≈ 5.75″) the spacer hits the rail when the module is lifted straight up | Spacer sized for a straight drop where possible; otherwise an info note says to tilt the module in | Chisel, hammer, screwdriver and router racks, simple and double drill stations, screw and shallow boxes |
| 7 | Wall rail screws placed at 0.6 × rail length | A rail shorter than the stud spacing cannot reach two studs | Screw stations at the stud spacing (setting), at least two, centred; an info note when the rail is shorter than the stud spacing | All French-cleat modules |
| 8 | Holes and slots of any size, all in the through-cut output | A hole smaller than the cutter cannot be cut, and a slot narrower than the cutter cannot be cut at all | Holes smaller than the cutter are drilled from a separate drill layout (screw holes with the default 6.35 mm cutter, small router bit holes); slots and slot-shaped openings must be at least the cutter (error) | All; racks, stands, drill stations |
| 9 | T-bone reliefs on slots that open at a panel edge | Reliefs on the open side scallop the panel edge | Open walls get no relief (core `tp_pocket_2d` open flags) | Shelves flush with a panel edge |
| 10 | Screw pilots modelled as holes in the panel edge | An edge hole cannot be cut on a flat sheet | Clearance holes through the face; the pilot is listed as drilled at assembly. Joints whose part is too shallow for the pilot are glued only | All |
| 11 | Door pull mortise 0.12″ above the finger bore | The mortise and its corner reliefs break into the bore | Pull moved a cutter width plus clearance clear of the bore | Door cabinets |
| 12 | Paper towel dowel drawn but not listed | Not in any parts or hardware list | Listed as hardware with its length | Paper towel holder |
| 13 | Flat 2D view lays parts in a strip | Not nested on sheets, no per-sheet files | Placement table, engraved labels, sheet nesting and per-sheet SVG/DXF from the app | All |
| 14 | Screwdriver rack: a back-less three-piece CNC version with a staggered row | A different construction from every other rack | Standard rack; the staggered second row is a setting | Screwdriver rack |
| 15 | Hook panel offers CNC side hooks | It has no side panels to cut hooks into | Always hangs from a beveled board; the Cleat setting is disabled with that reason | Hook panel |
| 16 | Sliding door rear leaf: grip block on the inside face | The block of the rear leaf passes the front leaf only with extra track clearance | Finger bores in both leaves | Sliding door cabinet |
| 17 | Closed lid box: lid over full-height sides | Lid and sides share the top corner | Sides and front stop one board below the top; the lid rests on them, hinged at the back | Closed lid box |

## Fit verification

Nothing here has been cut yet. The engine checks every design geometrically, the
test suite sweeps every module, and the Export view makes a fit test coupon to cut
before a full module. **These are geometric checks, not a substitute for a physical
cut**: they show the parts fit as drawn with the stated stock, clearances and cutter.
They do not know how your machine, cutter deflection, sheet flatness or actual
thickness behave. Measure the stock, cut the coupon, adjust, then cut the module.

### What the engine checks (CHECK records, every design, in the app and in CI)

- **Joint fit**: every tab against its slot: slot = tab + fit clearance on both axes
  (`FIT_CLEARANCE`), slot at least the cutter (`SLOT_CUTTER`), tab length against the
  thickness it passes through and the tab setback (`TAB_LENGTH`), the slot corner
  relief covers the tab corner (`SLOT_RELIEF`; one warning when relief is left to
  CAM), at least two cutter widths of wood between slots (`TAB_WEB`), room for a tab
  or screw on every joint (`NO_ROOM_FOR_TABS`, `NO_ROOM_FOR_SCREWS`).
- **Screws**: each clearance hole lies in the host's wood (`SCREW_LANDING`), clear
  of slots, notches and openings with their reliefs (`SCREW_CLASH`), and the pilot
  fits the member's edge (`SCREW_PILOT`). Within each part, no slot, hole, notch or
  opening runs into another (`CUT_CLASH`).
- **Assembly**: every part has an assembly step and a direction; each joint must go
  together along its tabs from the parts already placed (`ASSEMBLY_ORDER`), so no
  part needs to enter two joints from different directions at once. The back must be
  held by at least two tabs or screws (`BACK_HELD`). No two parts share space
  (`PART_OVERLAP`, by their boxes; the test suite does the exact 3D check).
- **French cleat**: nothing reaches behind the wall (`WALL_CLEARANCE`), cleat larger
  than its bevel rise and lower than the module (`CLEAT_SIZE`), rail not below the
  module (`RAIL_BELOW_MODULE`), hook tip leaves a bearing flat (`HOOK_TIP`), hook
  deep enough for the cutter (`HOOK_CUTTER`), hook relief above the back notch
  (`HOOK_RELIEF`), module tall enough for the notch (`HOOK_NOTCH`), rail reaches both
  hooks (`RAIL_LENGTH`), other rails on the wall at the stated pitch clear of the
  hooks, hanger and spacer (`ADJACENT_RAIL`), notes for a tilt-in hang and a rail
  shorter than the stud spacing (`HANG_TILT`, `RAIL_STUDS`).
- **Functional fits**: doors and drawers keep at least 0.5 mm all round and shelves
  stay behind the doors (`DOOR_FIT`, `DRAWER_FIT`); sliding leaves lift out of the
  bottom channel and stay in the top one, are wide enough for their bores and leave
  room for shelves (`SLIDING_FIT`, `SLIDING_WIDTH`, `SLIDING_DEPTH`); bins at least 20
  mm clear (`BIN_FIT`); tool openings, slot lengths, router bit allowance, screwdriver
  rows, glove slot, dowel, wrench slots, gussets, hooks and brackets fit their parts
  (`TOOL_FIT`, `SLOT_LENGTH`, `DOWEL_FIT`, `GUSSET`, `HOOK_COUNT`, `BRACKET_COUNT`).
- **Cut layout**: every part placed once, no overlapping rectangles
  (`LAYOUT_OVERLAP`), parts within the sheet (`SHEET_SIZE`).

### What CI checks

- `tests/products.mjs`: every starter through the production workers: no engine
  errors, the cut SVG has exactly one outline per part matching its placement, sheet
  nesting with one outline per part per sheet, labels inside their parts, golden
  snapshots (`tests/golden/products/shop_wall.json`), and unit checks of the editor
  definition (starters, module switching, disabled-with-reason settings, coupon).
- `tests/product-interference.mjs`: every part rendered in assembly position and every
  pair intersected (exact 3D, Manifold): all starters, 16 hand-picked shop wall
  cases (both cleats, screws through the back, free standing, screw joinery, ½″ and
  measured stock, no relief and dog-bones, many shelves, drawers and bins, other
  rails on the wall), and in the CI sweep 24 random designs per product.

### Results per module

Checked with CNC side hooks and with beveled boards, with screws through the back,
free standing, screw joinery, dog-bones and ½″ stock: no engine errors and no
intersecting parts for any starter. "Fixed" refers to the table above.

| Module | Result | Notes |
|---|---|---|
| Simple shelves, spray paint display, jar shelves | Pass, fixed 1, 2, 9 | |
| Single and double cube shelf | Pass, fixed 1, 2 | Dividers stand on the bottom, the top drops on, the sides slide on |
| Narrow shelves, sandpaper shelf | Pass, fixed 1, 2, 5 | |
| Single and double door cabinet | Pass, fixed 1, 2, 5, 11 | Hinges listed as hardware; fit to the hinges you buy |
| Sliding door cabinet | Pass, fixed 1, 2, 4, 16 | |
| 3- and 4-drawer cabinet | Pass, fixed 1, 2 | Drawer boxes run wood on wood on the dividers |
| Chisel, hammer, screwdriver racks | Pass, fixed 1, 2, 3, 8 (and 14) | With CNC hooks the side panels are held by the deck and the hook notches: on these short racks their rear edge below the hook is too short for a tab. Beveled board: tilt to hang (6) |
| Clamp rack | Pass, fixed 1, 2, 3, 8 | |
| Plier stand, router bit stand | Pass, fixed 1, 2, 3, 8 | Router stand with a beveled board: tilt to hang (6) |
| Circular saw stand | Pass, fixed 1, 2, 3, 8 | |
| Simple and double drill station | Pass, fixed 1, 2, 3 | Known issue: with CNC hooks the gussets are not tabbed to the back (too little rear edge below the hook); the back is held by the cradle's tab and its screws, so turning off joint screws is refused (`BACK_HELD`). Beveled board: tilt to hang (6) |
| Single and double shelf drill stand | Pass, fixed 1, 2 | |
| Closed lid box | Pass, fixed 1, 2, 17 | Lid hinges listed as hardware |
| Screw box, shallow storage box | Pass, fixed 1, 2 | Beveled board: tilt to hang (6) |
| Glove box | Pass, fixed 1, 2 | |
| Hook panel | Pass, fixed 3, 15 | Known issue: each hook is held by one glued tab; the web beside it is too narrow for a screw. Hooks carry their load as cantilevers, so glue them well or add screws from behind |
| Material storage stand | Pass, fixed 1, 2, 3 | |
| Paper towel holder | Pass, fixed 3, 12 | |
| Wrench holder | Pass, fixed 3 | |

### Fit test coupon

The Export view of a shop wall design has a **Fit test coupon** card. It builds the
coupon with the design's own stock, clearances, tab setback, cutter, relief and
bevel: a slot plate and a tab plate (one tab with its screws), and a short CNC hook
(or a beveled hanger) with a short wall rail. It goes through the same engine checks
and sheet nesting as a module and downloads as SVG and DXF per stock. Cut it first:
the tab should slide in by hand and sit flush, and the hook should drop over the
rail and sit flat against it. Adjust the fit clearance, cutter or bevel and cut again
before cutting the module. The coupon is also the last starter in the module list,
so it can be inspected in 3D.

## Not covered

No load rating, racking or wall-anchoring analysis, no stud finding, no grain
direction or edge banding, and no CAM verification of the exported contours. Hinges
are counted, not modelled. The bevels of the hanger and wall rail are cut on a saw
after the blanks are cut.
