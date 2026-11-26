// Shop wall | Claude Cabinet Workshop product engine | Units: mm
// French-cleat and wall-mounted shop organizers: shelves and cubbies, door and drawer
// cabinets, tool racks, drill stations, boxes and holders, one module per design, after
// the owner's 31 "ShopWall" OpenSCAD modules (inch Customizer, board model, tab/slot
// planner, CNC side hooks and beveled cleats), rebuilt on the workshop's core:
//   - tabs, slots, reliefs and screws: joinery.scad (tab planner), tab_pocket.scad
//     (slot relief, tab shoulder relief, screws in the webs), seam_joinery.scad;
//   - cleats, CNC side hooks and the wall rail: cleat.scad and wall_mount.scad;
//   - cut-layout placement, kerf compensation, PLACE records and the overlap check:
//     placement.scad;
//   - one flat 2D profile per part drives the assembly, cut layout, labels and BOM.
// X left to right, Y from the wall side of the back (0) toward the front, Z up. The
// wall is at Y = -cleat thickness for a French cleat and at Y = 0 otherwise.
// See docs/SHOP_WALL.md for the review of the original modules.

/* [Module] */
// Which organizer to build. Choosing one in the editor loads its starting sizes.
module_type = "simple_shelves"; // [single_cube_shelf, double_cube_shelf, narrow_shelves, sandpaper_shelf, single_door_cabinet, double_door_cabinet, sliding_door_cabinet, three_drawer_cabinet, four_drawer_cabinet, simple_shelves, jar_shelves, spray_paint_display, chisel_rack, clamp_rack, hammer_rack, screwdriver_rack, plier_stand, router_bit_stand, circular_saw_stand, simple_drill_station, double_drill_station, single_shelf_drill_stand, double_shelf_drill_stand, closed_lid_box, screw_box, shallow_storage_box, glove_box, hook_panel, material_storage_stand, paper_towel_holder, wrench_holder, fit_coupon]

/* [Size] */
// Outside width.
width = 508; // [80:0.01:1500]
// Outside depth from the wall side of the back to the front.
depth = 177.8; // [50:0.01:800]
// Outside height of the body (a top lip or pull may rise above it).
height = 152.4; // [60:0.01:1500]

/* [Shelves and drawers] */
// Shelves between the bottom and top of shelf cabinets and door cabinets.
interior_shelves = 1; // [0:1:20]
// Side-by-side bays of a cube shelf.
bay_count = 2; // [1:1:12]
drawer_count = 3; // [1:1:10]
// Open display shelves, counting the bottom one.
display_shelves = 1; // [1:1:12]
// Height of the retaining lip on display shelves and the material stand.
lip_height = 19.05; // [5:0.01:150]
// Compartments above the drill cradle of a drill stand.
upper_shelf_count = 1; // [1:1:8]

/* [Tool openings] */
// Slots or holes in a row.
tool_count = 5; // [1:1:40]
// Slot width or hole diameter.
tool_width = 21.59; // [3:0.01:150]
// Slot length from the front edge. Zero sizes it from the depth.
slot_length = 0; // [0:0.01:600]
// Centre-to-centre spacing. Zero spreads the row across the usable width.
tool_pitch = 0; // [0:0.01:600]
// Rows of router bit holes.
tool_rows = 2; // [1:1:6]
// Added to the router bit shank for the hole diameter.
bit_fit_allowance = 0.635; // [0:0.01:5]
// Screwdriver rack: a staggered second row with one fewer hole.
second_row = true;

/* [Boxes] */
box_columns = 3; // [1:1:10]
box_rows = 2; // [1:1:8]
// Open boxes: front height as a share of the box height.
front_height_fraction = 0.52; // [0.3:0.01:1]
// Glove box slot height. Zero uses 42 % of the height.
aperture_height = 0; // [0:0.01:500]
// Glove box slot length. Zero uses 78 % of the inside width.
aperture_length = 0; // [0:0.01:1500]

/* [Holders] */
hook_count = 5; // [1:1:24]
bracket_count = 2; // [2:1:12]
dowel_diameter = 22.225; // [6:0.01:60]
// Added to the dowel for its holes.
rod_clearance = 0.762; // [0:0.01:5]
wrench_levels = 8; // [1:1:30]
// How much each wrench slot rises from its back end to the front.
wrench_rise = 9.652; // [0:0.01:60]
saw_guard_width = 57.15; // [10:0.01:300]
// Left side of the saw guard slot from the left outside face.
saw_guard_offset = 63.5; // [0:0.01:1000]

/* [Doors, drawers and lids] */
// Gap around doors, drawers, sliding leaves and lids.
fit_gap = 1.5875; // [0.2:0.01:10]

/* [Mount] */
mount = "french_cleat"; // [french_cleat, direct_screws, none]
// CNC side hooks cut the cleat into the side panels; a beveled board is screwed to the back.
cleat_strategy = "cnc_hooks"; // [cnc_hooks, beveled_board]
// Cut the mating wall rail with the module.
include_wall_rail = true;
cleat_height = 63.5; // [25:0.1:200]
bevel_angle = 45; // [25:1:60]
// Gap between the hanger's bevel and the rail's (0: bearing).
cleat_vertical_gap = 0; // [0:0.1:5]
// Rounding of the CNC hook tip.
hook_tip_radius = 2.54; // [0:0.01:10]
// Beveled board: inset of the hanger and spacer from the module's sides.
cleat_end_inset = 6.35; // [0:0.1:100]
// Zero cuts the rail as long as the module (or its hanger).
wall_rail_length = 0; // [0:1:3000]
// Spacing of the other rails on your cleat wall, for the collision check. Zero: one rail.
wall_rail_pitch = 0; // [0:1:1000]
// Stud spacing for the wall screws.
wall_screw_spacing = 406.4; // [50:1:1200]
wall_screw_diameter = 4.83; // [2:0.01:10]

/* [Materials and stock] */
carcass_stock = "3/4_nominal"; // [custom_mm, 1/8_nominal, 1/4_nominal, 3/8_nominal, 1/2_nominal, 5/8_nominal, 3/4_nominal, 1_nominal]
// Measured thickness in custom_mm mode.
material_thickness = 18.00; // [1:0.01:50]
// Stock for the hanger, spacer and wall rail.
cleat_stock = "match_carcass"; // [match_carcass, custom_mm, 1/2_nominal, 5/8_nominal, 3/4_nominal, 1_nominal]
custom_cleat_thickness = 19.05; // [6:0.01:50]

/* [Joinery] */
// Tab and slot (with screws beside the tabs) or butt joints held by screws.
joinery_style = "tab_slot"; // [tab_slot, screw]
// Total added width and length of every slot.
joint_fit_clearance = 0.3; // [0:0.01:2]
// Tabs stop this far short of the outside face of the panel they pass through.
tab_setback = 0.3; // [0:0.01:5]
// Longest tab along a joint (core tab planner).
joint_tab_width = 30; // [8:0.5:200]
// Approximate joint length per tab in adaptive mode.
target_tab_spacing = 150; // [40:1:600]
// Distance from a joint end to its first tab.
joint_tab_edge_margin = 12; // [2:0.5:100]
// Minimum solid wood between slots.
minimum_joint_web = 30; // [5:0.5:200]
tab_count_mode = "adaptive"; // [adaptive, fixed]
// Tabs per joint in fixed mode.
joint_tab_count = 2; // [1:1:8]
max_auto_tab_count = 6; // [1:1:10]
// Screws beside the tabs, through the panel with the slots.
joint_screws = true;
screw_clearance_diameter = 4.0; // [1:0.1:12]
// Pilot into the panel edge, drilled at assembly.
screw_pilot_diameter = 2.5; // [0.5:0.1:10]
screw_pilot_depth = 11.4; // [3:0.1:80]

/* [Machining] */
cnc_tool_diameter = 6.35; // [0.1:0.01:25]
slot_corner_relief = "t_bone"; // [none, dogbone, t_bone]
apply_kerf_compensation = false;
kerf = 0.15; // [0:0.01:10]
circle_segments = 48; // [12:4:96]

/* [Sheets and layout] */
stock_width = 2440; // [100:1:5000]
stock_height = 1220; // [100:1:5000]
layout_gap = 20; // [1:1:200]
include_shared_export_bounding_box = true;
engrave_label_size = 10; // [2:0.5:40]

/* [Output] */
output_mode = "assembly"; // [assembly, flat_3d, bom, cut_layout, engrave_layout]
/* [Hidden] */
// Test hook: render one part (ID) or DOWEL in assembly position.
render_part = "";
// Accepted for compatibility with the shared export worker.
dimension_report = "summary";
validation_report = "summary";
system_contract_report = "summary";
interface_keepout_policy = "enforce";

include <../../engine/v5/src/modular_organization/data/scad/tab_pocket.scad>
include <../../engine/v5/src/modular_organization/data/scad/joinery.scad>
include <../../engine/v5/src/modular_organization/data/scad/seam_joinery.scad>
include <../../engine/v5/src/modular_organization/data/scad/cleat.scad>
include <../../engine/v5/src/modular_organization/data/scad/wall_mount.scad>
include <../../engine/v5/src/modular_organization/data/scad/placement.scad>

$fn = circle_segments;
eps = 0.01;
big = 10000;

// ---------------------------------------------------------------- resolved settings
function stock_mm(stock, measured) =
    stock == "custom_mm" ? measured :
    stock == "1/8_nominal" ? 25.4/8 :
    stock == "1/4_nominal" ? 25.4/4 :
    stock == "3/8_nominal" ? 3*25.4/8 :
    stock == "1/2_nominal" ? 25.4/2 :
    stock == "5/8_nominal" ? 5*25.4/8 :
    stock == "3/4_nominal" ? 3*25.4/4 :
    stock == "1_nominal" ? 25.4 : -1;
t = stock_mm(carcass_stock, material_thickness);
ct = cleat_stock == "match_carcass" ? t : stock_mm(cleat_stock, custom_cleat_thickness);
W = width; D = depth; H = height;
F = D - t;          // depth in front of the back
I = W - 2*t;        // inside width
g = fit_gap;
fit = joint_fit_clearance;
tool = cnc_tool_diameter;
relief_on = slot_corner_relief != "none" && tool > 0;
MT = module_type;

FAMILY =
    MT == "single_cube_shelf" || MT == "double_cube_shelf" || MT == "narrow_shelves" || MT == "sandpaper_shelf" ? "cubby" :
    MT == "single_door_cabinet" || MT == "double_door_cabinet" || MT == "sliding_door_cabinet" ? "doors" :
    MT == "three_drawer_cabinet" || MT == "four_drawer_cabinet" ? "drawers" :
    MT == "simple_shelves" || MT == "jar_shelves" || MT == "spray_paint_display" ? "display" :
    MT == "chisel_rack" || MT == "clamp_rack" || MT == "hammer_rack" || MT == "screwdriver_rack" || MT == "circular_saw_stand" ? "rack" :
    MT == "plier_stand" || MT == "router_bit_stand" ? "stand" :
    MT == "simple_drill_station" || MT == "double_drill_station" ? "drill_simple" :
    MT == "single_shelf_drill_stand" || MT == "double_shelf_drill_stand" ? "drill_cabinet" :
    MT == "closed_lid_box" || MT == "screw_box" || MT == "shallow_storage_box" ? "box" :
    MT == "glove_box" ? "glove" : MT == "hook_panel" ? "hooks" : MT == "material_storage_stand" ? "brackets" :
    MT == "paper_towel_holder" ? "towel" : MT == "wrench_holder" ? "wrench" : MT == "fit_coupon" ? "coupon" : "unknown";
coupon = FAMILY == "coupon";
cube = MT == "single_cube_shelf" || MT == "double_cube_shelf";
// Hook panels have no side panels to cut hooks into; they always hang from a beveled board.
has_hangers = FAMILY != "hooks";
cleat_mount = mount == "french_cleat" || coupon;
cnc = cleat_mount && cleat_strategy == "cnc_hooks" && has_hangers;
beveled = cleat_mount && !cnc;
ch = cleat_height;
rise = wm_rise(ct, bevel_angle);
lift = wm_hang_lift(ct, bevel_angle, cleat_vertical_gap);
wall_y = cleat_mount ? -ct : 0;

// Tool rows: centre of opening i of n across a usable width u.
function tool_center(i, n, u) = tool_pitch == 0 ? u*(i + 0.5)/n : u/2 + (i - (n - 1)/2)*tool_pitch;
min_web_open = max(t/3, 3);

// ---------------------------------------------------------------- parts
// [0 id, 1 kind, 2 plane, 3 origin, 4 outline (local u,v), 5 thickness, 6 material,
//  7 local cuts, 8 role, 9 assembly step, 10 motion [axis, sign] of that step,
//  11 base profile of a rib in front of the back (u from the back's front face)]
// plane XY: u=X v=Y, thickness +Z.  XZ: u=X v=Z, thickness toward -Y from origin.y + th
// (laid front face up).  YZ: u=Y v=Z, thickness +X.
// Local cuts: ["circle", u, v, d], ["oblong", u, v, w, l, along(0 u | 1 v)],
// ["front", u, v_edge, w, l] (slot open at the edge v_edge, rounded end),
// ["poly", pts], ["pocket", u0, v0, w, h, open[l,r,b,t]], ["relief", centres].
function PT(id, kind, plane, o, pts, th=t, mat="CARCASS", cuts=[], role="", step=0, move=[-1, 0], prof=undef) =
    [id, kind, plane, o, pts, th, mat, cuts, role, step, move, is_undef(prof) ? pts : prof];
function rect(w, h) = [[0, 0], [w, 0], [w, h], [0, h]];
// Rectangle w wide from v0 to v1 (a rib standing on a panel), its rear edge last.
function vrect(w, v0, v1) = [[0, v0], [w, v0], [w, v1], [0, v1]];
function pts_box(pts) = [min([for (p=pts) p[0]]), max([for (p=pts) p[0]]), min([for (p=pts) p[1]]), max([for (p=pts) p[1]])];

// Horizontal panel between the sides, in front of the back.
function HZ(id, kind, z, dep=F, cuts=[], step=2, move=[0, -1]) = PT(id, kind, "XY", [t, t, z], rect(I, dep), t, "CARCASS", cuts, "", step, move);

// Rib: a vertical panel in front of the back (YZ). prof is its outline with u from the
// back's front face (u = 0) and its rear edge closing from [0, rear_top] to [0, 0].
// With CNC side hooks a hanger rib reaches through a notch in the back and hooks over
// the wall rail.
function hooked(role) = cnc && role == "hanger";
notch_z = H - ch - t;                         // ribs pass through the back above this
tip_v = H - ch;                               // hook tip (bearing on the rail's bevel)
rail_z = wm_rail_bottom(H, ch, ct, bevel_angle, cleat_vertical_gap);
function rear_top(prof) = prof[len(prof) - 1][1];
function rear_bottom(prof) = prof[0][1];
function shift_cut(c, du) =
    c[0] == "poly" ? ["poly", [for (p=c[1]) p + [du, 0]]] :
    c[0] == "relief" ? ["relief", [for (p=c[1]) p + [du, 0]]] :
    concat([c[0], c[1] + du], [for (k=[2:len(c)-1]) c[k]]);
function hook_outline(prof) = let(s = t + ct, top = rear_top(prof))
    concat([for (p=prof) [p[0] + s, p[1]]],
           top < H ? [[s, H]] : [],
           wm_hook_points(ct, bevel_angle, tip_v, H, hook_tip_radius),
           [[ct, notch_z], [s, notch_z]]);
function hook_cuts() = concat(
    tool > 0 ? [["relief", wm_hook_relief(ct, bevel_angle, tip_v, tool)]] : [],
    relief_on ? [["relief", wm_corner_relief([t + ct, notch_z], [-1, 0], [0, -1], tool)]] : []);
function RIB(id, kind, x, prof, role="inner", cuts=[], step=2, move=[1, -1]) =
    hooked(role) ? PT(id, kind, "YZ", [x, -ct, 0], hook_outline(prof), t, "CARCASS",
                      concat([for (c=cuts) shift_cut(c, t + ct)], hook_cuts()), role, step, move, prof)
                 : PT(id, kind, "YZ", [x, t, 0], prof, t, "CARCASS", cuts, role, step, move);
// Rib outline in front of the back (u from the back's front face).
function rib_prof(p) = p[11];

// Back: full width and height behind everything; CNC hanger ribs pass through notches.
// Its slots, holes and notches come from the joints and the mount below.
function BACK(step=9) = PT("BACK", "back", "XZ", [0, 0, 0], rect(W, H), t, "CARCASS", [], "", step, [1, 1]);

// Assembly steps: 1 is the first part laid down (static); every later part moves along
// `move` into the parts already placed. The fit check verifies every joint against them.
function side_pair(prof, kind="side", cuts=[], idL="SIDE_L", idR="SIDE_R") = [
    RIB(idL, kind, 0, prof, "hanger", cuts, 1, [-1, 0]),
    RIB(idR, kind, W - t, prof, "hanger", cuts, 3, [0, -1])];

// --- shelves and cubbies, door cabinets, drawer cabinets
n_shelves = FAMILY == "cubby" && !cube || FAMILY == "doors" ? interior_shelves : 0;
n_bays = cube ? bay_count : 1;
sliding = MT == "sliding_door_cabinet";
double_door = MT == "double_door_cabinet";
// Sliding doors: bottom strips half a board high, top strips deep enough to lift a
// leaf out of the bottom channel and still keep it in the top one.
strip_bottom = max(t/2, joint_screws || joinery_style == "screw" ? screw_pilot_depth + 2 : 0);
strip_lift = strip_bottom + 2*g;
strip_top = strip_lift + strip_bottom;
channel = t + 2*g;
track = 3*t + 2*channel;
shelf_depth = FAMILY == "doors" ? (sliding ? F - track - g : F - t - 2*g) : F;
clear_h = (H - 2*t - n_shelves*t)/(n_shelves + 1);     // equal openings
function shelf_z(k) = t + k*clear_h + (k - 1)*t;
bay_w = (I - (n_bays - 1)*t)/n_bays;
function bay_x(k) = t + k*bay_w + (k - 1)*t;           // left face of divider k
leaf = double_door ? (I - 3*g)/2 : I - 2*g;
door_h = H - 2*t - 2*g;
slide_w = (I + t)/2 - g;
slide_h = H - 2*t - strip_lift;
function slide_y(j) = D - track + t + j*(2*t + 2*g) + g;   // leaf j (0 rear, 1 front)
pull_span = min(101.6, 0.62*leaf);
function finger_d(w) = min(25.4, w/6);
drawer_pitch = (H - t)/max(1, drawer_count);
dbh = drawer_pitch - t - g;           // drawer box height
dbw = I - 2*g;
dbd = F - g;
function drawer_z(i) = i*drawer_pitch + t;
function drawer_parts(i) = let(x0 = t + g, y0 = t + g, z = drawer_z(i), s = 20 + 4*i, id = str("DRAWER_", i + 1),
        fd = min(34.29, dbh - t))
    [PT(str(id, "_SIDE_L"), "drawer_side", "YZ", [x0, y0 + t, z + t], rect(dbd - 2*t, dbh - t), t, "CARCASS", [], "", s, [-1, 0]),
     PT(str(id, "_SIDE_R"), "drawer_side", "YZ", [x0 + dbw - t, y0 + t, z + t], rect(dbd - 2*t, dbh - t), t, "CARCASS", [], "", s, [-1, 0]),
     PT(str(id, "_FRONT"), "drawer_front", "XZ", [x0, y0 + dbd - t, z + t], rect(dbw, dbh - t), t, "CARCASS", [["circle", dbw/2, dbh - t, fd]], "", s + 1, [1, -1]),
     PT(str(id, "_BACK"), "drawer_back", "XZ", [x0, y0, z + t], rect(dbw, dbh - t), t, "CARCASS", [], "", s + 2, [1, 1]),
     PT(str(id, "_BOTTOM"), "drawer_bottom", "XY", [x0, y0, z], rect(dbw, dbd), t, "CARCASS", [], "", s + 3, [2, 1])];
function shell_parts() = concat(
    side_pair(rect(F, H)),
    cube ? [PT("BOTTOM", "bottom", "XY", [t, t, 0], rect(I, F), t, "CARCASS", [], "", 0, [-1, 0]),
            PT("TOP", "top", "XY", [t, t, H - t], rect(I, F), t, "CARCASS", [], "", 0, [2, -1])]
         : [HZ("BOTTOM", "bottom", 0), HZ("TOP", "top", H - t)],
    [for (k=[1:1:n_shelves]) HZ(str("SHELF_", k), "shelf", shelf_z(k), shelf_depth)],
    [for (k=[1:1:n_bays - 1]) RIB(str("DIVIDER_", k), "divider", bay_x(k), vrect(F, t, H - t), "inner", [], 0, [2, -1])]);
// Cube shelves stand their dividers on the bottom first: bottom (0) -> dividers and top
// drop on (step 0.5 -> renumbered below) -> sides -> back.
function cube_steps(p) = p[0] == "BOTTOM" ? [1, [-1, 0]] : p[1] == "divider" ? [2, [2, -1]] : p[0] == "TOP" ? [3, [2, -1]] :
    p[0] == "SIDE_L" ? [4, [0, 1]] : p[0] == "SIDE_R" ? [5, [0, -1]] : [p[9], p[10]];
function restep(list, f) = [for (p=list) let(s = f(p)) [for (k=[0:len(p) - 1]) k == 9 ? s[0] : k == 10 ? s[1] : p[k]]];
function door_parts() = sliding ? concat(
        [for (j=[0:2]) let(y = D - track + j*(t + channel)) each [
            PT(str("STRIP_B", j + 1), "guide_strip", "XZ", [t, y, t], rect(I, strip_bottom), t, "CARCASS", [], "", 3, [2, -1]),
            PT(str("STRIP_T", j + 1), "guide_strip", "XZ", [t, y, H - t - strip_top], rect(I, strip_top), t, "CARCASS", [], "", 3, [2, 1])]],
        [for (j=[0:1]) PT(str("SLIDING_DOOR_", j + 1), "sliding_door", "XZ",
            [j == 0 ? t + g : W - t - g - slide_w, slide_y(j), t], rect(slide_w, slide_h), t, "CARCASS",
            [["circle", j == 0 ? 0.17*slide_w : 0.83*slide_w, 0.25*slide_h, finger_d(I)]], "", 30, [-1, 0])])
    : [for (j=[0:double_door ? 1 : 0]) let(x = j == 0 ? t + g : W - t - g - leaf, hx = j == 0 ? leaf - min(33, leaf/3) : min(33, leaf/3),
            fd = finger_d(I), px = x + min(max(hx - pull_span/2, t/3), leaf - pull_span - t/3), pz = t + g + 38.1 + fd/2 + tool + fit + 3) each [
        PT(str("DOOR_", j + 1), "door", "XZ", [x, D - t, t + g], rect(leaf, door_h), t, "CARCASS", [["circle", hx, 38.1, fd]], "", 30, [-1, 0]),
        PT(str("DOOR_", j + 1, "_PULL"), "pull", "XY", [px, D, pz], rect(pull_span, t), t, "CARCASS", [], "", 31, [1, -1])]];

// --- open display shelves
display_lips = MT != "simple_shelves";
disp_step = (H - t)/display_shelves;
function display_prof() = [[0, 0], [F, 0], [F, min(H, t + lip_height + 7.62)], [0.72*D - t, H], [0, H]];
function display_parts() = concat(
    side_pair(display_prof()),
    [for (i=[0:display_shelves - 1]) HZ(str("SHELF_", i + 1), "shelf", i*disp_step)],
    display_lips ? [for (i=[0:display_shelves - 1]) PT(str("LIP_", i + 1), "lip", "XZ", [t, D - t, i*disp_step + t], rect(I, lip_height), t, "CARCASS", [], "", 2.5, [2, -1])] : []);

// --- racks and stands
rack_prof = [[0, 0], [F, H - 1.5*t], [F, H], [0, H]];
function rack_cuts(u) = let(n = tool_count, w = tool_width)
    MT == "chisel_rack" || MT == "clamp_rack" ? [for (i=[0:n-1]) ["front", tool_center(i, n, u), F, w, slot_auto(MT == "chisel_rack" ? 0.72 : 0.72)]] :
    MT == "circular_saw_stand" ? [["front", saw_guard_offset + saw_guard_width/2 - t, F, saw_guard_width, slot_auto(0.85)]] :
    MT == "hammer_rack" ? [for (i=[0:n-1]) ["circle", tool_center(i, n, u), F/2, w]] :
    MT == "screwdriver_rack" ? (second_row && n > 1 ?
        concat([for (i=[0:n-1]) ["circle", tool_center(i, n, u), 0.30*F, w]],
               [for (i=[0:n-2]) ["circle", tool_center(i + 0.5, n, u), 0.70*F, w]]) :
        [for (i=[0:n-1]) ["circle", tool_center(i, n, u), F/2, w]]) :
    MT == "plier_stand" ? [for (i=[0:n-1]) ["oblong", tool_center(i, n, u), F/2, w, slot_auto(0.67), 1]] :
    MT == "router_bit_stand" ? [for (i=[0:n-1]) for (j=[0:tool_rows - 1]) ["circle", tool_center(i, n, u), F*(j + 0.5)/tool_rows, w + bit_fit_allowance]] : [];
function slot_auto(f) = slot_length > 0 ? slot_length : f*F;
function rack_parts() = concat(
    FAMILY == "stand" ? side_pair(rect(F, H)) : side_pair(rack_prof),
    FAMILY == "stand" ? [HZ("BOTTOM", "bottom", 0)] : [],
    [HZ("DECK", MT == "circular_saw_stand" ? "saw_cradle" : "tool_deck", H - t, F, rack_cuts(I))]);

// --- drill stations
drill_l = slot_length > 0 ? slot_length : 0.8*F;
gusset_d = 0.4*F;
function drill_parts() = FAMILY == "drill_simple" ? concat(
        [RIB("GUSSET_L", "gusset", 0, [[0, 0], [gusset_d, H - t], [0, H - t]], "hanger", [], 2, [2, 1]),
         RIB("GUSSET_R", "gusset", W - t, [[0, 0], [gusset_d, H - t], [0, H - t]], "hanger", [], 2, [2, 1])],
        [PT("CRADLE", "drill_cradle", "XY", [0, t, H - t], rect(W, F), t, "CARCASS",
            [for (i=[0:tool_count - 1]) ["front", tool_center(i, tool_count, W), F, tool_width, drill_l]], "", 1, [-1, 0])])
    : concat(side_pair(rect(F, H)),
        [HZ("CRADLE", "drill_cradle", 0, F, [for (i=[0:tool_count - 1]) ["front", tool_center(i, tool_count, I), F, tool_width, drill_l]])],
        [HZ("TOP", "top", H - t)],
        [for (i=[1:1:upper_shelf_count - 1]) HZ(str("SHELF_", i), "shelf", (H - t)*i/upper_shelf_count)]);

// --- boxes
box_lid = MT == "closed_lid_box";
box_div = MT != "shallow_storage_box";
box_top = box_lid ? H - t : H;
box_fh = box_lid ? box_top : max(2*t, box_top*front_height_fraction);
box_cy = F - t;
box_cell = (I - (box_columns - 1)*t)/box_columns;
box_dh = box_fh - 1.3*t;
function box_prof() = box_lid ? rect(F, box_top) : [[0, 0], [F, 0], [F, box_fh], [0.54*D - t, box_top], [0, box_top]];
function box_xdiv_y(j) = t + j*(box_cy + t)/box_rows - t;
lid_pull = min(101.6, 0.62*W);
function box_parts() = concat(
    [PT("BOTTOM", "bottom", "XY", [t, t, 0], rect(I, F), t, "CARCASS", [], "", 1, [-1, 0])],
    restep(side_pair(box_prof(), "box_side"), function(p) p[0] == "SIDE_L" ? [4, [0, 1]] : [5, [0, -1]]),
    [PT("FRONT", "box_front", "XZ", [t, D - t, t], rect(I, box_fh - t), t, "CARCASS", [], "", 3, [2, -1])],
    box_div ? concat(
        [for (i=[1:1:box_columns - 1]) RIB(str("LONG_DIV_", i), "long_divider", i*(box_cell + t), vrect(box_cy, t, t + box_dh), "inner", [], 2, [2, -1])],
        [for (i=[0:box_columns - 1]) for (j=[1:1:box_rows - 1])
            PT(str("CROSS_DIV_", i + 1, "_", j), "cross_divider", "XZ", [t + i*(box_cell + t), box_xdiv_y(j), t], rect(box_cell, box_dh), t, "CARCASS", [], "", 2, [2, -1])]) : [],
    box_lid ? [PT("LID", "lid", "XY", [0, t + g, H - t], rect(W, F - g), t, "CARCASS", [], "", 30, [-1, 0]),
               PT("LID_PULL", "pull", "XZ", [(W - lid_pull)/2, D - 1.5*t, H], rect(lid_pull, t), t, "CARCASS", [], "", 31, [2, -1])] : []);
// Lid box: the lid rests on the sides and front; the sides stop one board below the top.
function box_shift() = box_lid;

// --- glove box, hook panel, material stand, towel holder, wrench holder
glove_w = aperture_height > 0 ? aperture_height : 0.42*H;
glove_l = aperture_length > 0 ? aperture_length : 0.78*I;
function glove_parts() = concat(
    [PT("BOTTOM", "bottom", "XY", [t, t, 0], rect(I, F), t, "CARCASS", [], "", 1, [-1, 0])],
    restep(side_pair(rect(F, H)), function(p) p[0] == "SIDE_L" ? [3, [0, 1]] : [4, [0, -1]]),
    [PT("FRONT", "glove_front", "XZ", [t, D - t, t], rect(I, H - t), t, "CARCASS", [["oblong", I/2, (H - t)/2, glove_w, glove_l, 0]], "", 2, [2, -1])]);
hook_prof = [[0, 0], [F, 0.28*H], [F, 0.64*H], [F - t/2, 0.64*H], [F - t, 0.37*H], [0, 0.50*H]];
function hook_parts() = [for (i=[0:hook_count - 1]) RIB(str("HOOK_", i + 1), "hook", W*(i + 0.5)/hook_count - t/2, hook_prof, "inner", [], 2, [1, -1])];
function bracket_x(i) = (W - t)*i/(bracket_count - 1);
function bracket_parts() = concat(
    [for (i=[0:bracket_count - 1]) RIB(str("BRACKET_", i + 1), "bracket", bracket_x(i), [[0, 0], [F, H - t], [0, H - t]], "hanger", [], 2, [2, 1])],
    [PT("DECK", "deck", "XY", [0, t, H - t], rect(W, F), t, "CARCASS", [], "", 1, [-1, 0]),
     PT("LIP", "lip", "XZ", [0, D - t, H], rect(W, lip_height), t, "CARCASS", [], "", 3, [2, -1])]);
towel_y = F - max(t, dowel_diameter);   // dowel centre, from the back's front face
function towel_prof() = let(z = H/2, d = dowel_diameter) [[0, 0], [F, z - d], [F, z + d], [0, H]];
function towel_parts() = [for (s=[0:1]) RIB(s == 0 ? "CHEEK_L" : "CHEEK_R", "dowel_cheek", s == 0 ? 0 : W - t, towel_prof(), "hanger",
    [["circle", towel_y, H/2, dowel_diameter + rod_clearance]], 1, [-1, 0])];
wrench_l = slot_length > 0 ? slot_length : 0.70*F;
wrench_step = (H - 2*t - wrench_rise)/wrench_levels;
function wrench_slots() = [for (i=[0:wrench_levels - 1]) let(z = t + (i + 0.5)*wrench_step)
    ["poly", [[F - wrench_l, z], [F + 1, z + wrench_rise], [F + 1, z + wrench_rise + tool_width], [F - wrench_l, z + tool_width]]]];
function wrench_parts() = [for (s=[0:1]) RIB(s == 0 ? "CHEEK_L" : "CHEEK_R", "wrench_cheek", s == 0 ? 0 : W - t, rect(F, H), "hanger", wrench_slots(), 1, [-1, 0])];

// --- fit test coupon: one tab in its slot (with screws), and a short hook or hanger on
// a short rail, cut from the same stock with the same clearances, cutter and bevel.
cp_w = min(joint_tab_width, 60);
cp_plate = max(cp_w + 4*sj_screw_gap(screw_clearance_diameter, tool) , 100);
cp_top = 2*ch + 20;
cp_rail = wm_rail_bottom(cp_top, ch, ct, bevel_angle, cleat_vertical_gap);
cp_x = cp_plate + 40;
function coupon_hook_outline() = concat([[ct, cp_rail], [ct + 60, cp_rail], [ct + 60, cp_top]],
    wm_hook_points(ct, bevel_angle, cp_top - ch, cp_top, hook_tip_radius));
function coupon_parts() = concat(
    [PT("COUPON_SLOT", "coupon_slot", "XY", [0, 0, 0], rect(cp_plate, t + 60), t, "CARCASS", [], "", 1, [-1, 0]),
     PT("COUPON_TAB", "coupon_tab", "XZ", [0, 30, t], rect(cp_plate, 50), t, "CARCASS", [], "", 2, [2, -1])],
    cleat_strategy == "cnc_hooks" ?
        [PT("COUPON_HOOK", "coupon_hook", "YZ", [cp_x, -ct, 0], coupon_hook_outline(), t, "CARCASS",
            tool > 0 ? [["relief", wm_hook_relief(ct, bevel_angle, cp_top - ch, tool)]] : [], "", 40, [-1, 0])] :
        [PT("COUPON_HANGER", "hanger", "XZ", [cp_x - 30, -ct, cp_top - ch], rect(t + 60, ch), ct, "CLEAT", [], "", 40, [-1, 0])],
    [PT("COUPON_RAIL", "wall_rail", "XZ", [cp_x - 30, -ct, cp_rail], rect(t + 60, ch), ct, "CLEAT", [], "", 41, [-1, 0])]);

BODY = FAMILY == "cubby" ? (cube ? restep(shell_parts(), function(p) cube_steps(p)) : shell_parts()) :
       FAMILY == "doors" ? concat(shell_parts(), door_parts()) :
       FAMILY == "drawers" ? concat(shell_parts(), [for (i=[1:1:drawer_count - 1]) HZ(str("DRAWER_DIVIDER_", i), "drawer_divider", i*drawer_pitch)],
                                    [for (i=[0:drawer_count - 1]) each drawer_parts(i)]) :
       FAMILY == "display" ? display_parts() :
       FAMILY == "rack" || FAMILY == "stand" ? rack_parts() :
       FAMILY == "drill_simple" || FAMILY == "drill_cabinet" ? drill_parts() :
       FAMILY == "box" ? box_parts() :
       FAMILY == "glove" ? glove_parts() :
       FAMILY == "hooks" ? hook_parts() :
       FAMILY == "brackets" ? bracket_parts() :
       FAMILY == "towel" ? towel_parts() :
       FAMILY == "wrench" ? wrench_parts() :
       FAMILY == "coupon" ? coupon_parts() : [];
// The back goes on last (the front assembly is pushed onto it), except on hook panels,
// whose hooks are pushed onto the back.
RIBS = [for (p=BODY) if (p[2] == "YZ" && p[1] != "drawer_side") p];

// --- mount parts behind the back
hanger_len = W - 2*cleat_end_inset;
rail_len = wall_rail_length > 0 ? wall_rail_length : cnc ? W : hanger_len;
spacer_pad = let(drop = rail_z - lift - 3) drop >= 12 ? min(t, drop) : min(t, rail_z/2);
straight_drop = rail_z - lift - 3 >= 12;
MOUNT_PARTS = coupon ? [] : concat(
    beveled ? concat(
        [PT("HANGER", "hanger", "XZ", [cleat_end_inset, -ct, H - ch], rect(hanger_len, ch), ct, "CLEAT", [], "", 50, [1, -1])],
        spacer_pad >= 6 ? [PT("SPACER", "spacer", "XZ", [cleat_end_inset, -ct, 0], rect(hanger_len, spacer_pad), ct, "CLEAT", [], "", 51, [1, -1])] : []) : [],
    cleat_mount && include_wall_rail ?
        [PT("WALL_RAIL", "wall_rail", "XZ", [(W - rail_len)/2, -ct, rail_z], rect(rail_len, ch), ct, "CLEAT",
            [for (u=wm_screw_stations(rail_len, wall_screw_spacing, 2*wall_screw_diameter + 10)) ["circle", u, (ch - rise)/2, wall_screw_diameter]], "", 60, [-1, 0])] : []);

// Screws through the back (hanger, spacer, direct wall screws), kept off the rib bands.
rib_bands = [for (p=RIBS) [p[3][0] - 6 - screw_clearance_diameter, p[3][0] + t + 6 + screw_clearance_diameter]];
function in_band(x) = len([for (b=rib_bands) if (x > b[0] && x < b[1]) 1]) > 0;
function free_x(x) = !in_band(x) ? x :
    let(b = [for (q=rib_bands) if (x > q[0] && x < q[1]) q][0],
        lo = b[0] - 0.01, hi = b[1] + 0.01,
        c = [for (y=abs(x - lo) <= abs(x - hi) ? [lo, hi] : [hi, lo]) if (!in_band(y) && y > 10 && y < W - 10) y])
    len(c) ? c[0] : x;
function back_screw_xs(L, x0, d) = [for (u=wm_screw_stations(L, min(wall_screw_spacing, max(40, 0.6*L)), 2*d + 10)) free_x(x0 + u)];
BACK_SCREWS = coupon ? [] : concat(
    beveled ? [for (x=back_screw_xs(hanger_len, cleat_end_inset, screw_clearance_diameter)) [x, H - (ch - rise)/2, screw_clearance_diameter, "hanger"]] : [],
    beveled && spacer_pad >= 6 ? [for (x=back_screw_xs(hanger_len, cleat_end_inset, screw_clearance_diameter)) [x, spacer_pad/2, min(screw_clearance_diameter, spacer_pad/2), "spacer"]] : [],
    mount == "direct_screws" ? [for (z=[0.2*H, 0.8*H]) for (x=back_screw_xs(W, 0, wall_screw_diameter)) [x, z, wall_screw_diameter, "wall"]] : []);
function back_part() = let(b = BACK(FAMILY == "hooks" ? 1 : 9))
    [for (k=[0:len(b) - 1]) k == 7 ? concat(
        [for (p=RIBS) if (hooked(p[8])) let(x0 = p[3][0] - fit/2, w = t + fit, v0 = notch_z - fit/2)
            ["pocket", x0, v0, w, H - v0 + 1, [x0 < eps, x0 + w > W - eps, false, true]]],
        [for (s=BACK_SCREWS) ["circle", s[0], s[1], s[2]]]) : b[k]];

PARTS = coupon ? concat(BODY, MOUNT_PARTS) : concat(BODY, [back_part()], MOUNT_PARTS);
function pidx(id) = let(m = [for (k=[0:len(PARTS)-1]) if (PARTS[k][0] == id) k]) len(m) ? m[0] : -1;
function part(id) = PARTS[pidx(id)];

// World bounding box of a part's base outline: [[x0,x1],[y0,y1],[z0,z1]].
function world_box(p) = let(o = p[3], b = pts_box(p[4]), th = p[5])
    p[2] == "XY" ? [[o[0] + b[0], o[0] + b[1]], [o[1] + b[2], o[1] + b[3]], [o[2], o[2] + th]] :
    p[2] == "XZ" ? [[o[0] + b[0], o[0] + b[1]], [o[1], o[1] + th], [o[2] + b[2], o[2] + b[3]]] :
                   [[o[0], o[0] + th], [o[1] + b[0], o[1] + b[1]], [o[2] + b[2], o[2] + b[3]]];
// The same for the body of a part in front of the back (a hooked side panel without its hook).
function body_box(p) = hooked(p[8]) ? let(b = pts_box(p[11])) [[p[3][0], p[3][0] + p[5]], [t + b[0], t + b[1]], [b[2], b[3]]] : world_box(p);
// World -> local (u, v) of a point on part p.
function to_local(p, q) = let(o = p[3])
    p[2] == "XY" ? [q[0] - o[0], q[1] - o[1]] : p[2] == "XZ" ? [q[0] - o[0], q[2] - o[2]] : [q[1] - o[1], q[2] - o[2]];
// Local axis (0 u, 1 v) of a world axis on part p, or -1 across the thickness.
function local_axis(p, a) = p[2] == "XY" ? (a == 0 ? 0 : a == 1 ? 1 : -1) : p[2] == "XZ" ? (a == 0 ? 0 : a == 2 ? 1 : -1) : (a == 1 ? 0 : a == 2 ? 1 : -1);

// ---------------------------------------------------------------- joints
// [0 host, 1 member, 2 along axis, 3 s0, 4 L, 5 cross axis, 6 c0, 7 c1, 8 normal axis,
//  9 face, 10 dir, 11 segments (along, from s0), 12 tabs override ([] = planner)]
// The member's edge touches the host's face at `face`; dir = +1 when the host extends
// from the face toward +normal. Tabs are cut on the member, slots in the host.
function J(host, member, a, s0, L, c, c0, c1, n, f, dir, segs, tabs=[]) = [host, member, a, s0, L, c, c0, c1, n, f, dir, segs, tabs];
// Rib (YZ) into the back along its rear edge.
// The seam runs only where the rib has at least `rib_web` of wood in front of its rear
// edge, so a sloped or pointed rib keeps its tabs and shoulder reliefs off the thin tip.
rib_web = max(t, 2*tool);
function rear_depth(prof, v) = let(c = sj_chord(prof, v, 1)) len(c) && c[0] < 0.01 ? c[1] : 0;
function rear_from(prof, v, end, dv) = (dv > 0 ? v >= end : v <= end) ? end :
    rear_depth(prof, v) >= rib_web ? v : rear_from(prof, v + dv, end, dv);
function rib_back_joint(p) = let(x = p[3][0], prof = rib_prof(p), b0 = rear_bottom(prof),
        t0 = hooked(p[8]) ? notch_z - fit/2 - max(tool, t/2) : rear_top(prof),
        b = rear_from(prof, b0 + 0.01, t0, 0.5), top = rear_from(prof, t0 - 0.01, b, -0.5))
    J("BACK", p[0], 2, b, top - b, 0, x, x + t, 1, t, -1, top > b ? [[0, top - b]] : []);
// Horizontal panel (XY) along its rear edge into the back, clear of the ribs' seams and
// the notches the hooked ribs pass through.
function hz_back_joint(h) = let(x0 = h[3][0], w = pts_box(h[4])[1], z = h[3][2],
        keep = [for (r=RIBS) let(a = r[3][0] - x0) [a - fit/2 - tool, a + t + fit/2 + tool]])
    J("BACK", h[0], 0, x0, w, 2, z, z + t, 1, t, -1, sj_cut_all([[0, w]], keep));
function back_horizontals() = [for (p=BODY) if (p[2] == "XY" && abs(p[3][1] - t) < eps && p[1] != "drawer_bottom" && p[1] != "pull") p];
// A joint has room for at least one tab (or screw with screw joinery).
function has_room(j) = joinery_style == "tab_slot" ? len(sj_tabs(j[11], tool, fit)) > 0 : len(sj_screw_only(j[11], tool)) > 0;
// Horizontal panel (XY) into a rib: seam along Y on the rib's face, where the rib's
// outline covers the panel's thickness band.
function hz_rib_joint(h, r, left) = let(z = h[3][2], y0 = h[3][1], dep = pts_box(h[4])[3],
        prof = rib_prof(r), band = sj_band(prof, z - (hooked(r[8]) ? 0 : 0), z + t),
        lo = len(band) ? max(0, band[0] - (y0 - t)) : 0, hi = len(band) ? min(dep, band[1] - (y0 - t)) : 0)
    J(r[0], h[0], 1, y0, dep, 2, z, z + t, 0, left ? r[3][0] + t : r[3][0], left ? -1 : 1, hi > lo ? [[lo, hi]] : []);
// Panel standing on a horizontal panel (its bottom edge on the host's top face) or
// hanging from one (its top edge on the host's underside).
function on_joint(host, m, below) = let(hb = world_box(part(host)), mb = world_box(m),
        a = m[2] == "XZ" ? 0 : 1, c = 1 - a, s0 = mb[a][0], L = mb[a][1] - mb[a][0])
    J(host, m[0], a, s0, L, c, mb[c][0], mb[c][1], 2, below ? hb[2][1] : hb[2][0], below ? -1 : 1, [[0, L]]);
// Panel end (XZ part's X edge) into a rib's face.
function end_joint(r, m, left, z0, z1) =
    J(r[0], m[0], 2, z0, z1 - z0, 1, m[3][1], m[3][1] + m[5], 0, left ? r[3][0] + t : r[3][0], left ? -1 : 1, [[0, z1 - z0]]);
function horizontals() = [for (p=BODY) if (p[2] == "XY" && (p[3][0] == t) && p[1] != "drawer_bottom" && p[1] != "pull") p];
function side_joints(L, R) = concat(
    [for (h=horizontals()) hz_rib_joint(h, L, true)],
    [for (h=horizontals()) hz_rib_joint(h, R, false)]);

JOINTS = coupon ? [J("COUPON_SLOT", "COUPON_TAB", 0, 0, cp_plate, 1, 30, 30 + t, 2, t, -1, [[0, cp_plate]], [[cp_plate/2 - cp_w/2, cp_plate/2 + cp_w/2]])] :
    concat(
    // Ribs and horizontal panels into the back (hook panels: the hooks are pushed onto
    // the back). A rib whose rear edge below its hook has no room for a tab is held by the
    // horizontals' joints instead.
    [for (p=RIBS) let(j = rib_back_joint(p)) if (has_room(j) || len(back_horizontals()) == 0) j],
    [for (h=back_horizontals()) let(j = hz_back_joint(h)) if (has_room(j)) j],
    FAMILY == "cubby" || FAMILY == "doors" || FAMILY == "drawers" || FAMILY == "display" || FAMILY == "rack" || FAMILY == "stand" ||
    FAMILY == "drill_cabinet" || FAMILY == "box" || FAMILY == "glove" ? side_joints(part("SIDE_L"), part("SIDE_R")) : [],
    cube ? [for (p=BODY) if (p[1] == "divider") each [on_joint("BOTTOM", p, true), on_joint("TOP", p, false)]] : [],
    FAMILY == "doors" && sliding ? [for (p=BODY) if (p[1] == "guide_strip") on_joint(p[3][2] < H/2 ? "BOTTOM" : "TOP", p, p[3][2] < H/2)] : [],
    FAMILY == "doors" && !sliding ? [for (p=BODY) if (p[1] == "pull") let(d = part(str(p[0] == "DOOR_1_PULL" ? "DOOR_1" : "DOOR_2")))
        J(d[0], p[0], 0, p[3][0], pull_span, 2, p[3][2], p[3][2] + t, 1, D, -1, [[0, pull_span]])] : [],
    FAMILY == "drawers" ? [for (i=[0:drawer_count - 1]) let(id = str("DRAWER_", i + 1), z = drawer_z(i), x0 = t + g, y0 = t + g) each [
        on_joint(str(id, "_BOTTOM"), part(str(id, "_SIDE_L")), true), on_joint(str(id, "_BOTTOM"), part(str(id, "_SIDE_R")), true),
        on_joint(str(id, "_BOTTOM"), part(str(id, "_FRONT")), true), on_joint(str(id, "_BOTTOM"), part(str(id, "_BACK")), true),
        for (s=[0:1]) let(x = s == 0 ? x0 : x0 + dbw - t) each [
            J(str(id, "_FRONT"), str(id, s == 0 ? "_SIDE_L" : "_SIDE_R"), 2, z + t, dbh - t, 0, x, x + t, 1, y0 + dbd - t, 1, [[0, dbh - t]]),
            J(str(id, "_BACK"), str(id, s == 0 ? "_SIDE_L" : "_SIDE_R"), 2, z + t, dbh - t, 0, x, x + t, 1, y0 + t, -1, [[0, dbh - t]])]]] : [],
    FAMILY == "display" && display_lips ? [for (i=[0:display_shelves - 1]) on_joint(str("SHELF_", i + 1), part(str("LIP_", i + 1)), true)] : [],
    FAMILY == "drill_simple" ? [for (s=["GUSSET_L", "GUSSET_R"]) let(r = part(s))
        J("CRADLE", s, 1, t, gusset_d, 0, r[3][0], r[3][0] + t, 2, H - t, 1, [[0, gusset_d]])] : [],
    FAMILY == "box" ? concat(
        [on_joint("BOTTOM", part("FRONT"), true),
         end_joint(part("SIDE_L"), part("FRONT"), true, t, box_fh), end_joint(part("SIDE_R"), part("FRONT"), false, t, box_fh)],
        [for (p=BODY) if (p[1] == "long_divider" || p[1] == "cross_divider") on_joint("BOTTOM", p, true)],
        box_lid ? [on_joint("LID", part("LID_PULL"), true)] : []) : [],
    FAMILY == "glove" ? [on_joint("BOTTOM", part("FRONT"), true),
         end_joint(part("SIDE_L"), part("FRONT"), true, t, H), end_joint(part("SIDE_R"), part("FRONT"), false, t, H)] : [],
    FAMILY == "brackets" ? concat(
        [for (p=BODY) if (p[1] == "bracket") J("DECK", p[0], 1, t, F, 0, p[3][0], p[3][0] + t, 2, H - t, 1, [[0, F]])],
        [on_joint("DECK", part("LIP"), true)]) : []);

// Joint style and planned tabs and screws (positions along the seam, from s0).
function tab_joint(j) = joinery_style == "tab_slot";
function jtabs(j) = !tab_joint(j) ? [] : len(j[12]) ? j[12] : sj_tabs(j[11], tool, fit);
// Edge depth of the member behind a joint, for the screw pilot.
function edge_depth(j) = let(mb = world_box(part(j[1]))) mb[j[8]][1] - mb[j[8]][0];
function pilot_fits(j) = screw_pilot_diameter <= part(j[1])[5] - 4 && edge_depth(j) >= screw_pilot_depth + 2 - 0.001;
// Tab joints whose member is too shallow for the pilot are glued without screws.
function jscrews(j) = tab_joint(j) ? (joint_screws && pilot_fits(j) ? sj_screws(j[11], jtabs(j), screw_clearance_diameter, tool) : [])
                                   : sj_screw_only(j[11], tool);
function host_t(j) = part(j[0])[5];
// Slot cross range, opened past the host's edge when the member is flush with it.
function slot_cross(j) = let(hb = world_box(part(j[0]))[j[5]], lo = j[6] - fit/2, hi = j[7] + fit/2)
    [lo < hb[0] + 0.5 ? hb[0] - 1 : lo, hi > hb[1] - 0.5 ? hb[1] + 1 : hi];
// Axis-aligned world box from along/cross/normal ranges.
function wbox(j, ar, cr, nr) = [for (ax=[0:2]) ax == j[2] ? ar : ax == j[5] ? cr : nr];
function into(j, d, extra=0) = j[10] > 0 ? [j[9] - extra, j[9] + d] : [j[9] - d, j[9] + extra];
// Features [part, type, world box, diameter, joint index]: add (tab), slot, hole (screw).
function joint_features(k) = let(j = JOINTS[k], ht = host_t(j))
    concat(
        [for (q=jtabs(j)) each [
            [j[1], "add", wbox(j, [j[3] + q[0], j[3] + q[1]], [j[6], j[7]], into(j, ht - tab_setback, 0)), 0, k],
            [j[0], "slot", wbox(j, [j[3] + q[0] - fit/2, j[3] + q[1] + fit/2], slot_cross(j), into(j, ht + 1, 1)), 0, k]]],
        [for (s=jscrews(j)) let(a = j[3] + s, c = (j[6] + j[7])/2)
            [j[0], "hole", wbox(j, [a, a], [c, c], into(j, ht + 1, 1)), screw_clearance_diameter, k]]);
FEATURES = [for (k=[0:1:len(JOINTS) - 1]) each joint_features(k)];

// ---------------------------------------------------------------- local frames
// World box -> local [u0,u1,v0,v1,w0,w1] of part p (w across the thickness).
function local_box(p, b) = let(o=p[3], th=p[5])
    p[2] == "XY" ? [b[0][0] - o[0], b[0][1] - o[0], b[1][0] - o[1], b[1][1] - o[1], b[2][0] - o[2], b[2][1] - o[2]] :
    p[2] == "XZ" ? [b[0][0] - o[0], b[0][1] - o[0], b[2][0] - o[2], b[2][1] - o[2], th - (b[1][1] - o[1]), th - (b[1][0] - o[1])] :
                   [b[1][0] - o[1], b[1][1] - o[1], b[2][0] - o[2], b[2][1] - o[2], b[0][0] - o[0], b[0][1] - o[0]];
function part_features(id, type) = [for (f=FEATURES) if (f[0] == id && f[1] == type) f];
function adds(p) = [for (f=part_features(p[0], "add")) local_box(p, f[2])];
function ext(p) = let(b = pts_box(p[4]), a = adds(p))
    [min(concat([b[0]], [for (x=a) x[0]])), max(concat([b[1]], [for (x=a) x[1]])),
     min(concat([b[2]], [for (x=a) x[2]])), max(concat([b[3]], [for (x=a) x[3]]))];
function cut_w(p) = let(e=ext(p)) e[1] - e[0];
function cut_h(p) = let(e=ext(p)) e[3] - e[2];
// Slot walls that lie outside the host's outline are open (no corner relief there).
function slot_open(p, lb) = let(mu = (lb[0] + lb[1])/2, mv = (lb[2] + lb[3])/2)
    [!sj_inside(p[4], [lb[0], mv]), !sj_inside(p[4], [lb[1], mv]), !sj_inside(p[4], [mu, lb[2]]), !sj_inside(p[4], [mu, lb[3]])];
// Shoulder of a tab on its member: [local seam axis, x0, w, shoulder coordinate].
function shoulder(p, f) = let(j = JOINTS[f[4]], lb = local_box(p, f[2]), la = local_axis(p, j[2]),
        face = to_local(p, [for (ax=[0:2]) ax == j[8] ? j[9] : (f[2][ax][0] + f[2][ax][1])/2]))
    la == 0 ? [0, lb[0], lb[1] - lb[0], face[1]] : [1, lb[2], lb[3] - lb[2], face[0]];

// ---------------------------------------------------------------- 2D geometry
module local_cut(c) {
    if (c[0] == "circle") { if (c[3] > 0) translate([c[1], c[2]]) circle(d=c[3]); }
    else if (c[0] == "oblong") hull() for (s=[-1, 1])
        translate([c[1] + (c[5] == 0 ? s*(c[4] - c[3])/2 : 0), c[2] + (c[5] == 1 ? s*(c[4] - c[3])/2 : 0)]) circle(d=c[3]);
    else if (c[0] == "front") {
        translate([c[1] - c[3]/2, c[2] - c[4] + c[3]/2]) square([c[3], c[4] - c[3]/2 + 1]);
        translate([c[1], c[2] - c[4] + c[3]/2]) circle(d=c[3]);
    }
    else if (c[0] == "poly") polygon(c[1]);
    else if (c[0] == "pocket") translate([c[1], c[2]]) tp_pocket_2d(c[3], c[4], tool, slot_corner_relief, c[5]);
    else if (c[0] == "relief") wm_relief_2d(c[1], tool);
}
// Local bounding box of a cut [u0, u1, v0, v1].
function cut_bbox(c) =
    c[0] == "circle" ? [c[1] - c[3]/2, c[1] + c[3]/2, c[2] - c[3]/2, c[2] + c[3]/2] :
    c[0] == "oblong" ? (c[5] == 0 ? [c[1] - c[4]/2, c[1] + c[4]/2, c[2] - c[3]/2, c[2] + c[3]/2] : [c[1] - c[3]/2, c[1] + c[3]/2, c[2] - c[4]/2, c[2] + c[4]/2]) :
    c[0] == "front" ? [c[1] - c[3]/2, c[1] + c[3]/2, c[2] - c[4], c[2]] :
    c[0] == "poly" ? pts_box(c[1]) :
    c[0] == "pocket" ? [c[1], c[1] + c[3], c[2], c[2] + c[4]] :
    let(r = tool/2) [min([for (q=c[1]) q[0]]) - r, max([for (q=c[1]) q[0]]) + r, min([for (q=c[1]) q[1]]) - r, max([for (q=c[1]) q[1]]) + r];
// Finished through-cut profile in local coordinates.
module part_2d(p) {
    difference() {
        union() {
            polygon(p[4]);
            for (b=adds(p)) translate([b[0], b[2]]) square([b[1] - b[0], b[3] - b[2]]);
        }
        for (f=part_features(p[0], "slot")) let(lb=local_box(p, f[2]))
            translate([lb[0], lb[2]]) tp_pocket_2d(lb[1] - lb[0], lb[3] - lb[2], tool, slot_corner_relief, slot_open(p, lb));
        for (f=part_features(p[0], "hole")) let(lb=local_box(p, f[2])) translate([lb[0], lb[2]]) circle(d=f[3]);
        // T-bone shoulder reliefs beside every tab, so the shoulder seats on the slot mouth.
        if (relief_on) for (f=part_features(p[0], "add")) let(s = shoulder(p, f))
            if (s[0] == 0) tp_tab_root_reliefs_2d(s[1], s[2], s[3], tool);
            else multmatrix([[0, 1, 0, 0], [1, 0, 0, 0], [0, 0, 1, 0], [0, 0, 0, 1]]) tp_tab_root_reliefs_2d(s[1], s[2], s[3], tool);
        for (c=p[7]) local_cut(c);
    }
}

// ---------------------------------------------------------------- 3D
function frame(p) = p[2] == "XY" ? [[1,0,0,p[3][0]], [0,1,0,p[3][1]], [0,0,1,p[3][2]], [0,0,0,1]] :
                    p[2] == "XZ" ? [[1,0,0,p[3][0]], [0,0,-1,p[3][1] + p[5]], [0,1,0,p[3][2]], [0,0,0,1]] :
                                   [[0,0,1,p[3][0]], [1,0,0,p[3][1]], [0,1,0,p[3][2]], [0,0,0,1]];
module part_3d(p) {
    if (p[1] == "wall_rail" || p[1] == "hanger")
        // Beveled boards: the bevel is a second cut along the blank (cleat.scad profile).
        difference() {
            translate([p[3][0], -ct, p[1] == "hanger" ? p[3][2] + ch - 2*ch + rise - cleat_vertical_gap : p[3][2]])
                mo_cleat_profile(pts_box(p[4])[1], ct, ch, bevel_angle, p[1] == "hanger" ? "stand" : "wall", p[1] == "hanger" ? cleat_vertical_gap : 0);
            for (c=p[7]) if (c[0] == "circle") translate([p[3][0] + c[1], 1, p[3][2] + c[2]]) rotate([90, 0, 0]) cylinder(d=c[3], h=ct + 2);
        }
    else multmatrix(frame(p)) linear_extrude(p[5]) part_2d(p);
}
COLORS = [["back", [0.72, 0.56, 0.37]], ["side", [0.82, 0.68, 0.47]], ["box_side", [0.82, 0.68, 0.47]], ["door", [0.88, 0.74, 0.52]],
          ["sliding_door", [0.88, 0.74, 0.52]], ["drawer_front", [0.88, 0.74, 0.52]], ["wall_rail", [0.55, 0.42, 0.28]],
          ["hanger", [0.60, 0.46, 0.30]], ["spacer", [0.60, 0.46, 0.30]], ["pull", [0.50, 0.38, 0.25]], ["lid", [0.88, 0.74, 0.52]]];
function color_of(kind) = let(c = [for (x=COLORS) if (x[0] == kind) x[1]]) len(c) ? c[0] : [0.91, 0.79, 0.59];
module dowel() {
    color([0.62, 0.45, 0.27]) translate([-t/3, t + towel_y, H/2]) rotate([0, 90, 0]) cylinder(h=W + 2*t/3, d=dowel_diameter);
}
module assembly() {
    for (p=PARTS) if (render_part == "" || render_part == p[0]) color(color_of(p[1])) part_3d(p);
    if (FAMILY == "towel" && (render_part == "" || render_part == "DOWEL")) dowel();
}

// ---------------------------------------------------------------- flat layout
// Rows no wider than the stock sheet (or the widest part), layout_gap apart, into the
// core placement table: [id, x, y, w, h, paint name, paint index].
row_limit = max(stock_width, max([for (p=PARTS) cut_w(p)]));
function pack(i=0, x=0, y=0, rowh=0, acc=[]) = i >= len(PARTS) ? acc :
    let(w = cut_w(PARTS[i]), h = cut_h(PARTS[i]), nr = x > 0 && x + w > row_limit,
        nx = nr ? 0 : x, ny = nr ? y + rowh + layout_gap : y, nh = nr ? h : max(rowh, h))
    pack(i + 1, nx + w + layout_gap, ny, nh, concat(acc, [[PARTS[i][0], nx, ny, w, h, PARTS[i][1], i]]));
cut_layout_placement_table = pack();
LW = max([for (q=cut_layout_placement_table) q[1] + q[3]]);
LH = max([for (q=cut_layout_placement_table) q[2] + q[4]]);
module paint(name, index=0) { color(color_of(name)) children(); }
module laid(p) { e = ext(p); translate([-e[0], -e[2]]) children(); }
module export_frame() {
    if (include_shared_export_bounding_box) {
        m = layout_gap;
        difference() {
            translate([-m - 0.5, -m - 0.5]) square([LW + 2*m + 1, LH + 2*m + 1]);
            translate([-m, -m]) square([LW + 2*m, LH + 2*m]);
        }
    }
}
// Flat cut profile of a part: beveled boards are cut as rectangular blanks.
module flat_2d(p) { part_2d(p); }
module cut_layout() {
    export_frame();
    for (p=PARTS) placed(p[0]) laid(p) flat_2d(p);
}
// Part labels sit inside the part's outline: the first spot, from the middle outwards,
// where the whole label (about one size per character wide) is on the part.
function label_fits(p, c, w, h) = len([for (d=[[0, 0], [-w/2, -h/2], [w/2, -h/2], [w/2, h/2], [-w/2, h/2]]) if (!sj_inside(p[4], c + d)) 1]) == 0;
function label_spot(p, s) = let(b = pts_box(p[4]), f = [0.5, 0.35, 0.65, 0.2, 0.8],
        c = [for (fy=f) for (fx=f) let(q = [b[0] + fx*(b[1] - b[0]), b[2] + fy*(b[3] - b[2])]) if (label_fits(p, q, 1.0*s*len(p[0]), 1.3*s)) q])
    len(c) ? [c[0], s] : s > 2 ? label_spot(p, s/2) : [[(b[0] + b[1])/2, (b[2] + b[3])/2], s];
module engrave_layout() {
    export_frame();
    for (q=cut_layout_placement_table) let(p = part(q[0]), e = ext(p), l = label_spot(p, min(engrave_label_size, q[4]/4, 0.9*q[3]/(len(q[0]) + 1))))
        translate([q[1] + l[0][0] - e[0], q[2] + l[0][1] - e[2]]) text(q[0], size=l[1], halign="center", valign="center");
}
module flat_3d() {
    for (p=PARTS) let(q = cut_layout_placement_table[placement_index(p[0])]) translate([q[1], q[2]]) linear_extrude(p[5]) laid(p) flat_2d(p);
}

// ---------------------------------------------------------------- fit checks
module check(ok, code, msg) { if (!ok) echo(str("CHECK|ERROR|", code, "|", msg)); }
module warn(ok, code, msg) { if (!ok) echo(str("CHECK|WARN|", code, "|", msg)); }
function good_count(n, lo, hi) = n >= lo && n <= hi && floor(n) == n;
function rects_overlap(a, b) = a[0] < b[0] + b[2] - 0.001 && b[0] < a[0] + a[2] - 0.001 && a[1] < b[1] + b[3] - 0.001 && b[1] < a[1] + a[3] - 0.001;
function lb4(lb) = [lb[0], lb[1], lb[2], lb[3]];
function grow(b, m) = [b[0] - m, b[1] + m, b[2] - m, b[3] + m];
// Every through cut of a part in local boxes [u0,u1,v0,v1] with what it is.
function part_slots(p) = [for (f=part_features(p[0], "slot")) [lb4(local_box(p, f[2])), str("slot for ", JOINTS[f[4]][1])]];
function part_holes(p) = [for (f=part_features(p[0], "hole")) let(lb=local_box(p, f[2])) [[lb[0] - f[3]/2, lb[0] + f[3]/2, lb[2] - f[3]/2, lb[2] + f[3]/2], str("screw for ", JOINTS[f[4]][1])]];
function part_cuts(p) = [for (c=p[7]) if (c[0] != "relief") [cut_bbox(c), c[0] == "pocket" ? "notch for a hooked rib" : c[0] == "circle" && c[3] == screw_clearance_diameter ? "screw" : "opening"]];
// Tongue corner covered by a slot corner's relief (or by the clearance alone when CAM adds no relief).
function corner_clear(w, h, open) = let(r = tool/2, cs = tp_pocket_relief_centres(w, h, tool, slot_corner_relief, open))
    [for (ix=[0:1]) for (iy=[0:1]) if (!open[ix] && !open[2 + iy])
        let(cx = ix == 0 ? 0 : w, cy = iy == 0 ? 0 : h, tc = [cx + (ix == 0 ? 1 : -1)*fit/2, cy + (iy == 0 ? 1 : -1)*fit/2])
        relief_on ? len([for (c=cs) if (norm(c - tc) <= r + 1e-6) 1]) > 0 : fit/2*sqrt(2) >= (sqrt(2) - 1)*r];
module fit_checks() {
    // 1. Every tab against its slot: clearance on both axes, tab length, cutter and reliefs.
    for (k=[0:1:len(JOINTS) - 1]) let(j = JOINTS[k], h = part(j[0]), m = part(j[1]), ht = h[5]) {
        check(pidx(j[0]) >= 0 && pidx(j[1]) >= 0, "JOINT_PARTS", str("Joint ", j[1], " to ", j[0], " names a missing part."));
        check(abs((j[7] - j[6]) - m[5]) < 0.01, "TAB_THICKNESS", str(j[1], " to ", j[0], ": the tab is not the member's full thickness."));
        if (tab_joint(j)) {
            ts = jtabs(j);
            check(len(ts) > 0, "NO_ROOM_FOR_TABS", str(j[1], " to ", j[0], ": no room for a tab on this joint; make the part larger or use screw joinery."));
            for (q=ts) let(lb = [q[0] - fit/2, q[1] + fit/2], sc = slot_cross(j)) {
                check(abs((lb[1] - lb[0]) - (q[1] - q[0]) - fit) < 0.001 && sc[0] <= j[6] - fit/2 + 0.001 && sc[1] >= j[7] + fit/2 - 0.001,
                      "FIT_CLEARANCE", str(j[1], " to ", j[0], ": slot is not tab + ", fit, " mm on both axes."));
                check(min(q[1] - q[0] + fit, m[5] + fit) >= tool, "SLOT_CUTTER", str(j[1], " to ", j[0], ": a ", q[1] - q[0] + fit, " x ", m[5] + fit, " mm slot is narrower than the ", tool, " mm cutter."));
                check(tab_setback >= 0 && tab_setback < ht/2, "TAB_LENGTH", str(j[1], " to ", j[0], ": tabs must be shorter than the ", ht, " mm panel they pass through, by less than half its thickness."));
                if (q[0] < q[1]) let(w = q[1] - q[0] + fit, hh = sc[1] - sc[0], open = [false, false, sc[0] < j[6] - fit/2 - 0.5, sc[1] > j[7] + fit/2 + 0.5],
                        cc = corner_clear(w, hh, open))
                    if (relief_on) check(len([for (c=cc) if (!c) 1]) == 0, "SLOT_RELIEF", str(j[1], " to ", j[0], ": a slot corner relief does not clear the tab corner."));
            }
            check(len([for (x=sj_webs(ts)) if (x < 2*tool + 1) 1]) == 0, "TAB_WEB", str(j[1], " to ", j[0], ": less than two cutter widths of wood between slots."));
        } else check(len(jscrews(j)) > 0, "NO_ROOM_FOR_SCREWS", str(j[1], " to ", j[0], ": no room for a screw."));
        // Screws land in the host's wood, clear of its slots and cuts, and in the member's edge.
        for (s=jscrews(j)) let(a = j[3] + s, c = (j[6] + j[7])/2, wp = [for (ax=[0:2]) ax == j[2] ? a : ax == j[5] ? c : j[9]],
                lc = to_local(h, wp), d = screw_clearance_diameter, hb = [lc[0] - d/2, lc[0] + d/2, lc[1] - d/2, lc[1] + d/2],
                hits = [for (x=concat(part_slots(h), [for (y=part_cuts(h)) if (y[1] != "screw") y])) if (sj_rects_overlap(grow(x[0], relief_on ? tool/2 : 0), hb)) x[1]],
                mb = world_box(m)) {
            check(sj_circle_inside(h[4], lc, d + 2), "SCREW_LANDING", str(j[1], " to ", j[0], ": a screw hole at ", a, " mm breaks out of ", j[0], "."));
            check(len(hits) == 0, "SCREW_CLASH", str(j[1], " to ", j[0], ": a screw hole runs into the ", hits[0], " in ", j[0], "."));
            check(pilot_fits(j), "SCREW_PILOT",
                  str(j[1], " to ", j[0], ": the ", screw_pilot_diameter, " x ", screw_pilot_depth, " mm pilot does not fit the edge of ", j[1], "."));
        }
    }
    if (!relief_on && len([for (j=JOINTS) each jtabs(j)]) > 0)
        warn(fit/2*sqrt(2) >= (sqrt(2) - 1)*tool/2, "SLOT_RELIEF", str("Slots are cut with square inside corners: the ", tool, " mm cutter leaves rounded corners that stop the tabs seating unless CAM adds dog-bone or T-bone relief."));
    // 2. Slots, notches, screws and openings of one part do not run into each other.
    for (p=PARTS) let(feats = concat([for (x=part_slots(p)) [grow(x[0], relief_on ? tool/2 : 0), x[1]]], part_holes(p), part_cuts(p)))
        for (a=[0:1:len(feats) - 2]) for (b=[a + 1:1:len(feats) - 1])
            check(!sj_rects_overlap(feats[a][0], feats[b][0]) || (feats[a][1] == feats[b][1] && feats[a][1] == "opening"), "CUT_CLASH",
                  str(p[0], ": the ", feats[a][1], " runs into the ", feats[b][1], "."));
    // 3. Assembly order: every joint goes together along its tab direction.
    for (j=JOINTS) let(h = part(j[0]), m = part(j[1])) {
        later = m[9] > h[9] ? m : h;
        need = m[9] > h[9] ? [j[8], j[10]] : [j[8], -j[10]];
        check(m[9] != h[9] && later[10] == need, "ASSEMBLY_ORDER",
              str(j[1], " to ", j[0], ": in the assembly order ", later[0], " cannot be fitted along its tabs."));
    }
    if (!coupon) check(len([for (j=JOINTS) if (j[0] == "BACK") each concat(jtabs(j), jscrews(j))]) >= 2, "BACK_HELD", "The back has fewer than two tabs or screws holding it: turn on screws beside the tabs, use a fixed count of two tabs, or make the module larger.");
    // 4. No two parts share space (base outlines, by their boxes). Beveled boards interlock
    // with the rail, and hooked side panels reach through the back, so those pairs are
    // left to the exact 3D sweep of the test suite.
    for (a=[0:1:len(PARTS) - 2]) for (b=[a + 1:1:len(PARTS) - 1]) let(p = PARTS[a], q = PARTS[b], A = body_box(p), B = body_box(q))
        if (!(p[1] == "wall_rail" || q[1] == "wall_rail" || (hooked(p[8]) && q[0] == "BACK") || (hooked(q[8]) && p[0] == "BACK")))
            check(len([for (ax=[0:2]) if (A[ax][0] < B[ax][1] - 0.01 && B[ax][0] < A[ax][1] - 0.01) 1]) < 3, "PART_OVERLAP",
                  str(p[0], " and ", q[0], " occupy the same space."));
    // 5. Nothing passes the wall plane; the hanger or hooks engage the rail.
    check(min([for (p=PARTS) world_box(p)[1][0]]) >= wall_y - 0.001, "WALL_CLEARANCE", "A part reaches behind the wall.");
    if (cleat_mount && !coupon) {
        check(ch > rise + 10 && H > ch + t, "CLEAT_SIZE", str("The ", ch, " mm cleat needs more than its ", rise, " mm bevel rise and must be lower than the module."));
        check(rail_z >= 0, "RAIL_BELOW_MODULE", str("The wall rail would start ", -rail_z, " mm below the module: use a shorter cleat or a taller module."));
        if (cnc) {
            check(wm_tip_ok(ct, ch, bevel_angle, hook_tip_radius), "HOOK_TIP", "The hook tip radius leaves no flat bevel to bear on.");
            check(ct >= tool + 1, "HOOK_CUTTER", str("The ", ct, " mm hook is too shallow for the ", tool, " mm cutter."));
            check(wm_hook_relief_bottom(ct, bevel_angle, tip_v, tool) > notch_z + 1, "HOOK_RELIEF", "The hook's corner relief reaches below the back notch.");
            check(notch_z - fit/2 - max(tool, t/2) >= 2*tool + 12, "HOOK_NOTCH", str("The back notch for the hooks starts ", notch_z, " mm up: the module is too short for a ", ch, " mm cleat."));
            check(rail_len >= W - 0.01 || !include_wall_rail, "RAIL_LENGTH", "With CNC side hooks the wall rail must reach both side panels.");
        }
        if (beveled) info(straight_drop, "HANG_TILT", str("Lower spacer: tilt the module to hang it; lifting it ", lift, " mm straight up would hit the rail with the spacer."));
        info(!include_wall_rail || rail_len >= wall_screw_spacing + 2*wall_screw_diameter + 20, "RAIL_STUDS",
             str("The ", rail_len, " mm wall rail is shorter than the ", wall_screw_spacing, " mm stud spacing: use wall anchors or a longer rail."));
        // Other rails on the wall must stay clear of everything behind the back: the
        // hanger and spacer, or the hooks (from their tip up). The back itself may rest on
        // a lower rail's face.
        for (p=PARTS) let(b = world_box(p), lo = hooked(p[8]) ? tip_v : b[2][0]) if (b[1][0] < -0.001 && p[1] != "wall_rail")
            for (z=wm_other_rails(rail_z, ch, wall_rail_pitch, lo, b[2][1]))
                check(false, "ADJACENT_RAIL",
                      str(p[0], " runs into the wall rail at ", z, " mm: change the rail pitch or the module height."));
    }
    // 6. Functional fits.
    if (FAMILY == "doors" && !sliding) check(g >= 0.5 && leaf > 20 && t + shelf_depth <= D - t - g + 0.01, "DOOR_FIT", "Doors need at least 0.5 mm all round and shelves set back behind them.");
    if (sliding) {
        check(strip_top - strip_lift >= strip_bottom - 0.01 && slide_h + strip_lift + 2*t <= H + 0.01, "SLIDING_FIT",
              "A sliding leaf must lift out of the bottom channel and stay in the top one.");
        check(slide_w > 2*finger_d(I), "SLIDING_WIDTH", "Sliding leaves are too narrow for their finger bores.");
        check(shelf_depth > 2*t, "SLIDING_DEPTH", "The sliding-door track leaves no room for shelves: make the cabinet deeper.");
    }
    if (FAMILY == "drawers") check(dbh > 2*t + 10 && dbw > 2*t + 20 && dbd > 2*t + 20 && g >= 0.5, "DRAWER_FIT",
        str("Each drawer box needs room inside its opening: ", dbw, " x ", dbh, " x ", dbd, " mm with ", g, " mm clearance."));
    if (FAMILY == "box") check(box_cell >= 20 && box_cy/box_rows - t >= 20 && box_dh > t, "BIN_FIT", "Each bin needs at least 20 mm clear and dividers taller than a board.");
}
module info(ok, code, msg) { if (!ok) echo(str("CHECK|INFO|", code, "|", msg)); }

// Module-specific limits on sizes and openings.
function row_ok(n, w, u) = let(c = [for (i=[0:n-1]) tool_center(i, n, u)])
    c[0] - w/2 >= min_web_open + (relief_on ? tool : 0) && c[n-1] + w/2 <= u - min_web_open - (relief_on ? tool : 0) &&
    (n < 2 || c[1] - c[0] - w >= min_web_open);
module validate() {
    check(t > 0 && t <= 50, "STOCK", "Carcass stock must be a listed preset or a measured thickness from 1 to 50 mm.");
    check(ct > 0 && ct <= 50, "CLEAT_STOCK", "Cleat stock must be a listed preset or a measured thickness from 6 to 50 mm.");
    check(FAMILY != "unknown", "MODULE_TYPE", str("Unknown module ", MT, "."));
    check(coupon || (W >= 3*t + 20 && D >= 2*t + 20 && H >= 3*t + 20), "SIZE", "The module is too small for its stock.");
    check(fit >= 0 && fit < t/4, "FIT_CLEARANCE", "Joint fit clearance must be at least 0 and less than a quarter of the stock.");
    check(slot_corner_relief == "none" || slot_corner_relief == "dogbone" || slot_corner_relief == "t_bone", "SLOT_RELIEF", "Corner relief must be none, dogbone or t_bone.");
    check(screw_pilot_diameter > 0 && screw_clearance_diameter >= screw_pilot_diameter, "SCREW_SIZE", "The screw clearance hole must be at least the pilot size.");
    if (n_shelves > 0) check(clear_h >= 20, "SHELF_SPACING", str("Shelves leave ", clear_h, " mm openings; use fewer shelves."));
    if (cube) check(bay_w >= 40, "BAY_WIDTH", str("Bays are ", bay_w, " mm wide; use fewer bays."));
    if (FAMILY == "display") check(display_shelves == 1 || disp_step > t + (display_lips ? lip_height : 0) + 20, "SHELF_SPACING", "Display shelves are too close for their lips.");
    if (FAMILY == "drill_cabinet") check((H - t)/upper_shelf_count > t + 20, "SHELF_SPACING", "Too many compartments above the cradle.");
    if (FAMILY == "rack" || FAMILY == "stand" || FAMILY == "drill_simple" || FAMILY == "drill_cabinet") {
        u = FAMILY == "drill_simple" ? W : I;
        w = MT == "circular_saw_stand" ? saw_guard_width : MT == "router_bit_stand" ? tool_width + bit_fit_allowance : tool_width;
        n = MT == "circular_saw_stand" ? 1 : tool_count;
        l = MT == "circular_saw_stand" ? slot_auto(0.85) : MT == "plier_stand" ? slot_auto(0.67) : FAMILY == "drill_simple" || FAMILY == "drill_cabinet" ? drill_l : slot_auto(0.72);
        if (MT == "circular_saw_stand") check(saw_guard_offset >= t + min_web_open + tool && saw_guard_offset + saw_guard_width <= W - t - min_web_open - tool, "TOOL_FIT", "The saw guard slot must sit between the sides with wood to spare.");
        else check(row_ok(n, w, u - (FAMILY == "drill_simple" ? 2*t : 0)) || (FAMILY == "drill_simple" && row_ok(n, w, u)), "TOOL_FIT",
            str("The ", n, " openings of ", w, " mm leave less than ", min_web_open, " mm of wood between them or at the ends; use fewer, narrower or a set pitch."));
        if (MT == "chisel_rack" || MT == "clamp_rack" || MT == "circular_saw_stand" || FAMILY == "drill_simple" || FAMILY == "drill_cabinet" || MT == "plier_stand")
            check(l > w/2 && l < F - min_web_open - (MT == "plier_stand" ? (F - l)/2 : 0), "SLOT_LENGTH", str("Slots ", l, " mm long do not fit a ", F, " mm deep panel."));
        if (MT == "router_bit_stand") check(bit_fit_allowance > 0 && F/tool_rows > w + min_web_open, "TOOL_FIT", "Router bit holes need an allowance over the shank and room for their rows.");
        if (MT == "screwdriver_rack" && second_row) check(0.40*F > w + min_web_open, "TOOL_FIT", "The two rows of screwdriver holes overlap; make the rack deeper or the holes smaller.");
        warn(w >= tool, "DRILL_HOLES", str(w, " mm openings are smaller than the ", tool, " mm cutter: drill them."));
    }
    if (FAMILY == "drill_simple") check(gusset_d >= 2*t, "GUSSET", "The drill station is too shallow for its gussets.");
    if (FAMILY == "glove") check(glove_l >= glove_w && glove_l < I - 2*min_web_open - 2*tool && glove_w < H - 3*t, "TOOL_FIT", "The glove slot must fit inside the front.");
    if (FAMILY == "hooks") check(W/hook_count > t + 10, "HOOK_COUNT", "Too many hooks for the width.");
    if (FAMILY == "brackets") check(good_count(bracket_count, 2, 12) && (W - t)/(bracket_count - 1) > t + 20, "BRACKET_COUNT", "Too many brackets for the width.");
    if (FAMILY == "towel") check(towel_y > dowel_diameter && H > 3*dowel_diameter && towel_y + (dowel_diameter + rod_clearance)/2 < F - min_web_open, "DOWEL_FIT", "The dowel does not fit its cheeks.");
    if (FAMILY == "wrench") check(wrench_step > tool_width + wrench_rise + t/4 && wrench_l < F - t/3 && tool_width >= tool, "TOOL_FIT", "The wrench slots overlap or do not fit the cheeks.");
    check(layout_gap > 0, "LAYOUT_OVERLAP", str("layout_gap is ", layout_gap, " mm; parts of the flat cut layout would overlap."));
    warn(layout_gap >= tool, "LAYOUT_GAP", "The layout gap is narrower than the cutter.");
    for (p=PARTS) warn(min(cut_w(p), cut_h(p)) <= min(stock_width, stock_height) && max(cut_w(p), cut_h(p)) <= max(stock_width, stock_height),
        "SHEET_SIZE", str(p[0], " (", cut_w(p), " x ", cut_h(p), " mm) is larger than the ", stock_width, " x ", stock_height, " mm sheet."));
    for (o=layout_overlaps()) check(false, "LAYOUT_OVERLAP", str(o[0], " overlaps ", o[1], " in the flat cut layout."));
    fit_checks();
    echo(str("CHECK|INFO|FIT_SUMMARY|", len(JOINTS), " joints, ", len([for (j=JOINTS) each jtabs(j)]), " tabs and ",
             len([for (j=JOINTS) each jscrews(j)]), " screws checked for slot clearance, cutter reach, relief, screw landing and assembly order; geometric check only, cut a fit coupon before a full module."));
    echo("CHECK|INFO|VALIDATION_SCOPE|Geometric and manufacturing checks only; no load rating, wall anchoring or CAM verification.");
}

// ---------------------------------------------------------------- reports
NAMES = [["single_cube_shelf", "Single cube shelf"], ["double_cube_shelf", "Double cube shelf"], ["narrow_shelves", "Narrow shelves"],
         ["sandpaper_shelf", "Sandpaper shelf"], ["single_door_cabinet", "Single door cabinet"], ["double_door_cabinet", "Double door cabinet"],
         ["sliding_door_cabinet", "Sliding door cabinet"], ["three_drawer_cabinet", "3-drawer cabinet"], ["four_drawer_cabinet", "4-drawer cabinet"],
         ["simple_shelves", "Simple shelves"], ["jar_shelves", "Jar shelves"], ["spray_paint_display", "Spray paint display"],
         ["chisel_rack", "Chisel rack"], ["clamp_rack", "Clamp rack"], ["hammer_rack", "Hammer rack"], ["screwdriver_rack", "Screwdriver rack"],
         ["plier_stand", "Plier stand"], ["router_bit_stand", "Router bit stand"], ["circular_saw_stand", "Circular saw stand"],
         ["simple_drill_station", "Simple drill station"], ["double_drill_station", "Double drill station"],
         ["single_shelf_drill_stand", "Single shelf drill stand"], ["double_shelf_drill_stand", "Double shelf drill stand"],
         ["closed_lid_box", "Closed lid box"], ["screw_box", "Screw box"], ["shallow_storage_box", "Shallow storage box"], ["glove_box", "Glove box"],
         ["hook_panel", "Hook panel"], ["material_storage_stand", "Material storage stand"], ["paper_towel_holder", "Paper towel holder"],
         ["wrench_holder", "Wrench holder"], ["fit_coupon", "Fit test coupon"]];
function bom_note(p) =
    p[1] == "wall_rail" ? str("SECONDARY BEVEL ", bevel_angle, " deg along the top edge, high side to the room; blank; screw into studs") :
    p[1] == "hanger" ? str("SECONDARY BEVEL ", bevel_angle, " deg along the bottom edge, low side to the wall; blank; screwed through the back") :
    p[1] == "spacer" ? "screwed through the back; keeps the bottom of the module off the wall" :
    hooked(p[8]) || p[1] == "coupon_hook" ? "CNC side hook on the rear edge" : "as drawn";
module reports() {
    validate();
    total_d = D + (cleat_mount ? ct : 0);
    echo(str("DIM|CABINET|OUTSIDE|W=", W, "|H=", H, "|D=", total_d));
    echo(str("DIM|SHOP_WALL|MODULE|TYPE=", MT, "|FAMILY=", FAMILY, "|W=", W, "|H=", H, "|D=", D, "|WALL_D=", total_d, "|STOCK=", t));
    echo(str("DIM|SHOP_WALL|MOUNT|MOUNT=", mount, "|STRATEGY=", cleat_mount ? (cnc ? "cnc_hooks" : "beveled_board") : "none",
             "|CLEAT_H=", ch, "|BEVEL=", bevel_angle, "|RISE=", rise, "|RAIL_Z=", rail_z, "|RAIL_L=", rail_len, "|HANG_LIFT=", lift));
    echo(str("DIM|SHOP_WALL|JOINERY|STYLE=", joinery_style, "|FIT=", fit, "|SETBACK=", tab_setback, "|RELIEF=", relief_on ? slot_corner_relief : "none", "|CUTTER=", tool,
             "|JOINTS=", len(JOINTS), "|TABS=", len([for (j=JOINTS) each jtabs(j)]), "|SCREWS=", len([for (j=JOINTS) each jscrews(j)])));
    if (n_shelves > 0) echo(str("DIM|SHOP_WALL|SHELVES|COUNT=", n_shelves, "|OPENING_H=", clear_h));
    if (cube) echo(str("DIM|SHOP_WALL|BAYS|COUNT=", n_bays, "|CLEAR_W=", bay_w, "|CLEAR_H=", H - 2*t));
    if (FAMILY == "drawers") echo(str("DIM|SHOP_WALL|DRAWERS|COUNT=", drawer_count, "|BOX_W=", dbw, "|BOX_H=", dbh, "|BOX_D=", dbd, "|GAP=", g));
    if (FAMILY == "doors") echo(sliding ? str("DIM|SHOP_WALL|SLIDING|LEAF_W=", slide_w, "|LEAF_H=", slide_h, "|LIFT=", strip_lift, "|CHANNEL=", channel) :
                                          str("DIM|SHOP_WALL|DOORS|COUNT=", double_door ? 2 : 1, "|LEAF_W=", leaf, "|LEAF_H=", door_h, "|GAP=", g));
    if (FAMILY == "box") echo(str("DIM|SHOP_WALL|BINS|COLUMNS=", box_div ? box_columns : 1, "|ROWS=", box_div ? box_rows : 1, "|CELL_W=", box_div ? box_cell : I, "|FRONT_H=", box_fh));
    if (FAMILY == "rack" || FAMILY == "stand" || FAMILY == "drill_simple" || FAMILY == "drill_cabinet")
        echo(str("DIM|SHOP_WALL|OPENINGS|COUNT=", MT == "circular_saw_stand" ? 1 : tool_count, "|WIDTH=", MT == "circular_saw_stand" ? saw_guard_width : MT == "router_bit_stand" ? tool_width + bit_fit_allowance : tool_width,
                 "|PITCH=", tool_pitch, "|ROWS=", MT == "router_bit_stand" ? tool_rows : MT == "screwdriver_rack" && second_row ? 2 : 1));
    if (output_mode == "cut_layout") echo("OPERATION|cut_layout|Through cuts, full stock thickness: outlines, tabs, slots, hooks, notches, openings and holes. Bevel the hanger and wall rail blanks on a saw afterwards.");
    if (output_mode == "bom") {
        for (p=PARTS) echo(str("BOM|", p[0], "|1|", p[1], "|", p[6], "|", p[5], "|", cut_w(p), "|", cut_h(p), "|", bom_note(p)));
        placement_report();
        screws = len([for (j=JOINTS) each jscrews(j)]);
        if (screws > 0) echo(str("HARDWARE|ID=joint_screws|QTY=", screws, "|UNIT=each|NOTE=countersunk wood screws through ", screw_clearance_diameter, " mm holes; pilot ", screw_pilot_diameter, " x ", screw_pilot_depth, " mm into the panel edge, drilled at assembly"));
        bs = [for (s=BACK_SCREWS) if (s[3] != "wall") s];
        if (len(bs)) echo(str("HARDWARE|ID=hanger_screws|QTY=", len(bs), "|UNIT=each|NOTE=countersunk from inside the back into the hanger and spacer; length at most ", floor(t + ct - 3), " mm"));
        ws = len([for (s=BACK_SCREWS) if (s[3] == "wall") s]) + (cleat_mount && include_wall_rail && !coupon ? len(wm_screw_stations(rail_len, wall_screw_spacing, 2*wall_screw_diameter + 10)) : 0);
        if (ws > 0) echo(str("HARDWARE|ID=wall_screws|QTY=", ws, "|UNIT=each|NOTE=", wall_screw_diameter, " mm screws into studs (or rated anchors), countersunk flush"));
        hinges = FAMILY == "doors" && !sliding ? (double_door ? 4 : 2) : box_lid && FAMILY == "box" ? 2 : 0;
        if (hinges > 0) echo(str("HARDWARE|ID=hinges|QTY=", hinges, "|UNIT=each|NOTE=surface-mount or butt hinges for ", t, " mm stock; ", FAMILY == "box" ? "lid hinged at the top of the back" : "inset doors hinged on the outer edges"));
        if (FAMILY == "towel") echo(str("HARDWARE|ID=dowel|QTY=1|UNIT=each|NOTE=", dowel_diameter, " mm dowel, ", W + 2*t/3, " mm long"));
        echo("HARDWARE|ID=glue|QTY=1|UNIT=bottle|NOTE=wood glue for every tab joint");
    }
}

reports();
if (output_mode == "assembly") assembly();
else if (output_mode == "flat_3d") flat_3d();
else if (output_mode == "cut_layout") cut_layout();
else if (output_mode == "engrave_layout") engrave_layout();
