// Modular Organization: drawer — source entrypoint; units mm.
/* [Materials / Stock] */

// Convenience selectors for common sheet-stock thicknesses.
// "custom_mm" preserves the editable metric thickness below and is the safest
// choice for CNC joinery when you have measured the actual sheet thickness.
//
// Nominal inch selections convert the stated fraction directly to millimeters.
// Real plywood often measures thinner than its nominal label, so measure stock
// and use custom_mm when fit is critical.
carcass_stock = "custom_mm";

back_stock = "custom_mm";

drawer_stock = "custom_mm"; // [custom_mm, 1/8_nominal, 1/4_nominal, 3/8_nominal, 1/2_nominal, 5/8_nominal, 3/4_nominal, 1_nominal]

drawer_bottom_stock = "custom_mm"; // [custom_mm, 1/8_nominal, 1/4_nominal, 3/8_nominal, 1/2_nominal, 5/8_nominal, 3/4_nominal, 1_nominal]

drawer_front_stock = "custom_mm"; // [custom_mm, 1/8_nominal, 1/4_nominal, 3/8_nominal, 1/2_nominal, 5/8_nominal, 3/4_nominal, 1_nominal]

drawer_divider_stock = "custom_mm"; // [custom_mm, 1/8_nominal, 1/4_nominal, 3/8_nominal, 1/2_nominal, 5/8_nominal, 3/4_nominal]

/* [Materials / Measured Thickness] */

// Used whenever the matching stock selector above is set to custom_mm.
// Defaults intentionally preserve the existing Utility Cabinet geometry.
custom_carcass_thickness = 18.00; // [0.01:0.01:100]

custom_back_thickness = 6.00; // [0.01:0.01:100]

custom_drawer_material_thickness = 12.00; // [0.01:0.01:100]

custom_drawer_bottom_thickness = 6.00; // [0.01:0.01:100]

custom_drawer_front_thickness = 18.00; // [0.01:0.01:100]

custom_drawer_divider_thickness = 6.00; // [0.01:0.01:100]

/* [Hidden] */
material_thickness =
    resolved_stock_thickness(
        carcass_stock,
        custom_carcass_thickness
    ); // [0.01:0.01:100]

/* [Materials / Measured Thickness] */

// Fixed lower rail attached to the cabinet side.

// Matching upper runner attached to the outside of each drawer side.
// Its underside rides on the top surface of the fixed rail.

/* [Machining / Tool and Kerf] */

// Circle/cylinder smoothness. Mostly affects round drill holes and CNC corner relief.
circle_segments = 48; // [12:4:96]

cnc_tool_diameter = 6.35;

// Usually leave this OFF and compensate in CAM.
apply_kerf_compensation = false;

kerf = 0.15;

/* [Machining / Drawer Joints] */

// Relief for this material only. Inherit preserves the shared setting.
drawer_slot_corner_relief = "inherit"; // [inherit,none,dogbone,t_bone]
// Cutter diameter in mm. Zero inherits the shared cutter diameter.
drawer_cnc_tool_diameter = 0; // [0:0.01:50]


// Drawer tab/slot clearance is independent from the carcass.
drawer_joint_fit_clearance = 0.20; // [0:0.05:2]

// Drawer dado clearance is independent as well. It applies to both
// front/back-to-side dados and optional drawer-bottom grooves.
drawer_dado_fit_clearance = 0.20; // [0:0.05:2]

// Blind dado depth for drawer front/back-to-side joints.
drawer_dado_depth = 4;

drawer_bottom_dado_depth = 4;

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

/* [Sizing / Fit Targets] */

// enclosure   = measure the existing cabinet opening and let the engine calculate
//               the replacement drawer box.
// outside_box = reproduce / specify the finished outside box envelope.
// inside_clear= design the box around the required usable storage volume.
drawer_design_basis = "enclosure"; // [enclosure, outside_box, inside_clear, modular_grid]

// Measured clear opening width and height.
// Usable depth is measured from the enclosure/front reference plane to the
// rear obstruction/back panel.
enclosure_opening_width = 450;

enclosure_opening_height = 160;

enclosure_usable_depth = 500;

// When design_basis = enclosure, width/depth are derived from the opening.
// Height can be specified independently because replacement drawers commonly
// use a shorter box than the available opening.
enclosure_height_mode = "box_height";

// [box_height, inside_clear, fill_opening]

enclosure_target_box_height = 120;

enclosure_target_inside_height = 100;

// Used when drawer_design_basis = outside_box.
target_box_outside_width = 424.6;

target_box_outside_depth = 480;

target_box_outside_height = 120;

// Used when drawer_design_basis = inside_clear.
target_box_inside_width = 400;

target_box_inside_depth = 456;

target_box_inside_height = 100;

/* [Sizing / Modular Grid] */

// Used when drawer_design_basis = modular_grid.
// Required inside axis = pitch * count + 2 * edge clearance.
// 42 mm defaults are convenient for Gridfinity but remain fully generic.
drawer_module_pitch_x = 42;

drawer_module_count_x = 10; // [1:1:40]

drawer_module_edge_clearance_x = 1;

drawer_module_pitch_y = 42;

drawer_module_count_y = 8; // [1:1:40]

drawer_module_edge_clearance_y = 1;

drawer_module_inside_height = 85;

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
drawer_joinery_style = "butt"; // [butt, screw, dado, tab_slot]

// Bottom joinery is independent. "dado" cuts a groove in all four drawer
// walls and enlarges the bottom so it enters those grooves. This can be used
// together with drawer_joinery_style = "tab_slot".
drawer_bottom_joinery = "butt"; // [butt, dado]

/* [Fronts / Layout and Reveals] */

// none        = drawer box only / reuse the original front.
// overlay     = new face larger than the opening by the configured overlays.
// inset_flush = new face fits inside the opening with a perimeter reveal.
drawer_face_style = "none"; // [none, overlay, inset_flush]

// opening = derive from opening + overlay/reveal.
// custom  = use the explicit face width/height below.
drawer_face_size_mode = "opening"; // [opening, custom]

drawer_face_overlay_horizontal = 12.7;

drawer_face_overlay_vertical = 12.7;

drawer_face_inset_reveal = 2;

drawer_face_back_clearance = 2;

custom_drawer_face_width = 475.4;

custom_drawer_face_height = 185.4;

/* [Drawers / Layout] */

// Used only when drawer_mount = none. This is the running air gap per side.
drawer_free_fit_clearance_per_side = 1.0;

// Optional structure between ADJACENT drawers. This does not replace the
// existing drawer/door combo divider.
include_drawer_separators = false;

// A full separator is a broad horizontal panel.
// Stretchers create one front and one rear cross-piece at each drawer boundary.
drawer_separator_style = "stretchers"; // [full, stretchers]

drawer_separator_stretcher_depth = 75;

/* [Drawers / Clearances] */

drawer_vertical_clearance = 5;

drawer_back_clearance = 20;

drawer_bottom_inset = 8;

front_setback = 2; // drawer box setback behind the drawer face

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

/* [Hardware / Slides] */

// metal_slides = commercial side-mount slides
// wood_rails   = runners cut from the same sheet material
// none         = no slide allowance / runner geometry
drawer_mount = "metal_slides"; // [metal_slides, wood_rails, none]

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


// Replacement drawers normally need the drawer-mounted runners only.
// Enable this if you also want matching fixed enclosure rails manufactured.
standalone_include_fixed_wood_rails = false;

// 0 = auto (drawer depth minus 20 mm). Otherwise use the entered cut length.
standalone_wood_slide_length = 0;

wood_rail_height = 28;

wood_rail_front_setback = 20;

wood_drawer_runner_height = 14;

/* [Hidden] */
wood_rail_depth =
    standalone_wood_slide_length > 0
        ? standalone_wood_slide_length
        : max(20,standalone_pre_resolved_box_depth()-20);

/* [Hardware / Wood Runners] */

wood_drawer_runner_depth = wood_rail_depth;

wood_drawer_runner_front_setback = wood_rail_front_setback;

// Vertical location of the drawer runner, measured upward from the bottom of
// the drawer box. The fixed rail is automatically positioned underneath it.
wood_drawer_runner_bottom_offset = 30;

// Running clearances. side_clearance keeps the drawer runner away from the
// cabinet side; vertical_clearance prevents a zero-clearance/interference fit.
wood_rail_side_clearance = 1.0;

wood_rail_vertical_clearance = 0.5;

// Matching holes are cut in:
//   fixed rail <-> cabinet side
//   drawer runner <-> drawer side
// This makes it easy to locate the rails with screws, dowel pins, or temporary
// registration pins before final fastening.
include_wood_slide_registration_holes = true;

wood_slide_registration_hole_diameter = 4;

wood_slide_registration_hole_count = 3; // [1:1:8]

wood_slide_registration_end_margin = 50;

/* [Hardware / Handles] */

include_drawer_handle_holes = false;

// Drawer pulls are centered; this shifts them vertically from center.
drawer_handle_vertical_offset = 0;

/* [Hardware / Drawer Fasteners] */

// Through pilot guides into the front/back edges, only in screw mode.
drawer_screw_hole_diameter = 3.00; // [1:0.01:8]

drawer_screw_edge_margin = 15.00; // [5:0.01:50]

/* [Hardware / Face Registration] */

// Matching registration pattern between the drawer box FRONT and decorative
// drawer FACE. The drawer box front is always drilled through.
include_drawer_face_registration_holes = false;

drawer_face_registration_hole_diameter = 4;

drawer_face_registration_hole_count = 2; // [1:1:4]

drawer_face_registration_hole_spacing = 160;

// Moves the registration pattern relative to the drawer-box vertical center.
drawer_face_registration_vertical_offset = 0;

// half_depth = blind hole from the REAR face, depth = 1/2 face thickness.
// through    = full through-hole in decorative face.
drawer_face_registration_face_hole = "half_depth"; // [half_depth, through]

/* [Output / View] */

// Stable Configurator API identity. Recipes may change design_name in the UI,
// but design_type is fixed by this front end.
design_name = "Replacement Drawer";

// What OpenSCAD displays/exports.
output_mode = "assembly"; // [assembly, cut_layout, engrave_layout, print_layout, pocket_layout, pocket_drawer_dados, pocket_bottom_grooves, pocket_divider_bottom_grooves, pocket_divider_perimeter_grooves, pocket_face_registration, calibration_coupon_cut, calibration_coupon_pocket, calibration_coupon_engrave, bom, drawers_only]

// Stable colors make it easier to identify the same part in assembly and
// flat-layout views. "material" returns to a plywood-like single material
// palette; "monochrome" uses neutral gray.
color_mode = "by_part"; // [by_part, material, monochrome]

/* [Output / Visibility] */

// Assembly-only translucent reference of the measured/required enclosure.
show_enclosure_reference = true;

show_metal_slide_envelopes = true;

/* [Output / Flat Layout] */

layout_gap = 20;

layout_show_stock = false;

stock_width = 2440;

stock_height = 1220;

/* [Output / Labels] */

// Optional part labels in ENGRAVE output.
engrave_drawer_divider_ids = true;

// engrave_layout exports ONLY vector part IDs plus the same registration frame
// used by CUT/POCKET layouts. Import it at the same origin as the cut file.
// The part IDs also match the IDs printed by output_mode = "bom".
engrave_label_size = 8;

engrave_label_min_size = 2.5;

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
calibration_coupon_label_size = 5;

// Preview-only overlays in calibration_coupon_cut. They are excluded from
// exported SVG/DXF geometry.
show_calibration_pockets_over_cut = true;

show_calibration_labels_over_cut = true;

/* [Output / Export Registration] */

// Show exact blind-operation geometry over the cut layout in OpenSCAD.
// PREVIEW ONLY; it does not alter exported cut geometry.
show_blind_pockets_over_cut_layout = true;

// Add the same outer dummy frame to CUT and POCKET layouts so OpenSCAD crops
// both exports to exactly the same extents/origin.
include_shared_export_bounding_box = true;

export_bounding_box_margin = 20;

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

design_type = "drawer";
config_api_version = 1;



$fn = circle_segments;

// Internal section: Hidden


// Visual-only switches for inspecting the assembled model.
// Manufacturing outputs remain complete regardless of these settings.
show_carcass_sides = true;
show_carcass_bottom = true;
show_carcass_top = true;
show_toe_kick = true;
show_base_hardware = true;
show_worktop = true;
show_back_construction = true;

show_combo_divider = true;
show_shelves = true;
show_door_hinge_partitions = true;
show_drawer_separators = true;
show_drawer_bank_partitions = true;
show_mixed_bay_partitions = true;

show_drawer_box_sides = true;
show_drawer_box_front_back = true;
show_drawer_bottoms = true;
show_drawer_dividers = true;
show_drawer_faces = true;
show_drawer_slide_parts = true;

show_doors = true;



// Internal section: Hidden


// Direct configuration. V26 presets/recipes no longer override these values.
cabinet_width = max(200,enclosure_opening_width+100);
cabinet_height = max(200,enclosure_opening_height+100);
cabinet_depth = max(100,enclosure_usable_depth);



// Internal section: Hidden


cabinet_contents = "drawers"; // [drawers, doors, combo]
drawer_count = 1;
door_count = 0;

// legacy = full-width vertical arrangement.
// mixed_bays = independent side-by-side vertical columns.
cabinet_layout_mode = "legacy";



// Internal section: Hidden


// Used only when cabinet_layout_mode = "mixed_bays".
// Valid bay types: drawers/drawer, door/doors, open/shelf/shelves.
// Example: ["drawers","drawers","door"]
mixed_bay_count = 3; // [1:1:4]
mixed_bay_types = ["drawers","drawers","door","open"];

// Relative CLEAR opening widths. [1,1,2] makes bay 3 twice as wide.
mixed_bay_width_weights = [1,1,1,1];

// Decorative gap between neighboring bay fronts. It is centered on the
// structural full-depth partition between the bays.
mixed_bay_front_gap = 3;



// Internal section: Hidden


// Normally leave this enabled. Full-depth partitions separate the bay openings
// and provide the inner mounting surfaces for drawers, doors, and shelf pins.
// Their joinery always follows the main carcass joinery_style.
include_mixed_bay_partitions = true;





// Internal section: Hidden


// Choose whether each horizontal axis is controlled by the outside cabinet
// envelope or solved backward from the required finished drawer interior.
width_basis = "outside";
depth_basis = "outside";

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



// Internal section: Hidden


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


// Internal section: Hidden


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
ganging_style = "none";

// Which OUTER cabinet side(s) receive the pattern.
ganging_sides = "both"; // [left, right, both]

// standard = two vertical stations.
// tall     = three vertical stations.
ganging_vertical_pattern = "standard"; // [standard, tall]

// Front/rear columns are measured from their respective cabinet edges.
// Matching cabinet depths are required for both columns to align.
ganging_front_setback = 64; // [30:1:150]
ganging_rear_setback = 64; // [30:1:150]



// Internal section: Hidden


// Common furniture/cabinet alignment dowel starting point.
ganging_dowel_diameter = 8; // [4:0.5:12]
ganging_dowel_depth = 10; // [4:0.5:18]

// Clearance hole for sleeve/sex-bolt style cabinet connectors.
ganging_connector_hole_diameter = 6.5; // [4:0.5:12]

// In dowel_connector mode the dowel and connector are separated vertically.
// 32 mm keeps the pair compatible with system-hole thinking without requiring
// the rest of the cabinet to use a 32 mm system.
ganging_pair_vertical_spacing = 32; // [16:1:64]

// Station centers keep this far away from the usable opening boundaries and
// cabinet extremes before snapping to the 32 mm canonical grid.
ganging_vertical_margin = 64; // [32:1:128]

// Conflict detector clearance around existing drilling/joinery.
ganging_conflict_clearance = 6; // [2:0.5:15]


// Internal section: Hidden

door_stock = "custom_mm";



// Internal section: Hidden

custom_door_thickness = 18.00; // [0.01:0.01:100]



// Internal section: Hidden


function nominal_stock_thickness_mm(stock) =
    stock == "1/8_nominal" ? 3.175 :
    stock == "1/4_nominal" ? 6.35 :
    stock == "3/8_nominal" ? 9.525 :
    stock == "1/2_nominal" ? 12.7 :
    stock == "5/8_nominal" ? 15.875 :
    stock == "3/4_nominal" ? 19.05 :
    stock == "1_nominal"   ? 25.4 :
    0;

function resolved_stock_thickness(stock,custom_mm) =
    stock == "custom_mm"
        ? custom_mm
        : nominal_stock_thickness_mm(stock);

// Resolved earlier for a public computed default: material_thickness

back_thickness =
    resolved_stock_thickness(
        back_stock,
        custom_back_thickness
    ); // [0.01:0.01:100]

drawer_material_thickness =
    resolved_stock_thickness(
        drawer_stock,
        custom_drawer_material_thickness
    ); // [0.01:0.01:100]

drawer_bottom_thickness =
    resolved_stock_thickness(
        drawer_bottom_stock,
        custom_drawer_bottom_thickness
    ); // [0.01:0.01:100]

drawer_front_thickness =
    resolved_stock_thickness(
        drawer_front_stock,
        custom_drawer_front_thickness
    ); // [0.01:0.01:100]


door_thickness =
    resolved_stock_thickness(
        door_stock,
        custom_door_thickness
    ); // [0.01:0.01:100]



// Internal section: Hidden


// Select the physical mounting context directly.
cabinet_mount_style = "floor";

// Floor-base construction. Wall cabinets automatically suppress floor hardware.
base_style = "flat";

// Toe-kick dimensions; used only when base_style = "toe_kick".
custom_toe_kick_height = 100;
custom_toe_kick_setback = 65;
custom_bottom_above_toe = custom_toe_kick_height;

// Optional lower-front side-panel notch for a toe kick.
custom_side_toe_kick_cutout = "none"; // [none, left, right, both]



// Internal section: Hidden


// For leveling_feet / casters, a full-footprint mounting plate can be placed
// beneath the carcass. It uses carcass stock and is included in CUT/BOM.
include_base_mounting_plate = true;
base_mounting_plate_side_inset = 0;
base_mounting_plate_front_inset = 0;
base_mounting_plate_back_inset = 0;

// Bottom-panel width.
// joined: existing carcass bottom fits between / joins into the side panels.
// full_width: bottom spans the full cabinet footprint; side panels sit on top
// of it. This is especially useful for caster/leveler loads when no separate
// mounting plate is used.
bottom_width_style = "joined"; // [joined, full_width]

// Hardware centers measured inward from the cabinet footprint.
base_hardware_inset_x = 55;
base_hardware_inset_y = 55;

// Keep hardware drilling separate from CUT geometry. Export it with
// output_mode = "pocket_base_hardware".
include_base_hardware_drill_holes = true;

// Generic caster mounting plate / hole pattern.
caster_height = 100;
caster_wheel_diameter = 75;
caster_mount_plate_width = 70;
caster_mount_plate_depth = 60;
caster_hole_spacing_x = 50;
caster_hole_spacing_y = 40;
caster_hole_diameter = 6;

// Generic leveling-foot geometry / mounting hole.
leveler_height = 30;
leveler_foot_diameter = 40;
leveler_mount_hole_diameter = 10;



// Internal section: Hidden


// Adds a separate work surface ABOVE the carcass top. This is independent of
// the internal full-top / stretcher construction below it.
include_worktop = false;
worktop_thickness = 38.00; // [0.01:0.01:100]

// Positive values extend beyond the cabinet footprint.
worktop_side_overhang = 15;
worktop_front_overhang = 25;
worktop_back_overhang = 0;



// Internal section: Hidden


// Matching alignment holes between the carcass top support and worktop.
// The support holes are THROUGH holes. The worktop receives matching BLIND
// pockets from its underside, so the finished top surface remains unbroken.
include_worktop_registration_holes = true;

worktop_registration_hole_diameter = 4;
worktop_registration_hole_count = 3; // [1:1:6]
worktop_registration_end_margin = 75;

// Blind depth into the UNDERSIDE of the separate worktop.
worktop_registration_blind_depth = 8;

// The rows are automatically centered front-to-back on the front/rear top
// stretchers. With a full carcass top, those same front/rear row positions are
// used to provide two alignment rows.



// Internal section: Hidden


// Select a full sheet top or front/rear stretchers.
top_style = "stretchers"; // [stretchers, full]
top_stretcher_depth = 90;



// Internal section: Hidden


// panel            = thin applied back, nailed/screwed around carcass edges.
// structural_panel = solid carcass-thickness back captured at the rear edge;
//                    it automatically follows carcass butt/dado/tab_slot joinery.
// stretchers        = structural rear rails made from carcass material.
// none              = open back.
back_style = "none";

// Applied-panel position. Used only when back_style = "panel".
// structural_panel is always flush with the cabinet rear edge.
back_inset = 0;

// Structural rear stretchers. They sit inside the rear edge and use the same
// side-joinery style as the carcass (butt / dado / tab_slot).
back_stretcher_count = 2; // [1:1:4]
back_stretcher_height = 100;
back_stretcher_edge_margin = 30;
back_stretcher_inset = 0;



// Internal section: Hidden


// One selector controls the fixed cabinet-to-side-panel joints.
joinery_style = "butt"; // [butt, screw, dado, tab_slot]

// Total added clearance around TAB/SLOT joints relative to the mating part.
// Positive values make the joint looser. Start small and cut a test coupon.
joint_fit_clearance = 0.20; // [0:0.05:2]

// Independent clearance for CARCASS dados.
// This changes pocket width/length around the mating panel, not dado depth.
dado_fit_clearance = 0.20; // [0:0.05:2]

// Blind dado depth into each cabinet side.
// Used only when joinery_style = "dado".
dado_depth = 6; // [2:0.5:18]

// Tab count can be adaptive or fixed.
// "adaptive" is recommended: the count is calculated independently for each
// edge length so a 90 mm stretcher does not receive the same number of joints
// as a 600 mm shelf.
// Used only when joinery_style = "tab_slot".
tab_count_mode = "adaptive"; // [adaptive, fixed]

// Used only when tab_count_mode = "fixed".
joint_tab_count = 3; // [1:1:8]

// Used by adaptive mode. This is an approximate span-per-tab target, not the
// actual gap. With the defaults, ~600 mm edges get about 3 tabs while ~90-100
// mm edges get 1.
target_tab_spacing = 180;
max_auto_tab_count = 6; // [1:1:10]

// Joint geometry.
joint_tab_width = 35;
joint_tab_edge_margin = 15;

// Minimum amount of solid material requested between adjacent tab/slot
// features. Adaptive mode will reduce the tab count before violating this.
minimum_joint_web = 30;

// CNC corner relief for square tabs:
//   dogbone = diagonal relief, minimum material removal
//   t_bone   = relief along the longest slot wall, preserving the other wall
// Leave "none" for laser cutting or if CAM handles relief.
slot_corner_relief = "none"; // [none, dogbone, t_bone]


// Internal section: Hidden


// Used only when joinery_style = "butt".
// These are through-holes in the cabinet SIDE panels, centered on the edge
// of each mating bottom/top/shelf/divider/separator/toe-kick part. They act as
// screw/pilot-hole guides so a butt-jointed part can be located consistently.
include_butt_registration_holes = false;
butt_registration_hole_diameter = 4;
butt_registration_target_spacing = 180;
butt_registration_edge_margin = 35;



// Internal section: Hidden


// Shared mounting depth for decorative DOORS and DRAWER FACES.
//
// overlay     = current behavior: the front sits proud of the carcass face.
// inset_flush = the visible front surface is flush with the carcass front
//               plane and the panel thickness extends into the opening.
front_mount_style = drawer_face_style == "inset_flush" ? "inset_flush" : "overlay";

// Extra air space behind a flush/inset front. Drawer boxes, shelves,
// separators and slide hardware are automatically kept behind this plane.
inset_front_back_clearance = drawer_face_back_clearance;

// OVERLAY mode only:
// Overlay-only width. "partial" stays between side-panel outer edges;
// "full" covers the side-panel front edges. True inset fronts are controlled
// only by front_mount_style = "inset_flush".
overlay_width_style = "partial"; // [partial, full]

front_edge_reveal = 0;

// When true, the lowest visible front covers the front edge of the raised
// cabinet bottom. Drawer boxes / cabinet interior remain inside the opening.
fronts_cover_bottom_lip = true;



// Internal section: Hidden


// Hole pattern dimensions shared by drawer and door pulls.
// Enable/placement controls live in the relevant Drawer / Door sections.
handle_hole_pattern = "two_hole"; // [single_hole, two_hole]
handle_hole_diameter = 5;
handle_hole_spacing = 96;



// Internal section: Hidden


// Gap between adjacent decorative doors.
door_gap = 3;

// Relative widths for side-by-side door bays. Only the first door_count
// entries are used. Equal weights preserve equal-width doors.
// Example: [1,1.5,2] creates progressively wider door bays.
door_width_weights = [1,1,1,1];

// For a DOORS-ONLY wall cabinet, extend decorative doors to the cabinet top.
// Combo cabinets intentionally stop below the drawer region.
wall_doors_flush_top = true;



// Internal section: Hidden


// fixed = built-in shelves using the selected carcass joinery_style.
// adjustable = loose shelves plus shelf-pin hole rows in both cabinet sides.
shelf_style = "fixed"; // [fixed, adjustable]

// Number of shelf PANELS supplied. In adjustable mode their preview locations
// are evenly spaced, but they can be moved to any drilled shelf-pin position.
door_shelf_count = 1; // [0:1:6]

// Adjustable-shelf geometry.
adjustable_shelf_side_clearance = 2;
adjustable_shelf_hole_diameter = 5;
adjustable_shelf_hole_spacing = 32;
adjustable_shelf_front_setback = 37;
adjustable_shelf_rear_setback = 37;
adjustable_shelf_hole_bottom_margin = 50;
adjustable_shelf_hole_top_margin = 50;

// through works for CNC or laser.
// blind is more cabinet-like; export pocket_layout for the drilling operation.
adjustable_shelf_hole_type = "through"; // [through, blind]
adjustable_shelf_hole_depth = 10;



// Internal section: Hidden


// Used by mixed bays of type "door" or "open".
// Each bay can independently use loose adjustable shelves or structural fixed
// shelves. Fixed shelves inherit the main carcass joinery_style at the bay
// boundaries (cabinet sides / full-depth mixed-bay partitions).
mixed_bay_shelf_styles = ["adjustable","adjustable","adjustable","adjustable"];

// Number of shelf PANELS supplied in each bay.
mixed_bay_shelf_counts = [0,0,2,2];



// Internal section: Hidden


include_door_handle_holes = false;

// Door pulls are placed near the opening edge, opposite the hinges.
door_handle_from_open_edge = 50;
door_handle_from_top = 90;
door_handle_orientation = "vertical"; // [vertical, horizontal]



// Internal section: Hidden


// Number of decorative doors in each mixed door bay. Supported values are 1
// and 2. A two-door bay creates an equal pair that hinges at the OUTER bay
// edges and meets at the center using door_gap.
mixed_bay_door_counts = [1,1,1,1];

// Used only for SINGLE-door mixed bays. Set the hinge side explicitly so the
// door can mount to either the cabinet side or neighboring full-depth partition.
// Paired doors ignore this array and automatically hinge left/right outward.
mixed_bay_door_hinge_sides = ["left","right","left","right"];



// Internal section: Hidden


// Basic starting points only. Verify all values against the selected hardware.
// euro_35mm = blind 35 mm cup pocket in door + fixing holes + cabinet plate holes
// screw_holes = no cup pocket; only door/cabinet mounting holes
hinge_style = "none"; // [none, euro_35mm, screw_holes]



// One-door cabinets can choose which cabinet side carries the hinges.
// Two-door cabinets automatically hinge at the outer left/right edges.
single_door_hinge_side = "left"; // [left, right]

hinge_count = 2; // [2:1:5]
hinge_end_offset = 100;

// Door-side geometry
hinge_cup_diameter = 35;
hinge_cup_depth = 12;
hinge_cup_center_from_door_edge = 22.5;
hinge_door_fixing_hole_diameter = 3;
hinge_door_fixing_hole_spacing = 45;

// Cabinet-side mounting-plate geometry.
// 37 mm front setback and 32 mm vertical spacing are common Euro-system
// starting points but MUST be checked against the selected hinge/plate.
hinge_plate_hole_diameter = 5;
hinge_plate_center_from_front = 37;
hinge_plate_hole_spacing = 32;

// Hardware presets may disable unsupported operations instead of leaving stale drilling.
hinge_door_fixing_enabled = true;
hinge_plate_holes_enabled = true;



// Internal section: Hidden


// Cabinets with more than two side-by-side doors automatically receive a
// full-depth vertical partition behind every inter-door gap. These partitions
// provide hinge mounting surfaces AND separate the door compartments.
//
// Partition-to-carcass joinery ALWAYS follows the main carcass joinery_style
// and uses the same fit/depth settings.
include_door_hinge_partitions = true;

// Clearance used for fixed-shelf cross-lap notches in the partitions.
door_hinge_partition_shelf_clearance = 0.5;



// Internal section: Hidden


// Decorative applied drawer faces can be omitted for a simpler drawer.
// When omitted, optional handle holes move automatically to the box front.
include_drawer_faces = drawer_face_style != "none";

// Gap between adjacent decorative drawer faces.
drawer_gap = 3;

// Shared vertical sizing recipe. "graduated" makes lower drawers progressively
// taller. "custom_weights" uses one positive weight per drawer.
drawer_height_mode = "equal"; // [equal, graduated, custom_weights]
drawer_graduated_step = 0.35;
drawer_height_weights = [1,1,1,1];



// Internal section: Hidden


// Used only by bays whose mixed_bay_types entry is "drawers".
// Arrays are indexed by BAY, not by drawer-only bay number.
mixed_bay_drawer_counts = [4,2,4,4];
mixed_bay_drawer_height_modes = ["equal","equal","equal","equal"];
mixed_bay_drawer_graduated_steps = [0.35,0.35,0.35,0.35];

// One row of custom drawer-height weights per bay.
mixed_bay_drawer_height_weights = [
    [1,1,1,1,1,1,1,1],
    [1,1,1,1,1,1,1,1],
    [1,1,1,1,1,1,1,1],
    [1,1,1,1,1,1,1,1]
];



// Internal section: Hidden


// Multiple banks split the drawer region into side-by-side columns.
// "shared" = all banks use the shared drawer_count / height recipe.
// "independent" = each bank can use a different drawer count / height recipe.
drawer_bank_count = 1; // [1:1:4]
drawer_bank_layout_mode = "shared"; // [shared, independent]

// Relative bank widths. Only the first drawer_bank_count entries are used.
// Example: [1,2] makes bank 2 twice the clear width of bank 1.
drawer_bank_width_weights = [1,1,1,1];

// Used only when drawer_bank_layout_mode = "independent".
drawer_bank_drawer_counts = [4,4,4,4];
drawer_bank_height_modes = ["equal","equal","equal","equal"];
drawer_bank_graduated_steps = [0.35,0.35,0.35,0.35];

// One row of custom height weights per bank.
drawer_bank_height_weights = [
    [1,1,1,1,1,1,1,1],
    [1,1,1,1,1,1,1,1],
    [1,1,1,1,1,1,1,1],
    [1,1,1,1,1,1,1,1]
];

// Decorative gap over structural bank partitions.
drawer_bank_face_gap = drawer_gap;

// Vertical bank partitions.
drawer_bank_partition_rear_clearance = 10;
drawer_bank_partition_joinery = "match_carcass"; // [match_carcass, butt, dado, tab_slot]




// Called while wood_rail_depth is evaluated, which happens before the resolved
// stock thicknesses further down this file are assigned. OpenSCAD would see
// those variables as undef, so the thicknesses are resolved directly here from
// the public stock inputs (defined at the top of the file).
function standalone_pre_resolved_box_depth() =
    drawer_design_basis == "enclosure"
        ? max(
            1,
            enclosure_usable_depth
            - (
                drawer_face_style == "inset_flush"
                    ? max(
                        front_setback,
                        resolved_stock_thickness(
                            drawer_front_stock,
                            custom_drawer_front_thickness
                        )
                        + max(0,drawer_face_back_clearance)
                      )
                    : front_setback
              )
            - drawer_back_clearance
          )
        : drawer_design_basis == "inside_clear"
            ? max(
                1,
                target_box_inside_depth
                + 2*resolved_stock_thickness(
                    drawer_stock,
                    custom_drawer_material_thickness
                  )
              )
            : drawer_design_basis == "modular_grid"
                ? max(
                    1,
                    drawer_module_pitch_y
                    * max(1,round(drawer_module_count_y))
                    + 2*max(0,drawer_module_edge_clearance_y)
                    + 2*resolved_stock_thickness(
                        drawer_stock,
                        custom_drawer_material_thickness
                      )
                  )
                : max(1,target_box_outside_depth);


// Resolved earlier for a public computed default: wood_rail_depth

// Internal section: Hidden


// Fixed by design in V24. Kept internally so older geometry helpers remain
// compatible, but it is no longer exposed in the Customizer.
back_joinery = "simple";




// Internal section: Standalone Drawer Resolver - Hidden


standalone_drawer_mode = true;

standalone_mount_side_clearance =
    drawer_mount == "metal_slides"
        ? metal_slide_clearance_per_side
        : drawer_mount == "wood_rails"
            ? wood_rail_thickness + wood_rail_side_clearance
            : drawer_free_fit_clearance_per_side;

standalone_effective_front_setback =
    drawer_face_style == "inset_flush"
        ? max(
            front_setback,
            drawer_front_thickness
            + max(0,drawer_face_back_clearance)
          )
        : front_setback;

standalone_drawer_outer_width =
    drawer_design_basis == "enclosure"
        ? max(
            1,
            enclosure_opening_width
            - 2*standalone_mount_side_clearance
          )
        : drawer_design_basis == "inside_clear"
            ? max(
                1,
                target_box_inside_width
                + 2*drawer_material_thickness
              )
            : drawer_design_basis == "modular_grid"
                ? max(
                    1,
                    drawer_module_pitch_x
                    * max(1,round(drawer_module_count_x))
                    + 2*max(0,drawer_module_edge_clearance_x)
                    + 2*drawer_material_thickness
                  )
                : max(1,target_box_outside_width);

standalone_drawer_box_depth =
    drawer_design_basis == "enclosure"
        ? max(
            1,
            enclosure_usable_depth
            - standalone_effective_front_setback
            - drawer_back_clearance
          )
        : drawer_design_basis == "inside_clear"
            ? max(
                1,
                target_box_inside_depth
                + 2*drawer_material_thickness
              )
            : drawer_design_basis == "modular_grid"
                ? max(
                    1,
                    drawer_module_pitch_y
                    * max(1,round(drawer_module_count_y))
                    + 2*max(0,drawer_module_edge_clearance_y)
                    + 2*drawer_material_thickness
                  )
                : max(1,target_box_outside_depth);

standalone_drawer_box_height =
    drawer_design_basis == "outside_box"
        ? max(1,target_box_outside_height)
        : drawer_design_basis == "inside_clear"
            ? max(
                1,
                target_box_inside_height
                + drawer_bottom_inset
                + drawer_bottom_thickness
              )
            : drawer_design_basis == "modular_grid"
                ? max(
                    1,
                    drawer_module_inside_height
                    + drawer_bottom_inset
                    + drawer_bottom_thickness
                  )
                : enclosure_height_mode == "fill_opening"
                ? max(
                    1,
                    enclosure_opening_height
                    - 2*max(0,drawer_vertical_clearance)
                  )
                : enclosure_height_mode == "inside_clear"
                    ? max(
                        1,
                        enclosure_target_inside_height
                        + drawer_bottom_inset
                        + drawer_bottom_thickness
                      )
                    : max(1,enclosure_target_box_height);

standalone_enclosure_opening_width =
    drawer_design_basis == "enclosure"
        ? max(1,enclosure_opening_width)
        : standalone_drawer_outer_width
          + 2*standalone_mount_side_clearance;

standalone_enclosure_usable_depth =
    drawer_design_basis == "enclosure"
        ? max(1,enclosure_usable_depth)
        : standalone_drawer_box_depth
          + standalone_effective_front_setback
          + drawer_back_clearance;

standalone_enclosure_opening_height =
    drawer_design_basis == "enclosure"
        ? max(1,enclosure_opening_height)
        : standalone_drawer_box_height
          + 2*max(0,drawer_vertical_clearance);

standalone_drawer_vertical_clearance =
    max(
        0,
        (
            standalone_enclosure_opening_height
            - standalone_drawer_box_height
        )/2
    );

standalone_drawer_box_x0 =
    max(
        0,
        (
            standalone_enclosure_opening_width
            - standalone_drawer_outer_width
        )/2
    );

standalone_drawer_box_z =
    standalone_drawer_vertical_clearance;

standalone_drawer_face_width =
    !include_drawer_faces
        ? 0
        : drawer_face_size_mode == "custom"
            ? max(1,custom_drawer_face_width)
            : drawer_face_style == "inset_flush"
                ? max(
                    1,
                    standalone_enclosure_opening_width
                    - 2*max(0,drawer_face_inset_reveal)
                  )
                : standalone_enclosure_opening_width
                  + 2*max(0,drawer_face_overlay_horizontal);

standalone_drawer_face_height =
    !include_drawer_faces
        ? 0
        : drawer_face_size_mode == "custom"
            ? max(1,custom_drawer_face_height)
            : drawer_face_style == "inset_flush"
                ? max(
                    1,
                    standalone_enclosure_opening_height
                    - 2*max(0,drawer_face_inset_reveal)
                  )
                : standalone_enclosure_opening_height
                  + 2*max(0,drawer_face_overlay_vertical);

standalone_drawer_face_x =
    (
        standalone_enclosure_opening_width
        - standalone_drawer_face_width
    )/2;

standalone_drawer_face_z =
    (
        standalone_enclosure_opening_height
        - standalone_drawer_face_height
    )/2;


// Internal section: Resolved Configuration - Hidden


// Direct API values above are the source of truth. These active aliases only
// adapt them to the shared geometry engine. No recipe/preset logic lives here.
active_mount_style = cabinet_mount_style;
active_base_style = active_mount_style == "wall" ? "flat" : base_style;

has_toe_kick =
    active_mount_style == "floor"
    && active_base_style == "toe_kick"
    && custom_toe_kick_height > 0;

toe_kick_height = has_toe_kick ? custom_toe_kick_height : 0;
toe_kick_setback = has_toe_kick ? custom_toe_kick_setback : 0;
bottom_above_toe = has_toe_kick ? custom_bottom_above_toe : 0;
side_toe_kick_cutout = has_toe_kick ? custom_side_toe_kick_cutout : "none";

base_hardware_active =
    active_mount_style == "floor"
    && (active_base_style == "leveling_feet" || active_base_style == "casters");
base_mounting_plate_active = base_hardware_active && include_base_mounting_plate;
worktop_active = include_worktop;

front_width_style = overlay_width_style == "full" ? "full_overlay" : "inset";

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

// Shared-core compatibility.
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

// Shared-core compatibility. The benchtop branch exposes this as a user control.
extend_top_drawer_face_to_top = false;

// Profile-specific validation threshold used only for console guidance.
drawer_face_height_warning_threshold = 70;


// Shared-core V22 features: generalized mixed vertical bays, independent
// drawer stacks, weighted widths, full-depth structural partitions,
// operation-specific pocket exports, and optional applied drawer faces.
//
// ---------------------------
// SHARED IMPLEMENTATION
// ---------------------------
carcass_joint_geometry = joinery_style == "screw" ? "butt" : joinery_style;
carcass_registration_enabled = joinery_style == "screw" || include_butt_registration_holes;
drawer_joint_geometry = drawer_joinery_style == "screw" ? "butt" : drawer_joinery_style;
include <core.scad>
include <layouts.scad>


