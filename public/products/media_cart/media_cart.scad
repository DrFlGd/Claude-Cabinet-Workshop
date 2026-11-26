// Media cart | Claude Cabinet Workshop product engine | Units: mm
// Based on the standalone "Shop media holder" model (shapes, bin grid, towers,
// stock presets and crosspiece joinery), corrected for manufacture:
//   - every part is one flat 2D profile; the 3D assembly, the cut layout, the
//     pocket layouts and the parts list are all drawn from that same profile;
//   - every joint is defined once (world coordinates) and produces matching tabs and
//     receivers, dados and tongues, or screw holes on both mating parts;
//   - fins half-lap every crosspiece, front and rear included, so a one-row grid is
//     still locked together;
//   - floors, the bin deck, cubbies and tower parts are joined (Panel joinery), with
//     an assembly order in which every part arrives along the direction of its tabs;
//   - slots, receivers and dados get dog-bone or T-bone relief at closed corners.
// X left to right, Y front (0) to back, Z up. Body heights exclude casters.
// See docs/MEDIA_CART_REVIEW.md for the review of the original model.

/* [Shape] */
shape = "sloped_bins"; // [sloped_bins, stepped_bins, shelf_cart, custom]
// Auto follows the selected shape. Stepped or Sloped overrides it for any shape.
bin_profile = "Auto"; // [Auto, Stepped, Sloped]
// Tower and lower cubby settings apply to the Custom shape.
custom_tower = "None"; // [None, Left, Right, Both]
custom_lower_cubbies = true;

/* [Body and grid] */
width = 900; // [300:1:2400]
depth = 600; // [200:1:1200]
// Full-height back and tower height. Sets the rise between bin entrances.
rear_height = 950; // [150:1:2000]
// End the bin walls level with the last row entrance. Shelf towers keep their full height.
back_flush_with_top_entrance = false;
front_height = 350; // [60:1:2000]
rows = 3; // [1:1:12]
columns = 3; // [1:1:12]
// Clear space above the bottom panel when lower cubbies are enabled.
cubby_height = 125; // [40:1:800]
cubby_columns = 3; // [1:1:12]

/* [Materials and stock] */
// Carcass stock applies to side walls, crosspieces, floors, cubbies and tower parts.
carcass_stock = "custom_mm"; // [custom_mm, 1/8_nominal, 1/4_nominal, 3/8_nominal, 1/2_nominal, 5/8_nominal, 3/4_nominal, 1_nominal]
// Measured carcass thickness in custom_mm mode.
material_thickness = 18.00; // [1:0.01:50]
// Stock for the lengthwise bin dividers (fins).
fin_stock = "match_carcass"; // [match_carcass, custom_mm, 1/8_nominal, 1/4_nominal, 3/8_nominal, 1/2_nominal, 5/8_nominal, 3/4_nominal, 1_nominal]
custom_fin_thickness = 12.00; // [1:0.01:50]

/* [Joinery] */
// Connection between each crosspiece and both bin side walls.
joinery_style = "tab_slot"; // [butt, screw, dado, tab_slot]
// Connection of floors, the bin deck, cubby parts and tower parts.
panel_joinery = "tab_slot"; // [butt, screw, dado, tab_slot]
// Depth of every dado (housing) groove.
dado_depth = 6.0; // [0.5:0.1:20]
// Total extra groove width across the housed panel.
dado_fit_clearance = 0.20; // [0:0.05:2]
// Total added width and length of tab receivers and half-lap slots.
joint_fit_clearance = 0.20; // [0:0.05:2]
// Length of each tab along the joint; screws use the same positions.
tab_length = 40; // [10:1:200]
// Approximate spacing between tab centers.
tab_spacing = 160; // [40:1:600]
// Distance from a joint end to the first tab.
tab_edge_margin = 20; // [3:1:100]
// Minimum solid material between neighbouring receivers.
minimum_joint_web = 25; // [5:1:100]
// Screw mode: clearance holes through the receiving panel.
screw_clearance_diameter = 4.5; // [1:0.1:12]
// Pilot holes are drilled into panel edges at assembly.
screw_pilot_diameter = 3.0; // [0.5:0.1:10]
screw_pilot_depth = 22.0; // [5:0.5:80]

/* [Side towers] */
// Clear inside width per tower. Each tower shares the bins' side wall.
tower_width = 185; // [60:1:800]
// Number of clear openings between base and cap.
tower_openings = 5; // [1:1:12]

/* [Mobility] */
show_casters = true;
// Floor to underside of the bottom panel.
caster_height = 85; // [20:1:250]
// Caster plate center from the outside edges.
caster_inset = 70; // [20:1:300]
// Bolt hole pattern of the caster plate (center to center).
caster_hole_spacing_x = 75; // [10:0.5:200]
caster_hole_spacing_y = 75; // [10:0.5:200]
// Zero leaves the bottom panel undrilled.
caster_hole_diameter = 8.5; // [0:0.1:20]

/* [Machining] */
cnc_tool_diameter = 6.35; // [0.1:0.01:50]
slot_corner_relief = "dogbone"; // [none, dogbone, t_bone]
apply_kerf_compensation = false;
kerf = 0.15; // [0:0.01:10]
circle_segments = 32; // [12:4:96]

/* [Sheets and layout] */
stock_width = 2440; // [100:1:5000]
stock_height = 1220; // [100:1:5000]
layout_gap = 20; // [1:1:200]
include_shared_export_bounding_box = true;
engrave_label_size = 12; // [2:0.5:40]

/* [Output] */
output_mode = "assembly"; // [assembly, flat_3d, bom, cut_layout, pocket_layout, pocket_dados, pocket_dados_flip, engrave_layout]
/* [Hidden] */
// Test hook: render one part (ID) or CASTERS in assembly position.
render_part = "";
// Accepted for compatibility with the shared export worker.
dimension_report = "summary";
validation_report = "summary";
system_contract_report = "summary";
interface_keepout_policy = "enforce";

$fn = circle_segments;
eps = 0.01;
big = 10000;

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
ft = fin_stock == "match_carcass" ? t : stock_mm(fin_stock, custom_fin_thickness);
fit = joint_fit_clearance;
dfc = dado_fit_clearance;
dd = dado_depth;
web = minimum_joint_web;
min_tab = max(8, cnc_tool_diameter);

// Shape resolution (original names accepted).
is_custom = shape == "custom" || shape == "Custom";
is_shelf_cart = shape == "shelf_cart" || shape == "Shelf cart";
preset_stepped = shape == "stepped_bins" || shape == "Stepped bins";
stepped = bin_profile == "Auto" ? preset_stepped : bin_profile == "Stepped";
tower = is_custom ? custom_tower : is_shelf_cart ? "Right" : "None";
lower = is_custom ? custom_lower_cubbies : !is_shelf_cart;
left = tower == "Left" || tower == "Both";
right = tower == "Right" || tower == "Both";

x0 = left ? tower_width + t : 0;            // outside face of the bins' left wall
x1 = width - (right ? tower_width + t : 0); // outside face of the bins' right wall
span = x1 - x0 - 2*t;
deck = lower ? 2*t + cubby_height : t;      // top of the bins' floor
floor_part = lower ? "DECK" : "BOTTOM";
pitch = (depth - t)/rows;
col_pitch = (span + ft)/columns;
last_rise = back_flush_with_top_entrance ? rows - 1 : rows;
function row_z(i) = front_height + (rear_height - front_height)*min(i, last_rise)/rows;
function wall_y(i) = i*pitch;
function fin_x(c) = x0 + t - ft + c*col_pitch;
// Half-lap split height. Stepped fins are only as tall as the lower row in front of a
// crosspiece, so the lap is split at half that height; otherwise the fin segment in front
// of the crossing would be cut free (the original model split at half the crosspiece).
function lap_z(i) = deck + ((stepped ? min(row_z(max(i - 1, 0)), row_z(i)) : row_z(i)) - deck)/2;
function cubby_x(c) = x0 + c*(span + t)/cubby_columns;
tower_pitch = (rear_height - t)/tower_openings;
function tower_x(s) = s == "L" ? t : x1;            // left face of a tower's clear opening
function tower_outer_x(s) = s == "L" ? 0 : width - t;
function tower_shared(s) = s == "L" ? "SIDE_L" : "SIDE_R";
bin_top = row_z(rows);
body_height = (left || right) ? rear_height : bin_top;
lift = show_casters ? caster_height : 0;

// Upper edge of the bin side walls and fins, front to rear, in the YZ plane.
function upper_edge() = concat(
    [[0, front_height]],
    stepped ? [for (i=[1:1:last_rise]) each [[wall_y(i), row_z(i-1)], [wall_y(i), row_z(i)]]] :
              (last_rise > 0 ? [[wall_y(last_rise), row_z(last_rise)]] : []),
    [[depth, row_z(rows)]]);
EDGE = upper_edge();
// Lowest edge height at y (a step counts as its lower side), for corner tests.
function edge_min(y) = min(concat(
    [for (k=[0:len(EDGE)-2]) let(a=EDGE[k], b=EDGE[k+1])
        if (b[0] - a[0] > eps && y >= a[0] - eps && y <= b[0] + eps)
            a[1] + (b[1] - a[1])*min(1, max(0, (y - a[0])/(b[0] - a[0])))],
    [for (k=[0:len(EDGE)-2]) let(a=EDGE[k], b=EDGE[k+1])
        if (abs(b[0] - a[0]) <= eps && abs(y - a[0]) <= eps) min(a[1], b[1])],
    [big]));

// ---------------------------------------------------------------- parts
// [id, kind, plane, origin, W, H, thickness, material, profile_z0 (-1 = rectangle)]
// plane XY: u=X v=Y, thickness up (+Z).  XZ: u=X v=Z, thickness +Y, laid front face up.
// YZ: u=Y v=Z, thickness +X, laid +X face up.
function cross_id(i) = str("CROSS_", i + 1);
function fin_id(c) = str("FIN_", c);
function side_tall(s) = s == "L" ? left : right;
PARTS = concat(
    [["BOTTOM", "bottom_panel", "XY", [0, 0, 0], width, depth, t, "CARCASS", -1],
     ["SIDE_L", "side_wall", "YZ", [x0, 0, t], depth, (left ? rear_height : bin_top) - t, t, "CARCASS", left ? -1 : t],
     ["SIDE_R", "side_wall", "YZ", [x1 - t, 0, t], depth, (right ? rear_height : bin_top) - t, t, "CARCASS", right ? -1 : t]],
    lower ? concat(
        [["DECK", "deck", "XY", [x0 + t, 0, deck - t], span, depth, t, "CARCASS", -1],
         ["CUBBY_BACK", "cubby_back", "XZ", [x0 + t, depth - t, t], span, cubby_height, t, "CARCASS", -1]],
        cubby_columns > 1 ? [for (c=[1:cubby_columns-1])
            [str("CUBBY_DIV_", c), "cubby_divider", "YZ", [cubby_x(c), 0, t], depth - t, cubby_height, t, "CARCASS", -1]] : []) : [],
    [for (i=[0:rows]) [cross_id(i), "crosspiece", "XZ", [x0 + t, wall_y(i), deck], span, row_z(i) - deck, t, "CARCASS", -1]],
    columns > 1 ? [for (c=[1:columns-1]) [fin_id(c), "fin", "YZ", [fin_x(c), 0, deck], depth, bin_top - deck, ft, "FIN", deck]] : [],
    [for (s=["L", "R"]) if (side_tall(s)) each concat(
        [[str("TOWER_", s), "tower_wall", "YZ", [tower_outer_x(s), 0, t], depth, rear_height - t, t, "CARCASS", -1],
         [str("TOWER_", s, "_BACK"), "tower_back", "XZ", [tower_x(s), depth - t, t], tower_width, rear_height - 2*t, t, "CARCASS", -1],
         [str("TOWER_", s, "_TOP"), "tower_top", "XY", [tower_x(s), 0, rear_height - t], tower_width, depth, t, "CARCASS", -1]],
        tower_openings > 1 ? [for (k=[1:tower_openings-1])
            [str("TOWER_", s, "_SHELF_", k), "tower_shelf", "XY", [tower_x(s), 0, k*tower_pitch], tower_width, depth - t, t, "CARCASS", -1]] : [])]);
function pidx(id) = let(m=[for (k=[0:len(PARTS)-1]) if (PARTS[k][0] == id) k]) len(m) ? m[0] : -1;
function part(id) = PARTS[pidx(id)];
function is_profile(p) = p[8] >= 0;
// Top of the part's base outline at local u (rectangles: H).
function top_at(p, u) = is_profile(p) ? edge_min(u) - p[8] : p[5];
function inside_base(p, u, v) = u > eps && u < p[4] - eps && v > eps && v < top_at(p, u) - eps;

// ---------------------------------------------------------------- joints
// [host, member, family, along-axis, s0, L, cross-axis, c0, c1, normal-axis, face, dir, host_t, base segments, side]
// The member touches the host face at `face` (world, along the normal axis); dir=+1 when the
// host extends from the face in +normal, -1 when it extends in -normal. Segments are the
// stretches of the strip (0..L) where tabs or screws may go. Side 0 is the primary face of
// the host; side 1 members avoid side 0 tabs and holes.
function J(host, member, fam, a, s0, L, c, c0, c1, n, f, dir, segs, side=0) =
    [host, member, fam, a, s0, L, c, c0, c1, n, f, dir, part(host)[6], segs, side];
function full(L) = [[0, L]];
// Stepped bin walls rise only at a crosspiece: tabs stay below the step, so their receivers
// are closed holes and never sever the narrow rear post of the wall.
function wall_segs(i, tall) = (stepped && !tall && i >= 1 && row_z(i) > row_z(i - 1) + eps) ? [[0, row_z(i - 1) - deck]] : full(row_z(i) - deck);
function row_segments(y0) = [for (i=[1:rows]) [wall_y(i-1) + t - y0, wall_y(i) - y0]];
function col_segments() = [for (c=[0:columns-1])
    [(c == 0 ? x0 + t : fin_x(c) + ft) - (x0 + t), (c == columns - 1 ? x1 - t : fin_x(c + 1)) - (x0 + t)]];
function shared_dir(s) = s == "L" ? 1 : -1;   // tower members meet the shared wall from outside the bins
JOINTS = concat(
    // Crosspieces to both bin walls (Crosspiece joinery) and down to the bin floor.
    [for (i=[0:rows]) each [
        J("SIDE_L", cross_id(i), "cross", 2, deck, row_z(i) - deck, 1, wall_y(i), wall_y(i) + t, 0, x0 + t, -1, wall_segs(i, left)),
        J("SIDE_R", cross_id(i), "cross", 2, deck, row_z(i) - deck, 1, wall_y(i), wall_y(i) + t, 0, x1 - t, 1, wall_segs(i, right)),
        J(floor_part, cross_id(i), "panel", 0, x0 + t, span, 1, wall_y(i), wall_y(i) + t, 2, deck, -1, col_segments())]],
    // Fins down to the bin floor, between the crosspieces they lap.
    columns > 1 ? [for (c=[1:columns-1])
        J(floor_part, fin_id(c), "panel", 1, 0, depth, 0, fin_x(c), fin_x(c) + ft, 2, deck, -1, row_segments(0))] : [],
    // Side walls stand on the bottom panel; screwed from below.
    [J("BOTTOM", "SIDE_L", "base", 1, 0, depth, 0, x0, x0 + t, 2, t, -1, full(depth)),
     J("BOTTOM", "SIDE_R", "base", 1, 0, depth, 0, x1 - t, x1, 2, t, -1, full(depth))],
    lower ? concat(
        [J("SIDE_L", "DECK", "panel", 1, 0, depth, 2, deck - t, deck, 0, x0 + t, -1, full(depth)),
         J("SIDE_R", "DECK", "panel", 1, 0, depth, 2, deck - t, deck, 0, x1 - t, 1, full(depth)),
         J("SIDE_L", "CUBBY_BACK", "panel", 2, t, cubby_height, 1, depth - t, depth, 0, x0 + t, -1, full(cubby_height)),
         J("SIDE_R", "CUBBY_BACK", "panel", 2, t, cubby_height, 1, depth - t, depth, 0, x1 - t, 1, full(cubby_height)),
         J("BOTTOM", "CUBBY_BACK", "panel", 0, x0 + t, span, 1, depth - t, depth, 2, t, -1, full(span)),
         J("DECK", "CUBBY_BACK", "panel", 0, x0 + t, span, 1, depth - t, depth, 2, deck - t, 1, full(span), 1)],
        cubby_columns > 1 ? [for (c=[1:cubby_columns-1]) each [
            J("BOTTOM", str("CUBBY_DIV_", c), "panel", 1, 0, depth - t, 0, cubby_x(c), cubby_x(c) + t, 2, t, -1, full(depth - t)),
            J("DECK", str("CUBBY_DIV_", c), "panel", 1, 0, depth - t, 0, cubby_x(c), cubby_x(c) + t, 2, deck - t, 1, full(depth - t), 1)]] : []) : [],
    // Towers: shelves, cap and back are housed in the outer wall (primary face) and the
    // shared bin wall (secondary face); the tower walls and back stand on the bottom panel.
    [for (s=["L", "R"]) if (side_tall(s)) let(
        ow = str("TOWER_", s), sh = tower_shared(s), tx = tower_x(s),
        of = s == "L" ? t : width - t, odir = s == "L" ? -1 : 1,
        sf = s == "L" ? x0 : x1, sdir = shared_dir(s)) each concat(
        [J("BOTTOM", ow, "base", 1, 0, depth, 0, tower_outer_x(s), tower_outer_x(s) + t, 2, t, -1, full(depth)),
         J("BOTTOM", str(ow, "_BACK"), "base", 0, tx, tower_width, 1, depth - t, depth, 2, t, -1, full(tower_width)),
         J(ow, str(ow, "_BACK"), "panel", 2, t, rear_height - 2*t, 1, depth - t, depth, 0, of, odir, full(rear_height - 2*t)),
         J(sh, str(ow, "_BACK"), "panel", 2, t, rear_height - 2*t, 1, depth - t, depth, 0, sf, sdir, full(rear_height - 2*t), 1),
         J(ow, str(ow, "_TOP"), "panel", 1, 0, depth, 2, rear_height - t, rear_height, 0, of, odir, full(depth)),
         J(sh, str(ow, "_TOP"), "panel", 1, 0, depth, 2, rear_height - t, rear_height, 0, sf, sdir, full(depth), 1)],
        tower_openings > 1 ? [for (k=[1:tower_openings-1]) each [
            J(ow, str(ow, "_SHELF_", k), "panel", 1, 0, depth - t, 2, k*tower_pitch, k*tower_pitch + t, 0, of, odir, full(depth - t)),
            J(sh, str(ow, "_SHELF_", k), "panel", 1, 0, depth - t, 2, k*tower_pitch, k*tower_pitch + t, 0, sf, sdir, full(depth - t), 1)]] : [])]);

// Joint style. Walls stand on the bottom panel and arrive sideways, so they are screwed
// from below (glued only when panel joinery is butt).
function jstyle(j) = j[2] == "cross" ? joinery_style :
                     j[2] == "panel" ? panel_joinery :
                     panel_joinery == "butt" ? "butt" : "screw";
function through(j) = jstyle(j) == "tab_slot" || jstyle(j) == "screw";

// Interval helpers (lists of [a, b]).
function cut_interval(segs, p, q) = [for (s=segs) each
    (q <= s[0] || p >= s[1]) ? [s] : concat(p > s[0] ? [[s[0], p]] : [], q < s[1] ? [[q, s[1]]] : [])];
function cut_all(segs, list, k=0) = k >= len(list) ? segs : cut_all(cut_interval(segs, list[k][0], list[k][1]), list, k + 1);
function seg_tabs(a, b) = let(
    len_ = b - a, m = min(tab_edge_margin, len_*0.25), use = len_ - 2*m,
    n0 = max(1, round(use/tab_spacing)), nweb = floor((use + web)/(tab_length + web)),
    n = use >= min_tab ? max(1, min(n0, nweb)) : 0,
    w = n > 0 ? min(tab_length, (use - (n - 1)*web)/n) : 0)
    (n < 1 || w < min_tab) ? [] : [for (k=[0:n-1]) let(cc = a + m + use*(k + 0.5)/n) [cc - w/2, cc + w/2]];
// Projection of a host-plane rectangle [[a0,a1],[c0,c1]] (world, along/cross axes of j) onto j's strip.
function rect_on(j, r) = (r[1][1] > j[7] + eps && r[1][0] < j[8] - eps) ? [[r[0][0] - j[4], r[0][1] - j[4]]] : [];
// Through features of joint k in world [[along..],[cross..]] of joint j's axes.
function k_rects(j, k, tabs) = j[3] == k[3] ?
        [for (q=tabs) [[k[4] + q[0] - fit/2, k[4] + q[1] + fit/2], [k[7] - fit/2, k[8] + fit/2]]] :
        [for (q=tabs) [[k[7] - fit/2, k[8] + fit/2], [k[4] + q[0] - fit/2, k[4] + q[1] + fit/2]]];
function k_band(j, k) = j[3] == k[3] ? [[k[4], k[4] + k[5]], [k[7] - dfc/2, k[8] + dfc/2]] :
                                        [[k[7] - dfc/2, k[8] + dfc/2], [k[4], k[4] + k[5]]];
function same_host(j) = [for (k=JOINTS) if (k[0] == j[0] && k[14] != j[14]) k];
function widen(list) = [for (r=list) [r[0] - web, r[1] + web]];
// Free stretches. Primary-face joints use their own segments (dados run the full strip).
// Secondary-face joints yield: they skip the primary face's receivers and holes, and their
// through features also skip the primary face's dado grooves (dado against dado is fine,
// because every dado is shallower than half the stock).
function base_segs(j) = jstyle(j) == "dado" ? full(j[5]) : j[13];
function segs(j) = j[14] == 0 ? base_segs(j) :
    [for (s=cut_all(base_segs(j), widen(concat(
        [for (k=same_host(j)) if (through(k)) each [for (r=k_rects(j, k, tabs(k))) each rect_on(j, r)]],
        [for (k=same_host(j)) if (through(j) && jstyle(k) == "dado") each rect_on(j, k_band(j, k))]))))
        if (s[1] - s[0] >= min_tab) s];
function tabs(j) = [for (s=segs(j)) if (s[1] - s[0] > 0) each seg_tabs(s[0], s[1])];

// Axis-aligned world box from along/cross/normal ranges.
function wbox(j, ar, cr, nr) = [for (ax=[0:2]) ax == j[3] ? ar : ax == j[6] ? cr : nr];
function into(j, depth_, extra=0) = j[11] > 0 ? [j[10] - extra, j[10] + depth_] : [j[10] - depth_, j[10] + extra];
// Features: [part, type, box, diameter, relief]. Types: add, slot, pocket, hole.
function joint_features(j) = let(st = jstyle(j), ts = (st == "tab_slot" || st == "screw") ? tabs(j) : [])
    st == "tab_slot" ? [for (q=ts) each [
        [j[1], "add", wbox(j, [j[4] + q[0], j[4] + q[1]], [j[7], j[8]], into(j, j[12])), 0, false],
        [j[0], "slot", wbox(j, [j[4] + q[0] - fit/2, j[4] + q[1] + fit/2], [j[7] - fit/2, j[8] + fit/2], into(j, j[12] + eps, eps)), 0, true]]] :
    st == "dado" ? [for (q=segs(j)) each [
        [j[1], "add", wbox(j, [j[4] + q[0], j[4] + q[1]], [j[7], j[8]], into(j, dd)), 0, false],
        [j[0], "pocket", wbox(j, [j[4] + q[0], j[4] + q[1]], [j[7] - dfc/2, j[8] + dfc/2], into(j, dd, eps)), 0, true]]] :
    st == "screw" ? [for (q=ts) let(ac = j[4] + (q[0] + q[1])/2, cc = (j[7] + j[8])/2)
        [j[0], "hole", wbox(j, [ac, ac], [cc, cc], into(j, j[12] + eps, eps)), screw_clearance_diameter, false]] : [];
// Opposing half-laps: crosspieces are slotted from the top, fins from below.
LAPS = columns > 1 ? [for (i=[0:rows]) for (c=[1:columns-1]) each [
    [cross_id(i), "slot", [[fin_x(c) - fit/2, fin_x(c) + ft + fit/2], [wall_y(i) - eps, wall_y(i) + t + eps], [lap_z(i), big]], 0, true],
    [fin_id(c), "slot", [[fin_x(c) - eps, fin_x(c) + ft + eps], [wall_y(i) - fit/2, wall_y(i) + t + fit/2], [-big, lap_z(i) + fit/2]], 0, true]]] : [];
function caster_xy() = [for (x=[caster_inset, width - caster_inset]) for (y=[caster_inset, depth - caster_inset]) [x, y]];
CASTER_HOLES = show_casters && caster_hole_diameter > 0 ? [for (p=caster_xy()) for (sx=[-1, 1]) for (sy=[-1, 1])
    let(hx = p[0] + sx*caster_hole_spacing_x/2, hy = p[1] + sy*caster_hole_spacing_y/2)
    ["BOTTOM", "hole", [[hx, hx], [hy, hy], [-eps, t + eps]], caster_hole_diameter, false]] : [];
FEATURES = concat([for (j=JOINTS) each joint_features(j)], LAPS, CASTER_HOLES);

// ---------------------------------------------------------------- local frames
// World box -> local [u0,u1,v0,v1,w0,w1] of part p (w across the thickness, top face w=th).
function local_box(p, b) = let(o=p[3], th=p[6])
    p[2] == "XY" ? [b[0][0] - o[0], b[0][1] - o[0], b[1][0] - o[1], b[1][1] - o[1], b[2][0] - o[2], b[2][1] - o[2]] :
    p[2] == "XZ" ? [b[0][0] - o[0], b[0][1] - o[0], b[2][0] - o[2], b[2][1] - o[2], th - (b[1][1] - o[1]), th - (b[1][0] - o[1])] :
                   [b[1][0] - o[1], b[1][1] - o[1], b[2][0] - o[2], b[2][1] - o[2], b[0][0] - o[0], b[0][1] - o[0]];
function part_features(id, type) = [for (f=FEATURES) if (f[0] == id && f[1] == type) f];
function is_through(p, lb) = lb[4] <= eps && lb[5] >= p[6] - eps;
// Pockets by face: 1 = top face (w = th), 0 = bottom face.
function pocket_face(p, lb) = lb[5] >= p[6] - eps ? 1 : 0;
function face_pockets(p, face) = [for (f=part_features(p[0], "pocket")) let(lb=local_box(p, f[2])) if (!is_through(p, lb) && pocket_face(p, lb) == face) [lb, f]];
// Lay a part mirrored when its only pockets are on the bottom face, so pockets face up.
function flipped(p) = len(face_pockets(p, 1)) == 0 && len(face_pockets(p, 0)) > 0;
function two_sided(p) = len(face_pockets(p, 1)) > 0 && len(face_pockets(p, 0)) > 0;
// 2D extents of base plus added tabs/tongues.
function adds(p) = [for (f=part_features(p[0], "add")) local_box(p, f[2])];
function ext(p) = let(a=adds(p), top=is_profile(p) ? max([for (q=EDGE) q[1]]) - p[8] : p[5])
    [min(concat([0], [for (b=a) b[0]])), max(concat([p[4]], [for (b=a) b[1]])),
     min(concat([0], [for (b=a) b[2]])), max(concat([top], [for (b=a) b[3]]))];
function cut_w(p) = let(e=ext(p)) e[1] - e[0];
function cut_h(p) = let(e=ext(p)) e[3] - e[2];

// ---------------------------------------------------------------- 2D geometry
relief_on = slot_corner_relief != "none" && cnc_tool_diameter > 0;
module relief(p, u0, u1, v0, v1) {
    r = cnc_tool_diameter/2;
    w = u1 - u0; h = v1 - v0;
    if (relief_on) for (cu=[0, 1]) for (cv=[0, 1]) {
        u = cu == 0 ? u0 : u1; v = cv == 0 ? v0 : v1;
        su = cu == 0 ? 1 : -1; sv = cv == 0 ? 1 : -1;
        if (inside_base(p, u, v))
            translate(slot_corner_relief == "dogbone" ? [u + su*r/sqrt(2), v + sv*r/sqrt(2)] :
                      w >= h ? [u + su*r, v] : [u, v + sv*r])
                circle(r=r);
    }
}
module cut_rect(p, lb, with_relief) {
    translate([lb[0], lb[2]]) square([lb[1] - lb[0], lb[3] - lb[2]]);
    if (with_relief) relief(p, lb[0], lb[1], lb[2], lb[3]);
}
module base_2d(p) {
    if (is_profile(p)) polygon(concat([[0, 0], [p[4], 0]], [for (k=[len(EDGE)-1:-1:0]) [EDGE[k][0], EDGE[k][1] - p[8]]]));
    else square([p[4], p[5]]);
}
// Finished through-cut profile in local coordinates.
module part_2d(p) {
    difference() {
        union() {
            base_2d(p);
            for (b=adds(p)) translate([b[0], b[2]]) square([b[1] - b[0], b[3] - b[2]]);
        }
        for (f=part_features(p[0], "slot")) let(lb=local_box(p, f[2])) cut_rect(p, lb, f[4]);
        for (f=part_features(p[0], "pocket")) let(lb=local_box(p, f[2])) if (is_through(p, lb)) cut_rect(p, lb, f[4]);
        for (f=part_features(p[0], "hole")) let(lb=local_box(p, f[2])) translate([lb[0], lb[2]]) circle(d=f[3]);
    }
}
module pockets_2d(p, face) {
    // Clipped to the part, so every pocket contour lies inside the part's cut rectangle.
    intersection() {
        union() for (q=face_pockets(p, face)) cut_rect(p, q[0], q[1][4]);
        part_2d(p);
    }
}

// ---------------------------------------------------------------- 3D
function frame(p) = p[2] == "XY" ? [[1,0,0,p[3][0]], [0,1,0,p[3][1]], [0,0,1,p[3][2]], [0,0,0,1]] :
                    p[2] == "XZ" ? [[1,0,0,p[3][0]], [0,0,-1,p[3][1] + p[6]], [0,1,0,p[3][2]], [0,0,0,1]] :
                                   [[0,0,1,p[3][0]], [1,0,0,p[3][1]], [0,1,0,p[3][2]], [0,0,0,1]];
module part_3d(p) {
    multmatrix(frame(p)) difference() {
        linear_extrude(p[6]) part_2d(p);
        for (face=[0, 1]) for (q=face_pockets(p, face)) let(lb=q[0])
            translate([0, 0, lb[4]]) linear_extrude(lb[5] - lb[4]) cut_rect(p, lb, q[1][4]);
    }
}
COLORS = [["bottom_panel", [0.72, 0.56, 0.37]], ["side_wall", [0.82, 0.68, 0.47]], ["tower_wall", [0.82, 0.68, 0.47]],
          ["crosspiece", [0.82, 0.68, 0.47]], ["fin", [0.91, 0.79, 0.59]], ["deck", [0.91, 0.79, 0.59]],
          ["cubby_back", [0.82, 0.68, 0.47]], ["cubby_divider", [0.91, 0.79, 0.59]], ["tower_back", [0.78, 0.64, 0.44]],
          ["tower_shelf", [0.91, 0.79, 0.59]], ["tower_top", [0.91, 0.79, 0.59]]];
function color_of(kind) = [for (c=COLORS) if (c[0] == kind) c[1]][0];
module caster(x, y) {
    h = caster_height;
    color([0.18, 0.18, 0.20]) translate([x, y, 0.34*h]) rotate([0, 90, 0]) cylinder(r=0.34*h, h=0.29*h, center=true);
    color([0.45, 0.46, 0.48]) {
        for (s=[-1, 1]) translate([x + s*0.185*h - 0.04*h, y - 0.12*h, 0.34*h]) cube([0.08*h, 0.24*h, 0.51*h]);
        translate([x - 0.27*h, y - 0.27*h, 0.85*h]) cube([0.54*h, 0.54*h, 0.15*h]);
    }
}
module assembly() {
    for (p=PARTS) if (render_part == "" || render_part == p[0])
        color(color_of(p[1])) translate([0, 0, lift]) part_3d(p);
    if (show_casters && (render_part == "" || render_part == "CASTERS")) for (c=caster_xy()) caster(c[0], c[1]);
}

// ---------------------------------------------------------------- flat layout
// Parts fill rows no wider than the stock sheet (or the widest part), layout_gap apart.
row_limit = max(stock_width, max([for (p=PARTS) cut_w(p)]));
function pack(i=0, x=0, y=0, rowh=0, acc=[]) = i >= len(PARTS) ? acc :
    let(w = cut_w(PARTS[i]), h = cut_h(PARTS[i]), nr = x > 0 && x + w > row_limit,
        nx = nr ? 0 : x, ny = nr ? y + rowh + layout_gap : y, nh = nr ? h : max(rowh, h))
    pack(i + 1, nx + w + layout_gap, ny, nh, concat(acc, [[nx, ny]]));
PLACES = pack();
LW = max([for (k=[0:len(PARTS)-1]) PLACES[k][0] + cut_w(PARTS[k])]);
LH = max([for (k=[0:len(PARTS)-1]) PLACES[k][1] + cut_h(PARTS[k])]);
module laid(k) {
    p = PARTS[k]; e = ext(p);
    translate(PLACES[k]) if (flipped(p)) translate([e[1] - e[0], 0]) mirror([1, 0]) translate([-e[0], -e[2]]) children();
    else translate([-e[0], -e[2]]) children();
}
// Bottom-face pockets, drawn where they sit after the part is turned over left to right.
module laid_flip(k) {
    p = PARTS[k]; e = ext(p);
    translate(PLACES[k]) if (flipped(p)) translate([-e[0], -e[2]]) children();
    else translate([e[1] - e[0], 0]) mirror([1, 0]) translate([-e[0], -e[2]]) children();
}
module export_frame() {
    if (include_shared_export_bounding_box) {
        m = layout_gap;
        difference() {
            translate([-m - 0.5, -m - 0.5]) square([LW + 2*m + 1, LH + 2*m + 1]);
            translate([-m, -m]) square([LW + 2*m, LH + 2*m]);
        }
    }
}
module kerf_compensated() {
    if (apply_kerf_compensation && kerf > 0) offset(delta=kerf/2) children(); else children();
}
module cut_layout() {
    export_frame();
    for (k=[0:len(PARTS)-1]) laid(k) kerf_compensated() part_2d(PARTS[k]);
}
module pocket_layout(which) {
    export_frame();
    for (k=[0:len(PARTS)-1]) let(p=PARTS[k]) {
        up = flipped(p) ? 0 : 1;
        if (which != "flip" && len(face_pockets(p, up))) laid(k) pockets_2d(p, up);
        if (which == "flip" && len(face_pockets(p, 1 - up))) laid_flip(k) pockets_2d(p, 1 - up);
    }
}
module engrave_layout() {
    export_frame();
    for (k=[0:len(PARTS)-1]) let(p=PARTS[k], w=cut_w(p), h=cut_h(p),
            s=min(engrave_label_size, h/4, w/(0.75*len(p[0]) + 1)))
        translate(PLACES[k] + [w/2, h/2]) text(p[0], size=s, halign="center", valign="center");
}
module flat_3d() {
    for (k=[0:len(PARTS)-1]) let(p=PARTS[k], up=flipped(p) ? 0 : 1) translate(PLACES[k]) difference() {
        linear_extrude(p[6]) laid_local(p) part_2d(p);
        // Pockets on the face that is up are cut from the top, the others from below.
        for (face=[0, 1]) for (q=face_pockets(p, face)) let(lb=q[0], d=lb[5] - lb[4])
            translate([0, 0, face == up ? p[6] - d : -eps]) linear_extrude(d + eps) laid_local(p) cut_rect(p, lb, q[1][4]);
    }
}
module laid_local(p) {
    e = ext(p);
    if (flipped(p)) translate([e[1] - e[0], 0]) mirror([1, 0]) translate([-e[0], -e[2]]) children();
    else translate([-e[0], -e[2]]) children();
}

// ---------------------------------------------------------------- checks and reports
module check(ok, code, msg) { if (!ok) echo(str("CHECK|ERROR|", code, "|", msg)); }
module warn(ok, code, msg) { if (!ok) echo(str("CHECK|WARN|", code, "|", msg)); }
function good_count(n, lo, hi) = n >= lo && n <= hi && floor(n) == n;
function any_style(s) = joinery_style == s || panel_joinery == s;
function rects_overlap(a, b) = a[0] < b[0] + b[2] - 0.001 && b[0] < a[0] + a[2] - 0.001 && a[1] < b[1] + b[3] - 0.001 && b[1] < a[1] + a[3] - 0.001;
module validate() {
    check(t > 0 && t <= 50, "CARCASS_STOCK", "Carcass stock must be a listed preset or a measured thickness from 1 to 50 mm.");
    check(ft > 0 && ft <= 50, "FIN_STOCK", "Fin stock must be a listed preset or a measured thickness from 1 to 50 mm.");
    for (s=[joinery_style, panel_joinery]) check(s == "butt" || s == "screw" || s == "dado" || s == "tab_slot", "JOINERY", str("Unknown joinery ", s, "."));
    check(slot_corner_relief == "none" || slot_corner_relief == "dogbone" || slot_corner_relief == "t_bone", "SLOT_RELIEF", "Corner relief must be none, dogbone or t_bone.");
    check(good_count(rows, 1, 12) && good_count(columns, 1, 12), "BIN_COUNT", "Rows and columns must be whole numbers from 1 to 12.");
    check(fit >= 0 && fit < min(t, ft)/2, "FIT_CLEARANCE", "Joint fit clearance must be at least 0 and less than half the thinner stock.");
    check(pitch - t >= 20, "BIN_DEPTH", str("Each bin needs at least 20 mm clear front to back; this grid leaves ", pitch - t, " mm."));
    check(col_pitch - ft >= 20, "BIN_WIDTH", str("Each bin needs at least 20 mm clear width; this grid leaves ", col_pitch - ft, " mm."));
    check(front_height - deck >= max(2*t, 30), "FRONT_HEIGHT", "The front crosspiece needs at least twice the stock thickness (and 30 mm) above the bin floor.");
    check(rear_height >= front_height, "REAR_HEIGHT", "Rear height must be at least the front height.");
    check(!lower || (cubby_height >= 40 && good_count(cubby_columns, 1, 12) && (span + t)/cubby_columns - t >= 40), "CUBBIES", "Lower cubbies need at least 40 mm clear height and width.");
    check(!(left || right) || (tower_width >= 60 && good_count(tower_openings, 1, 12) && tower_pitch - t >= 40), "TOWER", "Tower openings need at least 60 mm clear width and 40 mm clear height.");
    check(span >= 60, "BIN_SPAN", "The towers leave too little width for the bins.");
    if (any_style("dado")) {
        check(dd > 0 && dd < t/2, "DADO_DEPTH", "Dados must be shallower than half the carcass stock, so grooves on both faces of a wall or the deck never meet.");
        check(dfc >= 0 && dfc < t/2, "DADO_FIT", "Dado fit clearance must be at least 0 and less than half the stock.");
    }
    if (any_style("screw") || panel_joinery != "butt") {
        check(screw_pilot_diameter > 0 && screw_clearance_diameter >= screw_pilot_diameter && screw_clearance_diameter < min(t, ft) - 2, "SCREW_SIZE", "Screw clearance must be at least the pilot size and at least 2 mm smaller than the stock it enters.");
        check(screw_pilot_depth > 0, "SCREW_PILOT", "Pilot depth must be positive.");
        warn(screw_clearance_diameter >= cnc_tool_diameter, "DRILL_HOLES", str(screw_clearance_diameter, " mm screw holes are smaller than the ", cnc_tool_diameter, " mm cutter: drill them or use a smaller cutter."));
    }
    check(min(t, ft) + fit >= cnc_tool_diameter || columns == 1 && !any_style("tab_slot"), "SLOT_WIDTH", str("Slots ", min(t, ft) + fit, " mm wide are narrower than the ", cnc_tool_diameter, " mm cutter."));
    check(tab_length >= min_tab, "TAB_LENGTH", str("Tabs must be at least ", min_tab, " mm long (the cutter diameter, or 8 mm)."));
    // Every primary joint keeps at least one tab or screw. A secondary joint (a tower part on
    // the shared wall, a cubby part under the deck) that has no room left is glued only.
    for (j=JOINTS) if ((through(j) && len(tabs(j)) == 0) || (jstyle(j) == "dado" && len(segs(j)) == 0))
        echo(str(j[14] == 0 ? "CHECK|ERROR|NO_ROOM_FOR_TABS|" : "CHECK|WARN|GLUED_ONLY|", j[1], " to ", j[0], ": no room for ",
                 jstyle(j) == "screw" ? "a screw" : jstyle(j) == "dado" ? "a dado" : "a tab",
                 j[14] == 0 ? ". Make the part longer or change the joinery." : " beside the joints on the other face; this joint is glued only."));
    // Caster bolt holes must stay clear of every panel standing on the bottom.
    for (h=CASTER_HOLES) for (j=JOINTS) if (j[0] == "BOTTOM") let(r=caster_hole_diameter/2, x=h[2][0][0], y=h[2][1][0],
            box=wbox(j, [j[4], j[4] + j[5]], [j[7], j[8]], [0, 0]))
        check(x + r <= box[0][0] || x - r >= box[0][1] || y + r <= box[1][0] || y - r >= box[1][1], "CASTER_HOLE",
              str("A caster bolt hole at ", x, ", ", y, " lands under ", j[1], "; change the caster inset or hole spacing."));
    check(!show_casters || (caster_inset - max(caster_hole_spacing_x, caster_hole_spacing_y)/2 - caster_hole_diameter/2 >= 5 && 2*caster_inset < min(width, depth)), "CASTER_FIT", "Caster plates must sit inside the bottom panel.");
    check(layout_gap > 0, "LAYOUT_OVERLAP", str("layout_gap is ", layout_gap, " mm; parts of the flat cut layout would overlap."));
    warn(layout_gap >= cnc_tool_diameter, "LAYOUT_GAP", "The layout gap is narrower than the cutter.");
    for (p=PARTS) warn(min(cut_w(p), cut_h(p)) <= min(stock_width, stock_height) && max(cut_w(p), cut_h(p)) <= max(stock_width, stock_height),
        "SHEET_SIZE", str(p[0], " (", cut_w(p), " x ", cut_h(p), " mm) is larger than the ", stock_width, " x ", stock_height, " mm sheet."));
    two = [for (p=PARTS) if (two_sided(p)) p[0]];
    if (len(two)) echo(str("CHECK|WARN|TWO_SIDED|", len(two), " part(s) have dados on both faces (", two[0], len(two) > 1 ? " and others" : "", "): machine pocket_dados, turn the part over left to right, then machine pocket_dados_flip."));
    warn(body_height + lift <= 2.2*depth, "TIP_REVIEW", "The cart is more than 2.2 times taller than it is deep; check stability before loading the top bins.");
    for (a=[0:len(PARTS)-2]) for (b=[a+1:len(PARTS)-1])
        check(!rects_overlap([PLACES[a][0], PLACES[a][1], cut_w(PARTS[a]), cut_h(PARTS[a])], [PLACES[b][0], PLACES[b][1], cut_w(PARTS[b]), cut_h(PARTS[b])]),
              "LAYOUT_OVERLAP", str(PARTS[a][0], " overlaps ", PARTS[b][0], " in the flat cut layout."));
    echo("CHECK|INFO|VALIDATION_SCOPE|Geometric and manufacturing checks only; no load rating, stability or CAM verification.");
}
function joint_count(style) = len([for (j=JOINTS) if (jstyle(j) == style) j]);
module reports() {
    validate();
    echo(str("DIM|CABINET|OUTSIDE|W=", width, "|H=", body_height + lift, "|D=", depth));
    echo(str("DIM|MEDIA_CART|BODY|W=", width, "|H=", body_height, "|D=", depth, "|CASTER_H=", lift, "|SHAPE=", shape, "|PROFILE=", stepped ? "stepped" : "sloped", "|TOWER=", tower, "|CUBBIES=", lower ? "yes" : "no"));
    echo(str("DIM|MEDIA_CART|BINS|ROWS=", rows, "|COLUMNS=", columns, "|CLEAR_W=", col_pitch - ft, "|CLEAR_D=", pitch - t, "|FLOOR_Z=", deck, "|FRONT_ENTRANCE_Z=", row_z(0)));
    for (i=[1:rows]) echo(str("DIM|MEDIA_CART|ROW|R", i, "|FRONT_WALL_Z=", row_z(i - 1), "|BACK_WALL_Z=", row_z(i), "|DEPTH_FROM_ENTRANCE=", row_z(i - 1) - deck));
    if (lower) echo(str("DIM|MEDIA_CART|CUBBIES|COLUMNS=", cubby_columns, "|CLEAR_W=", (span + t)/cubby_columns - t, "|CLEAR_H=", cubby_height, "|CLEAR_D=", depth - t));
    if (left || right) echo(str("DIM|MEDIA_CART|TOWER|SIDES=", tower, "|CLEAR_W=", tower_width, "|OPENINGS=", tower_openings, "|OPENING_H=", tower_pitch - t, "|SHELF_D=", depth - t));
    echo(str("DIM|MEDIA_CART|JOINERY|CROSSPIECES=", joinery_style, "|PANELS=", panel_joinery, "|FIT=", fit, "|DADO_DEPTH=", dd, "|RELIEF=", relief_on ? slot_corner_relief : "none", "|CUTTER=", cnc_tool_diameter));
    // Machining notes for the operation being exported (shown with each layout).
    if (output_mode == "cut_layout") echo("OPERATION|cut_layout|Through cuts, full stock thickness: part outlines, slots, half-laps, tab receivers and holes. Parts are laid as listed in the BOM notes.");
    if (output_mode == "pocket_layout" || output_mode == "pocket_dados") echo(str("OPERATION|", output_mode, "|Pockets ", dd, " mm deep on the face that is up in the cut layout (dados for housed panels)."));
    if (output_mode == "pocket_dados_flip") echo(str("OPERATION|pocket_dados_flip|Pockets ", dd, " mm deep on the other face: after the up-face pass, turn each two-sided part over left to right within its own place in the layout (same bounding box) and register on the frame."));
    if (output_mode == "engrave_layout") echo("OPERATION|engrave_layout|Part labels on the face that is up; shallow engrave or marker only, not a through cut.");
    if (output_mode == "bom") {
        for (p=PARTS) let(up = flipped(p) ? 0 : 1, pk = len(face_pockets(p, up)) + len(face_pockets(p, 1 - up)))
            echo(str("BOM|", p[0], "|1|", p[1], "|", p[7], "|", p[6], "|", cut_w(p), "|", cut_h(p), "|",
                     flipped(p) ? "laid inner face up" : "as drawn",
                     pk ? str("; dados ", dd, " mm deep", two_sided(p) ? " on both faces" : "") : ""));
        for (k=[0:len(PARTS)-1]) echo(str("PLACE|", PARTS[k][0], "|X=", PLACES[k][0], "|Y=", PLACES[k][1], "|W=", cut_w(PARTS[k]), "|H=", cut_h(PARTS[k])));
        screws = len([for (f=FEATURES) if (f[1] == "hole") f]) - len(CASTER_HOLES);
        if (screws > 0) echo(str("HARDWARE|ID=screws|QTY=", screws, "|UNIT=each|NOTE=countersunk wood screws; clearance ", screw_clearance_diameter, " mm, pilot ", screw_pilot_diameter, " mm x ", screw_pilot_depth, " mm drilled into the panel edge at assembly"));
        if (show_casters) echo(str("HARDWARE|ID=casters|QTY=4|UNIT=each|NOTE=plate casters, ", caster_height, " mm floor to plate; two with brakes recommended"));
        if (show_casters && caster_hole_diameter > 0) echo(str("HARDWARE|ID=caster_bolts|QTY=16|UNIT=each|NOTE=bolts with washers and nuts through ", caster_hole_diameter, " mm holes"));
        echo("HARDWARE|ID=glue|QTY=1|UNIT=bottle|NOTE=wood glue for every joint");
    }
}

reports();
if (output_mode == "assembly") assembly();
else if (output_mode == "flat_3d") flat_3d();
else if (output_mode == "cut_layout") cut_layout();
else if (output_mode == "pocket_layout" || output_mode == "pocket_dados") pocket_layout("up");
else if (output_mode == "pocket_dados_flip") pocket_layout("flip");
else if (output_mode == "engrave_layout") engrave_layout();
