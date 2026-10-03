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
                                    d=effective_slot_tool_diameter()
                                );
    }
}

// Fixed horizontal panel used for bottoms, tops, stretchers, shelves,
// and the combo divider.
module joined_horizontal_panel_3d(y0,depth,z0,tab_location="default") {
    if (carcass_joint_geometry == "butt") {
        sheet_box([inner_width,depth,material_thickness],
                  [material_thickness,y0,z0]);
    }
    else if (carcass_joint_geometry == "dado") {
        dd = effective_dado_depth();
        sheet_box([inner_width+2*dd,depth,material_thickness],
                  [material_thickness-dd,y0,z0]);
    }
    else if (carcass_joint_geometry == "tab_slot") {
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
    if (carcass_joint_geometry == "butt") {
        cut_part(inner_width,depth);
    }
    else if (carcass_joint_geometry == "dado") {
        cut_part(inner_width+2*effective_dado_depth(),depth);
    }
    else if (carcass_joint_geometry == "tab_slot") {
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
                                d=effective_slot_tool_diameter()
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

                if (carcass_joint_geometry == "dado") {
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
                else if (carcass_joint_geometry == "tab_slot") {
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
        && carcass_joint_geometry == "tab_slot") {

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
        && carcass_joint_geometry == "dado") {

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
        if (carcass_joint_geometry == "dado") {
            dd = door_hinge_partition_dado_depth();
            zz = edge == "bottom" ? z0-dd : z0;

            sheet_box(
                [material_thickness,span,dd],
                [x0,y0,zz]
            );
        }
        else if (carcass_joint_geometry == "tab_slot") {
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
    if (combo_contents_active) {
        door_hinge_partition_joinery_segment_3d(
            x0,
            door_hinge_partition_combo_joint_y0(),
            door_hinge_partition_combo_joint_span(),
            z0,"top");
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

module face_frame_partition_notches_3d(x0) {
    for (b=face_frame_rail_back_bands())
        translate([x0-1,-0.01,b[0]-0.01])
            cube([
                material_thickness+2,
                effective_face_frame_back_dado_depth+0.01,
                b[1]-b[0]+0.02
            ]);
}

// Same notches in a partition's flat cut (X = depth from the front, Y = Z - cut_z0).
module face_frame_partition_notches_2d(cut_z0) {
    for (b=face_frame_rail_back_bands())
        translate([-0.01,b[0]-cut_z0-0.01])
            square([
                effective_face_frame_back_dado_depth+0.01,
                b[1]-b[0]+0.02
            ]);
}

// Internal adjustable-shelf support holes are made THROUGH the partition so
// one drilled row supports the bays on both sides. Cabinet outer-side holes
// still obey adjustable_shelf_hole_type (through/blind).
module door_hinge_partition_shelf_pin_holes_3d(x0) {
    if (shelf_style == "adjustable")
        for (row=[0:1])
            for (i=[0:shelf_pin_count()-1])
                if (shelf_pin_kept_on_door_partition(row,i))
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
        face_frame_partition_notches_3d(x0);
    }
}

module door_hinge_partition_joinery_segment_cut(
    x0,span,y0,edge_height
) {
    if (span > 0) {
        if (carcass_joint_geometry == "dado") {
            translate([x0,y0])
                cut_part(
                    span,
                    door_hinge_partition_dado_depth()
                );
        }
        else if (carcass_joint_geometry == "tab_slot") {
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

    if (carcass_joint_geometry == "dado")
        door_hinge_partition_joinery_segment_cut(
            0,
            door_hinge_partition_actual_depth,
            0,
            ext);
    else if (carcass_joint_geometry == "tab_slot")
        door_hinge_partition_joinery_segment_cut(
            0,
            door_hinge_partition_actual_depth,
            0,
            ext);
}

module door_hinge_partition_top_joinery_cut(body_top_y) {
    if (combo_contents_active) {
        door_hinge_partition_joinery_segment_cut(
            door_hinge_partition_combo_joint_y0(),
            door_hinge_partition_combo_joint_span(),
            body_top_y,0);
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

        face_frame_partition_notches_2d(cut_z0);

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
                    if (shelf_pin_kept_on_door_partition(row,i))
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
// MIXED-BAY AND SECTION PARTITIONS
// ---------------------------
//
// A partition (vertical member between bays) enters the member below it and
// the member above it: the carcass bottom/top for full-height mixed-bay
// partitions, or a section divider. Fixed shelves and section dividers enter
// its faces. Everything a bay mounts (slides, hinge plates, shelf pins) is
// drilled through it.

// Partitions whose bottom (member "bottom") or top (member "top") enters the
// carcass bottom panel or top panel/stretchers.
function mixed_bay_partitions_into(member="bottom") =
    [for (p=[0:max(0,mixed_bay_partition_count()-1)])
        if (mixed_bay_partition_count() > 0
            && (member == "bottom"
                ? mixed_bay_partition_bottom_end(p)
                : mixed_bay_partition_top_end(p)) == -1)
            p];

// Receiver cuts for a list of partitions entering a horizontal member that
// occupies [panel_y0, panel_y0+panel_depth] at height z0. receiver_face "top"
// means the partitions come from above.
module partition_receiver_cuts_3d(
    parts,panel_y0,panel_depth,z0,receiver_face="top"
) {
    ov = mixed_bay_depth_overlap_length(panel_y0,panel_depth);
    ov0 = mixed_bay_depth_overlap_start(panel_y0);
    end = receiver_face == "top" ? "bottom" : "top";

    if (ov > 0)
        for (p=parts) {
            px = mixed_bay_partition_x(p);

            if (carcass_joint_geometry == "dado") {
                c = dado_fit_clearance;
                dd = mixed_bay_partition_end_length(p,end);
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
            else if (carcass_joint_geometry == "tab_slot") {
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

// The same through slots in a flat horizontal part whose local X origin is
// at global X = origin_x.
module partition_receiver_through_2d(
    parts,panel_y0,panel_depth,origin_x
) {
    if (carcass_joint_geometry == "tab_slot") {
        c = joint_fit_clearance;
        ov = mixed_bay_depth_overlap_length(panel_y0,panel_depth);
        ov0 = mixed_bay_depth_overlap_start(panel_y0);

        if (ov > 0)
            for (p=parts) {
                lx = mixed_bay_partition_x(p)-origin_x-c/2;
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

module partition_receiver_dado_pockets_2d(
    parts,panel_y0,panel_depth,origin_x
) {
    if (carcass_joint_geometry == "dado") {
        c = dado_fit_clearance;
        ov = mixed_bay_depth_overlap_length(panel_y0,panel_depth);
        ov0 = mixed_bay_depth_overlap_start(panel_y0);

        if (ov > 0)
            for (p=parts) {
                lx = mixed_bay_partition_x(p)-origin_x-c/2;
                ly = ov0-panel_y0-c/2;

                translate([lx,ly])
                    square([material_thickness+c,ov+c]);
            }
    }
}

// Carcass bottom (receiver_face "top") and top (receiver_face "bottom").
module mixed_bay_partition_receiver_cuts_3d(
    panel_y0,panel_depth,z0,receiver_face="top"
) {
    if (mixed_bay_partition_count() > 0)
        partition_receiver_cuts_3d(
            mixed_bay_partitions_into(receiver_face == "top" ? "bottom" : "top"),
            panel_y0,panel_depth,z0,receiver_face);
}

module mixed_bay_partition_receiver_through_2d(
    panel_y0,panel_depth,member="bottom"
) {
    if (mixed_bay_partition_count() > 0)
        partition_receiver_through_2d(
            mixed_bay_partitions_into(member),
            panel_y0,panel_depth,horizontal_panel_global_x0());
}

module mixed_bay_partition_receiver_dado_pockets_2d(
    panel_y0,panel_depth,member="bottom"
) {
    if (mixed_bay_partition_count() > 0)
        partition_receiver_dado_pockets_2d(
            mixed_bay_partitions_into(member),
            panel_y0,panel_depth,horizontal_panel_global_x0());
}

// Depth bands [y0, span] in which a partition end is joined: the full depth of
// the carcass bottom, the top panel or both top stretchers, or the depth of the
// section divider it enters.
function mixed_bay_partition_end_segments(p,end="bottom") =
    let(e=end == "bottom" ? mixed_bay_partition_bottom_end(p) : mixed_bay_partition_top_end(p))
    e >= 0
        ? [[
            mixed_bay_depth_overlap_start(section_divider_y0(e)),
            mixed_bay_depth_overlap_length(section_divider_y0(e),section_divider_depth(e))
          ]]
    : end == "bottom" || top_style == "full"
        ? [[0,mixed_bay_partition_depth]]
        : let(
            front_span=min(mixed_bay_partition_depth,top_stretcher_depth),
            rear_start=max(0,resolved_cabinet_depth-top_stretcher_depth),
            rear_span=max(0,min(mixed_bay_partition_depth,resolved_cabinet_depth)-rear_start)
          )
          [
            if (front_span > 0) [0,front_span],
            if (rear_span > 0) [rear_start,rear_span]
          ];

// Tongue (dado) or tabs (tab-and-slot) of length len at one partition end.
module partition_joinery_segment_3d(x0,y0,span,z0,edge="bottom",len=0) {
    if (span > 0 && len > 0) {
        zz = edge == "bottom" ? z0-len : z0;

        if (carcass_joint_geometry == "dado")
            sheet_box([material_thickness,span,len],[x0,y0,zz]);
        else if (carcass_joint_geometry == "tab_slot")
            for (n=[0:effective_tab_count(span)-1])
                sheet_box(
                    [material_thickness,tab_width_for(span),len],
                    [x0,y0+tab_start(span,n),zz]
                );
    }
}

module partition_joinery_segment_cut(y0,span,ybase,len=0) {
    if (span > 0 && len > 0) {
        if (carcass_joint_geometry == "dado")
            translate([y0,ybase])
                cut_part(span,len);
        else if (carcass_joint_geometry == "tab_slot")
            for (n=[0:effective_tab_count(span)-1])
                translate([y0+tab_start(span,n),ybase])
                    cut_part(tab_width_for(span),len);
    }
}

module mixed_bay_partition_end_joinery_3d(p,end="bottom") {
    for (seg=mixed_bay_partition_end_segments(p,end))
        partition_joinery_segment_3d(
            mixed_bay_partition_x(p),seg[0],seg[1],
            end == "bottom" ? mixed_bay_partition_bottom_z(p) : mixed_bay_partition_top_z(p),
            end,
            mixed_bay_partition_end_length(p,end));
}

// Horizontal members entering partition p: [z, face, y0, depth, length].
// face "left" is entered from the bays to the partition's left.
function mixed_bay_partition_entries(p) =
    concat(
        [for (face=["left","right"])
            for (bb=face == "left"
                    ? mixed_bay_partition_left_bays(p)
                    : mixed_bay_partition_right_bays(p))
                if (mixed_bay_has_fixed_shelves(bb))
                    for (s=[1:mixed_bay_shelf_count(bb)])
                        [
                            mixed_bay_shelf_z(bb,s),face,
                            shelf_front_y,shelf_depth,
                            mixed_bay_fixed_shelf_end_length(
                                bb,s,face == "left" ? "right" : "left")
                        ]],
        [for (h=[0:max(0,section_divider_count()-1)])
            if (section_divider_count() > 0)
                for (face=["left","right"])
                    if ((face == "left"
                            ? section_divider_right_end(h)
                            : section_divider_left_end(h)) == p)
                        [
                            section_divider_z(h),face,
                            section_divider_y0(h),section_divider_depth(h),
                            section_divider_end_length(
                                h,face == "left" ? "right" : "left")
                        ]]
    );

module mixed_bay_partition_horizontal_receivers_3d(x0,p=0) {
    for (e=mixed_bay_partition_entries(p)) {
        zz = e[0];
        yy = e[2];
        dp = e[3];

        if (carcass_joint_geometry == "dado") {
            c = dado_fit_clearance;
            // Members on the left enter the partition's left face.
            xx = e[1] == "left"
                ? x0-0.01
                : x0+material_thickness-e[4]-0.01;

            translate([xx,yy-c/2,zz-c/2])
                cube([
                    e[4]+0.02,
                    dp+c,
                    material_thickness+c
                ]);
        }
        else if (carcass_joint_geometry == "tab_slot") {
            c = joint_fit_clearance;

            for (n=[0:tab_count_for_location(dp,"shelf")-1])
                slot_cut_x_3d(
                    x0-1,
                    material_thickness+2,
                    yy+tab_start_for_location(dp,n,"shelf")-c/2,
                    zz-c/2,
                    tab_width_for(dp)+c,
                    material_thickness+c
                );
        }
        else if (carcass_joint_geometry == "butt" && carcass_registration_enabled) {
            for (n=[0:butt_reg_count(dp)-1])
                round_hole_x_3d(
                    x0-1,
                    yy+butt_reg_pos(dp,n),
                    zz+material_thickness/2,
                    material_thickness+2,
                    butt_registration_hole_diameter
                );
        }
    }
}

// Flat-cut equivalents: X = depth from the front, Y = Z - cut_z0.
module mixed_bay_partition_horizontal_receivers_through_2d(p=0) {
    cut_z0 = mixed_bay_partition_cut_global_bottom_z(p);

    for (e=mixed_bay_partition_entries(p)) {
        zz = e[0];
        yy = e[2];
        dp = e[3];

        if (carcass_joint_geometry == "tab_slot") {
            c = joint_fit_clearance;

            for (n=[0:tab_count_for_location(dp,"shelf")-1])
                translate([
                    yy+tab_start_for_location(dp,n,"shelf")-c/2,
                    zz-cut_z0-c/2
                ])
                    slot_shape_2d(
                        tab_width_for(dp)+c,
                        material_thickness+c
                    );
        }
        else if (carcass_joint_geometry == "butt" && carcass_registration_enabled) {
            for (n=[0:butt_reg_count(dp)-1])
                round_hole_2d(
                    yy+butt_reg_pos(dp,n),
                    zz+material_thickness/2-cut_z0,
                    butt_registration_hole_diameter
                );
        }
    }
}

// face = "left" draws the pockets entered from the partition's left face,
// "right" those entered from its right face, "both" every pocket.
module mixed_bay_partition_fixed_shelf_dado_pockets_2d(
    p=0,face="both"
) {
    c = dado_fit_clearance;
    cut_z0 = mixed_bay_partition_cut_global_bottom_z(p);

    if (carcass_joint_geometry == "dado")
        for (e=mixed_bay_partition_entries(p))
            if (face == "both" || face == e[1])
                translate([
                    e[2]-c/2,
                    e[0]-cut_z0-c/2
                ])
                    square([
                        e[3]+c,
                        material_thickness+c
                    ]);
}

module mixed_bay_partition_hardware_holes_3d(x0,p=0) {
    if (mixed_bay_partition_has_hinge_plates(p))
        for (hz=mixed_bay_partition_hinge_zs(p))
            if (hinge_plate_holes_enabled)
            for (dz=[
                -effective_hinge_plate_hole_spacing/2,
                effective_hinge_plate_hole_spacing/2
            ])
                round_hole_x_3d(
                    x0-1,
                    effective_hinge_plate_center_from_front,
                    hz+dz,
                    material_thickness+2,
                    effective_hinge_plate_hole_diameter
                );

    if (mixed_bay_partition_has_shelf_pins(p))
        for (row=[0:1])
            for (zz=mixed_bay_partition_pin_zs(p))
                if (mixed_shelf_pin_kept_on_partition(p,row,zz))
                round_hole_x_3d(
                    x0-1,
                    shelf_pin_y(row),
                    zz,
                    material_thickness+2,
                    adjustable_shelf_hole_diameter
                );

    // Drawer slide patterns from the bays on both faces share this partition.
    for (bb=mixed_bay_partition_bays(p)) {
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
    z0 = mixed_bay_partition_bottom_z(p);
    bh = mixed_bay_partition_body_height(p);

    difference() {
        union() {
            sheet_box(
                [material_thickness,mixed_bay_partition_depth,bh],
                [x0,0,z0]
            );

            mixed_bay_partition_end_joinery_3d(p,"bottom");
            mixed_bay_partition_end_joinery_3d(p,"top");
        }

        mixed_bay_partition_hardware_holes_3d(x0,p);
        mixed_bay_partition_horizontal_receivers_3d(x0,p);
        door_hinge_partition_back_stretcher_notches_3d(x0);
        face_frame_partition_notches_3d(x0);
    }
}

module mixed_bay_partition_cut(p=0) {
    bh = mixed_bay_partition_body_height(p);
    body_offset = mixed_bay_partition_cut_body_offset(p);
    cut_z0 = mixed_bay_partition_cut_global_bottom_z(p);

    difference() {
        union() {
            translate([0,body_offset])
                cut_part(mixed_bay_partition_depth,bh);

            for (seg=mixed_bay_partition_end_segments(p,"bottom"))
                partition_joinery_segment_cut(
                    seg[0],seg[1],0,mixed_bay_partition_end_length(p,"bottom"));

            for (seg=mixed_bay_partition_end_segments(p,"top"))
                partition_joinery_segment_cut(
                    seg[0],seg[1],body_offset+bh,mixed_bay_partition_end_length(p,"top"));
        }

        face_frame_partition_notches_2d(cut_z0);

        if (mixed_bay_partition_has_hinge_plates(p))
            for (hz=mixed_bay_partition_hinge_zs(p))
                if (hinge_plate_holes_enabled)
                for (dz=[
                    -effective_hinge_plate_hole_spacing/2,
                    effective_hinge_plate_hole_spacing/2
                ])
                    round_hole_2d(
                        effective_hinge_plate_center_from_front,
                        hz+dz-cut_z0,
                        effective_hinge_plate_hole_diameter
                    );

        if (mixed_bay_partition_has_shelf_pins(p))
            for (row=[0:1])
                for (zz=mixed_bay_partition_pin_zs(p))
                    if (mixed_shelf_pin_kept_on_partition(p,row,zz))
                    round_hole_2d(
                        shelf_pin_y(row),
                        zz-cut_z0,
                        adjustable_shelf_hole_diameter
                    );

        mixed_bay_partition_horizontal_receivers_through_2d(p);

        for (bb=mixed_bay_partition_bays(p)) {
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

// Fixed bay shelves span the bay between its members and are joined into them
// (or into the carcass sides) with the carcass joinery.
module mixed_bay_fixed_shelf_3d(b=0,z0=0,s=1) {
    x0 = mixed_bay_shelf_x(b);
    ww = mixed_bay_shelf_span(b);
    ll = mixed_bay_fixed_shelf_end_length(b,s,"left");
    rl = mixed_bay_fixed_shelf_end_length(b,s,"right");

    if (carcass_joint_geometry == "dado") {
        sheet_box(
            [ww+ll+rl,shelf_depth,material_thickness],
            [x0-ll,shelf_front_y,z0]
        );
    }
    else if (carcass_joint_geometry == "tab_slot") {
        union() {
            sheet_box([ww,shelf_depth,material_thickness],[x0,shelf_front_y,z0]);

            for (n=[0:tab_count_for_location(shelf_depth,"shelf")-1]) {
                yy = tab_start_for_location(shelf_depth,n,"shelf");
                tw = tab_width_for(shelf_depth);

                sheet_box(
                    [ll,tw,material_thickness],
                    [x0-ll,shelf_front_y+yy,z0]
                );
                sheet_box(
                    [rl,tw,material_thickness],
                    [x0+ww,shelf_front_y+yy,z0]
                );
            }
        }
    }
    else {
        sheet_box([ww,shelf_depth,material_thickness],[x0,shelf_front_y,z0]);
    }
}

module mixed_bay_fixed_shelf_cut(b=0,s=1) {
    ww = mixed_bay_shelf_span(b);
    ll = mixed_bay_fixed_shelf_end_length(b,s,"left");
    rl = mixed_bay_fixed_shelf_end_length(b,s,"right");

    if (carcass_joint_geometry == "dado") {
        cut_part(ww+ll+rl,shelf_depth);
    }
    else if (carcass_joint_geometry == "tab_slot") {
        union() {
            translate([ll,0])
                cut_part(ww,shelf_depth);

            for (n=[0:tab_count_for_location(shelf_depth,"shelf")-1]) {
                yy = tab_start_for_location(shelf_depth,n,"shelf");
                tw = tab_width_for(shelf_depth);

                translate([0,yy])
                    cut_part(ll,tw);
                translate([ll+ww,yy])
                    cut_part(rl,tw);
            }
        }
    }
    else {
        cut_part(ww,shelf_depth);
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

// ---------------------------
// SECTION DIVIDERS
// ---------------------------

// Partitions entering a divider from above (receiver face "top") and below.
module section_divider_receivers_3d(h) {
    partition_receiver_cuts_3d(
        section_divider_partitions(h,"top"),
        section_divider_y0(h),section_divider_depth(h),
        section_divider_z(h),"top");
    partition_receiver_cuts_3d(
        section_divider_partitions(h,"bottom"),
        section_divider_y0(h),section_divider_depth(h),
        section_divider_z(h),"bottom");
}

module section_divider_3d(h) {
    x0 = section_divider_x0(h);
    ww = section_divider_width(h);
    y0 = section_divider_y0(h);
    dp = section_divider_depth(h);
    z0 = section_divider_z(h);
    ll = section_divider_end_length(h,"left");
    rl = section_divider_end_length(h,"right");

    difference() {
        if (carcass_joint_geometry == "dado") {
            sheet_box([ww+ll+rl,dp,material_thickness],[x0-ll,y0,z0]);
        }
        else if (carcass_joint_geometry == "tab_slot") {
            union() {
                sheet_box([ww,dp,material_thickness],[x0,y0,z0]);

                for (n=[0:tab_count_for_location(dp,"shelf")-1]) {
                    yy = y0+tab_start_for_location(dp,n,"shelf");
                    tw = tab_width_for(dp);

                    sheet_box([ll,tw,material_thickness],[x0-ll,yy,z0]);
                    sheet_box([rl,tw,material_thickness],[x0+ww,yy,z0]);
                }
            }
        }
        else {
            sheet_box([ww,dp,material_thickness],[x0,y0,z0]);
        }

        section_divider_receivers_3d(h);
    }
}

// Flat part: X along the divider from its left end, Y = depth from its front.
function section_divider_cut_origin_x(h) =
    section_divider_x0(h)-section_divider_end_length(h,"left");

module section_divider_cut(h) {
    ww = section_divider_width(h);
    dp = section_divider_depth(h);
    ll = section_divider_end_length(h,"left");
    rl = section_divider_end_length(h,"right");
    parts = concat(
        section_divider_partitions(h,"top"),
        section_divider_partitions(h,"bottom"));

    difference() {
        if (carcass_joint_geometry == "dado") {
            cut_part(ww+ll+rl,dp);
        }
        else if (carcass_joint_geometry == "tab_slot") {
            union() {
                translate([ll,0])
                    cut_part(ww,dp);

                for (n=[0:tab_count_for_location(dp,"shelf")-1]) {
                    yy = tab_start_for_location(dp,n,"shelf");
                    tw = tab_width_for(dp);

                    translate([0,yy])
                        cut_part(ll,tw);
                    translate([ll+ww,yy])
                        cut_part(rl,tw);
                }
            }
        }
        else {
            cut_part(ww,dp);
        }

        partition_receiver_through_2d(
            parts,section_divider_y0(h),dp,section_divider_cut_origin_x(h));
    }
}

// Dado pockets on both faces of a divider (plan view, overlapping).
module section_divider_dado_pockets_2d(h) {
    partition_receiver_dado_pockets_2d(
        concat(
            section_divider_partitions(h,"top"),
            section_divider_partitions(h,"bottom")),
        section_divider_y0(h),section_divider_depth(h),
        section_divider_cut_origin_x(h));
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
            panel_y0,depth,tab_location == "top" ? "top" : "bottom");
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
    y0 = drawer_bank_partition_bottom_joint_y0();
    span = drawer_bank_partition_bottom_joint_span();

    if (span > 0)
    for (n=[0:effective_tab_count(span)-1]) {
        yy = y0+tab_start(span,n);
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
                // Body plus top tongue, and a bottom tongue only where the
                // supporting panel's dado runs.
                sheet_box(
                    [material_thickness,drawer_bank_partition_depth,bh+dd],
                    [x0,0,z0]
                );

                if (drawer_bank_partition_bottom_joint_span() > 0)
                    sheet_box(
                        [
                            material_thickness,
                            drawer_bank_partition_bottom_joint_span(),
                            dd
                        ],
                        [x0,drawer_bank_partition_bottom_joint_y0(),z0-dd]
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
        face_frame_partition_notches_3d(x0);
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
                translate([0,dd])
                    cut_part(
                        drawer_bank_partition_depth,
                        bh+dd
                    );

                translate([drawer_bank_partition_bottom_joint_y0(),0])
                    cut_part(
                        drawer_bank_partition_bottom_joint_span(),
                        dd+0.01
                    );
            }
            else {
                translate([0,bottom_extra])
                    cut_part(drawer_bank_partition_depth,bh);

                if (mode == "tab_slot") {
                    bottom_y0 = drawer_bank_partition_bottom_joint_y0();
                    bottom_span = drawer_bank_partition_bottom_joint_span();

                    if (bottom_span > 0)
                    for (n=[0:effective_tab_count(bottom_span)-1])
                        translate([bottom_y0+tab_start(bottom_span,n),0])
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

        face_frame_partition_notches_2d(
            drawer_bank_partition_bottom_z()-z_local_base);

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
    if (has_toe_kick && carcass_joint_geometry == "butt") {
        sheet_box([inner_width,material_thickness,toe_kick_height],
                  [material_thickness,toe_kick_setback,0]);
    }
    else if (has_toe_kick && carcass_joint_geometry == "dado") {
        dd = effective_dado_depth();
        sheet_box([inner_width+2*dd,material_thickness,toe_kick_height],
                  [material_thickness-dd,toe_kick_setback,0]);
    }
    else if (has_toe_kick && carcass_joint_geometry == "tab_slot") {
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
    if (has_toe_kick && carcass_joint_geometry == "butt") {
        cut_part(inner_width,toe_kick_height);
    }
    else if (has_toe_kick && carcass_joint_geometry == "dado") {
        cut_part(inner_width+2*effective_dado_depth(),toe_kick_height);
    }
    else if (has_toe_kick && carcass_joint_geometry == "tab_slot") {
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
    if (carcass_joint_geometry == "butt") {
        sheet_box(
            [inner_width,material_thickness,back_stretcher_height],
            [material_thickness,back_stretcher_y,z0]
        );
    }
    else if (carcass_joint_geometry == "dado") {
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
    else if (carcass_joint_geometry == "tab_slot") {
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
    if (carcass_joint_geometry == "butt") {
        cut_part(inner_width,back_stretcher_height);
    }
    else if (carcass_joint_geometry == "dado") {
        cut_part(
            inner_width+2*effective_dado_depth(),
            back_stretcher_height
        );
    }
    else if (carcass_joint_geometry == "tab_slot") {
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
        carcass_joint_geometry == "dado"
            ? dado_fit_clearance
            : joint_fit_clearance;

    if (carcass_joint_geometry == "dado") {
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
    else if (carcass_joint_geometry == "tab_slot") {
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
        carcass_joint_geometry == "dado"
            ? dado_fit_clearance
            : joint_fit_clearance;

    if (carcass_joint_geometry == "dado") {
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
    else if (carcass_joint_geometry == "tab_slot") {
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
        carcass_joint_geometry == "dado"
            ? dado_fit_clearance
            : joint_fit_clearance;

    if (has_toe_kick && carcass_joint_geometry == "dado") {
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
    else if (has_toe_kick && carcass_joint_geometry == "tab_slot") {
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
    if (carcass_joint_geometry == "butt" && carcass_registration_enabled) {
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
    if (carcass_joint_geometry == "butt" && carcass_registration_enabled) {
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
    if (has_toe_kick && carcass_joint_geometry == "butt" && carcass_registration_enabled) {
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
    if (has_toe_kick && carcass_joint_geometry == "butt" && carcass_registration_enabled) {
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
    if (carcass_joint_geometry == "butt" && carcass_registration_enabled) {
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
    if (carcass_joint_geometry == "butt" && carcass_registration_enabled) {
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
    if (carcass_joint_geometry == "butt" && carcass_registration_enabled) {
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
            && combo_contents_active
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
    if (carcass_joint_geometry == "butt" && carcass_registration_enabled) {
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
            && combo_contents_active
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
    if (carcass_joint_geometry != "butt") {
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
        if (!mixed_bay_mode && combo_contents_active && door_region_height > material_thickness)
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

    if (carcass_joint_geometry == "tab_slot") {
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
        if (!mixed_bay_mode && combo_contents_active && door_region_height > material_thickness)
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

    if (carcass_joint_geometry == "dado") {
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
        if (!mixed_bay_mode && combo_contents_active && door_region_height > material_thickness)
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
        if (carcass_joint_geometry == "butt") {
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
        else if (carcass_joint_geometry == "dado") {
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
        else if (carcass_joint_geometry == "tab_slot") {
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
        if (carcass_joint_geometry == "butt") {
            cut_part(
                inner_width,
                captured_back_height
            );
        }
        else if (carcass_joint_geometry == "dado") {
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
        else if (carcass_joint_geometry == "tab_slot") {
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
            carcass_joint_geometry == "dado"
                ? dado_fit_clearance
                : joint_fit_clearance;

        if (carcass_joint_geometry == "dado") {
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
        else if (carcass_joint_geometry == "tab_slot") {
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
            carcass_joint_geometry == "butt"
            && carcass_registration_enabled
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
            carcass_joint_geometry == "dado"
                ? dado_fit_clearance
                : joint_fit_clearance;

        if (carcass_joint_geometry == "tab_slot") {
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
            carcass_joint_geometry == "butt"
            && carcass_registration_enabled
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
        && carcass_joint_geometry == "dado"
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
            carcass_joint_geometry == "dado"
                ? dado_fit_clearance
                : joint_fit_clearance;

        if (carcass_joint_geometry == "dado") {
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
        else if (carcass_joint_geometry == "tab_slot") {
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
        && carcass_joint_geometry == "tab_slot"
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
        && carcass_joint_geometry == "dado"
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
            for (i=[0:shelf_pin_count()-1]) if (shelf_pin_kept_on_side(side,row,i)) {
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
module adjustable_shelf_pin_holes_cut_2d(side=undef) {
    if (!mixed_bay_mode
        && has_doors
        && shelf_style == "adjustable"
        && adjustable_shelf_hole_type == "through") {

        for (row=[0:1])
            for (i=[0:shelf_pin_count()-1])
                if (shelf_pin_kept_on_side(side,row,i))
                round_hole_2d(
                    shelf_pin_y(row),
                    shelf_pin_z(i),
                    adjustable_shelf_hole_diameter
                );
    }
}

// Blind shelf-pin drilling belongs in pocket_layout.
module adjustable_shelf_pin_holes_pocket_2d(side=undef) {
    if (!mixed_bay_mode
        && has_doors
        && shelf_style == "adjustable"
        && adjustable_shelf_hole_type == "blind") {

        for (row=[0:1])
            for (i=[0:shelf_pin_count()-1])
                if (shelf_pin_kept_on_side(side,row,i))
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
            for (zz=mixed_bay_side_pin_zs(side))
            if (mixed_shelf_pin_kept_on_side(side,row,zz)) {
                yy = shelf_pin_y(row);

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
            for (zz=mixed_bay_side_pin_zs(side))
                if (mixed_shelf_pin_kept_on_side(side,row,zz))
                round_hole_2d(
                    shelf_pin_y(row),
                    zz,
                    adjustable_shelf_hole_diameter
                );
}

module mixed_bay_side_shelf_pin_holes_pocket_2d(side) {
    if (mixed_bay_mode
        && mixed_bay_side_has_shelf_pins(side)
        && adjustable_shelf_hole_type == "blind")
        for (row=[0:1])
            for (zz=mixed_bay_side_pin_zs(side))
                if (mixed_shelf_pin_kept_on_side(side,row,zz))
                round_hole_2d(
                    shelf_pin_y(row),
                    zz,
                    adjustable_shelf_hole_diameter
                );
}

module mixed_bay_side_hinge_plate_holes_3d(x0,side) {
    if (mixed_bay_mode && mixed_bay_side_has_hinge_plates(side))
        for (hz=mixed_bay_side_hinge_zs(side))
            if (hinge_plate_holes_enabled)
            for (dz=[
                -effective_hinge_plate_hole_spacing/2,
                effective_hinge_plate_hole_spacing/2
            ])
                round_hole_x_3d(
                    x0-1,
                    effective_hinge_plate_center_from_front,
                    hz+dz,
                    material_thickness+2,
                    effective_hinge_plate_hole_diameter
                );
}

module mixed_bay_side_hinge_plate_holes_cut_2d(side) {
    if (mixed_bay_mode && mixed_bay_side_has_hinge_plates(side))
        for (hz=mixed_bay_side_hinge_zs(side))
            if (hinge_plate_holes_enabled)
            for (dz=[
                -effective_hinge_plate_hole_spacing/2,
                effective_hinge_plate_hole_spacing/2
            ])
                round_hole_2d(
                    effective_hinge_plate_center_from_front,
                    hz+dz,
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
// MIXED-BAY FIXED SHELVES AND SECTION DIVIDERS IN OUTER CABINET SIDES
// ---------------------------

// Horizontal members entering an outer side: [z, y0, depth] of each fixed
// shelf of a bay against that side and each section divider ending there.
function side_horizontal_entries(side) =
    concat(
        [for (bb=mixed_bay_side_bays(side))
            if (mixed_bay_has_fixed_shelves(bb))
                for (s=[1:mixed_bay_shelf_count(bb)])
                    [mixed_bay_shelf_z(bb,s),shelf_front_y,shelf_depth]],
        [for (h=[0:max(0,section_divider_count()-1)])
            if (section_divider_count() > 0
                && (side == "left"
                    ? section_divider_left_end(h)
                    : section_divider_right_end(h)) == -1)
                [section_divider_z(h),section_divider_y0(h),section_divider_depth(h)]]
    );

module mixed_bay_side_fixed_shelf_joinery_3d(x0,side) {
    if (carcass_joint_geometry != "butt")
        for (e=side_horizontal_entries(side))
            side_horizontal_joint_cut_3d(side,e[1],e[2],e[0],"shelf");
}

module mixed_bay_side_fixed_shelf_through_2d(side) {
    c = joint_fit_clearance;

    if (carcass_joint_geometry == "tab_slot")
        for (e=side_horizontal_entries(side))
            for (n=[0:tab_count_for_location(e[2],"shelf")-1]) {
                sy = e[1]+tab_start_for_location(e[2],n,"shelf")-c/2;
                sw = tab_width_for(e[2])+c;

                translate([sy,e[0]-c/2])
                    slot_shape_2d(
                        sw,
                        material_thickness+c
                    );
            }
}

module mixed_bay_side_fixed_shelf_dado_pockets_2d(side) {
    c = dado_fit_clearance;

    if (carcass_joint_geometry == "dado")
        for (e=side_horizontal_entries(side))
            translate([e[1]-c/2,e[0]-c/2])
                square([
                    e[2]+c,
                    material_thickness+c
                ]);
}

module mixed_bay_side_fixed_shelf_butt_registration_3d(x0,side) {
    if (carcass_joint_geometry == "butt"
        && carcass_registration_enabled)
        for (e=side_horizontal_entries(side))
            side_horizontal_butt_registration_3d(x0,e[1],e[2],e[0]);
}

module mixed_bay_side_fixed_shelf_butt_registration_2d(side) {
    if (carcass_joint_geometry == "butt"
        && carcass_registration_enabled)
        for (e=side_horizontal_entries(side))
            side_horizontal_butt_registration_2d(e[1],e[2],e[0]);
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
        for (side_bank=side_drawer_banks(side))
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
        for (side_bank=side_drawer_banks(side))
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

    if (side_has_toe_cutout(side))
        translate([-0.01,-0.01])
            square([
                toe_kick_setback+0.02,
                toe_kick_height+0.02
            ]);

    all_side_through_joinery_2d();
    mixed_bay_side_fixed_shelf_through_2d(side);

    adjustable_shelf_pin_holes_cut_2d(side);
    mixed_bay_side_shelf_pin_holes_cut_2d(side);

    all_side_butt_registration_2d();
    mixed_bay_side_fixed_shelf_butt_registration_2d(side);

    for (side_bank=side_drawer_banks(side))
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

    for (side_bank=side_drawer_banks(side))
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
            carcass_joint_geometry == "dado"
                ? dado_fit_clearance
                : joint_fit_clearance;

        for (front=[true,false]) {
            y0 = stack_base_cross_y(front);

            if (carcass_joint_geometry == "dado") {
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
            else if (carcass_joint_geometry == "tab_slot") {
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
                carcass_joint_geometry == "butt"
                && carcass_registration_enabled
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

            if (carcass_joint_geometry == "tab_slot")
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
                carcass_joint_geometry == "butt"
                && carcass_registration_enabled
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
        && carcass_joint_geometry == "dado"
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

            if (carcass_joint_geometry == "dado")
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
        if (carcass_joint_geometry == "butt") {
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
        else if (carcass_joint_geometry == "dado") {
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
        else if (carcass_joint_geometry == "tab_slot") {
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
        if (carcass_joint_geometry == "butt") {
            cut_part(
                inner_width,
                stack_base_height
            );
        }
        else if (carcass_joint_geometry == "dado") {
            cut_part(
                inner_width+2*effective_dado_depth(),
                stack_base_height
            );
        }
        else if (carcass_joint_geometry == "tab_slot") {
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

        for (band=face_frame_stile_cross_pockets())
            translate([0,band[0]])
                square([
                    effective_face_frame_side_stile_width,
                    band[1]-band[0]
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
    if (face_frame_mid_rail_receives_divider) {
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

        // The bottom and top panels run under the part of each stile that
        // overhangs the opening, so the stile is pocketed across its full width
        // at those heights (the same bands the rails receive).
        for (band=face_frame_stile_cross_pockets())
            translate([
                x0-0.01,
                -0.01,
                face_frame_bottom_z+band[0]-0.01
            ])
                cube([
                    effective_face_frame_side_stile_width+0.02,
                    effective_face_frame_back_dado_depth+0.02,
                    band[1]-band[0]+0.02
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

            if (face_frame_mid_rail_receives_divider)
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
        && combo_contents_active
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
        for (b=[0:layout_bay_count-1])
            if (mixed_bay_is_shelfable(b) && mixed_bay_shelf_count(b) > 0)
                for (s=[1:mixed_bay_shelf_count(b)])
                    paint("shelf",mixed_bay_shelf_part_index(b,s))
                        if (mixed_bay_shelf_style(b) == "fixed")
                            mixed_bay_fixed_shelf_3d(
                                b,mixed_bay_shelf_z(b,s),s);
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

    // Section dividers are horizontal dividers (shown with the combo divider).
    if (show_combo_divider
        && section_divider_count() > 0) {
        for (h=[0:section_divider_count()-1])
            paint("section_divider",h)
                section_divider_3d(h);
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
