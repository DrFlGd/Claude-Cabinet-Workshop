# Modular workbench

The **Modular workbench** cabinet type (engine frontend `workbench`,
`public/engine/v5/src/modular_organization/data/scad/workbench.scad`) is a rolling
base frame on a square grid of cells, simple cabinet modules that drop onto whole
cells and stack (doors, drawers, drawers over a door, open, or open behind a framed face),
and a puzzle-jointed worksurface with a dog-hole grid.

It is modelled on reference plans the owner of this project bought: three base
frames (small, medium, large), one example module (a "simple cabinet"), the
matching worksurfaces, a set of five cut plywood handles and a rendering of how
modules sit on the frames. **The plans are not part of this repository** and no
outline was traced from them. The dimensions below were measured from the plans and
every part is generated from parameters, so the defaults reproduce the reference
and stay consistent when sizes change. This page is the specification the engine
implements.

## How the reference was measured

- The plans are metric DXF cut files: every outline is a closed polyline or circle
  on one layer, one file per sheet. Lengths were read from the polyline vertices
  (bounding boxes, edge runs, notch and finger positions) and circle centres.
- Cut depths come from the plans' toolpath specification, which assigns each
  outline colour an operation (through cut, pocket depth, drilling depth).
- Imperial versions of the plans keep the same metric grid and use thicker stock
  (for example a 15.0 in module bottom instead of 382 mm), so the type has one
  metric grid and the imperial starter only changes the stock thicknesses.
- The rendering of a frame with modules shows how modules occupy cells (single
  cells and two-cell modules), and that casters sit under the frame corners.
- A photo grid of module configurations from the same reference set shows stacks of
  two to eight drawers, a drawer above a door, stacked half-height modules and open
  cubes behind face panels with large rounded cut-outs. No cut files came with these
  configurations, so the drawer and face-panel construction below is the engine's own
  (see "Drawer modules").

## Derived dimensions (defaults)

### Grid and base frame

| Quantity | Reference | Parameter |
|---|---|---|
| Cell pitch | 400 mm | `cell_size` |
| Grids | small 2 × 2, medium 3 × 2, large 4 × 2 cells | `frame_size` (custom: 1–5 × 1–3) |
| Strip stock | 18 mm | `frame_thickness` |
| Strip height | 85 mm (without tabs) | `frame_height` |
| Strip lengths | 800 / 1200 / 1600 = columns × cell; cross strips 800 = rows × cell | derived |
| Strip centre lines | 60 mm inside every cell edge (60, 340, 460, 740 …) | `frame_rail_inset` |
| Cross strips | only under the two end columns of the medium and large frames | `frame_cross_members` (`ends`, `every_column`) |
| Half-lap slots | 18 mm wide (zero clearance), half the strip height deep; long strips slotted from the top, cross strips from the bottom | `joint_fit_clearance` |
| Registration tabs | 50 × 13 mm on the top edge at every cell centre (200, 600 …) | `registration_tab_length`, `registration_tab_height` |
| Strip end taper | 18.67 mm inset at the floor, reaching full length 8 mm below the top, 3 mm corner radius | `frame_foot_inset` |
| Casters | not in the cut files; the rendering shows them under the outer strip crossings | `caster_height` (75), `caster_plate_size` (60) |

A full set is `2 × rows` long strips and `2 × cross columns` cross strips. Slots
sit at every crossing; dogbone relief (cutter radius) is cut in the slot corners
and at the base of every tab.

### Simple cabinet module (one cell)

| Part | Reference | Rule in the engine |
|---|---|---|
| Sides | 730 × 382 mm, 18 mm | module height × (cells deep × cell − door thickness) |
| Back | 730 × 390 mm | inside width + 2 × finger length; fingers 13 mm long into 14 mm deep housings |
| Bottom | 382 × 390 mm | same depth as the sides, same width as the back |
| Top rails | front 75 × 390, back 93 × 390 mm (75 + the back's thickness) | `top_rail_width` |
| Door | 725 × 395 mm (2.5 mm reveal all round) | (module width ÷ doors − gap) × (height − gap); `door_gap` 5 |
| Shelf | 364 × 339 mm, 12 mm | inside width × (depth − setback 20 − rear clearance 5) |
| Module footprint | 400 × 400 mm = one cell; carcass 382 deep + 18 door | derived |

- **Side housings** (14 mm deep pockets on the inside face): three for the back
  panel fingers along the rear edge (each 730 / 7 = 104.29 mm long, every other
  seventh of the height), two for the bottom fingers along the bottom edge (80 mm
  long, starting 62 and 222 mm from the front), and two 25 mm housings in the top
  edge for each rail's fingers. Finger counts follow the height and depth: the back
  has `2n + 1` fields with `n = round((H / 105 − 1) / 2)`, the bottom and rails
  centre as many 80 / 50 mm fingers as fit with 80 / 100 mm gaps and 40 mm margins.
- **Back and rails into the back**: the bottom's rear fingers (80 mm) and the back
  rail's rear fingers (50 mm) pass through 18 mm deep notches in the back.
- **Registration pockets**: four 51 × 19 mm pockets (tab + 0.5 mm all round),
  14 mm deep with dogbones, on the underside of each bottom where the frame tabs of
  its cells land (60 / 340 mm across, centred 200 mm from the cell edge).
- **Shelf pins**: 5 mm holes 10 mm deep at 50 mm pitch from 175 mm above the
  bottom (193 mm on the side) up to 200 mm below the top, in rows 90 mm from the
  front and 50 mm in front of the back (68 mm from the back edge of the side).
- **Hinge cups**: 35 mm, 12 mm deep, centres 21 mm from the hinge edge and
  87.5 mm from the door ends; two full-overlay hinges per door (three above 1 m,
  four above 1.5 m).
- **Hand slots**: 25 × 100 mm slots in the top rails, centred on the dog-hole rows
  (50 mm from the cell edge) and spanning 50–150 and 250–350 mm of each cell.
- **Handle holes**: 4.5 mm at 140 mm centres, 72.5 mm below the door top, centre
  117.5 mm from the latch edge.
- The plans' 1.5 mm screw-marking dimples and their drilling jig are not modelled.

### Worksurface

| Quantity | Reference | Parameter |
|---|---|---|
| Stock | 18 mm | `worksurface_thickness` |
| Overhang | 50 mm past the frame on every side | `worksurface_overhang` |
| Outer corners | 15 mm radius | `worksurface_corner_radius` |
| Panels | small: 2 panels 900 × 465; medium: a 465 × 900 end panel + two 865 × 465; large: end panels 465 × 900 at both ends and 830 × 465 pairs between | panel rule below |
| Seams | on cell boundaries, joined by dovetail puzzle tabs 30 mm deep across the seam at 180 mm pitch with 15° flanks | `puzzle_depth`, `puzzle_pitch`, `puzzle_angle`, `puzzle_clearance` |
| Dog holes | 16 mm on a 100 mm grid starting 50 mm from each cell edge | `dog_hole_diameter`, `dog_hole_pitch`, `worksurface_dog_holes` |

Panel rule: on two-row grids with three or more columns the first column is one
full-depth panel; the remaining columns pair up row by row, and an odd last column
becomes a second full-depth end panel (this gives the reference medium and large
layouts). Every other grid pairs columns row by row. Seam segments stop half a
puzzle depth short of a crossing seam, so T-junctions are straight; the joint band
along each segment is shared between the two panels (tabs to the lower panel, the
spaces between them to the higher one), with inside corners rounded to the cutter.

### Handles

Five pull profiles cut from 18 mm stock, all screwed on at 140 mm centres:
square 162 × 45, rounded 162 × 45, chamfered 184 × 42, straight bar 202 × 45 and
traditional 210 × 49 mm (`handle_style`). The engine draws its own parametric
profiles at those sizes (finger recess and two screw lugs); the plans' exact
curves are not reproduced. The plans' drilling block and hole jig are not modelled.

### Drawer modules (engine design, matching the photo configurations)

The carcass is the simple cabinet above; only its front and interior change.

| Contents | Front | Interior |
|---|---|---|
| `door` | one door per cell of width (reference) | shelves on pins |
| `drawers` | `n` equal drawer fronts over the full height | `n` drawer boxes on side-mount slides, no shelf pins |
| `drawer_door` | `n` drawer fronts of `combo_drawer_height` (150) above one door (two on wider modules) | drawers at the top; shelf pins only below them |
| `open` | none (reference) | shelves on pins |
| `framed` | a face panel the size of a door with a rounded opening (`face_opening_border` 40, `face_opening_radius` 60) | shelves on pins |

- **Fronts.** Drawer fronts are full overlay like the doors: the module width less
  `door_gap`, the drawer's share of the height less `door_gap`, so drawer and door
  reveals line up. The pull sits in the middle of the front, `handle_top_offset` below
  its top or half way down on low fronts, on the same 140 mm hole centres.
- **Boxes.** Sides, front and back from `drawer_box_thickness` (12, the reference's
  second sheet), the bottom from `drawer_bottom_thickness` (12). Box width = inside
  width − 2 × `metal_slide_clearance_per_side` (12.7): 338.6 mm in a one-cell module.
  Box depth = slide length. Box height = the drawer's share of the opening between the
  bottom and the top rails, less `drawer_vertical_clearance` (20, half above and half
  below): four drawers in a 730 mm module give boxes of 144.5, 162.5, 162.5 and
  144.5 mm.
- **Box joints.** The corners are through finger joints with an odd number of
  equal fingers about `drawer_finger_pitch` (35) high, the sides taking the top and
  bottom fingers, with dogbones in every notch. The bottom has 60 mm tongues
  (`drawer_bottom_tongue` 5 long) on all four edges, centred with 60 mm gaps and
  30 mm margins, in blind pockets `drawer_bottom_pocket_depth` (6) deep milled into
  the inside faces `drawer_bottom_inset` (8) above the lower edge. The pockets have
  dogbones at their corners and the tongues T-bone reliefs at their roots, from the
  shared tab-in-pocket helpers (`tab_pocket.scad`).
- **Slides.** Side-mount full-extension slides, the same parameters and generic hole
  arrays as the equipment stand (`metal_slide_cabinet_holes_x` /
  `metal_slide_drawer_holes_x` = 37, 133, 229, 325 mm from the slide front, holes past
  the slide end left out). `metal_slide_length` 0 picks the longest of 250 … 700 mm
  in 50 mm steps that fits between the module front and the back less
  `drawer_rear_clearance` (5): 350 mm in a one-cell-deep module. Cabinet holes are
  8 mm pilots in the module sides at the box's mid-height; drawer holes go through the
  box sides. Both are in the `pocket_slide_holes` file.
- **Reports.** Each drawer reports `DIM|DRAWER` outside, inside-clear and opening
  sizes (the app's drawer-fit table reads them), `DIM|DRAWER_FACE` and `DIM|SLIDE`;
  the hardware list counts slide pairs by length.

### Stacking keys

A module standing on another is located by loose keys instead of being only screwed
down. A key is a block of frame stock the size of a frame tab and twice its height
(50 × 26 × 18 mm). It stands in a pocket of the registration-pocket size
(51 × 19 mm, `registration_pocket_depth` 14 deep, dogbones) milled into a top rail of
the module below, and in one of the four registration pockets that every cell of the
upper module's bottom already has for the frame. A key goes wherever one of those four
sites lies wholly inside a rail of the module below, 3 mm clear of its edges and hand
slots. On a module that faces front or back the sites are the two along the rails; on
a sideways module they are the two across the cell, so a one-cell module stacked on a
one-cell module always gets two keys. A stacked module with fewer than two keys
reports `STACK_KEYS` and should be screwed down; `include_stack_keys` turns the keys
off (and back to the `STACK_FASTENING` warning).

## Layout rules (beyond the reference)

- `modules` lists one row per module: `[column, row, cells wide, cells deep,
  height, contents door|open|drawers|drawer_door|framed, shelves, facing
  front|back|left|right, hinge left|right, drawers]`. Rows saved without the drawer
  count read as three drawers. The Layout tab edits it.
- A module turned left or right swaps its width and depth: its face is the cells'
  side.
- Later modules stack on earlier ones: a module rests on the highest module under
  any of its cells and must be supported evenly (`MODULE_SUPPORT`). Stacked
  modules are located by keys (above).
- A module whose doors or drawers would open into another module is an error; an open
  or framed module facing another is a warning (`MODULE_FACING`).
- The worksurface rests on the tallest modules; cells with lower or no modules are
  reported (`WORKSURFACE_SUPPORT`).
- Modules wider than one cell get two doors hinged on the outer edges.

## Decisions where the reference was silent

- Two-cell modules in the rendering are taken as one cabinet spanning both cells
  (not two cabinets); single cells are single modules.
- Back-row modules face the back of the bench in the default layouts.
- Stacking, sideways modules and custom grids are extensions; the reference only
  shows one module height on the three frames.
- Drawer, drawer-and-door and framed modules follow the photo grid's configurations
  but not its construction, which no cut file documents: the fronts copy the
  reference door (full overlay, 5 mm gap), the boxes use metal side-mount slides,
  finger-jointed corners and a captured bottom, and the framed face panel is screwed
  to the carcass front edges.
- Stacked modules are located by loose keys in the existing registration pockets
  rather than by changing the reference carcass (the stackable cabinet type nests
  its bottoms between the rails below instead; that would change the reference
  module's bottom and sides).
- Fit clearances default to zero because the reference cuts are exact (18 mm slots
  for 18 mm strips, a 364 mm shelf in a 364 mm opening); `joint_fit_clearance`,
  `registration_clearance`, `shelf_side_clearance` and `puzzle_clearance` open
  them up for real sheet thickness and machine accuracy.
- Casters are modelled as reference hardware under the outer strip crossings with
  a 75 mm mounting height; check your casters.
- Custom grids with three rows put their panels in pairs per row, so four panels
  meet at one point on interior crossings.

## Checks

The engine reports `CHECK|ERROR` for geometry that cannot be built (grid fit,
support, door and drawer clearance, joint depths, cutter access in the puzzle necks,
dog holes inside seams, hinges and handles that do not fit their fronts, drawer boxes
too low for their slides, slides that do not fit, no room for a door under the
drawers, face-panel borders) and warnings for shelf sag on wide modules, unsupported
worksurface cells, stacked modules with fewer than two keys, wide drawers and parts
larger than the stock sheet. The repository tests check every starter's cut layout against
its part table and nest it on the stock sheet (`tests/golden.mjs`), render every
part on its own and intersect every pair (`tests/engine-interference.mjs`,
hand-picked layouts and a seeded random sweep of module layouts), and run the
schematic and validation for every starter (`tests/v5-integration.cjs`).
