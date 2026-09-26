// Modular Organization Core — fork v3 / Configurator API V3.
// Included by utility_cabinet.scad and benchtop_drawer_cabinet.scad.
// User-facing Customizer settings belong in the entry files, not here.

/* [Hidden] */

combo_door_height_units = 3;

// Compatibility helper for OpenSCAD versions without built-in sum().
function vec_sum(v, i=0) = i >= len(v) ? 0 : v[i] + vec_sum(v, i+1);

// Optional component mode used by the dedicated replacement-drawer front end.
// Existing cabinet front ends do not define standalone_drawer_mode, so their
// behavior remains unchanged.
standalone_drawer_active =
    !is_undef(standalone_drawer_mode)
    && standalone_drawer_mode;

effective_drawer_free_fit_clearance_per_side =
    is_undef(drawer_free_fit_clearance_per_side)
        ? 1
        : max(0,drawer_free_fit_clearance_per_side);

standalone_include_fixed_wood_rails_resolved =
    standalone_drawer_active
        ? (
            is_undef(standalone_include_fixed_wood_rails)
                ? false
                : standalone_include_fixed_wood_rails
          )
        : true;


// ---------------------------
// CANONICAL HARDWARE SETTINGS
// ---------------------------
// Hardware catalog entries are one-time patches of these ordinary settings.
// Geometry has no persistent hardware-profile mode.

effective_metal_slide_clearance_per_side = metal_slide_clearance_per_side;
effective_metal_slide_length = metal_slide_length;
resolved_metal_slide_front_setback_base = metal_slide_front_setback;
effective_metal_slide_envelope_height = metal_slide_envelope_height;
effective_metal_slide_rear_margin = metal_slide_hole_rear_margin;
effective_metal_slide_cabinet_hole_diameter = metal_slide_cabinet_hole_diameter;
effective_metal_slide_drawer_hole_diameter = metal_slide_drawer_hole_diameter;
effective_metal_slide_cabinet_hole_z = metal_slide_cabinet_hole_z_from_drawer_bottom;
effective_metal_slide_drawer_hole_z = metal_slide_drawer_hole_z_from_drawer_bottom;

function custom_metal_slide_holes_x() = [for (n=[0:max(0,metal_slide_hole_count-1)]) metal_slide_first_hole_from_front+n*metal_slide_hole_spacing];
function active_slide_cabinet_holes_local() = metal_slide_hole_pattern_mode == "explicit_array" ? metal_slide_cabinet_holes_x : custom_metal_slide_holes_x();
function active_slide_drawer_holes_local() = metal_slide_hole_pattern_mode == "explicit_array" ? metal_slide_drawer_holes_x : custom_metal_slide_holes_x();
function hardware_select_local_holes(holes,mode="recommended") =
    len(holes)<=2 || mode=="all" ? holes :
    mode=="minimum" ? [holes[0],holes[len(holes)-1]] :
    len(holes)<=3 ? holes : [holes[0],holes[floor((len(holes)-1)/2)],holes[len(holes)-1]];
function active_slide_cabinet_holes() = metal_slide_hole_pattern_mode == "explicit_array" ? hardware_select_local_holes(metal_slide_cabinet_holes_x,hardware_drilling_mode) : custom_metal_slide_holes_x();
function active_slide_drawer_holes() = metal_slide_hole_pattern_mode == "explicit_array" ? hardware_select_local_holes(metal_slide_drawer_holes_x,hardware_drilling_mode) : custom_metal_slide_holes_x();

effective_hinge_style = hinge_style;
effective_hinge_cup_diameter = hinge_cup_diameter;
effective_hinge_cup_depth = hinge_cup_depth;
effective_hinge_cup_center_from_door_edge = hinge_cup_center_from_door_edge;
effective_hinge_door_fixing_hole_diameter = hinge_door_fixing_hole_diameter;
effective_hinge_door_fixing_hole_spacing = hinge_door_fixing_hole_spacing;
effective_hinge_plate_hole_diameter = hinge_plate_hole_diameter;
effective_hinge_plate_center_from_front = hinge_plate_center_from_front;
effective_hinge_plate_hole_spacing = hinge_plate_hole_spacing;


// ---------------------------
// FIT-TARGET / MODULAR SIZING
// ---------------------------
//
// Public `cabinet_width` and `cabinet_depth` remain the user's configured
// outside-envelope starting values. V29 can solve either axis backward from
// the desired FINISHED drawer interior and expose the result to the existing
// geometry engine through resolved_cabinet_width / resolved_cabinet_depth.
//
// The solver is deliberately algebraic rather than a general constraint
// system. It inverts the exact width/depth relationships already used by the
// drawer engine, which keeps the result deterministic and web-friendly.

sizing_modular_mode =
    target_dimension_mode == "modular_grid";

sizing_requested_drawer_inside_width =
    max(
        1,
        sizing_modular_mode
            ? target_module_pitch_x
              * max(1,round(target_module_count_x))
              + 2*max(0,target_module_edge_clearance_x)
            : target_drawer_inside_width
    );

sizing_requested_drawer_inside_depth =
    max(
        1,
        sizing_modular_mode
            ? target_module_pitch_y
              * max(1,round(target_module_count_y))
              + 2*max(0,target_module_edge_clearance_y)
            : target_drawer_inside_depth
    );

sizing_mixed_mode =
    active_cabinet_layout_mode == "mixed_bays";

function sizing_mixed_bay_type(i=0) =
    i < len(active_mixed_bay_types)
        ? active_mixed_bay_types[i]
        : "open";

function sizing_mixed_bay_is_drawer(i=0) =
    sizing_mixed_bay_type(i) == "drawers"
    || sizing_mixed_bay_type(i) == "drawer";

function sizing_mixed_has_drawer(i=0) =
    i >= active_mixed_bay_count
        ? false
        : sizing_mixed_bay_is_drawer(i)
            ? true
            : sizing_mixed_has_drawer(i+1);

sizing_has_drawers =
    sizing_mixed_mode
        ? sizing_mixed_has_drawer()
        : cabinet_contents == "drawers"
          || cabinet_contents == "combo";

sizing_bank_count =
    sizing_mixed_mode
        ? max(1,active_mixed_bay_count)
        : max(1,drawer_bank_count);

sizing_target_bank_index =
    min(
        sizing_bank_count-1,
        max(0,round(target_drawer_bank)-1)
    );

sizing_target_bank_valid =
    sizing_has_drawers
    && (
        !sizing_mixed_mode
        || sizing_mixed_bay_is_drawer(sizing_target_bank_index)
    );

function sizing_bank_weight(i=0) =
    sizing_mixed_mode
        ? (
            i < len(active_mixed_bay_width_weights)
                ? max(0.05,active_mixed_bay_width_weights[i])
                : 1
          )
        : (
            i < len(drawer_bank_width_weights)
                ? max(0.05,drawer_bank_width_weights[i])
                : 1
          );

function sizing_bank_weight_sum(i=0) =
    i >= sizing_bank_count
        ? 0
        : sizing_bank_weight(i)+sizing_bank_weight_sum(i+1);

sizing_bank_weight_total =
    max(0.05,sizing_bank_weight_sum());

sizing_target_bank_weight =
    max(0.05,sizing_bank_weight(sizing_target_bank_index));

sizing_drawer_side_clearance_per_side =
    drawer_mount == "metal_slides"
        ? effective_metal_slide_clearance_per_side
        : drawer_mount == "wood_rails"
            ? wood_rail_thickness+wood_rail_side_clearance
            : effective_drawer_free_fit_clearance_per_side;

sizing_required_drawer_opening_width =
    sizing_requested_drawer_inside_width
    + 2*drawer_material_thickness
    + 2*sizing_drawer_side_clearance_per_side;

sizing_required_available_opening_width =
    sizing_required_drawer_opening_width
    * sizing_bank_weight_total
    / sizing_target_bank_weight;

sizing_partition_allowance_width =
    sizing_mixed_mode
        ? max(0,sizing_bank_count-1)
          * (
                include_mixed_bay_partitions
                    ? material_thickness
                    : 0
            )
        : max(0,sizing_bank_count-1)*material_thickness;

sizing_face_frame_active =
    !is_undef(front_facing_style)
    && front_facing_style == "face_frame";

sizing_face_frame_stile_width =
    sizing_face_frame_active
        ? max(
            3,
            is_undef(face_frame_side_stile_width)
                ? 38.1
                : face_frame_side_stile_width
          )
        : 0;

// Mixed-bay openings currently resolve from carcass inner width in the shared
// geometry engine. Legacy/non-mixed face-frame drawer banks resolve from the
// clear opening between face-frame stiles. Mirror those exact rules here.
sizing_width_side_allowance =
    sizing_mixed_mode
        ? 2*material_thickness
        : sizing_face_frame_active
            ? 2*sizing_face_frame_stile_width
            : 2*material_thickness;

sizing_required_cabinet_width =
    max(
        50,
        sizing_required_available_opening_width
        + sizing_partition_allowance_width
        + sizing_width_side_allowance
    );

sizing_fronts_inset_flush =
    front_mount_style == "inset_flush"
    || front_mount_style == "flush"
    || front_mount_style == "inset";

sizing_effective_drawer_front_setback =
    sizing_fronts_inset_flush
    && include_drawer_faces
        ? max(
            front_setback,
            drawer_front_thickness
            + max(0,inset_front_back_clearance)
          )
        : front_setback;

sizing_structural_back_allowance =
    back_style == "structural_panel"
        ? material_thickness
        : 0;

sizing_required_cabinet_depth =
    max(
        50,
        sizing_requested_drawer_inside_depth
        + 2*drawer_material_thickness
        + sizing_effective_drawer_front_setback
        + drawer_back_clearance
        + sizing_structural_back_allowance
    );

resolved_cabinet_width =
    width_basis == "drawer_inside"
    && sizing_target_bank_valid
        ? target_dimension_policy == "exact"
            ? sizing_required_cabinet_width
            : max(cabinet_width,sizing_required_cabinet_width)
        : cabinet_width;

resolved_cabinet_depth =
    depth_basis == "drawer_inside"
    && sizing_target_bank_valid
        ? target_dimension_policy == "exact"
            ? sizing_required_cabinet_depth
            : max(cabinet_depth,sizing_required_cabinet_depth)
        : cabinet_depth;

// Wood-slide rail lengths in the current front ends are cabinet-relative
// defaults. When exact target sizing changes cabinet depth, carry the same
// depth delta into those members so a smaller/larger solved cabinet does not
// leave the runners at the old envelope length.
sizing_depth_delta =
    resolved_cabinet_depth-cabinet_depth;

resolved_wood_rail_depth =
    max(
        20,
        wood_rail_depth
        + (
            depth_basis == "drawer_inside"
            && sizing_target_bank_valid
                ? sizing_depth_delta
                : 0
          )
    );

resolved_wood_drawer_runner_depth =
    max(
        20,
        wood_drawer_runner_depth
        + (
            depth_basis == "drawer_inside"
            && sizing_target_bank_valid
                ? sizing_depth_delta
                : 0
          )
    );

// ---------------------------
// GENERALIZED MIXED-BAY MODE
// ---------------------------

mixed_bay_mode = active_cabinet_layout_mode == "mixed_bays";

function mixed_bay_type(b=0) =
    b < len(active_mixed_bay_types)
        ? active_mixed_bay_types[b]
        : "open";

// Accept the natural singular/plural spellings for drawer and door bays.
function mixed_bay_type_normalized(b=0) =
    mixed_bay_type(b) == "doors" ? "door" :
    mixed_bay_type(b) == "drawer" ? "drawers" :
    mixed_bay_type(b) == "shelf" ? "open" :
    mixed_bay_type(b) == "shelves" ? "open" :
    mixed_bay_type(b);

function mixed_bay_is_type(b,type) =
    b >= 0
    && b < active_mixed_bay_count
    && mixed_bay_type_normalized(b) == type;

function mixed_bay_has_type(type,i=0) =
    i >= active_mixed_bay_count
        ? false
        : mixed_bay_type_normalized(i) == type
            ? true
            : mixed_bay_has_type(type,i+1);

function mixed_bay_type_count(type,i=0) =
    i >= active_mixed_bay_count
        ? 0
        : (mixed_bay_type_normalized(i) == type ? 1 : 0)
          + mixed_bay_type_count(type,i+1);

// Mixed door bays may contain one door or an equal paired set.
function mixed_bay_door_count(b=0) =
    mixed_bay_is_type(b,"door")
        ? min(
            2,
            max(
                1,
                b < len(active_mixed_bay_door_counts)
                    ? round(active_mixed_bay_door_counts[b])
                    : 1
            )
          )
        : 0;

function mixed_bay_door_count_prefix(b,j=0) =
    j >= b
        ? 0
        : mixed_bay_door_count(j)
          + mixed_bay_door_count_prefix(b,j+1);

function mixed_bay_total_door_count() =
    mixed_bay_door_count_prefix(active_mixed_bay_count);

function mixed_bay_door_part_index(b,leaf=0) =
    mixed_bay_door_count_prefix(b)+leaf;

has_drawers =
    mixed_bay_mode
        ? mixed_bay_has_type("drawers")
        : cabinet_contents == "drawers" || cabinet_contents == "combo";

has_doors =
    mixed_bay_mode
        ? mixed_bay_has_type("door")
        : cabinet_contents == "doors" || cabinet_contents == "combo";

active_door_count =
    has_doors
        ? (mixed_bay_mode ? mixed_bay_total_door_count() : door_count)
        : 0;

inner_width =
    standalone_drawer_active
        ? standalone_enclosure_opening_width
        : resolved_cabinet_width - 2*material_thickness;

function mixed_bay_width_weight(b=0) =
    b < len(active_mixed_bay_width_weights)
        ? max(0.05,active_mixed_bay_width_weights[b])
        : 1;

function mixed_bay_width_weight_sum(i=0) =
    i >= active_mixed_bay_count
        ? 0
        : mixed_bay_width_weight(i)
          + mixed_bay_width_weight_sum(i+1);

mixed_bay_width_weight_total =
    max(0.05,mixed_bay_width_weight_sum());

mixed_bay_partition_thickness =
    mixed_bay_mode && include_mixed_bay_partitions
        ? material_thickness
        : 0;

mixed_bay_available_opening_width =
    max(
        1,
        inner_width
        - max(0,active_mixed_bay_count-1)*mixed_bay_partition_thickness
    );

function mixed_bay_opening_width(b=0) =
    max(
        1,
        mixed_bay_available_opening_width
        *mixed_bay_width_weight(b)
        /mixed_bay_width_weight_total
    );

function mixed_bay_opening_width_prefix(b,j=0) =
    j >= b
        ? 0
        : mixed_bay_opening_width(j)
          + mixed_bay_opening_width_prefix(b,j+1);

function mixed_bay_opening_x(b=0) =
    material_thickness
    + mixed_bay_opening_width_prefix(b)
    + b*mixed_bay_partition_thickness;

function mixed_bay_partition_x(p) =
    mixed_bay_opening_x(p)
    + mixed_bay_opening_width(p);

function mixed_bay_partition_center_x(p) =
    mixed_bay_partition_x(p) + mixed_bay_partition_thickness/2;

function mixed_bay_partition_count() =
    mixed_bay_mode && include_mixed_bay_partitions
        ? max(0,active_mixed_bay_count-1)
        : 0;
// A thin applied back sits behind the carcass and does not consume interior
// depth. A structural back is carcass-thickness material captured flush with
// the rear edge, so drawer/partition/shelf depth stops at its front face.
structural_back_active = back_style == "structural_panel";

structural_back_y =
    resolved_cabinet_depth-material_thickness;

usable_depth =
    standalone_drawer_active
        ? standalone_enclosure_usable_depth
        : structural_back_active
            ? structural_back_y
            : resolved_cabinet_depth;

fronts_inset_flush =
    front_mount_style == "inset_flush"
    || front_mount_style == "flush"
    || front_mount_style == "inset";


// ---------------------------
// OPTIONAL CARCASS FRONT FACING / FACE FRAME
// ---------------------------

// These inputs are intentionally optional so every existing front end remains
// geometry-identical unless it explicitly enables a face frame.
front_facing_style_resolved =
    is_undef(front_facing_style)
        ? "none"
        : front_facing_style;

face_frame_active =
    front_facing_style_resolved == "face_frame";

effective_face_frame_thickness =
    face_frame_active
        ? max(
            0.5,
            is_undef(face_frame_thickness)
                ? material_thickness
                : face_frame_thickness
          )
        : 0;

// Face frames are already manufactured as separate stiles/rails. V25 adds a
// second attachment style where the back of each perimeter strip is pocketed
// so the carcass front edge nests into the facing.
//
// "segmented_surface" preserves V24 geometry.
// "segmented_back_dado" shifts the frame rearward by the dado depth and removes
// matching back-side pockets from the four perimeter pieces.
face_frame_construction_resolved =
    is_undef(face_frame_construction)
        ? "segmented_surface"
        : face_frame_construction;

face_frame_back_dado_active =
    face_frame_active
    && (
        face_frame_construction_resolved == "segmented_back_dado"
        || face_frame_construction_resolved == "back_dado"
        || face_frame_construction_resolved == "dado"
    );

effective_face_frame_back_dado_clearance =
    face_frame_back_dado_active
        ? max(
            0,
            is_undef(face_frame_back_dado_clearance)
                ? dado_fit_clearance
                : face_frame_back_dado_clearance
          )
        : 0;

effective_face_frame_back_dado_depth =
    face_frame_back_dado_active
        ? min(
            max(
                0.5,
                is_undef(face_frame_back_dado_depth)
                    ? min(
                        material_thickness/3,
                        effective_face_frame_thickness/3
                      )
                    : face_frame_back_dado_depth
            ),
            max(0.5,effective_face_frame_thickness-0.5)
          )
        : 0;

// The carcass enters the BACK of the frame by dado_depth, so only the
// remaining thickness projects in front of the plywood carcass.
face_frame_projection =
    face_frame_active
        ? effective_face_frame_thickness
          - effective_face_frame_back_dado_depth
        : 0;

face_frame_front_y =
    -face_frame_projection;

face_frame_back_y =
    effective_face_frame_back_dado_depth;

face_frame_back_dado_width =
    material_thickness
    + effective_face_frame_back_dado_clearance;

effective_face_frame_side_stile_width =
    face_frame_active
        ? max(
            3,
            is_undef(face_frame_side_stile_width)
                ? 38.1
                : face_frame_side_stile_width
          )
        : 0;

effective_face_frame_top_rail_width =
    face_frame_active
        ? max(
            3,
            is_undef(face_frame_top_rail_width)
                ? 38.1
                : face_frame_top_rail_width
          )
        : 0;

effective_face_frame_bottom_rail_width =
    face_frame_active
        ? max(
            3,
            is_undef(face_frame_bottom_rail_width)
                ? 38.1
                : face_frame_bottom_rail_width
          )
        : 0;

effective_face_frame_mid_rail_width =
    face_frame_active
        ? max(
            3,
            is_undef(face_frame_mid_rail_width)
                ? 38.1
                : face_frame_mid_rail_width
          )
        : 0;

effective_face_frame_center_stile_width =
    face_frame_active
        ? max(
            3,
            is_undef(face_frame_center_stile_width)
                ? 38.1
                : face_frame_center_stile_width
          )
        : 0;

effective_face_frame_overlay =
    face_frame_active
        ? max(
            0,
            is_undef(face_frame_overlay)
                ? 12.7
                : face_frame_overlay
          )
        : 0;

face_frame_mid_rail_mode_resolved =
    is_undef(face_frame_mid_rail_mode)
        ? "none"
        : face_frame_mid_rail_mode;

face_frame_inset_combo_rail =
    face_frame_active
    && fronts_inset_flush
    && !mixed_bay_mode
    && cabinet_contents == "combo"
    && face_frame_mid_rail_mode_resolved == "combo_auto";

face_frame_center_stile_enabled =
    face_frame_active
    && !is_undef(include_face_frame_center_stile)
    && include_face_frame_center_stile;

face_frame_bottom_z =
    face_frame_active
        ? (
            has_toe_kick
                ? bottom_above_toe
                : 0
          )
        : 0;

face_frame_top_z =
    cabinet_height;

face_frame_height =
    max(
        0,
        face_frame_top_z-face_frame_bottom_z
    );

face_frame_inner_left_x =
    effective_face_frame_side_stile_width;

face_frame_inner_right_x =
    resolved_cabinet_width-effective_face_frame_side_stile_width;

face_frame_clear_width =
    max(
        1,
        face_frame_inner_right_x-face_frame_inner_left_x
    );

face_frame_clear_bottom_z =
    face_frame_bottom_z
    + effective_face_frame_bottom_rail_width;

face_frame_clear_top_z =
    face_frame_top_z
    - effective_face_frame_top_rail_width;

face_frame_clear_height =
    max(
        1,
        face_frame_clear_top_z-face_frame_clear_bottom_z
    );

// The face-frame front is the new decorative-front reference plane.
front_reference_y =
    face_frame_active
        ? face_frame_front_y
        : 0;

cabinet_finished_depth =
    resolved_cabinet_depth+face_frame_projection;

// Decorative-front depth helpers.
// Cabinet interior is +Y; the user-facing front is -Y.
function decorative_front_y(thickness) =
    fronts_inset_flush
        ? front_reference_y
        : front_reference_y-thickness;

function decorative_front_back_y(thickness) =
    decorative_front_y(thickness)+thickness;

function decorative_front_through_drill_start_y(thickness) =
    decorative_front_back_y(thickness)+1;

function decorative_front_blind_drill_start_y(thickness) =
    decorative_front_back_y(thickness)+0.01;

// Flush/inset fronts occupy real cabinet depth. Interior members and drawer
// hardware are automatically kept behind the back face of those fronts.
inset_front_interior_depth =
    fronts_inset_flush
        ? max(
            has_doors ? door_thickness : 0,
            has_drawers && include_drawer_faces
                ? drawer_front_thickness
                : 0
          )
          + max(0,inset_front_back_clearance)
        : 0;

front_opening_bottom_z =
    standalone_drawer_active
        ? 0
        : face_frame_active
            ? face_frame_clear_bottom_z
            : bottom_above_toe + material_thickness;

front_opening_top_z =
    standalone_drawer_active
        ? standalone_enclosure_opening_height
        : face_frame_active
            ? face_frame_clear_top_z
            : cabinet_height - material_thickness;

// Internal usable opening. Drawer boxes, shelves, etc. stay inside this region.
content_bottom_z = front_opening_bottom_z + front_edge_reveal;
content_top_z = front_opening_top_z - front_edge_reveal;
content_height = max(0, content_top_z - content_bottom_z);

// Visible fronts can optionally extend downward across the front edge of the
// raised bottom panel.
front_panel_bottom_z =
    fronts_inset_flush
        ? content_bottom_z
        : fronts_cover_bottom_lip
            ? bottom_above_toe + front_edge_reveal
            : content_bottom_z;

bottom_lip_overlay =
    max(0, content_bottom_z - front_panel_bottom_z);

drawer_stack_bottom_z =
    include_drawer_faces ? front_panel_bottom_z : content_bottom_z;

drawer_only_front_height =
    max(0, content_top_z - drawer_stack_bottom_z);


// ---------------------------
// DRAWER BANK CONFIGURATION
// ---------------------------

// Legacy drawer-bank settings remain available, while mixed-bay mode maps the
// existing drawer geometry engine onto the generalized bay indices.
function active_drawer_bank_count() =
    mixed_bay_mode ? active_mixed_bay_count : drawer_bank_count;

function drawer_bank_drawer_count(b=0) =
    mixed_bay_mode
        ? mixed_bay_is_type(b,"drawers")
            ? (b < len(active_mixed_bay_drawer_counts)
                ? max(1,round(active_mixed_bay_drawer_counts[b]))
                : max(1,drawer_count))
            : 0
        : drawer_bank_layout_mode == "independent"
          && b < len(drawer_bank_drawer_counts)
            ? max(1,round(drawer_bank_drawer_counts[b]))
            : max(1,drawer_count);

function drawer_bank_height_mode_for(b=0) =
    mixed_bay_mode
        ? (b < len(active_mixed_bay_drawer_height_modes)
            ? active_mixed_bay_drawer_height_modes[b]
            : drawer_height_mode)
        : drawer_bank_layout_mode == "independent"
          && b < len(drawer_bank_height_modes)
            ? drawer_bank_height_modes[b]
            : drawer_height_mode;

function drawer_bank_graduated_step_for(b=0) =
    mixed_bay_mode
        ? (b < len(active_mixed_bay_drawer_graduated_steps)
            ? active_mixed_bay_drawer_graduated_steps[b]
            : drawer_graduated_step)
        : drawer_bank_layout_mode == "independent"
          && b < len(drawer_bank_graduated_steps)
            ? drawer_bank_graduated_steps[b]
            : drawer_graduated_step;

function drawer_bank_custom_weight(b,i) =
    mixed_bay_mode
        ? (b < len(active_mixed_bay_drawer_height_weights)
           && i < len(active_mixed_bay_drawer_height_weights[b])
            ? max(0.05,active_mixed_bay_drawer_height_weights[b][i])
            : i < len(drawer_height_weights)
                ? max(0.05,drawer_height_weights[i])
                : 1)
        : drawer_bank_layout_mode == "independent"
          && b < len(drawer_bank_height_weights)
          && i < len(drawer_bank_height_weights[b])
            ? max(0.05,drawer_bank_height_weights[b][i])
            : i < len(drawer_height_weights)
                ? max(0.05,drawer_height_weights[i])
                : 1;

// i=0 is the TOP drawer. Graduated mode therefore grows toward the bottom.
function drawer_height_weight(i,b=0) =
    drawer_bank_height_mode_for(b) == "graduated"
        ? max(
            0.05,
            1 + i*drawer_bank_graduated_step_for(b)
          )
        : drawer_bank_height_mode_for(b) == "custom_weights"
            ? drawer_bank_custom_weight(b,i)
            : 1;

function drawer_height_weight_sum(b=0,i=0) =
    i >= drawer_bank_drawer_count(b)
        ? 0
        : drawer_height_weight(i,b)
          + drawer_height_weight_sum(b,i+1);

function drawer_bank_weight_total(b=0) =
    max(0.05,drawer_height_weight_sum(b));

function drawer_bank_drawer_prefix(b,j=0) =
    j >= b
        ? 0
        : drawer_bank_drawer_count(j)
          + drawer_bank_drawer_prefix(b,j+1);

function drawer_total_count() =
    drawer_bank_drawer_prefix(active_drawer_bank_count());

function drawer_part_index(b,i) =
    drawer_bank_drawer_prefix(b)+i;

active_drawer_count =
    has_drawers ? drawer_total_count() : 0;

// Legacy combo cabinets keep their historic vertical divider behavior. Mixed
// bays are full-height columns, so each drawer bay independently fills the
// full drawer region instead.
combo_reference_drawer_unit =
    !mixed_bay_mode && cabinet_contents == "combo"
        ? max(
            0,
            (
                content_height
                - drawer_gap*drawer_bank_drawer_count(0)
            )
            / (
                drawer_bank_weight_total(0)
                + combo_door_height_units
            )
          )
        : 0;

combo_reference_door_height =
    !mixed_bay_mode && cabinet_contents == "combo"
        ? combo_door_height_units*combo_reference_drawer_unit
        : 0;

function drawer_height_unit_for_bank(b=0) =
    mixed_bay_mode
        ? max(
            0,
            (
                drawer_only_front_height
                - drawer_gap*max(0,drawer_bank_drawer_count(b)-1)
            )
            / drawer_bank_weight_total(b)
          )
        : cabinet_contents == "drawers"
            ? max(
                0,
                (
                    drawer_only_front_height
                    - drawer_gap*max(0,drawer_bank_drawer_count(b)-1)
                )
                / drawer_bank_weight_total(b)
              )
            : cabinet_contents == "combo"
                ? max(
                    0,
                    face_frame_inset_combo_rail
                        ? (
                            content_top_z
                            - (
                                content_bottom_z
                                + combo_reference_door_height
                                + effective_face_frame_mid_rail_width/2
                                + front_edge_reveal
                              )
                            - drawer_gap
                              *max(
                                  0,
                                  drawer_bank_drawer_count(b)-1
                               )
                          )
                          / drawer_bank_weight_total(b)
                        : (
                            content_height
                            - combo_reference_door_height
                            - drawer_gap*drawer_bank_drawer_count(b)
                          )
                          / drawer_bank_weight_total(b)
                  )
                : 0;

function drawer_face_nominal_height(i,b=0) =
    max(
        0,
        drawer_height_unit_for_bank(b)
        *drawer_height_weight(i,b)
    );

// Compatibility scalar retained for older validation/echo helpers.
drawer_height_unit = drawer_height_unit_for_bank(0);
drawer_height_weight_total = drawer_bank_weight_total(0);
drawer_face_height = drawer_face_nominal_height(0,0);


door_region_height =
    mixed_bay_mode
        ? (has_doors ? content_height : 0)
        : cabinet_contents == "doors"
            ? content_height
            : cabinet_contents == "combo"
                ? combo_reference_door_height
                : 0;

// The internal door compartment still starts above the bottom panel.
door_region_bottom_z = content_bottom_z;
door_region_top_z = door_region_bottom_z + door_region_height;

// The visible door front may overlap the bottom-panel lip.
door_face_bottom_z =
    has_doors ? front_panel_bottom_z : door_region_bottom_z;

// Doors-only wall cabinets can overlay the top-panel front edge all the way
// to the cabinet top. Combo cabinets intentionally keep the normal region top
// so the doors cannot overlap the drawer fronts above them.
door_face_top_z =
    face_frame_inset_combo_rail
        ? door_region_top_z
          - effective_face_frame_mid_rail_width/2
          - front_edge_reveal
        : has_doors
          && active_mount_style == "wall"
          && (mixed_bay_mode || cabinet_contents == "doors")
          && wall_doors_flush_top
          && !fronts_inset_flush
            ? cabinet_height
            : door_region_top_z;

door_face_height =
    has_doors
        ? max(0, door_face_top_z - door_face_bottom_z)
        : 0;

combo_divider_top_z = door_region_top_z;
combo_divider_bottom_z = combo_divider_top_z - material_thickness;

face_frame_mid_rail_active =
    face_frame_active
    && (
        face_frame_mid_rail_mode_resolved == "combo_auto"
        || face_frame_mid_rail_mode_resolved == "custom"
    );

face_frame_mid_rail_center_z =
    face_frame_mid_rail_mode_resolved == "combo_auto"
        ? door_region_top_z
        : face_frame_mid_rail_mode_resolved == "custom"
            ? (
                is_undef(face_frame_custom_mid_rail_z)
                    ? (face_frame_clear_bottom_z+face_frame_clear_top_z)/2
                    : face_frame_custom_mid_rail_z
              )
            : 0;

effective_drawer_front_setback =
    fronts_inset_flush
    && include_drawer_faces
        ? max(
            front_setback,
            drawer_front_thickness
            + max(0,inset_front_back_clearance)
          )
        : front_setback;

effective_wood_rail_front_setback =
    fronts_inset_flush
        ? max(
            wood_rail_front_setback,
            inset_front_interior_depth
          )
        : wood_rail_front_setback;

effective_wood_drawer_runner_front_setback =
    fronts_inset_flush
        ? max(
            wood_drawer_runner_front_setback,
            effective_drawer_front_setback
          )
        : wood_drawer_runner_front_setback;

effective_metal_slide_front_setback =
    fronts_inset_flush
        ? max(
            resolved_metal_slide_front_setback_base,
            inset_front_interior_depth
          )
        : resolved_metal_slide_front_setback_base;

drawer_box_depth =
    standalone_drawer_active
        ? standalone_drawer_box_depth
        : usable_depth
          - effective_drawer_front_setback
          - drawer_back_clearance;

front_panel_x =
    face_frame_active
        ? fronts_inset_flush
            ? face_frame_inner_left_x+front_edge_reveal
            : face_frame_inner_left_x-effective_face_frame_overlay
        : fronts_inset_flush
            ? material_thickness + front_edge_reveal
            : front_width_style == "full_overlay"
                ? front_edge_reveal
                : material_thickness + front_edge_reveal;

front_panel_width =
    face_frame_active
        ? fronts_inset_flush
            ? face_frame_clear_width-2*front_edge_reveal
            : face_frame_clear_width+2*effective_face_frame_overlay
        : fronts_inset_flush
            ? inner_width - 2*front_edge_reveal
            : front_width_style == "full_overlay"
                ? resolved_cabinet_width - 2*front_edge_reveal
                : inner_width - 2*front_edge_reveal;

// Mixed-bay decorative front boundaries are centered over the structural
// partitions, just like the weighted drawer-bank front logic.
function mixed_bay_front_left_x(b=0) =
    fronts_inset_flush
        ? mixed_bay_opening_x(b)
          + front_edge_reveal
        : b <= 0
            ? front_panel_x
            : mixed_bay_partition_center_x(b-1)
              + mixed_bay_front_gap/2;

function mixed_bay_front_right_x(b=0) =
    fronts_inset_flush
        ? mixed_bay_opening_x(b)
          + mixed_bay_opening_width(b)
          - front_edge_reveal
        : b >= active_mixed_bay_count-1
            ? front_panel_x+front_panel_width
            : mixed_bay_partition_center_x(b)
              - mixed_bay_front_gap/2;

function mixed_bay_front_width(b=0) =
    max(1,mixed_bay_front_right_x(b)-mixed_bay_front_left_x(b));

function mixed_bay_front_x(b=0) = mixed_bay_front_left_x(b);

function mixed_bay_door_hinge_side(b=0) =
    b < len(active_mixed_bay_door_hinge_sides)
        ? active_mixed_bay_door_hinge_sides[b]
        : "left";

function mixed_bay_door_leaf_width(b=0) =
    max(
        1,
        (
            mixed_bay_front_width(b)
            - door_gap*max(0,mixed_bay_door_count(b)-1)
        ) / max(1,mixed_bay_door_count(b))
    );

function mixed_bay_door_leaf_x(b=0,leaf=0) =
    mixed_bay_front_x(b)
    + leaf*(mixed_bay_door_leaf_width(b)+door_gap);

function mixed_bay_door_leaf_hinge_side(b=0,leaf=0) =
    mixed_bay_door_count(b) >= 2
        ? (leaf == 0 ? "left" : "right")
        : mixed_bay_door_hinge_side(b);

function mixed_bay_door_leaf_handle_side(b=0,leaf=0) =
    mixed_bay_door_leaf_hinge_side(b,leaf) == "left"
        ? "right"
        : "left";

function mixed_bay_door_hinge_local_x(b=0,leaf=0) =
    mixed_bay_door_leaf_hinge_side(b,leaf) == "left"
        ? effective_hinge_cup_center_from_door_edge
        : mixed_bay_door_leaf_width(b)-effective_hinge_cup_center_from_door_edge;

function mixed_bay_door_handle_local_x(b=0,leaf=0) =
    mixed_bay_door_leaf_handle_side(b,leaf) == "left"
        ? door_handle_from_open_edge
        : mixed_bay_door_leaf_width(b)-door_handle_from_open_edge;

function mixed_bay_door_uses_left_boundary(b=0) =
    mixed_bay_is_type(b,"door")
    && (
        mixed_bay_door_count(b) >= 2
        || mixed_bay_door_hinge_side(b) == "left"
    );

function mixed_bay_door_uses_right_boundary(b=0) =
    mixed_bay_is_type(b,"door")
    && (
        mixed_bay_door_count(b) >= 2
        || mixed_bay_door_hinge_side(b) == "right"
    );

function mixed_bay_hinge_z(j) =
    hinge_count <= 1
        ? door_face_bottom_z + door_face_height/2
        : door_face_bottom_z
          + hinge_end_offset
          + j*(door_face_height-2*hinge_end_offset)/(hinge_count-1);

function mixed_bay_shelf_count(b=0) =
    b < len(active_mixed_bay_shelf_counts)
        ? max(0,round(active_mixed_bay_shelf_counts[b]))
        : 0;

function mixed_bay_shelf_style(b=0) =
    b < len(active_mixed_bay_shelf_styles)
        ? active_mixed_bay_shelf_styles[b]
        : "adjustable";

function mixed_bay_is_shelfable(b=0) =
    mixed_bay_is_type(b,"door") || mixed_bay_is_type(b,"open");

function mixed_bay_has_fixed_shelves(b=0) =
    mixed_bay_is_shelfable(b)
    && mixed_bay_shelf_count(b) > 0
    && mixed_bay_shelf_style(b) == "fixed";

function mixed_bay_has_adjustable_shelves(b=0) =
    mixed_bay_is_shelfable(b)
    && mixed_bay_shelf_count(b) > 0
    && mixed_bay_shelf_style(b) != "fixed";

function mixed_bay_any_fixed_shelves(i=0) =
    i >= active_mixed_bay_count
        ? false
        : mixed_bay_has_fixed_shelves(i)
            ? true
            : mixed_bay_any_fixed_shelves(i+1);

function mixed_bay_any_adjustable_shelves(i=0) =
    i >= active_mixed_bay_count
        ? false
        : mixed_bay_has_adjustable_shelves(i)
            ? true
            : mixed_bay_any_adjustable_shelves(i+1);

function mixed_bay_shelf_z(b,s) =
    content_bottom_z
    + s*(content_height/(mixed_bay_shelf_count(b)+1))
    - material_thickness/2;

function mixed_bay_adjustable_shelf_width(b=0) =
    max(
        10,
        mixed_bay_opening_width(b)
        - 2*adjustable_shelf_side_clearance
    );

function mixed_bay_adjustable_shelf_x(b=0) =
    mixed_bay_opening_x(b)+adjustable_shelf_side_clearance;

function mixed_bay_fixed_shelf_dado_depth() = effective_dado_depth();

function mixed_bay_fixed_shelf_cut_width(b=0) =
    joinery_style == "dado"
        ? mixed_bay_opening_width(b)+2*mixed_bay_fixed_shelf_dado_depth()
        : joinery_style == "tab_slot"
            ? mixed_bay_opening_width(b)+2*material_thickness
            : mixed_bay_opening_width(b);

function mixed_bay_fixed_shelf_cut_body_offset() =
    joinery_style == "dado"
        ? mixed_bay_fixed_shelf_dado_depth()
        : joinery_style == "tab_slot"
            ? material_thickness
            : 0;

function mixed_bay_side_fixed_bay(side) =
    side == "left" ? 0 : active_mixed_bay_count-1;

function mixed_bay_side_has_fixed_shelves(side) =
    mixed_bay_mode
    && mixed_bay_has_fixed_shelves(mixed_bay_side_fixed_bay(side));

function mixed_bay_shelf_pin_count() =
    content_top_z-adjustable_shelf_hole_top_margin
        < content_bottom_z+adjustable_shelf_hole_bottom_margin
        ? 0
        : floor(
            (
                content_top_z-adjustable_shelf_hole_top_margin
                - (content_bottom_z+adjustable_shelf_hole_bottom_margin)
            ) / max(1,adjustable_shelf_hole_spacing)
          ) + 1;

function mixed_bay_shelf_pin_z(i) =
    content_bottom_z
    + adjustable_shelf_hole_bottom_margin
    + i*adjustable_shelf_hole_spacing;

function door_width_weight(i=0) =
    i < len(door_width_weights)
        ? max(0.05,door_width_weights[i])
        : 1;

function door_width_weight_sum(i=0) =
    i >= door_count
        ? 0
        : door_width_weight(i)
          + door_width_weight_sum(i+1);

door_width_weight_total =
    max(0.05,door_width_weight_sum());

door_available_front_width =
    max(
        1,
        front_panel_width
        - door_gap*max(0,door_count-1)
    );

function door_each_width(i=0) =
    max(
        1,
        door_available_front_width
        *door_width_weight(i)
        /door_width_weight_total
    );

function door_width_prefix(i,j=0) =
    j >= i
        ? 0
        : door_each_width(j)
          + door_width_prefix(i,j+1);

function door_local_x(i) =
    door_width_prefix(i)
    + i*door_gap;

function door_layout_part_x(i,j=0) =
    j >= i
        ? 0
        : door_each_width(j)
          + layout_gap
          + door_layout_part_x(i,j+1);

function door_hinge_side(i) =
    door_count == 1
        ? single_door_hinge_side
        : i == 0
            ? "left"
            : i == door_count-1
                ? "right"
                : (i % 2 == 0 ? "left" : "right");

function door_handle_side(i) =
    door_hinge_side(i) == "left" ? "right" : "left";

function hinge_z(j) =
    hinge_count <= 1
        ? door_face_bottom_z + door_face_height/2
        : door_face_bottom_z
          + hinge_end_offset
          + j*(door_face_height-2*hinge_end_offset)/(hinge_count-1);

function hinge_local_z(j) =
    hinge_z(j)-door_face_bottom_z;

function hinge_local_x(door_w,i) =
    door_hinge_side(i) == "left"
        ? effective_hinge_cup_center_from_door_edge
        : door_w-effective_hinge_cup_center_from_door_edge;

function cabinet_side_has_door_hinges(side) =
    !mixed_bay_mode
    && has_doors
    && effective_hinge_style != "none"
    && (
        (door_count == 1 && single_door_hinge_side == side)
        || (door_count >= 2 && (side == "left" || side == "right"))
    );

function door_handle_local_x(door_w,i) =
    door_handle_side(i) == "left"
        ? door_handle_from_open_edge
        : door_w-door_handle_from_open_edge;

function door_handle_local_z() =
    door_face_height-door_handle_from_top;


// ---------------------------
// MULTI-DOOR FULL-DEPTH PARTITIONS
// ---------------------------

// More than two side-by-side doors receive one vertical partition behind each
// inter-door gap. The partition is structural and runs from the cabinet front
// to the rear construction, so each door has a true compartment.
//
// Partitions reach the full cabinet depth. If structural rear stretchers are
// selected, open rear notches let those stretchers pass through the partition
// plane without shortening the partition.
active_door_hinge_partitions =
    !mixed_bay_mode
    && has_doors
    && include_door_hinge_partitions
    && door_count > 2;

function door_hinge_partition_count() =
    active_door_hinge_partitions ? door_count-1 : 0;

function door_gap_center_x(p) =
    front_panel_x
    + door_local_x(p)
    + door_each_width(p)
    + door_gap/2;

function door_hinge_partition_x(p) =
    min(
        resolved_cabinet_width-2*material_thickness,
        max(
            material_thickness,
            door_gap_center_x(p)-material_thickness/2
        )
    );

function door_hinge_partition_bottom_z() =
    front_opening_bottom_z;

function door_hinge_partition_top_z() =
    cabinet_contents == "combo"
        ? combo_divider_bottom_z
        : front_opening_top_z;

function door_hinge_partition_body_height() =
    max(
        1,
        door_hinge_partition_top_z()
        - door_hinge_partition_bottom_z()
    );

door_hinge_partition_actual_depth = usable_depth;

function door_hinge_partition_dado_depth() =
    min(effective_dado_depth(),material_thickness-0.2);

function door_hinge_partition_cut_height() =
    joinery_style == "dado"
        ? door_hinge_partition_body_height()
          + 2*door_hinge_partition_dado_depth()
        : joinery_style == "tab_slot"
            ? door_hinge_partition_body_height()+2*material_thickness
            : door_hinge_partition_body_height();

function door_hinge_partition_cut_body_offset() =
    joinery_style == "dado"
        ? door_hinge_partition_dado_depth()
        : joinery_style == "tab_slot"
            ? material_thickness
            : 0;

function door_hinge_partition_cut_global_bottom_z() =
    door_hinge_partition_bottom_z()
    - door_hinge_partition_cut_body_offset();

function door_hinge_depth_overlap_start(panel_y0) =
    max(0,panel_y0);

function door_hinge_depth_overlap_end(panel_y0,panel_depth) =
    min(
        door_hinge_partition_actual_depth,
        panel_y0+panel_depth
    );

function door_hinge_depth_overlap_length(panel_y0,panel_depth) =
    max(
        0,
        door_hinge_depth_overlap_end(panel_y0,panel_depth)
        - door_hinge_depth_overlap_start(panel_y0)
    );

// Door-bay boundaries are used for adjustable shelves. A full-depth partition
// physically separates the shelf spaces, so loose shelves become one panel per
// door compartment rather than one full-width panel with impossible cutouts.
function door_bay_left_x(b) =
    b <= 0
        ? material_thickness
        : door_hinge_partition_x(b-1)+material_thickness;

function door_bay_right_x(b) =
    b >= door_count-1
        ? resolved_cabinet_width-material_thickness
        : door_hinge_partition_x(b);

function door_bay_opening_width(b) =
    max(1,door_bay_right_x(b)-door_bay_left_x(b));

function door_bay_adjustable_shelf_width(b) =
    max(
        10,
        door_bay_opening_width(b)
        - 2*adjustable_shelf_side_clearance
    );

function door_bay_adjustable_shelf_x(b) =
    door_bay_left_x(b)+adjustable_shelf_side_clearance;

function door_bay_shelf_layout_prefix(b,j=0) =
    j >= b
        ? 0
        : door_bay_adjustable_shelf_width(j)
          + layout_gap
          + door_bay_shelf_layout_prefix(b,j+1);

function door_adjustable_shelf_piece_count() =
    door_hinge_partition_count() > 0 ? door_count : 1;

function door_adjustable_shelf_piece_width(b=0) =
    door_hinge_partition_count() > 0
        ? door_bay_adjustable_shelf_width(b)
        : adjustable_shelf_width;

function door_adjustable_shelf_piece_x(b=0) =
    door_hinge_partition_count() > 0
        ? door_bay_adjustable_shelf_x(b)
        : material_thickness+adjustable_shelf_side_clearance;

function door_adjustable_shelf_layout_x(b=0) =
    door_hinge_partition_count() > 0
        ? door_bay_shelf_layout_prefix(b)
        : 0;

// ---------------------------
// GENERALIZED MIXED-BAY PARTITIONS / SHELVES
// ---------------------------

function mixed_bay_partition_bottom_z() = front_opening_bottom_z;
function mixed_bay_partition_top_z() = front_opening_top_z;
function mixed_bay_partition_body_height() =
    max(1,mixed_bay_partition_top_z()-mixed_bay_partition_bottom_z());

mixed_bay_partition_depth = usable_depth;

function mixed_bay_partition_dado_depth() =
    min(effective_dado_depth(),material_thickness-0.2);

function mixed_bay_partition_cut_height() =
    joinery_style == "dado"
        ? mixed_bay_partition_body_height()
          + 2*mixed_bay_partition_dado_depth()
        : joinery_style == "tab_slot"
            ? mixed_bay_partition_body_height()+2*material_thickness
            : mixed_bay_partition_body_height();

function mixed_bay_partition_cut_body_offset() =
    joinery_style == "dado"
        ? mixed_bay_partition_dado_depth()
        : joinery_style == "tab_slot"
            ? material_thickness
            : 0;

function mixed_bay_partition_cut_global_bottom_z() =
    mixed_bay_partition_bottom_z()
    - mixed_bay_partition_cut_body_offset();

function mixed_bay_depth_overlap_start(panel_y0) = max(0,panel_y0);
function mixed_bay_depth_overlap_end(panel_y0,panel_depth) =
    min(mixed_bay_partition_depth,panel_y0+panel_depth);
function mixed_bay_depth_overlap_length(panel_y0,panel_depth) =
    max(
        0,
        mixed_bay_depth_overlap_end(panel_y0,panel_depth)
        - mixed_bay_depth_overlap_start(panel_y0)
    );

function mixed_bay_partition_has_hinge_plates(p) =
    effective_hinge_style != "none"
    && (
        mixed_bay_door_uses_right_boundary(p)
        || mixed_bay_door_uses_left_boundary(p+1)
    );

function mixed_bay_partition_has_shelf_pins(p) =
    mixed_bay_has_adjustable_shelves(p)
    || mixed_bay_has_adjustable_shelves(p+1);

function mixed_bay_side_has_hinge_plates(side) =
    effective_hinge_style != "none"
    && (
        (side == "left" && mixed_bay_door_uses_left_boundary(0))
        ||
        (side == "right"
         && mixed_bay_door_uses_right_boundary(active_mixed_bay_count-1))
    );

function mixed_bay_side_has_shelf_pins(side) =
    side == "left"
        ? mixed_bay_has_adjustable_shelves(0)
        : mixed_bay_has_adjustable_shelves(active_mixed_bay_count-1);

function mixed_bay_shelf_count_prefix(b,j=0) =
    j >= b
        ? 0
        : (mixed_bay_is_shelfable(j) ? mixed_bay_shelf_count(j) : 0)
          + mixed_bay_shelf_count_prefix(b,j+1);

function mixed_bay_total_shelf_count() =
    mixed_bay_shelf_count_prefix(active_mixed_bay_count);

function mixed_bay_shelf_part_index(b,s) =
    mixed_bay_shelf_count_prefix(b)+s-1;

function mixed_bay_door_layout_span(b=0) =
    mixed_bay_is_type(b,"door")
        ? mixed_bay_door_count(b)*mixed_bay_door_leaf_width(b)
          + max(0,mixed_bay_door_count(b)-1)*layout_gap
        : 0;

function mixed_bay_door_layout_prefix(b,j=0) =
    j >= b
        ? 0
        : (mixed_bay_is_type(j,"door")
            ? mixed_bay_door_layout_span(j)+layout_gap
            : 0)
          + mixed_bay_door_layout_prefix(b,j+1);

function mixed_bay_door_layout_x(b=0,leaf=0) =
    mixed_bay_door_layout_prefix(b)
    + leaf*(mixed_bay_door_leaf_width(b)+layout_gap);

// Weighted drawer banks separated by carcass-material vertical partitions.
// Equal weights preserve the previous equal-column behavior.
function drawer_bank_width_weight(b=0) =
    b < len(drawer_bank_width_weights)
        ? max(0.05,drawer_bank_width_weights[b])
        : 1;

function drawer_bank_width_weight_sum(i=0) =
    i >= drawer_bank_count
        ? 0
        : drawer_bank_width_weight(i)
          + drawer_bank_width_weight_sum(i+1);

drawer_bank_width_weight_total =
    max(0.05,drawer_bank_width_weight_sum());

drawer_bank_available_opening_width =
    max(
        1,
        (
            face_frame_active
                ? face_frame_clear_width
                : inner_width
        )
        - max(0,drawer_bank_count-1)*material_thickness
    );

function drawer_bank_opening_width(b=0) =
    standalone_drawer_active
        ? standalone_enclosure_opening_width
        : mixed_bay_mode
            ? mixed_bay_opening_width(b)
            : max(
                1,
                drawer_bank_available_opening_width
                *drawer_bank_width_weight(b)
                /drawer_bank_width_weight_total
              );

function drawer_bank_opening_width_prefix(b,j=0) =
    j >= b
        ? 0
        : drawer_bank_opening_width(j)
          + drawer_bank_opening_width_prefix(b,j+1);

function drawer_bank_opening_x(b=0) =
    standalone_drawer_active
        ? 0
        : mixed_bay_mode
            ? mixed_bay_opening_x(b)
            : (
                face_frame_active
                    ? face_frame_inner_left_x
                    : material_thickness
              )
              + drawer_bank_opening_width_prefix(b)
              + b*material_thickness;

function drawer_bank_partition_center_x(p) =
    mixed_bay_mode
        ? mixed_bay_partition_center_x(p)
        : drawer_bank_opening_x(p)
          + drawer_bank_opening_width(p)
          + material_thickness/2;

function drawer_outer_width(b=0) =
    standalone_drawer_active
        ? standalone_drawer_outer_width
        : drawer_mount == "metal_slides"
            ? drawer_bank_opening_width(b)
              - 2*effective_metal_slide_clearance_per_side
            : drawer_mount == "wood_rails"
                ? drawer_bank_opening_width(b)
                  - 2*(
                        wood_rail_thickness
                        + wood_rail_side_clearance
                      )
                : drawer_bank_opening_width(b)
                  - 2*effective_drawer_free_fit_clearance_per_side;

function drawer_box_x0(b=0) =
    standalone_drawer_active
        ? standalone_drawer_box_x0
        : drawer_bank_opening_x(b)
          + (
                drawer_bank_opening_width(b)
                - drawer_outer_width(b)
            )/2;

// Decorative bank-face gaps are centered on the structural partitions so a
// weighted bank remains visually aligned with its actual opening.
function drawer_face_left_x(b=0) =
    standalone_drawer_active
        ? standalone_drawer_face_x
        : fronts_inset_flush
            ? drawer_bank_opening_x(b)
              + front_edge_reveal
            : mixed_bay_mode
                ? mixed_bay_front_left_x(b)
                : b <= 0
                    ? front_panel_x
                    : drawer_bank_partition_center_x(b-1)
                      + drawer_bank_face_gap/2;

function drawer_face_right_x(b=0) =
    standalone_drawer_active
        ? standalone_drawer_face_x
          + standalone_drawer_face_width
        : fronts_inset_flush
            ? drawer_bank_opening_x(b)
              + drawer_bank_opening_width(b)
              - front_edge_reveal
            : mixed_bay_mode
                ? mixed_bay_front_right_x(b)
                : b >= drawer_bank_count-1
                    ? front_panel_x+front_panel_width
                    : drawer_bank_partition_center_x(b)
                      - drawer_bank_face_gap/2;

function drawer_face_width(b=0) =
    standalone_drawer_active
        ? standalone_drawer_face_width
        : max(
            1,
            drawer_face_right_x(b)-drawer_face_left_x(b)
          );

function drawer_face_x(b=0) =
    drawer_face_left_x(b);

// Sum nominal face heights from drawer 0 through i (inclusive).
function drawer_face_height_prefix(i,b=0,j=0) =
    j > i
        ? 0
        : drawer_face_nominal_height(j,b)
          + drawer_face_height_prefix(i,b,j+1);

function drawer_face_z(i,b=0) =
    standalone_drawer_active
        ? standalone_drawer_face_z
        : content_top_z
          - drawer_face_height_prefix(i,b)
          - i*drawer_gap;

// Optional decorative-only extension for the TOP drawer face. Every bank's
// top face may reach the cabinet top while its box geometry stays unchanged.
function drawer_face_top_extension(i,b=0) =
    include_drawer_faces
    && extend_top_drawer_face_to_top
    && !fronts_inset_flush
    && i == 0
        ? max(0,cabinet_height-content_top_z)
        : 0;

function drawer_face_height_for(i,b=0) =
    standalone_drawer_active
        ? standalone_drawer_face_height
        : drawer_face_nominal_height(i,b)
          + drawer_face_top_extension(i,b);

function drawer_face_top_z(i,b=0) =
    drawer_face_z(i,b)
    + drawer_face_height_for(i,b);

function effective_drawer_vertical_clearance_for(b=0) =
    standalone_drawer_active
        ? standalone_drawer_vertical_clearance
        : !mixed_bay_mode
          && include_drawer_separators
          && drawer_bank_layout_mode == "shared"
          && has_drawers
          && drawer_bank_drawer_count(b) > 1
            ? max(
                drawer_vertical_clearance,
                (material_thickness-drawer_gap)/2 + 2
              )
            : drawer_vertical_clearance;

function drawer_box_opening_bottom_z(i,b=0) =
    standalone_drawer_active
        ? 0
        : max(drawer_face_z(i,b), content_bottom_z);

function drawer_box_opening_top_z(i,b=0) =
    standalone_drawer_active
        ? standalone_enclosure_opening_height
        : drawer_face_z(i,b)
          + drawer_face_nominal_height(i,b);

function drawer_box_height(i=0,b=0) =
    standalone_drawer_active
        ? standalone_drawer_box_height
        : max(
            40,
            drawer_box_opening_top_z(i,b)
            - drawer_box_opening_bottom_z(i,b)
            - 2*effective_drawer_vertical_clearance_for(b)
          );

function drawer_box_z(i,b=0) =
    standalone_drawer_active
        ? standalone_drawer_box_z
        : drawer_box_opening_bottom_z(i,b)
          + effective_drawer_vertical_clearance_for(b);

// Separator i is between drawer i and drawer i+1. Full-width separators are
// supported only in shared bank mode because independent stacks need different
// Z boundaries.
function drawer_separator_z(i,b=0) =
    drawer_face_z(i,b)
    - drawer_gap/2
    - material_thickness/2;

function drawer_runner_z(i,b=0) =
    drawer_box_z(i,b)
    + wood_drawer_runner_bottom_offset;


// Fixed cabinet rail is calculated from the drawer runner so the runner's
// underside rides directly above the rail's top surface.
function drawer_rail_z(i,b=0) =
    drawer_runner_z(i,b)
    - wood_rail_vertical_clearance
    - wood_rail_height;

function active_slide_length() = min(effective_metal_slide_length, drawer_box_depth);
function slide_cabinet_hole_depth(hx) = effective_metal_slide_front_setback + hx;
function slide_drawer_hole_depth(hx) = effective_metal_slide_front_setback + hx;
function cabinet_slide_hole_is_valid(hx,available_depth) = slide_cabinet_hole_depth(hx) <= min(active_slide_length(),available_depth)-effective_metal_slide_rear_margin;
function drawer_slide_hole_is_valid(hx,available_depth) = slide_drawer_hole_depth(hx) <= min(active_slide_length(),available_depth)-effective_metal_slide_rear_margin;

function compensated_hole_diameter(d) =
    max(0.1, d - (apply_kerf_compensation ? kerf : 0));

function effective_dado_depth() =
    min(max(0.1,dado_depth), material_thickness);

function effective_back_dado_depth() =
    min(max(0.1,dado_depth), material_thickness);

function effective_drawer_dado_depth() =
    min(
        max(0.1,drawer_dado_depth),
        max(0.1,drawer_material_thickness-0.5)
    );

function effective_drawer_bottom_dado_depth() =
    min(
        max(0.1,drawer_bottom_dado_depth),
        max(0.1,drawer_material_thickness-0.5)
    );

function drawer_inner_width(b=0) =
    drawer_outer_width(b) - 2*drawer_material_thickness;

function drawer_inner_depth() =
    drawer_box_depth - 2*drawer_material_thickness;

function drawer_cross_panel_width(b=0) =
    drawer_joinery_style == "dado"
        ? drawer_inner_width(b) + 2*effective_drawer_dado_depth()
        : drawer_joinery_style == "tab_slot"
            ? drawer_outer_width(b)
            : drawer_inner_width(b);

// Location of the normal inner-width body inside a flat front/back profile.
function drawer_cross_panel_inner_x_offset() =
    drawer_joinery_style == "dado"
        ? effective_drawer_dado_depth()
        : drawer_joinery_style == "tab_slot"
            ? drawer_material_thickness
            : 0;

function drawer_bottom_width(b=0) =
    drawer_inner_width(b)
    + (drawer_bottom_joinery == "dado"
        ? 2*effective_drawer_bottom_dado_depth()
        : 0);

function drawer_bottom_depth() =
    drawer_inner_depth()
    + (drawer_bottom_joinery == "dado"
        ? 2*effective_drawer_bottom_dado_depth()
        : 0);


// ---------------------------
// DIMENSION REPORT HELPERS
// ---------------------------

// Primary carcass clear-space dimensions. "Clear depth" begins behind an
// inset/flush decorative front when that mounting style is active.
function cabinet_clear_width() =
    max(0,inner_width);

function cabinet_clear_height() =
    max(
        0,
        front_opening_top_z-front_opening_bottom_z
    );

function cabinet_clear_depth() =
    max(
        0,
        usable_depth
        - (
            fronts_inset_flush
                ? max(
                    0,
                    decorative_front_back_y(
                        max(
                            has_doors ? door_thickness : 0,
                            has_drawers && include_drawer_faces
                                ? drawer_front_thickness
                                : 0
                        )
                    )
                  )
                : 0
          )
    );

// Drawer dimensions are finished/assembled dimensions, not flat-part envelope
// dimensions. The inside height is measured from the TOP of the drawer bottom
// panel to the top edge of the drawer walls.
function drawer_inside_clear_height(i=0,b=0) =
    max(
        0,
        drawer_box_height(i,b)
        - drawer_bottom_inset
        - drawer_bottom_thickness
    );

function drawer_opening_height(i=0,b=0) =
    max(
        0,
        drawer_box_opening_top_z(i,b)
        - drawer_box_opening_bottom_z(i,b)
    );

function drawer_side_clearance_per_side(b=0) =
    max(
        0,
        (
            drawer_bank_opening_width(b)
            - drawer_outer_width(b)
        )/2
    );

function drawer_vertical_clearance_per_side(b=0) =
    max(
        0,
        effective_drawer_vertical_clearance_for(b)
    );

// Cabinet/bay height available to generalized mixed-bay doors/open shelves.
function mixed_bay_clear_height(b=0) =
    max(
        0,
        front_opening_top_z-front_opening_bottom_z
    );

// Drawer box-front <-> decorative-face registration pattern.
// Pattern is centered on the cabinet/drawer width so it lines up in every
// front_width_style and every drawer joinery style.
function drawer_face_reg_dx(n) =
    (n-(drawer_face_registration_hole_count-1)/2)
    * drawer_face_registration_hole_spacing;

function drawer_face_reg_global_x(n,b=0) =
    drawer_box_x0(b) + drawer_outer_width(b)/2 + drawer_face_reg_dx(n);

function drawer_face_reg_box_local_x(n,b=0) =
    drawer_cross_panel_width(b)/2 + drawer_face_reg_dx(n);

function drawer_face_reg_face_local_x(n,b=0) =
    drawer_face_reg_global_x(n,b)-drawer_face_x(b);

function drawer_face_reg_global_z(i,b=0) =
    drawer_box_z(i,b)
    + drawer_box_height(i,b)/2
    + drawer_face_registration_vertical_offset;

function drawer_face_reg_box_local_z(i,b=0) =
    drawer_box_height(i,b)/2
    + drawer_face_registration_vertical_offset;

function drawer_face_reg_face_local_z(i,b=0) =
    drawer_face_reg_global_z(i,b)-drawer_face_z(i,b);

function drawer_face_registration_blind_depth() =
    drawer_front_thickness/2;

active_drawer_face_registration =
    include_drawer_faces && include_drawer_face_registration_holes;

function drawer_bank_partition_joinery_mode() =
    drawer_bank_partition_joinery == "match_carcass"
        ? joinery_style
        : drawer_bank_partition_joinery;

function drawer_bank_partition_count() = mixed_bay_mode ? 0 : max(0,drawer_bank_count-1);

function drawer_bank_partition_x(p) =
    drawer_bank_opening_x(p)
    + drawer_bank_opening_width(p);

function drawer_bank_partition_bottom_z() =
    cabinet_contents == "combo"
        ? combo_divider_top_z
        : front_opening_bottom_z;

function drawer_bank_partition_top_z() = front_opening_top_z;

function drawer_bank_partition_body_height() =
    max(1,drawer_bank_partition_top_z()-drawer_bank_partition_bottom_z());

drawer_bank_partition_depth =
    max(20,usable_depth-drawer_bank_partition_rear_clearance);

function drawer_bank_partition_dado_depth() =
    min(effective_dado_depth(),material_thickness-0.2);

function drawer_bank_partition_cut_height() =
    drawer_bank_partition_joinery_mode() == "dado"
        ? drawer_bank_partition_body_height()
          + 2*drawer_bank_partition_dado_depth()
        : drawer_bank_partition_joinery_mode() == "tab_slot"
            ? drawer_bank_partition_body_height()+2*material_thickness
            : drawer_bank_partition_body_height();

function horizontal_panel_global_x0() =
    joinery_style == "dado"
        ? material_thickness-effective_dado_depth()
        : joinery_style == "tab_slot"
            ? 0
            : material_thickness;

function horizontal_panel_local_x(global_x) =
    global_x-horizontal_panel_global_x0();

function depth_overlap_start(panel_y0) = max(0,panel_y0);
function depth_overlap_end(panel_y0,panel_depth) =
    min(drawer_bank_partition_depth,panel_y0+panel_depth);
function depth_overlap_length(panel_y0,panel_depth) =
    max(0,depth_overlap_end(panel_y0,panel_depth)-depth_overlap_start(panel_y0));

function drawer_bottom_cross_panel_local_x() =
    drawer_cross_panel_inner_x_offset()
    - (drawer_bottom_joinery == "dado"
        ? effective_drawer_bottom_dado_depth()
        : 0);

// Automatic butt-registration pattern: long parts receive more guide holes,
// while short stretchers naturally reduce to one.
function butt_reg_margin(span) =
    min(butt_registration_edge_margin, max(6,span*0.25));

function butt_reg_count(span) =
    max(1, round(span / max(1,butt_registration_target_spacing)));

function butt_reg_pos(span,i) =
    butt_reg_margin(span)
    + (span-2*butt_reg_margin(span))*(i+0.5)/butt_reg_count(span);

// Evenly spaced wood-slide registration holes, measured from the front/end of
// the rail/runner itself.
function wood_slide_reg_margin(span) =
    min(wood_slide_registration_end_margin, max(5,span*0.25));

function wood_slide_reg_pos(span,i) =
    wood_slide_registration_hole_count <= 1
        ? span/2
        : wood_slide_reg_margin(span)
          + i*(span-2*wood_slide_reg_margin(span))
            /(wood_slide_registration_hole_count-1);

// Drawer side starts at front_setback, while the runner's setting is in
// cabinet-global Y coordinates.
function wood_drawer_runner_local_front() =
    effective_wood_drawer_runner_front_setback
    - effective_drawer_front_setback;

// Drawer-runner registration holes also pass through the drawer SIDE panel.
// With tab/slot drawer corners, an end registration hole can otherwise land
// in the front/rear tab slot (or its CNC corner relief). Keep the hole centers inside a
// safe depth interval while leaving the fixed CABINET rail pattern unchanged.
function wood_drawer_runner_reg_web() =
    max(2, wood_slide_registration_hole_diameter/2);

function slot_relief_is_dogbone() =
    slot_corner_relief == "dogbone";

function slot_relief_is_tbone() =
    slot_corner_relief == "t_bone"
    || slot_corner_relief == "tbone"
    || slot_corner_relief == "t-bone";

function slot_relief_is_active() =
    (slot_relief_is_dogbone() || slot_relief_is_tbone())
    && cnc_tool_diameter > 0;

function slot_relief_radius() =
    max(0,cnc_tool_diameter/2);

function slot_dogbone_inset() =
    slot_relief_radius()/sqrt(2);

// Maximum distance the relief extends OUTSIDE a nominal slot wall.
// Conventional diagonal dogbones only project r-r/sqrt(2) past each wall.
// A T-bone can project a full cutter radius past the relieved wall.
function drawer_tab_slot_relief_reach() =
    slot_relief_is_dogbone()
        ? max(0,slot_relief_radius()-slot_dogbone_inset())
        : slot_relief_is_tbone()
            ? slot_relief_radius()
            : 0;

function wood_drawer_runner_side_safe_min(d) =
    drawer_material_thickness
    + drawer_joint_fit_clearance/2
    + drawer_tab_slot_relief_reach()
    + wood_slide_registration_hole_diameter/2
    + wood_drawer_runner_reg_web();

function wood_drawer_runner_side_safe_max(d) =
    d
    - drawer_material_thickness
    - drawer_joint_fit_clearance/2
    - drawer_tab_slot_relief_reach()
    - wood_slide_registration_hole_diameter/2
    - wood_drawer_runner_reg_web();

function wood_drawer_runner_reg_min(d) =
    drawer_joinery_style == "tab_slot"
        ? max(
            wood_slide_reg_margin(resolved_wood_drawer_runner_depth),
            wood_drawer_runner_side_safe_min(d)
                - wood_drawer_runner_local_front()
          )
        : wood_slide_reg_margin(resolved_wood_drawer_runner_depth);

function wood_drawer_runner_reg_max(d) =
    drawer_joinery_style == "tab_slot"
        ? min(
            resolved_wood_drawer_runner_depth
                - wood_slide_reg_margin(resolved_wood_drawer_runner_depth),
            wood_drawer_runner_side_safe_max(d)
                - wood_drawer_runner_local_front()
          )
        : resolved_wood_drawer_runner_depth
          - wood_slide_reg_margin(resolved_wood_drawer_runner_depth);

function wood_drawer_runner_reg_valid(d) =
    wood_drawer_runner_reg_max(d)
    >= wood_drawer_runner_reg_min(d);

function wood_drawer_runner_reg_pos(d,i) =
    wood_slide_registration_hole_count <= 1
        ? (wood_drawer_runner_reg_min(d)
           + wood_drawer_runner_reg_max(d))/2
        : wood_drawer_runner_reg_min(d)
          + i*(
                wood_drawer_runner_reg_max(d)
                - wood_drawer_runner_reg_min(d)
              )
            /(wood_slide_registration_hole_count-1);

function side_has_toe_cutout(side) =
    side_toe_kick_cutout == "both"
    || side_toe_kick_cutout == side;

function tab_margin(span) =
    min(joint_tab_edge_margin, max(2,span*0.15));

// Maximum count that physically fits while preserving the requested minimum
// solid web between joints. This uses the desired tab width; it does not
// intentionally shrink tabs merely to cram more joints onto a short edge.
function max_tabs_by_web(span) =
    max(1,
        floor(
            (span - 2*tab_margin(span) + minimum_joint_web)
            / max(0.1, joint_tab_width + minimum_joint_web)
        )
    );

// Adaptive count uses BOTH an approximate spacing target and the physical
// minimum-web constraint.
function auto_tab_count(span) =
    min(
        max_auto_tab_count,
        max_tabs_by_web(span),
        max(1, round(span / max(1,target_tab_spacing)))
    );

function effective_tab_count(span) =
    tab_count_mode == "fixed"
        ? max(1,joint_tab_count)
        : auto_tab_count(span);

// In fixed mode the width may shrink if necessary to keep geometry valid.
// In adaptive mode this normally remains joint_tab_width because the count
// has already been reduced to preserve minimum_joint_web.
function tab_width_for(span) =
    min(
        joint_tab_width,
        max(
            6,
            (
                span
                - 2*tab_margin(span)
                - max(0,effective_tab_count(span)-1)*minimum_joint_web
            ) / max(1,effective_tab_count(span))
        )
    );

function tab_center(span,i) =
    tab_margin(span)
    + (span-2*tab_margin(span))*(i+0.5)/effective_tab_count(span);

function tab_start(span,i) =
    tab_center(span,i) - tab_width_for(span)/2;

// ---------------------------
// LOCATION-AWARE CARCASS TAB PLACEMENT (INHERITED FROM V35)
// ---------------------------
//
// Horizontal carcass joints resolve through one location-aware policy.  This
// keeps matching tabs and side-panel slots on the same resolver and avoids
// one-off geometry patches.  Supported locations are bottom, top, shelf,
// separator, and default.  Custom center arrays are measured from the local
// FRONT edge of the mating panel.

function resolved_edge_joinery_policy() =
    is_undef(edge_joinery_policy) ? "legacy" : edge_joinery_policy;

function location_tab_placement(location="default") =
    resolved_edge_joinery_policy() == "legacy"
        ? (location == "bottom" && stackable_mode
            ? (is_undef(bottom_tab_placement) ? "automatic" : bottom_tab_placement)
            : "automatic")
        : location == "bottom"
            ? (is_undef(bottom_tab_placement) ? "automatic" : bottom_tab_placement)
        : location == "top"
            ? (is_undef(top_tab_placement) ? "automatic" : top_tab_placement)
        : location == "shelf"
            ? (is_undef(shelf_tab_placement) ? "automatic" : shelf_tab_placement)
        : location == "separator"
            ? (is_undef(separator_tab_placement) ? "automatic" : separator_tab_placement)
        : "automatic";

function location_tab_custom_centers(location="default") =
    location == "bottom"
        ? (is_undef(bottom_tab_custom_centers) ? [] : bottom_tab_custom_centers)
    : location == "top"
        ? (is_undef(top_tab_custom_centers) ? [] : top_tab_custom_centers)
    : location == "shelf"
        ? (is_undef(shelf_tab_custom_centers) ? [] : shelf_tab_custom_centers)
    : location == "separator"
        ? (is_undef(separator_tab_custom_centers) ? [] : separator_tab_custom_centers)
    : [];

function location_tab_custom_centers_resolved(span,location="default") =
    [
        for (p=location_tab_custom_centers(location))
            if (
                is_num(p)
                && p >= tab_width_for(span)/2
                && p <= span-tab_width_for(span)/2
            ) p
    ];

function location_tab_custom_active(span,location="default") =
    location_tab_placement(location) == "custom"
    && len(location_tab_custom_centers_resolved(span,location)) > 0;

// Edge-biased placement preserves the ordinary tab count and tab width, but
// brings the first/last tabs to the configured edge margin.  Internal tabs are
// distributed linearly between them.
function edge_biased_tab_center(span,i) =
    let(
        n = effective_tab_count(span),
        w = tab_width_for(span),
        a = tab_margin(span) + w/2,
        b = span - tab_margin(span) - w/2
    )
    n <= 1 || b <= a ? span/2 : a + (b-a)*i/(n-1);

// A small web keeps slot clearance / optional corner relief away from a
// stackable shoulder. The nominal tab itself remains joint_tab_width wide.
function stack_safe_bottom_tab_edge_web() =
    max(
        1,
        joint_fit_clearance/2
        + (slot_relief_is_active() ? slot_relief_radius() : 0)
    );

function stack_safe_bottom_edge_center(span,front=true) =
    let(
        w = tab_width_for(span),
        web = stack_safe_bottom_tab_edge_web(),
        pad = front
            ? effective_stack_front_margin
            : effective_stack_back_margin,
        min_center = w/2 + web,
        max_center = max(min_center,pad-w/2-web),
        preferred = pad/2
    )
    min(max(preferred,min_center),max_center);

function stack_safe_bottom_tabs_possible(span) =
    let(
        w = tab_width_for(span),
        web = stack_safe_bottom_tab_edge_web()
    )
    effective_stack_front_margin >= w+2*web
    && effective_stack_back_margin >= w+2*web;

function stack_safe_bottom_tab_center(span,i) =
    let(
        n = effective_tab_count(span),
        fc = stack_safe_bottom_edge_center(span,true),
        rc = span-stack_safe_bottom_edge_center(span,false)
    )
    !stack_safe_bottom_tabs_possible(span)
        ? tab_center(span,i)
        : n <= 1
        ? span/2
        : fc + (rc-fc)*i/(n-1);

function tab_count_for_location(span,location="default") =
    location_tab_custom_active(span,location)
        ? len(location_tab_custom_centers_resolved(span,location))
        : effective_tab_count(span);

function tab_center_for_location(span,i,location="default") =
    location_tab_custom_active(span,location)
        ? location_tab_custom_centers_resolved(span,location)[i]
        : (
            location == "bottom"
            && stackable_mode
            && location_tab_placement(location) == "stack_safe"
          )
            ? stack_safe_bottom_tab_center(span,i)
        : location_tab_placement(location) == "edge_biased"
            ? edge_biased_tab_center(span,i)
        : tab_center(span,i);

function tab_start_for_location(span,i,location="default") =
    tab_center_for_location(span,i,location) - tab_width_for(span)/2;

// Compatibility wrappers retained for the V34 stackable API.
function resolved_bottom_tab_placement() = location_tab_placement("bottom");
function bottom_tab_custom_centers_resolved(span) =
    location_tab_custom_centers_resolved(span,"bottom");
function bottom_tab_custom_active(span) = location_tab_custom_active(span,"bottom");
function bottom_tab_count(span) = tab_count_for_location(span,"bottom");
function bottom_tab_center(span,i) = tab_center_for_location(span,i,"bottom");
function bottom_tab_start(span,i) = tab_start_for_location(span,i,"bottom");

function joined_panel_width() =
    joinery_style == "dado"
        ? inner_width + 2*effective_dado_depth()
        : joinery_style == "tab_slot"
            ? resolved_cabinet_width
            : inner_width;

// Local X offset of the inner-width body in a flat horizontal carcass part.
function horizontal_panel_inner_x_offset() =
    joinery_style == "dado"
        ? effective_dado_depth()
        : joinery_style == "tab_slot"
            ? material_thickness
            : 0;

function door_shelf_z(s) =
    door_region_bottom_z
    + s*(door_region_height/(door_shelf_count+1))
    - material_thickness/2;

adjustable_shelf_width =
    max(10, inner_width - 2*adjustable_shelf_side_clearance);

shelf_pin_z_min =
    door_region_bottom_z + adjustable_shelf_hole_bottom_margin;

shelf_pin_z_max =
    door_region_top_z - adjustable_shelf_hole_top_margin;

function shelf_pin_count() =
    !has_doors || shelf_style != "adjustable" || shelf_pin_z_max < shelf_pin_z_min
        ? 0
        : floor(
            (shelf_pin_z_max-shelf_pin_z_min)
            / max(1,adjustable_shelf_hole_spacing)
          ) + 1;

function shelf_pin_z(i) =
    shelf_pin_z_min + i*adjustable_shelf_hole_spacing;

function shelf_pin_y(row) =
    row == 0
        ? adjustable_shelf_front_setback
        : resolved_cabinet_depth-adjustable_shelf_rear_setback;


// Structural/captured-back body dimensions. The solid back fits BETWEEN the
// bottom/top members in butt mode, then gains dado tongues or tab extensions
// according to the active carcass joinery.
captured_back_bottom_z =
    bottom_above_toe + material_thickness;

captured_back_top_z =
    cabinet_height - material_thickness;

captured_back_height =
    max(
        0,
        captured_back_top_z-captured_back_bottom_z
    );

structural_back_dado_depth =
    min(
        effective_dado_depth(),
        material_thickness-0.2
    );

function structural_back_cut_width() =
    joinery_style == "dado"
        ? inner_width+2*structural_back_dado_depth
        : joinery_style == "tab_slot"
            ? resolved_cabinet_width
            : inner_width;

function structural_back_cut_height() =
    joinery_style == "dado"
        ? captured_back_height+2*structural_back_dado_depth
        : joinery_style == "tab_slot"
            ? captured_back_height+2*material_thickness
            : captured_back_height;

// Applied back sits BEHIND the rear carcass edge. With back_inset = 0 the
// front face of the back starts exactly at resolved_cabinet_depth.
applied_back_y = resolved_cabinet_depth-back_inset;

// The applied back spans the full cabinet width and runs from the underside
// of the raised cabinet bottom to the cabinet top, leaving the toe-kick open.
simple_back_bottom_z = bottom_above_toe;
simple_back_top_z = cabinet_height;
simple_back_height =
    max(0,simple_back_top_z-simple_back_bottom_z);

back_panel_y =
    structural_back_active
        ? structural_back_y
        : applied_back_y;

back_panel_bottom_z =
    structural_back_active
        ? captured_back_bottom_z
        : simple_back_bottom_z;

back_panel_top_z =
    structural_back_active
        ? captured_back_top_z
        : simple_back_top_z;

back_panel_height =
    structural_back_active
        ? captured_back_height
        : simple_back_height;

back_cut_width =
    structural_back_active
        ? structural_back_cut_width()
        : resolved_cabinet_width;

back_cut_height =
    structural_back_active
        ? structural_back_cut_height()
        : simple_back_height;

// Structural back-stretcher placement.
back_stretcher_y =
    resolved_cabinet_depth - material_thickness - back_stretcher_inset;

back_stretcher_region_bottom_z =
    bottom_above_toe + material_thickness;

back_stretcher_region_top_z =
    cabinet_height - material_thickness;

back_stretcher_min_z =
    back_stretcher_region_bottom_z
    + back_stretcher_edge_margin;

back_stretcher_max_z =
    max(
        back_stretcher_min_z,
        back_stretcher_region_top_z
        - back_stretcher_edge_margin
        - back_stretcher_height
    );

function back_stretcher_z(i) =
    back_stretcher_count <= 1
        ? (back_stretcher_min_z+back_stretcher_max_z)/2
        : back_stretcher_min_z
          + (back_stretcher_max_z-back_stretcher_min_z)
            * i/(back_stretcher_count-1);

back_stretcher_layout_height =
    back_style == "stretchers"
        ? back_stretcher_count*back_stretcher_height
          + max(0,back_stretcher_count-1)*layout_gap
        : 0;

// General interior panels sit behind flush/inset decorative fronts and stop
// short of the rear construction.
interior_panel_front_y =
    fronts_inset_flush
        ? inset_front_interior_depth
        : 0;

shelf_front_y = interior_panel_front_y;

shelf_depth =
    max(
        10,
        usable_depth
        - shelf_front_y
        - 10
    );

// Optional separators exist only BETWEEN drawers.
drawer_separator_count =
    !mixed_bay_mode
    && has_drawers
    && include_drawer_separators
    && drawer_bank_layout_mode == "shared"
    && drawer_bank_drawer_count(0) > 1
        ? drawer_bank_drawer_count(0)-1
        : 0;

drawer_separator_front_y = interior_panel_front_y;
drawer_separator_full_depth = shelf_depth;
drawer_separator_stretcher_actual_depth =
    min(drawer_separator_stretcher_depth, drawer_separator_full_depth/2);

joined_w = joined_panel_width();

full_width_bottom_active =
    bottom_width_style == "full_width"
    && bottom_above_toe <= 0.001;

side_panel_bottom_z =
    full_width_bottom_active
        ? material_thickness
        : 0;

side_panel_cut_height =
    max(1,cabinet_height-side_panel_bottom_z);


// ---------------------------
// CABINET GANGING / ALIGNMENT
// ---------------------------

// V28 uses a canonical, envelope-derived side-panel pattern. The pattern is
// deliberately NOT auto-shifted based on a cabinet's internal contents because
// that could make the RIGHT side of one cabinet disagree with the LEFT side of
// its neighbor. Instead, conflicts are detected and reported in structured
// WARN| records so a project/run layer can resolve the pair consistently.

ganging_active =
    ganging_style != "none"
    && ganging_sides != "none";

ganging_connector_active =
    ganging_active
    && (
        ganging_style == "connector_only"
        || ganging_style == "dowel_connector"
    );

ganging_dowel_active =
    ganging_active
    && ganging_style == "dowel_connector";

function ganging_side_active(side="left") =
    ganging_active
    && (
        ganging_sides == "both"
        || ganging_sides == side
    );

effective_ganging_dowel_diameter =
    max(1,ganging_dowel_diameter);

effective_ganging_connector_hole_diameter =
    max(1,ganging_connector_hole_diameter);

effective_ganging_dowel_depth =
    min(
        max(1,ganging_dowel_depth),
        max(1,material_thickness-1)
    );

effective_ganging_pair_vertical_spacing =
    max(
        effective_ganging_dowel_diameter
            + effective_ganging_connector_hole_diameter,
        ganging_pair_vertical_spacing
    );

ganging_pair_half_spacing =
    ganging_dowel_active
        ? effective_ganging_pair_vertical_spacing/2
        : 0;

requested_ganging_station_count =
    ganging_vertical_pattern == "tall"
        ? 3
        : 2;

ganging_grid_pitch = 32;

ganging_station_min_raw =
    max(
        side_panel_bottom_z
            + ganging_vertical_margin
            + ganging_pair_half_spacing,
        front_opening_bottom_z
            + ganging_conflict_clearance
            + ganging_pair_half_spacing
    );

ganging_station_max_raw =
    min(
        cabinet_height
            - ganging_vertical_margin
            - ganging_pair_half_spacing,
        front_opening_top_z
            - ganging_conflict_clearance
            - ganging_pair_half_spacing
    );

ganging_station_min_grid =
    ceil(ganging_station_min_raw/ganging_grid_pitch)
    * ganging_grid_pitch;

ganging_station_max_grid =
    floor(ganging_station_max_raw/ganging_grid_pitch)
    * ganging_grid_pitch;

ganging_station_span =
    max(
        0,
        ganging_station_max_grid-ganging_station_min_grid
    );

effective_ganging_station_count =
    !ganging_active
        ? 0
        : ganging_station_max_grid < ganging_station_min_grid
            ? 1
            : (
                requested_ganging_station_count >= 3
                && ganging_station_span >= 2*ganging_grid_pitch
                    ? 3
                    : ganging_station_span >= ganging_grid_pitch
                        ? 2
                        : 1
              );

function ganging_snap_grid(z) =
    round(z/ganging_grid_pitch)
    * ganging_grid_pitch;

function ganging_station_center_z(i=0) =
    effective_ganging_station_count <= 1
        ? ganging_snap_grid(
            (
                ganging_station_min_raw
                + ganging_station_max_raw
            )/2
          )
        : i <= 0
            ? ganging_station_min_grid
            : i >= effective_ganging_station_count-1
                ? ganging_station_max_grid
                : ganging_snap_grid(
                    ganging_station_min_grid
                    + (
                        ganging_station_span
                        * i
                        /(effective_ganging_station_count-1)
                      )
                  );

function ganging_dowel_z(i=0) =
    ganging_station_center_z(i)
    - ganging_pair_half_spacing;

function ganging_connector_z(i=0) =
    ganging_dowel_active
        ? ganging_station_center_z(i)
          + ganging_pair_half_spacing
        : ganging_station_center_z(i);

ganging_max_hole_diameter =
    max(
        effective_ganging_dowel_diameter,
        effective_ganging_connector_hole_diameter
    );

ganging_depth_edge_min =
    max(
        20,
        ganging_max_hole_diameter/2+6
    );

ganging_front_y =
    min(
        max(
            ganging_depth_edge_min,
            ganging_front_setback
        ),
        max(
            ganging_depth_edge_min,
            resolved_cabinet_depth-ganging_depth_edge_min
        )
    );

ganging_rear_y =
    max(
        ganging_depth_edge_min,
        min(
            resolved_cabinet_depth-ganging_depth_edge_min,
            resolved_cabinet_depth-ganging_rear_setback
        )
    );

ganging_has_rear_column =
    ganging_rear_y
    - ganging_front_y
    >= ganging_max_hole_diameter+20;

effective_ganging_column_count =
    ganging_active
        ? (ganging_has_rear_column ? 2 : 1)
        : 0;

function ganging_column_y(c=0) =
    c <= 0
        ? ganging_front_y
        : ganging_rear_y;

function ganging_column_name(c=0) =
    c <= 0 ? "front" : "rear";


// ----------
// Conflict detection.
//
// These tests cover the common side-panel operations that can make a ganging
// hole impractical: horizontal carcass joints, fixed shelves, shelf-pin holes,
// hinge plates, metal-slide drilling, and wood-slide registration drilling.
// The canonical pattern is preserved even when a conflict is found.

function ganging_near(a,b,clearance=0) =
    abs(a-b)
    <= clearance;

function ganging_point_radius(is_dowel=false) =
    (
        is_dowel
            ? effective_ganging_dowel_diameter
            : effective_ganging_connector_hole_diameter
    )/2
    + ganging_conflict_clearance;

function ganging_structural_z_conflict(z,r) =
    ganging_near(
        z,
        bottom_above_toe,
        r+material_thickness/2
    )
    || ganging_near(
        z,
        bottom_above_toe+material_thickness,
        r+material_thickness/2
    )
    || ganging_near(
        z,
        cabinet_height-material_thickness,
        r+material_thickness/2
    )
    || (
        !mixed_bay_mode
        && cabinet_contents == "combo"
        && (
            ganging_near(
                z,
                combo_divider_bottom_z,
                r+material_thickness/2
            )
            || ganging_near(
                z,
                combo_divider_top_z,
                r+material_thickness/2
            )
        )
    );

function ganging_legacy_fixed_shelf_conflict(z,r) =
    !mixed_bay_mode
    && has_doors
    && shelf_style == "fixed"
    && len([
        for (s=[0:max(0,door_shelf_count-1)])
            if (
                door_shelf_count > 0
                && ganging_near(
                    z,
                    door_shelf_z(s),
                    r+material_thickness/2
                )
            )
                1
    ]) > 0;

function ganging_side_mixed_bay_index(side="left") =
    side == "left"
        ? 0
        : max(0,active_mixed_bay_count-1);

function ganging_mixed_fixed_shelf_conflict(z,r,side="left") =
    mixed_bay_mode
    && (
        let(
            b=ganging_side_mixed_bay_index(side)
        )
        (
            mixed_bay_has_fixed_shelves(b)
            && len([
        for (s=[0:max(0,mixed_bay_shelf_count(b)-1)])
            if (
                mixed_bay_shelf_count(b) > 0
                && ganging_near(
                    z,
                    mixed_bay_shelf_z(b,s),
                    r+material_thickness/2
                )
            )
                1
            ]) > 0
        )
    );

function ganging_legacy_shelf_pin_conflict(y,z,r) =
    !mixed_bay_mode
    && has_doors
    && shelf_style == "adjustable"
    && adjustable_shelf_hole_type != "none"
    && len([
        for (row=[0:1])
            for (i=[0:max(0,shelf_pin_count()-1)])
                if (
                    shelf_pin_count() > 0
                    && ganging_near(
                        y,
                        shelf_pin_y(row),
                        r+adjustable_shelf_hole_diameter/2
                    )
                    && ganging_near(
                        z,
                        shelf_pin_z(i),
                        r+adjustable_shelf_hole_diameter/2
                    )
                )
                    1
    ]) > 0;

function ganging_mixed_shelf_pin_conflict(
    y,z,r,side="left"
) =
    mixed_bay_mode
    && mixed_bay_side_has_shelf_pins(side)
    && len([
        for (row=[0:1])
            for (i=[0:max(0,mixed_bay_shelf_pin_count()-1)])
                if (
                    mixed_bay_shelf_pin_count() > 0
                    && ganging_near(
                        y,
                        shelf_pin_y(row),
                        r+adjustable_shelf_hole_diameter/2
                    )
                    && ganging_near(
                        z,
                        mixed_bay_shelf_pin_z(i),
                        r+adjustable_shelf_hole_diameter/2
                    )
                )
                    1
    ]) > 0;

function ganging_legacy_hinge_conflict(
    y,z,r,side="left"
) =
    cabinet_side_has_door_hinges(side)
    && len([
        for (j=[0:max(0,hinge_count-1)])
            if (hinge_plate_holes_enabled)
            for (dz=[
                -effective_hinge_plate_hole_spacing/2,
                effective_hinge_plate_hole_spacing/2
            ])
                if (
                    hinge_count > 0
                    && ganging_near(
                        y,
                        effective_hinge_plate_center_from_front,
                        r+effective_hinge_plate_hole_diameter/2
                    )
                    && ganging_near(
                        z,
                        hinge_z(j)+dz,
                        r+effective_hinge_plate_hole_diameter/2
                    )
                )
                    1
    ]) > 0;

function ganging_mixed_hinge_conflict(
    y,z,r,side="left"
) =
    mixed_bay_mode
    && mixed_bay_side_has_hinge_plates(side)
    && len([
        for (j=[0:max(0,hinge_count-1)])
            if (hinge_plate_holes_enabled)
            for (dz=[
                -effective_hinge_plate_hole_spacing/2,
                effective_hinge_plate_hole_spacing/2
            ])
                if (
                    hinge_count > 0
                    && ganging_near(
                        y,
                        effective_hinge_plate_center_from_front,
                        r+effective_hinge_plate_hole_diameter/2
                    )
                    && ganging_near(
                        z,
                        mixed_bay_hinge_z(j)+dz,
                        r+effective_hinge_plate_hole_diameter/2
                    )
                )
                    1
    ]) > 0;

function ganging_metal_slide_conflict(
    y,z,r,side="left"
) =
    has_drawers
    && drawer_mount == "metal_slides"
    && include_metal_slide_holes
    && (
        let(b = side == "left" ? 0 : active_drawer_bank_count()-1)
        drawer_bank_drawer_count(b) > 0
        && len([
            for (i=[0:drawer_bank_drawer_count(b)-1])
                for (hx=active_slide_cabinet_holes())
                    if (
                        cabinet_slide_hole_is_valid(hx,resolved_cabinet_depth)
                        && ganging_near(
                            y,
                            slide_cabinet_hole_depth(hx),
                            r+effective_metal_slide_cabinet_hole_diameter/2
                        )
                        && ganging_near(
                            z,
                            drawer_box_z(i,b)+effective_metal_slide_cabinet_hole_z,
                            r+effective_metal_slide_cabinet_hole_diameter/2
                        )
                    )
                        1
        ]) > 0
    );

function ganging_wood_slide_conflict(
    y,z,r,side="left"
) =
    has_drawers
    && drawer_mount == "wood_rails"
    && include_wood_slide_registration_holes
    && (
        let(
            b = side == "left"
                ? 0
                : active_drawer_bank_count()-1
        )
        (
            drawer_bank_drawer_count(b) > 0
            && len([
        for (i=[0:drawer_bank_drawer_count(b)-1])
            for (n=[0:max(0,wood_slide_registration_hole_count-1)])
                if (
                    wood_slide_registration_hole_count > 0
                    && ganging_near(
                        y,
                        effective_wood_rail_front_setback
                        + wood_slide_reg_pos(resolved_wood_rail_depth,n),
                        r+wood_slide_registration_hole_diameter/2
                    )
                    && ganging_near(
                        z,
                        drawer_rail_z(i,b)+wood_rail_height/2,
                        r+wood_slide_registration_hole_diameter/2
                    )
                )
                    1
            ]) > 0
        )
    );

function ganging_point_conflicts(
    y,z,side="left",is_dowel=false
) =
    let(r=ganging_point_radius(is_dowel))
    ganging_structural_z_conflict(z,r)
    || ganging_legacy_fixed_shelf_conflict(z,r)
    || ganging_mixed_fixed_shelf_conflict(z,r,side)
    || ganging_legacy_shelf_pin_conflict(y,z,r)
    || ganging_mixed_shelf_pin_conflict(y,z,r,side)
    || ganging_legacy_hinge_conflict(y,z,r,side)
    || ganging_mixed_hinge_conflict(y,z,r,side)
    || ganging_metal_slide_conflict(y,z,r,side)
    || ganging_wood_slide_conflict(y,z,r,side);


// ---------------------------
// MODULAR ORGANIZATION INTERFACE / FEATURE / KEEPOUT CONTRACT (FORK V3)
// ---------------------------
//
// Modular Organization v3 is a fork of Modular Storage v35.  Geometry remains
// authoritative in OpenSCAD, but physical relationships are now exposed as
// explicit records.  This gives the web/project layer a stable model:
//
//   project -> assemblies -> parts -> interfaces -> features / keepouts
//
// The initial contract intentionally covers the relationships that already
// have strong geometry semantics in the parent engine: carcass joints,
// stackable top/bottom mating geometry, side-ganging points, and drawer-box
// joinery.  More module families can attach to the same record types later.

organization_engine_family = "modular_organization";
organization_engine_version = 3;
organization_parent_engine = "modular_storage_v35";
organization_interface_contract = "MOI-3";

function organization_system_report_enabled() =
    is_undef(system_contract_report) ? true : system_contract_report != "off";

function organization_system_report_verbose() =
    !is_undef(system_contract_report) && system_contract_report == "verbose";

function organization_keepout_policy() =
    is_undef(interface_keepout_policy) ? "enforce" : interface_keepout_policy;

function organization_keepout_validation_enabled() =
    organization_keepout_policy() != "off";

function organization_keepout_conflict_severity() =
    organization_keepout_policy() == "enforce" ? "ERROR" : "WARN";

// Interface record fields.
MO_IF_ID       = 0;
MO_IF_STANDARD = 1;
MO_IF_KIND     = 2;
MO_IF_ROLE     = 3;
MO_IF_OWNER    = 4;
MO_IF_FACE     = 5;
MO_IF_MATE     = 6;
MO_IF_DATUM    = 7;
MO_IF_KEY      = 8;
MO_IF_TAGS     = 9;

function mo_interface(
    id,standard,kind,role,owner,face,mate,datum,key,tags=""
) = [id,standard,kind,role,owner,face,mate,datum,key,tags];

function mo_interface_id(r) = r[MO_IF_ID];
function mo_interface_standard(r) = r[MO_IF_STANDARD];
function mo_interface_kind(r) = r[MO_IF_KIND];
function mo_interface_role(r) = r[MO_IF_ROLE];
function mo_interface_owner(r) = r[MO_IF_OWNER];
function mo_interface_face(r) = r[MO_IF_FACE];
function mo_interface_mate(r) = r[MO_IF_MATE];
function mo_interface_datum(r) = r[MO_IF_DATUM];
function mo_interface_key(r) = r[MO_IF_KEY];
function mo_interface_tags(r) = r[MO_IF_TAGS];

// Keepouts are global cabinet-coordinate AABBs.  They are deliberately simple
// and conservative: a keepout is a region reserved by an interface, not a tool
// path.  Future module families can add cylinders/polygons while retaining the
// same owner/scope semantics.
MO_KO_ID     = 0;
MO_KO_OWNER  = 1;
MO_KO_SCOPE  = 2;
MO_KO_X0     = 3;
MO_KO_X1     = 4;
MO_KO_Y0     = 5;
MO_KO_Y1     = 6;
MO_KO_Z0     = 7;
MO_KO_Z1     = 8;
MO_KO_REASON = 9;

function mo_keepout(id,owner,scope,x0,x1,y0,y1,z0,z1,reason) =
    [id,owner,scope,x0,x1,y0,y1,z0,z1,reason];

function mo_keepout_id(r) = r[MO_KO_ID];
function mo_keepout_owner(r) = r[MO_KO_OWNER];

// Features use global cabinet-coordinate AABBs plus an optional 2D shape
// description on the owning part face.  The shape data lets the validator use
// exact circle/rectangle tests instead of treating every drilled hole as a
// rectangular box.  The AABB remains the stable interchange representation.
MO_F_ID        = 0;
MO_F_PART      = 1;
MO_F_KIND      = 2;
MO_F_INTERFACE = 3;
MO_F_X0        = 4;
MO_F_X1        = 5;
MO_F_Y0        = 6;
MO_F_Y1        = 7;
MO_F_Z0        = 8;
MO_F_Z1        = 9;
MO_F_SHAPE     = 10;
MO_F_CY        = 11;
MO_F_CZ        = 12;
MO_F_RADIUS    = 13;
MO_F_OPERATION = 14;
MO_F_SOURCE    = 15;

function mo_feature(
    id,part,kind,interface_id,x0,x1,y0,y1,z0,z1,
    shape="rect",cy=undef,cz=undef,radius=0,
    operation="cut",source="geometry"
) = [
    id,part,kind,interface_id,x0,x1,y0,y1,z0,z1,
    shape,cy,cz,radius,operation,source
];

function mo_feature_id(r) = r[MO_F_ID];
function mo_feature_interface(r) = r[MO_F_INTERFACE];
function mo_feature_part(r) = r[MO_F_PART];
function mo_feature_shape(r) = r[MO_F_SHAPE];

function mo_ranges_overlap(a0,a1,b0,b1,clearance=0) =
    max(a0,b0) <= min(a1,b1)+clearance;

// Positive overlap is used for feature/feature checks so merely touching at a
// shared nominal edge does not become a false collision.
function mo_ranges_overlap_positive(a0,a1,b0,b1,clearance=0,eps=0.0001) =
    max(a0,b0) < min(a1,b1)+clearance-eps;

function mo_circle_rect_hits(cy,cz,r,y0,y1,z0,z1,clearance=0) =
    let(
        qy=min(max(cy,y0),y1),
        qz=min(max(cz,z0),z1),
        dy=cy-qy,
        dz=cz-qz
    )
    dy*dy+dz*dz <= (r+clearance)*(r+clearance);

function mo_feature_hits_keepout(f,k,clearance=0) =
    mo_ranges_overlap(f[MO_F_X0],f[MO_F_X1],k[MO_KO_X0],k[MO_KO_X1],clearance)
    && (
        mo_feature_shape(f) == "circle"
            ? mo_circle_rect_hits(
                f[MO_F_CY],f[MO_F_CZ],f[MO_F_RADIUS],
                k[MO_KO_Y0],k[MO_KO_Y1],k[MO_KO_Z0],k[MO_KO_Z1],
                clearance
              )
            : mo_ranges_overlap(
                f[MO_F_Y0],f[MO_F_Y1],k[MO_KO_Y0],k[MO_KO_Y1],clearance
              )
              && mo_ranges_overlap(
                f[MO_F_Z0],f[MO_F_Z1],k[MO_KO_Z0],k[MO_KO_Z1],clearance
              )
    );

function mo_feature_pair_hits(a,b,clearance=0) =
    mo_feature_part(a) == mo_feature_part(b)
    && mo_ranges_overlap_positive(a[MO_F_X0],a[MO_F_X1],b[MO_F_X0],b[MO_F_X1],clearance)
    && (
        mo_feature_shape(a) == "circle" && mo_feature_shape(b) == "circle"
            ? let(
                dy=a[MO_F_CY]-b[MO_F_CY],
                dz=a[MO_F_CZ]-b[MO_F_CZ],
                rr=a[MO_F_RADIUS]+b[MO_F_RADIUS]+clearance
              ) dy*dy+dz*dz < rr*rr
        : mo_feature_shape(a) == "circle"
            ? mo_circle_rect_hits(
                a[MO_F_CY],a[MO_F_CZ],a[MO_F_RADIUS],
                b[MO_F_Y0],b[MO_F_Y1],b[MO_F_Z0],b[MO_F_Z1],clearance
              )
        : mo_feature_shape(b) == "circle"
            ? mo_circle_rect_hits(
                b[MO_F_CY],b[MO_F_CZ],b[MO_F_RADIUS],
                a[MO_F_Y0],a[MO_F_Y1],a[MO_F_Z0],a[MO_F_Z1],clearance
              )
        : mo_ranges_overlap_positive(a[MO_F_Y0],a[MO_F_Y1],b[MO_F_Y0],b[MO_F_Y1],clearance)
          && mo_ranges_overlap_positive(a[MO_F_Z0],a[MO_F_Z1],b[MO_F_Z0],b[MO_F_Z1],clearance)
    );

function mo_joint_span(location="default") =
    location == "bottom" ? resolved_cabinet_depth
    : location == "top" ? (top_style == "full" ? resolved_cabinet_depth : top_stretcher_depth)
    : location == "shelf" ? shelf_depth
    : location == "separator" ? drawer_separator_full_depth
    : resolved_cabinet_depth;

function mo_joint_compatibility_key(location="default") =
    let(span=mo_joint_span(location))
    joinery_style == "tab_slot"
        ? str(
            "STYLE=tab_slot;T=",material_thickness,
            ";FIT=",joint_fit_clearance,
            ";SPAN=",span,
            ";COUNT=",tab_count_for_location(span,location),
            ";CENTERS=",[
                for (i=[0:tab_count_for_location(span,location)-1])
                    tab_center_for_location(span,i,location)
            ]
          )
    : joinery_style == "dado"
        ? str(
            "STYLE=dado;T=",material_thickness,
            ";DEPTH=",effective_dado_depth(),
            ";FIT=",dado_fit_clearance,
            ";SPAN=",span
          )
    : str("STYLE=butt;T=",material_thickness,";SPAN=",span);

function mo_stack_compatibility_key() =
    str(
        "KSV=2",
        ";W=",resolved_cabinet_width,
        ";D=",resolved_cabinet_depth,
        ";T=",material_thickness,
        ";ID=",effective_stack_interface_depth,
        ";F=",effective_stack_front_margin,
        ";B=",effective_stack_back_margin,
        ";R=",effective_stack_interface_corner_radius,
        ";C=",effective_stack_interface_clearance
    );

// MOI-GANG-1 v2 signs every geometry-driving value, including hole diameters
// and blind depth.  V2 intentionally signed only placement coordinates, which
// meant physically different dowel patterns could compare equal.
function mo_ganging_compatibility_key() =
    str(
        "KSV=2",
        ";H=",cabinet_height,
        ";D=",resolved_cabinet_depth,
        ";T=",material_thickness,
        ";STYLE=",ganging_style,
        ";DOWEL_D=",ganging_dowel_active ? effective_ganging_dowel_diameter : 0,
        ";DOWEL_DEPTH=",ganging_dowel_active ? effective_ganging_dowel_depth : 0,
        ";CONNECTOR_D=",ganging_connector_active ? effective_ganging_connector_hole_diameter : 0,
        ";PAIR_SPACING=",effective_ganging_pair_vertical_spacing,
        ";COL_COUNT=",effective_ganging_column_count,
        ";STATION_COUNT=",effective_ganging_station_count,
        ";Y=",[
            for (c=[0:max(0,effective_ganging_column_count-1)])
                if (effective_ganging_column_count > 0) ganging_column_y(c)
        ],
        ";DOWEL_Z=",[
            for (s=[0:max(0,effective_ganging_station_count-1)])
                if (effective_ganging_station_count > 0 && ganging_dowel_active)
                    ganging_dowel_z(s)
        ],
        ";CONNECTOR_Z=",[
            for (s=[0:max(0,effective_ganging_station_count-1)])
                if (effective_ganging_station_count > 0 && ganging_connector_active)
                    ganging_connector_z(s)
        ]
    );

function mo_drawer_joinery_compatibility_key() =
    str(
        "KSV=2",
        ";STYLE=",drawer_joinery_style,
        ";SIDE_T=",drawer_material_thickness,
        ";FB_T=",drawer_material_thickness,
        ";JOINT_FIT=",drawer_joint_fit_clearance,
        ";DADO_FIT=",drawer_dado_fit_clearance,
        ";DADO_DEPTH=",drawer_joinery_style == "dado" ? effective_drawer_dado_depth() : 0,
        ";BOTTOM_STYLE=",drawer_bottom_joinery,
        ";BOTTOM_T=",drawer_bottom_thickness,
        ";BOTTOM_DADO_DEPTH=",drawer_bottom_joinery == "dado" ? effective_drawer_bottom_dado_depth() : 0,
        ";BOTTOM_INSET=",drawer_bottom_inset
    );

function mo_has_fixed_shelf_interface() =
    (
        !mixed_bay_mode
        && has_doors
        && shelf_style == "fixed"
        && door_shelf_count > 0
    )
    || (
        mixed_bay_mode
        && len([
            for (b=[0:max(0,active_mixed_bay_count-1)])
                if (
                    active_mixed_bay_count > 0
                    && mixed_bay_has_fixed_shelves(b)
                    && mixed_bay_shelf_count(b) > 0
                ) 1
        ]) > 0
    );

function organization_internal_interfaces() =
    concat(
        standalone_drawer_active ? [] : [
            mo_interface(
                "carcass.bottom","MOI-JOINT-1","part_joint","paired",
                "BOTTOM","left/right edges","carcass.side.receiver",
                "front-left-bottom",mo_joint_compatibility_key("bottom"),
                "internal;structural"
            ),
            mo_interface(
                "carcass.top","MOI-JOINT-1","part_joint","paired",
                top_style == "full" ? "TOP" : "TOP-F/TOP-R",
                "left/right edges","carcass.side.receiver",
                "front-left-top",mo_joint_compatibility_key("top"),
                "internal;structural"
            )
        ],
        (!standalone_drawer_active && mo_has_fixed_shelf_interface()) ? [
            mo_interface(
                "carcass.shelf","MOI-JOINT-1","part_joint","paired",
                "SHELF","left/right edges","side-or-partition.receiver",
                "local-front",mo_joint_compatibility_key("shelf"),
                "internal;repeatable"
            )
        ] : [],
        (!standalone_drawer_active && drawer_separator_count > 0) ? [
            mo_interface(
                "carcass.separator","MOI-JOINT-1","part_joint","paired",
                "DRAWER-SEPARATOR","left/right edges","side-or-partition.receiver",
                "local-front",mo_joint_compatibility_key("separator"),
                "internal;repeatable"
            )
        ] : [],
        (has_drawers || standalone_drawer_active) ? [
            mo_interface(
                "drawer.corner","MOI-DRAWER-1","part_joint","paired",
                "DRAWER-BOX","corner edges","drawer.corner.receiver",
                "drawer-front-left-bottom",mo_drawer_joinery_compatibility_key(),
                "internal;drawer"
            )
        ] : []
    );

function organization_external_interfaces() =
    concat(
        stackable_mode ? [
            mo_interface(
                "stack.bottom","MOI-STACK-1","stack","male",
                "CARCASS-SIDES","bottom","MOI-STACK-1:female",
                "cabinet-front-bottom",mo_stack_compatibility_key(),
                "external;vertical;load-bearing"
            ),
            mo_interface(
                "stack.top","MOI-STACK-1","stack","female",
                "CARCASS-SIDES","top","MOI-STACK-1:male",
                "cabinet-front-top",mo_stack_compatibility_key(),
                "external;vertical;load-bearing"
            )
        ] : [],
        ganging_side_active("left") ? [
            mo_interface(
                "side_gang.left","MOI-GANG-1","side_gang","peer",
                "CS-L","outer-left","MOI-GANG-1:peer",
                "cabinet-front-bottom",mo_ganging_compatibility_key(),
                "external;horizontal;alignment"
            )
        ] : [],
        ganging_side_active("right") ? [
            mo_interface(
                "side_gang.right","MOI-GANG-1","side_gang","peer",
                "CS-R","outer-right","MOI-GANG-1:peer",
                "cabinet-front-bottom",mo_ganging_compatibility_key(),
                "external;horizontal;alignment"
            )
        ] : []
    );

function organization_interfaces() =
    concat(organization_external_interfaces(),organization_internal_interfaces());

// V3 project-composition frame records. Frames are deliberately expressed in
// the module-local coordinate system. U/V are in-plane reference axes and N is
// the outward face normal. The project resolver currently supports rigid
// translation plus user-specified orthogonal Z rotation; the frame contract is
// general enough to add automatic arbitrary rotations later without changing
// the record format.
MO_FR_ID = 0;
MO_FR_OX = 1; MO_FR_OY = 2; MO_FR_OZ = 3;
MO_FR_UX = 4; MO_FR_UY = 5; MO_FR_UZ = 6;
MO_FR_VX = 7; MO_FR_VY = 8; MO_FR_VZ = 9;
MO_FR_NX = 10; MO_FR_NY = 11; MO_FR_NZ = 12;

function mo_interface_frame(id,origin,u,v,n) = [
    id,
    origin[0],origin[1],origin[2],
    u[0],u[1],u[2],
    v[0],v[1],v[2],
    n[0],n[1],n[2]
];

function organization_module_kind() = standalone_drawer_active ? "drawer" : "cabinet";
function organization_module_width() = standalone_drawer_active ? drawer_outer_width(0) : resolved_cabinet_width;
function organization_module_depth() = standalone_drawer_active ? drawer_box_depth : cabinet_finished_depth;
function organization_module_height() = standalone_drawer_active ? drawer_box_height(0,0) : cabinet_height;

function organization_interface_frames() = concat(
    stackable_mode ? [
        mo_interface_frame("stack.bottom",[0,0,0],[1,0,0],[0,1,0],[0,0,-1]),
        mo_interface_frame("stack.top",[0,0,cabinet_height],[1,0,0],[0,1,0],[0,0,1])
    ] : [],
    ganging_side_active("left") ? [
        mo_interface_frame("side_gang.left",[0,0,0],[0,1,0],[0,0,1],[-1,0,0])
    ] : [],
    ganging_side_active("right") ? [
        mo_interface_frame("side_gang.right",[resolved_cabinet_width,0,0],[0,1,0],[0,0,1],[1,0,0])
    ] : []
);

// The stack profile's two radiused transitions are reserved volumes.  The
// front transition runs from margin -> margin+2R; the rear is its depth-axis
// mirror.  A small guard accounts for fit clearance and CNC corner relief.
function mo_stack_keepout_guard() =
    max(1,stack_safe_bottom_tab_edge_web());

function mo_stack_front_transition_range() = [
    max(0,effective_stack_front_margin-mo_stack_keepout_guard()),
    min(
        resolved_cabinet_depth,
        effective_stack_front_margin
        + 2*effective_stack_interface_corner_radius
        + mo_stack_keepout_guard()
    )
];

function mo_stack_rear_transition_range() = [
    max(
        0,
        resolved_cabinet_depth
        - effective_stack_back_margin
        - 2*effective_stack_interface_corner_radius
        - mo_stack_keepout_guard()
    ),
    min(
        resolved_cabinet_depth,
        resolved_cabinet_depth-effective_stack_back_margin
        + mo_stack_keepout_guard()
    )
];

function mo_stack_interface_keepouts() =
    !stackable_mode ? [] :
    let(
        fr=mo_stack_front_transition_range(),
        rr=mo_stack_rear_transition_range(),
        z0=max(0,effective_stack_interface_depth-material_thickness),
        z1=min(cabinet_height,effective_stack_interface_depth+material_thickness)
    )
    [
        mo_keepout(
            "stack.left.front_transition","stack.bottom","side_panel",
            0,material_thickness,fr[0],fr[1],z0,z1,
            "Reserved for the front radiused stacking shoulder"
        ),
        mo_keepout(
            "stack.left.rear_transition","stack.bottom","side_panel",
            0,material_thickness,rr[0],rr[1],z0,z1,
            "Reserved for the rear radiused stacking shoulder"
        ),
        mo_keepout(
            "stack.right.front_transition","stack.bottom","side_panel",
            resolved_cabinet_width-material_thickness,resolved_cabinet_width,
            fr[0],fr[1],z0,z1,
            "Reserved for the front radiused stacking shoulder"
        ),
        mo_keepout(
            "stack.right.rear_transition","stack.bottom","side_panel",
            resolved_cabinet_width-material_thickness,resolved_cabinet_width,
            rr[0],rr[1],z0,z1,
            "Reserved for the rear radiused stacking shoulder"
        )
    ];

function mo_ganging_point_keepout(
    side="left",c=0,s=0,is_dowel=false
) =
    let(
        r=ganging_point_radius(is_dowel),
        y=ganging_column_y(c),
        z=is_dowel ? ganging_dowel_z(s) : ganging_connector_z(s),
        x0=is_dowel
            ? (side == "left" ? 0 : resolved_cabinet_width-effective_ganging_dowel_depth)
            : (side == "left" ? 0 : resolved_cabinet_width-material_thickness),
        x1=is_dowel
            ? (side == "left" ? effective_ganging_dowel_depth : resolved_cabinet_width)
            : (side == "left" ? material_thickness : resolved_cabinet_width),
        kind=is_dowel ? "dowel" : "connector"
    )
    mo_keepout(
        str("ganging.",side,".",ganging_column_name(c),".",s+1,".",kind),
        str("side_gang.",side),"side_panel",
        x0,x1,y-r,y+r,z-r,z+r,
        str("Reserved by canonical side-ganging ",kind," point")
    );

function mo_ganging_keepouts(side="left") =
    !ganging_side_active(side) ? [] :
    concat(
        ganging_connector_active ? [
            for (c=[0:max(0,effective_ganging_column_count-1)])
                for (s=[0:max(0,effective_ganging_station_count-1)])
                    if (effective_ganging_column_count > 0
                        && effective_ganging_station_count > 0)
                        mo_ganging_point_keepout(side,c,s,false)
        ] : [],
        ganging_dowel_active ? [
            for (c=[0:max(0,effective_ganging_column_count-1)])
                for (s=[0:max(0,effective_ganging_station_count-1)])
                    if (effective_ganging_column_count > 0
                        && effective_ganging_station_count > 0)
                        mo_ganging_point_keepout(side,c,s,true)
        ] : []
    );

function organization_keepouts() =
    concat(
        mo_stack_interface_keepouts(),
        mo_ganging_keepouts("left"),
        mo_ganging_keepouts("right")
    );

// ---------- Exhaustive cabinet-side manufacturing feature ledger ----------
//
// Every generated hole, blind pocket, or carcass joint that can exist on the
// two OUTER cabinet side panels is represented here.  This is the collision
// domain used by the external stack/ganging interfaces, so a clean interface
// report no longer depends on a hand-picked subset of side operations.

function mo_side_part(side="left") = side == "left" ? "CS-L" : "CS-R";

function mo_side_x_range(side="left",mode="through",depth=0) =
    mode == "blind_inner"
        ? (side == "left"
            ? [material_thickness-depth,material_thickness]
            : [resolved_cabinet_width-material_thickness,
               resolved_cabinet_width-material_thickness+depth])
    : mode == "blind_outer"
        ? (side == "left"
            ? [0,depth]
            : [resolved_cabinet_width-depth,resolved_cabinet_width])
    : (side == "left"
        ? [0,material_thickness]
        : [resolved_cabinet_width-material_thickness,resolved_cabinet_width]);

function mo_side_rect_feature(
    id,side,kind,owner,y0,y1,z0,z1,
    depth_mode="through",depth=0,operation="cut_layout",source="side_panel"
) =
    let(xr=mo_side_x_range(side,depth_mode,depth))
    mo_feature(
        id,mo_side_part(side),kind,owner,
        xr[0],xr[1],y0,y1,z0,z1,
        "rect",undef,undef,0,operation,source
    );

function mo_side_circle_feature(
    id,side,kind,owner,y,z,d,
    depth_mode="through",depth=0,operation="cut_layout",source="side_panel"
) =
    let(
        xr=mo_side_x_range(side,depth_mode,depth),
        r=d/2
    )
    mo_feature(
        id,mo_side_part(side),kind,owner,
        xr[0],xr[1],y-r,y+r,z-r,z+r,
        "circle",y,z,r,operation,source
    );

function mo_side_horizontal_features(
    side="left",y0=0,panel_depth=100,z0=0,
    location="default",prefix="joint",owner="carcass.joint"
) =
    joinery_style == "dado"
        ? let(c=dado_fit_clearance,dd=effective_dado_depth()) [
            mo_side_rect_feature(
                str(prefix,".dado"),side,"dado_pocket",owner,
                y0-c/2,y0+panel_depth+c/2,
                z0-c/2,z0+material_thickness+c/2,
                "blind_inner",dd,"pocket_carcass_dados","side_horizontal_joint"
            )
          ]
    : joinery_style == "tab_slot"
        ? let(c=joint_fit_clearance,n=tab_count_for_location(panel_depth,location)) [
            for (i=[0:max(0,n-1)]) if (n>0)
                let(
                    sy=y0+tab_start_for_location(panel_depth,i,location)-c/2,
                    sw=tab_width_for(panel_depth)+c
                )
                mo_side_rect_feature(
                    str(prefix,".slot.",i+1),side,"through_slot",owner,
                    sy,sy+sw,z0-c/2,z0+material_thickness+c/2,
                    "through",0,"cut_layout","side_horizontal_joint"
                )
          ]
    : include_butt_registration_holes
        ? let(n=butt_reg_count(panel_depth)) [
            for (i=[0:max(0,n-1)]) if (n>0)
                mo_side_circle_feature(
                    str(prefix,".registration.",i+1),side,
                    "registration_hole",owner,
                    y0+butt_reg_pos(panel_depth,i),
                    z0+material_thickness/2,
                    butt_registration_hole_diameter,
                    "through",0,"cut_layout","side_horizontal_butt_registration"
                )
          ]
        : [];

function mo_side_toe_features(side="left") =
    !has_toe_kick ? [] :
    joinery_style == "dado"
        ? let(c=dado_fit_clearance,dd=effective_dado_depth()) [
            mo_side_rect_feature(
                str("toe.",side,".dado"),side,"dado_pocket","carcass.toe",
                toe_kick_setback-c/2,toe_kick_setback+material_thickness+c/2,
                -c/2,toe_kick_height+c/2,
                "blind_inner",dd,"pocket_carcass_dados","side_toe_joint"
            )
          ]
    : joinery_style == "tab_slot"
        ? let(c=joint_fit_clearance,n=effective_tab_count(toe_kick_height)) [
            for (i=[0:max(0,n-1)]) if(n>0)
                let(
                    zz=tab_start(toe_kick_height,i)-c/2,
                    zh=tab_width_for(toe_kick_height)+c
                )
                mo_side_rect_feature(
                    str("toe.",side,".slot.",i+1),side,"through_slot","carcass.toe",
                    toe_kick_setback-c/2,toe_kick_setback+material_thickness+c/2,
                    zz,zz+zh,"through",0,"cut_layout","side_toe_joint"
                )
          ]
    : include_butt_registration_holes
        ? let(n=butt_reg_count(toe_kick_height)) [
            for(i=[0:max(0,n-1)]) if(n>0)
                mo_side_circle_feature(
                    str("toe.",side,".registration.",i+1),side,
                    "registration_hole","carcass.toe",
                    toe_kick_setback+material_thickness/2,
                    butt_reg_pos(toe_kick_height,i),
                    butt_registration_hole_diameter,
                    "through",0,"cut_layout","side_toe_butt_registration"
                )
          ]
        : [];

function mo_side_back_stretcher_features(side="left") =
    back_style != "stretchers" ? [] : [
        for (b=[0:max(0,back_stretcher_count-1)]) if(back_stretcher_count>0)
            each (
                joinery_style == "dado"
                    ? let(c=dado_fit_clearance,dd=effective_dado_depth()) [
                        mo_side_rect_feature(
                            str("back_stretcher.",side,".",b+1,".dado"),
                            side,"dado_pocket","carcass.back_stretcher",
                            back_stretcher_y-c/2,
                            back_stretcher_y+material_thickness+c/2,
                            back_stretcher_z(b)-c/2,
                            back_stretcher_z(b)+back_stretcher_height+c/2,
                            "blind_inner",dd,"pocket_carcass_dados",
                            "side_back_stretcher_joint"
                        )
                      ]
                : joinery_style == "tab_slot"
                    ? let(c=joint_fit_clearance,n=effective_tab_count(back_stretcher_height)) [
                        for(i=[0:max(0,n-1)]) if(n>0)
                            let(
                                zz=back_stretcher_z(b)+tab_start(back_stretcher_height,i)-c/2,
                                zh=tab_width_for(back_stretcher_height)+c
                            )
                            mo_side_rect_feature(
                                str("back_stretcher.",side,".",b+1,".slot.",i+1),
                                side,"through_slot","carcass.back_stretcher",
                                back_stretcher_y-c/2,
                                back_stretcher_y+material_thickness+c/2,
                                zz,zz+zh,"through",0,"cut_layout",
                                "side_back_stretcher_joint"
                            )
                      ]
                : include_butt_registration_holes
                    ? let(n=butt_reg_count(back_stretcher_height)) [
                        for(i=[0:max(0,n-1)]) if(n>0)
                            mo_side_circle_feature(
                                str("back_stretcher.",side,".",b+1,".registration.",i+1),
                                side,"registration_hole","carcass.back_stretcher",
                                back_stretcher_y+material_thickness/2,
                                back_stretcher_z(b)+butt_reg_pos(back_stretcher_height,i),
                                butt_registration_hole_diameter,
                                "through",0,"cut_layout","side_back_stretcher_butt_registration"
                            )
                      ]
                    : []
            )
    ];

function mo_side_structural_back_features(side="left") =
    !structural_back_active ? [] :
    joinery_style == "dado"
        ? let(c=dado_fit_clearance,dd=structural_back_dado_depth) [
            mo_side_rect_feature(
                str("structural_back.",side,".dado"),side,
                "dado_pocket","carcass.back",
                structural_back_y-c/2,structural_back_y+material_thickness+c/2,
                captured_back_bottom_z-c/2,
                captured_back_bottom_z+captured_back_height+c/2,
                "blind_inner",dd,"pocket_carcass_dados","side_back_joint"
            )
          ]
    : joinery_style == "tab_slot"
        ? let(c=joint_fit_clearance,n=effective_tab_count(captured_back_height)) [
            for(i=[0:max(0,n-1)]) if(n>0)
                let(
                    zz=captured_back_bottom_z+tab_start(captured_back_height,i)-c/2,
                    zh=tab_width_for(captured_back_height)+c
                )
                mo_side_rect_feature(
                    str("structural_back.",side,".slot.",i+1),side,
                    "through_slot","carcass.back",
                    structural_back_y-c/2,structural_back_y+material_thickness+c/2,
                    zz,zz+zh,"through",0,"cut_layout","side_back_joint"
                )
          ]
    : include_butt_registration_holes
        ? let(n=butt_reg_count(captured_back_height)) [
            for(i=[0:max(0,n-1)]) if(n>0)
                mo_side_circle_feature(
                    str("structural_back.",side,".registration.",i+1),side,
                    "registration_hole","carcass.back",
                    structural_back_y+material_thickness/2,
                    captured_back_bottom_z+butt_reg_pos(captured_back_height,i),
                    butt_registration_hole_diameter,
                    "through",0,"cut_layout","side_back_joint"
                )
          ]
        : [];

function mo_side_carcass_joint_features(side="left") =
    concat(
        (!full_width_bottom_active)
            ? mo_side_horizontal_features(
                side,0,resolved_cabinet_depth,bottom_above_toe,"bottom",
                str("bottom.",side),"carcass.bottom")
            : [],
        top_style == "full"
            ? mo_side_horizontal_features(
                side,0,resolved_cabinet_depth,cabinet_height-material_thickness,
                "top",str("top.",side),"carcass.top")
            : concat(
                mo_side_horizontal_features(
                    side,0,top_stretcher_depth,cabinet_height-material_thickness,
                    "top",str("top_front.",side),"carcass.top"),
                mo_side_horizontal_features(
                    side,resolved_cabinet_depth-top_stretcher_depth,
                    top_stretcher_depth,cabinet_height-material_thickness,
                    "top",str("top_rear.",side),"carcass.top")
              ),
        (!mixed_bay_mode && cabinet_contents == "combo" && door_region_height > material_thickness)
            ? mo_side_horizontal_features(
                side,shelf_front_y,shelf_depth,combo_divider_bottom_z,"shelf",
                str("combo_divider.",side),"carcass.shelf")
            : [],
        (!mixed_bay_mode && has_doors && shelf_style == "fixed"
            && door_shelf_count > 0 && door_region_height > 60)
            ? [for(s=[1:door_shelf_count]) each
                mo_side_horizontal_features(
                    side,shelf_front_y,shelf_depth,door_shelf_z(s),"shelf",
                    str("fixed_shelf.",side,".",s),"carcass.shelf")]
            : [],
        (drawer_separator_count > 0)
            ? [for(s=[0:drawer_separator_count-1]) each
                let(sep_z=drawer_separator_z(s))
                (drawer_separator_style == "full"
                    ? mo_side_horizontal_features(
                        side,drawer_separator_front_y,drawer_separator_full_depth,
                        sep_z,"separator",str("separator.",side,".",s+1),
                        "carcass.separator")
                    : concat(
                        mo_side_horizontal_features(
                            side,drawer_separator_front_y,
                            drawer_separator_stretcher_actual_depth,sep_z,
                            "separator",str("separator_front.",side,".",s+1),
                            "carcass.separator"),
                        mo_side_horizontal_features(
                            side,
                            drawer_separator_front_y+drawer_separator_full_depth
                                -drawer_separator_stretcher_actual_depth,
                            drawer_separator_stretcher_actual_depth,sep_z,
                            "separator",str("separator_rear.",side,".",s+1),
                            "carcass.separator")
                      ))]
            : [],
        (mixed_bay_mode && mixed_bay_side_has_fixed_shelves(side))
            ? let(bb=mixed_bay_side_fixed_bay(side)) [
                for(s=[1:mixed_bay_shelf_count(bb)]) each
                    mo_side_horizontal_features(
                        side,shelf_front_y,shelf_depth,mixed_bay_shelf_z(bb,s),
                        "shelf",str("mixed_fixed_shelf.",side,".",s),
                        "carcass.shelf")
              ]
            : [],
        mo_side_toe_features(side),
        mo_side_back_stretcher_features(side),
        mo_side_structural_back_features(side)
    );

function mo_side_shelf_pin_features(side="left") =
    let(
        blind=adjustable_shelf_hole_type == "blind",
        dd=blind ? min(adjustable_shelf_hole_depth,material_thickness-0.5) : 0,
        dm=blind ? "blind_inner" : "through",
        op=blind ? "pocket_shelf_pins" : "cut_layout"
    )
    concat(
        (!mixed_bay_mode && has_doors && shelf_style == "adjustable")
            ? [for(row=[0:1]) for(i=[0:max(0,shelf_pin_count()-1)])
                if(shelf_pin_count()>0)
                mo_side_circle_feature(
                    str("shelf_pin.",side,".",row,".",i+1),side,
                    blind ? "blind_hole" : "through_hole","storage.shelf_grid",
                    shelf_pin_y(row),shelf_pin_z(i),adjustable_shelf_hole_diameter,
                    dm,dd,op,"adjustable_shelf_pin")]
            : [],
        (mixed_bay_mode && mixed_bay_side_has_shelf_pins(side))
            ? [for(row=[0:1]) for(i=[0:max(0,mixed_bay_shelf_pin_count()-1)])
                if(mixed_bay_shelf_pin_count()>0)
                mo_side_circle_feature(
                    str("mixed_shelf_pin.",side,".",row,".",i+1),side,
                    blind ? "blind_hole" : "through_hole","storage.shelf_grid",
                    shelf_pin_y(row),mixed_bay_shelf_pin_z(i),
                    adjustable_shelf_hole_diameter,dm,dd,op,"mixed_shelf_pin")]
            : []
    );

function mo_side_hinge_features(side="left") =
    !hinge_plate_holes_enabled ? [] :
    concat(
        cabinet_side_has_door_hinges(side)
            ? [for(j=[0:max(0,hinge_count-1)]) if(hinge_count>0)
                for(dz=[-effective_hinge_plate_hole_spacing/2,
                         effective_hinge_plate_hole_spacing/2])
                    mo_side_circle_feature(
                        str("hinge_plate.",side,".",j+1,".",dz<0?1:2),side,
                        "through_hole","hardware.hinge",
                        effective_hinge_plate_center_from_front,
                        hinge_z(j)+dz,effective_hinge_plate_hole_diameter,
                        "through",0,"cut_layout","hinge_plate")]
            : [],
        (mixed_bay_mode && mixed_bay_side_has_hinge_plates(side))
            ? [for(j=[0:max(0,hinge_count-1)]) if(hinge_count>0)
                for(dz=[-effective_hinge_plate_hole_spacing/2,
                         effective_hinge_plate_hole_spacing/2])
                    mo_side_circle_feature(
                        str("mixed_hinge_plate.",side,".",j+1,".",dz<0?1:2),side,
                        "through_hole","hardware.hinge",
                        effective_hinge_plate_center_from_front,
                        mixed_bay_hinge_z(j)+dz,effective_hinge_plate_hole_diameter,
                        "through",0,"cut_layout","mixed_hinge_plate")]
            : []
    );

function mo_side_slide_features(side="left") =
    let(b=side == "left" ? 0 : active_drawer_bank_count()-1)
    concat(
        (has_drawers && drawer_bank_drawer_count(b)>0
            && drawer_mount == "metal_slides" && include_metal_slide_holes)
            ? [for(i=[0:drawer_bank_drawer_count(b)-1])
                for(hx=active_slide_cabinet_holes())
                    if(cabinet_slide_hole_is_valid(hx,resolved_cabinet_depth))
                        mo_side_circle_feature(
                            str("metal_slide.",side,".",i+1,".",hx),side,
                            "through_hole","hardware.slide",
                            slide_cabinet_hole_depth(hx),
                            drawer_box_z(i,b)+effective_metal_slide_cabinet_hole_z,
                            effective_metal_slide_cabinet_hole_diameter,
                            "through",0,"cut_layout","metal_slide")]
            : [],
        (has_drawers && drawer_bank_drawer_count(b)>0
            && drawer_mount == "wood_rails" && include_wood_slide_registration_holes)
            ? [for(i=[0:drawer_bank_drawer_count(b)-1])
                for(n=[0:max(0,wood_slide_registration_hole_count-1)])
                    if(wood_slide_registration_hole_count>0)
                        mo_side_circle_feature(
                            str("wood_slide.",side,".",i+1,".",n+1),side,
                            "registration_hole","hardware.slide",
                            effective_wood_rail_front_setback
                                +wood_slide_reg_pos(resolved_wood_rail_depth,n),
                            drawer_rail_z(i,b)+wood_rail_height/2,
                            wood_slide_registration_hole_diameter,
                            "through",0,"cut_layout","wood_slide_registration")]
            : []
    );

function mo_side_ganging_features(side="left") =
    !ganging_side_active(side) ? [] :
    concat(
        ganging_connector_active ? [
            for(c=[0:max(0,effective_ganging_column_count-1)])
                for(s=[0:max(0,effective_ganging_station_count-1)])
                    if(effective_ganging_column_count>0 && effective_ganging_station_count>0)
                        mo_side_circle_feature(
                            str("ganging.",side,".",ganging_column_name(c),".",s+1,".connector"),
                            side,"through_hole",str("side_gang.",side),
                            ganging_column_y(c),ganging_connector_z(s),
                            effective_ganging_connector_hole_diameter,
                            "through",0,"cut_layout","ganging_connector")
        ] : [],
        ganging_dowel_active ? [
            for(c=[0:max(0,effective_ganging_column_count-1)])
                for(s=[0:max(0,effective_ganging_station_count-1)])
                    if(effective_ganging_column_count>0 && effective_ganging_station_count>0)
                        mo_side_circle_feature(
                            str("ganging.",side,".",ganging_column_name(c),".",s+1,".dowel"),
                            side,"blind_hole",str("side_gang.",side),
                            ganging_column_y(c),ganging_dowel_z(s),
                            effective_ganging_dowel_diameter,
                            "blind_outer",effective_ganging_dowel_depth,
                            "pocket_ganging","ganging_dowel")
        ] : []
    );

function mo_side_features(side="left") =
    concat(
        mo_side_carcass_joint_features(side),
        mo_side_shelf_pin_features(side),
        mo_side_hinge_features(side),
        mo_side_slide_features(side),
        mo_side_ganging_features(side)
    );

function organization_features() =
    standalone_drawer_active ? [] :
    concat(mo_side_features("left"),mo_side_features("right"));

function organization_feature_keepout_conflicts() = [
    for (f=organization_features())
        for (k=organization_keepouts())
            if (
                mo_feature_interface(f) != mo_keepout_owner(k)
                && mo_feature_hits_keepout(f,k)
            )
                [mo_feature_id(f),mo_keepout_id(k),f[MO_F_INTERFACE],k[MO_KO_OWNER]]
];

function mo_feature_is_structural_joinery(f) =
    f[MO_F_INTERFACE] == "carcass.bottom"
    || f[MO_F_INTERFACE] == "carcass.top"
    || f[MO_F_INTERFACE] == "carcass.shelf"
    || f[MO_F_INTERFACE] == "carcass.separator"
    || f[MO_F_INTERFACE] == "carcass.toe"
    || f[MO_F_INTERFACE] == "carcass.back"
    || f[MO_F_INTERFACE] == "carcass.back_stretcher";

// Separate structural joints are allowed to meet at designed cabinet corners
// (for example a bottom dado meeting the captured-back dado). Everything else
// on the same side panel is checked against every other feature, including
// duplicate/overlapping features owned by the same interface.
function mo_feature_pair_is_expected(a,b) =
    mo_feature_is_structural_joinery(a)
    && mo_feature_is_structural_joinery(b)
    && mo_feature_interface(a) != mo_feature_interface(b);

function organization_feature_feature_conflicts() =
    let(fs=organization_features(),n=len(fs)) [
        for(i=[0:max(0,n-1)]) if(n>1)
            for(j=[0:max(0,n-1)]) if(j>i)
                if(!mo_feature_pair_is_expected(fs[i],fs[j])
                    && mo_feature_pair_hits(fs[i],fs[j]))
                    [
                        mo_feature_id(fs[i]),mo_feature_id(fs[j]),
                        fs[i][MO_F_INTERFACE],fs[j][MO_F_INTERFACE],
                        fs[i][MO_F_PART]
                    ]
    ];

function organization_side_feature_family_count() =
    len([
        "carcass_horizontal_joinery","toe_joinery","back_stretcher_joinery",
        "structural_back_joinery","shelf_pin_drilling","hinge_plate_drilling",
        "slide_drilling","ganging_drilling"
    ]);

function organization_feature_owner_classes() = [
    ["carcass.bottom.tabs_receivers","carcass.bottom"],
    ["carcass.top.tabs_receivers","carcass.top"],
    ["carcass.fixed_shelf.tabs_receivers","carcass.shelf"],
    ["carcass.separator.tabs_receivers","carcass.separator"],
    ["carcass.toe.joinery","carcass.toe"],
    ["carcass.back.joinery","carcass.back"],
    ["carcass.back_stretcher.joinery","carcass.back_stretcher"],
    ["drawer.corner.joinery","drawer.corner"],
    ["stack.bottom.profile","stack.bottom"],
    ["stack.top.profile","stack.top"],
    ["ganging.left.points","side_gang.left"],
    ["ganging.right.points","side_gang.right"],
    ["hardware.slide.drilling","hardware.slide"],
    ["hardware.hinge.drilling","hardware.hinge"],
    ["storage.shelf_pin.drilling","storage.shelf_grid"]
];



bottom_panel_width =
    full_width_bottom_active
        ? resolved_cabinet_width
        : joined_w;

bottom_panel_global_x0 =
    full_width_bottom_active
        ? 0
        : horizontal_panel_global_x0();

bottom_receiver_x_shift =
    full_width_bottom_active
        ? horizontal_panel_global_x0()
        : 0;

function bottom_panel_local_x(global_x) =
    global_x-bottom_panel_global_x0;

top_layout_x = bottom_panel_width + layout_gap;

// Cut-layout placement values.
layout_y2 = cabinet_height + layout_gap;
layout_y3 = layout_y2 + resolved_cabinet_depth + layout_gap;
layout_y4 =
    layout_y3
    + max([
        include_back ? back_cut_height : 0,
        back_stretcher_layout_height,
        toe_kick_height
    ])
    + layout_gap;

door_compartment_panel_count =
    mixed_bay_mode
        ? 0
        : (has_doors ? door_shelf_count : 0)
          + (cabinet_contents == "combo" ? 1 : 0);

// Mixed-bay adjustable shelves use the same shelf-depth row pitch and occupy
// the legacy door-compartment layout area before partition parts.
mixed_bay_shelf_layout_base_y =
    layout_y4
    + door_compartment_panel_count*(shelf_depth+layout_gap);

function mixed_bay_shelf_layout_y(b,s) =
    mixed_bay_shelf_layout_base_y
    + (mixed_bay_shelf_count_prefix(b)+s-1)
      *(shelf_depth+layout_gap);

door_hinge_partition_layout_base_y =
    mixed_bay_shelf_layout_base_y
    + (mixed_bay_mode ? mixed_bay_total_shelf_count() : 0)
      *(shelf_depth+layout_gap)
    + layout_gap;

door_hinge_partition_layout_row_height =
    door_hinge_partition_cut_height()+layout_gap;

mixed_bay_partition_layout_base_y =
    door_hinge_partition_layout_base_y
    + (
        door_hinge_partition_count() > 0
            ? door_hinge_partition_count()
              *door_hinge_partition_layout_row_height
              + layout_gap
            : 0
      );

mixed_bay_partition_layout_row_height =
    mixed_bay_partition_cut_height()+layout_gap;

drawer_bank_partition_layout_base_y =
    mixed_bay_partition_layout_base_y
    + (
        mixed_bay_partition_count() > 0
            ? mixed_bay_partition_count()
              *mixed_bay_partition_layout_row_height
              + layout_gap
            : 0
      );

drawer_bank_partition_layout_row_height =
    drawer_bank_partition_cut_height()+layout_gap;

drawer_separator_layout_base_y =
    drawer_bank_partition_layout_base_y
    + drawer_bank_partition_count()*drawer_bank_partition_layout_row_height
    + layout_gap;

drawer_separator_layout_row_height =
    drawer_separator_style == "full"
        ? drawer_separator_full_depth + layout_gap
        : 2*drawer_separator_stretcher_actual_depth + 2*layout_gap;

drawer_layout_base_y =
    standalone_drawer_active
        ? 0
        : drawer_separator_layout_base_y
          + drawer_separator_count*drawer_separator_layout_row_height
          + layout_gap;

function drawer_layout_face_height(i,b=0) =
    include_drawer_faces ? drawer_face_height_for(i,b) : 0;

// Wood rails/runners share the horizontal strip beside the drawer face in the
// flat layouts. Shallow faces (or no applied face) used to let the second rail
// extend downward into the drawer-side/cross-panel row. Reserve the taller of
// the face strip or the complete two-piece slide strip before placing box parts.
function drawer_layout_slide_strip_height() =
    drawer_mount == "wood_rails"
        ? max(
            2*wood_rail_height + layout_gap,
            2*wood_drawer_runner_height + layout_gap
          )
        : 0;

function drawer_layout_header_height(i,b=0) =
    max(
        drawer_layout_face_height(i,b),
        drawer_layout_slide_strip_height()
    );

// Canonical flat-layout Y origin for the drawer SIDE / FRONT / BACK parts.
// CUT, PRINT, and all blind drawer-pocket overlays must use this same helper.
// Keeping this in one place prevents pocket geometry from drifting back onto
// the wood-rail strip when faces are shallow or disabled.
function drawer_layout_box_parts_y(b,i) =
    drawer_layout_row_y(b,i)
    + drawer_layout_header_height(i,b)
    + layout_gap;

function drawer_layout_row_height_for(i,b=0) =
    drawer_layout_header_height(i,b)
    + max(
        2*drawer_box_height(i,b)+layout_gap,
        drawer_box_height(i,b)+2*layout_gap+drawer_box_depth
      )
    + 2*layout_gap;

function drawer_layout_prefix_height(b,i,j=0) =
    j >= i
        ? 0
        : drawer_layout_row_height_for(j,b)
          + drawer_layout_prefix_height(b,i,j+1);

function drawer_layout_stack_height(b=0) =
    drawer_layout_prefix_height(
        b,drawer_bank_drawer_count(b));

function drawer_layout_bank_prefix_height(b,j=0) =
    j >= b
        ? 0
        : drawer_layout_stack_height(j)
          + layout_gap
          + drawer_layout_bank_prefix_height(b,j+1);

function drawer_layout_bank_base_y(b) =
    drawer_layout_base_y
    + drawer_layout_bank_prefix_height(b);

function drawer_layout_row_y(b,i) =
    drawer_layout_bank_base_y(b)
    + drawer_layout_prefix_height(b,i);

function drawer_layout_all_banks_height() =
    drawer_layout_bank_prefix_height(active_drawer_bank_count())
    - (active_drawer_bank_count() > 0 ? layout_gap : 0);

door_layout_y =
    drawer_layout_base_y
    + max(0,drawer_layout_all_banks_height())
    + layout_gap;


// ---------------------------
// BASE HARDWARE / WORKTOP DERIVED GEOMETRY
// ---------------------------

base_mounting_plate_x =
    max(0,base_mounting_plate_side_inset);

base_mounting_plate_y =
    max(0,base_mounting_plate_front_inset);

base_mounting_plate_width =
    max(
        10,
        resolved_cabinet_width
        - 2*max(0,base_mounting_plate_side_inset)
    );

base_mounting_plate_depth =
    max(
        10,
        resolved_cabinet_depth
        - max(0,base_mounting_plate_front_inset)
        - max(0,base_mounting_plate_back_inset)
    );

function base_hardware_half_x() =
    active_base_style == "casters"
        ? caster_mount_plate_width/2
        : leveler_foot_diameter/2;

function base_hardware_half_y() =
    active_base_style == "casters"
        ? caster_mount_plate_depth/2
        : leveler_foot_diameter/2;

function base_hardware_center_x(side=0) =
    side == 0
        ? max(
            base_hardware_inset_x,
            base_mounting_plate_active
                ? base_mounting_plate_x
                  + base_hardware_half_x()
                : material_thickness
                  + base_hardware_half_x()
          )
        : min(
            resolved_cabinet_width-base_hardware_inset_x,
            base_mounting_plate_active
                ? base_mounting_plate_x
                  + base_mounting_plate_width
                  - base_hardware_half_x()
                : resolved_cabinet_width
                  - material_thickness
                  - base_hardware_half_x()
          );

function base_hardware_center_y(front=0) =
    front == 0
        ? max(
            base_hardware_inset_y,
            base_mounting_plate_active
                ? base_mounting_plate_y
                  + base_hardware_half_y()
                : base_hardware_half_y()
          )
        : min(
            resolved_cabinet_depth-base_hardware_inset_y,
            base_mounting_plate_active
                ? base_mounting_plate_y
                  + base_mounting_plate_depth
                  - base_hardware_half_y()
                : resolved_cabinet_depth
                  - base_hardware_half_y()
          );

function base_hardware_center_x_for_index(i) =
    base_hardware_center_x(i % 2);

function base_hardware_center_y_for_index(i) =
    base_hardware_center_y(floor(i/2));

function base_hardware_hole_count_per_corner() =
    active_base_style == "casters" ? 4 : 1;

function base_hardware_hole_global_x(corner,hole=0) =
    active_base_style == "casters"
        ? base_hardware_center_x_for_index(corner)
          + ((hole % 2) == 0 ? -1 : 1)
            *caster_hole_spacing_x/2
        : base_hardware_center_x_for_index(corner);

function base_hardware_hole_global_y(corner,hole=0) =
    active_base_style == "casters"
        ? base_hardware_center_y_for_index(corner)
          + (floor(hole/2) == 0 ? -1 : 1)
            *caster_hole_spacing_y/2
        : base_hardware_center_y_for_index(corner);

function base_hardware_hole_diameter() =
    active_base_style == "casters"
        ? caster_hole_diameter
        : leveler_mount_hole_diameter;

worktop_width =
    resolved_cabinet_width + 2*max(0,worktop_side_overhang);

worktop_depth =
    resolved_cabinet_depth
    + max(0,worktop_front_overhang)
    + max(0,worktop_back_overhang);

worktop_x = -max(0,worktop_side_overhang);
worktop_y = -max(0,worktop_front_overhang);
worktop_z = cabinet_height;

active_worktop_registration =
    worktop_active
    && include_worktop_registration_holes
    && worktop_registration_hole_count > 0;

effective_worktop_registration_blind_depth =
    active_worktop_registration
        ? min(
            max(0.5,worktop_registration_blind_depth),
            max(0.5,worktop_thickness-0.5)
          )
        : 0;

function worktop_registration_x_margin() =
    min(
        max(10,worktop_registration_end_margin),
        max(10,inner_width/2-5)
    );

function worktop_registration_x(i) =
    worktop_registration_hole_count <= 1
        ? resolved_cabinet_width/2
        : material_thickness
          + worktop_registration_x_margin()
          + i*(
                inner_width
                - 2*worktop_registration_x_margin()
            )/(worktop_registration_hole_count-1);

// Two front/rear rows. With stretcher construction these land at the center of
// each stretcher. With a full top the same two rows are retained.
function worktop_registration_row_y(r) =
    r == 0
        ? min(resolved_cabinet_depth/2,top_stretcher_depth/2)
        : max(
            resolved_cabinet_depth/2,
            resolved_cabinet_depth-top_stretcher_depth/2
          );

function worktop_registration_worktop_local_x(i) =
    worktop_registration_x(i)-worktop_x;

function worktop_registration_worktop_local_y(r) =
    worktop_registration_row_y(r)-worktop_y;

accessory_layout_y =
    door_layout_y
    + (has_doors ? door_face_height : 0)
    + layout_gap;

base_mounting_plate_layout_y = accessory_layout_y;

worktop_layout_y =
    accessory_layout_y
    + (base_mounting_plate_active
        ? base_mounting_plate_depth+layout_gap
        : 0);

accessory_layout_end_y =
    max([
        door_layout_y
            + (has_doors ? door_face_height : 0)
            + layout_gap,
        base_mounting_plate_active
            ? base_mounting_plate_layout_y
              + base_mounting_plate_depth
              + layout_gap
            : 0,
        worktop_active
            ? worktop_layout_y
              + worktop_depth
              + layout_gap
            : 0
    ]);


// ---------------------------
// STACKABLE MODULE / BASE DERIVED GEOMETRY
// ---------------------------

stack_base_active =
    stackable_mode
    && include_stack_base;

effective_stack_interface_depth =
    stackable_mode
        ? min(
            max(2,stack_interface_depth),
            max(2,cabinet_height/3)
          )
        : 0;

effective_stack_interface_clearance =
    max(0,stack_interface_clearance);

effective_stack_front_margin =
    min(
        max(material_thickness,stack_interface_front_margin),
        max(
            material_thickness,
            resolved_cabinet_depth
            - material_thickness
            - stack_interface_back_margin
            - 20
        )
    );

effective_stack_back_margin =
    min(
        max(material_thickness,stack_interface_back_margin),
        max(
            material_thickness,
            resolved_cabinet_depth
            - material_thickness
            - effective_stack_front_margin
            - 20
        )
    );

stack_interface_center_span =
    max(
        2,
        resolved_cabinet_depth
        - effective_stack_front_margin
        - effective_stack_back_margin
    );

stack_interface_tool_radius =
    max(0,cnc_tool_diameter/2);

// The canonical interface transition uses TWO tangent quarter-circle fillets:
// high pad -> vertical tangent -> low tongue.  The female recess is then
// offset outward by stack_interface_clearance.
//
// Because that female offset can reduce one of the two local concave radii,
// keep the nominal mating radius at least cutter_radius + clearance.
stack_interface_min_nominal_radius =
    stack_interface_tool_radius
    + effective_stack_interface_clearance;

stack_interface_max_nominal_radius =
    min(
        effective_stack_interface_depth/2,
        max(1,stack_interface_center_span/4-1)
    );

effective_stack_interface_corner_radius =
    min(
        max(
            stack_interface_min_nominal_radius,
            stack_interface_corner_radius
        ),
        stack_interface_max_nominal_radius
    );

stack_interface_vertical_tangent_length =
    max(
        0,
        effective_stack_interface_depth
        - 2*effective_stack_interface_corner_radius
    );

stack_module_pitch =
    stackable_mode
        ? cabinet_height-effective_stack_interface_depth
        : cabinet_height;

stack_first_module_z =
    stack_base_active
        ? stack_base_height
          - effective_stack_interface_depth
          + stack_preview_explode_gap
        : 0;

stack_preview_total_height =
    stackable_mode
        ? stack_first_module_z
          + max(0,stack_preview_count-1)
            *(stack_module_pitch+stack_preview_explode_gap)
          + cabinet_height
        : cabinet_height;

function stack_base_cross_rail_cut_width() =
    joinery_style == "dado"
        ? inner_width+2*effective_dado_depth()
        : joinery_style == "tab_slot"
            ? resolved_cabinet_width
            : inner_width;

stack_base_side_layout_y =
    accessory_layout_end_y;

stack_base_cross_layout_y =
    stack_base_side_layout_y
    + (stack_base_active ? stack_base_height+layout_gap : 0);

stack_base_layout_end_y =
    stack_base_active
        ? stack_base_cross_layout_y
          + stack_base_height
          + layout_gap
        : accessory_layout_end_y;


// Face-frame strips are laid out after all other accessories. They use their
// own stock thickness/material role but share the common export frame.
face_frame_layout_y =
    stack_base_layout_end_y;

face_frame_stile_cut_height =
    face_frame_height;

face_frame_rail_cut_width =
    max(
        1,
        resolved_cabinet_width
        - 2*effective_face_frame_side_stile_width
    );

face_frame_center_stile_cut_height =
    max(
        1,
        face_frame_clear_height
    );

face_frame_mid_rail_cut_width =
    face_frame_rail_cut_width;

face_frame_layout_end_y =
    face_frame_active
        ? face_frame_layout_y
          + max(
                face_frame_stile_cut_height,
                effective_face_frame_top_rail_width
                + effective_face_frame_bottom_rail_width
                + effective_face_frame_mid_rail_width
                + 4*layout_gap
            )
          + layout_gap
        : stack_base_layout_end_y;


// Conservative common export bounds for BOTH cut_layout and pocket_layout.
// Width includes the side-panel row plus generous room for drawer components.
// Height uses door_layout_y because it is always below all previous layout rows.
standalone_drawer_header_layout_width =
    drawer_mount == "wood_rails"
        ? max(drawer_face_width(0),drawer_outer_width(0))
          + layout_gap
          + (
                standalone_include_fixed_wood_rails_resolved
                    ? resolved_wood_rail_depth+layout_gap
                    : 0
            )
          + resolved_wood_drawer_runner_depth
        : max(
            drawer_face_width(0),
            drawer_outer_width(0)
          );

standalone_drawer_box_parts_layout_width =
    2*(drawer_box_depth+layout_gap)
    + drawer_cross_panel_width(0)
    + layout_gap;

standalone_drawer_layout_width =
    max(
        1,
        standalone_drawer_header_layout_width,
        standalone_drawer_box_parts_layout_width,
        drawer_bottom_width(0)
    );

standalone_drawer_layout_height =
    max(
        1,
        drawer_layout_all_banks_height()
        + layout_gap
    );

export_layout_content_width =
    standalone_drawer_active
        ? standalone_drawer_layout_width
        : max([
            stock_width,
            2*resolved_cabinet_depth + layout_gap,
            bottom_panel_width + joined_w + layout_gap,
            back_cut_width + layout_gap + resolved_cabinet_width,
            3*max(resolved_cabinet_width,resolved_cabinet_depth) + 4*layout_gap,
            base_mounting_plate_active
                ? base_mounting_plate_width
                : 0,
            worktop_active
                ? worktop_width
                : 0,
            stack_base_active
                ? max(
                    2*resolved_cabinet_depth+layout_gap,
                    2*stack_base_cross_rail_cut_width()+layout_gap
                  )
                : 0,
            face_frame_active
                ? max(
                    2*effective_face_frame_side_stile_width
                        + face_frame_rail_cut_width
                        + 4*layout_gap,
                    resolved_cabinet_width
                  )
                : 0
        ]);

export_layout_content_height =
    standalone_drawer_active
        ? standalone_drawer_layout_height
        : max([
            stock_height,
            accessory_layout_end_y,
            stack_base_layout_end_y,
            face_frame_layout_end_y
        ]);


// ---------------------------
// BASIC HELPERS
// ---------------------------

module sheet_box(size=[10,10,10], pos=[0,0,0]) {
    translate(pos) cube(size);
}

module cut_rect(w,h) {
    if (apply_kerf_compensation)
        offset(delta=kerf/2) square([w,h]);
    else
        square([w,h]);
}

module cut_part(w,h) {
    if (w > 0 && h > 0)
        cut_rect(w,h);
}

module metal_hole_2d(xpos,zpos,diameter=effective_metal_slide_cabinet_hole_diameter) {
    translate([xpos,zpos]) circle(d=compensated_hole_diameter(diameter));
}

module metal_hole_x_3d(xstart,ypos,zpos,depth,diameter=effective_metal_slide_cabinet_hole_diameter) {
    translate([xstart,ypos,zpos]) rotate([0,90,0]) cylinder(h=depth,d=diameter);
}

module round_hole_x_3d(xstart,ypos,zpos,depth,diameter) {
    translate([xstart,ypos,zpos])
        rotate([0,90,0])
            cylinder(h=depth,d=diameter);
}

module round_hole_2d(xpos,ypos,diameter) {
    translate([xpos,ypos])
        circle(d=diameter);
}

module round_hole_y_3d(xpos,y_front,zpos,depth,diameter) {
    translate([xpos,y_front,zpos])
        rotate([90,0,0])
            cylinder(h=depth,d=diameter);
}


// ---------------------------
// DISPLAY COLORS
// ---------------------------

// The palette is intentionally high-contrast rather than photorealistic.
// Names remain stable between assembly and cut-layout views.
function part_rgb(name, index=0) =
    color_mode == "material"
        ? [0.86,0.72,0.48]
        : color_mode == "monochrome"
            ? [0.72,0.72,0.72]
            : name == "side_left"       ? [0.26,0.53,0.86]
            : name == "side_right"      ? [0.30,0.70,0.48]
            : name == "bottom"          ? [0.93,0.55,0.22]
            : name == "top_front"       ? [0.56,0.38,0.78]
            : name == "top_rear"        ? [0.74,0.38,0.73]
            : name == "top_full"        ? [0.62,0.42,0.80]
            : name == "back"            ? [0.86,0.34,0.38]
            : name == "toe_kick"        ? [0.55,0.36,0.22]
            : name == "base_mounting_plate" ? [0.34,0.34,0.38]
            : name == "caster"          ? [0.18,0.18,0.20]
            : name == "leveler"         ? [0.30,0.30,0.32]
            : name == "worktop"         ? [0.72,0.55,0.30]
            : name == "divider"         ? [0.92,0.78,0.25]
            : name == "drawer_separator"? [0.92,0.86,0.48]
            : name == "drawer_bank_partition" ? [0.38,0.60,0.80]
            : name == "mixed_bay_partition" ? [0.32,0.58,0.72]
            : name == "door_hinge_partition" ? [0.72,0.54,0.30]
            : name == "shelf"           ? [0.24,0.72,0.72]
            : name == "rail"            ? [0.42,0.45,0.49]
            : name == "drawer_runner"   ? [0.18,0.58,0.44]
            : name == "drawer_face"     ? (index % 2 == 0 ? [0.96,0.49,0.34] : [0.93,0.64,0.30])
            : name == "drawer_side_l"   ? [0.30,0.68,0.82]
            : name == "drawer_side_r"   ? [0.34,0.76,0.65]
            : name == "drawer_box_front"? [0.58,0.73,0.36]
            : name == "drawer_box_back" ? [0.45,0.63,0.31]
            : name == "drawer_bottom"   ? [0.80,0.82,0.42]
            : name == "door"            ? (index % 2 == 0 ? [0.88,0.46,0.64] : [0.67,0.48,0.82])
            : [0.80,0.80,0.80];

module paint(name,index=0) {
    color(part_rgb(name,index)) children();
}


// ---------------------------
// JOINERY HELPERS
// ---------------------------

// CNC relief centers for a rectangular slot.
// Corner indexes: ix=0 left / ix=1 right; iy=0 bottom / iy=1 top.
//
// DOGBONE:
//   The cutter center moves diagonally INWARD from the nominal sharp corner
//   by r/sqrt(2) in X and Y. The cutter circumference therefore passes exactly
//   through the original sharp corner while minimizing extra material removal.
//
// T-BONE:
//   The cutter center moves INWARD by one cutter radius along the slot's
//   LONGEST adjacent wall. The other wall remains straight. This mirrors the
//   common "T-bone on longest edge" CAM convention and is useful when the slot
//   is narrow relative to cutter diameter.
function slot_relief_center_x(w,h,ix,iy) =
    let(
        r = slot_relief_radius(),
        d = slot_dogbone_inset(),
        cx = ix == 0 ? 0 : w,
        sx = ix == 0 ? 1 : -1
    )
    slot_relief_is_dogbone()
        ? cx + sx*d
        : slot_relief_is_tbone() && w >= h
            ? cx + sx*r
            : cx;

function slot_relief_center_y(w,h,ix,iy) =
    let(
        r = slot_relief_radius(),
        d = slot_dogbone_inset(),
        cy = iy == 0 ? 0 : h,
        sy = iy == 0 ? 1 : -1
    )
    slot_relief_is_dogbone()
        ? cy + sy*d
        : slot_relief_is_tbone() && h > w
            ? cy + sy*r
            : cy;

// Central open-edge policy inherited from v35 used by every slot-relief orientation.
// Relief is legal only when BOTH walls meeting at a corner are closed.
function slot_edge_open(edge,open_left,open_right,open_bottom,open_top) =
    edge == "left" ? open_left
    : edge == "right" ? open_right
    : edge == "bottom" ? open_bottom
    : edge == "top" ? open_top
    : false;

function slot_corner_is_closed(
    ix,iy,open_left=false,open_right=false,open_bottom=false,open_top=false
) =
    !slot_edge_open(ix == 0 ? "left" : "right",
                    open_left,open_right,open_bottom,open_top)
    && !slot_edge_open(iy == 0 ? "bottom" : "top",
                       open_left,open_right,open_bottom,open_top);

module slot_corner_relief_2d(
    w,h,
    open_left=false,open_right=false,
    open_bottom=false,open_top=false
) {
    if (slot_relief_is_active())
        for (ix=[0:1])
            for (iy=[0:1])
                // Relief only belongs at a genuinely closed/internal corner.
                // If either wall meeting at this corner is open to the panel
                // perimeter, the cutter already has an escape path and a
                // dogbone/T-bone would unnecessarily scallop the finished edge.
                if (slot_corner_is_closed(
                    ix,iy,open_left,open_right,open_bottom,open_top))
                    translate([
                        slot_relief_center_x(w,h,ix,iy),
                        slot_relief_center_y(w,h,ix,iy)
                    ])
                        circle(d=cnc_tool_diameter);
}

// 2D through-slot shape in the side-panel Y/Z plane.
// w = slot dimension along cabinet depth (Y)
// h = slot dimension vertically (Z)
module slot_shape_2d(
    w,h,
    open_left=false,open_right=false,
    open_bottom=false,open_top=false
) {
    union() {
        square([w,h]);
        slot_corner_relief_2d(
            w,h,
            open_left,open_right,
            open_bottom,open_top
        );
    }
}

// Same slot as above, cut through a cabinet side in the X direction.
module slot_cut_x_3d(
    xstart,depth,y0,z0,w,h,
    open_left=false,open_right=false,
    open_bottom=false,open_top=false
) {
    union() {
        translate([xstart,y0,z0])
            cube([depth,w,h]);

        if (slot_relief_is_active())
            for (ix=[0:1])
                for (iy=[0:1])
                    if (slot_corner_is_closed(
                        ix,iy,open_left,open_right,open_bottom,open_top))
                        translate([
                            xstart,
                            y0+slot_relief_center_x(w,h,ix,iy),
                            z0+slot_relief_center_y(w,h,ix,iy)
                        ])
                            rotate([0,90,0])
                                cylinder(
                                    h=depth,
                                    d=cnc_tool_diameter
                                );
    }
}

// Fixed horizontal panel used for bottoms, tops, stretchers, shelves,
// and the combo divider.
module joined_horizontal_panel_3d(y0,depth,z0,tab_location="default") {
    if (joinery_style == "butt") {
        sheet_box([inner_width,depth,material_thickness],
                  [material_thickness,y0,z0]);
    }
    else if (joinery_style == "dado") {
        dd = effective_dado_depth();
        sheet_box([inner_width+2*dd,depth,material_thickness],
                  [material_thickness-dd,y0,z0]);
    }
    else if (joinery_style == "tab_slot") {
        union() {
            sheet_box([inner_width,depth,material_thickness],
                      [material_thickness,y0,z0]);

            tab_n = tab_count_for_location(depth,tab_location);

            for (i=[0:tab_n-1]) {
                ty = y0 + tab_start_for_location(depth,i,tab_location);
                tw = tab_width_for(depth);

                // Left and right tabs extend through the cabinet sides.
                sheet_box([material_thickness,tw,material_thickness],
                          [0,ty,z0]);
                sheet_box([material_thickness,tw,material_thickness],
                          [resolved_cabinet_width-material_thickness,ty,z0]);
            }
        }
    }
}

// 2D profile of the same horizontal panel.
// Local X is cabinet width; local Y is the panel's depth.
module joined_horizontal_panel_cut(depth,tab_location="default") {
    if (joinery_style == "butt") {
        cut_part(inner_width,depth);
    }
    else if (joinery_style == "dado") {
        cut_part(inner_width+2*effective_dado_depth(),depth);
    }
    else if (joinery_style == "tab_slot") {
        union() {
            translate([material_thickness,0])
                cut_part(inner_width,depth);

            tab_n = tab_count_for_location(depth,tab_location);

            for (i=[0:tab_n-1]) {
                ty = tab_start_for_location(depth,i,tab_location);
                tw = tab_width_for(depth);

                translate([0,ty])
                    cut_part(material_thickness,tw);
                translate([resolved_cabinet_width-material_thickness,ty])
                    cut_part(material_thickness,tw);
            }
        }
    }
}


// ---------------------------
// DRAWER-BANK VERTICAL PARTITIONS / RECEIVERS
// ---------------------------

module slot_cut_z_3d(
    x0,y0,zstart,depth,w,h,
    open_left=false,open_right=false,
    open_bottom=false,open_top=false
) {
    union() {
        translate([x0,y0,zstart])
            cube([w,h,depth]);

        if (slot_relief_is_active())
            for (ix=[0:1])
                for (iy=[0:1])
                    if (slot_corner_is_closed(
                        ix,iy,open_left,open_right,open_bottom,open_top))
                        translate([
                            x0+slot_relief_center_x(w,h,ix,iy),
                            y0+slot_relief_center_y(w,h,ix,iy),
                            zstart
                        ])
                            cylinder(
                                h=depth,
                                d=cnc_tool_diameter
                            );
    }
}

module drawer_bank_receiver_cuts_3d(
    panel_y0,panel_depth,z0,receiver_face="top"
) {
    if (has_drawers && drawer_bank_partition_count() > 0) {
        mode = drawer_bank_partition_joinery_mode();
        ov = depth_overlap_length(panel_y0,panel_depth);
        ov0 = depth_overlap_start(panel_y0);

        if (ov > 0) {
            for (p=[0:drawer_bank_partition_count()-1]) {
                px = drawer_bank_partition_x(p);

                if (mode == "dado") {
                    c = dado_fit_clearance;
                    dd = drawer_bank_partition_dado_depth();
                    zcut = receiver_face == "top"
                        ? z0 + material_thickness - dd - 0.01
                        : z0 - 0.01;

                    translate([
                        px-c/2,
                        ov0-c/2,
                        zcut
                    ])
                        cube([
                            material_thickness+c,
                            ov+c,
                            dd+0.02
                        ]);
                }
                else if (mode == "tab_slot") {
                    c = joint_fit_clearance;

                    for (n=[0:effective_tab_count(ov)-1]) {
                        yy = ov0 + tab_start(ov,n)-c/2;
                        hh = tab_width_for(ov)+c;

                        slot_cut_z_3d(
                            px-c/2,
                            yy,
                            z0-1,
                            material_thickness+2,
                            material_thickness+c,
                            hh
                        );
                    }
                }
            }
        }
    }
}

module drawer_bank_receiver_through_2d(panel_y0,panel_depth) {
    if (has_drawers
        && drawer_bank_partition_count() > 0
        && drawer_bank_partition_joinery_mode() == "tab_slot") {

        c = joint_fit_clearance;
        ov = depth_overlap_length(panel_y0,panel_depth);
        ov0 = depth_overlap_start(panel_y0);

        if (ov > 0)
            for (p=[0:drawer_bank_partition_count()-1]) {
                lx = horizontal_panel_local_x(
                    drawer_bank_partition_x(p)) - c/2;
                ly0 = ov0-panel_y0;

                for (n=[0:effective_tab_count(ov)-1]) {
                    yy = ly0 + tab_start(ov,n)-c/2;
                    hh = tab_width_for(ov)+c;

                    translate([lx,yy])
                        slot_shape_2d(material_thickness+c,hh);
                }
            }
    }
}

module drawer_bank_receiver_dado_pockets_2d(panel_y0,panel_depth) {
    if (has_drawers
        && drawer_bank_partition_count() > 0
        && drawer_bank_partition_joinery_mode() == "dado") {

        c = dado_fit_clearance;
        ov = depth_overlap_length(panel_y0,panel_depth);
        ov0 = depth_overlap_start(panel_y0);

        if (ov > 0)
            for (p=[0:drawer_bank_partition_count()-1]) {
                lx = horizontal_panel_local_x(
                    drawer_bank_partition_x(p)) - c/2;
                ly = ov0-panel_y0-c/2;

                translate([lx,ly])
                    square([
                        material_thickness+c,
                        ov+c
                    ]);
            }
    }
}


// Receiver cuts for the automatic multi-door hinge partitions.
module door_hinge_partition_receiver_cuts_3d(
    panel_y0,panel_depth,z0,receiver_face="top"
) {
    if (door_hinge_partition_count() > 0) {
        ov = door_hinge_depth_overlap_length(panel_y0,panel_depth);
        ov0 = door_hinge_depth_overlap_start(panel_y0);

        if (ov > 0)
            for (p=[0:door_hinge_partition_count()-1]) {
                px = door_hinge_partition_x(p);

                if (joinery_style == "dado") {
                    c = dado_fit_clearance;
                    dd = door_hinge_partition_dado_depth();
                    zcut =
                        receiver_face == "top"
                            ? z0 + material_thickness-dd-0.01
                            : z0-0.01;

                    translate([
                        px-c/2,
                        ov0-c/2,
                        zcut
                    ])
                        cube([
                            material_thickness+c,
                            ov+c,
                            dd+0.02
                        ]);
                }
                else if (joinery_style == "tab_slot") {
                    c = joint_fit_clearance;

                    for (n=[0:effective_tab_count(ov)-1]) {
                        yy = ov0+tab_start(ov,n)-c/2;
                        hh = tab_width_for(ov)+c;

                        slot_cut_z_3d(
                            px-c/2,
                            yy,
                            z0-1,
                            material_thickness+2,
                            material_thickness+c,
                            hh
                        );
                    }
                }
            }
    }
}

module door_hinge_partition_receiver_through_2d(
    panel_y0,panel_depth
) {
    if (door_hinge_partition_count() > 0
        && joinery_style == "tab_slot") {

        c = joint_fit_clearance;
        ov = door_hinge_depth_overlap_length(panel_y0,panel_depth);
        ov0 = door_hinge_depth_overlap_start(panel_y0);

        if (ov > 0)
            for (p=[0:door_hinge_partition_count()-1]) {
                lx =
                    horizontal_panel_local_x(
                        door_hinge_partition_x(p))
                    - c/2;
                ly0 = ov0-panel_y0;

                for (n=[0:effective_tab_count(ov)-1]) {
                    yy = ly0+tab_start(ov,n)-c/2;
                    hh = tab_width_for(ov)+c;

                    translate([lx,yy])
                        slot_shape_2d(
                            material_thickness+c,
                            hh
                        );
                }
            }
    }
}

module door_hinge_partition_receiver_dado_pockets_2d(
    panel_y0,panel_depth
) {
    if (door_hinge_partition_count() > 0
        && joinery_style == "dado") {

        c = dado_fit_clearance;
        ov = door_hinge_depth_overlap_length(panel_y0,panel_depth);
        ov0 = door_hinge_depth_overlap_start(panel_y0);

        if (ov > 0)
            for (p=[0:door_hinge_partition_count()-1]) {
                lx =
                    horizontal_panel_local_x(
                        door_hinge_partition_x(p))
                    - c/2;
                ly = ov0-panel_y0-c/2;

                translate([lx,ly])
                    square([
                        material_thickness+c,
                        ov+c
                    ]);
            }
    }
}

module door_hinge_partition_joinery_segment_3d(
    x0,y0,span,z0,edge="bottom"
) {
    if (span > 0) {
        if (joinery_style == "dado") {
            dd = door_hinge_partition_dado_depth();
            zz = edge == "bottom" ? z0-dd : z0;

            sheet_box(
                [material_thickness,span,dd],
                [x0,y0,zz]
            );
        }
        else if (joinery_style == "tab_slot") {
            zz = edge == "bottom"
                ? z0-material_thickness
                : z0;

            for (n=[0:effective_tab_count(span)-1]) {
                yy = y0+tab_start(span,n);
                th = tab_width_for(span);

                sheet_box(
                    [
                        material_thickness,
                        th,
                        material_thickness
                    ],
                    [x0,yy,zz]
                );
            }
        }
    }
}

module door_hinge_partition_bottom_joinery_3d(x0,z0) {
    door_hinge_partition_joinery_segment_3d(
        x0,0,door_hinge_partition_actual_depth,z0,"bottom");
}

module door_hinge_partition_top_joinery_3d(x0,z0) {
    if (cabinet_contents == "combo") {
        span =
            min(
                door_hinge_partition_actual_depth,
                shelf_depth
            );

        door_hinge_partition_joinery_segment_3d(
            x0,0,span,z0,"top");
    }
    else if (top_style == "full") {
        door_hinge_partition_joinery_segment_3d(
            x0,0,door_hinge_partition_actual_depth,z0,"top");
    }
    else {
        front_span =
            min(
                door_hinge_partition_actual_depth,
                top_stretcher_depth
            );

        if (front_span > 0)
            door_hinge_partition_joinery_segment_3d(
                x0,0,front_span,z0,"top");

        rear_start =
            max(0,resolved_cabinet_depth-top_stretcher_depth);

        rear_span =
            max(
                0,
                min(
                    door_hinge_partition_actual_depth,
                    resolved_cabinet_depth
                )-rear_start
            );

        if (rear_span > 0)
            door_hinge_partition_joinery_segment_3d(
                x0,rear_start,rear_span,z0,"top");
    }
}

module door_hinge_partition_plate_holes_3d(x0) {
    if (effective_hinge_style != "none")
        for (j=[0:hinge_count-1])
            if (hinge_plate_holes_enabled)
            for (dz=[
                -effective_hinge_plate_hole_spacing/2,
                effective_hinge_plate_hole_spacing/2
            ])
                round_hole_x_3d(
                    x0-1,
                    effective_hinge_plate_center_from_front,
                    hinge_z(j)+dz,
                    material_thickness+2,
                    effective_hinge_plate_hole_diameter
                );
}

// Fixed shelves remain continuous full-width parts. They cross the partition
// through an open-front cross-lap notch, preserving the existing shelf-to-side
// carcass joinery while also tying the partition to each fixed shelf.
module door_hinge_partition_fixed_shelf_notches_3d(x0) {
    if (shelf_style == "fixed" && door_shelf_count > 0) {
        c = max(0,door_hinge_partition_shelf_clearance);
        notch_depth =
            min(
                shelf_depth,
                door_hinge_partition_actual_depth
            );

        for (s=[1:door_shelf_count])
            translate([
                x0-1,
                shelf_front_y-0.01,
                door_shelf_z(s)-c/2
            ])
                cube([
                    material_thickness+2,
                    notch_depth+0.02,
                    material_thickness+c
                ]);
    }
}

// Internal adjustable-shelf support holes are made THROUGH the partition so
// one drilled row supports the bays on both sides. Cabinet outer-side holes
// still obey adjustable_shelf_hole_type (through/blind).
module door_hinge_partition_shelf_pin_holes_3d(x0) {
    if (shelf_style == "adjustable")
        for (row=[0:1])
            for (i=[0:shelf_pin_count()-1])
                round_hole_x_3d(
                    x0-1,
                    shelf_pin_y(row),
                    shelf_pin_z(i),
                    material_thickness+2,
                    adjustable_shelf_hole_diameter
                );
}

// Structural rear stretchers cross the partition near the cabinet back.
// Open rear notches let the full-depth partition reach the back plane without
// colliding with those horizontal members.
module door_hinge_partition_back_stretcher_notches_3d(x0) {
    if (back_style == "stretchers") {
        c = max(0,joint_fit_clearance);

        for (b=[0:back_stretcher_count-1])
            translate([
                x0-1,
                back_stretcher_y-c/2,
                back_stretcher_z(b)-c/2
            ])
                cube([
                    material_thickness+2,
                    resolved_cabinet_depth-back_stretcher_y+c/2+1,
                    back_stretcher_height+c
                ]);
    }
}

module door_hinge_partition_3d(p=0) {
    x0 = door_hinge_partition_x(p);
    z0 = door_hinge_partition_bottom_z();
    z1 = door_hinge_partition_top_z();
    bh = door_hinge_partition_body_height();

    difference() {
        union() {
            sheet_box(
                [
                    material_thickness,
                    door_hinge_partition_actual_depth,
                    bh
                ],
                [x0,0,z0]
            );

            door_hinge_partition_bottom_joinery_3d(x0,z0);
            door_hinge_partition_top_joinery_3d(x0,z1);
        }

        door_hinge_partition_plate_holes_3d(x0);
        door_hinge_partition_fixed_shelf_notches_3d(x0);
        door_hinge_partition_shelf_pin_holes_3d(x0);
        door_hinge_partition_back_stretcher_notches_3d(x0);
    }
}

module door_hinge_partition_joinery_segment_cut(
    x0,span,y0,edge_height
) {
    if (span > 0) {
        if (joinery_style == "dado") {
            translate([x0,y0])
                cut_part(
                    span,
                    door_hinge_partition_dado_depth()
                );
        }
        else if (joinery_style == "tab_slot") {
            for (n=[0:effective_tab_count(span)-1])
                translate([
                    x0+tab_start(span,n),
                    y0
                ])
                    cut_part(
                        tab_width_for(span),
                        material_thickness
                    );
        }
    }
}

module door_hinge_partition_bottom_joinery_cut() {
    ext = door_hinge_partition_cut_body_offset();

    if (joinery_style == "dado")
        door_hinge_partition_joinery_segment_cut(
            0,
            door_hinge_partition_actual_depth,
            0,
            ext);
    else if (joinery_style == "tab_slot")
        door_hinge_partition_joinery_segment_cut(
            0,
            door_hinge_partition_actual_depth,
            0,
            ext);
}

module door_hinge_partition_top_joinery_cut(body_top_y) {
    if (cabinet_contents == "combo") {
        span =
            min(
                door_hinge_partition_actual_depth,
                shelf_depth
            );

        door_hinge_partition_joinery_segment_cut(
            0,span,body_top_y,0);
    }
    else if (top_style == "full") {
        door_hinge_partition_joinery_segment_cut(
            0,
            door_hinge_partition_actual_depth,
            body_top_y,
            0);
    }
    else {
        front_span =
            min(
                door_hinge_partition_actual_depth,
                top_stretcher_depth
            );

        if (front_span > 0)
            door_hinge_partition_joinery_segment_cut(
                0,front_span,body_top_y,0);

        rear_start =
            max(0,resolved_cabinet_depth-top_stretcher_depth);

        rear_span =
            max(
                0,
                min(
                    door_hinge_partition_actual_depth,
                    resolved_cabinet_depth
                )-rear_start
            );

        if (rear_span > 0)
            door_hinge_partition_joinery_segment_cut(
                rear_start,
                rear_span,
                body_top_y,
                0);
    }
}

module door_hinge_partition_cut() {
    bh = door_hinge_partition_body_height();
    body_offset = door_hinge_partition_cut_body_offset();
    cut_z0 = door_hinge_partition_cut_global_bottom_z();

    difference() {
        union() {
            translate([0,body_offset])
                cut_part(
                    door_hinge_partition_actual_depth,
                    bh
                );

            door_hinge_partition_bottom_joinery_cut();
            door_hinge_partition_top_joinery_cut(
                body_offset+bh);
        }

        // Hinge mounting-plate holes.
        if (effective_hinge_style != "none")
            for (j=[0:hinge_count-1])
                if (hinge_plate_holes_enabled)
                for (dz=[
                    -effective_hinge_plate_hole_spacing/2,
                    effective_hinge_plate_hole_spacing/2
                ])
                    round_hole_2d(
                        effective_hinge_plate_center_from_front,
                        hinge_z(j)+dz-cut_z0,
                        effective_hinge_plate_hole_diameter
                    );

        // Fixed-shelf cross-lap notches.
        if (shelf_style == "fixed" && door_shelf_count > 0) {
            c = max(0,door_hinge_partition_shelf_clearance);
            notch_depth =
                min(
                    shelf_depth,
                    door_hinge_partition_actual_depth
                );

            for (s=[1:door_shelf_count])
                translate([
                    shelf_front_y-0.01,
                    door_shelf_z(s)-cut_z0-c/2
                ])
                    square([
                        notch_depth+0.02,
                        material_thickness+c
                    ]);
        }

        // Through shelf-pin holes serve both faces of an internal partition.
        if (shelf_style == "adjustable")
            for (row=[0:1])
                for (i=[0:shelf_pin_count()-1])
                    round_hole_2d(
                        shelf_pin_y(row),
                        shelf_pin_z(i)-cut_z0,
                        adjustable_shelf_hole_diameter
                    );

        // Open rear notches for structural back stretchers.
        if (back_style == "stretchers") {
            c = max(0,joint_fit_clearance);

            for (b=[0:back_stretcher_count-1])
                translate([
                    back_stretcher_y-c/2,
                    back_stretcher_z(b)-cut_z0-c/2
                ])
                    square([
                        door_hinge_partition_actual_depth
                            - back_stretcher_y
                            + c/2 + 0.02,
                        back_stretcher_height+c
                    ]);
        }
    }
}


// ---------------------------
// MIXED-BAY FULL-DEPTH PARTITIONS
// ---------------------------

module mixed_bay_partition_receiver_cuts_3d(
    panel_y0,panel_depth,z0,receiver_face="top"
) {
    if (mixed_bay_partition_count() > 0) {
        ov = mixed_bay_depth_overlap_length(panel_y0,panel_depth);
        ov0 = mixed_bay_depth_overlap_start(panel_y0);

        if (ov > 0)
            for (p=[0:mixed_bay_partition_count()-1]) {
                px = mixed_bay_partition_x(p);

                if (joinery_style == "dado") {
                    c = dado_fit_clearance;
                    dd = mixed_bay_partition_dado_depth();
                    zcut =
                        receiver_face == "top"
                            ? z0 + material_thickness-dd-0.01
                            : z0-0.01;

                    translate([px-c/2,ov0-c/2,zcut])
                        cube([
                            material_thickness+c,
                            ov+c,
                            dd+0.02
                        ]);
                }
                else if (joinery_style == "tab_slot") {
                    c = joint_fit_clearance;

                    for (n=[0:effective_tab_count(ov)-1]) {
                        yy = ov0+tab_start(ov,n)-c/2;
                        hh = tab_width_for(ov)+c;

                        slot_cut_z_3d(
                            px-c/2,
                            yy,
                            z0-1,
                            material_thickness+2,
                            material_thickness+c,
                            hh
                        );
                    }
                }
            }
    }
}

module mixed_bay_partition_receiver_through_2d(
    panel_y0,panel_depth
) {
    if (mixed_bay_partition_count() > 0
        && joinery_style == "tab_slot") {

        c = joint_fit_clearance;
        ov = mixed_bay_depth_overlap_length(panel_y0,panel_depth);
        ov0 = mixed_bay_depth_overlap_start(panel_y0);

        if (ov > 0)
            for (p=[0:mixed_bay_partition_count()-1]) {
                lx = horizontal_panel_local_x(mixed_bay_partition_x(p))-c/2;
                ly0 = ov0-panel_y0;

                for (n=[0:effective_tab_count(ov)-1]) {
                    yy = ly0+tab_start(ov,n)-c/2;
                    hh = tab_width_for(ov)+c;

                    translate([lx,yy])
                        slot_shape_2d(material_thickness+c,hh);
                }
            }
    }
}

module mixed_bay_partition_receiver_dado_pockets_2d(
    panel_y0,panel_depth
) {
    if (mixed_bay_partition_count() > 0
        && joinery_style == "dado") {

        c = dado_fit_clearance;
        ov = mixed_bay_depth_overlap_length(panel_y0,panel_depth);
        ov0 = mixed_bay_depth_overlap_start(panel_y0);

        if (ov > 0)
            for (p=[0:mixed_bay_partition_count()-1]) {
                lx = horizontal_panel_local_x(mixed_bay_partition_x(p))-c/2;
                ly = ov0-panel_y0-c/2;

                translate([lx,ly])
                    square([material_thickness+c,ov+c]);
            }
    }
}

module mixed_bay_partition_bottom_joinery_3d(x0,z0) {
    door_hinge_partition_joinery_segment_3d(
        x0,0,mixed_bay_partition_depth,z0,"bottom");
}

module mixed_bay_partition_top_joinery_3d(x0,z0) {
    if (top_style == "full") {
        door_hinge_partition_joinery_segment_3d(
            x0,0,mixed_bay_partition_depth,z0,"top");
    }
    else {
        front_span = min(mixed_bay_partition_depth,top_stretcher_depth);

        if (front_span > 0)
            door_hinge_partition_joinery_segment_3d(
                x0,0,front_span,z0,"top");

        rear_start = max(0,resolved_cabinet_depth-top_stretcher_depth);
        rear_span =
            max(
                0,
                min(mixed_bay_partition_depth,resolved_cabinet_depth)-rear_start
            );

        if (rear_span > 0)
            door_hinge_partition_joinery_segment_3d(
                x0,rear_start,rear_span,z0,"top");
    }
}

// Fixed shelves terminate into the vertical support on each side of a mixed
// bay. Internal partitions can therefore receive shelf joinery from either
// face at independently chosen shelf elevations.
module mixed_bay_partition_fixed_shelf_cuts_3d(x0,p=0) {
    c = joinery_style == "dado" ? dado_fit_clearance : joint_fit_clearance;
    dd = mixed_bay_fixed_shelf_dado_depth();

    for (bb=[p,p+1])
        if (mixed_bay_has_fixed_shelves(bb))
            for (s=[1:mixed_bay_shelf_count(bb)]) {
                zz = mixed_bay_shelf_z(bb,s);

                if (joinery_style == "dado") {
                    // Bay p approaches this partition from the left; bay p+1
                    // approaches it from the right.
                    xx = bb == p
                        ? x0-0.01
                        : x0+material_thickness-dd-0.01;

                    translate([xx,shelf_front_y-c/2,zz-c/2])
                        cube([
                            dd+0.02,
                            shelf_depth+c,
                            material_thickness+c
                        ]);
                }
                else if (joinery_style == "tab_slot") {
                    for (n=[0:tab_count_for_location(shelf_depth,"shelf")-1]) {
                        sy = shelf_front_y+tab_start_for_location(shelf_depth,n,"shelf")-c/2;
                        sw = tab_width_for(shelf_depth)+c;

                        slot_cut_x_3d(
                            x0-1,
                            material_thickness+2,
                            sy,
                            zz-c/2,
                            sw,
                            material_thickness+c
                        );
                    }
                }
            }
}

module mixed_bay_partition_fixed_shelf_through_2d(p=0) {
    c = joint_fit_clearance;
    cut_z0 = mixed_bay_partition_cut_global_bottom_z();

    if (joinery_style == "tab_slot")
        for (bb=[p,p+1])
            if (mixed_bay_has_fixed_shelves(bb))
                for (s=[1:mixed_bay_shelf_count(bb)])
                    for (n=[0:tab_count_for_location(shelf_depth,"shelf")-1]) {
                        sy = shelf_front_y+tab_start_for_location(shelf_depth,n,"shelf")-c/2;
                        sw = tab_width_for(shelf_depth)+c;

                        translate([
                            sy,
                            mixed_bay_shelf_z(bb,s)-cut_z0-c/2
                        ])
                            slot_shape_2d(
                                sw,
                                material_thickness+c
                            );
                    }
}

module mixed_bay_partition_fixed_shelf_butt_registration_2d(p=0) {
    cut_z0 = mixed_bay_partition_cut_global_bottom_z();

    if (joinery_style == "butt" && include_butt_registration_holes)
        for (bb=[p,p+1])
            if (mixed_bay_has_fixed_shelves(bb))
                for (s=[1:mixed_bay_shelf_count(bb)])
                    for (n=[0:butt_reg_count(shelf_depth)-1])
                        round_hole_2d(
                            shelf_front_y+butt_reg_pos(shelf_depth,n),
                            mixed_bay_shelf_z(bb,s)
                                + material_thickness/2
                                - cut_z0,
                            butt_registration_hole_diameter
                        );
}

// face = "left" means the shelf in bay p enters the left face of partition p.
// face = "right" means the shelf in bay p+1 enters the right face.
module mixed_bay_partition_fixed_shelf_dado_pockets_2d(
    p=0,face="both"
) {
    c = dado_fit_clearance;
    cut_z0 = mixed_bay_partition_cut_global_bottom_z();

    if (joinery_style == "dado")
        for (bb=[p,p+1]) {
            selected =
                face == "both"
                || (face == "left" && bb == p)
                || (face == "right" && bb == p+1);

            if (selected && mixed_bay_has_fixed_shelves(bb))
                for (s=[1:mixed_bay_shelf_count(bb)])
                    translate([
                        shelf_front_y-c/2,
                        mixed_bay_shelf_z(bb,s)-cut_z0-c/2
                    ])
                        square([
                            shelf_depth+c,
                            material_thickness+c
                        ]);
        }
}

module mixed_bay_partition_fixed_shelf_butt_registration_3d(x0,p=0) {
    if (joinery_style == "butt" && include_butt_registration_holes)
        for (bb=[p,p+1])
            if (mixed_bay_has_fixed_shelves(bb))
                for (s=[1:mixed_bay_shelf_count(bb)])
                    for (n=[0:butt_reg_count(shelf_depth)-1])
                        round_hole_x_3d(
                            x0-1,
                            shelf_front_y+butt_reg_pos(shelf_depth,n),
                            mixed_bay_shelf_z(bb,s)
                                + material_thickness/2,
                            material_thickness+2,
                            butt_registration_hole_diameter
                        );
}

module mixed_bay_partition_hardware_holes_3d(x0,p=0) {
    if (mixed_bay_partition_has_hinge_plates(p))
        for (j=[0:hinge_count-1])
            if (hinge_plate_holes_enabled)
            for (dz=[
                -effective_hinge_plate_hole_spacing/2,
                effective_hinge_plate_hole_spacing/2
            ])
                round_hole_x_3d(
                    x0-1,
                    effective_hinge_plate_center_from_front,
                    mixed_bay_hinge_z(j)+dz,
                    material_thickness+2,
                    effective_hinge_plate_hole_diameter
                );

    if (mixed_bay_partition_has_shelf_pins(p))
        for (row=[0:1])
            for (i=[0:mixed_bay_shelf_pin_count()-1])
                round_hole_x_3d(
                    x0-1,
                    shelf_pin_y(row),
                    mixed_bay_shelf_pin_z(i),
                    material_thickness+2,
                    adjustable_shelf_hole_diameter
                );

    // Drawer slide patterns from both neighboring bays share this partition.
    for (bb=[p,p+1]) {
        if (mixed_bay_is_type(bb,"drawers")
            && drawer_mount == "wood_rails"
            && include_wood_slide_registration_holes)
            for (i=[0:drawer_bank_drawer_count(bb)-1])
                for (n=[0:wood_slide_registration_hole_count-1])
                    round_hole_x_3d(
                        x0-1,
                        effective_wood_rail_front_setback
                            + wood_slide_reg_pos(resolved_wood_rail_depth,n),
                        drawer_rail_z(i,bb)+wood_rail_height/2,
                        material_thickness+2,
                        wood_slide_registration_hole_diameter
                    );

        if (mixed_bay_is_type(bb,"drawers")
            && drawer_mount == "metal_slides"
            && include_metal_slide_holes)
            for (i=[0:drawer_bank_drawer_count(bb)-1]) {
                hz = drawer_box_z(i,bb) + effective_metal_slide_cabinet_hole_z;

                for (hx=active_slide_cabinet_holes())
                    if (cabinet_slide_hole_is_valid(hx,resolved_cabinet_depth))
                        round_hole_x_3d(x0-1,slide_cabinet_hole_depth(hx),hz,material_thickness+2,effective_metal_slide_cabinet_hole_diameter);
            }
    }
}

module mixed_bay_partition_3d(p=0) {
    x0 = mixed_bay_partition_x(p);
    z0 = mixed_bay_partition_bottom_z();
    z1 = mixed_bay_partition_top_z();
    bh = mixed_bay_partition_body_height();

    difference() {
        union() {
            sheet_box(
                [material_thickness,mixed_bay_partition_depth,bh],
                [x0,0,z0]
            );

            mixed_bay_partition_bottom_joinery_3d(x0,z0);
            mixed_bay_partition_top_joinery_3d(x0,z1);
        }

        mixed_bay_partition_hardware_holes_3d(x0,p);
        mixed_bay_partition_fixed_shelf_cuts_3d(x0,p);
        mixed_bay_partition_fixed_shelf_butt_registration_3d(x0,p);
        door_hinge_partition_back_stretcher_notches_3d(x0);
    }
}

module mixed_bay_partition_bottom_joinery_cut() {
    ext = mixed_bay_partition_cut_body_offset();

    if (joinery_style == "dado" || joinery_style == "tab_slot")
        door_hinge_partition_joinery_segment_cut(
            0,mixed_bay_partition_depth,0,ext);
}

module mixed_bay_partition_top_joinery_cut(body_top_y) {
    if (top_style == "full") {
        door_hinge_partition_joinery_segment_cut(
            0,mixed_bay_partition_depth,body_top_y,0);
    }
    else {
        front_span = min(mixed_bay_partition_depth,top_stretcher_depth);

        if (front_span > 0)
            door_hinge_partition_joinery_segment_cut(
                0,front_span,body_top_y,0);

        rear_start = max(0,resolved_cabinet_depth-top_stretcher_depth);
        rear_span =
            max(
                0,
                min(mixed_bay_partition_depth,resolved_cabinet_depth)-rear_start
            );

        if (rear_span > 0)
            door_hinge_partition_joinery_segment_cut(
                rear_start,rear_span,body_top_y,0);
    }
}

module mixed_bay_partition_cut(p=0) {
    bh = mixed_bay_partition_body_height();
    body_offset = mixed_bay_partition_cut_body_offset();
    cut_z0 = mixed_bay_partition_cut_global_bottom_z();

    difference() {
        union() {
            translate([0,body_offset])
                cut_part(mixed_bay_partition_depth,bh);

            mixed_bay_partition_bottom_joinery_cut();
            mixed_bay_partition_top_joinery_cut(body_offset+bh);
        }

        if (mixed_bay_partition_has_hinge_plates(p))
            for (j=[0:hinge_count-1])
                if (hinge_plate_holes_enabled)
                for (dz=[
                    -effective_hinge_plate_hole_spacing/2,
                    effective_hinge_plate_hole_spacing/2
                ])
                    round_hole_2d(
                        effective_hinge_plate_center_from_front,
                        mixed_bay_hinge_z(j)+dz-cut_z0,
                        effective_hinge_plate_hole_diameter
                    );

        if (mixed_bay_partition_has_shelf_pins(p))
            for (row=[0:1])
                for (i=[0:mixed_bay_shelf_pin_count()-1])
                    round_hole_2d(
                        shelf_pin_y(row),
                        mixed_bay_shelf_pin_z(i)-cut_z0,
                        adjustable_shelf_hole_diameter
                    );

        mixed_bay_partition_fixed_shelf_through_2d(p);
        mixed_bay_partition_fixed_shelf_butt_registration_2d(p);

        for (bb=[p,p+1]) {
            if (mixed_bay_is_type(bb,"drawers")
                && drawer_mount == "wood_rails"
                && include_wood_slide_registration_holes)
                for (i=[0:drawer_bank_drawer_count(bb)-1])
                    for (n=[0:wood_slide_registration_hole_count-1])
                        round_hole_2d(
                            effective_wood_rail_front_setback
                                + wood_slide_reg_pos(resolved_wood_rail_depth,n),
                            drawer_rail_z(i,bb)+wood_rail_height/2-cut_z0,
                            wood_slide_registration_hole_diameter
                        );

            if (mixed_bay_is_type(bb,"drawers")
                && drawer_mount == "metal_slides"
                && include_metal_slide_holes)
                for (i=[0:drawer_bank_drawer_count(bb)-1]) {
                    hz = drawer_box_z(i,bb) + effective_metal_slide_cabinet_hole_z;

                    for (hx=active_slide_cabinet_holes())
                        if (cabinet_slide_hole_is_valid(hx,resolved_cabinet_depth))
                            round_hole_2d(slide_cabinet_hole_depth(hx),hz-cut_z0,effective_metal_slide_cabinet_hole_diameter);
                }
        }

        if (back_style == "stretchers") {
            c = max(0,joint_fit_clearance);

            for (b=[0:back_stretcher_count-1])
                translate([
                    back_stretcher_y-c/2,
                    back_stretcher_z(b)-cut_z0-c/2
                ])
                    square([
                        mixed_bay_partition_depth-back_stretcher_y+c/2+0.02,
                        back_stretcher_height+c
                    ]);
        }
    }
}

module mixed_bay_fixed_shelf_3d(b=0,z0=0) {
    x0 = mixed_bay_opening_x(b);
    ww = mixed_bay_opening_width(b);

    if (joinery_style == "butt") {
        sheet_box([ww,shelf_depth,material_thickness],[x0,shelf_front_y,z0]);
    }
    else if (joinery_style == "dado") {
        dd = mixed_bay_fixed_shelf_dado_depth();
        sheet_box(
            [ww+2*dd,shelf_depth,material_thickness],
            [x0-dd,shelf_front_y,z0]
        );
    }
    else if (joinery_style == "tab_slot") {
        union() {
            sheet_box([ww,shelf_depth,material_thickness],[x0,shelf_front_y,z0]);

            for (n=[0:tab_count_for_location(shelf_depth,"shelf")-1]) {
                yy = tab_start_for_location(shelf_depth,n,"shelf");
                tw = tab_width_for(shelf_depth);

                sheet_box(
                    [material_thickness,tw,material_thickness],
                    [x0-material_thickness,shelf_front_y+yy,z0]
                );
                sheet_box(
                    [material_thickness,tw,material_thickness],
                    [x0+ww,shelf_front_y+yy,z0]
                );
            }
        }
    }
}

module mixed_bay_fixed_shelf_cut(b=0) {
    ww = mixed_bay_opening_width(b);

    if (joinery_style == "butt") {
        cut_part(ww,shelf_depth);
    }
    else if (joinery_style == "dado") {
        cut_part(
            ww+2*mixed_bay_fixed_shelf_dado_depth(),
            shelf_depth
        );
    }
    else if (joinery_style == "tab_slot") {
        union() {
            translate([material_thickness,0])
                cut_part(ww,shelf_depth);

            for (n=[0:tab_count_for_location(shelf_depth,"shelf")-1]) {
                yy = tab_start_for_location(shelf_depth,n,"shelf");
                tw = tab_width_for(shelf_depth);

                translate([0,yy])
                    cut_part(material_thickness,tw);
                translate([material_thickness+ww,yy])
                    cut_part(material_thickness,tw);
            }
        }
    }
}

module mixed_bay_adjustable_shelf_3d(b=0,z0=0) {
    sheet_box(
        [
            mixed_bay_adjustable_shelf_width(b),
            shelf_depth,
            material_thickness
        ],
        [mixed_bay_adjustable_shelf_x(b),shelf_front_y,z0]
    );
}

module mixed_bay_adjustable_shelf_cut(b=0) {
    cut_part(mixed_bay_adjustable_shelf_width(b),shelf_depth);
}

// Wrapper horizontal carcass member. It can receive both drawer-bank
// partitions and door-hinge partitions. For the combo divider the two systems
// enter opposite faces, so door_receiver_face can differ from receiver_face.
module joined_horizontal_bank_receiver_3d(
    y0,depth,z0,receiver_face="top",door_receiver_face="same",
    tab_location="default"
) {
    actual_door_face =
        door_receiver_face == "same"
            ? receiver_face
            : door_receiver_face;

    difference() {
        joined_horizontal_panel_3d(y0,depth,z0,tab_location);

        drawer_bank_receiver_cuts_3d(
            y0,depth,z0,receiver_face);

        door_hinge_partition_receiver_cuts_3d(
            y0,depth,z0,actual_door_face);

        mixed_bay_partition_receiver_cuts_3d(
            y0,depth,z0,receiver_face);

        back_horizontal_receiver_cuts_3d(
            y0,depth,z0,receiver_face);
    }
}

module joined_horizontal_bank_receiver_cut(
    panel_y0,depth,tab_location="default"
) {
    difference() {
        joined_horizontal_panel_cut(depth,tab_location);
        drawer_bank_receiver_through_2d(panel_y0,depth);
        door_hinge_partition_receiver_through_2d(
            panel_y0,depth);
        mixed_bay_partition_receiver_through_2d(
            panel_y0,depth);
        back_horizontal_receiver_through_2d(
            panel_y0,depth);
    }
}


// Bottom wrapper. In full-width mode the side panels sit on the top surface,
// while internal partition joinery remains active.
module cabinet_bottom_3d() {
    if (full_width_bottom_active) {
        difference() {
            sheet_box(
                [resolved_cabinet_width,resolved_cabinet_depth,material_thickness],
                [0,0,bottom_above_toe]
            );

            drawer_bank_receiver_cuts_3d(
                0,resolved_cabinet_depth,bottom_above_toe,"top");
            door_hinge_partition_receiver_cuts_3d(
                0,resolved_cabinet_depth,bottom_above_toe,"top");
            mixed_bay_partition_receiver_cuts_3d(
                0,resolved_cabinet_depth,bottom_above_toe,"top");
            back_horizontal_receiver_cuts_3d(
                0,resolved_cabinet_depth,bottom_above_toe,"top");
        }
    }
    else
        joined_horizontal_bank_receiver_3d(
            0,resolved_cabinet_depth,bottom_above_toe,"top","same","bottom");
}

module cabinet_bottom_cut() {
    if (full_width_bottom_active) {
        difference() {
            cut_part(resolved_cabinet_width,resolved_cabinet_depth);

            translate([bottom_receiver_x_shift,0]) {
                drawer_bank_receiver_through_2d(
                    0,resolved_cabinet_depth);
                door_hinge_partition_receiver_through_2d(
                    0,resolved_cabinet_depth);
                mixed_bay_partition_receiver_through_2d(
                    0,resolved_cabinet_depth);
            }

            back_horizontal_receiver_through_2d(
                0,
                resolved_cabinet_depth,
                bottom_panel_global_x0
            );
        }
    }
    else
        joined_horizontal_bank_receiver_cut(
            0,resolved_cabinet_depth,"bottom");
}

module bottom_drawer_bank_receiver_dado_pockets_2d() {
    translate([bottom_receiver_x_shift,0])
        drawer_bank_receiver_dado_pockets_2d(
            0,resolved_cabinet_depth);
}

module bottom_door_hinge_partition_receiver_dado_pockets_2d() {
    translate([bottom_receiver_x_shift,0])
        door_hinge_partition_receiver_dado_pockets_2d(
            0,resolved_cabinet_depth);
}

module bottom_mixed_bay_partition_receiver_dado_pockets_2d() {
    translate([bottom_receiver_x_shift,0])
        mixed_bay_partition_receiver_dado_pockets_2d(
            0,resolved_cabinet_depth);
}

module bottom_back_receiver_dado_pockets_2d() {
    back_horizontal_dado_pocket_2d(
        0,
        resolved_cabinet_depth,
        bottom_panel_global_x0
    );
}

module drawer_bank_partition_bottom_tabs_3d(x0,z0) {
    span = min(drawer_bank_partition_depth,
               cabinet_contents == "combo" ? shelf_depth : resolved_cabinet_depth);

    for (n=[0:effective_tab_count(span)-1]) {
        yy = tab_start(span,n);
        th = tab_width_for(span);
        sheet_box(
            [material_thickness,th,material_thickness],
            [x0,yy,z0-material_thickness]
        );
    }
}

module drawer_bank_partition_top_tabs_3d(x0,z0) {
    if (top_style == "full") {
        span = drawer_bank_partition_depth;
        for (n=[0:effective_tab_count(span)-1]) {
            yy = tab_start(span,n);
            th = tab_width_for(span);
            sheet_box(
                [material_thickness,th,material_thickness],
                [x0,yy,z0]
            );
        }
    } else {
        front_span = min(drawer_bank_partition_depth,top_stretcher_depth);
        if (front_span > 0)
            for (n=[0:effective_tab_count(front_span)-1]) {
                yy = tab_start(front_span,n);
                th = tab_width_for(front_span);
                sheet_box(
                    [material_thickness,th,material_thickness],
                    [x0,yy,z0]
                );
            }

        rear_start = max(0,resolved_cabinet_depth-top_stretcher_depth);
        rear_span = max(0,drawer_bank_partition_depth-rear_start);
        if (rear_span > 0)
            for (n=[0:effective_tab_count(rear_span)-1]) {
                yy = rear_start + tab_start(rear_span,n);
                th = tab_width_for(rear_span);
                sheet_box(
                    [material_thickness,th,material_thickness],
                    [x0,yy,z0]
                );
            }
    }
}

module drawer_bank_partition_slide_holes_3d(x0,z_start,p=0) {
    // A partition borders bank p on its left and bank p+1 on its right.
    // Registration holes are through-features, so include the union of both
    // adjacent banks' vertical patterns when their drawer stacks differ.
    for (bb=[p,p+1]) {
        if (drawer_mount == "wood_rails"
            && include_wood_slide_registration_holes) {
            for (i=[0:drawer_bank_drawer_count(bb)-1])
                for (n=[0:wood_slide_registration_hole_count-1])
                    round_hole_x_3d(
                        x0-1,
                        effective_wood_rail_front_setback
                            + wood_slide_reg_pos(resolved_wood_rail_depth,n),
                        drawer_rail_z(i,bb)+wood_rail_height/2,
                        material_thickness+2,
                        wood_slide_registration_hole_diameter
                    );
        }

        if (drawer_mount == "metal_slides"
            && include_metal_slide_holes) {
            for (i=[0:drawer_bank_drawer_count(bb)-1]) {
                hz = drawer_box_z(i,bb) + effective_metal_slide_cabinet_hole_z;

                for (hx=active_slide_cabinet_holes())
                    if (cabinet_slide_hole_is_valid(hx,resolved_cabinet_depth))
                        round_hole_x_3d(x0-1,slide_cabinet_hole_depth(hx),hz,material_thickness+2,effective_metal_slide_cabinet_hole_diameter);
            }
        }
    }
}


module drawer_bank_partition_3d(p=0) {
    mode = drawer_bank_partition_joinery_mode();
    dd = drawer_bank_partition_dado_depth();
    x0 = drawer_bank_partition_x(p);
    z0 = drawer_bank_partition_bottom_z();
    z1 = drawer_bank_partition_top_z();
    bh = drawer_bank_partition_body_height();

    difference() {
        union() {
            if (mode == "dado") {
                sheet_box(
                    [material_thickness,drawer_bank_partition_depth,bh+2*dd],
                    [x0,0,z0-dd]
                );
            }
            else {
                sheet_box(
                    [material_thickness,drawer_bank_partition_depth,bh],
                    [x0,0,z0]
                );

                if (mode == "tab_slot") {
                    drawer_bank_partition_bottom_tabs_3d(x0,z0);
                    drawer_bank_partition_top_tabs_3d(x0,z1);
                }
            }
        }

        drawer_bank_partition_slide_holes_3d(x0,z0,p);
    }
}

module drawer_bank_partition_cut(p=0) {
    mode = drawer_bank_partition_joinery_mode();
    dd = drawer_bank_partition_dado_depth();
    bh = drawer_bank_partition_body_height();
    bottom_extra = mode == "tab_slot" ? material_thickness : 0;

    difference() {
        union() {
            if (mode == "dado") {
                cut_part(
                    drawer_bank_partition_depth,
                    bh+2*dd
                );
            }
            else {
                translate([0,bottom_extra])
                    cut_part(drawer_bank_partition_depth,bh);

                if (mode == "tab_slot") {
                    bottom_span = min(
                        drawer_bank_partition_depth,
                        cabinet_contents == "combo" ? shelf_depth : resolved_cabinet_depth);

                    for (n=[0:effective_tab_count(bottom_span)-1])
                        translate([tab_start(bottom_span,n),0])
                            cut_part(
                                tab_width_for(bottom_span),
                                material_thickness
                            );

                    top_y = bottom_extra+bh;
                    if (top_style == "full") {
                        span = drawer_bank_partition_depth;
                        for (n=[0:effective_tab_count(span)-1])
                            translate([tab_start(span,n),top_y])
                                cut_part(
                                    tab_width_for(span),
                                    material_thickness
                                );
                    } else {
                        front_span = min(
                            drawer_bank_partition_depth,
                            top_stretcher_depth);
                        if (front_span > 0)
                            for (n=[0:effective_tab_count(front_span)-1])
                                translate([
                                    tab_start(front_span,n),top_y])
                                    cut_part(
                                        tab_width_for(front_span),
                                        material_thickness
                                    );

                        rear_start = max(
                            0,resolved_cabinet_depth-top_stretcher_depth);
                        rear_span = max(
                            0,drawer_bank_partition_depth-rear_start);
                        if (rear_span > 0)
                            for (n=[0:effective_tab_count(rear_span)-1])
                                translate([
                                    rear_start+tab_start(rear_span,n),top_y])
                                    cut_part(
                                        tab_width_for(rear_span),
                                        material_thickness
                                    );
                    }
                }
            }
        }

        // Through registration holes for both adjacent drawer banks.
        z_local_base = mode == "dado" ? dd : bottom_extra;

        for (bb=[p,p+1]) {
            if (drawer_mount == "wood_rails"
                && include_wood_slide_registration_holes)
                for (i=[0:drawer_bank_drawer_count(bb)-1])
                    for (n=[0:wood_slide_registration_hole_count-1])
                        round_hole_2d(
                            effective_wood_rail_front_setback
                                + wood_slide_reg_pos(resolved_wood_rail_depth,n),
                            z_local_base
                                + drawer_rail_z(i,bb)
                                + wood_rail_height/2
                                - drawer_bank_partition_bottom_z(),
                            wood_slide_registration_hole_diameter
                        );

            if (drawer_mount == "metal_slides"
                && include_metal_slide_holes)
                for (i=[0:drawer_bank_drawer_count(bb)-1]) {
                    hz = drawer_box_z(i,bb) + effective_metal_slide_cabinet_hole_z;

                    for (hx=active_slide_cabinet_holes())
                        if (cabinet_slide_hole_is_valid(hx,resolved_cabinet_depth))
                            round_hole_2d(slide_cabinet_hole_depth(hx),z_local_base+hz-drawer_bank_partition_bottom_z(),effective_metal_slide_cabinet_hole_diameter);
                }
        }
    }
}

// Toe-kick rail is a vertical cross-panel in the X/Z plane.
module joined_toe_kick_3d() {
    if (has_toe_kick && joinery_style == "butt") {
        sheet_box([inner_width,material_thickness,toe_kick_height],
                  [material_thickness,toe_kick_setback,0]);
    }
    else if (has_toe_kick && joinery_style == "dado") {
        dd = effective_dado_depth();
        sheet_box([inner_width+2*dd,material_thickness,toe_kick_height],
                  [material_thickness-dd,toe_kick_setback,0]);
    }
    else if (has_toe_kick && joinery_style == "tab_slot") {
        union() {
            sheet_box([inner_width,material_thickness,toe_kick_height],
                      [material_thickness,toe_kick_setback,0]);

            for (i=[0:effective_tab_count(toe_kick_height)-1]) {
                tz = tab_start(toe_kick_height,i);
                tw = tab_width_for(toe_kick_height);

                sheet_box([material_thickness,material_thickness,tw],
                          [0,toe_kick_setback,tz]);
                sheet_box([material_thickness,material_thickness,tw],
                          [resolved_cabinet_width-material_thickness,toe_kick_setback,tz]);
            }
        }
    }
}

module joined_toe_kick_cut() {
    if (has_toe_kick && joinery_style == "butt") {
        cut_part(inner_width,toe_kick_height);
    }
    else if (has_toe_kick && joinery_style == "dado") {
        cut_part(inner_width+2*effective_dado_depth(),toe_kick_height);
    }
    else if (has_toe_kick && joinery_style == "tab_slot") {
        union() {
            translate([material_thickness,0])
                cut_part(inner_width,toe_kick_height);

            for (i=[0:effective_tab_count(toe_kick_height)-1]) {
                tz = tab_start(toe_kick_height,i);
                tw = tab_width_for(toe_kick_height);

                translate([0,tz])
                    cut_part(material_thickness,tw);
                translate([resolved_cabinet_width-material_thickness,tz])
                    cut_part(material_thickness,tw);
            }
        }
    }
}

// Structural rear stretcher: vertical cross-panel in the X/Z plane.
// It uses the same side-joinery style as the carcass.
module joined_back_stretcher_3d(z0) {
    if (joinery_style == "butt") {
        sheet_box(
            [inner_width,material_thickness,back_stretcher_height],
            [material_thickness,back_stretcher_y,z0]
        );
    }
    else if (joinery_style == "dado") {
        dd = effective_dado_depth();
        sheet_box(
            [
                inner_width+2*dd,
                material_thickness,
                back_stretcher_height
            ],
            [
                material_thickness-dd,
                back_stretcher_y,
                z0
            ]
        );
    }
    else if (joinery_style == "tab_slot") {
        union() {
            sheet_box(
                [
                    inner_width,
                    material_thickness,
                    back_stretcher_height
                ],
                [
                    material_thickness,
                    back_stretcher_y,
                    z0
                ]
            );

            for (i=[0:effective_tab_count(back_stretcher_height)-1]) {
                tz = z0 + tab_start(back_stretcher_height,i);
                tw = tab_width_for(back_stretcher_height);

                sheet_box(
                    [material_thickness,material_thickness,tw],
                    [0,back_stretcher_y,tz]
                );
                sheet_box(
                    [material_thickness,material_thickness,tw],
                    [
                        resolved_cabinet_width-material_thickness,
                        back_stretcher_y,
                        tz
                    ]
                );
            }
        }
    }
}

module joined_back_stretcher_cut() {
    if (joinery_style == "butt") {
        cut_part(inner_width,back_stretcher_height);
    }
    else if (joinery_style == "dado") {
        cut_part(
            inner_width+2*effective_dado_depth(),
            back_stretcher_height
        );
    }
    else if (joinery_style == "tab_slot") {
        union() {
            translate([material_thickness,0])
                cut_part(inner_width,back_stretcher_height);

            for (i=[0:effective_tab_count(back_stretcher_height)-1]) {
                tz = tab_start(back_stretcher_height,i);
                tw = tab_width_for(back_stretcher_height);

                translate([0,tz])
                    cut_part(material_thickness,tw);
                translate([resolved_cabinet_width-material_thickness,tz])
                    cut_part(material_thickness,tw);
            }
        }
    }
}

// Matching back-stretcher feature in a cabinet side.
module side_back_stretcher_joint_cut_3d(side,z0) {
    c =
        joinery_style == "dado"
            ? dado_fit_clearance
            : joint_fit_clearance;

    if (joinery_style == "dado") {
        dd = effective_dado_depth();

        if (side == "left")
            translate([
                material_thickness-dd,
                back_stretcher_y-c/2,
                z0-c/2
            ])
                cube([
                    dd+0.02,
                    material_thickness+c,
                    back_stretcher_height+c
                ]);
        else
            translate([
                resolved_cabinet_width-material_thickness-0.01,
                back_stretcher_y-c/2,
                z0-c/2
            ])
                cube([
                    dd+0.02,
                    material_thickness+c,
                    back_stretcher_height+c
                ]);
    }
    else if (joinery_style == "tab_slot") {
        for (i=[0:effective_tab_count(back_stretcher_height)-1]) {
            sy = back_stretcher_y-c/2;
            sw = material_thickness+c;
            sz = z0 + tab_start(back_stretcher_height,i)-c/2;
            sh = tab_width_for(back_stretcher_height)+c;

            rear_open = back_stretcher_inset <= 0.001;

            if (side == "left")
                slot_cut_x_3d(
                    -1,material_thickness+2,sy,sz,sw,sh,
                    false,rear_open,false,false);
            else
                slot_cut_x_3d(
                    resolved_cabinet_width-material_thickness-1,
                    material_thickness+2,sy,sz,sw,sh,
                    false,rear_open,false,false);
        }
    }
}




// Create one horizontal member's matching feature in a cabinet side.
module side_horizontal_joint_cut_3d(
    side,y0,panel_depth,z0,tab_location="default"
) {
    c =
        joinery_style == "dado"
            ? dado_fit_clearance
            : joint_fit_clearance;

    if (joinery_style == "dado") {
        dd = effective_dado_depth();

        if (side == "left")
            translate([material_thickness-dd,
                       y0-c/2,
                       z0-c/2])
                cube([dd+0.02,panel_depth+c,material_thickness+c]);
        else
            translate([resolved_cabinet_width-material_thickness-0.01,
                       y0-c/2,
                       z0-c/2])
                cube([dd+0.02,panel_depth+c,material_thickness+c]);
    }
    else if (joinery_style == "tab_slot") {
        tab_n = tab_count_for_location(panel_depth,tab_location);

        for (i=[0:tab_n-1]) {
            sy = y0 + tab_start_for_location(panel_depth,i,tab_location) - c/2;
            sw = tab_width_for(panel_depth) + c;
            sz = z0 - c/2;
            sh = material_thickness + c;

            // A slot that terminates at the physical panel perimeter already
            // has cutter access on that side. Do not add dogbone/T-bone relief
            // to those open corners. This matters especially for stackable
            // bottom tabs located in the raised front/rear stacking pads.
            nominal_sy = y0 + tab_start_for_location(panel_depth,i,tab_location);
            nominal_sw = tab_width_for(panel_depth);

            open_front = nominal_sy <= 0.001;
            open_rear = nominal_sy + nominal_sw
                >= resolved_cabinet_depth - 0.001;

            open_bottom =
                z0 <= side_panel_bottom_z + 0.001
                || (
                    stackable_mode
                    && tab_location == "bottom"
                    && abs(z0-effective_stack_interface_depth) <= 0.001
                    && (
                        nominal_sy + nominal_sw
                            <= effective_stack_front_margin + 0.001
                        || nominal_sy
                            >= resolved_cabinet_depth
                               - effective_stack_back_margin - 0.001
                    )
                );

            open_top = z0 + material_thickness
                >= cabinet_height - 0.001;

            if (side == "left")
                slot_cut_x_3d(
                    -1,material_thickness+2,sy,sz,sw,sh,
                    open_front,open_rear,open_bottom,open_top
                );
            else
                slot_cut_x_3d(
                    resolved_cabinet_width-material_thickness-1,
                    material_thickness+2,sy,sz,sw,sh,
                    open_front,open_rear,open_bottom,open_top
                );
        }
    }
}

// Matching toe-kick feature in a cabinet side.
module side_toe_joint_cut_3d(side) {
    c =
        joinery_style == "dado"
            ? dado_fit_clearance
            : joint_fit_clearance;

    if (has_toe_kick && joinery_style == "dado") {
        dd = effective_dado_depth();

        if (side == "left")
            translate([material_thickness-dd,
                       toe_kick_setback-c/2,
                       -c/2])
                cube([dd+0.02,
                      material_thickness+c,
                      toe_kick_height+c]);
        else
            translate([resolved_cabinet_width-material_thickness-0.01,
                       toe_kick_setback-c/2,
                       -c/2])
                cube([dd+0.02,
                      material_thickness+c,
                      toe_kick_height+c]);
    }
    else if (has_toe_kick && joinery_style == "tab_slot") {
        for (i=[0:effective_tab_count(toe_kick_height)-1]) {
            sy = toe_kick_setback - c/2;
            sw = material_thickness + c;
            sz = tab_start(toe_kick_height,i) - c/2;
            sh = tab_width_for(toe_kick_height) + c;

            front_open = toe_kick_setback <= 0.001;

            if (side == "left")
                slot_cut_x_3d(
                    -1,material_thickness+2,sy,sz,sw,sh,
                    front_open,false,false,false);
            else
                slot_cut_x_3d(
                    resolved_cabinet_width-material_thickness-1,
                    material_thickness+2,sy,sz,sw,sh,
                    front_open,false,false,false);
        }
    }
}

// ---------------------------
// BUTT-JOINT REGISTRATION HOLES
// ---------------------------

// Horizontal member: hole axis passes through the cabinet side (X direction)
// and points at the center of the mating panel edge.
module side_horizontal_butt_registration_3d(
    x0,y0,panel_depth,z0
) {
    if (joinery_style == "butt" && include_butt_registration_holes) {
        for (i=[0:butt_reg_count(panel_depth)-1]) {
            round_hole_x_3d(
                x0-1,
                y0+butt_reg_pos(panel_depth,i),
                z0+material_thickness/2,
                material_thickness+2,
                butt_registration_hole_diameter
            );
        }
    }
}

module side_horizontal_butt_registration_2d(
    y0,panel_depth,z0
) {
    if (joinery_style == "butt" && include_butt_registration_holes) {
        for (i=[0:butt_reg_count(panel_depth)-1]) {
            round_hole_2d(
                y0+butt_reg_pos(panel_depth,i),
                z0+material_thickness/2,
                butt_registration_hole_diameter
            );
        }
    }
}

// Toe-kick rail is vertical, so guide holes distribute along its height.
module side_toe_butt_registration_3d(x0) {
    if (has_toe_kick && joinery_style == "butt" && include_butt_registration_holes) {
        for (i=[0:butt_reg_count(toe_kick_height)-1]) {
            round_hole_x_3d(
                x0-1,
                toe_kick_setback+material_thickness/2,
                butt_reg_pos(toe_kick_height,i),
                material_thickness+2,
                butt_registration_hole_diameter
            );
        }
    }
}

module side_toe_butt_registration_2d() {
    if (has_toe_kick && joinery_style == "butt" && include_butt_registration_holes) {
        for (i=[0:butt_reg_count(toe_kick_height)-1]) {
            round_hole_2d(
                toe_kick_setback+material_thickness/2,
                butt_reg_pos(toe_kick_height,i),
                butt_registration_hole_diameter
            );
        }
    }
}


module side_back_stretcher_butt_registration_3d(x0,z0) {
    if (joinery_style == "butt" && include_butt_registration_holes) {
        for (i=[0:butt_reg_count(back_stretcher_height)-1]) {
            round_hole_x_3d(
                x0-1,
                back_stretcher_y+material_thickness/2,
                z0+butt_reg_pos(back_stretcher_height,i),
                material_thickness+2,
                butt_registration_hole_diameter
            );
        }
    }
}

module side_back_stretcher_butt_registration_2d(z0) {
    if (joinery_style == "butt" && include_butt_registration_holes) {
        for (i=[0:butt_reg_count(back_stretcher_height)-1]) {
            round_hole_2d(
                back_stretcher_y+material_thickness/2,
                z0+butt_reg_pos(back_stretcher_height,i),
                butt_registration_hole_diameter
            );
        }
    }
}


// Collect all butt-joint guide holes that belong to one cabinet side.
module all_side_butt_registration_3d(x0) {
    if (joinery_style == "butt" && include_butt_registration_holes) {
        // Bottom.
        if (!full_width_bottom_active)
            side_horizontal_butt_registration_3d(
                x0,0,resolved_cabinet_depth,bottom_above_toe);

        // Top/full or top stretchers.
        top_z = cabinet_height-material_thickness;

        if (top_style == "full") {
            side_horizontal_butt_registration_3d(
                x0,0,resolved_cabinet_depth,top_z);
        } else {
            side_horizontal_butt_registration_3d(
                x0,0,top_stretcher_depth,top_z);
            side_horizontal_butt_registration_3d(
                x0,
                resolved_cabinet_depth-top_stretcher_depth,
                top_stretcher_depth,
                top_z);
        }

        // Combo divider.
        if (!mixed_bay_mode
            && cabinet_contents == "combo"
            && door_region_height > material_thickness)
            side_horizontal_butt_registration_3d(
                x0,shelf_front_y,shelf_depth,combo_divider_bottom_z);

        // Fixed shelves.
        if (!mixed_bay_mode
            && has_doors
            && shelf_style == "fixed"
            && door_shelf_count > 0
            && door_region_height > 60)
            for (s=[1:door_shelf_count])
                side_horizontal_butt_registration_3d(
                    x0,shelf_front_y,shelf_depth,door_shelf_z(s));

        // Optional drawer separators.
        if (drawer_separator_count > 0)
            for (s=[0:drawer_separator_count-1]) {
                sep_z = drawer_separator_z(s);

                if (drawer_separator_style == "full") {
                    side_horizontal_butt_registration_3d(
                        x0,drawer_separator_front_y,
                        drawer_separator_full_depth,sep_z);
                } else {
                    side_horizontal_butt_registration_3d(
                        x0,drawer_separator_front_y,
                        drawer_separator_stretcher_actual_depth,sep_z);
                    side_horizontal_butt_registration_3d(
                        x0,
                        drawer_separator_front_y
                            + drawer_separator_full_depth
                            - drawer_separator_stretcher_actual_depth,
                        drawer_separator_stretcher_actual_depth,
                        sep_z);
                }
            }

        if (has_toe_kick)
            side_toe_butt_registration_3d(x0);

        if (back_style == "stretchers")
            for (b=[0:back_stretcher_count-1])
                side_back_stretcher_butt_registration_3d(
                    x0,back_stretcher_z(b));
    }
}

module all_side_butt_registration_2d() {
    if (joinery_style == "butt" && include_butt_registration_holes) {
        if (!full_width_bottom_active)
            side_horizontal_butt_registration_2d(
                0,resolved_cabinet_depth,bottom_above_toe);

        top_z = cabinet_height-material_thickness;

        if (top_style == "full") {
            side_horizontal_butt_registration_2d(
                0,resolved_cabinet_depth,top_z);
        } else {
            side_horizontal_butt_registration_2d(
                0,top_stretcher_depth,top_z);
            side_horizontal_butt_registration_2d(
                resolved_cabinet_depth-top_stretcher_depth,
                top_stretcher_depth,
                top_z);
        }

        if (!mixed_bay_mode
            && cabinet_contents == "combo"
            && door_region_height > material_thickness)
            side_horizontal_butt_registration_2d(
                shelf_front_y,shelf_depth,combo_divider_bottom_z);

        if (!mixed_bay_mode
            && has_doors
            && shelf_style == "fixed"
            && door_shelf_count > 0
            && door_region_height > 60)
            for (s=[1:door_shelf_count])
                side_horizontal_butt_registration_2d(
                    shelf_front_y,shelf_depth,door_shelf_z(s));

        if (drawer_separator_count > 0)
            for (s=[0:drawer_separator_count-1]) {
                sep_z = drawer_separator_z(s);

                if (drawer_separator_style == "full") {
                    side_horizontal_butt_registration_2d(
                        drawer_separator_front_y,
                        drawer_separator_full_depth,sep_z);
                } else {
                    side_horizontal_butt_registration_2d(
                        drawer_separator_front_y,
                        drawer_separator_stretcher_actual_depth,
                        sep_z);
                    side_horizontal_butt_registration_2d(
                        drawer_separator_front_y
                            + drawer_separator_full_depth
                            - drawer_separator_stretcher_actual_depth,
                        drawer_separator_stretcher_actual_depth,
                        sep_z);
                }
            }

        if (has_toe_kick)
            side_toe_butt_registration_2d();

        if (back_style == "stretchers")
            for (b=[0:back_stretcher_count-1])
                side_back_stretcher_butt_registration_2d(
                    back_stretcher_z(b));
    }
}


// All carcass joinery features that belong in one side panel.
module all_side_joinery_cuts_3d(side) {
    if (joinery_style != "butt") {
        // Bottom.
        if (!full_width_bottom_active)
            side_horizontal_joint_cut_3d(
                side,0,resolved_cabinet_depth,bottom_above_toe,"bottom");

        // Top/full or top stretchers.
        top_z = cabinet_height-material_thickness;

        if (top_style == "full") {
            side_horizontal_joint_cut_3d(
                side,0,resolved_cabinet_depth,top_z,"top");
        } else {
            side_horizontal_joint_cut_3d(
                side,0,top_stretcher_depth,top_z,"top");
            side_horizontal_joint_cut_3d(
                side,resolved_cabinet_depth-top_stretcher_depth,
                top_stretcher_depth,top_z,"top");
        }

        // Combo divider.
        if (!mixed_bay_mode && cabinet_contents == "combo" && door_region_height > material_thickness)
            side_horizontal_joint_cut_3d(
                side,shelf_front_y,shelf_depth,combo_divider_bottom_z,"shelf");

        // Fixed door-compartment shelves.
        if (!mixed_bay_mode && has_doors && shelf_style == "fixed" && door_shelf_count > 0 && door_region_height > 60)
            for (s=[1:door_shelf_count])
                side_horizontal_joint_cut_3d(
                    side,shelf_front_y,shelf_depth,door_shelf_z(s),"shelf");

        // Optional separators between adjacent drawers.
        if (drawer_separator_count > 0)
            for (s=[0:drawer_separator_count-1]) {
                sep_z = drawer_separator_z(s);

                if (drawer_separator_style == "full") {
                    side_horizontal_joint_cut_3d(
                        side,drawer_separator_front_y,
                        drawer_separator_full_depth,sep_z,"separator");
                } else {
                    side_horizontal_joint_cut_3d(
                        side,drawer_separator_front_y,
                        drawer_separator_stretcher_actual_depth,sep_z,"separator");
                    side_horizontal_joint_cut_3d(
                        side,
                        drawer_separator_front_y
                            + drawer_separator_full_depth
                            - drawer_separator_stretcher_actual_depth,
                        drawer_separator_stretcher_actual_depth,
                        sep_z,"separator");
                }
            }

        // Toe-kick rail.
        if (has_toe_kick)
            side_toe_joint_cut_3d(side);

        // Structural rear stretchers.
        if (back_style == "stretchers")
            for (b=[0:back_stretcher_count-1])
                side_back_stretcher_joint_cut_3d(
                    side,back_stretcher_z(b));
    }
}


// Side-panel joinery as 2D THROUGH geometry.
// Dado pockets are intentionally NOT here because they are blind.
module all_side_through_joinery_2d() {
    c = joint_fit_clearance;

    if (joinery_style == "tab_slot") {
        // Bottom.
        if (!full_width_bottom_active)
            for (i=[0:bottom_tab_count(resolved_cabinet_depth)-1]) {
                sy = bottom_tab_start(resolved_cabinet_depth,i)-c/2;
                sw = tab_width_for(resolved_cabinet_depth)+c;
                nominal_sy = bottom_tab_start(
                    resolved_cabinet_depth,i);
                nominal_sw = tab_width_for(resolved_cabinet_depth);
                bottom_open =
                    bottom_above_toe <= side_panel_bottom_z + 0.001
                    || (
                        stackable_mode
                        && abs(
                            bottom_above_toe-effective_stack_interface_depth
                        ) <= 0.001
                        && (
                            nominal_sy + nominal_sw
                                <= effective_stack_front_margin + 0.001
                            || nominal_sy
                                >= resolved_cabinet_depth
                                   - effective_stack_back_margin - 0.001
                        )
                    );

                translate([sy,bottom_above_toe-c/2])
                    slot_shape_2d(
                        sw,material_thickness+c,
                        false,false,bottom_open,false
                    );
            }

        // Top.
        top_z = cabinet_height-material_thickness;

        if (top_style == "full") {
            for (i=[0:tab_count_for_location(resolved_cabinet_depth,"top")-1]) {
                sy = tab_start_for_location(resolved_cabinet_depth,i,"top")-c/2;
                sw = tab_width_for(resolved_cabinet_depth)+c;
                translate([sy,top_z-c/2])
                    slot_shape_2d(
                        sw,material_thickness+c,
                        false,false,false,true
                    );
            }
        } else {
            for (i=[0:tab_count_for_location(top_stretcher_depth,"top")-1]) {
                sw = tab_width_for(top_stretcher_depth)+c;

                translate([tab_start_for_location(top_stretcher_depth,i,"top")-c/2,
                           top_z-c/2])
                    slot_shape_2d(
                        sw,material_thickness+c,
                        false,false,false,true
                    );

                translate([resolved_cabinet_depth-top_stretcher_depth
                           + tab_start_for_location(top_stretcher_depth,i,"top")-c/2,
                           top_z-c/2])
                    slot_shape_2d(
                        sw,material_thickness+c,
                        false,false,false,true
                    );
            }
        }

        // Combo divider.
        if (!mixed_bay_mode && cabinet_contents == "combo" && door_region_height > material_thickness)
            for (i=[0:tab_count_for_location(shelf_depth,"shelf")-1]) {
                sy = shelf_front_y+tab_start_for_location(shelf_depth,i,"shelf")-c/2;
                sw = tab_width_for(shelf_depth)+c;
                translate([sy,combo_divider_bottom_z-c/2])
                    slot_shape_2d(sw,material_thickness+c);
            }

        // Fixed shelves.
        if (!mixed_bay_mode && has_doors && shelf_style == "fixed" && door_shelf_count > 0 && door_region_height > 60)
            for (s=[1:door_shelf_count])
                for (i=[0:tab_count_for_location(shelf_depth,"shelf")-1]) {
                    sy = shelf_front_y+tab_start_for_location(shelf_depth,i,"shelf")-c/2;
                    sw = tab_width_for(shelf_depth)+c;
                    translate([sy,door_shelf_z(s)-c/2])
                        slot_shape_2d(sw,material_thickness+c);
                }

        // Optional drawer separators.
        if (drawer_separator_count > 0)
            for (s=[0:drawer_separator_count-1]) {
                sep_z = drawer_separator_z(s);

                if (drawer_separator_style == "full") {
                    for (i=[0:tab_count_for_location(drawer_separator_full_depth,"separator")-1]) {
                        sy = drawer_separator_front_y
                            + tab_start_for_location(drawer_separator_full_depth,i,"separator")-c/2;
                        sw = tab_width_for(drawer_separator_full_depth)+c;
                        translate([sy,sep_z-c/2])
                            slot_shape_2d(sw,material_thickness+c);
                    }
                } else {
                    for (i=[0:tab_count_for_location(drawer_separator_stretcher_actual_depth,"separator")-1]) {
                        sw = tab_width_for(drawer_separator_stretcher_actual_depth)+c;

                        translate([
                            drawer_separator_front_y
                                + tab_start_for_location(drawer_separator_stretcher_actual_depth,i,"separator")-c/2,
                            sep_z-c/2
                        ])
                            slot_shape_2d(sw,material_thickness+c);

                        translate([
                            drawer_separator_front_y
                                + drawer_separator_full_depth
                                - drawer_separator_stretcher_actual_depth
                                + tab_start_for_location(drawer_separator_stretcher_actual_depth,i,"separator")
                                - c/2,
                            sep_z-c/2
                        ])
                            slot_shape_2d(sw,material_thickness+c);
                    }
                }
            }

        // Toe-kick slots.
        if (has_toe_kick)
            for (i=[0:effective_tab_count(toe_kick_height)-1]) {
                sy = toe_kick_setback-c/2;
                sw = material_thickness+c;
                sz = tab_start(toe_kick_height,i)-c/2;
                sh = tab_width_for(toe_kick_height)+c;

                translate([sy,sz])
                    slot_shape_2d(
                        sw,sh,
                        toe_kick_setback <= 0.001,false,false,false
                    );
            }

        // Structural rear-stretcher slots.
        if (back_style == "stretchers")
            for (b=[0:back_stretcher_count-1])
                for (i=[0:effective_tab_count(back_stretcher_height)-1]) {
                    sy = back_stretcher_y-c/2;
                    sw = material_thickness+c;
                    sz =
                        back_stretcher_z(b)
                        + tab_start(back_stretcher_height,i)
                        - c/2;
                    sh = tab_width_for(back_stretcher_height)+c;

                    translate([sy,sz])
                        slot_shape_2d(
                            sw,sh,
                            false,back_stretcher_inset <= 0.001,
                            false,false
                        );
                }
    }
}


// Dado pocket geometry in side-panel local Y/Z coordinates.
// Export output_mode = "pocket_layout" as a separate CAM operation.
module all_side_dado_pockets_2d() {
    c = dado_fit_clearance;

    if (joinery_style == "dado") {
        // Bottom.
        if (!full_width_bottom_active)
            translate([-c/2,bottom_above_toe-c/2])
                square([resolved_cabinet_depth+c,material_thickness+c]);

        // Top.
        top_z = cabinet_height-material_thickness;

        if (top_style == "full") {
            translate([-c/2,top_z-c/2])
                square([resolved_cabinet_depth+c,material_thickness+c]);
        } else {
            translate([-c/2,top_z-c/2])
                square([top_stretcher_depth+c,material_thickness+c]);

            translate([resolved_cabinet_depth-top_stretcher_depth-c/2,
                       top_z-c/2])
                square([top_stretcher_depth+c,material_thickness+c]);
        }

        // Combo divider.
        if (!mixed_bay_mode && cabinet_contents == "combo" && door_region_height > material_thickness)
            translate([shelf_front_y-c/2,combo_divider_bottom_z-c/2])
                square([shelf_depth+c,material_thickness+c]);

        // Fixed shelves.
        if (!mixed_bay_mode && has_doors && shelf_style == "fixed" && door_shelf_count > 0 && door_region_height > 60)
            for (s=[1:door_shelf_count])
                translate([shelf_front_y-c/2,door_shelf_z(s)-c/2])
                    square([shelf_depth+c,material_thickness+c]);

        // Optional drawer separators.
        if (drawer_separator_count > 0)
            for (s=[0:drawer_separator_count-1]) {
                sep_z = drawer_separator_z(s);

                if (drawer_separator_style == "full") {
                    translate([drawer_separator_front_y-c/2,sep_z-c/2])
                        square([
                            drawer_separator_full_depth+c,
                            material_thickness+c
                        ]);
                } else {
                    translate([drawer_separator_front_y-c/2,sep_z-c/2])
                        square([
                            drawer_separator_stretcher_actual_depth+c,
                            material_thickness+c
                        ]);

                    translate([
                        drawer_separator_front_y
                            + drawer_separator_full_depth
                            - drawer_separator_stretcher_actual_depth
                            - c/2,
                        sep_z-c/2
                    ])
                        square([
                            drawer_separator_stretcher_actual_depth+c,
                            material_thickness+c
                        ]);
                }
            }

        // Toe-kick vertical dado.
        if (has_toe_kick)
            translate([toe_kick_setback-c/2,-c/2])
                square([material_thickness+c,toe_kick_height+c]);

        // Structural rear-stretcher dados.
        if (back_style == "stretchers")
            for (b=[0:back_stretcher_count-1])
                translate([
                    back_stretcher_y-c/2,
                    back_stretcher_z(b)-c/2
                ])
                    square([
                        material_thickness+c,
                        back_stretcher_height+c
                    ]);

        // Solid structural-back side dado.
        side_back_dado_pocket_2d();
    }
}



// ---------------------------
// BACK PANEL
// ---------------------------

// "panel" is the original thin applied sheet.
// "structural_panel" is carcass-thickness material captured flush with the rear
// edge and joined to BOTH cabinet sides and the rear-reaching bottom/top member
// with the active carcass butt/dado/tab-slot style.

function structural_back_panel_overlaps_horizontal(
    panel_y0,
    panel_depth
) =
    structural_back_active
    && panel_y0 <= structural_back_y+0.001
    && panel_y0+panel_depth
       >= structural_back_y+material_thickness-0.001;


module structural_back_panel_3d() {
    if (structural_back_active) {
        if (joinery_style == "butt") {
            sheet_box(
                [
                    inner_width,
                    material_thickness,
                    captured_back_height
                ],
                [
                    material_thickness,
                    structural_back_y,
                    captured_back_bottom_z
                ]
            );
        }
        else if (joinery_style == "dado") {
            dd = structural_back_dado_depth;

            union() {
                // Main body.
                sheet_box(
                    [
                        inner_width,
                        material_thickness,
                        captured_back_height
                    ],
                    [
                        material_thickness,
                        structural_back_y,
                        captured_back_bottom_z
                    ]
                );

                // Left/right tongues into cabinet-side dados.
                sheet_box(
                    [
                        dd,
                        material_thickness,
                        captured_back_height
                    ],
                    [
                        material_thickness-dd,
                        structural_back_y,
                        captured_back_bottom_z
                    ]
                );

                sheet_box(
                    [
                        dd,
                        material_thickness,
                        captured_back_height
                    ],
                    [
                        resolved_cabinet_width-material_thickness,
                        structural_back_y,
                        captured_back_bottom_z
                    ]
                );

                // Bottom/top tongues into the horizontal receivers. The four
                // corners are intentionally absent so the side and horizontal
                // dados can meet without overlapping tongue material.
                sheet_box(
                    [
                        inner_width,
                        material_thickness,
                        dd
                    ],
                    [
                        material_thickness,
                        structural_back_y,
                        captured_back_bottom_z-dd
                    ]
                );

                sheet_box(
                    [
                        inner_width,
                        material_thickness,
                        dd
                    ],
                    [
                        material_thickness,
                        structural_back_y,
                        captured_back_top_z
                    ]
                );
            }
        }
        else if (joinery_style == "tab_slot") {
            union() {
                sheet_box(
                    [
                        inner_width,
                        material_thickness,
                        captured_back_height
                    ],
                    [
                        material_thickness,
                        structural_back_y,
                        captured_back_bottom_z
                    ]
                );

                // Side tabs.
                for (i=[0:effective_tab_count(captured_back_height)-1]) {
                    tz =
                        captured_back_bottom_z
                        + tab_start(captured_back_height,i);
                    tw = tab_width_for(captured_back_height);

                    sheet_box(
                        [material_thickness,material_thickness,tw],
                        [0,structural_back_y,tz]
                    );

                    sheet_box(
                        [material_thickness,material_thickness,tw],
                        [
                            resolved_cabinet_width-material_thickness,
                            structural_back_y,
                            tz
                        ]
                    );
                }

                // Bottom/top tabs.
                for (i=[0:effective_tab_count(inner_width)-1]) {
                    tx =
                        material_thickness
                        + tab_start(inner_width,i);
                    tw = tab_width_for(inner_width);

                    sheet_box(
                        [tw,material_thickness,material_thickness],
                        [
                            tx,
                            structural_back_y,
                            captured_back_bottom_z-material_thickness
                        ]
                    );

                    sheet_box(
                        [tw,material_thickness,material_thickness],
                        [
                            tx,
                            structural_back_y,
                            captured_back_top_z
                        ]
                    );
                }
            }
        }
    }
}


module structural_back_panel_cut() {
    if (structural_back_active) {
        if (joinery_style == "butt") {
            cut_part(
                inner_width,
                captured_back_height
            );
        }
        else if (joinery_style == "dado") {
            dd = structural_back_dado_depth;

            union() {
                translate([dd,dd])
                    cut_part(
                        inner_width,
                        captured_back_height
                    );

                translate([0,dd])
                    cut_part(
                        dd,
                        captured_back_height
                    );

                translate([dd+inner_width,dd])
                    cut_part(
                        dd,
                        captured_back_height
                    );

                translate([dd,0])
                    cut_part(
                        inner_width,
                        dd
                    );

                translate([dd,dd+captured_back_height])
                    cut_part(
                        inner_width,
                        dd
                    );
            }
        }
        else if (joinery_style == "tab_slot") {
            union() {
                translate([
                    material_thickness,
                    material_thickness
                ])
                    cut_part(
                        inner_width,
                        captured_back_height
                    );

                for (i=[0:effective_tab_count(captured_back_height)-1]) {
                    tz =
                        material_thickness
                        + tab_start(captured_back_height,i);
                    tw = tab_width_for(captured_back_height);

                    translate([0,tz])
                        cut_part(
                            material_thickness,
                            tw
                        );

                    translate([
                        resolved_cabinet_width-material_thickness,
                        tz
                    ])
                        cut_part(
                            material_thickness,
                            tw
                        );
                }

                for (i=[0:effective_tab_count(inner_width)-1]) {
                    tx =
                        material_thickness
                        + tab_start(inner_width,i);
                    tw = tab_width_for(inner_width);

                    translate([tx,0])
                        cut_part(
                            tw,
                            material_thickness
                        );

                    translate([
                        tx,
                        material_thickness+captured_back_height
                    ])
                        cut_part(
                            tw,
                            material_thickness
                        );
                }
            }
        }
    }
}


module back_panel_3d() {
    if (back_style == "panel") {
        sheet_box(
            [
                resolved_cabinet_width,
                back_thickness,
                simple_back_height
            ],
            [
                0,
                applied_back_y,
                simple_back_bottom_z
            ]
        );
    }
    else if (structural_back_active) {
        structural_back_panel_3d();
    }
}


module back_panel_cut() {
    if (back_style == "panel")
        cut_part(
            resolved_cabinet_width,
            simple_back_height
        );
    else if (structural_back_active)
        structural_back_panel_cut();
}


// Matching side-panel receiver for the structural back.
module side_back_joint_cut_3d(side) {
    if (structural_back_active) {
        c =
            joinery_style == "dado"
                ? dado_fit_clearance
                : joint_fit_clearance;

        if (joinery_style == "dado") {
            dd = structural_back_dado_depth;

            if (side == "left")
                translate([
                    material_thickness-dd,
                    structural_back_y-c/2,
                    captured_back_bottom_z-c/2
                ])
                    cube([
                        dd+0.02,
                        material_thickness+c,
                        captured_back_height+c
                    ]);
            else
                translate([
                    resolved_cabinet_width-material_thickness-0.01,
                    structural_back_y-c/2,
                    captured_back_bottom_z-c/2
                ])
                    cube([
                        dd+0.02,
                        material_thickness+c,
                        captured_back_height+c
                    ]);
        }
        else if (joinery_style == "tab_slot") {
            for (i=[0:effective_tab_count(captured_back_height)-1]) {
                sy = structural_back_y-c/2;
                sw = material_thickness+c;
                sz =
                    captured_back_bottom_z
                    + tab_start(captured_back_height,i)
                    - c/2;
                sh =
                    tab_width_for(captured_back_height)+c;

                if (side == "left")
                    slot_cut_x_3d(
                        -1,
                        material_thickness+2,
                        sy,sz,sw,sh
                    );
                else
                    slot_cut_x_3d(
                        resolved_cabinet_width-material_thickness-1,
                        material_thickness+2,
                        sy,sz,sw,sh
                    );
            }
        }
        else if (
            joinery_style == "butt"
            && include_butt_registration_holes
        ) {
            x0 =
                side == "left"
                    ? -1
                    : resolved_cabinet_width-material_thickness-1;

            for (i=[0:butt_reg_count(captured_back_height)-1])
                round_hole_x_3d(
                    x0,
                    structural_back_y+material_thickness/2,
                    captured_back_bottom_z
                        + butt_reg_pos(captured_back_height,i),
                    material_thickness+2,
                    butt_registration_hole_diameter
                );
        }
    }
}


// Through geometry in cabinet-side local Y/Z coordinates.
module side_back_joint_2d() {
    if (structural_back_active) {
        c =
            joinery_style == "dado"
                ? dado_fit_clearance
                : joint_fit_clearance;

        if (joinery_style == "tab_slot") {
            for (i=[0:effective_tab_count(captured_back_height)-1]) {
                sy = structural_back_y-c/2;
                sw = material_thickness+c;
                sz =
                    captured_back_bottom_z
                    + tab_start(captured_back_height,i)
                    - c/2;
                sh =
                    tab_width_for(captured_back_height)+c;

                translate([sy,sz])
                    slot_shape_2d(sw,sh);
            }
        }
        else if (
            joinery_style == "butt"
            && include_butt_registration_holes
        ) {
            for (i=[0:butt_reg_count(captured_back_height)-1])
                round_hole_2d(
                    structural_back_y+material_thickness/2,
                    captured_back_bottom_z
                        + butt_reg_pos(captured_back_height,i),
                    butt_registration_hole_diameter
                );
        }
    }
}


// Blind dado in cabinet-side local Y/Z coordinates.
module side_back_dado_pocket_2d() {
    if (
        structural_back_active
        && joinery_style == "dado"
    ) {
        c = dado_fit_clearance;

        translate([
            structural_back_y-c/2,
            captured_back_bottom_z-c/2
        ])
            square([
                material_thickness+c,
                captured_back_height+c
            ]);
    }
}


// Structural-back receiver in a horizontal bottom/top member.
module back_horizontal_receiver_cuts_3d(
    panel_y0,
    panel_depth,
    z0,
    receiver_face="top"
) {
    if (
        structural_back_panel_overlaps_horizontal(
            panel_y0,
            panel_depth
        )
    ) {
        c =
            joinery_style == "dado"
                ? dado_fit_clearance
                : joint_fit_clearance;

        if (joinery_style == "dado") {
            dd = structural_back_dado_depth;
            zcut =
                receiver_face == "top"
                    ? z0+material_thickness-dd-0.01
                    : z0-0.01;

            translate([
                material_thickness-c/2,
                structural_back_y-c/2,
                zcut
            ])
                cube([
                    inner_width+c,
                    material_thickness+c,
                    dd+0.02
                ]);
        }
        else if (joinery_style == "tab_slot") {
            for (i=[0:effective_tab_count(inner_width)-1]) {
                sx =
                    material_thickness
                    + tab_start(inner_width,i)
                    - c/2;
                sw = tab_width_for(inner_width)+c;
                sy = structural_back_y-c/2;
                sh = material_thickness+c;

                slot_cut_z_3d(
                    sx,
                    sy,
                    z0-1,
                    material_thickness+2,
                    sw,
                    sh
                );
            }
        }
    }
}


// Through slots in a horizontal part's local 2D coordinates.
module back_horizontal_receiver_through_2d(
    panel_y0,
    panel_depth,
    panel_global_x0=horizontal_panel_global_x0()
) {
    if (
        structural_back_panel_overlaps_horizontal(
            panel_y0,
            panel_depth
        )
        && joinery_style == "tab_slot"
    ) {
        c = joint_fit_clearance;

        for (i=[0:effective_tab_count(inner_width)-1]) {
            gx =
                material_thickness
                + tab_start(inner_width,i)
                - c/2;
            lx = gx-panel_global_x0;
            ly = structural_back_y-panel_y0-c/2;

            translate([lx,ly])
                slot_shape_2d(
                    tab_width_for(inner_width)+c,
                    material_thickness+c
                );
        }
    }
}


// Blind dado pocket in a horizontal part's local 2D coordinates.
module back_horizontal_dado_pocket_2d(
    panel_y0,
    panel_depth,
    panel_global_x0=horizontal_panel_global_x0()
) {
    if (
        structural_back_panel_overlaps_horizontal(
            panel_y0,
            panel_depth
        )
        && joinery_style == "dado"
    ) {
        c = dado_fit_clearance;
        lx =
            material_thickness
            - panel_global_x0
            - c/2;
        ly =
            structural_back_y
            - panel_y0
            - c/2;

        translate([lx,ly])
            square([
                inner_width+c,
                material_thickness+c
            ]);
    }
}


// Compatibility wrappers retained for callers that want a plain horizontal
// part plus the structural-back receiver.
module joined_horizontal_back_receiver_3d(
    y0,
    depth,
    z0,
    receiver_face="top",
    enable_back_tabs=false
) {
    difference() {
        joined_horizontal_panel_3d(y0,depth,z0);

        if (enable_back_tabs || structural_back_active)
            back_horizontal_receiver_cuts_3d(
                y0,depth,z0,receiver_face);
    }
}

module joined_horizontal_back_receiver_cut(
    panel_y0,
    depth,
    enable_back_tabs=false
) {
    difference() {
        joined_horizontal_panel_cut(depth);

        if (enable_back_tabs || structural_back_active)
            back_horizontal_receiver_through_2d(
                panel_y0,depth);
    }
}


// ---------------------------
// WOOD SLIDE PARTS + REGISTRATION
// ---------------------------

module wood_fixed_rail_3d(x0,y0,z0) {
    difference() {
        sheet_box(
            [wood_rail_thickness,resolved_wood_rail_depth,wood_rail_height],
            [x0,y0,z0]
        );

        if (include_wood_slide_registration_holes) {
            for (n=[0:wood_slide_registration_hole_count-1]) {
                round_hole_x_3d(
                    x0-1,
                    y0+wood_slide_reg_pos(resolved_wood_rail_depth,n),
                    z0+wood_rail_height/2,
                    wood_rail_thickness+2,
                    wood_slide_registration_hole_diameter
                );
            }
        }
    }
}

module wood_drawer_runner_3d(x0,y0,z0) {
    difference() {
        sheet_box(
            [
                wood_drawer_runner_thickness,
                resolved_wood_drawer_runner_depth,
                wood_drawer_runner_height
            ],
            [x0,y0,z0]
        );

        if (include_wood_slide_registration_holes
            && wood_drawer_runner_reg_valid(drawer_box_depth)) {
            for (n=[0:wood_slide_registration_hole_count-1]) {
                round_hole_x_3d(
                    x0-1,
                    y0+wood_drawer_runner_reg_pos(drawer_box_depth,n),
                    z0+wood_drawer_runner_height/2,
                    wood_drawer_runner_thickness+2,
                    wood_slide_registration_hole_diameter
                );
            }
        }
    }
}

module wood_fixed_rail_cut() {
    difference() {
        cut_part(resolved_wood_rail_depth,wood_rail_height);

        if (include_wood_slide_registration_holes) {
            for (n=[0:wood_slide_registration_hole_count-1])
                round_hole_2d(
                    wood_slide_reg_pos(resolved_wood_rail_depth,n),
                    wood_rail_height/2,
                    wood_slide_registration_hole_diameter
                );
        }
    }
}

module wood_drawer_runner_cut() {
    difference() {
        cut_part(
            resolved_wood_drawer_runner_depth,
            wood_drawer_runner_height
        );

        if (include_wood_slide_registration_holes
            && wood_drawer_runner_reg_valid(drawer_box_depth)) {
            for (n=[0:wood_slide_registration_hole_count-1])
                round_hole_2d(
                    wood_drawer_runner_reg_pos(drawer_box_depth,n),
                    wood_drawer_runner_height/2,
                    wood_slide_registration_hole_diameter
                );
        }
    }
}


// ---------------------------
// ADJUSTABLE-SHELF PIN HOLES
// ---------------------------

// 3D holes in a cabinet side. Blind holes are drilled from the INTERIOR face.
module adjustable_shelf_pin_holes_3d(x0,side) {
    if (!mixed_bay_mode && has_doors && shelf_style == "adjustable") {
        for (row=[0:1])
            for (i=[0:shelf_pin_count()-1]) {
                yy = shelf_pin_y(row);
                zz = shelf_pin_z(i);

                if (adjustable_shelf_hole_type == "through") {
                    round_hole_x_3d(
                        x0-1,yy,zz,
                        material_thickness+2,
                        adjustable_shelf_hole_diameter
                    );
                } else {
                    dd = min(
                        adjustable_shelf_hole_depth,
                        material_thickness-0.5
                    );

                    if (side == "left")
                        round_hole_x_3d(
                            x0+material_thickness-dd,
                            yy,zz,
                            dd+0.02,
                            adjustable_shelf_hole_diameter
                        );
                    else
                        round_hole_x_3d(
                            x0-0.01,
                            yy,zz,
                            dd+0.02,
                            adjustable_shelf_hole_diameter
                        );
                }
            }
    }
}

// Through shelf-pin holes belong in cut_layout.
module adjustable_shelf_pin_holes_cut_2d() {
    if (!mixed_bay_mode
        && has_doors
        && shelf_style == "adjustable"
        && adjustable_shelf_hole_type == "through") {

        for (row=[0:1])
            for (i=[0:shelf_pin_count()-1])
                round_hole_2d(
                    shelf_pin_y(row),
                    shelf_pin_z(i),
                    adjustable_shelf_hole_diameter
                );
    }
}

// Blind shelf-pin drilling belongs in pocket_layout.
module adjustable_shelf_pin_holes_pocket_2d() {
    if (!mixed_bay_mode
        && has_doors
        && shelf_style == "adjustable"
        && adjustable_shelf_hole_type == "blind") {

        for (row=[0:1])
            for (i=[0:shelf_pin_count()-1])
                round_hole_2d(
                    shelf_pin_y(row),
                    shelf_pin_z(i),
                    adjustable_shelf_hole_diameter
                );
    }
}



// Mixed-bay shelf-pin holes on the two OUTER cabinet sides. Internal bay
// partitions always use through holes so one drilled row serves both faces.
module mixed_bay_side_shelf_pin_holes_3d(x0,side) {
    if (mixed_bay_mode && mixed_bay_side_has_shelf_pins(side)) {
        for (row=[0:1])
            for (i=[0:mixed_bay_shelf_pin_count()-1]) {
                yy = shelf_pin_y(row);
                zz = mixed_bay_shelf_pin_z(i);

                if (adjustable_shelf_hole_type == "through") {
                    round_hole_x_3d(
                        x0-1,yy,zz,
                        material_thickness+2,
                        adjustable_shelf_hole_diameter
                    );
                } else {
                    dd = min(
                        adjustable_shelf_hole_depth,
                        material_thickness-0.5
                    );

                    if (side == "left")
                        round_hole_x_3d(
                            x0+material_thickness-dd,
                            yy,zz,
                            dd+0.02,
                            adjustable_shelf_hole_diameter
                        );
                    else
                        round_hole_x_3d(
                            x0-0.01,
                            yy,zz,
                            dd+0.02,
                            adjustable_shelf_hole_diameter
                        );
                }
            }
    }
}

module mixed_bay_side_shelf_pin_holes_cut_2d(side) {
    if (mixed_bay_mode
        && mixed_bay_side_has_shelf_pins(side)
        && adjustable_shelf_hole_type == "through")
        for (row=[0:1])
            for (i=[0:mixed_bay_shelf_pin_count()-1])
                round_hole_2d(
                    shelf_pin_y(row),
                    mixed_bay_shelf_pin_z(i),
                    adjustable_shelf_hole_diameter
                );
}

module mixed_bay_side_shelf_pin_holes_pocket_2d(side) {
    if (mixed_bay_mode
        && mixed_bay_side_has_shelf_pins(side)
        && adjustable_shelf_hole_type == "blind")
        for (row=[0:1])
            for (i=[0:mixed_bay_shelf_pin_count()-1])
                round_hole_2d(
                    shelf_pin_y(row),
                    mixed_bay_shelf_pin_z(i),
                    adjustable_shelf_hole_diameter
                );
}

module mixed_bay_side_hinge_plate_holes_3d(x0,side) {
    if (mixed_bay_mode && mixed_bay_side_has_hinge_plates(side))
        for (j=[0:hinge_count-1])
            if (hinge_plate_holes_enabled)
            for (dz=[
                -effective_hinge_plate_hole_spacing/2,
                effective_hinge_plate_hole_spacing/2
            ])
                round_hole_x_3d(
                    x0-1,
                    effective_hinge_plate_center_from_front,
                    mixed_bay_hinge_z(j)+dz,
                    material_thickness+2,
                    effective_hinge_plate_hole_diameter
                );
}

module mixed_bay_side_hinge_plate_holes_cut_2d(side) {
    if (mixed_bay_mode && mixed_bay_side_has_hinge_plates(side))
        for (j=[0:hinge_count-1])
            if (hinge_plate_holes_enabled)
            for (dz=[
                -effective_hinge_plate_hole_spacing/2,
                effective_hinge_plate_hole_spacing/2
            ])
                round_hole_2d(
                    effective_hinge_plate_center_from_front,
                    mixed_bay_hinge_z(j)+dz,
                    effective_hinge_plate_hole_diameter
                );
}

// ---------------------------
// DOOR SHELVES WITH FULL-DEPTH PARTITIONS
// ---------------------------

// Fixed shelves remain continuous and pass through cross-lap notches cut into
// the vertical partitions.
module fixed_door_shelf_3d(z0) {
    joined_horizontal_panel_3d(
        shelf_front_y,shelf_depth,z0,"shelf");
}

module fixed_door_shelf_cut() {
    joined_horizontal_panel_cut(shelf_depth,"shelf");
}

// Adjustable shelves cannot pass through full-depth partitions, so each door
// bay receives its own loose shelf panel.
module adjustable_door_shelf_3d(z0,b=0) {
    sheet_box(
        [
            door_adjustable_shelf_piece_width(b),
            shelf_depth,
            material_thickness
        ],
        [
            door_adjustable_shelf_piece_x(b),
            shelf_front_y,
            z0
        ]
    );
}

module adjustable_door_shelf_cut(b=0) {
    cut_part(
        door_adjustable_shelf_piece_width(b),
        shelf_depth);
}


// ---------------------------
// MIXED-BAY FIXED-SHELF RECEIVERS IN OUTER CABINET SIDES
// ---------------------------

module mixed_bay_side_fixed_shelf_joinery_3d(x0,side) {
    bb = mixed_bay_side_fixed_bay(side);

    if (mixed_bay_side_has_fixed_shelves(side)
        && joinery_style != "butt")
        for (s=[1:mixed_bay_shelf_count(bb)])
            side_horizontal_joint_cut_3d(
                side,
                shelf_front_y,
                shelf_depth,
                mixed_bay_shelf_z(bb,s),
                "shelf"
            );
}

module mixed_bay_side_fixed_shelf_through_2d(side) {
    bb = mixed_bay_side_fixed_bay(side);
    c = joint_fit_clearance;

    if (mixed_bay_side_has_fixed_shelves(side)
        && joinery_style == "tab_slot")
        for (s=[1:mixed_bay_shelf_count(bb)])
            for (n=[0:tab_count_for_location(shelf_depth,"shelf")-1]) {
                sy = shelf_front_y+tab_start_for_location(shelf_depth,n,"shelf")-c/2;
                sw = tab_width_for(shelf_depth)+c;

                translate([
                    sy,
                    mixed_bay_shelf_z(bb,s)-c/2
                ])
                    slot_shape_2d(
                        sw,
                        material_thickness+c
                    );
            }
}

module mixed_bay_side_fixed_shelf_dado_pockets_2d(side) {
    bb = mixed_bay_side_fixed_bay(side);
    c = dado_fit_clearance;

    if (mixed_bay_side_has_fixed_shelves(side)
        && joinery_style == "dado")
        for (s=[1:mixed_bay_shelf_count(bb)])
            translate([
                shelf_front_y-c/2,
                mixed_bay_shelf_z(bb,s)-c/2
            ])
                square([
                    shelf_depth+c,
                    material_thickness+c
                ]);
}

module mixed_bay_side_fixed_shelf_butt_registration_3d(x0,side) {
    bb = mixed_bay_side_fixed_bay(side);

    if (mixed_bay_side_has_fixed_shelves(side)
        && joinery_style == "butt"
        && include_butt_registration_holes)
        for (s=[1:mixed_bay_shelf_count(bb)])
            side_horizontal_butt_registration_3d(
                x0,
                shelf_front_y,
                shelf_depth,
                mixed_bay_shelf_z(bb,s),
                "shelf"
            );
}

module mixed_bay_side_fixed_shelf_butt_registration_2d(side) {
    bb = mixed_bay_side_fixed_bay(side);

    if (mixed_bay_side_has_fixed_shelves(side)
        && joinery_style == "butt"
        && include_butt_registration_holes)
        for (s=[1:mixed_bay_shelf_count(bb)])
            side_horizontal_butt_registration_2d(
                shelf_front_y,
                shelf_depth,
                mixed_bay_shelf_z(bb,s),
                "shelf"
            );
}


// ---------------------------
// STACKABLE SIDE INTERFACE PROFILE
// ---------------------------

// Extrude 2D Y/Z geometry along global X. Useful for side-profile cutouts.
module yz_extrude_3d(xstart,depth) {
    translate([xstart,0,0])
        multmatrix([
            [0,0,1,0],
            [1,0,0,0],
            [0,1,0,0],
            [0,0,0,1]
        ])
            linear_extrude(height=depth)
                children();
}


function stack_arc_points(
    cx,cz,r,a0,a1,segments=12
) = [
    for (i=[0:segments])
        let(a=a0+(a1-a0)*i/segments)
            [
                cx+r*cos(a),
                cz+r*sin(a)
            ]
];


// Canonical FRONT mating transition, returned HIGH -> LOW.
//
// It is a tangent S-profile:
//   high horizontal
//       quarter-circle R
//       optional vertical tangent
//       quarter-circle R
//   low horizontal
//
// There is therefore NO sharp internal corner on the milled bottom relief.
// The same nominal boundary is reused for the top recess.
function stack_front_mating_profile_points(
    margin,
    z0,
    d,
    r,
    segments=12
) =
    concat(
        // Upper fillet: tangent to the high pad and vertical center section.
        stack_arc_points(
            margin,
            z0+d-r,
            r,
            90,
            0,
            segments
        ),

        // Vertical tangent between the two radii. This collapses to zero
        // length when r = d/2.
        [
            [
                margin+r,
                z0+r
            ]
        ],

        // Lower fillet: tangent to the vertical section and low tongue.
        stack_arc_points(
            margin+2*r,
            z0+r,
            r,
            180,
            270,
            segments
        )
    );


// Rear transition is the exact depth-axis mirror of the front transition,
// returned LOW -> HIGH so it can be concatenated into one notch polygon.
function stack_rear_mating_profile_points(
    margin,
    z0,
    d,
    r,
    segments=12
) =
    let(
        fp = stack_front_mating_profile_points(
            margin,z0,d,r,segments
        )
    )
    [
        for (i=[len(fp)-1:-1:0])
            [
                resolved_cabinet_depth-fp[i][0],
                fp[i][1]
            ]
    ];


// Nominal female recess before fit clearance.
//
// This uses EXACTLY the same nominal mating boundary as the male bottom
// tongue.  The female is made larger in stack_top_notch_cutout_2d() by a
// true 2D offset rather than by inventing a second transition geometry.
module stack_top_notch_nominal_2d(top_z) {
    if (stackable_mode) {
        d = effective_stack_interface_depth;
        r = effective_stack_interface_corner_radius;
        z0 = top_z-d;

        fp = stack_front_mating_profile_points(
            effective_stack_front_margin,
            z0,d,r
        );

        rp = stack_rear_mating_profile_points(
            effective_stack_back_margin,
            z0,d,r
        );

        polygon(
            concat(
                fp,
                rp,
                [
                    [
                        resolved_cabinet_depth-effective_stack_back_margin,
                        top_z+2
                    ],
                    [
                        effective_stack_front_margin,
                        top_z+2
                    ]
                ]
            )
        );
    }
}


// Female top recess.
//
// Clearance is applied as a REAL 2D expansion of the canonical nominal notch.
// That gives clearance around BOTH radiused shoulders and along the center
// tongue floor.  The nominal radius is kept >= cutter radius + clearance so
// the resulting concave female geometry remains directly millable.
module stack_top_notch_cutout_2d(top_z) {
    if (stackable_mode) {
        c = effective_stack_interface_clearance;

        if (c > 0)
            offset(delta=c)
                stack_top_notch_nominal_2d(
                    top_z);
        else
            stack_top_notch_nominal_2d(
                top_z);
    }
}


// FRONT bottom relief.
//
// The boundary from full-height end pad to center tongue is the SAME canonical
// S-profile as the top notch, but used as the edge of the removed region.
// Both shoulders are tangent radii; no square internal corner remains for the
// router to fake.
module stack_bottom_front_relief_2d(
    margin
) {
    if (stackable_mode) {
        d = effective_stack_interface_depth;
        r = effective_stack_interface_corner_radius;

        fp = stack_front_mating_profile_points(
            margin,
            0,
            d,
            r
        );

        low = fp[len(fp)-1];

        polygon(
            concat(
                [
                    [-2,-2],
                    [low[0],-2]
                ],
                [
                    for (i=[len(fp)-1:-1:0])
                        fp[i]
                ],
                [
                    [-2,d]
                ]
            )
        );
    }
}


// Bottom end reliefs leave a centered male tongue projecting below the cabinet
// bottom plane. The rear is the exact mirror of the front.
module stack_bottom_notch_cutouts_2d() {
    if (stackable_mode) {
        stack_bottom_front_relief_2d(
            effective_stack_front_margin
        );

        translate([resolved_cabinet_depth,0])
            mirror([1,0,0])
                stack_bottom_front_relief_2d(
                    effective_stack_back_margin
                );
    }
}


module stack_module_side_profile_cutouts_2d() {
    if (stackable_mode) {
        stack_top_notch_cutout_2d(
            cabinet_height);
        stack_bottom_notch_cutouts_2d();
    }
}


module stack_module_side_profile_cutouts_3d(x0) {
    if (stackable_mode)
        yz_extrude_3d(
            x0-1,
            material_thickness+2
        )
            stack_module_side_profile_cutouts_2d();
}


module stack_base_side_profile_2d() {
    difference() {
        cut_part(
            resolved_cabinet_depth,
            stack_base_height
        );

        // The separate base uses the SAME female profile as every module.
        stack_top_notch_cutout_2d(
            stack_base_height);
    }
}


// ---------------------------
// GANGING / ALIGNMENT HARDWARE
// ---------------------------

module ganging_side_through_holes_2d(side="left") {
    if (
        ganging_side_active(side)
        && ganging_connector_active
    )
        for (c=[0:effective_ganging_column_count-1])
            for (s=[0:effective_ganging_station_count-1])
                round_hole_2d(
                    ganging_column_y(c),
                    ganging_connector_z(s),
                    effective_ganging_connector_hole_diameter
                );
}


module ganging_side_dowel_pockets_2d(side="left") {
    if (
        ganging_side_active(side)
        && ganging_dowel_active
    )
        for (c=[0:effective_ganging_column_count-1])
            for (s=[0:effective_ganging_station_count-1])
                round_hole_2d(
                    ganging_column_y(c),
                    ganging_dowel_z(s),
                    effective_ganging_dowel_diameter
                );
}


module ganging_side_holes_3d(x0=0,side="left") {
    if (ganging_side_active(side)) {
        // Through holes for cabinet connector bolts / sleeves.
        if (ganging_connector_active)
            for (c=[0:effective_ganging_column_count-1])
                for (s=[0:effective_ganging_station_count-1])
                    round_hole_x_3d(
                        x0-1,
                        ganging_column_y(c),
                        ganging_connector_z(s),
                        material_thickness+2,
                        effective_ganging_connector_hole_diameter
                    );

        // Blind alignment dowels drill from the OUTER side face.
        if (ganging_dowel_active)
            for (c=[0:effective_ganging_column_count-1])
                for (s=[0:effective_ganging_station_count-1]) {
                    xs =
                        side == "left"
                            ? x0-0.01
                            : x0
                              + material_thickness
                              - effective_ganging_dowel_depth
                              - 0.01;

                    round_hole_x_3d(
                        xs,
                        ganging_column_y(c),
                        ganging_dowel_z(s),
                        effective_ganging_dowel_depth+0.02,
                        effective_ganging_dowel_diameter
                    );
                }
    }
}


// ---------------------------
// CABINET SIDE PANELS
// ---------------------------

module cabinet_side_panel_3d(x0=0,side="left") {
    side_bank = side == "left" ? 0 : active_drawer_bank_count()-1;

    difference() {
        translate([x0,0,side_panel_bottom_z])
            cube([
                material_thickness,
                resolved_cabinet_depth,
                side_panel_cut_height
            ]);

        // Complementary top/bottom stacking interface.
        stack_module_side_profile_cutouts_3d(x0);

        // Optional toe-kick notch in the lower FRONT corner.
        if (side_has_toe_cutout(side))
            translate([x0-1,-1,-1])
                cube([
                    material_thickness+2,
                    toe_kick_setback+1,
                    toe_kick_height+1
                ]);

        // Chosen carcass joinery.
        all_side_joinery_cuts_3d(side);
        mixed_bay_side_fixed_shelf_joinery_3d(x0,side);

        // Adjustable-shelf pin holes. Legacy and generalized mixed-bay modes
        // use separate placement logic.
        adjustable_shelf_pin_holes_3d(x0,side);
        mixed_bay_side_shelf_pin_holes_3d(x0,side);

        // Optional guide holes for simple butt-jointed carcass members.
        all_side_butt_registration_3d(x0);
        mixed_bay_side_fixed_shelf_butt_registration_3d(x0,side);

        // Matching holes for the fixed cabinet-side portions of wood slides.
        if (has_drawers
            && drawer_bank_drawer_count(side_bank) > 0
            && drawer_mount == "wood_rails"
            && include_wood_slide_registration_holes) {

            for (i=[0:drawer_bank_drawer_count(side_bank)-1]) {
                for (n=[0:wood_slide_registration_hole_count-1]) {
                    round_hole_x_3d(
                        x0-1,
                        effective_wood_rail_front_setback
                            + wood_slide_reg_pos(resolved_wood_rail_depth,n),
                        drawer_rail_z(i,side_bank)+wood_rail_height/2,
                        material_thickness+2,
                        wood_slide_registration_hole_diameter
                    );
                }
            }
        }

        // Cabinet ganging / alignment hardware.
        ganging_side_holes_3d(x0,side);

        // Back-panel tabs receive their own through-slots.
        side_back_joint_cut_3d(side);

        // Door hinge mounting-plate holes in the cabinet side panels.
        if (cabinet_side_has_door_hinges(side)) {
            for (j=[0:hinge_count-1])
                if (hinge_plate_holes_enabled)
                for (dz=[
                    -effective_hinge_plate_hole_spacing/2,
                    effective_hinge_plate_hole_spacing/2
                ])
                    round_hole_x_3d(
                        x0-1,
                        effective_hinge_plate_center_from_front,
                        hinge_z(j)+dz,
                        material_thickness+2,
                        effective_hinge_plate_hole_diameter
                    );
        }

        // Generalized mixed-bay door hinge plate holes.
        mixed_bay_side_hinge_plate_holes_3d(x0,side);

        // Optional commercial-slide holes.
        if (has_drawers
            && drawer_bank_drawer_count(side_bank) > 0
            && drawer_mount == "metal_slides"
            && include_metal_slide_holes) {

            for (i=[0:drawer_bank_drawer_count(side_bank)-1]) {
                hole_z = drawer_box_z(i,side_bank) + effective_metal_slide_cabinet_hole_z;

                for (hx=active_slide_cabinet_holes())
                    if (cabinet_slide_hole_is_valid(hx,resolved_cabinet_depth))
                        metal_hole_x_3d(x0-1,slide_cabinet_hole_depth(hx),hole_z,material_thickness+2,effective_metal_slide_cabinet_hole_diameter);
            }
        }
    }
}

module cabinet_side_panel_cut_features(side="left") {
    side_bank = side == "left" ? 0 : active_drawer_bank_count()-1;

    if (side_has_toe_cutout(side))
        translate([-0.01,-0.01])
            square([
                toe_kick_setback+0.02,
                toe_kick_height+0.02
            ]);

    all_side_through_joinery_2d();
    mixed_bay_side_fixed_shelf_through_2d(side);

    adjustable_shelf_pin_holes_cut_2d();
    mixed_bay_side_shelf_pin_holes_cut_2d(side);

    all_side_butt_registration_2d();
    mixed_bay_side_fixed_shelf_butt_registration_2d(side);

    if (has_drawers
        && drawer_bank_drawer_count(side_bank) > 0
        && drawer_mount == "wood_rails"
        && include_wood_slide_registration_holes) {

        for (i=[0:drawer_bank_drawer_count(side_bank)-1])
            for (n=[0:wood_slide_registration_hole_count-1])
                round_hole_2d(
                    effective_wood_rail_front_setback
                        + wood_slide_reg_pos(resolved_wood_rail_depth,n),
                    drawer_rail_z(i,side_bank)+wood_rail_height/2,
                    wood_slide_registration_hole_diameter
                );
    }

    ganging_side_through_holes_2d(side);

    side_back_joint_2d();

    if (cabinet_side_has_door_hinges(side)) {
        for (j=[0:hinge_count-1])
            if (hinge_plate_holes_enabled)
            for (dz=[
                -effective_hinge_plate_hole_spacing/2,
                effective_hinge_plate_hole_spacing/2
            ])
                round_hole_2d(
                    effective_hinge_plate_center_from_front,
                    hinge_z(j)+dz,
                    effective_hinge_plate_hole_diameter
                );
    }

    mixed_bay_side_hinge_plate_holes_cut_2d(side);

    if (has_drawers
        && drawer_bank_drawer_count(side_bank) > 0
        && drawer_mount == "metal_slides"
        && include_metal_slide_holes) {

        for (i=[0:drawer_bank_drawer_count(side_bank)-1]) {
            hole_z = drawer_box_z(i,side_bank) + effective_metal_slide_cabinet_hole_z;

            for (hx=active_slide_cabinet_holes())
                if (cabinet_slide_hole_is_valid(hx,resolved_cabinet_depth))
                    metal_hole_2d(slide_cabinet_hole_depth(hx),hole_z,effective_metal_slide_cabinet_hole_diameter);
        }
    }
}

module cabinet_side_panel_cut(side="left") {
    difference() {
        cut_part(
            resolved_cabinet_depth,
            side_panel_cut_height
        );

        stack_module_side_profile_cutouts_2d();

        translate([0,-side_panel_bottom_z])
            cabinet_side_panel_cut_features(side);
    }
}



// ---------------------------
// STACKABLE BASE FRAME
// ---------------------------

function stack_base_cross_y(front=true) =
    front
        ? 0
        : resolved_cabinet_depth-material_thickness;


module stack_base_side_receiver_cuts_3d(
    x0,
    side
) {
    if (stack_base_active) {
        c =
            joinery_style == "dado"
                ? dado_fit_clearance
                : joint_fit_clearance;

        for (front=[true,false]) {
            y0 = stack_base_cross_y(front);

            if (joinery_style == "dado") {
                dd = effective_dado_depth();

                if (side == "left")
                    translate([
                        x0+material_thickness-dd,
                        y0-c/2,
                        -c/2
                    ])
                        cube([
                            dd+0.02,
                            material_thickness+c,
                            stack_base_height+c
                        ]);
                else
                    translate([
                        x0-0.01,
                        y0-c/2,
                        -c/2
                    ])
                        cube([
                            dd+0.02,
                            material_thickness+c,
                            stack_base_height+c
                        ]);
            }
            else if (joinery_style == "tab_slot") {
                for (i=[0:effective_tab_count(stack_base_height)-1]) {
                    sz =
                        tab_start(stack_base_height,i)-c/2;
                    sh =
                        tab_width_for(stack_base_height)+c;

                    slot_cut_x_3d(
                        x0-1,
                        material_thickness+2,
                        y0-c/2,
                        sz,
                        material_thickness+c,
                        sh,
                        front,!front,false,false
                    );
                }
            }
            else if (
                joinery_style == "butt"
                && include_butt_registration_holes
            ) {
                for (i=[0:butt_reg_count(stack_base_height)-1])
                    round_hole_x_3d(
                        x0-1,
                        y0+material_thickness/2,
                        butt_reg_pos(stack_base_height,i),
                        material_thickness+2,
                        butt_registration_hole_diameter
                    );
            }
        }
    }
}


module stack_base_side_receivers_through_2d() {
    if (stack_base_active) {
        c = joint_fit_clearance;

        for (front=[true,false]) {
            y0 = stack_base_cross_y(front);

            if (joinery_style == "tab_slot")
                for (i=[0:effective_tab_count(stack_base_height)-1]) {
                    sz =
                        tab_start(stack_base_height,i)-c/2;
                    sh =
                        tab_width_for(stack_base_height)+c;

                    translate([
                        y0-c/2,
                        sz
                    ])
                        slot_shape_2d(
                            material_thickness+c,
                            sh,
                            front,!front,false,false
                        );
                }

            if (
                joinery_style == "butt"
                && include_butt_registration_holes
            )
                for (i=[0:butt_reg_count(stack_base_height)-1])
                    round_hole_2d(
                        y0+material_thickness/2,
                        butt_reg_pos(stack_base_height,i),
                        butt_registration_hole_diameter
                    );
        }
    }
}


module stack_base_side_dado_pockets_2d() {
    if (
        stack_base_active
        && joinery_style == "dado"
    ) {
        c = dado_fit_clearance;

        for (front=[true,false]) {
            y0 = stack_base_cross_y(front);

            translate([
                y0-c/2,
                -c/2
            ])
                square([
                    material_thickness+c,
                    stack_base_height+c
                ]);
        }
    }
}


module stack_base_side_rail_3d(
    x0,
    side
) {
    if (stack_base_active)
        difference() {
            sheet_box(
                [
                    material_thickness,
                    resolved_cabinet_depth,
                    stack_base_height
                ],
                [x0,0,0]
            );

            yz_extrude_3d(
                x0-1,
                material_thickness+2
            )
                stack_top_notch_cutout_2d(
                    stack_base_height);

            stack_base_side_receiver_cuts_3d(
                x0,
                side
            );
        }
}


module stack_base_side_rail_cut() {
    if (stack_base_active)
        difference() {
            stack_base_side_profile_2d();
            stack_base_side_receivers_through_2d();
        }
}


module stack_base_side_rail_print_part() {
    if (stack_base_active)
        difference() {
            linear_extrude(height=material_thickness)
                stack_base_side_rail_cut();

            if (joinery_style == "dado")
                translate([
                    0,0,
                    material_thickness-effective_dado_depth()
                ])
                    linear_extrude(
                        height=effective_dado_depth()+0.02
                    )
                        stack_base_side_dado_pockets_2d();
        }
}


module stack_base_cross_rail_3d(
    y0
) {
    if (stack_base_active) {
        if (joinery_style == "butt") {
            sheet_box(
                [
                    inner_width,
                    material_thickness,
                    stack_base_height
                ],
                [
                    material_thickness,
                    y0,
                    0
                ]
            );
        }
        else if (joinery_style == "dado") {
            dd = effective_dado_depth();

            sheet_box(
                [
                    inner_width+2*dd,
                    material_thickness,
                    stack_base_height
                ],
                [
                    material_thickness-dd,
                    y0,
                    0
                ]
            );
        }
        else if (joinery_style == "tab_slot") {
            union() {
                sheet_box(
                    [
                        inner_width,
                        material_thickness,
                        stack_base_height
                    ],
                    [
                        material_thickness,
                        y0,
                        0
                    ]
                );

                for (i=[0:effective_tab_count(stack_base_height)-1]) {
                    tz =
                        tab_start(stack_base_height,i);
                    tw =
                        tab_width_for(stack_base_height);

                    sheet_box(
                        [
                            material_thickness,
                            material_thickness,
                            tw
                        ],
                        [0,y0,tz]
                    );

                    sheet_box(
                        [
                            material_thickness,
                            material_thickness,
                            tw
                        ],
                        [
                            resolved_cabinet_width-material_thickness,
                            y0,
                            tz
                        ]
                    );
                }
            }
        }
    }
}


module stack_base_cross_rail_cut() {
    if (stack_base_active) {
        if (joinery_style == "butt") {
            cut_part(
                inner_width,
                stack_base_height
            );
        }
        else if (joinery_style == "dado") {
            cut_part(
                inner_width+2*effective_dado_depth(),
                stack_base_height
            );
        }
        else if (joinery_style == "tab_slot") {
            union() {
                translate([material_thickness,0])
                    cut_part(
                        inner_width,
                        stack_base_height
                    );

                for (i=[0:effective_tab_count(stack_base_height)-1]) {
                    tz =
                        tab_start(stack_base_height,i);
                    tw =
                        tab_width_for(stack_base_height);

                    translate([0,tz])
                        cut_part(
                            material_thickness,
                            tw
                        );

                    translate([
                        resolved_cabinet_width-material_thickness,
                        tz
                    ])
                        cut_part(
                            material_thickness,
                            tw
                        );
                }
            }
        }
    }
}


module stack_base_assembly_3d() {
    if (stack_base_active && show_stack_base) {
        paint("stack_base_side")
            stack_base_side_rail_3d(
                0,
                "left"
            );

        paint("stack_base_side")
            stack_base_side_rail_3d(
                resolved_cabinet_width-material_thickness,
                "right"
            );

        paint("stack_base_cross")
            stack_base_cross_rail_3d(
                0
            );

        paint("stack_base_cross")
            stack_base_cross_rail_3d(
                resolved_cabinet_depth-material_thickness
            );
    }
}


// ---------------------------
// FACE FRAME / FRONT FACING
// ---------------------------

// Back-side pocket positions in each individual face-frame strip.
//
// Stiles receive the front edges of the cabinet SIDE panels.
// Top rail receives the front top panel / front stretcher.
// Bottom rail receives the cabinet bottom front edge.
// Auto combo mid rail receives the combo divider front edge.
//
// Because the perimeter support meets the edge of the strip, these are
// technically back rabbets at the strip edge, but they are exported with the
// blind-pocket operations as the requested "back dado" construction.

module face_frame_stile_back_dado_pocket_2d(side="left") {
    if (face_frame_back_dado_active) {
        w = min(
            effective_face_frame_side_stile_width,
            face_frame_back_dado_width
        );

        if (side == "left")
            square([
                w,
                face_frame_stile_cut_height
            ]);
        else
            translate([
                effective_face_frame_side_stile_width-w,
                0
            ])
                square([
                    w,
                    face_frame_stile_cut_height
                ]);
    }
}


module face_frame_top_rail_back_dado_pocket_2d() {
    if (face_frame_back_dado_active) {
        h = min(
            effective_face_frame_top_rail_width,
            face_frame_back_dado_width
        );

        translate([
            0,
            effective_face_frame_top_rail_width-h
        ])
            square([
                face_frame_rail_cut_width,
                h
            ]);
    }
}


module face_frame_bottom_rail_back_dado_pocket_2d() {
    if (face_frame_back_dado_active) {
        h = min(
            effective_face_frame_bottom_rail_width,
            face_frame_back_dado_width
        );

        square([
            face_frame_rail_cut_width,
            h
        ]);
    }
}


module face_frame_mid_rail_back_dado_pocket_2d() {
    if (
        face_frame_back_dado_active
        && face_frame_mid_rail_active
    ) {
        h = min(
            effective_face_frame_mid_rail_width,
            face_frame_back_dado_width
        );

        // combo_auto places the divider immediately BELOW the rail center,
        // so its front edge enters the lower edge of the mid rail.
        square([
            face_frame_mid_rail_cut_width,
            h
        ]);
    }
}


// 3D pocket subtraction from the physical BACK face.  In assembly coordinates
// the carcass begins at Y=0 and the frame back extends to +dado_depth.
module face_frame_stile_back_dado_cut_3d(
    x0,
    side="left"
) {
    if (face_frame_back_dado_active) {
        w = min(
            effective_face_frame_side_stile_width,
            face_frame_back_dado_width
        );

        px =
            side == "left"
                ? x0
                : x0
                  + effective_face_frame_side_stile_width
                  - w;

        translate([
            px,
            -0.01,
            face_frame_bottom_z-0.01
        ])
            cube([
                w,
                effective_face_frame_back_dado_depth+0.02,
                face_frame_height+0.02
            ]);
    }
}


module face_frame_rail_back_dado_cut_3d(
    z0,
    rail_width,
    pocket_from="bottom"
) {
    if (face_frame_back_dado_active) {
        h = min(
            rail_width,
            face_frame_back_dado_width
        );

        pz =
            pocket_from == "top"
                ? z0+rail_width-h
                : z0;

        translate([
            effective_face_frame_side_stile_width-0.01,
            -0.01,
            pz-0.01
        ])
            cube([
                face_frame_rail_cut_width+0.02,
                effective_face_frame_back_dado_depth+0.02,
                h+0.02
            ]);
    }
}


module face_frame_stile_3d(x0,side="left") {
    if (face_frame_active)
        difference() {
            sheet_box(
                [
                    effective_face_frame_side_stile_width,
                    effective_face_frame_thickness,
                    face_frame_height
                ],
                [
                    x0,
                    face_frame_front_y,
                    face_frame_bottom_z
                ]
            );

            face_frame_stile_back_dado_cut_3d(
                x0,
                side
            );
        }
}


module face_frame_rail_3d(
    z0,
    width,
    pocket_from="bottom"
) {
    if (face_frame_active)
        difference() {
            sheet_box(
                [
                    face_frame_rail_cut_width,
                    effective_face_frame_thickness,
                    width
                ],
                [
                    effective_face_frame_side_stile_width,
                    face_frame_front_y,
                    z0
                ]
            );

            face_frame_rail_back_dado_cut_3d(
                z0,
                width,
                pocket_from
            );
        }
}


module face_frame_center_stile_3d() {
    if (face_frame_center_stile_enabled)
        sheet_box(
            [
                effective_face_frame_center_stile_width,
                effective_face_frame_thickness,
                face_frame_center_stile_cut_height
            ],
            [
                resolved_cabinet_width/2
                    - effective_face_frame_center_stile_width/2,
                face_frame_front_y,
                face_frame_clear_bottom_z
            ]
        );
}


module face_frame_mid_rail_3d() {
    if (face_frame_mid_rail_active)
        difference() {
            sheet_box(
                [
                    face_frame_mid_rail_cut_width,
                    effective_face_frame_thickness,
                    effective_face_frame_mid_rail_width
                ],
                [
                    effective_face_frame_side_stile_width,
                    face_frame_front_y,
                    face_frame_mid_rail_center_z
                        - effective_face_frame_mid_rail_width/2
                ]
            );

            if (face_frame_back_dado_active)
                face_frame_rail_back_dado_cut_3d(
                    face_frame_mid_rail_center_z
                        - effective_face_frame_mid_rail_width/2,
                    effective_face_frame_mid_rail_width,
                    "bottom"
                );
        }
}


module face_frame_assembly_3d() {
    if (face_frame_active) {
        paint("face_frame")
            face_frame_stile_3d(
                0,
                "left"
            );

        paint("face_frame")
            face_frame_stile_3d(
                resolved_cabinet_width
                - effective_face_frame_side_stile_width,
                "right"
            );

        paint("face_frame")
            face_frame_rail_3d(
                face_frame_top_z
                - effective_face_frame_top_rail_width,
                effective_face_frame_top_rail_width,
                "top"
            );

        paint("face_frame")
            face_frame_rail_3d(
                face_frame_bottom_z,
                effective_face_frame_bottom_rail_width,
                "bottom"
            );

        if (face_frame_mid_rail_active)
            paint("face_frame")
                face_frame_mid_rail_3d();

        if (face_frame_center_stile_enabled)
            paint("face_frame")
                face_frame_center_stile_3d();
    }
}


module face_frame_stile_cut() {
    if (face_frame_active)
        cut_part(
            effective_face_frame_side_stile_width,
            face_frame_stile_cut_height
        );
}


module face_frame_top_rail_cut() {
    if (face_frame_active)
        cut_part(
            face_frame_rail_cut_width,
            effective_face_frame_top_rail_width
        );
}


module face_frame_bottom_rail_cut() {
    if (face_frame_active)
        cut_part(
            face_frame_rail_cut_width,
            effective_face_frame_bottom_rail_width
        );
}


module face_frame_mid_rail_cut() {
    if (face_frame_mid_rail_active)
        cut_part(
            face_frame_mid_rail_cut_width,
            effective_face_frame_mid_rail_width
        );
}


module face_frame_center_stile_cut() {
    if (face_frame_center_stile_enabled)
        cut_part(
            effective_face_frame_center_stile_width,
            face_frame_center_stile_cut_height
        );
}


module face_frame_stile_print_part(side="left") {
    if (face_frame_active)
        difference() {
            linear_extrude(
                height=effective_face_frame_thickness
            )
                face_frame_stile_cut();

            if (face_frame_back_dado_active)
                translate([
                    0,0,
                    effective_face_frame_thickness
                    - effective_face_frame_back_dado_depth
                ])
                    linear_extrude(
                        height=
                            effective_face_frame_back_dado_depth
                            + 0.02
                    )
                        face_frame_stile_back_dado_pocket_2d(
                            side
                        );
        }
}


module face_frame_top_rail_print_part() {
    if (face_frame_active)
        difference() {
            linear_extrude(
                height=effective_face_frame_thickness
            )
                face_frame_top_rail_cut();

            if (face_frame_back_dado_active)
                translate([
                    0,0,
                    effective_face_frame_thickness
                    - effective_face_frame_back_dado_depth
                ])
                    linear_extrude(
                        height=
                            effective_face_frame_back_dado_depth
                            + 0.02
                    )
                        face_frame_top_rail_back_dado_pocket_2d();
        }
}


module face_frame_bottom_rail_print_part() {
    if (face_frame_active)
        difference() {
            linear_extrude(
                height=effective_face_frame_thickness
            )
                face_frame_bottom_rail_cut();

            if (face_frame_back_dado_active)
                translate([
                    0,0,
                    effective_face_frame_thickness
                    - effective_face_frame_back_dado_depth
                ])
                    linear_extrude(
                        height=
                            effective_face_frame_back_dado_depth
                            + 0.02
                    )
                        face_frame_bottom_rail_back_dado_pocket_2d();
        }
}


module face_frame_mid_rail_print_part() {
    if (face_frame_mid_rail_active)
        difference() {
            linear_extrude(
                height=effective_face_frame_thickness
            )
                face_frame_mid_rail_cut();

            if (face_frame_back_dado_active)
                translate([
                    0,0,
                    effective_face_frame_thickness
                    - effective_face_frame_back_dado_depth
                ])
                    linear_extrude(
                        height=
                            effective_face_frame_back_dado_depth
                            + 0.02
                    )
                        face_frame_mid_rail_back_dado_pocket_2d();
        }
}


// ---------------------------
// WORKTOP REGISTRATION
// ---------------------------

module worktop_registration_support_holes_3d(
    panel_y0,
    panel_depth,
    z0
) {
    if (active_worktop_registration)
        for (r=[0:1]) {
            gy = worktop_registration_row_y(r);

            if (gy >= panel_y0
                && gy <= panel_y0+panel_depth)
                for (i=[0:worktop_registration_hole_count-1])
                    translate([
                        worktop_registration_x(i),
                        gy,
                        z0-1
                    ])
                        cylinder(
                            h=material_thickness+2,
                            d=worktop_registration_hole_diameter
                        );
        }
}

module worktop_registration_support_holes_2d(
    panel_y0,
    panel_depth
) {
    if (active_worktop_registration)
        for (r=[0:1]) {
            gy = worktop_registration_row_y(r);

            if (gy >= panel_y0
                && gy <= panel_y0+panel_depth)
                for (i=[0:worktop_registration_hole_count-1])
                    round_hole_2d(
                        horizontal_panel_local_x(
                            worktop_registration_x(i)
                        ),
                        gy-panel_y0,
                        worktop_registration_hole_diameter
                    );
        }
}

module worktop_registration_worktop_pockets_2d() {
    if (active_worktop_registration)
        for (r=[0:1])
            for (i=[0:worktop_registration_hole_count-1])
                round_hole_2d(
                    worktop_registration_worktop_local_x(i),
                    worktop_registration_worktop_local_y(r),
                    worktop_registration_hole_diameter
                );
}

module worktop_registration_worktop_pockets_3d() {
    if (active_worktop_registration)
        for (r=[0:1])
            for (i=[0:worktop_registration_hole_count-1])
                translate([
                    worktop_registration_x(i),
                    worktop_registration_row_y(r),
                    worktop_z-0.01
                ])
                    cylinder(
                        h=effective_worktop_registration_blind_depth+0.02,
                        d=worktop_registration_hole_diameter
                    );
}


// ---------------------------
// BASE HARDWARE / WORKTOP
// ---------------------------

module base_hardware_holes_plate_2d() {
    if (base_hardware_active
        && include_base_hardware_drill_holes)
        for (c=[0:3])
            for (h=[0:base_hardware_hole_count_per_corner()-1])
                round_hole_2d(
                    base_hardware_hole_global_x(c,h)
                        - base_mounting_plate_x,
                    base_hardware_hole_global_y(c,h)
                        - base_mounting_plate_y,
                    base_hardware_hole_diameter()
                );
}

module base_hardware_holes_bottom_2d() {
    if (base_hardware_active
        && !base_mounting_plate_active
        && include_base_hardware_drill_holes)
        for (c=[0:3])
            for (h=[0:base_hardware_hole_count_per_corner()-1])
                round_hole_2d(
                    bottom_panel_local_x(
                        base_hardware_hole_global_x(c,h)
                    ),
                    base_hardware_hole_global_y(c,h),
                    base_hardware_hole_diameter()
                );
}

module base_hardware_holes_plate_3d(z0) {
    if (base_hardware_active
        && include_base_hardware_drill_holes)
        for (c=[0:3])
            for (h=[0:base_hardware_hole_count_per_corner()-1])
                translate([
                    base_hardware_hole_global_x(c,h),
                    base_hardware_hole_global_y(c,h),
                    z0-1
                ])
                    cylinder(
                        h=material_thickness+2,
                        d=base_hardware_hole_diameter()
                    );
}

module base_hardware_holes_bottom_3d(z0) {
    if (base_hardware_active
        && !base_mounting_plate_active
        && include_base_hardware_drill_holes)
        for (c=[0:3])
            for (h=[0:base_hardware_hole_count_per_corner()-1])
                translate([
                    base_hardware_hole_global_x(c,h),
                    base_hardware_hole_global_y(c,h),
                    z0-1
                ])
                    cylinder(
                        h=material_thickness+2,
                        d=base_hardware_hole_diameter()
                    );
}

module base_mounting_plate_3d() {
    if (base_mounting_plate_active)
        difference() {
            sheet_box(
                [
                    base_mounting_plate_width,
                    base_mounting_plate_depth,
                    material_thickness
                ],
                [
                    base_mounting_plate_x,
                    base_mounting_plate_y,
                    -material_thickness
                ]
            );

            base_hardware_holes_plate_3d(
                -material_thickness);
        }
}

module base_mounting_plate_cut() {
    if (base_mounting_plate_active)
        cut_part(
            base_mounting_plate_width,
            base_mounting_plate_depth
        );
}

module worktop_3d() {
    if (worktop_active)
        difference() {
            sheet_box(
                [
                    worktop_width,
                    worktop_depth,
                    worktop_thickness
                ],
                [worktop_x,worktop_y,worktop_z]
            );

            worktop_registration_worktop_pockets_3d();
        }
}

module worktop_cut() {
    if (worktop_active)
        cut_part(worktop_width,worktop_depth);
}

module caster_visual_3d(c=0) {
    cx = base_hardware_center_x_for_index(c);
    cy = base_hardware_center_y_for_index(c);
    surface_z =
        base_mounting_plate_active
            ? -material_thickness
            : 0;

    // Generic mounting plate.
    translate([
        cx-caster_mount_plate_width/2,
        cy-caster_mount_plate_depth/2,
        surface_z-4
    ])
        cube([
            caster_mount_plate_width,
            caster_mount_plate_depth,
            4
        ]);

    // Generic wheel envelope; intended for fit/clearance visualization only.
    translate([
        cx,
        cy,
        surface_z-caster_height+caster_wheel_diameter/2
    ])
        rotate([90,0,0])
            cylinder(
                h=max(12,caster_mount_plate_depth*0.35),
                d=caster_wheel_diameter,
                center=true
            );
}

module leveler_visual_3d(c=0) {
    cx = base_hardware_center_x_for_index(c);
    cy = base_hardware_center_y_for_index(c);
    surface_z =
        base_mounting_plate_active
            ? -material_thickness
            : 0;

    translate([
        cx,cy,
        surface_z-leveler_height
    ])
        cylinder(
            h=leveler_height,
            d=max(6,leveler_mount_hole_diameter*0.65)
        );

    translate([
        cx,cy,
        surface_z-leveler_height-4
    ])
        cylinder(
            h=4,
            d=leveler_foot_diameter
        );
}

module base_hardware_visual_3d() {
    if (base_hardware_active)
        for (c=[0:3])
            if (active_base_style == "casters")
                caster_visual_3d(c);
            else
                leveler_visual_3d(c);
}


// ---------------------------
// 3D CARCASS
// ---------------------------

module carcass() {
    if (show_carcass_sides) {
        paint("side_left")
            cabinet_side_panel_3d(0,"left");
        paint("side_right")
            cabinet_side_panel_3d(
                resolved_cabinet_width-material_thickness,"right");
    }

    if (show_carcass_bottom)
        paint("bottom")
            difference() {
                cabinet_bottom_3d();

                base_hardware_holes_bottom_3d(
                    bottom_above_toe);
            }

    if (show_toe_kick && has_toe_kick)
        paint("toe_kick")
            joined_toe_kick_3d();

    if (show_carcass_top) {
        if (top_style == "full") {
            paint("top_full")
                difference() {
                    joined_horizontal_bank_receiver_3d(
                        0,resolved_cabinet_depth,
                        cabinet_height-material_thickness,
                        "bottom","same","top");

                    worktop_registration_support_holes_3d(
                        0,resolved_cabinet_depth,
                        cabinet_height-material_thickness
                    );
                }
        } else {
            paint("top_front")
                difference() {
                    joined_horizontal_bank_receiver_3d(
                        0,top_stretcher_depth,
                        cabinet_height-material_thickness,
                        "bottom","same","top");

                    worktop_registration_support_holes_3d(
                        0,top_stretcher_depth,
                        cabinet_height-material_thickness
                    );
                }

            paint("top_rear")
                difference() {
                    joined_horizontal_bank_receiver_3d(
                        resolved_cabinet_depth-top_stretcher_depth,
                        top_stretcher_depth,
                        cabinet_height-material_thickness,
                        "bottom","same","top");

                    worktop_registration_support_holes_3d(
                        resolved_cabinet_depth-top_stretcher_depth,
                        top_stretcher_depth,
                        cabinet_height-material_thickness
                    );
                }
        }
    }

    if (show_back_construction) {
        if (back_style == "panel"
            || back_style == "structural_panel") {
            paint("back")
                back_panel_3d();
        } else if (back_style == "stretchers") {
            for (b=[0:back_stretcher_count-1])
                paint("back_stretcher",b)
                    joined_back_stretcher_3d(
                        back_stretcher_z(b));
        }
    }

    if (show_combo_divider
        && !mixed_bay_mode
        && cabinet_contents == "combo"
        && door_region_height > material_thickness) {
        paint("divider")
            joined_horizontal_bank_receiver_3d(
                shelf_front_y,shelf_depth,
                combo_divider_bottom_z,
                "top","bottom","shelf");
    }

    if (show_shelves
        && !mixed_bay_mode
        && has_doors
        && door_shelf_count > 0
        && door_region_height > 60) {

        for (s=[1:door_shelf_count]) {
            if (shelf_style == "fixed") {
                paint("shelf",s)
                    fixed_door_shelf_3d(
                        door_shelf_z(s));
            } else {
                for (b=[0:door_adjustable_shelf_piece_count()-1])
                    paint("shelf",s*10+b)
                        adjustable_door_shelf_3d(
                            door_shelf_z(s),b);
            }
        }
    }

    if (show_shelves && mixed_bay_mode) {
        for (b=[0:active_mixed_bay_count-1])
            if (mixed_bay_is_shelfable(b) && mixed_bay_shelf_count(b) > 0)
                for (s=[1:mixed_bay_shelf_count(b)])
                    paint("shelf",mixed_bay_shelf_part_index(b,s))
                        if (mixed_bay_shelf_style(b) == "fixed")
                            mixed_bay_fixed_shelf_3d(
                                b,mixed_bay_shelf_z(b,s));
                        else
                            mixed_bay_adjustable_shelf_3d(
                                b,mixed_bay_shelf_z(b,s));
    }

    if (show_mixed_bay_partitions
        && mixed_bay_partition_count() > 0) {
        for (p=[0:mixed_bay_partition_count()-1])
            paint("mixed_bay_partition",p)
                mixed_bay_partition_3d(p);
    }

    if (show_door_hinge_partitions
        && door_hinge_partition_count() > 0) {
        for (p=[0:door_hinge_partition_count()-1])
            paint("door_hinge_partition",p)
                door_hinge_partition_3d(p);
    }

    if (show_drawer_bank_partitions
        && has_drawers
        && drawer_bank_partition_count() > 0) {
        for (p=[0:drawer_bank_partition_count()-1])
            paint("drawer_bank_partition",p)
                drawer_bank_partition_3d(p);
    }

    if (show_drawer_separators && drawer_separator_count > 0) {
        for (s=[0:drawer_separator_count-1]) {
            sep_z = drawer_separator_z(s);

            if (drawer_separator_style == "full") {
                paint("drawer_separator",s)
                    joined_horizontal_panel_3d(
                        drawer_separator_front_y,
                        drawer_separator_full_depth,
                        sep_z,"separator");
            } else {
                paint("drawer_separator",s)
                    joined_horizontal_panel_3d(
                        drawer_separator_front_y,
                        drawer_separator_stretcher_actual_depth,
                        sep_z,"separator");

                paint("drawer_separator",s)
                    joined_horizontal_panel_3d(
                        drawer_separator_front_y
                            + drawer_separator_full_depth
                            - drawer_separator_stretcher_actual_depth,
                        drawer_separator_stretcher_actual_depth,
                        sep_z,"separator");
            }
        }
    }

    // Fixed cabinet-side / partition-side portions of optional drawer slides.
    if (show_drawer_slide_parts
        && has_drawers
        && drawer_mount == "wood_rails") {

        for (b=[0:active_drawer_bank_count()-1])
            if (drawer_bank_drawer_count(b) > 0)
                for (i=[0:drawer_bank_drawer_count(b)-1]) {
                rz = drawer_rail_z(i,b);
                ox = drawer_bank_opening_x(b);
                ow = drawer_bank_opening_width(b);
                pi = drawer_part_index(b,i);

                paint("rail",pi)
                    wood_fixed_rail_3d(
                        ox,
                        effective_wood_rail_front_setback,
                        rz
                    );

                paint("rail",pi)
                    wood_fixed_rail_3d(
                        ox+ow-wood_rail_thickness,
                        effective_wood_rail_front_setback,
                        rz
                    );
            }
    }

    if (show_drawer_slide_parts
        && has_drawers
        && drawer_mount == "metal_slides"
        && show_metal_slide_envelopes) {

        for (b=[0:active_drawer_bank_count()-1])
            if (drawer_bank_drawer_count(b) > 0)
                for (i=[0:drawer_bank_drawer_count(b)-1]) {
                rz = drawer_box_z(i,b);
                ox = drawer_bank_opening_x(b);
                ow = drawer_bank_opening_width(b);

                color([0.25,0.25,0.25,0.35]) {
                    translate([
                        ox,
                        effective_metal_slide_front_setback,
                        rz
                    ])
                        cube([
                            effective_metal_slide_clearance_per_side,
                            active_slide_length(),
                            effective_metal_slide_envelope_height
                        ]);

                    translate([
                        ox+ow-effective_metal_slide_clearance_per_side,
                        effective_metal_slide_front_setback,
                        rz
                    ])
                        cube([
                            effective_metal_slide_clearance_per_side,
                            active_slide_length(),
                            effective_metal_slide_envelope_height
                        ]);
                }
            }
    }

    if (show_base_hardware) {
        if (base_mounting_plate_active)
            paint("base_mounting_plate")
                base_mounting_plate_3d();

        if (base_hardware_active)
            paint(
                active_base_style == "casters"
                    ? "caster"
                    : "leveler"
            )
                base_hardware_visual_3d();
    }

    if (show_worktop && worktop_active)
        paint("worktop")
            worktop_3d();
}


// ---------------------------
// DRAWERS
// ---------------------------

// ---------- Drawer side joinery ----------

// Through tab slots in a drawer side's local depth/height plane.
module drawer_side_tab_slots_2d(d,bh) {
    if (drawer_joinery_style == "tab_slot") {
        c = drawer_joint_fit_clearance;
        st = drawer_material_thickness;

        for (n=[0:effective_tab_count(bh)-1]) {
            tz = tab_start(bh,n)-c/2;
            th = tab_width_for(bh)+c;

            // Front and rear box panels.
            translate([-c/2,tz])
                slot_shape_2d(st+c,th);

            translate([d-st-c/2,tz])
                slot_shape_2d(st+c,th);
        }
    }
}

// Blind pocket geometry in a drawer side, local depth/height coordinates.
module drawer_side_corner_dado_pockets_2d(d,bh) {
    if (drawer_joinery_style == "dado") {
        c = drawer_dado_fit_clearance;
        st = drawer_material_thickness;

        translate([-c/2,-c/2])
            square([st+c,bh+c]);

        translate([d-st-c/2,-c/2])
            square([st+c,bh+c]);
    }
}

module drawer_side_bottom_groove_pocket_2d(d,bh) {
    if (drawer_bottom_joinery == "dado") {
        c = drawer_dado_fit_clearance;
        st = drawer_material_thickness;
        bdd = effective_drawer_bottom_dado_depth();

        translate([
            st-bdd-c/2,
            drawer_bottom_inset-c/2
        ])
            square([
                drawer_bottom_depth()+c,
                drawer_bottom_thickness+c
            ]);
    }
}

module drawer_side_dado_pockets_2d(d,bh) {
    drawer_side_corner_dado_pockets_2d(d,bh);
    drawer_side_bottom_groove_pocket_2d(d,bh);
}

// Blind bottom groove in a drawer front/back panel, local width/height.
module drawer_cross_panel_bottom_pocket_2d(bh,b=0) {
    if (drawer_bottom_joinery == "dado") {
        c = drawer_dado_fit_clearance;

        translate([
            drawer_bottom_cross_panel_local_x()-c/2,
            drawer_bottom_inset-c/2
        ])
            square([
                drawer_bottom_width(b)+c,
                drawer_bottom_thickness+c
            ]);
    }
}

// 3D blind cuts in one drawer side.
// "left"/"right" tells us which face is the drawer interior.
module drawer_side_blind_joinery_3d(x0,y0,z0,d,bh,side) {
    c = drawer_dado_fit_clearance;
    st = drawer_material_thickness;

    if (drawer_joinery_style == "dado") {
        dd = effective_drawer_dado_depth();

        cut_x =
            side == "left"
                ? x0 + st - dd
                : x0 - 0.01;

        // Front dado.
        translate([
            cut_x,
            y0-c/2,
            z0-c/2
        ])
            cube([
                dd+0.02,
                st+c,
                bh+c
            ]);

        // Rear dado.
        translate([
            cut_x,
            y0+d-st-c/2,
            z0-c/2
        ])
            cube([
                dd+0.02,
                st+c,
                bh+c
            ]);
    }

    if (drawer_bottom_joinery == "dado") {
        bdd = effective_drawer_bottom_dado_depth();

        cut_x =
            side == "left"
                ? x0 + st - bdd
                : x0 - 0.01;

        translate([
            cut_x,
            y0 + st - bdd - c/2,
            z0 + drawer_bottom_inset - c/2
        ])
            cube([
                bdd+0.02,
                drawer_bottom_depth()+c,
                drawer_bottom_thickness+c
            ]);
    }
}

module drawer_side_through_joinery_3d(x0,y0,z0,d,bh) {
    if (drawer_joinery_style == "tab_slot") {
        c = drawer_joint_fit_clearance;
        st = drawer_material_thickness;

        for (n=[0:effective_tab_count(bh)-1]) {
            tz = z0 + tab_start(bh,n)-c/2;
            th = tab_width_for(bh)+c;

            slot_cut_x_3d(
                x0-1,
                st+2,
                y0-c/2,
                tz,
                st+c,
                th
            );

            slot_cut_x_3d(
                x0-1,
                st+2,
                y0+d-st-c/2,
                tz,
                st+c,
                th
            );
        }
    }
}


// ---------- Drawer side panel ----------

module drawer_side_panel_3d(x0,y0,z0,d,bh,i=0,side="left") {
    st = drawer_material_thickness;

    difference() {
        translate([x0,y0,z0]) cube([st,d,bh]);

        drawer_side_through_joinery_3d(
            x0,y0,z0,d,bh);

        drawer_side_blind_joinery_3d(
            x0,y0,z0,d,bh,side);

        if (drawer_mount == "metal_slides" && include_metal_slide_holes) {
            hole_z = z0 + effective_metal_slide_drawer_hole_z;

            for (hx=active_slide_drawer_holes())
                if (drawer_slide_hole_is_valid(hx,d))
                    metal_hole_x_3d(x0-1,y0+slide_drawer_hole_depth(hx),hole_z,st+2,effective_metal_slide_drawer_hole_diameter);
        }

        if (drawer_mount == "wood_rails"
            && include_wood_slide_registration_holes
            && wood_drawer_runner_reg_valid(d)) {

            for (n=[0:wood_slide_registration_hole_count-1]) {
                round_hole_x_3d(
                    x0-1,
                    y0
                        + wood_drawer_runner_local_front()
                        + wood_drawer_runner_reg_pos(d,n),
                    z0
                        + wood_drawer_runner_bottom_offset
                        + wood_drawer_runner_height/2,
                    st+2,
                    wood_slide_registration_hole_diameter
                );
            }
        }
    }
}

module drawer_side_panel_cut(d,bh,i=0) {
    difference() {
        cut_part(d,bh);

        drawer_side_tab_slots_2d(d,bh);

        if (drawer_mount == "metal_slides" && include_metal_slide_holes) {
            for (hx=active_slide_drawer_holes())
                if (drawer_slide_hole_is_valid(hx,d))
                    metal_hole_2d(slide_drawer_hole_depth(hx),effective_metal_slide_drawer_hole_z,effective_metal_slide_drawer_hole_diameter);
        }

        if (drawer_mount == "wood_rails"
            && include_wood_slide_registration_holes
            && wood_drawer_runner_reg_valid(d)) {

            for (n=[0:wood_slide_registration_hole_count-1])
                round_hole_2d(
                    wood_drawer_runner_local_front()
                        + wood_drawer_runner_reg_pos(d,n),
                    wood_drawer_runner_bottom_offset
                        + wood_drawer_runner_height/2,
                    wood_slide_registration_hole_diameter
                );
        }
    }
}


// ---------- Drawer front/back box panels ----------

// 2D profile. Local X = drawer width; local Y = panel height.
module drawer_cross_panel_cut(bh,is_front=false,b=0) {
    st = drawer_material_thickness;
    iw = drawer_inner_width(b);
    ow = drawer_outer_width(b);

    difference() {
        if (drawer_joinery_style == "butt") {
            cut_part(iw,bh);
        }
        else if (drawer_joinery_style == "dado") {
            cut_part(
                iw+2*effective_drawer_dado_depth(),
                bh
            );
        }
        else if (drawer_joinery_style == "tab_slot") {
            union() {
                translate([st,0])
                    cut_part(iw,bh);

                for (n=[0:effective_tab_count(bh)-1]) {
                    tz = tab_start(bh,n);
                    th = tab_width_for(bh);

                    translate([0,tz])
                        cut_part(st,th);

                    translate([ow-st,tz])
                        cut_part(st,th);
                }
            }
        }

        // Drawer BOX FRONT registration holes are used only with an applied face.
        if (is_front && active_drawer_face_registration) {
            for (n=[0:drawer_face_registration_hole_count-1])
                round_hole_2d(
                    drawer_face_reg_box_local_x(n,b),
                    bh/2 + drawer_face_registration_vertical_offset,
                    drawer_face_registration_hole_diameter
                );
        }

        // With no decorative face, handle holes move to the structural box front.
        if (is_front
            && !include_drawer_faces
            && include_drawer_handle_holes) {
            cx = drawer_cross_panel_width(b)/2;
            cy = bh/2 + drawer_handle_vertical_offset;

            if (handle_hole_pattern == "single_hole")
                round_hole_2d(cx,cy,handle_hole_diameter);
            else
                for (dx=[-handle_hole_spacing/2,handle_hole_spacing/2])
                    round_hole_2d(
                        cx+dx,cy,handle_hole_diameter);
        }
    }
}

// Assembly geometry for either the front or rear box panel.
// Rear/front differ only in Y placement and which face gets the bottom groove.
module drawer_cross_panel_3d(
    x0,y_panel,z0,bh,is_front=true,b=0
) {
    st = drawer_material_thickness;
    iw = drawer_inner_width(b);
    ow = drawer_outer_width(b);
    dd = effective_drawer_dado_depth();

    difference() {
        union() {
            if (drawer_joinery_style == "butt") {
                sheet_box(
                    [iw,st,bh],
                    [x0+st,y_panel,z0]
                );
            }
            else if (drawer_joinery_style == "dado") {
                sheet_box(
                    [iw+2*dd,st,bh],
                    [x0+st-dd,y_panel,z0]
                );
            }
            else if (drawer_joinery_style == "tab_slot") {
                sheet_box(
                    [iw,st,bh],
                    [x0+st,y_panel,z0]
                );

                for (n=[0:effective_tab_count(bh)-1]) {
                    tz = z0 + tab_start(bh,n);
                    th = tab_width_for(bh);

                    sheet_box(
                        [st,st,th],
                        [x0,y_panel,tz]
                    );

                    sheet_box(
                        [st,st,th],
                        [x0+ow-st,y_panel,tz]
                    );
                }
            }
        }

        // Optional bottom groove, independent of the side joinery choice.
        if (drawer_bottom_joinery == "dado") {
            c = drawer_dado_fit_clearance;
            bdd = effective_drawer_bottom_dado_depth();

            groove_y =
                is_front
                    ? y_panel + st - bdd - 0.01
                    : y_panel - 0.01;

            translate([
                x0 + st - bdd - c/2,
                groove_y,
                z0 + drawer_bottom_inset - c/2
            ])
                cube([
                    drawer_bottom_width(b)+c,
                    bdd+0.02,
                    drawer_bottom_thickness+c
                ]);
        }

        // Matching through-holes in the drawer BOX FRONT.
        if (is_front && active_drawer_face_registration) {
            for (n=[0:drawer_face_registration_hole_count-1])
                round_hole_y_3d(
                    x0 + ow/2 + drawer_face_reg_dx(n),
                    y_panel + st + 1,
                    z0 + bh/2
                       + drawer_face_registration_vertical_offset,
                    st+2,
                    drawer_face_registration_hole_diameter
                );
        }

        // With no decorative face, handle holes belong to the box front.
        if (is_front
            && !include_drawer_faces
            && include_drawer_handle_holes) {
            cx = x0 + ow/2;
            cz = z0 + bh/2 + drawer_handle_vertical_offset;

            if (handle_hole_pattern == "single_hole")
                round_hole_y_3d(
                    cx,y_panel+st+1,cz,
                    st+2,handle_hole_diameter);
            else
                for (dx=[-handle_hole_spacing/2,handle_hole_spacing/2])
                    round_hole_y_3d(
                        cx+dx,y_panel+st+1,cz,
                        st+2,handle_hole_diameter);
        }
    }
}


// ---------- Drawer bottom ----------

module drawer_bottom_3d(x0,y0,z0,b=0) {
    bdd =
        drawer_bottom_joinery == "dado"
            ? effective_drawer_bottom_dado_depth()
            : 0;

    sheet_box(
        [
            drawer_bottom_width(b),
            drawer_bottom_depth(),
            drawer_bottom_thickness
        ],
        [
            x0 + drawer_material_thickness - bdd,
            y0 + drawer_material_thickness - bdd,
            z0 + drawer_bottom_inset
        ]
    );
}

module drawer_bottom_cut(b=0) {
    cut_part(
        drawer_bottom_width(b),
        drawer_bottom_depth()
    );
}


// ---------- Flat blind-pocket helpers for CAM / print layout ----------

module drawer_side_print_part(d,bh,i=0) {
    difference() {
        linear_extrude(height=drawer_material_thickness)
            drawer_side_panel_cut(d,bh,i);

        if (drawer_joinery_style == "dado"
            || drawer_bottom_joinery == "dado") {

            translate([
                0,0,
                drawer_material_thickness
                    - max(
                        drawer_joinery_style == "dado"
                            ? effective_drawer_dado_depth()
                            : 0,
                        drawer_bottom_joinery == "dado"
                            ? effective_drawer_bottom_dado_depth()
                            : 0
                    )
            ])
                linear_extrude(
                    height=max(
                        drawer_joinery_style == "dado"
                            ? effective_drawer_dado_depth()
                            : 0,
                        drawer_bottom_joinery == "dado"
                            ? effective_drawer_bottom_dado_depth()
                            : 0
                    ) + 0.02
                )
                    drawer_side_dado_pockets_2d(d,bh);
        }
    }
}

// Uses a single print-face orientation for the blind bottom groove.
module drawer_cross_panel_print_part(bh,is_front=false,b=0) {
    difference() {
        linear_extrude(height=drawer_material_thickness)
            drawer_cross_panel_cut(bh,is_front,b);

        if (drawer_bottom_joinery == "dado") {
            bdd = effective_drawer_bottom_dado_depth();

            translate([
                0,0,
                drawer_material_thickness-bdd
            ])
                linear_extrude(height=bdd+0.02)
                    drawer_cross_panel_bottom_pocket_2d(bh,b);
        }
    }
}


// ---------- Drawer dado pocket layout ----------

module drawer_joinery_dado_pocket_layout() {
    if (has_drawers && drawer_joinery_style == "dado") {
        g = layout_gap;
        d = drawer_box_depth;

        for (b=[0:active_drawer_bank_count()-1])
            if (drawer_bank_drawer_count(b) > 0)
                for (i=[0:drawer_bank_drawer_count(b)-1]) {
                bh = drawer_box_height(i,b);
                side_y = drawer_layout_box_parts_y(b,i);
                pi = drawer_part_index(b,i);

                paint("drawer_side_l",pi)
                    translate([0,side_y])
                        drawer_side_corner_dado_pockets_2d(d,bh);

                paint("drawer_side_r",pi)
                    translate([d+g,side_y])
                        drawer_side_corner_dado_pockets_2d(d,bh);
            }
    }
}

module drawer_bottom_groove_pocket_layout() {
    if (has_drawers && drawer_bottom_joinery == "dado") {
        g = layout_gap;
        d = drawer_box_depth;

        for (b=[0:active_drawer_bank_count()-1])
            if (drawer_bank_drawer_count(b) > 0)
                for (i=[0:drawer_bank_drawer_count(b)-1]) {
                bh = drawer_box_height(i,b);
                side_y = drawer_layout_box_parts_y(b,i);
                pi = drawer_part_index(b,i);

                paint("drawer_side_l",pi)
                    translate([0,side_y])
                        drawer_side_bottom_groove_pocket_2d(d,bh);

                paint("drawer_side_r",pi)
                    translate([d+g,side_y])
                        drawer_side_bottom_groove_pocket_2d(d,bh);

                cross_x = 2*(d+g);

                paint("drawer_box_front",pi)
                    translate([cross_x,side_y])
                        drawer_cross_panel_bottom_pocket_2d(bh,b);

                paint("drawer_box_back",pi)
                    translate([cross_x,side_y+bh+g])
                        drawer_cross_panel_bottom_pocket_2d(bh,b);
            }
    }
}

module drawer_dado_pocket_layout() {
    drawer_joinery_dado_pocket_layout();
    drawer_bottom_groove_pocket_layout();
}


// Drawer-mounted portion of the two-piece wooden slide.
// This is intentionally separate from drawer_box() so it can be grouped with
// the drawer in every drawer-only display mode, even when drawer boxes are
// hidden and only drawer fronts are being previewed.
module drawer_mounted_wood_slides(i=0,b=0) {
    if (has_drawers && drawer_mount == "wood_rails") {
        ow = drawer_outer_width(b);
        x0 = drawer_box_x0(b);
        runner_z = drawer_runner_z(i,b);
        pi = drawer_part_index(b,i);

        paint("drawer_runner",pi)
            wood_drawer_runner_3d(
                x0-wood_drawer_runner_thickness,
                effective_wood_drawer_runner_front_setback,
                runner_z
            );

        paint("drawer_runner",pi)
            wood_drawer_runner_3d(
                x0+ow,
                effective_wood_drawer_runner_front_setback,
                runner_z
            );
    }
}


// ---------------------------
// DRAWER FACE HARDWARE
// ---------------------------

module drawer_face_3d(i=0,b=0) {
    fh = drawer_face_height_for(i,b);

    difference() {
        sheet_box(
            [drawer_face_width(b),drawer_front_thickness,fh],
            [
                drawer_face_x(b),
                decorative_front_y(drawer_front_thickness),
                drawer_face_z(i,b)
            ]
        );

        if (include_drawer_handle_holes) {
            cx = drawer_face_x(b) + drawer_face_width(b)/2;
            cz = drawer_face_z(i,b)
                 + fh/2
                 + drawer_handle_vertical_offset;

            if (handle_hole_pattern == "single_hole") {
                round_hole_y_3d(
                    cx,
                    decorative_front_through_drill_start_y(
                        drawer_front_thickness),
                    cz,
                    drawer_front_thickness+2,
                    handle_hole_diameter
                );
            } else {
                for (dx=[-handle_hole_spacing/2,handle_hole_spacing/2])
                    round_hole_y_3d(
                        cx+dx,
                        decorative_front_through_drill_start_y(
                            drawer_front_thickness),
                        cz,
                        drawer_front_thickness+2,
                        handle_hole_diameter
                    );
            }
        }

        // Matching registration holes in the decorative drawer FACE.
        if (active_drawer_face_registration) {
            face_depth =
                drawer_face_registration_face_hole == "through"
                    ? drawer_front_thickness+2
                    : drawer_face_registration_blind_depth()+0.02;

            face_start_y =
                drawer_face_registration_face_hole == "through"
                    ? decorative_front_through_drill_start_y(
                        drawer_front_thickness)
                    : decorative_front_blind_drill_start_y(
                        drawer_front_thickness);

            for (n=[0:drawer_face_registration_hole_count-1])
                round_hole_y_3d(
                    drawer_face_reg_global_x(n,b),
                    face_start_y,
                    drawer_face_reg_global_z(i,b),
                    face_depth,
                    drawer_face_registration_hole_diameter
                );
        }
    }
}

module drawer_face_cut(i=0,b=0) {
    fh = drawer_face_height_for(i,b);

    difference() {
        cut_part(drawer_face_width(b),fh);

        if (include_drawer_handle_holes) {
            cx = drawer_face_width(b)/2;
            cy = fh/2 + drawer_handle_vertical_offset;

            if (handle_hole_pattern == "single_hole") {
                round_hole_2d(cx,cy,handle_hole_diameter);
            } else {
                for (dx=[-handle_hole_spacing/2,handle_hole_spacing/2])
                    round_hole_2d(
                        cx+dx,cy,handle_hole_diameter
                    );
            }
        }

        // Through registration holes belong in cut_layout. Half-depth face
        // registration holes are exported through pocket_layout instead.
        if (active_drawer_face_registration
            && drawer_face_registration_face_hole == "through") {

            for (n=[0:drawer_face_registration_hole_count-1])
                round_hole_2d(
                    drawer_face_reg_face_local_x(n,b),
                    drawer_face_reg_face_local_z(i,b),
                    drawer_face_registration_hole_diameter
                );
        }
    }
}


// Blind half-depth registration holes in decorative drawer faces, positioned
// exactly over those faces in cut_layout.
module drawer_face_registration_pocket_layout() {
    if (has_drawers
        && active_drawer_face_registration
        && drawer_face_registration_face_hole == "half_depth") {

        for (b=[0:active_drawer_bank_count()-1])
            if (drawer_bank_drawer_count(b) > 0)
                for (i=[0:drawer_bank_drawer_count(b)-1]) {
                row_y = drawer_layout_row_y(b,i);

                for (n=[0:drawer_face_registration_hole_count-1])
                    round_hole_2d(
                        drawer_face_reg_face_local_x(n,b),
                        row_y + drawer_face_reg_face_local_z(i,b),
                        drawer_face_registration_hole_diameter
                    );
            }
    }
}

// Full-depth printable drawer face. Through holes come from drawer_face_cut();
// half-depth registration pockets are subtracted from one face here.
module drawer_face_print_part(i=0,b=0) {
    difference() {
        linear_extrude(height=drawer_front_thickness)
            drawer_face_cut(i,b);

        if (active_drawer_face_registration
            && drawer_face_registration_face_hole == "half_depth") {

            bd = drawer_face_registration_blind_depth();

            for (n=[0:drawer_face_registration_hole_count-1])
                translate([
                    drawer_face_reg_face_local_x(n,b),
                    drawer_face_reg_face_local_z(i,b),
                    drawer_front_thickness-bd
                ])
                    cylinder(
                        h=bd+0.02,
                        d=drawer_face_registration_hole_diameter
                    );
        }
    }
}


module drawer_box(i=0,b=0,explode=0) {
    ow = drawer_outer_width(b);
    st = drawer_material_thickness;
    bh = drawer_box_height(i,b);
    d  = drawer_box_depth;
    iz = drawer_box_z(i,b);
    pi = drawer_part_index(b,i);

    x0 = drawer_box_x0(b);
    y0 = effective_drawer_front_setback;
    z0 = iz;

    if (show_drawer_box_sides) {
        paint("drawer_side_l",pi)
            drawer_side_panel_3d(
                x0-explode,y0,z0,d,bh,i,"left");

        paint("drawer_side_r",pi)
            drawer_side_panel_3d(
                x0+ow-st+explode,y0,z0,d,bh,i,"right");
    }

    if (show_drawer_box_front_back) {
        paint("drawer_box_front",pi)
            drawer_cross_panel_3d(
                x0,y0,z0,bh,true,b);

        paint("drawer_box_back",pi)
            drawer_cross_panel_3d(
                x0,y0+d-st,z0,bh,false,b);
    }

    if (show_drawer_bottoms)
        paint("drawer_bottom",pi)
            drawer_bottom_3d(x0,y0,z0,b);

    if (include_drawer_faces && show_drawer_faces)
        paint("drawer_face",pi)
            drawer_face_3d(i,b);
}

module all_drawers() {
    if (has_drawers) {
        for (b=[0:active_drawer_bank_count()-1])
            if (drawer_bank_drawer_count(b) > 0)
                for (i=[0:drawer_bank_drawer_count(b)-1]) {
                drawer_box(i,b);

                if (show_drawer_slide_parts)
                    drawer_mounted_wood_slides(i,b);
            }
    }
}


// ---------------------------
// DOORS + HINGE / HANDLE HARDWARE
// ---------------------------

module door_panel_3d(i=0) {
    dw = door_each_width(i);
    x0 = front_panel_x + door_local_x(i);
    z0 = door_face_bottom_z;

    difference() {
        sheet_box(
            [dw,door_thickness,door_face_height],
            [x0,decorative_front_y(door_thickness),z0]
        );

        if (effective_hinge_style != "none") {
            hx = x0 + hinge_local_x(dw,i);

            for (j=[0:hinge_count-1]) {
                hz = hinge_z(j);

                if (effective_hinge_style == "euro_35mm")
                    round_hole_y_3d(
                        hx,
                        decorative_front_blind_drill_start_y(
                            door_thickness),
                        hz,
                        min(effective_hinge_cup_depth,door_thickness-0.5),
                        effective_hinge_cup_diameter
                    );

                if (hinge_door_fixing_enabled)
                for (dz=[
                    -effective_hinge_door_fixing_hole_spacing/2,
                    effective_hinge_door_fixing_hole_spacing/2
                ])
                    round_hole_y_3d(
                        hx,
                        decorative_front_through_drill_start_y(
                            door_thickness),
                        hz+dz,
                        door_thickness+2,
                        effective_hinge_door_fixing_hole_diameter
                    );
            }
        }

        if (include_door_handle_holes) {
            hx = x0 + door_handle_local_x(dw,i);
            hz = z0 + door_handle_local_z();

            if (handle_hole_pattern == "single_hole") {
                round_hole_y_3d(
                    hx,
                    decorative_front_through_drill_start_y(
                        door_thickness),
                    hz,
                    door_thickness+2,
                    handle_hole_diameter
                );
            }
            else if (door_handle_orientation == "vertical") {
                for (dz=[-handle_hole_spacing/2,handle_hole_spacing/2])
                    round_hole_y_3d(
                        hx,
                        decorative_front_through_drill_start_y(
                            door_thickness),
                        hz+dz,
                        door_thickness+2,
                        handle_hole_diameter
                    );
            }
            else {
                for (dx=[-handle_hole_spacing/2,handle_hole_spacing/2])
                    round_hole_y_3d(
                        hx+dx,
                        decorative_front_through_drill_start_y(
                            door_thickness),
                        hz,
                        door_thickness+2,
                        handle_hole_diameter
                    );
            }
        }
    }
}

module door_panel_cut(i=0) {
    dw = door_each_width(i);

    difference() {
        cut_part(dw,door_face_height);

        if (effective_hinge_style != "none") {
            hx = hinge_local_x(dw,i);

            for (j=[0:hinge_count-1]) {
                hz = hinge_local_z(j);

                // 35 mm cup is blind, so only fixing holes go in cut_layout.
                if (hinge_door_fixing_enabled)
                for (dz=[
                    -effective_hinge_door_fixing_hole_spacing/2,
                    effective_hinge_door_fixing_hole_spacing/2
                ])
                    round_hole_2d(
                        hx,hz+dz,
                        effective_hinge_door_fixing_hole_diameter
                    );
            }
        }

        if (include_door_handle_holes) {
            hx = door_handle_local_x(dw,i);
            hz = door_handle_local_z();

            if (handle_hole_pattern == "single_hole") {
                round_hole_2d(hx,hz,handle_hole_diameter);
            }
            else if (door_handle_orientation == "vertical") {
                for (dz=[-handle_hole_spacing/2,handle_hole_spacing/2])
                    round_hole_2d(
                        hx,hz+dz,handle_hole_diameter
                    );
            }
            else {
                for (dx=[-handle_hole_spacing/2,handle_hole_spacing/2])
                    round_hole_2d(
                        hx+dx,hz,handle_hole_diameter
                    );
            }
        }
    }
}

module mixed_bay_door_panel_3d(b=0,leaf=0) {
    dw = mixed_bay_door_leaf_width(b);
    x0 = mixed_bay_door_leaf_x(b,leaf);
    z0 = door_face_bottom_z;

    difference() {
        sheet_box(
            [dw,door_thickness,door_face_height],
            [x0,decorative_front_y(door_thickness),z0]
        );

        if (effective_hinge_style != "none") {
            hx = x0 + mixed_bay_door_hinge_local_x(b,leaf);

            for (j=[0:hinge_count-1]) {
                hz = mixed_bay_hinge_z(j);

                if (effective_hinge_style == "euro_35mm")
                    round_hole_y_3d(
                        hx,
                        decorative_front_blind_drill_start_y(
                            door_thickness),
                        hz,
                        min(effective_hinge_cup_depth,door_thickness-0.5),
                        effective_hinge_cup_diameter
                    );

                if (hinge_door_fixing_enabled)
                for (dz=[
                    -effective_hinge_door_fixing_hole_spacing/2,
                    effective_hinge_door_fixing_hole_spacing/2
                ])
                    round_hole_y_3d(
                        hx,
                        decorative_front_through_drill_start_y(
                            door_thickness),
                        hz+dz,
                        door_thickness+2,
                        effective_hinge_door_fixing_hole_diameter
                    );
            }
        }

        if (include_door_handle_holes) {
            hx = x0 + mixed_bay_door_handle_local_x(b,leaf);
            hz = z0 + door_handle_local_z();

            if (handle_hole_pattern == "single_hole") {
                round_hole_y_3d(
                    hx,
                    decorative_front_through_drill_start_y(
                        door_thickness),
                    hz,
                    door_thickness+2,
                    handle_hole_diameter
                );
            }
            else if (door_handle_orientation == "vertical") {
                for (dz=[-handle_hole_spacing/2,handle_hole_spacing/2])
                    round_hole_y_3d(
                        hx,
                        decorative_front_through_drill_start_y(
                            door_thickness),
                        hz+dz,
                        door_thickness+2,
                        handle_hole_diameter
                    );
            }
            else {
                for (dx=[-handle_hole_spacing/2,handle_hole_spacing/2])
                    round_hole_y_3d(
                        hx+dx,
                        decorative_front_through_drill_start_y(
                            door_thickness),
                        hz,
                        door_thickness+2,
                        handle_hole_diameter
                    );
            }
        }
    }
}

module mixed_bay_door_panel_cut(b=0,leaf=0) {
    dw = mixed_bay_door_leaf_width(b);

    difference() {
        cut_part(dw,door_face_height);

        if (effective_hinge_style != "none") {
            hx = mixed_bay_door_hinge_local_x(b,leaf);

            for (j=[0:hinge_count-1]) {
                hz = mixed_bay_hinge_z(j)-door_face_bottom_z;

                if (hinge_door_fixing_enabled)
                for (dz=[
                    -effective_hinge_door_fixing_hole_spacing/2,
                    effective_hinge_door_fixing_hole_spacing/2
                ])
                    round_hole_2d(
                        hx,hz+dz,
                        effective_hinge_door_fixing_hole_diameter
                    );
            }
        }

        if (include_door_handle_holes) {
            hx = mixed_bay_door_handle_local_x(b,leaf);
            hz = door_handle_local_z();

            if (handle_hole_pattern == "single_hole")
                round_hole_2d(hx,hz,handle_hole_diameter);
            else if (door_handle_orientation == "vertical")
                for (dz=[-handle_hole_spacing/2,handle_hole_spacing/2])
                    round_hole_2d(hx,hz+dz,handle_hole_diameter);
            else
                for (dx=[-handle_hole_spacing/2,handle_hole_spacing/2])
                    round_hole_2d(hx+dx,hz,handle_hole_diameter);
        }
    }
}

module door_hinge_pocket_layout() {
    if (has_doors && effective_hinge_style == "euro_35mm") {
        if (mixed_bay_mode) {
            for (b=[0:active_mixed_bay_count-1])
                if (mixed_bay_is_type(b,"door"))
                    for (leaf=[0:mixed_bay_door_count(b)-1]) {
                        door_layout_x = mixed_bay_door_layout_x(b,leaf);
                        hx = door_layout_x
                             + mixed_bay_door_hinge_local_x(b,leaf);

                        for (j=[0:hinge_count-1])
                            round_hole_2d(
                                hx,
                                door_layout_y
                                    + mixed_bay_hinge_z(j)
                                    - door_face_bottom_z,
                                effective_hinge_cup_diameter
                            );
                    }
        }
        else {
            for (i=[0:door_count-1]) {
                dw = door_each_width(i);
                door_layout_x = door_layout_part_x(i);
                hx = door_layout_x + hinge_local_x(dw,i);

                for (j=[0:hinge_count-1])
                    round_hole_2d(
                        hx,
                        door_layout_y + hinge_local_z(j),
                        effective_hinge_cup_diameter
                    );
            }
        }
    }
}

module doors() {
    if (has_doors && show_doors && door_face_height > 20) {
        if (mixed_bay_mode) {
            for (b=[0:active_mixed_bay_count-1])
                if (mixed_bay_is_type(b,"door"))
                    for (leaf=[0:mixed_bay_door_count(b)-1])
                        paint("door",mixed_bay_door_part_index(b,leaf))
                            mixed_bay_door_panel_3d(b,leaf);
        }
        else {
            for (i=[0:door_count-1])
                paint("door",i)
                    door_panel_3d(i);
        }
    }
}


// ---------------------------
// ASSEMBLY
// ---------------------------

module cabinet_unit_assembly() {
    carcass();
    face_frame_assembly_3d();
    all_drawers();
    doors();
}


module stackable_assembly() {
    if (stack_base_active)
        stack_base_assembly_3d();

    for (m=[0:max(1,stack_preview_count)-1])
        translate([
            0,
            0,
            stack_first_module_z
            + m*(
                stack_module_pitch
                + stack_preview_explode_gap
              )
        ])
            cabinet_unit_assembly();
}


module assembly() {
    if (stackable_mode)
        stackable_assembly();
    else
        cabinet_unit_assembly();
}


