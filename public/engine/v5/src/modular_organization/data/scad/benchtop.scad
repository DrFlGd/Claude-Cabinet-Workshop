// Modular Organization: benchtop — source entrypoint; units mm.
/* [Materials / Stock] */

// NOMINAL presets are convenient starting points. Plywood commonly measures
// thinner than its nominal inch size, so use custom for final production.

carcass_stock = "3/8_nominal"; // [1/4_nominal, 3/8_nominal, 1/2_nominal, custom]

drawer_stock = "1/4_nominal"; // [same_as_carcass, 1/4_nominal, 3/8_nominal, 1/2_nominal, custom]

drawer_bottom_stock = "1/8_nominal"; // [1/8_nominal, 1/4_nominal, same_as_drawer, custom]

drawer_front_stock = "same_as_carcass"; // [same_as_carcass, 1/4_nominal, 3/8_nominal, 1/2_nominal, custom]

back_stock = "1/8_nominal"; // [1/8_nominal, 1/4_nominal, custom]

drawer_divider_stock = "custom_mm"; // [custom_mm, 1/8_nominal, 1/4_nominal, 3/8_nominal, 1/2_nominal, 5/8_nominal, 3/4_nominal]

/* [Materials / Measured Thickness] */

custom_carcass_thickness = 9.50; // [0.01:0.01:100]

custom_drawer_material_thickness = 6.35; // [0.01:0.01:100]

custom_drawer_bottom_thickness = 3.00; // [0.01:0.01:100]

custom_drawer_front_thickness = 9.50; // [0.01:0.01:100]

custom_back_thickness = 3.00; // [0.01:0.01:100]

/* [Hidden] */
material_thickness =
    carcass_stock == "1/4_nominal" ? 6.35 :
    carcass_stock == "3/8_nominal" ? 9.525 :
    carcass_stock == "1/2_nominal" ? 12.7 :
    custom_carcass_thickness; // [0.01:0.01:100]

/* [Materials / Measured Thickness] */

// Doors are unused in this focused drawers-only branch.
door_thickness = material_thickness; // [0.01:0.01:100]

custom_drawer_divider_thickness = 6.00; // [0.01:0.01:100]

// Fixed lower rail attached to the cabinet side.

// Matching upper runner attached to the outside of each drawer side.
// Its underside rides on the top surface of the fixed rail.

/* [Machining / Tool and Kerf] */

// Circle/cylinder smoothness. Mostly affects round drill holes and CNC corner relief.
circle_segments = 48; // [12:4:96]

cnc_tool_diameter = 3.175;

apply_kerf_compensation = false;

kerf = 0.15;

/* [Machining / Shared Slot Relief] */

// 1/8 in end mill is a common small-cabinet CNC starting point.
slot_corner_relief = "none"; // [none, dogbone, t_bone]

/* [Machining / Frame Joints] */

// Relief for this material only. Inherit preserves the shared setting.
carcass_slot_corner_relief = "inherit"; // [inherit,none,dogbone,t_bone]
// Cutter diameter in mm. Zero inherits the shared cutter diameter.
carcass_cnc_tool_diameter = 0; // [0:0.01:50]


// Total added clearance around TAB/SLOT joints relative to the mating part.
// Positive values make the joint looser. Start small and cut a test coupon.
joint_fit_clearance = 0.15; // [0:0.05:2]

// Independent clearance for CARCASS dados.
// This changes pocket width/length around the mating panel, not dado depth.
dado_fit_clearance = 0.15; // [0:0.05:2]

// Dado depth scales with the thinner benchtop carcass stock.
// auto is intentionally conservative: about 38% of actual sheet thickness.
dado_depth_mode = "auto"; // [auto, custom]

custom_dado_depth = 3;

/* [Machining / Drawer Joints] */

// Relief for this material only. Inherit preserves the shared setting.
drawer_slot_corner_relief = "inherit"; // [inherit,none,dogbone,t_bone]
// Cutter diameter in mm. Zero inherits the shared cutter diameter.
drawer_cnc_tool_diameter = 0; // [0:0.01:50]


// Drawer tab/slot clearance is independent from the carcass.
drawer_joint_fit_clearance = 0.15; // [0:0.05:2]

// Drawer dado clearance is independent as well. It applies to both
// front/back-to-side dados and optional drawer-bottom grooves.
drawer_dado_fit_clearance = 0.15; // [0:0.05:2]

// Shallow drawer dados are safer in 1/4 in stock.
drawer_dado_depth_mode = "auto"; // [auto, custom]

custom_drawer_dado_depth = 2;

drawer_bottom_dado_depth_mode = "auto"; // [auto, custom]

custom_drawer_bottom_dado_depth = 1.5;

/* [Machining / Divider Grooves] */

// Relief for this material only. Inherit preserves the shared setting.
drawer_bottom_slot_corner_relief = "none"; // [inherit,none,dogbone,t_bone]
// Cutter diameter in mm. Zero inherits the shared cutter diameter.
drawer_bottom_cnc_tool_diameter = 0; // [0:0.01:50]


// Relief for this material only. Inherit preserves the shared setting.
divider_slot_corner_relief = "inherit"; // [inherit,none,dogbone,t_bone]
// Cutter diameter in mm. Zero inherits the shared cutter diameter.
divider_cnc_tool_diameter = 0; // [0:0.01:50]


// Positive values widen the receiving grooves/slits relative to measured stock.
drawer_divider_groove_clearance = 0.20; // [0:0.05:2]

drawer_divider_interlock_clearance = 0.20; // [0:0.05:2]

// Blind-pocket depths from the drawer's inside faces.
drawer_divider_bottom_groove_depth = 2.5;

drawer_divider_perimeter_groove_depth = 3;

/* [Sizing / Envelope] */

// Direct drawers-only benchtop configuration.
cabinet_width = 320;

cabinet_height = 320;

cabinet_depth = 280;

/* [Sizing / Fit Targets] */

// Choose whether each horizontal axis is controlled by the outside cabinet
// envelope or solved backward from the required finished drawer interior.
width_basis = "outside"; // [outside, drawer_inside]

depth_basis = "outside"; // [outside, drawer_inside]

// "minimum" only grows an undersized cabinet; it never shrinks an existing
// outside envelope. "exact" resizes the cabinet to hit the requested finished
// drawer interior as closely as the construction rules allow.
target_dimension_policy = "minimum"; // [minimum, exact]

// direct       = use the target interior dimensions below.
// modular_grid = derive the target from pitch x module count + edge clearance.
target_dimension_mode = "direct"; // [direct, modular_grid]

// 1-based drawer-bank / mixed-bay slot whose clear width is used for solving.
// In ordinary single-bank cabinets leave this at 1.
target_drawer_bank = 1; // [1:1:4]

// Finished assembled drawer interior clear dimensions.
target_drawer_inside_width = 420; // [40:1:1500]

target_drawer_inside_depth = 336; // [40:1:1200]

/* [Sizing / Modular Grid] */

// Generic modular-grid sizing. A 42 mm pitch is convenient for Gridfinity,
// but these controls intentionally remain storage-system agnostic.
//
// Required interior axis = pitch * count + 2 * edge_clearance.
target_module_pitch_x = 42; // [10:0.5:100]

target_module_count_x = 10; // [1:1:40]

target_module_edge_clearance_x = 1; // [0:0.25:20]

target_module_pitch_y = 42; // [10:0.5:100]

target_module_count_y = 8; // [1:1:40]

target_module_edge_clearance_y = 1; // [0:0.25:20]

/* [Structure / Layout] */

drawer_count = 4; // [1:1:12]

/* [Structure / Top] */

// Select a full sheet top or front/rear stretchers.
top_style = "full"; // [full, stretchers]

top_stretcher_depth = 50;

/* [Structure / Back and Braces] */

// panel            = thin applied back, nailed/screwed around carcass edges.
// structural_panel = solid carcass-thickness back captured at the rear edge;
//                    it automatically follows carcass butt/dado/tab_slot joinery.
// stretchers        = structural rear rails made from carcass material.
// none              = open back.
back_style = "panel"; // [panel, structural_panel, stretchers, none]

// Applied-panel position. Used only when back_style = "panel".
// structural_panel is always flush with the cabinet rear edge.
back_inset = 0;

// Structural rear stretchers. They sit inside the rear edge and use the same
// side-joinery style as the carcass (butt / dado / tab_slot).
back_stretcher_count = 2; // [1:1:4]

back_stretcher_height = 50;

back_stretcher_edge_margin = 15;

back_stretcher_inset = 0;

/* [Structure / Frame Joinery] */

// One selector controls the fixed cabinet-to-side-panel joints.
joinery_style = "dado"; // [butt, screw, dado, tab_slot]

// Tab count can be adaptive or fixed.
// "adaptive" is recommended: the count is calculated independently for each
// edge length so a 90 mm stretcher does not receive the same number of joints
// as a 600 mm shelf.
// Used only when joinery_style = "tab_slot".
tab_count_mode = "adaptive"; // [adaptive, fixed]

// Used only when tab_count_mode = "fixed".
joint_tab_count = 3; // [1:1:8]

// Adaptive tab geometry is scaled down for small panels.
target_tab_spacing = max(45,min(90,material_thickness*8));

max_auto_tab_count = 8; // [1:1:12]

joint_tab_width = max(12,min(25,material_thickness*2.4));

joint_tab_edge_margin = max(6,min(12,material_thickness*1.2));

minimum_joint_web = max(10,min(20,material_thickness*1.8));

/* [Structure / Tab Placement] */

// Location-aware joinery inherited from Modular Storage v35 lets the same carcass use different tab placement
// policies at the bottom, top, fixed shelves, and drawer separators.
// legacy preserves the V34 evenly distributed behavior everywhere except the
// stackable bottom override; location_aware enables the selectors below.
edge_joinery_policy = "location_aware"; // [location_aware, legacy]

// automatic = historical evenly distributed tabs.
// edge_biased = move the first/last tab toward the ends while preserving the
// configured edge margin and minimum web.
// custom = use the matching *_tab_custom_centers array below.
top_tab_placement = "automatic"; // [automatic, edge_biased, custom]

shelf_tab_placement = "automatic"; // [automatic, edge_biased, custom]

separator_tab_placement = "automatic"; // [automatic, edge_biased, custom]

top_tab_custom_centers = [];

shelf_tab_custom_centers = [];

separator_tab_custom_centers = [];

// Bottom joints are independently configurable on non-stackable cabinets.
bottom_tab_placement = "automatic"; // [automatic, edge_biased, custom]

bottom_tab_custom_centers = [];

/* [Structure / Drawer Joinery] */

// Joinery between the drawer FRONT/BACK box panels and the drawer SIDES.
// These intentionally mirror the carcass choices.
drawer_joinery_style = "dado"; // [butt, screw, dado, tab_slot]

// Grooved bottom is useful for small drawers; depth scales with drawer wall.
drawer_bottom_joinery = "dado"; // [butt, dado]

/* [Fronts / Layout and Reveals] */

// Shared mounting depth for decorative DOORS and DRAWER FACES.
//
// overlay     = current behavior: the front sits proud of the carcass face.
// inset_flush = the visible front surface is flush with the carcass front
//               plane and the panel thickness extends into the opening.
front_mount_style = "overlay"; // [overlay, inset_flush]

// Extra air space behind a flush/inset front. Drawer boxes, shelves,
// separators and slide hardware are automatically kept behind this plane.
inset_front_back_clearance = 2; // [0:0.25:10]

// OVERLAY mode only; ignored by inset_flush.
overlay_width_style = "partial"; // [partial, full]

front_edge_reveal = 1.5;

// When true, the lowest decorative drawer front overlays the bottom-panel edge.
fronts_cover_bottom_lip = true;

drawer_gap = 2;

/* [Drawers / Layout] */

include_drawer_faces = true;

// Extend ONLY the top decorative drawer face to the cabinet top.
// Drawer-box geometry and the gap below it remain unchanged.
extend_top_drawer_face_to_top = false;

drawer_height_mode = "equal"; // [equal, graduated, custom_weights]

drawer_graduated_step = 0.35;

drawer_height_weights = [1,1,1,1];

drawer_bank_count = 1; // [1:1:4]

drawer_bank_layout_mode = "shared"; // [shared, independent]

// Relative bank widths. Example: [1,2] makes bank 2 twice as wide.
drawer_bank_width_weights = [1,1,1,1];

drawer_bank_drawer_counts = [4,4,4,4];

drawer_bank_height_modes = ["equal","equal","equal","equal"];

drawer_bank_graduated_steps = [0.35,0.35,0.35,0.35];

drawer_bank_face_gap = drawer_gap;

drawer_bank_partition_rear_clearance = 10;

drawer_bank_partition_joinery = "match_carcass"; // [match_carcass, butt, dado, tab_slot]

// Optional structure between ADJACENT drawers. This does not replace the
// existing drawer/door combo divider.
include_drawer_separators = false;

// A full separator is a broad horizontal panel.
// Stretchers create one front and one rear cross-piece at each drawer boundary.
drawer_separator_style = "stretchers"; // [full, stretchers]

drawer_separator_stretcher_depth = 75;

/* [Drawers / Clearances] */

drawer_vertical_clearance = 4;

drawer_back_clearance = 8;

drawer_bottom_inset = 4;

front_setback = 1.5;

/* [Dividers / Layout] */

// Adds a removable or captured orthogonal divider grid to generated drawers.
// equal_count creates equal clear compartments; custom_positions uses explicit
// divider centerlines measured from the drawer's inside-left / inside-front.
include_drawer_divider_grid = false;

drawer_divider_layout_mode = "equal_count"; // [equal_count, custom_positions]

// Compartment counts. Internal divider quantities are columns-1 and rows-1.
drawer_divider_columns = 4; // [1:1:20]

drawer_divider_rows = 3; // [1:1:20]

// Used only when layout_mode = custom_positions. Values are centerlines in mm
// from the finished inside-left / inside-front drawer faces.
drawer_divider_custom_x = [100,200,300];

drawer_divider_custom_y = [120,240];

// all applies the same grid to every generated drawer. drawer_index targets the
// 1-based flattened drawer number shown in BOM/part IDs.
drawer_divider_target_mode = "all"; // [all, drawer_index]

drawer_divider_target_index = 1; // [1:1:40]

// How the divider assembly is captured by the drawer box.
// freestanding          = divider parts only, no drawer machining.
// bottom_only           = shallow locating grooves in the drawer bottom.
// bottom_and_perimeter  = bottom grooves plus end grooves in drawer walls.
drawer_divider_mounting = "bottom_and_perimeter"; // [freestanding, bottom_only, bottom_and_perimeter]

drawer_divider_height = 60;

// Minimum clear distance from drawer inside faces to the first divider edge.
drawer_divider_edge_margin = 8;

// longitudinal_top = front-to-back dividers are slotted from the top and
// left-to-right dividers from the bottom. transverse_top reverses the pattern.
drawer_divider_interlock_orientation = "longitudinal_top"; // [longitudinal_top, transverse_top]

/* [Mounting / Ganging] */

// Side-to-side cabinet connection system.
//
// none             = no ganging geometry.
// connector_only   = through connector-bolt holes only.
// dowel_connector  = blind alignment dowels + through connector-bolt holes.
//
// The pattern is canonical for a given cabinet envelope so LEFT and RIGHT
// mating sides use the same coordinates. The engine detects conflicts with
// common side-panel operations and reports WARN| records rather than silently
// moving one cabinet to a different pattern.
ganging_style = "none"; // [none, connector_only, dowel_connector]

// Which OUTER cabinet side(s) receive the pattern.
ganging_sides = "both"; // [left, right, both]

// standard = two vertical stations.
// tall     = three vertical stations.
ganging_vertical_pattern = "standard"; // [standard, tall]

// Front/rear columns are measured from their respective cabinet edges.
// Matching cabinet depths are required for both columns to align.
ganging_front_setback = 64; // [30:1:150]

ganging_rear_setback = 64; // [30:1:150]

// Station centers keep this far away from the usable opening boundaries and
// cabinet extremes before snapping to the 32 mm canonical grid.
ganging_vertical_margin = 64; // [32:1:128]

/* [Hardware / Slides] */

// metal_slides = commercial side-mount slides
// wood_rails   = runners cut from the same sheet material
// none         = no slide allowance / runner geometry
drawer_mount = "none"; // [none, wood_rails, metal_slides]

// Total air gap is 2x this value. 12.7 mm is a common nominal 1/2" per side,
// but use the clearance specified by your exact slide hardware.
metal_slide_clearance_per_side = 12.7;

metal_slide_length = 500;

metal_slide_front_setback = 3;

metal_slide_envelope_height = 45;

/* [Hardware / Slide Drilling] */

// Controls how an explicit hardware hole array is reduced for machining.
hardware_drilling_mode = "recommended"; // [minimum, recommended, all]

// When enabled and drawer_mount = "metal_slides", through-holes are placed
// in BOTH cabinet side panels and drawer side panels.
include_metal_slide_holes = true;

metal_slide_hole_diameter = 5;

// Defaults are generic, not tied to a particular slide manufacturer.
metal_slide_first_hole_from_front = 37;

metal_slide_hole_spacing = 96;

metal_slide_hole_count = 4; // [1:1:10]

// legacy_spacing preserves the historic first-hole/spacing/count controls.
// explicit_array is used by hardware-catalog patches with manufacturer-specific patterns.
metal_slide_hole_pattern_mode = "legacy_spacing"; // [legacy_spacing, explicit_array]

metal_slide_cabinet_holes_x = [37,133,229,325];

metal_slide_drawer_holes_x = [37,133,229,325];

metal_slide_cabinet_hole_diameter = 5;

metal_slide_drawer_hole_diameter = 5;

metal_slide_hole_rear_margin = 20;

metal_slide_cabinet_hole_z_from_drawer_bottom = 22.5;

metal_slide_drawer_hole_z_from_drawer_bottom = 22.5;

/* [Hardware / Wood Runners] */

// Fixed cabinet rail and matching drawer runner thicknesses.
wood_rail_thickness = material_thickness; // [0.01:0.01:100]
wood_drawer_runner_thickness = wood_rail_thickness; // [0.01:0.01:100]


wood_rail_height = 12;

custom_wood_rail_depth = cabinet_depth - 70;

wood_rail_front_setback = 20;

wood_drawer_runner_height = 6;

custom_wood_drawer_runner_depth = custom_wood_rail_depth;

wood_drawer_runner_front_setback = wood_rail_front_setback;

// Vertical location of the drawer runner, measured upward from the bottom of
// the drawer box. The fixed rail is automatically positioned underneath it.
wood_drawer_runner_bottom_offset = 12;

// Running clearances. side_clearance keeps the drawer runner away from the
// cabinet side; vertical_clearance prevents a zero-clearance/interference fit.
wood_rail_side_clearance = 0.5;

wood_rail_vertical_clearance = 0.35;

// Matching holes are cut in:
//   fixed rail <-> cabinet side
//   drawer runner <-> drawer side
// This makes it easy to locate the rails with screws, dowel pins, or temporary
// registration pins before final fastening.
include_wood_slide_registration_holes = true;

wood_slide_registration_hole_diameter = 3;

wood_slide_registration_hole_count = 3; // [1:1:8]

wood_slide_registration_end_margin = 20;

/* [Hardware / Handles] */

include_drawer_handle_holes = false;

handle_hole_pattern = "two_hole"; // [single_hole, two_hole]

handle_hole_diameter = 4;

handle_hole_spacing = 64;

// Drawer pulls are centered. This shifts them vertically from center.
drawer_handle_vertical_offset = 0;

/* [Hardware / Frame Fasteners] */

// Used only when joinery_style = "butt".
// These are through-holes in the cabinet SIDE panels, centered on the edge
// of each mating bottom/top/shelf/divider/separator/toe-kick part. They act as
// screw/pilot-hole guides so a butt-jointed part can be located consistently.
include_butt_registration_holes = false;

butt_registration_hole_diameter = 3;

butt_registration_target_spacing = 80;

butt_registration_edge_margin = 15;

/* [Hardware / Drawer Fasteners] */

// Through pilot guides into the front/back edges, only in screw mode.
drawer_screw_hole_diameter = 3.00; // [1:0.01:8]

drawer_screw_edge_margin = 15.00; // [5:0.01:50]

/* [Hardware / Face Registration] */

// Matching registration pattern between the drawer box FRONT and decorative
// drawer FACE. The drawer box front is always drilled through.
include_drawer_face_registration_holes = true;

drawer_face_registration_hole_diameter = 3;

drawer_face_registration_hole_count = 2; // [1:1:4]

drawer_face_registration_hole_spacing = 80;

// Moves the registration pattern relative to the drawer-box vertical center.
drawer_face_registration_vertical_offset = 0;

// half_depth = blind hole from the REAR face, depth = 1/2 face thickness.
// through    = full through-hole in decorative face.
drawer_face_registration_face_hole = "half_depth"; // [half_depth, through]

/* [Hardware / Ganging] */

// Common furniture/cabinet alignment dowel starting point.
ganging_dowel_diameter = 8; // [4:0.5:12]

ganging_dowel_depth = 10; // [4:0.5:18]

// Clearance hole for sleeve/sex-bolt style cabinet connectors.
ganging_connector_hole_diameter = 6.5; // [4:0.5:12]

// In dowel_connector mode the dowel and connector are separated vertically.
// 32 mm keeps the pair compatible with system-hole thinking without requiring
// the rest of the cabinet to use a 32 mm system.
ganging_pair_vertical_spacing = 32; // [16:1:64]

// Conflict detector clearance around existing drilling/joinery.
ganging_conflict_clearance = 6; // [2:0.5:15]

/* [Output / View] */

// Stable Configurator API identity. Recipes may change design_name in the UI,
// but design_type is fixed by this front end.
design_name = "Compact 4-Drawer Benchtop";

// What OpenSCAD displays/exports.
output_mode = "assembly"; // [assembly, cut_layout, engrave_layout, calibration_coupon_cut, calibration_coupon_pocket, calibration_coupon_engrave, flat_3d, print_layout, pocket_layout, pocket_carcass_dados, pocket_drawer_dados, pocket_bottom_grooves, pocket_divider_bottom_grooves, pocket_divider_perimeter_grooves, pocket_shelf_pins, pocket_hinge_cups, pocket_face_registration, pocket_base_hardware, pocket_worktop_registration, pocket_face_frame_dados, pocket_ganging, bom, carcass_only, drawers_only]

// Stable colors make it easier to identify the same part in assembly and
// flat-layout views. "material" returns to a plywood-like single material
// palette; "monochrome" uses neutral gray.
color_mode = "by_part"; // [by_part, material, monochrome]

/* [Output / Visibility] */

// These toggles affect ONLY assembly, carcass_only, and drawers_only previews.
// Manufacturing layouts always contain the complete set of required parts.
show_carcass_sides = true;

show_carcass_bottom = true;

show_carcass_top = true;

show_back_construction = true;

show_drawer_separators = true;

show_drawer_bank_partitions = true;

show_drawer_box_sides = true;

show_drawer_box_front_back = true;

show_drawer_bottoms = true;

show_drawer_dividers = true;

show_drawer_faces = true;

show_drawer_slide_parts = true;

show_metal_slide_envelopes = true;

/* [Output / Flat Layout] */

layout_gap = 12;

layout_show_stock = false;

stock_width = 1220;

stock_height = 610;

/* [Output / Labels] */

// Optional part labels in ENGRAVE output.
engrave_drawer_divider_ids = true;

// engrave_layout exports ONLY vector part IDs plus the same registration frame
// used by CUT/POCKET layouts. Import it at the same origin as the cut file.
// The part IDs also match the IDs printed by output_mode = "bom".
engrave_label_size = 5;

engrave_label_min_size = 2;

// Preview the cut-part outlines behind labels in OpenSCAD. The outlines use
// the preview-only % modifier and are NOT included in engraving exports.
show_cut_outlines_in_engrave_preview = true;

/* [Output / Calibration] */

// The coupon automatically adopts the ACTIVE cabinet/material/joinery settings.
// Only tests relevant to the current configuration are generated:
//   carcass tab/slot or dado fit
//   drawer corner tab/slot or dado fit
//   drawer-bottom groove fit
//   wood-slide horizontal side clearance
//
// Fit offsets are added to the configured clearance. Example with a configured
// 0.20 mm dado clearance: [-0.20,-0.10,0,0.10,0.20] tests
// 0.00 / 0.10 / 0.20 / 0.30 / 0.40 mm.
calibration_fit_offsets = [-0.20,-0.10,0,0.10,0.20];

// Wood-slide offsets are intentionally biased upward because running clearance
// often needs more room than static joinery. With a configured 1.0 mm setting,
// the defaults test 0.5 / 1.0 / 1.5 / 2.0 / 2.5 mm PER SIDE.
calibration_slide_clearance_offsets = [-0.50,0,0.50,1.00,1.50];

// Label size used by calibration_coupon_engrave.
calibration_coupon_label_size = 4;

// Preview-only overlays in calibration_coupon_cut. They are excluded from
// exported SVG/DXF geometry.
show_calibration_pockets_over_cut = true;

show_calibration_labels_over_cut = true;

/* [Output / Export Registration] */

show_blind_pockets_over_cut_layout = true;

include_shared_export_bounding_box = true;

export_bounding_box_margin = 12;

export_bounding_box_frame_width = 0.20; // [0.05:0.05:1.00]

/* [System / Reports] */

// Structured dimensions are echoed to the OpenSCAD console in lines beginning
// with DIM|. "full" adds per-door, per-shelf, and per-drawer assembled sizes.
dimension_report = "full"; // [off, summary, full]

// Machine-readable design-health checks are echoed as
// CHECK|SEVERITY|CODE|MESSAGE for the website and package exporter.
validation_report = "summary"; // [off, summary, verbose]

// Modular Organization v4 is a fork of Modular Storage v35.  The fork exposes
// physical connection interfaces, owned keepout zones, and compatibility keys
// as machine-readable records so project-level tools can reason about modules
// without duplicating the geometry rules.
system_contract_report = "summary"; // [off, summary, verbose]

/* [System / Interface Validation] */

// enforce   = geometry-specific safe policies remain authoritative and
//             interface keepout conflicts are validation errors.
// warn_only = keepout conflicts are reported as warnings.
// off       = suppress interface-owned keepout validation only.
interface_keepout_policy = "enforce"; // [enforce, warn_only, off]

/* [Hidden] */

// Internal section: Hidden

design_type = "benchtop";
config_api_version = 1;


$fn = circle_segments;


// Resolved earlier for a public computed default: material_thickness


drawer_material_thickness =
    drawer_stock == "same_as_carcass" ? material_thickness :
    drawer_stock == "1/4_nominal" ? 6.35 :
    drawer_stock == "3/8_nominal" ? 9.525 :
    drawer_stock == "1/2_nominal" ? 12.7 :
    custom_drawer_material_thickness; // [0.01:0.01:100]


drawer_bottom_thickness =
    drawer_bottom_stock == "1/8_nominal" ? 3.175 :
    drawer_bottom_stock == "1/4_nominal" ? 6.35 :
    drawer_bottom_stock == "same_as_drawer" ? drawer_material_thickness :
    custom_drawer_bottom_thickness; // [0.01:0.01:100]


drawer_front_thickness =
    drawer_front_stock == "same_as_carcass" ? material_thickness :
    drawer_front_stock == "1/4_nominal" ? 6.35 :
    drawer_front_stock == "3/8_nominal" ? 9.525 :
    drawer_front_stock == "1/2_nominal" ? 12.7 :
    custom_drawer_front_thickness; // [0.01:0.01:100]


back_thickness =
    back_stock == "1/8_nominal" ? 3.175 :
    back_stock == "1/4_nominal" ? 6.35 :
    custom_back_thickness; // [0.01:0.01:100]


dado_depth =
    dado_depth_mode == "auto"
        ? round(min(material_thickness*0.38,
                    max(1,material_thickness-1.5))*10)/10
        : custom_dado_depth;


drawer_bank_height_weights = [
    [1,1,1,1,1,1,1,1],
    [1,1,1,1,1,1,1,1],
    [1,1,1,1,1,1,1,1],
    [1,1,1,1,1,1,1,1]
];


drawer_dado_depth =
    drawer_dado_depth_mode == "auto"
        ? round(min(drawer_material_thickness*0.35,
                    max(0.8,drawer_material_thickness-1.2))*10)/10
        : custom_drawer_dado_depth;


drawer_bottom_dado_depth =
    drawer_bottom_dado_depth_mode == "auto"
        ? round(min(drawer_material_thickness*0.30,
                    max(0.8,drawer_material_thickness-1.2))*10)/10
        : custom_drawer_bottom_dado_depth;

// Internal section: Hidden


// Fixed by design in V24. Kept internally so older geometry helpers remain
// compatible, but it is no longer exposed in the Customizer.
back_joinery = "simple";



// Drawers-only compatibility value.
door_gap = 2;



// Internal section: Resolved Configuration - Hidden


cabinet_contents = "drawers";
door_count = 0;
front_width_style = overlay_width_style == "full" ? "full_overlay" : "inset";

// Flat-bottom benchtop construction.
active_mount_style = "benchtop";
active_base_style = "flat";
has_toe_kick = false;
toe_kick_height = 0;
toe_kick_setback = 0;
bottom_above_toe = 0;
side_toe_kick_cutout = "none";

base_hardware_active = false;
include_base_mounting_plate = false;
base_mounting_plate_active = false;
base_mounting_plate_side_inset = 0;
base_mounting_plate_front_inset = 0;
base_mounting_plate_back_inset = 0;
bottom_width_style = "joined";
base_hardware_inset_x = 30;
base_hardware_inset_y = 30;
include_base_hardware_drill_holes = false;
caster_height = 75;
caster_wheel_diameter = 50;
caster_mount_plate_width = 55;
caster_mount_plate_depth = 45;
caster_hole_spacing_x = 35;
caster_hole_spacing_y = 25;
caster_hole_diameter = 5;
leveler_height = 20;
leveler_foot_diameter = 30;
leveler_mount_hole_diameter = 8;

include_worktop = false;
worktop_active = false;
worktop_thickness = 18.00; // [0.01:0.01:100]
worktop_side_overhang = 0;
worktop_front_overhang = 0;
worktop_back_overhang = 0;
include_worktop_registration_holes = false;
worktop_registration_hole_diameter = 4;
worktop_registration_hole_count = 3;
worktop_registration_end_margin = 50;
worktop_registration_blind_depth = 4;

// top_style is a direct public configuration value.

// Hidden compatibility values for inherited door/shelf geometry.
// They remain permanently disabled in this drawers-only branch.
shelf_style = "fixed";
door_shelf_count = 0;
wall_doors_flush_top = false;
show_doors = false;
hinge_style = "none";


single_door_hinge_side = "left";
hinge_count = 2;
hinge_end_offset = 100;
hinge_cup_diameter = 35;
hinge_cup_depth = 12;
hinge_cup_center_from_door_edge = 22.5;
hinge_door_fixing_hole_diameter = 3;
hinge_door_fixing_hole_spacing = 45;
hinge_plate_hole_diameter = 5;
hinge_plate_center_from_front = 37;
hinge_plate_hole_spacing = 32;

// Hardware presets may disable unsupported operations instead of leaving stale drilling.
hinge_door_fixing_enabled = true;
hinge_plate_holes_enabled = true;
include_door_handle_holes = false;
door_handle_from_open_edge = 50;
door_handle_from_top = 90;
door_handle_orientation = "vertical";

adjustable_shelf_side_clearance = 2;
adjustable_shelf_hole_diameter = 5;
adjustable_shelf_hole_spacing = 32;
adjustable_shelf_front_setback = 37;
adjustable_shelf_rear_setback = 37;
adjustable_shelf_hole_bottom_margin = 50;
adjustable_shelf_hole_top_margin = 50;
adjustable_shelf_hole_type = "through";
adjustable_shelf_hole_depth = 10;

// Optional shop-made wood runners preserve a small rear clearance.
wood_rail_depth = max(40,cabinet_depth-front_setback-drawer_back_clearance-8);
wood_drawer_runner_depth = wood_rail_depth;

// Shared-core V22 stackable-cabinet compatibility. Disabled here.
stackable_mode = false;
include_stack_base = false;
show_stack_base = false;
stack_preview_count = 1;
stack_preview_explode_gap = 0;
stack_interface_depth = 12;
stack_interface_front_margin = 70;
stack_interface_back_margin = 70;
stack_interface_transition = 18;
stack_interface_corner_radius = 6;
stack_interface_clearance = 0.5;
stack_base_height = 60;

include_back = back_style == "panel" || back_style == "structural_panel";


// Large-cabinet-only visibility categories remain permanently disabled here.
show_toe_kick = false;
show_base_hardware = false;
show_worktop = false;
show_combo_divider = false;
show_shelves = false;
show_door_hinge_partitions = false;

// Door-partition compatibility values; unused by this drawers-only branch.
include_door_hinge_partitions = false;
door_hinge_partition_depth = 90;
door_hinge_partition_shelf_clearance = 0.5;
door_width_weights = [1,1,1,1];

// Generalized mixed-bay compatibility; this drawers-only branch remains legacy.
cabinet_layout_mode = "legacy";
mixed_bay_count = 1;
mixed_bay_types = ["drawers"];
mixed_bay_width_weights = [1];
mixed_bay_front_gap = drawer_gap;
include_mixed_bay_partitions = false;
show_mixed_bay_partitions = false;
mixed_bay_drawer_counts = [drawer_count];
mixed_bay_drawer_height_modes = [drawer_height_mode];
mixed_bay_drawer_graduated_steps = [drawer_graduated_step];
mixed_bay_drawer_height_weights = [drawer_height_weights];
mixed_bay_door_counts = [1];
mixed_bay_door_hinge_sides = ["left"];
mixed_bay_shelf_styles = ["adjustable"];
mixed_bay_shelf_counts = [0];

// Shared-core V22 active-layout aliases. Benchtop stays legacy/drawer-only.
active_cabinet_layout_mode = cabinet_layout_mode;
active_mixed_bay_count = mixed_bay_count;
active_mixed_bay_types = mixed_bay_types;
active_mixed_bay_width_weights = mixed_bay_width_weights;
active_mixed_bay_drawer_counts = mixed_bay_drawer_counts;
active_mixed_bay_door_counts = mixed_bay_door_counts;
active_mixed_bay_shelf_styles = mixed_bay_shelf_styles;
active_mixed_bay_shelf_counts = mixed_bay_shelf_counts;
active_mixed_bay_drawer_height_modes = mixed_bay_drawer_height_modes;
active_mixed_bay_drawer_graduated_steps = mixed_bay_drawer_graduated_steps;
active_mixed_bay_drawer_height_weights = mixed_bay_drawer_height_weights;
active_mixed_bay_door_hinge_sides = mixed_bay_door_hinge_sides;


// Profile-specific validation threshold used only for console guidance.
drawer_face_height_warning_threshold = 45;


// Shared-core V22 features: generalized mixed vertical bays plus the existing
// independent drawer-bank, weighted-width, CAM, and drawer-face capabilities.
//
// ---------------------------
// SHARED IMPLEMENTATION
// ---------------------------
carcass_joint_geometry = joinery_style == "screw" ? "butt" : joinery_style;
carcass_registration_enabled = joinery_style == "screw" || include_butt_registration_holes;
drawer_joint_geometry = drawer_joinery_style == "screw" ? "butt" : drawer_joinery_style;
include <core.scad>
include <layouts.scad>


