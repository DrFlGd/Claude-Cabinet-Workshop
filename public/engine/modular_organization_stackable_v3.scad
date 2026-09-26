//
// Modular Organization Stackable — v3 (Shared Core)
// Keep this file in the same folder as cabinet_core.scad and cabinet_layouts.scad.
// OpenSCAD source intended for CNC/laser-cut sheet goods.
// Units: millimeters.
//
// Modular stackable cabinet front end.
//
// The side panels use a complementary top/bottom lap:
//   - a female center recess along the top edge;
//   - a matching fully-radiused male center tongue along the bottom edge.
// Stacked modules overlap vertically by stack_interface_depth while the
// front/rear end pads carry the cabinet-bottom plane.
//
// A separate four-rail base frame uses the same top recess and the selected
// carcass joinery at its corners.
//
// Manufacturing outputs generate ONE module plus ONE base frame. The assembly
// preview may show several identical modules stacked to demonstrate fit.
//
// V8 separates back-panel joinery from the main carcass joinery and adds
// optional horizontal separators between adjacent drawers.
//
// Back panel:
//   - simple:   full-width, full-height applied back for nailing/screwing to
//               the rear edges of the carcass; no joinery is generated.
//   - dado:     inset back edges enter blind grooves in the side, bottom,
//               and rear-top members.
//   - tab_slot: inset back receives tabs with matching slots.
// The default is "simple".
//
// Drawer separators:
//   - optional; only generated between adjacent drawers.
//   - full:       a full-depth horizontal separator.
//   - stretchers: front/rear cross stretchers at each drawer boundary.
// The separator pieces use the selected main carcass joinery_style at the sides.
//
// Stable per-part colors and adaptive tab counts from V7 are retained.
//
// V20 also makes the lowest front panels overlay the front edge of the raised
// cabinet bottom by default. The visible drawer/door front can therefore hide
// the bottom-panel lip while the actual drawer box remains safely above it.
//
// V21 corrects the simple applied back so it begins at the UNDERSIDE of the
// raised cabinet bottom rather than extending through the toe-kick area.
//
// V22 corrects tab/slot back construction: the back remains a full-width
// applied panel. Side edges are no longer scalloped away for side tabs.
//
// V23 added toe-kick side cutouts.
//
// V24 simplifies the back completely:
//   - the back is ALWAYS a thin applied panel;
//   - it has NO tabs, slots, dados, or notches;
//   - it is intended to be nailed or screwed around the rear carcass edges;
//   - main carcass joinery_style does not alter the back panel in any way.
//
// V25 turns the shop-made wood drawer slide into a mating two-piece system.
//
// V26 adds assembly-registration drilling.
//
// V27 explicitly groups the UPPER wooden slide runners with the drawer.
//
// V28 adds basic front/hardware options.
//
// V29 adds adjustable shelves, corrected dog-bones, and print_layout.
//
// V20 adds configurable drawer-box joinery.
//
// V21 separates carcass/drawer tab-slot and dado fit controls.
//
// V22 adds exportable blind-operation guides to cut_layout.
//
// V23 attempted to embed blind-operation guides by subtracting narrow rings.
//
// V24 keeps cut_layout and pocket_layout as separate, clean geometries.
//
// V25 normalized SVG page metadata after export.
//
// V26 aligns cut_layout and pocket_layout with a shared dummy export frame.
//
// V27 adds matching drawer-box-front <-> decorative-face registration holes.
//
// Historical note: V28 introduced the original preset resolver. V26 removes
// preset-driven geometry in favor of direct configuration + external recipes.
// Wall mounting and structural back-stretcher construction remain supported.
//
// Wall mode:
//   - puts the cabinet bottom at Z=0;
//   - removes the toe-kick rail and all toe-kick joinery/registration holes;
//   - disables side toe-kick notches;
//   - extends a simple back panel down to the cabinet bottom.
//
// Back construction:
//   - panel:      existing thin applied back;
//   - stretchers: structural horizontal mounting/strength rails at the rear;
//   - none:       no rear panel or rear stretchers.
//
// V29 makes doors-only wall cabinets extend their decorative doors to the
// cabinet top edge by default. The internal opening/top panel geometry remains
// unchanged; this is a visible-front overlay only.
//
// V30 backports the granular ASSEMBLY VISIBILITY controls from the benchtop
// drawer-cabinet branch. These toggles are preview-only: they affect assembly,
// carcass_only, and drawers_only views, but NEVER remove geometry from
// cut_layout, pocket_layout, or print_layout.
//
// Hardware dimensions remain intentionally exposed so they can be changed to
// match a specific manufacturer's drawing before production.
//
// Carcass joinery:
//   - butt:     simple panels between the cabinet sides.
//   - dado:     fixed cross-panels enter blind dados in the cabinet sides.
//   - tab_slot: fixed cross-panels receive tabs that pass through matching
//               side-panel slots; optional CNC dogbone / T-bone relief is available.
//
// Drawer-box joinery is controlled independently from carcass joinery.
// Drawer tab/slot uses the same fit, adaptive-tab, and corner-relief settings as
// the carcass unless drawer-specific dado depths are noted below.
//
// DADO CNC WORKFLOW:
//   "cut_layout" contains the outside profiles and all THROUGH features.
//   "pocket_layout" contains blind dado/pocket geometry in the SAME
//   side-panel locations/origin as cut_layout. Export it separately and assign
//   the dado_depth as the pocketing depth in CAM. A 2D DXF/SVG cannot itself
//   encode pocket depth.
//
// TAB/SLOT CNC WORKFLOW:
//   tab_slot creates actual through slots in the side-panel cut profiles.
//   "dogbone" moves the cutter center diagonally INWARD from each nominal
//   corner by radius/sqrt(2), so the cutter just clears the square corner
//   while removing much less extra material than the old corner-centered cut.
//   "t_bone" moves the cutter center inward along the slot's longest wall,
//   keeping the other wall straight. Leave "none" for laser cutting or when
//   CAM adds its own corner relief.
//
// IMPORTANT:
//   Verify all fit values, slide-hole locations, cutter compensation, and
//   material thickness with a test coupon before cutting production parts.
//

// Customizer sections use Part / Basic and Part / Advanced naming to
// emulate a nested hierarchy in OpenSCAD's flat Customizer list.

// V27 OPENSCAD-NATIVE RECIPES
// Keep the matching .json file beside this .scad file. OpenSCAD Customizer
// exposes those recipes in its Preset dropdown. Selecting one applies ordinary
// editable parameter values; no persistent preset resolver exists in geometry.
//
/* [Output / Basic] */

// Stable Configurator API identity. Recipes may change design_name in the UI,
// but design_type is fixed by this front end.
design_name = "Two-Drawer Stackable Module";

/* [Hidden] */
design_type = "stackable";
config_api_version = 1;

/* [Output / Basic] */

// Structured dimensions are echoed to the OpenSCAD console in lines beginning
// with DIM|. "full" adds per-door, per-shelf, and per-drawer assembled sizes.
dimension_report = "full"; // [off, summary, full]

// Machine-readable design-health checks are echoed as
// CHECK|SEVERITY|CODE|MESSAGE for the website and package exporter.
validation_report = "summary"; // [off, summary, verbose]


/* [System / Advanced - Interface Contracts] */

// Modular Organization v3 is a fork of Modular Storage v35.  The fork exposes
// physical connection interfaces, owned keepout zones, and compatibility keys
// as machine-readable records so project-level tools can reason about modules
// without duplicating the geometry rules.
system_contract_report = "summary"; // [off, summary, verbose]

// enforce   = geometry-specific safe policies remain authoritative and
//             interface keepout conflicts are validation errors.
// warn_only = keepout conflicts are reported as warnings.
// off       = suppress interface-owned keepout validation only.
interface_keepout_policy = "enforce"; // [enforce, warn_only, off]


// What OpenSCAD displays/exports.
output_mode = "assembly"; // [assembly, cut_layout, engrave_layout, calibration_coupon_cut, calibration_coupon_pocket, calibration_coupon_engrave, print_layout, pocket_layout, pocket_carcass_dados, pocket_drawer_dados, pocket_bottom_grooves, pocket_shelf_pins, pocket_hinge_cups, pocket_face_registration, pocket_base_hardware, pocket_worktop_registration, pocket_face_frame_dados, pocket_ganging, bom, carcass_only, drawers_only]

// Circle/cylinder smoothness. Mostly affects round drill holes and CNC corner relief.
circle_segments = 48; // [12:4:96]
$fn = circle_segments;

// Stable colors make it easier to identify the same part in assembly and
// flat-layout views. "material" returns to a plywood-like single material
// palette; "monochrome" uses neutral gray.
color_mode = "by_part"; // [by_part, material, monochrome]


/* [Output / Advanced - Assembly Visibility] */

// Visual-only switches for inspecting the assembled model.
// Manufacturing outputs remain complete regardless of these settings.
show_carcass_sides = true;
show_carcass_bottom = true;
show_carcass_top = true;
show_toe_kick = true;
show_base_hardware = true;
show_worktop = false;
show_stack_base = true;
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
show_drawer_faces = true;
show_drawer_slide_parts = true;

show_doors = true;


/* [Stackable / Basic - Module] */

// Direct module configuration. Recipes are applied by the configurator and do
// not remain as hidden modes inside the geometry engine.
module_type = "drawers"; // [drawers, open, door]
drawer_count = 2; // [0:1:8]
door_shelf_count = 1; // [0:1:6]

cabinet_width = 500;
cabinet_height = 360;
cabinet_depth = 500;


/* [Stackable / Basic - Interface & Base] */

// Preview several identical modules as one stack. Manufacturing outputs still
// contain one module plus one base-frame set.
stack_preview_count = 4; // [1:1:8]
include_stack_base = true;

// Vertical overlap between neighboring modules. The cabinet bottom panel is
// automatically raised to this height, leaving the center side-panel tongue
// below it.
stack_interface_depth = 18;

// Separate base-frame rail height.
stack_base_height = 70;


/* [Stackable / Advanced - Interface Fit] */

// Front/rear end pads remain full-height; the center span becomes the mating
// tongue/recess. Keep these margins at least as deep as the top stretchers.
stack_interface_front_margin = 80;
stack_interface_back_margin = 80;

// Radius for BOTH tangent shoulders of the stacking transition.
//
// The profile is now a fully-radiused S transition:
//   high end pad -> radius -> vertical tangent -> radius -> center tongue.
//
// It is automatically kept large enough for the selected cutter + fit
// clearance and small enough for two fillets to fit inside the interface
// depth. With the default 18 mm interface depth, 9 mm gives two tangent
// quarter-circles with no vertical segment between them.
stack_interface_corner_radius = 9;

// Clearance is applied by offsetting the COMPLETE female mating profile.
// The male bottom and female top therefore come from one canonical geometry.
stack_interface_clearance = 0.60; // [0:0.05:2]

// Assembly-only separation for inspecting the mating geometry.
stack_preview_explode_gap = 0; // [0:1:50]


/* [Stackable / Advanced - Top Rails] */

// Stackable modules intentionally use front/rear top stretchers rather than a
// full top so the next module's center tongue can enter the top recess.
top_stretcher_depth = 70;


/* [Hidden] */

// Single full-width module bay. module_type directly controls its contents.
cabinet_layout_mode = "mixed_bays";
mixed_bay_count = 1;
mixed_bay_types = ["drawers"];
mixed_bay_width_weights = [1];
mixed_bay_front_gap = 3;
include_mixed_bay_partitions = false;



/* [Sizing / Basic - Fit Target] */

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


/* [Sizing / Advanced - Modular Grid] */

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

/* [Ganging / Basic - Alignment & Connection] */

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


/* [Ganging / Advanced - Hardware & Pattern] */

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

/* [Materials / Basic - Nominal Stock] */

// Convenience selectors for common sheet-stock thicknesses.
// "custom_mm" preserves the editable metric thickness below and is the safest
// choice for CNC joinery when you have measured the actual sheet thickness.
//
// Nominal inch selections convert the stated fraction directly to millimeters.
// Real plywood often measures thinner than its nominal label, so measure stock
// and use custom_mm when fit is critical.
carcass_stock = "3/4_nominal"; // [custom_mm, 1/8_nominal, 1/4_nominal, 3/8_nominal, 1/2_nominal, 5/8_nominal, 3/4_nominal, 1_nominal]
back_stock = "1/4_nominal"; // [custom_mm, 1/8_nominal, 1/4_nominal, 3/8_nominal, 1/2_nominal, 5/8_nominal, 3/4_nominal, 1_nominal]
drawer_stock = "1/2_nominal"; // [custom_mm, 1/8_nominal, 1/4_nominal, 3/8_nominal, 1/2_nominal, 5/8_nominal, 3/4_nominal, 1_nominal]
drawer_bottom_stock = "1/4_nominal"; // [custom_mm, 1/8_nominal, 1/4_nominal, 3/8_nominal, 1/2_nominal, 5/8_nominal, 3/4_nominal, 1_nominal]
drawer_front_stock = "3/4_nominal"; // [custom_mm, 1/8_nominal, 1/4_nominal, 3/8_nominal, 1/2_nominal, 5/8_nominal, 3/4_nominal, 1_nominal]
door_stock = "3/4_nominal"; // [custom_mm, 1/8_nominal, 1/4_nominal, 3/8_nominal, 1/2_nominal, 5/8_nominal, 3/4_nominal, 1_nominal]


/* [Materials / Advanced - Measured Thicknesses] */

// Used whenever the matching stock selector above is set to custom_mm.
// Defaults intentionally preserve the existing Utility Cabinet geometry.
custom_carcass_thickness = 18;
custom_back_thickness = 6;
custom_drawer_material_thickness = 12;
custom_drawer_bottom_thickness = 6;
custom_drawer_front_thickness = 18;
custom_door_thickness = 18;


/* [Hidden] */

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

material_thickness =
    resolved_stock_thickness(
        carcass_stock,
        custom_carcass_thickness
    );

back_thickness =
    resolved_stock_thickness(
        back_stock,
        custom_back_thickness
    );

drawer_material_thickness =
    resolved_stock_thickness(
        drawer_stock,
        custom_drawer_material_thickness
    );

drawer_bottom_thickness =
    resolved_stock_thickness(
        drawer_bottom_stock,
        custom_drawer_bottom_thickness
    );

drawer_front_thickness =
    resolved_stock_thickness(
        drawer_front_stock,
        custom_drawer_front_thickness
    );

door_thickness =
    resolved_stock_thickness(
        door_stock,
        custom_door_thickness
    );


/* [Hidden] */

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


/* [Hidden] */

// For leveling_feet / casters, a full-footprint mounting plate can be placed
// beneath the carcass. It uses carcass stock and is included in CUT/BOM.
include_base_mounting_plate = false;
base_mounting_plate_side_inset = 0;
base_mounting_plate_front_inset = 0;
base_mounting_plate_back_inset = 0;

// Bottom-panel width.
// joined: existing carcass bottom fits between / joins into the side panels.
// full_width: bottom spans the full cabinet footprint; side panels sit on top
// of it. This is especially useful for caster/leveler loads when no separate
// mounting plate is used.
bottom_width_style = "joined";

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


/* [Hidden] */

// Adds a separate work surface ABOVE the carcass top. This is independent of
// the internal full-top / stretcher construction below it.
include_worktop = false;
worktop_thickness = 38;

// Positive values extend beyond the cabinet footprint.
worktop_side_overhang = 15;
worktop_front_overhang = 25;
worktop_back_overhang = 0;


/* [Hidden] */

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


/* [Hidden] */

// Select a full sheet top or front/rear stretchers.
custom_top_style = "stretchers";
// top_stretcher_depth set in Stackable / Advanced - Top Rails


/* [Carcass / Basic - Back] */

// panel            = thin applied back, nailed/screwed around carcass edges.
// structural_panel = solid carcass-thickness back captured at the rear edge;
//                    it automatically follows carcass butt/dado/tab_slot joinery.
// stretchers        = structural rear rails made from carcass material.
// none              = open back.
back_style = "structural_panel"; // [structural_panel, panel, stretchers, none]

// Applied-panel position. Used only when back_style = "panel".
// structural_panel is always flush with the cabinet rear edge.
back_inset = 0;

// Structural rear stretchers. They sit inside the rear edge and use the same
// side-joinery style as the carcass (butt / dado / tab_slot).
back_stretcher_count = 2; // [1:1:4]
back_stretcher_height = 100;
back_stretcher_edge_margin = 30;
back_stretcher_inset = 0;


/* [Carcass / Advanced - Joinery] */

// One selector controls the fixed cabinet-to-side-panel joints.
joinery_style = "butt"; // [butt, dado, tab_slot]

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

// Bottom-panel tab placement can differ from the rest of the carcass.
// automatic = use the normal evenly-distributed carcass tab pattern.
// stack_safe = put the first/last tabs inside the full-height stacking pads,
// avoiding the rounded bottom stacking shoulders; inner tabs stay distributed.
// custom = use bottom_tab_custom_centers (centers measured from the FRONT edge).
bottom_tab_placement = "stack_safe"; // [automatic, edge_biased, stack_safe, custom]

// Used only when bottom_tab_placement = "custom". Values are millimeters from
// the front cabinet edge. Example for a 500 mm deep cabinet:
// [40,250,460]
// Invalid/out-of-range centers are ignored; if none remain, the automatic
// pattern is used as a safe fallback.
bottom_tab_custom_centers = [];

// Minimum amount of solid material requested between adjacent tab/slot
// features. Adaptive mode will reduce the tab count before violating this.
minimum_joint_web = 30;

// CNC corner relief for square tabs:
//   dogbone = diagonal relief, minimum material removal
//   t_bone   = relief along the longest slot wall, preserving the other wall
// Leave "none" for laser cutting or if CAM handles relief.
slot_corner_relief = "none"; // [none, dogbone, t_bone]

/* [Carcass / Advanced - Edge-aware Joinery] */

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

cnc_tool_diameter = 6.35;


/* [Carcass / Advanced - Butt Registration] */

// Used only when joinery_style = "butt".
// These are through-holes in the cabinet SIDE panels, centered on the edge
// of each mating bottom/top/shelf/divider/separator/toe-kick part. They act as
// screw/pilot-hole guides so a butt-jointed part can be located consistently.
include_butt_registration_holes = true;
butt_registration_hole_diameter = 4;
butt_registration_target_spacing = 180;
butt_registration_edge_margin = 35;


/* [Fronts / Basic - Gaps & Reveals] */

// Shared mounting depth for decorative DOORS and DRAWER FACES.
//
// overlay     = current behavior: the front sits proud of the carcass face.
// inset_flush = the visible front surface is flush with the carcass front
//               plane and the panel thickness extends into the opening.
front_mount_style = "overlay"; // [overlay, inset_flush]

// Extra air space behind a flush/inset front. Drawer boxes, shelves,
// separators and slide hardware are automatically kept behind this plane.
inset_front_back_clearance = 2; // [0:0.25:10]

// OVERLAY mode only:
// "inset" is the historical narrow-overlay width: fronts stay between the
// side-panel outer edges but still sit proud of the carcass.
// "full_overlay" extends fronts across the side-panel front edges.
// inset_flush ignores this selector and fits each front inside its actual
// cabinet/bay opening using front_edge_reveal.
overlay_width_style = "partial"; // [partial, full]

front_edge_reveal = 2;

// When true, the lowest visible front covers the front edge of the raised
// cabinet bottom. Drawer boxes / cabinet interior remain inside the opening.
fronts_cover_bottom_lip = true;


/* [Front Hardware / Basic - Shared Hole Pattern] */

// Hole pattern dimensions shared by drawer and door pulls.
// Enable/placement controls live in the relevant Drawer / Door sections.
handle_hole_pattern = "two_hole"; // [single_hole, two_hole]
handle_hole_diameter = 5;
handle_hole_spacing = 96;


/* [Doors / Basic - Layout & Width Ratios] */

// Gap between adjacent decorative doors.
door_gap = 3;

// Relative widths for side-by-side door bays. Only the first door_count
// entries are used. Equal weights preserve equal-width doors.
// Example: [1,1.5,2] creates progressively wider door bays.
door_width_weights = [1,1,1,1];

// For a DOORS-ONLY wall cabinet, extend decorative doors to the cabinet top.
// Combo cabinets intentionally stop below the drawer region.
wall_doors_flush_top = true;


/* [Doors / Basic - Shelves] */

// Stackable V26 uses adjustable shelves for open/door modules. Shelf count is
// configured directly in Stackable / Basic - Module as door_shelf_count.

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


/* [Shelves / Advanced - Mixed Bay Shelves] */

// Used by mixed bays of type "door" or "open".
// Each bay can independently use loose adjustable shelves or structural fixed
// shelves. Fixed shelves inherit the main carcass joinery_style at the bay
// boundaries (cabinet sides / full-depth mixed-bay partitions).
mixed_bay_shelf_styles = ["adjustable","adjustable","adjustable","adjustable"];

// Number of shelf PANELS supplied in each bay.
mixed_bay_shelf_counts = [0,0,2,2];


/* [Doors / Basic - Handles] */

include_door_handle_holes = false;

// Door pulls are placed near the opening edge, opposite the hinges.
door_handle_from_open_edge = 50;
door_handle_from_top = 90;
door_handle_orientation = "vertical"; // [vertical, horizontal]


/* [Doors / Advanced - Mixed Bay Doors] */

// Number of decorative doors in each mixed door bay. Supported values are 1
// and 2. A two-door bay creates an equal pair that hinges at the OUTER bay
// edges and meets at the center using door_gap.
mixed_bay_door_counts = [1,1,1,1];

// Used only for SINGLE-door mixed bays. Set the hinge side explicitly so the
// door can mount to either the cabinet side or neighboring full-depth partition.
// Paired doors ignore this array and automatically hinge left/right outward.
mixed_bay_door_hinge_sides = ["left","right","left","right"];


/* [Doors / Advanced - Hinges] */



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


/* [Doors / Advanced - Full-Depth Partitions] */

// Cabinets with more than two side-by-side doors automatically receive a
// full-depth vertical partition behind every inter-door gap. These partitions
// provide hinge mounting surfaces AND separate the door compartments.
//
// Partition-to-carcass joinery ALWAYS follows the main carcass joinery_style
// and uses the same fit/depth settings.
include_door_hinge_partitions = true;

// Clearance used for fixed-shelf cross-lap notches in the partitions.
door_hinge_partition_shelf_clearance = 0.5;


/* [Drawers / Basic - Fronts & Heights] */

// Decorative applied drawer faces can be omitted for a simpler drawer.
// When omitted, optional handle holes move automatically to the box front.
include_drawer_faces = true;

// Gap between adjacent decorative drawer faces.
drawer_gap = 3;

// Shared vertical sizing recipe. "graduated" makes lower drawers progressively
// taller. "custom_weights" uses one positive weight per drawer.
drawer_height_mode = "equal"; // [equal, graduated, custom_weights]
drawer_graduated_step = 0.35;
drawer_height_weights = [1,1,1,1];


/* [Drawers / Basic - Handles] */

include_drawer_handle_holes = false;

// Drawer pulls are centered; this shifts them vertically from center.
drawer_handle_vertical_offset = 0;


/* [Drawers / Basic - Mounting] */

// Controls how an explicit hardware hole array is reduced for machining.
hardware_drilling_mode = "recommended"; // [minimum, recommended, all]


// metal_slides = commercial side-mount slides
// wood_rails   = runners cut from the same sheet material
// none         = no slide allowance / runner geometry
drawer_mount = "wood_rails"; // [metal_slides, wood_rails, none]


/* [Drawers / Advanced - Mixed Bay Drawer Stacks] */

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


/* [Drawers / Advanced - Banks & Width Ratios] */

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


/* [Drawers / Advanced - Box Clearances] */

drawer_vertical_clearance = 10;
drawer_back_clearance = 20;
drawer_bottom_inset = 8;
front_setback = 2; // drawer box setback behind the drawer face


/* [Drawers / Advanced - Box Joinery] */

// Joinery between the drawer FRONT/BACK box panels and the drawer SIDES.
// These intentionally mirror the carcass choices.
drawer_joinery_style = "butt"; // [butt, dado, tab_slot]

// Drawer tab/slot clearance is independent from the carcass.
drawer_joint_fit_clearance = 0.20; // [0:0.05:2]

// Drawer dado clearance is independent as well. It applies to both
// front/back-to-side dados and optional drawer-bottom grooves.
drawer_dado_fit_clearance = 0.20; // [0:0.05:2]

// Blind dado depth for drawer front/back-to-side joints.
drawer_dado_depth = 4;

// Bottom joinery is independent. "dado" cuts a groove in all four drawer
// walls and enlarges the bottom so it enters those grooves. This can be used
// together with drawer_joinery_style = "tab_slot".
drawer_bottom_joinery = "butt"; // [butt, dado]
drawer_bottom_dado_depth = 4;

// Optional structure between ADJACENT drawers. This does not replace the
// existing drawer/door combo divider.
include_drawer_separators = false;

// A full separator is a broad horizontal panel.
// Stretchers create one front and one rear cross-piece at each drawer boundary.
drawer_separator_style = "stretchers"; // [full, stretchers]
drawer_separator_stretcher_depth = 75;


/* [Drawers / Advanced - Face Registration] */

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


/* [Drawers / Advanced - Metal Slides] */

// Total air gap is 2x this value. 12.7 mm is a common nominal 1/2" per side,
// but use the clearance specified by your exact slide hardware.
metal_slide_clearance_per_side = 12.7;
metal_slide_length = 500;
metal_slide_front_setback = 3;
metal_slide_envelope_height = 45;
show_metal_slide_envelopes = true;


/* [Drawers / Advanced - Metal Slide Drilling] */

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


/* [Drawers / Advanced - Wood Slides] */

// Fixed lower rail attached to the cabinet side.
wood_rail_thickness = material_thickness;
wood_rail_height = 28;
custom_wood_rail_depth = cabinet_depth - 70;
wood_rail_front_setback = 20;

// Matching upper runner attached to the outside of each drawer side.
// Its underside rides on the top surface of the fixed rail.
wood_drawer_runner_thickness = wood_rail_thickness;
wood_drawer_runner_height = 14;
custom_wood_drawer_runner_depth = custom_wood_rail_depth;
wood_drawer_runner_front_setback = wood_rail_front_setback;

// Vertical location of the drawer runner, measured upward from the bottom of
// the drawer box. The fixed rail is automatically positioned underneath it.
wood_drawer_runner_bottom_offset = 30;

// Running clearances. side_clearance keeps the drawer runner away from the
// cabinet side; vertical_clearance prevents a zero-clearance/interference fit.
wood_rail_side_clearance = 1.0;
wood_rail_vertical_clearance = 0.5;


/* [Drawers / Advanced - Wood Slide Registration] */

// Matching holes are cut in:
//   fixed rail <-> cabinet side
//   drawer runner <-> drawer side
// This makes it easy to locate the rails with screws, dowel pins, or temporary
// registration pins before final fastening.
include_wood_slide_registration_holes = true;
wood_slide_registration_hole_diameter = 4;
wood_slide_registration_hole_count = 3; // [1:1:8]
wood_slide_registration_end_margin = 50;


/* [Manufacturing / Basic - Flat Layout] */

layout_gap = 20;
layout_show_stock = false;
stock_width = 2440;
stock_height = 1220;


/* [Manufacturing / Basic - Calibration Coupon] */

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


/* [Manufacturing / Basic - Part Labels & BOM] */

// engrave_layout exports ONLY vector part IDs plus the same registration frame
// used by CUT/POCKET layouts. Import it at the same origin as the cut file.
// The part IDs also match the IDs printed by output_mode = "bom".
engrave_label_size = 8;
engrave_label_min_size = 2.5;

// Preview the cut-part outlines behind labels in OpenSCAD. The outlines use
// the preview-only % modifier and are NOT included in engraving exports.
show_cut_outlines_in_engrave_preview = true;


/* [Manufacturing / Advanced - CAM & Export Registration] */

// Show exact blind-operation geometry over the cut layout in OpenSCAD.
// PREVIEW ONLY; it does not alter exported cut geometry.
show_blind_pockets_over_cut_layout = true;

// Add the same outer dummy frame to CUT and POCKET layouts so OpenSCAD crops
// both exports to exactly the same extents/origin.
include_shared_export_bounding_box = true;
export_bounding_box_margin = 20;
export_bounding_box_frame_width = 0.20; // [0.05:0.05:1.00]

// Usually leave this OFF and compensate in CAM.
apply_kerf_compensation = false;
kerf = 0.15;


/* [Hidden] */

// Fixed by design in V24. Kept internally so older geometry helpers remain
// compatible, but it is no longer exposed in the Customizer.
back_joinery = "simple";


/* [Resolved Configuration - Hidden] */

stackable_mode = true;

door_count = module_type == "door" ? 1 : 0;
cabinet_contents = module_type == "drawers" ? "drawers" : "doors";

active_mount_style = "floor";
active_base_style = "flat";
has_toe_kick = false;
toe_kick_height = 0;
toe_kick_setback = 0;
bottom_above_toe = stack_interface_depth;
side_toe_kick_cutout = "none";

base_hardware_active = false;
base_mounting_plate_active = false;
worktop_active = false;

top_style = "stretchers";
shelf_style = "adjustable";

wood_rail_depth = max(20,cabinet_depth-70);
wood_drawer_runner_depth = wood_rail_depth;

front_width_style = overlay_width_style == "full" ? "full_overlay" : "inset";

active_cabinet_layout_mode = "mixed_bays";
active_mixed_bay_count = 1;
active_mixed_bay_types = [module_type];
active_mixed_bay_width_weights = [1];
active_mixed_bay_drawer_counts = [drawer_count];
active_mixed_bay_door_counts = [1];
active_mixed_bay_shelf_styles = ["adjustable"];
active_mixed_bay_shelf_counts = [door_shelf_count];
active_mixed_bay_drawer_height_modes = ["equal"];
active_mixed_bay_drawer_graduated_steps = [0.35];
active_mixed_bay_drawer_height_weights = [[1,1,1,1,1,1,1,1]];
active_mixed_bay_door_hinge_sides = ["left"];

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
include <modular_organization_core_v3.scad>
include <modular_organization_layouts_v3.scad>


