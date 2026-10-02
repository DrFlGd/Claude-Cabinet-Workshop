// Modular Organization Core — fork v4 / Configurator API V4.
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

section_layout_active = !is_undef(section_nodes) && active_cabinet_layout_mode == "sections";
// Section splits exclusively own interior divider/shelf geometry and machining.
combo_contents_active = !section_layout_active && cabinet_contents == "combo";

sizing_has_drawers = section_layout_active ? false :
    sizing_mixed_mode
        ? sizing_mixed_has_drawer()
        : cabinet_contents == "drawers"
          || combo_contents_active;

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

sized_wood_rail_depth =
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

sized_wood_drawer_runner_depth =
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

has_drawers = section_layout_active ? false :
    mixed_bay_mode
        ? mixed_bay_has_type("drawers")
        : cabinet_contents == "drawers" || combo_contents_active;

has_doors = section_layout_active ? false :
    mixed_bay_mode
        ? mixed_bay_has_type("door")
        : cabinet_contents == "doors" || combo_contents_active;

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

// Depth available to loose interior members (drawer boxes, shelves, dividers,
// drawer-bank partitions). Rear stretchers sit inside the carcass, so these
// members stop at the stretchers' front face. Full-depth door-hinge and
// mixed-bay partitions keep usable_depth because they are notched around the
// stretchers instead.
interior_usable_depth =
    !standalone_drawer_active && back_style == "stretchers"
        ? min(
            usable_depth,
            resolved_cabinet_depth-material_thickness-back_stretcher_inset
          )
        : usable_depth;

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
    && combo_contents_active
    && face_frame_mid_rail_mode_resolved == "combo_auto";

// A center stile divides a PAIR of doors. It is omitted where it would cross
// drawer fronts (drawer-only layouts, or a combo without a mid rail to end on)
// and where door-hinge partitions or independent bays already divide the front.
function face_frame_center_stile_wanted() =
    !section_layout_active && face_frame_active
    && !is_undef(include_face_frame_center_stile)
    && include_face_frame_center_stile
    && has_doors
    && !mixed_bay_mode
    && door_count == 2
    && (
        cabinet_contents == "doors"
        || (combo_contents_active && face_frame_mid_rail_mode_resolved != "none")
    );

face_frame_center_stile_enabled = face_frame_center_stile_wanted();

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
    !mixed_bay_mode && combo_contents_active
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

// combo_door_height (mm) sets the door region of a drawers-over-doors cabinet
// directly; 0 keeps the automatic three drawer-height units. It is limited so
// the drawer stack keeps at least 40 mm per drawer.
combo_requested_door_height =
    is_undef(combo_door_height) ? 0 : max(0,combo_door_height);

combo_reference_door_height =
    !mixed_bay_mode && combo_contents_active
        ? combo_requested_door_height > 0
            ? min(
                combo_requested_door_height,
                max(
                    0,
                    content_height
                    - drawer_gap*drawer_bank_drawer_count(0)
                    - 40*drawer_bank_drawer_count(0)
                )
              )
            : combo_door_height_units*combo_reference_drawer_unit
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
            : combo_contents_active
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
            : combo_contents_active
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

// combo_auto marks the drawer/door boundary, so it exists only for combo
// (drawer-over-door) contents; elsewhere it used to land on top of the doors.
face_frame_mid_rail_active = !section_layout_active &&
    face_frame_active
    && (
        (
            face_frame_mid_rail_mode_resolved == "combo_auto"
            && combo_contents_active
            && !mixed_bay_mode
        )
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
        : interior_usable_depth
          - effective_drawer_front_setback
          - drawer_back_clearance;

// Wood rails and runners never extend past the rear construction or the back of
// the drawer box. Front-end defaults are cabinet-relative and ignore the rail's
// own front setback, which let rails poke through the back of short cabinets.
resolved_wood_rail_depth =
    max(
        20,
        min(
            sized_wood_rail_depth,
            interior_usable_depth-effective_wood_rail_front_setback
        )
    );

resolved_wood_drawer_runner_depth =
    max(
        20,
        min(
            sized_wood_drawer_runner_depth,
            effective_drawer_front_setback
            + drawer_box_depth
            - effective_wood_drawer_runner_front_setback
        )
    );

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

// Without mixed-bay partitions an interior bay boundary has no panel, so drawer
// slides or runners, shelf ends and hinges on that boundary have nothing to
// mount to (and shelf joinery would reach into the neighbouring bay).
function mixed_bay_needs_boundary(b,side) =
    mixed_bay_is_type(b,"drawers")
    || (mixed_bay_is_shelfable(b) && mixed_bay_shelf_count(b) > 0)
    || (side == "left"
        ? mixed_bay_door_uses_left_boundary(b)
        : mixed_bay_door_uses_right_boundary(b));

// First interior boundary (between bay p and p+1) that needs a partition, or -1.
function mixed_bay_unsupported_boundary(p=0) =
    !mixed_bay_mode || include_mixed_bay_partitions
    || p >= active_mixed_bay_count-1
        ? -1
        : mixed_bay_needs_boundary(p,"right")
          || mixed_bay_needs_boundary(p+1,"left")
            ? p
            : mixed_bay_unsupported_boundary(p+1);

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
    carcass_joint_geometry == "dado"
        ? mixed_bay_opening_width(b)+2*mixed_bay_fixed_shelf_dado_depth()
        : carcass_joint_geometry == "tab_slot"
            ? mixed_bay_opening_width(b)+2*material_thickness
            : mixed_bay_opening_width(b);

function mixed_bay_fixed_shelf_cut_body_offset() =
    carcass_joint_geometry == "dado"
        ? mixed_bay_fixed_shelf_dado_depth()
        : carcass_joint_geometry == "tab_slot"
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

// Overlay doors cover a door-hinge partition, splitting at door_gap. Inset doors
// sit inside the cabinet front and cannot overlap a partition, so each partition
// becomes a visible mullion with the normal edge reveal on both sides of it.
function door_split_gap() =
    fronts_inset_flush
    && !mixed_bay_mode
    && has_doors
    && include_door_hinge_partitions
    && door_count > 2
        ? material_thickness + 2*front_edge_reveal
        : fronts_inset_flush && face_frame_center_stile_wanted()
            ? effective_face_frame_center_stile_width + 2*front_edge_reveal
            : door_gap;

door_available_front_width =
    max(
        1,
        front_panel_width
        - door_split_gap()*max(0,door_count-1)
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
    + i*door_split_gap();

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
    + door_split_gap()/2;

function door_hinge_partition_x(p) =
    min(
        resolved_cabinet_width-2*material_thickness,
        max(
            material_thickness,
            door_gap_center_x(p)-material_thickness/2
        )
    );

// Structural partitions run between the carcass bottom and top panels. (The
// front opening is narrower than the carcass when a face frame is fitted; using
// it left partitions short of the panels their joinery must enter.)
function carcass_interior_bottom_z() = bottom_above_toe + material_thickness;
function carcass_interior_top_z() = cabinet_height - material_thickness;

function door_hinge_partition_bottom_z() =
    carcass_interior_bottom_z();

function door_hinge_partition_top_z() =
    combo_contents_active
        ? combo_divider_bottom_z
        : carcass_interior_top_z();

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
    carcass_joint_geometry == "dado"
        ? door_hinge_partition_body_height()
          + 2*door_hinge_partition_dado_depth()
        : carcass_joint_geometry == "tab_slot"
            ? door_hinge_partition_body_height()+2*material_thickness
            : door_hinge_partition_body_height();

function door_hinge_partition_cut_body_offset() =
    carcass_joint_geometry == "dado"
        ? door_hinge_partition_dado_depth()
        : carcass_joint_geometry == "tab_slot"
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

// Combo top joint: the band of the divider (from shelf_front_y) that receives it.
function door_hinge_partition_combo_joint_y0() =
    door_hinge_depth_overlap_start(shelf_front_y);
function door_hinge_partition_combo_joint_span() =
    door_hinge_depth_overlap_length(shelf_front_y,shelf_depth);

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

function mixed_bay_partition_bottom_z() = carcass_interior_bottom_z();
function mixed_bay_partition_top_z() = carcass_interior_top_z();
function mixed_bay_partition_body_height() =
    max(1,mixed_bay_partition_top_z()-mixed_bay_partition_bottom_z());

mixed_bay_partition_depth = usable_depth;

function mixed_bay_partition_dado_depth() =
    min(effective_dado_depth(),material_thickness-0.2);

function mixed_bay_partition_cut_height() =
    carcass_joint_geometry == "dado"
        ? mixed_bay_partition_body_height()
          + 2*mixed_bay_partition_dado_depth()
        : carcass_joint_geometry == "tab_slot"
            ? mixed_bay_partition_body_height()+2*material_thickness
            : mixed_bay_partition_body_height();

function mixed_bay_partition_cut_body_offset() =
    carcass_joint_geometry == "dado"
        ? mixed_bay_partition_dado_depth()
        : carcass_joint_geometry == "tab_slot"
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

// Face-frame mid rail as a [bottom, top] Z band, or [] when there is none.
// The rail is face-frame stock that reaches behind the carcass front plane
// (back-dado construction) and always narrows the opening behind it, so a
// drawer box must pass between the rails rather than merely between the
// carcass members. Overlay fronts hide the rail but do not move it.
function face_frame_mid_rail_band() =
    face_frame_mid_rail_active
        ? [
            face_frame_mid_rail_center_z-effective_face_frame_mid_rail_width/2,
            face_frame_mid_rail_center_z+effective_face_frame_mid_rail_width/2
          ]
        : [];

function drawer_face_opening_bottom_z(i,b=0) =
    max(drawer_face_z(i,b), content_bottom_z);

function drawer_face_opening_top_z(i,b=0) =
    drawer_face_z(i,b)
    + drawer_face_nominal_height(i,b);

// True when the mid rail crosses this drawer's face span and the drawer lies
// mostly above (or below) the rail's center line.
function drawer_mid_rail_overlap(i,b=0) =
    let(
        band=face_frame_mid_rail_band(),
        z0=drawer_face_opening_bottom_z(i,b),
        z1=drawer_face_opening_top_z(i,b)
    )
    len(band) == 2 && band[1] > z0 && band[0] < z1;

function drawer_is_above_mid_rail(i,b=0) =
    let(band=face_frame_mid_rail_band())
    len(band) == 2
    && (drawer_face_opening_bottom_z(i,b)+drawer_face_opening_top_z(i,b))/2
       >= (band[0]+band[1])/2;

function drawer_box_opening_bottom_z(i,b=0) =
    standalone_drawer_active
        ? 0
        : drawer_mid_rail_overlap(i,b) && drawer_is_above_mid_rail(i,b)
            ? max(
                drawer_face_opening_bottom_z(i,b),
                face_frame_mid_rail_band()[1]
              )
            : drawer_face_opening_bottom_z(i,b);

function drawer_box_opening_top_z(i,b=0) =
    standalone_drawer_active
        ? standalone_enclosure_opening_height
        : drawer_mid_rail_overlap(i,b) && !drawer_is_above_mid_rail(i,b)
            ? min(
                drawer_face_opening_top_z(i,b),
                face_frame_mid_rail_band()[0]
              )
            : drawer_face_opening_top_z(i,b);

// Smallest box that still holds its bottom panel with a usable wall above it.
// (A fixed 40 mm floor used to apply here; in short openings it silently made
// neighbouring boxes overlap. Boxes that cannot fit are now reported by the
// DRAWER_BOX_FIT validation check instead.)
function minimum_drawer_box_height() =
    drawer_bottom_inset + drawer_bottom_thickness + 10;

function drawer_box_height(i=0,b=0) =
    standalone_drawer_active
        ? standalone_drawer_box_height
        : max(
            minimum_drawer_box_height(),
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
    drawer_joint_geometry == "dado"
        ? drawer_inner_width(b) + 2*effective_drawer_dado_depth()
        : drawer_joint_geometry == "tab_slot"
            ? drawer_outer_width(b)
            : drawer_inner_width(b);

// Location of the normal inner-width body inside a flat front/back profile.
function drawer_cross_panel_inner_x_offset() =
    drawer_joint_geometry == "dado"
        ? effective_drawer_dado_depth()
        : drawer_joint_geometry == "tab_slot"
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
// DRAWER DIVIDER GRID (MOI-DIVIDER-GRID-1)
// ---------------------------
// Divider positions are always expressed in the FINISHED drawer interior:
// X from inside-left, Y from inside-front.  The machining geometry is then
// projected onto the drawer bottom and perimeter wall parts from that datum.

function drawer_divider_thickness_resolved() =
    drawer_divider_stock == "1/8_nominal" ? 3.175 :
    drawer_divider_stock == "1/4_nominal" ? 6.35 :
    drawer_divider_stock == "3/8_nominal" ? 9.525 :
    drawer_divider_stock == "1/2_nominal" ? 12.7 :
    drawer_divider_stock == "5/8_nominal" ? 15.875 :
    drawer_divider_stock == "3/4_nominal" ? 19.05 :
    max(0.1,custom_drawer_divider_thickness);

function drawer_divider_active_for(b=0,i=0) =
    include_drawer_divider_grid
    && has_drawers
    && (
        drawer_divider_target_mode == "all"
        || (
            drawer_divider_target_mode == "drawer_index"
            && drawer_part_index(b,i)+1 == round(drawer_divider_target_index)
        )
    );

function drawer_divider_target_match_count() =
    len([
        for (b=[0:max(0,active_drawer_bank_count()-1)])
            if (active_drawer_bank_count()>0 && drawer_bank_drawer_count(b)>0)
                for (i=[0:drawer_bank_drawer_count(b)-1])
                    if (drawer_divider_active_for(b,i)) 1
    ]);

function drawer_divider_bottom_capture_active() =
    drawer_divider_mounting == "bottom_only"
    || drawer_divider_mounting == "bottom_and_perimeter";

function drawer_divider_perimeter_capture_active() =
    drawer_divider_mounting == "bottom_and_perimeter";

function effective_drawer_divider_bottom_groove_depth() =
    drawer_divider_bottom_capture_active()
        ? min(
            max(0.1,drawer_divider_bottom_groove_depth),
            max(0.1,drawer_bottom_thickness-0.5)
          )
        : 0;

function effective_drawer_divider_perimeter_groove_depth() =
    drawer_divider_perimeter_capture_active()
        ? min(
            max(0.1,drawer_divider_perimeter_groove_depth),
            max(0.1,drawer_material_thickness-0.5)
          )
        : 0;

function drawer_divider_bottom_extension() =
    drawer_divider_bottom_capture_active()
        ? effective_drawer_divider_bottom_groove_depth()
        : 0;

function drawer_divider_part_height() =
    max(1,drawer_divider_height)+drawer_divider_bottom_extension();

function drawer_divider_floor_z_local() =
    drawer_bottom_inset+drawer_bottom_thickness;

function drawer_divider_groove_width() =
    drawer_divider_thickness_resolved()+max(0,drawer_divider_groove_clearance);

function drawer_divider_interlock_width() =
    drawer_divider_thickness_resolved()+max(0,drawer_divider_interlock_clearance);

function drawer_divider_interlock_depth() =
    min(
        drawer_divider_part_height(),
        drawer_divider_part_height()/2 + max(0,drawer_divider_interlock_clearance)/2
    );

function drawer_divider_x_count() =
    drawer_divider_layout_mode == "custom_positions"
        ? len(drawer_divider_custom_x)
        : max(0,round(drawer_divider_columns)-1);

function drawer_divider_y_count() =
    drawer_divider_layout_mode == "custom_positions"
        ? len(drawer_divider_custom_y)
        : max(0,round(drawer_divider_rows)-1);

function drawer_divider_equal_clear(span,cells) =
    let(c=max(1,round(cells)),t=drawer_divider_thickness_resolved())
    (span-max(0,c-1)*t)/c;

function drawer_divider_equal_center(span,cells,n) =
    let(c=max(1,round(cells)),t=drawer_divider_thickness_resolved(),cl=drawer_divider_equal_clear(span,c))
    (n+1)*cl+n*t+t/2;

function drawer_divider_x_position(b,n) =
    drawer_divider_layout_mode == "custom_positions"
        ? drawer_divider_custom_x[n]
        : drawer_divider_equal_center(drawer_inner_width(b),drawer_divider_columns,n);

function drawer_divider_y_position(n) =
    drawer_divider_layout_mode == "custom_positions"
        ? drawer_divider_custom_y[n]
        : drawer_divider_equal_center(drawer_inner_depth(),drawer_divider_rows,n);

function drawer_divider_perimeter_extension() =
    drawer_divider_perimeter_capture_active()
        ? effective_drawer_divider_perimeter_groove_depth()
        : 0;

function drawer_divider_longitudinal_length() =
    drawer_inner_depth()+2*drawer_divider_perimeter_extension();

function drawer_divider_transverse_length(b=0) =
    drawer_inner_width(b)+2*drawer_divider_perimeter_extension();

function drawer_divider_bottom_inner_offset() =
    drawer_bottom_joinery == "dado"
        ? effective_drawer_bottom_dado_depth()
        : 0;

function drawer_divider_position_has_edge_clearance(pos,span) =
    pos-drawer_divider_thickness_resolved()/2 >= max(0,drawer_divider_edge_margin)
    && pos+drawer_divider_thickness_resolved()/2 <= span-max(0,drawer_divider_edge_margin);

function drawer_divider_positions_separated_x(b) =
    let(n=drawer_divider_x_count(),w=drawer_divider_thickness_resolved()+max(0,drawer_divider_interlock_clearance))
    len([
        for(a=[0:max(0,n-1)]) if(n>1)
            for(c=[0:max(0,n-1)]) if(c>a)
                if(abs(drawer_divider_x_position(b,a)-drawer_divider_x_position(b,c)) < w) 1
    ]) == 0;

function drawer_divider_positions_separated_y() =
    let(n=drawer_divider_y_count(),w=drawer_divider_thickness_resolved()+max(0,drawer_divider_interlock_clearance))
    len([
        for(a=[0:max(0,n-1)]) if(n>1)
            for(c=[0:max(0,n-1)]) if(c>a)
                if(abs(drawer_divider_y_position(a)-drawer_divider_y_position(c)) < w) 1
    ]) == 0;

function mo_drawer_organizer_compatibility_key(b=0,i=0) =
    str(
        "KSV=1",
        ";W=",drawer_inner_width(b),
        ";D=",drawer_inner_depth(),
        ";H=",drawer_inside_clear_height(i,b),
        ";WALL_T=",drawer_material_thickness,
        ";BOTTOM_T=",drawer_bottom_thickness,
        ";BOTTOM_INSET=",drawer_bottom_inset
    );


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
        interior_usable_depth
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
        ? carcass_joint_geometry
        : drawer_bank_partition_joinery;

function drawer_bank_partition_count() = mixed_bay_mode ? 0 : max(0,drawer_bank_count-1);

function drawer_bank_partition_x(p) =
    drawer_bank_opening_x(p)
    + drawer_bank_opening_width(p);

function drawer_bank_partition_bottom_z() =
    combo_contents_active
        ? combo_divider_top_z
        : carcass_interior_bottom_z();

function drawer_bank_partition_top_z() = carcass_interior_top_z();

function drawer_bank_partition_body_height() =
    max(1,drawer_bank_partition_top_z()-drawer_bank_partition_bottom_z());

drawer_bank_partition_depth =
    max(20,interior_usable_depth-drawer_bank_partition_rear_clearance);

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
    carcass_joint_geometry == "dado"
        ? material_thickness-effective_dado_depth()
        : carcass_joint_geometry == "tab_slot"
            ? 0
            : material_thickness;

function horizontal_panel_local_x(global_x) =
    global_x-horizontal_panel_global_x0();

function depth_overlap_start(panel_y0) = max(0,panel_y0);
function depth_overlap_end(panel_y0,panel_depth) =
    min(drawer_bank_partition_depth,panel_y0+panel_depth);
function depth_overlap_length(panel_y0,panel_depth) =
    max(0,depth_overlap_end(panel_y0,panel_depth)-depth_overlap_start(panel_y0));

// Joinery on a partition must occupy exactly the depth band its receiver cuts.
// In combo contents the receiver is the divider, which starts at shelf_front_y
// (behind inset fronts or a back-dadoed face frame), not at the carcass front.
function drawer_bank_partition_bottom_joint_y0() =
    combo_contents_active ? depth_overlap_start(shelf_front_y) : 0;
function drawer_bank_partition_bottom_joint_span() =
    combo_contents_active
        ? depth_overlap_length(shelf_front_y,shelf_depth)
        : min(drawer_bank_partition_depth,resolved_cabinet_depth);

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

// Maximum distance the relief extends OUTSIDE a nominal slot wall.
// Conventional diagonal dogbones only project r-r/sqrt(2) past each wall.
// A T-bone can project a full cutter radius past the relieved wall.
function drawer_tab_slot_relief_reach() =
    let($machining_material="drawer")
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
    drawer_joint_geometry == "tab_slot"
        ? max(
            wood_slide_reg_margin(resolved_wood_drawer_runner_depth),
            wood_drawer_runner_side_safe_min(d)
                - wood_drawer_runner_local_front()
          )
        : wood_slide_reg_margin(resolved_wood_drawer_runner_depth);

function wood_drawer_runner_reg_max(d) =
    drawer_joint_geometry == "tab_slot"
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
    carcass_joint_geometry == "dado"
        ? inner_width + 2*effective_dado_depth()
        : carcass_joint_geometry == "tab_slot"
            ? resolved_cabinet_width
            : inner_width;

// Local X offset of the inner-width body in a flat horizontal carcass part.
function horizontal_panel_inner_x_offset() =
    carcass_joint_geometry == "dado"
        ? effective_dado_depth()
        : carcass_joint_geometry == "tab_slot"
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

// Shelf pins versus hinge mounting plates.
//
// The front shelf-pin row and the hinge mounting plate share the usual 32 mm
// system setback, so on a door side some pin heights land on (or too close
// to) a plate screw hole. Those pin holes are omitted - the standard shop
// practice - instead of drilling two overlapping holes, which the machining
// ledger rejects. A web of shelf_pin_hinge_plate_web() mm is kept between any
// remaining pin hole and a plate hole. Every generator and the side-panel
// ledger use these predicates so geometry, layouts and validation agree.
function shelf_pin_hinge_plate_web() = 2;

function shelf_pin_hits_hinge_plate(y,z,hinge_zs) =
    hinge_plate_holes_enabled
    && effective_hinge_style != "none"
    && len([
        for (hz=hinge_zs)
            for (dz=[
                -effective_hinge_plate_hole_spacing/2,
                effective_hinge_plate_hole_spacing/2
            ])
                let(
                    dy=y-effective_hinge_plate_center_from_front,
                    dv=z-(hz+dz),
                    r=adjustable_shelf_hole_diameter/2
                      + effective_hinge_plate_hole_diameter/2
                      + shelf_pin_hinge_plate_web()
                )
                if (dy*dy+dv*dv < r*r) 1
    ]) > 0;

function legacy_hinge_plate_zs() =
    [for (j=[0:max(0,hinge_count-1)]) if (hinge_count > 0) hinge_z(j)];

function mixed_bay_hinge_plate_zs() =
    [for (j=[0:max(0,hinge_count-1)]) if (hinge_count > 0) mixed_bay_hinge_z(j)];

// Outer cabinet side, full-width (legacy) layouts. An unknown side is treated
// conservatively as a door side.
function shelf_pin_kept_on_side(side,row,i) =
    !(
        (is_undef(side)
            ? (!mixed_bay_mode && has_doors && effective_hinge_style != "none")
            : cabinet_side_has_door_hinges(side))
        && shelf_pin_hits_hinge_plate(
            shelf_pin_y(row),shelf_pin_z(i),legacy_hinge_plate_zs())
    );

// Door-hinge partitions are drilled for every hinge station.
function shelf_pin_kept_on_door_partition(row,i) =
    !(
        effective_hinge_style != "none"
        && shelf_pin_hits_hinge_plate(
            shelf_pin_y(row),shelf_pin_z(i),legacy_hinge_plate_zs())
    );

function mixed_shelf_pin_kept_on_side(side,row,i) =
    !(
        mixed_bay_side_has_hinge_plates(side)
        && shelf_pin_hits_hinge_plate(
            shelf_pin_y(row),mixed_bay_shelf_pin_z(i),mixed_bay_hinge_plate_zs())
    );

function mixed_shelf_pin_kept_on_partition(p,row,i) =
    !(
        mixed_bay_partition_has_hinge_plates(p)
        && shelf_pin_hits_hinge_plate(
            shelf_pin_y(row),mixed_bay_shelf_pin_z(i),mixed_bay_hinge_plate_zs())
    );


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
    carcass_joint_geometry == "dado"
        ? inner_width+2*structural_back_dado_depth
        : carcass_joint_geometry == "tab_slot"
            ? resolved_cabinet_width
            : inner_width;

function structural_back_cut_height() =
    carcass_joint_geometry == "dado"
        ? captured_back_height+2*structural_back_dado_depth
        : carcass_joint_geometry == "tab_slot"
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
// A back-dadoed face frame reaches effective_face_frame_back_dado_depth behind the
// carcass front plane. Only the sides, bottom and top are received by frame
// pockets, so every other interior member (shelves, combo divider, drawer
// separators) starts behind the frame's back face instead of colliding with it.
interior_panel_front_y =
    max(
        fronts_inset_flush ? inset_front_interior_depth : 0,
        face_frame_back_dado_active ? effective_face_frame_back_dado_depth : 0
    );

// The mid rail only needs a back pocket when a member's front edge reaches it.
// Horizontal pocket bands across each stile, in stile-local Z (from the frame
// bottom): the bottom panel and the top panel/front stretcher. They match the
// bands cut in the bottom and top rails.
function face_frame_stile_cross_pockets() =
    !face_frame_back_dado_active ? [] : [
        [0, min(effective_face_frame_bottom_rail_width,face_frame_back_dado_width)],
        [
            face_frame_height
            - min(effective_face_frame_top_rail_width,face_frame_back_dado_width),
            face_frame_height
        ]
    ];

face_frame_mid_rail_receives_divider =
    face_frame_back_dado_active
    && face_frame_mid_rail_active
    && interior_panel_front_y <= 0;

shelf_front_y = interior_panel_front_y;

shelf_depth =
    max(
        10,
        interior_usable_depth
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
        && combo_contents_active
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
// Modular Organization v4 is a fork of Modular Storage v35.  Geometry remains
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
organization_engine_version = 4;
organization_parent_engine = "modular_storage_v35";
organization_interface_contract = "MOI-4";

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
    carcass_joint_geometry == "tab_slot"
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
    : carcass_joint_geometry == "dado"
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
        ";STYLE=",drawer_joint_geometry,
        ";SIDE_T=",drawer_material_thickness,
        ";FB_T=",drawer_material_thickness,
        ";JOINT_FIT=",drawer_joint_fit_clearance,
        ";DADO_FIT=",drawer_dado_fit_clearance,
        ";DADO_DEPTH=",drawer_joint_geometry == "dado" ? effective_drawer_dado_depth() : 0,
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

function organization_drawer_organizer_interfaces() =
    !has_drawers ? [] : [
        for (b=[0:max(0,active_drawer_bank_count()-1)])
            if (active_drawer_bank_count()>0 && drawer_bank_drawer_count(b)>0)
                for (i=[0:drawer_bank_drawer_count(b)-1])
                    mo_interface(
                        str("drawer.",drawer_part_index(b,i)+1,".organizer"),
                        "MOI-DIVIDER-GRID-1","organizer_host","host",
                        id_drawer_bottom(b,i),"inside_volume","MOI-DIVIDER-GRID-1:insert",
                        "drawer-inside-left-front-floor",
                        mo_drawer_organizer_compatibility_key(b,i),
                        "internal;drawer;organizer"
                    )
    ];

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
        ] : [],
        organization_drawer_organizer_interfaces()
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
    carcass_joint_geometry == "dado"
        ? let(c=dado_fit_clearance,dd=effective_dado_depth()) [
            mo_side_rect_feature(
                str(prefix,".dado"),side,"dado_pocket",owner,
                y0-c/2,y0+panel_depth+c/2,
                z0-c/2,z0+material_thickness+c/2,
                "blind_inner",dd,"pocket_carcass_dados","side_horizontal_joint"
            )
          ]
    : carcass_joint_geometry == "tab_slot"
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
    : carcass_registration_enabled
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
    carcass_joint_geometry == "dado"
        ? let(c=dado_fit_clearance,dd=effective_dado_depth()) [
            mo_side_rect_feature(
                str("toe.",side,".dado"),side,"dado_pocket","carcass.toe",
                toe_kick_setback-c/2,toe_kick_setback+material_thickness+c/2,
                -c/2,toe_kick_height+c/2,
                "blind_inner",dd,"pocket_carcass_dados","side_toe_joint"
            )
          ]
    : carcass_joint_geometry == "tab_slot"
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
    : carcass_registration_enabled
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
                carcass_joint_geometry == "dado"
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
                : carcass_joint_geometry == "tab_slot"
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
                : carcass_registration_enabled
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
    carcass_joint_geometry == "dado"
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
    : carcass_joint_geometry == "tab_slot"
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
    : carcass_registration_enabled
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
        (!mixed_bay_mode && combo_contents_active && door_region_height > material_thickness)
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
                if(shelf_pin_count()>0 && shelf_pin_kept_on_side(side,row,i))
                mo_side_circle_feature(
                    str("shelf_pin.",side,".",row,".",i+1),side,
                    blind ? "blind_hole" : "through_hole","storage.shelf_grid",
                    shelf_pin_y(row),shelf_pin_z(i),adjustable_shelf_hole_diameter,
                    dm,dd,op,"adjustable_shelf_pin")]
            : [],
        (mixed_bay_mode && mixed_bay_side_has_shelf_pins(side))
            ? [for(row=[0:1]) for(i=[0:max(0,mixed_bay_shelf_pin_count()-1)])
                if(mixed_bay_shelf_pin_count()>0
                    && mixed_shelf_pin_kept_on_side(side,row,i))
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
    ["drawer.divider_grid.grooves","drawer.organizer"],
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
          + (combo_contents_active ? 1 : 0);

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

function drawer_layout_bottom_y(b,i) =
    drawer_layout_box_parts_y(b,i)
    + drawer_box_height(i,b)
    + 2*layout_gap;

function drawer_layout_divider_base_y(b,i) =
    drawer_layout_bottom_y(b,i)
    + drawer_bottom_depth()
    + layout_gap;

function drawer_layout_divider_piece_y(b,i,is_longitudinal,n) =
    drawer_layout_divider_base_y(b,i)
    + (
        is_longitudinal
            ? n
            : drawer_divider_x_count()+n
      )*(drawer_divider_part_height()+layout_gap);

function drawer_layout_divider_extra_height(b,i) =
    drawer_divider_active_for(b,i)
        ? (drawer_divider_x_count()+drawer_divider_y_count())
          *(drawer_divider_part_height()+layout_gap)
        : 0;

function drawer_layout_row_height_for(i,b=0) =
    drawer_layout_header_height(i,b)
    + max(
        2*drawer_box_height(i,b)+layout_gap,
        drawer_box_height(i,b)+2*layout_gap+drawer_box_depth
      )
    + 2*layout_gap
    + drawer_layout_divider_extra_height(b,i);

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
    carcass_joint_geometry == "dado"
        ? inner_width+2*effective_dado_depth()
        : carcass_joint_geometry == "tab_slot"
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
        (combo_contents_active && face_frame_mid_rail_active
            ? face_frame_mid_rail_center_z-effective_face_frame_mid_rail_width/2
            : face_frame_clear_top_z)
        - face_frame_clear_bottom_z
    );

// Face-frame rails reach effective_face_frame_back_dado_depth behind the carcass
// front plane. Full-height partitions are notched at the front edge wherever a
// rail crosses them. Bands are global [bottom, top] Z ranges.
function face_frame_rail_back_bands() =
    !face_frame_back_dado_active ? [] : concat(
        [
            [face_frame_bottom_z, face_frame_clear_bottom_z],
            [face_frame_clear_top_z, face_frame_top_z]
        ],
        len(face_frame_mid_rail_band()) == 2 ? [face_frame_mid_rail_band()] : []
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

