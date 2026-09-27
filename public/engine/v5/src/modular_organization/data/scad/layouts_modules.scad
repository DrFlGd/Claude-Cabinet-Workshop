function substr_category(s) = str(s[0],s[1],s[2],s[3],s[4],s[5]);
// Modular Organization Layouts — fork v4 / Configurator API V4.
// Included after cabinet_core.scad by each cabinet entry file.

// ---------------------------
// 2D CUT LAYOUT
// ---------------------------

// Dummy frame used only to force identical SVG cropping for CUT and POCKET.
// It is deliberately outside all real layout geometry.
module shared_export_bounding_box_2d() {
    if (include_shared_export_bounding_box) {
        m = max(0,export_bounding_box_margin);
        fw = max(0.01,export_bounding_box_frame_width);

        outer_w = export_layout_content_width + 2*m;
        outer_h = export_layout_content_height + 2*m;

        translate([-m,-m])
            difference() {
                square([outer_w,outer_h]);

                translate([fw,fw])
                    square([
                        max(0.01,outer_w-2*fw),
                        max(0.01,outer_h-2*fw)
                    ]);
            }
    }
}

module stock_outline() {
    if (layout_show_stock)
        %square([stock_width,stock_height]);
}


// ---------------------------
// PART IDS / ENGRAVING / BOM
// ---------------------------

// Compact IDs are intentionally stable across assembly, engraving, and BOM
// output. Indexes are 1-based for shop readability.
function id_side(side) = side == "left" ? "CS-L" : "CS-R";
function id_bottom() = "BOTTOM";
function id_top_full() = "TOP";
function id_top_front() = "TOP-F";
function id_top_rear() = "TOP-R";
function id_back() = "BACK";
function id_back_stretcher(i) = str("BACK-ST",i+1);
function id_toe_kick() = "TOE";
function id_base_mounting_plate() = "BASE-PLATE";
function id_worktop() = "WORKTOP";
function id_face_frame_stile(side) =
    side == "left" ? "FF-L" : "FF-R";
function id_face_frame_top_rail() = "FF-T";
function id_face_frame_bottom_rail() = "FF-B";
function id_face_frame_mid_rail() = "FF-MID";
function id_face_frame_center_stile() = "FF-CS";
function id_stack_base_side(side) =
    side == "left" ? "STACK-BASE-L" : "STACK-BASE-R";
function id_stack_base_cross(front=true) =
    front ? "STACK-BASE-F" : "STACK-BASE-B";
function id_combo_divider() = "DIV";

function id_legacy_shelf(s,p=0) =
    door_adjustable_shelf_piece_count() > 1
        ? str("SH",s+1,"-P",p+1)
        : str("SH",s+1);

function id_mixed_shelf(b,s) =
    str("B",b+1,"-SH",s);

function id_door_partition(p) =
    str("DOOR-P",p+1);

function id_mixed_partition(p) =
    str("BAY-P",p+1);

function id_drawer_bank_partition(p) =
    str("DB-P",p+1);

function id_drawer_separator(s,piece=0) =
    drawer_separator_style == "full"
        ? str("DSEP",s+1)
        : str("DSEP",s+1,piece == 0 ? "-F" : "-R");

function id_drawer_prefix(b,i) =
    standalone_drawer_active
        ? str("D",i+1)
        : str("B",b+1,"-D",i+1);

function id_drawer_face(b,i) =
    str(id_drawer_prefix(b,i),"-FACE");

function id_drawer_side(b,i,side) =
    str(id_drawer_prefix(b,i),side == "left" ? "-SL" : "-SR");

function id_drawer_cross(b,i,is_front) =
    str(id_drawer_prefix(b,i),is_front ? "-FR" : "-BK");

function id_drawer_bottom(b,i) =
    str(id_drawer_prefix(b,i),"-BOT");

function id_drawer_divider_longitudinal(b,i,n) =
    str(id_drawer_prefix(b,i),"-DIV-L",n+1);

function id_drawer_divider_transverse(b,i,n) =
    str(id_drawer_prefix(b,i),"-DIV-T",n+1);

function id_drawer_rail(b,i,n) =
    str(id_drawer_prefix(b,i),"-RAIL",n+1);

function id_drawer_runner(b,i,n) =
    str(id_drawer_prefix(b,i),"-RUN",n+1);

function id_legacy_door(i) =
    str("DOOR",i+1);

function id_mixed_door(b,leaf) =
    str("B",b+1,"-DOOR",leaf+1);


// Size label text to fit the nominal bounding rectangle. Compact IDs keep the
// result useful on narrow rails and small benchtop parts.
function engraving_text_size(id,w,h) =
    min(
        engrave_label_size,
        max(
            engrave_label_min_size,
            min(
                max(engrave_label_min_size,h*0.42),
                max(
                    engrave_label_min_size,
                    w/max(1,len(id)*0.62)
                )
            )
        )
    );

module engraving_label(id,w,h) {
    if (w > 0 && h > 0)
        translate([w/2,h/2])
            text(
                is_undef($section_id) ? id : str($section_id,"-",id),
                size=engraving_text_size(is_undef($section_id) ? id : str($section_id,"-",id),w,h),
                halign="center",
                valign="center"
            );
}

module engraving_label_at(x,y,id,w,h) {
    translate([x,y])
        engraving_label(id,w,h);
}


// ---------- Carcass / structure labels ----------

module carcass_engrave_labels() {
    g = layout_gap;

    engraving_label_at(
        0,0,id_side("left"),
        resolved_cabinet_depth,side_panel_cut_height
    );

    engraving_label_at(
        resolved_cabinet_depth+g,0,id_side("right"),
        resolved_cabinet_depth,side_panel_cut_height
    );

    engraving_label_at(
        0,layout_y2,id_bottom(),
        bottom_panel_width,resolved_cabinet_depth
    );

    if (top_style == "full") {
        engraving_label_at(
            top_layout_x,layout_y2,id_top_full(),
            joined_w,resolved_cabinet_depth
        );
    } else {
        engraving_label_at(
            top_layout_x,layout_y2,id_top_front(),
            joined_w,top_stretcher_depth
        );

        engraving_label_at(
            top_layout_x,
            layout_y2+top_stretcher_depth+g,
            id_top_rear(),
            joined_w,top_stretcher_depth
        );
    }

    if (back_style == "panel"
        || back_style == "structural_panel") {
        engraving_label_at(
            0,layout_y3,id_back(),
            back_cut_width,back_cut_height
        );
    }
    else if (back_style == "stretchers") {
        for (bb=[0:back_stretcher_count-1])
            engraving_label_at(
                0,
                layout_y3
                + bb*(back_stretcher_height+g),
                id_back_stretcher(bb),
                joined_w,back_stretcher_height
            );
    }

    if (has_toe_kick)
        engraving_label_at(
            back_cut_width+g,
            layout_y3,
            id_toe_kick(),
            joined_w,toe_kick_height
        );

    // Legacy door-compartment shelves.
    if (!mixed_bay_mode && has_doors && door_shelf_count > 0) {
        for (s=[0:door_shelf_count-1]) {
            shelf_y = layout_y4+s*(shelf_depth+g);

            if (shelf_style == "fixed") {
                engraving_label_at(
                    0,shelf_y,
                    id_legacy_shelf(s),
                    joined_w,shelf_depth
                );
            }
            else {
                for (bb=[0:door_adjustable_shelf_piece_count()-1])
                    engraving_label_at(
                        door_adjustable_shelf_layout_x(bb),
                        shelf_y,
                        id_legacy_shelf(s,bb),
                        door_adjustable_shelf_piece_width(bb),
                        shelf_depth
                    );
            }
        }
    }

    if (!mixed_bay_mode && cabinet_contents == "combo") {
        divider_y =
            layout_y4
            + (has_doors ? door_shelf_count : 0)
              *(shelf_depth+g);

        engraving_label_at(
            0,divider_y,id_combo_divider(),
            joined_w,shelf_depth
        );
    }

    // Mixed-bay shelves.
    if (mixed_bay_mode && mixed_bay_total_shelf_count() > 0)
        for (bb=[0:active_mixed_bay_count-1])
            if (mixed_bay_is_shelfable(bb)
                && mixed_bay_shelf_count(bb) > 0)
                for (s=[1:mixed_bay_shelf_count(bb)])
                    engraving_label_at(
                        0,
                        mixed_bay_shelf_layout_y(bb,s),
                        id_mixed_shelf(bb,s),
                        mixed_bay_shelf_style(bb) == "fixed"
                            ? mixed_bay_fixed_shelf_cut_width(bb)
                            : mixed_bay_adjustable_shelf_width(bb),
                        shelf_depth
                    );

    if (mixed_bay_partition_count() > 0)
        for (p=[0:mixed_bay_partition_count()-1])
            engraving_label_at(
                0,
                mixed_bay_partition_layout_base_y
                + p*mixed_bay_partition_layout_row_height,
                id_mixed_partition(p),
                mixed_bay_partition_depth,
                mixed_bay_partition_cut_height()
            );

    if (door_hinge_partition_count() > 0)
        for (p=[0:door_hinge_partition_count()-1])
            engraving_label_at(
                0,
                door_hinge_partition_layout_base_y
                + p*door_hinge_partition_layout_row_height,
                id_door_partition(p),
                door_hinge_partition_actual_depth,
                door_hinge_partition_cut_height()
            );

    if (has_drawers && drawer_bank_partition_count() > 0)
        for (p=[0:drawer_bank_partition_count()-1])
            engraving_label_at(
                0,
                drawer_bank_partition_layout_base_y
                + p*drawer_bank_partition_layout_row_height,
                id_drawer_bank_partition(p),
                drawer_bank_partition_depth,
                drawer_bank_partition_cut_height()
            );

    if (drawer_separator_count > 0)
        for (s=[0:drawer_separator_count-1]) {
            sy =
                drawer_separator_layout_base_y
                + s*drawer_separator_layout_row_height;

            if (drawer_separator_style == "full") {
                engraving_label_at(
                    0,sy,id_drawer_separator(s),
                    joined_w,drawer_separator_full_depth
                );
            } else {
                engraving_label_at(
                    0,sy,id_drawer_separator(s,0),
                    joined_w,drawer_separator_stretcher_actual_depth
                );

                engraving_label_at(
                    0,
                    sy+drawer_separator_stretcher_actual_depth+g,
                    id_drawer_separator(s,1),
                    joined_w,drawer_separator_stretcher_actual_depth
                );
            }
        }
}


// ---------- Base / worktop labels ----------

module accessory_engrave_labels() {
    if (base_mounting_plate_active)
        engraving_label_at(
            0,
            base_mounting_plate_layout_y,
            id_base_mounting_plate(),
            base_mounting_plate_width,
            base_mounting_plate_depth
        );

    if (worktop_active)
        engraving_label_at(
            0,
            worktop_layout_y,
            id_worktop(),
            worktop_width,
            worktop_depth
        );
}


// ---------- Drawer labels ----------

module drawer_engrave_labels() {
    if (has_drawers) {
        g = layout_gap;
        d = drawer_box_depth;

        for (bb=[0:active_drawer_bank_count()-1])
            if (drawer_bank_drawer_count(bb) > 0)
                for (i=[0:drawer_bank_drawer_count(bb)-1]) {
                    ow = drawer_outer_width(bb);
                    bh = drawer_box_height(i,bb);
                    row_y = drawer_layout_row_y(bb,i);

                    if (include_drawer_faces)
                        engraving_label_at(
                            0,row_y,
                            id_drawer_face(bb,i),
                            drawer_face_width(bb),
                            drawer_face_height_for(i,bb)
                        );

                    if (drawer_mount == "wood_rails") {
                        rail_x =
                            max(drawer_face_width(bb),ow)+g;
                        runner_x =
                            standalone_include_fixed_wood_rails_resolved
                                ? rail_x+resolved_wood_rail_depth+g
                                : rail_x;

                        if (standalone_include_fixed_wood_rails_resolved) {
                            engraving_label_at(
                                rail_x,row_y,
                                id_drawer_rail(bb,i,0),
                                resolved_wood_rail_depth,wood_rail_height
                            );

                            engraving_label_at(
                                rail_x,
                                row_y+wood_rail_height+g,
                                id_drawer_rail(bb,i,1),
                                resolved_wood_rail_depth,wood_rail_height
                            );
                        }

                        engraving_label_at(
                            runner_x,row_y,
                            id_drawer_runner(bb,i,0),
                            resolved_wood_drawer_runner_depth,
                            wood_drawer_runner_height
                        );

                        engraving_label_at(
                            runner_x,
                            row_y+wood_drawer_runner_height+g,
                            id_drawer_runner(bb,i,1),
                            resolved_wood_drawer_runner_depth,
                            wood_drawer_runner_height
                        );
                    }

                    side_y = drawer_layout_box_parts_y(bb,i);

                    engraving_label_at(
                        0,side_y,
                        id_drawer_side(bb,i,"left"),
                        d,bh
                    );

                    engraving_label_at(
                        d+g,side_y,
                        id_drawer_side(bb,i,"right"),
                        d,bh
                    );

                    engraving_label_at(
                        2*(d+g),side_y,
                        id_drawer_cross(bb,i,true),
                        drawer_cross_panel_width(bb),bh
                    );

                    engraving_label_at(
                        2*(d+g),
                        side_y+bh+g,
                        id_drawer_cross(bb,i,false),
                        drawer_cross_panel_width(bb),bh
                    );

                    bottom_y = side_y+bh+2*g;

                    engraving_label_at(
                        0,bottom_y,
                        id_drawer_bottom(bb,i),
                        drawer_bottom_width(bb),
                        drawer_bottom_depth()
                    );


                    if (drawer_divider_active_for(bb,i)
                        && engrave_drawer_divider_ids) {
                        for (n=[0:max(0,drawer_divider_x_count()-1)])
                            if (drawer_divider_x_count() > 0)
                                engraving_label_at(
                                    0,
                                    drawer_layout_divider_piece_y(bb,i,true,n),
                                    id_drawer_divider_longitudinal(bb,i,n),
                                    drawer_divider_longitudinal_length(),
                                    drawer_divider_part_height()
                                );
                        for (n=[0:max(0,drawer_divider_y_count()-1)])
                            if (drawer_divider_y_count() > 0)
                                engraving_label_at(
                                    0,
                                    drawer_layout_divider_piece_y(bb,i,false,n),
                                    id_drawer_divider_transverse(bb,i,n),
                                    drawer_divider_transverse_length(bb),
                                    drawer_divider_part_height()
                                );
                    }
                }
    }
}


// ---------- Door labels ----------

module door_engrave_labels() {
    if (has_doors && door_face_height > 20) {
        if (mixed_bay_mode) {
            for (bb=[0:active_mixed_bay_count-1])
                if (mixed_bay_is_type(bb,"door"))
                    for (leaf=[0:mixed_bay_door_count(bb)-1])
                        engraving_label_at(
                            mixed_bay_door_layout_x(bb,leaf),
                            door_layout_y,
                            id_mixed_door(bb,leaf),
                            mixed_bay_door_leaf_width(bb),
                            door_face_height
                        );
        }
        else {
            for (i=[0:door_count-1])
                engraving_label_at(
                    door_layout_part_x(i),
                    door_layout_y,
                    id_legacy_door(i),
                    door_each_width(i),
                    door_face_height
                );
        }
    }
}


module face_frame_engrave_labels() {
    if (face_frame_active) {
        g = layout_gap;
        sw = effective_face_frame_side_stile_width;
        rail_x =
            (
                face_frame_center_stile_enabled
                    ? 3
                    : 2
            )*(sw+g);

        engraving_label_at(
            0,
            face_frame_layout_y,
            id_face_frame_stile("left"),
            sw,
            face_frame_stile_cut_height
        );

        engraving_label_at(
            sw+g,
            face_frame_layout_y,
            id_face_frame_stile("right"),
            sw,
            face_frame_stile_cut_height
        );

        if (face_frame_center_stile_enabled)
            engraving_label_at(
                2*(sw+g),
                face_frame_layout_y,
                id_face_frame_center_stile(),
                effective_face_frame_center_stile_width,
                face_frame_center_stile_cut_height
            );

        engraving_label_at(
            rail_x,
            face_frame_layout_y,
            id_face_frame_top_rail(),
            face_frame_rail_cut_width,
            effective_face_frame_top_rail_width
        );

        engraving_label_at(
            rail_x,
            face_frame_layout_y
                + effective_face_frame_top_rail_width
                + g,
            id_face_frame_bottom_rail(),
            face_frame_rail_cut_width,
            effective_face_frame_bottom_rail_width
        );

        if (face_frame_mid_rail_active)
            engraving_label_at(
                rail_x,
                face_frame_layout_y
                    + effective_face_frame_top_rail_width
                    + effective_face_frame_bottom_rail_width
                    + 2*g,
                id_face_frame_mid_rail(),
                face_frame_mid_rail_cut_width,
                effective_face_frame_mid_rail_width
            );
    }
}


module stack_base_engrave_labels() {
    if (stack_base_active) {
        g = layout_gap;

        engraving_label_at(
            0,
            stack_base_side_layout_y,
            id_stack_base_side("left"),
            resolved_cabinet_depth,
            stack_base_height
        );

        engraving_label_at(
            resolved_cabinet_depth+g,
            stack_base_side_layout_y,
            id_stack_base_side("right"),
            resolved_cabinet_depth,
            stack_base_height
        );

        engraving_label_at(
            0,
            stack_base_cross_layout_y,
            id_stack_base_cross(true),
            stack_base_cross_rail_cut_width(),
            stack_base_height
        );

        engraving_label_at(
            stack_base_cross_rail_cut_width()+g,
            stack_base_cross_layout_y,
            id_stack_base_cross(false),
            stack_base_cross_rail_cut_width(),
            stack_base_height
        );
    }
}


module engrave_layout() {
    stock_outline();

    // Same real registration frame as CUT/POCKET outputs.
    shared_export_bounding_box_2d();

    // Helpful in the GUI but excluded from SVG/DXF exports.
    if (show_cut_outlines_in_engrave_preview)
        %cut_layout_parts_only();

    if (standalone_drawer_active)
        drawer_engrave_labels();
    else {
        carcass_engrave_labels();
        drawer_engrave_labels();
        door_engrave_labels();
        accessory_engrave_labels();
        stack_base_engrave_labels();
        face_frame_engrave_labels();
    }
}


// ---------------------------
// BOM / CUT LIST
// ---------------------------

module bom_row(
    id,
    category,
    material_role,
    thickness,
    cut_w,
    cut_h,
    notes=""
) {
    if (is_undef($section_id) || category=="door" || (len(category)>=6 && substr_category(category)=="drawer"))
    echo(
        str(
            "BOM|",
            is_undef($section_id) ? id : str($section_id,"-",id),"|1|",
            category,"|",
            material_role,"|",
            thickness,"|",
            cut_w,"|",
            cut_h,"|",
            notes
        )
    );
}

module bom_report() {
    echo("BOM_BEGIN");
    echo("BOM_HEADER|ID|QTY|CATEGORY|MATERIAL|THICKNESS_MM|CUT_W_MM|CUT_H_MM|NOTES");

    // Carcass.
    bom_row(id_side("left"),"carcass","CARCASS",
            material_thickness,resolved_cabinet_depth,side_panel_cut_height,
            stackable_mode
                ? "stackable_top_bottom_notches"
                : full_width_bottom_active
                    ? "sits_on_full_width_bottom"
                    : "side");
    bom_row(id_side("right"),"carcass","CARCASS",
            material_thickness,resolved_cabinet_depth,side_panel_cut_height,
            stackable_mode
                ? "stackable_top_bottom_notches"
                : full_width_bottom_active
                    ? "sits_on_full_width_bottom"
                    : "side");

    bom_row(id_bottom(),"carcass","CARCASS",
            material_thickness,bottom_panel_width,resolved_cabinet_depth,
            full_width_bottom_active ? "full_width" : carcass_joint_geometry);

    if (top_style == "full")
        bom_row(id_top_full(),"carcass","CARCASS",
                material_thickness,joined_w,resolved_cabinet_depth,carcass_joint_geometry);
    else {
        bom_row(id_top_front(),"carcass","CARCASS",
                material_thickness,joined_w,top_stretcher_depth,carcass_joint_geometry);
        bom_row(id_top_rear(),"carcass","CARCASS",
                material_thickness,joined_w,top_stretcher_depth,carcass_joint_geometry);
    }

    if (back_style == "panel")
        bom_row(id_back(),"back","BACK",
                back_thickness,back_cut_width,back_cut_height,"applied");
    else if (back_style == "structural_panel")
        bom_row(
            id_back(),
            "back_structural",
            "CARCASS",
            material_thickness,
            back_cut_width,
            back_cut_height,
            str("captured_",carcass_joint_geometry)
        );
    else if (back_style == "stretchers")
        for (bb=[0:back_stretcher_count-1])
            bom_row(id_back_stretcher(bb),"back_stretcher","CARCASS",
                    material_thickness,joined_w,back_stretcher_height,carcass_joint_geometry);

    if (has_toe_kick)
        bom_row(id_toe_kick(),"toe_kick","CARCASS",
                material_thickness,joined_w,toe_kick_height,carcass_joint_geometry);

    if (base_mounting_plate_active)
        bom_row(
            id_base_mounting_plate(),
            "base_mounting_plate","CARCASS",
            material_thickness,
            base_mounting_plate_width,
            base_mounting_plate_depth,
            active_base_style
        );

    if (worktop_active)
        bom_row(
            id_worktop(),
            "worktop","WORKTOP",
            worktop_thickness,
            worktop_width,
            worktop_depth,
            str(
                "overhang side/front/back=",
                worktop_side_overhang,"/",
                worktop_front_overhang,"/",
                worktop_back_overhang,
                active_worktop_registration
                    ? str(
                        "; underside blind registration ",
                        worktop_registration_hole_diameter,
                        "mm x ",
                        effective_worktop_registration_blind_depth,
                        "mm"
                      )
                    : ""
            )
        );

    if (face_frame_active) {
        bom_row(
            id_face_frame_stile("left"),
            "face_frame_stile","FACE_FRAME",
            effective_face_frame_thickness,
            effective_face_frame_side_stile_width,
            face_frame_stile_cut_height,
            face_frame_back_dado_active
                ? str(
                    "segmented_back_dado;depth=",
                    effective_face_frame_back_dado_depth
                  )
                : "segmented_surface"
        );

        bom_row(
            id_face_frame_stile("right"),
            "face_frame_stile","FACE_FRAME",
            effective_face_frame_thickness,
            effective_face_frame_side_stile_width,
            face_frame_stile_cut_height,
            face_frame_back_dado_active
                ? str(
                    "segmented_back_dado;depth=",
                    effective_face_frame_back_dado_depth
                  )
                : "segmented_surface"
        );

        bom_row(
            id_face_frame_top_rail(),
            "face_frame_rail","FACE_FRAME",
            effective_face_frame_thickness,
            face_frame_rail_cut_width,
            effective_face_frame_top_rail_width,
            face_frame_back_dado_active
                ? str(
                    "top_rail;back_dado_depth=",
                    effective_face_frame_back_dado_depth
                  )
                : "top rail"
        );

        bom_row(
            id_face_frame_bottom_rail(),
            "face_frame_rail","FACE_FRAME",
            effective_face_frame_thickness,
            face_frame_rail_cut_width,
            effective_face_frame_bottom_rail_width,
            face_frame_back_dado_active
                ? str(
                    "bottom_rail;back_dado_depth=",
                    effective_face_frame_back_dado_depth
                  )
                : "bottom rail"
        );

        if (face_frame_mid_rail_active)
            bom_row(
                id_face_frame_mid_rail(),
                "face_frame_rail","FACE_FRAME",
                effective_face_frame_thickness,
                face_frame_mid_rail_cut_width,
                effective_face_frame_mid_rail_width,
                str(
                    "center_z=",face_frame_mid_rail_center_z,
                    face_frame_back_dado_active
                        ? str(
                            ";back_dado_depth=",
                            effective_face_frame_back_dado_depth
                          )
                        : ""
                )
            );

        if (face_frame_center_stile_enabled)
            bom_row(
                id_face_frame_center_stile(),
                "face_frame_stile","FACE_FRAME",
                effective_face_frame_thickness,
                effective_face_frame_center_stile_width,
                face_frame_center_stile_cut_height,
                "center stile"
            );
    }

    if (stack_base_active) {
        bom_row(
            id_stack_base_side("left"),
            "stack_base_side","CARCASS",
            material_thickness,
            resolved_cabinet_depth,
            stack_base_height,
            str("top_stack_notch;",carcass_joint_geometry)
        );

        bom_row(
            id_stack_base_side("right"),
            "stack_base_side","CARCASS",
            material_thickness,
            resolved_cabinet_depth,
            stack_base_height,
            str("top_stack_notch;",carcass_joint_geometry)
        );

        bom_row(
            id_stack_base_cross(true),
            "stack_base_cross","CARCASS",
            material_thickness,
            stack_base_cross_rail_cut_width(),
            stack_base_height,
            carcass_joint_geometry
        );

        bom_row(
            id_stack_base_cross(false),
            "stack_base_cross","CARCASS",
            material_thickness,
            stack_base_cross_rail_cut_width(),
            stack_base_height,
            carcass_joint_geometry
        );
    }

    // Legacy shelves.
    if (!mixed_bay_mode && has_doors && door_shelf_count > 0)
        for (s=[0:door_shelf_count-1])
            if (shelf_style == "fixed")
                bom_row(id_legacy_shelf(s),"shelf_fixed","CARCASS",
                        material_thickness,joined_w,shelf_depth,carcass_joint_geometry);
            else
                for (bb=[0:door_adjustable_shelf_piece_count()-1])
                    bom_row(id_legacy_shelf(s,bb),"shelf_adjustable","CARCASS",
                            material_thickness,
                            door_adjustable_shelf_piece_width(bb),
                            shelf_depth,"loose");

    if (!mixed_bay_mode && cabinet_contents == "combo")
        bom_row(id_combo_divider(),"divider","CARCASS",
                material_thickness,joined_w,shelf_depth,carcass_joint_geometry);

    // Mixed shelves.
    if (mixed_bay_mode && mixed_bay_total_shelf_count() > 0)
        for (bb=[0:active_mixed_bay_count-1])
            if (mixed_bay_is_shelfable(bb)
                && mixed_bay_shelf_count(bb) > 0)
                for (s=[1:mixed_bay_shelf_count(bb)])
                    bom_row(
                        id_mixed_shelf(bb,s),
                        mixed_bay_shelf_style(bb) == "fixed"
                            ? "shelf_fixed"
                            : "shelf_adjustable",
                        "CARCASS",
                        material_thickness,
                        mixed_bay_shelf_style(bb) == "fixed"
                            ? mixed_bay_fixed_shelf_cut_width(bb)
                            : mixed_bay_adjustable_shelf_width(bb),
                        shelf_depth,
                        mixed_bay_shelf_style(bb) == "fixed"
                            ? carcass_joint_geometry
                            : "loose"
                    );

    // Structural partitions.
    if (mixed_bay_partition_count() > 0)
        for (p=[0:mixed_bay_partition_count()-1])
            bom_row(
                id_mixed_partition(p),
                "mixed_bay_partition","CARCASS",
                material_thickness,
                mixed_bay_partition_depth,
                mixed_bay_partition_cut_height(),
                carcass_joint_geometry
            );

    if (door_hinge_partition_count() > 0)
        for (p=[0:door_hinge_partition_count()-1])
            bom_row(
                id_door_partition(p),
                "door_partition","CARCASS",
                material_thickness,
                door_hinge_partition_actual_depth,
                door_hinge_partition_cut_height(),
                carcass_joint_geometry
            );

    if (has_drawers && drawer_bank_partition_count() > 0)
        for (p=[0:drawer_bank_partition_count()-1])
            bom_row(
                id_drawer_bank_partition(p),
                "drawer_bank_partition","CARCASS",
                material_thickness,
                drawer_bank_partition_depth,
                drawer_bank_partition_cut_height(),
                drawer_bank_partition_joinery_mode()
            );

    if (drawer_separator_count > 0)
        for (s=[0:drawer_separator_count-1])
            if (drawer_separator_style == "full")
                bom_row(
                    id_drawer_separator(s),
                    "drawer_separator","CARCASS",
                    material_thickness,
                    joined_w,drawer_separator_full_depth,
                    carcass_joint_geometry
                );
            else {
                bom_row(
                    id_drawer_separator(s,0),
                    "drawer_separator","CARCASS",
                    material_thickness,
                    joined_w,drawer_separator_stretcher_actual_depth,
                    carcass_joint_geometry
                );
                bom_row(
                    id_drawer_separator(s,1),
                    "drawer_separator","CARCASS",
                    material_thickness,
                    joined_w,drawer_separator_stretcher_actual_depth,
                    carcass_joint_geometry
                );
            }

    // Drawers.
    if (has_drawers)
        for (bb=[0:active_drawer_bank_count()-1])
            if (drawer_bank_drawer_count(bb) > 0)
                for (i=[0:drawer_bank_drawer_count(bb)-1]) {
                    bh = drawer_box_height(i,bb);

                    if (include_drawer_faces)
                        bom_row(
                            id_drawer_face(bb,i),
                            "drawer_face","DRAWER_FRONT",
                            drawer_front_thickness,
                            drawer_face_width(bb),
                            drawer_face_height_for(i,bb),
                            fronts_inset_flush
                                ? "inset_flush"
                                : "overlay"
                        );

                    if (drawer_mount == "wood_rails") {
                        bom_row(
                            id_drawer_rail(bb,i,0),
                            "drawer_rail","WOOD_RAIL",
                            wood_rail_thickness,
                            resolved_wood_rail_depth,wood_rail_height,
                            "fixed"
                        );
                        bom_row(
                            id_drawer_rail(bb,i,1),
                            "drawer_rail","WOOD_RAIL",
                            wood_rail_thickness,
                            resolved_wood_rail_depth,wood_rail_height,
                            "fixed"
                        );
                        bom_row(
                            id_drawer_runner(bb,i,0),
                            "drawer_runner","WOOD_RUNNER",
                            wood_drawer_runner_thickness,
                            resolved_wood_drawer_runner_depth,
                            wood_drawer_runner_height,
                            "drawer"
                        );
                        bom_row(
                            id_drawer_runner(bb,i,1),
                            "drawer_runner","WOOD_RUNNER",
                            wood_drawer_runner_thickness,
                            resolved_wood_drawer_runner_depth,
                            wood_drawer_runner_height,
                            "drawer"
                        );
                    }

                    bom_row(
                        id_drawer_side(bb,i,"left"),
                        "drawer_side","DRAWER_WALL",
                        drawer_material_thickness,
                        drawer_box_depth,bh,
                        drawer_joint_geometry
                    );
                    bom_row(
                        id_drawer_side(bb,i,"right"),
                        "drawer_side","DRAWER_WALL",
                        drawer_material_thickness,
                        drawer_box_depth,bh,
                        drawer_joint_geometry
                    );
                    bom_row(
                        id_drawer_cross(bb,i,true),
                        "drawer_front_box","DRAWER_WALL",
                        drawer_material_thickness,
                        drawer_cross_panel_width(bb),bh,
                        drawer_joint_geometry
                    );
                    bom_row(
                        id_drawer_cross(bb,i,false),
                        "drawer_back_box","DRAWER_WALL",
                        drawer_material_thickness,
                        drawer_cross_panel_width(bb),bh,
                        drawer_joint_geometry
                    );
                    bom_row(
                        id_drawer_bottom(bb,i),
                        "drawer_bottom","DRAWER_BOTTOM",
                        drawer_bottom_thickness,
                        drawer_bottom_width(bb),
                        drawer_bottom_depth(),
                        drawer_bottom_joinery
                    );


                    if (drawer_divider_active_for(bb,i)) {
                        for (n=[0:max(0,drawer_divider_x_count()-1)])
                            if (drawer_divider_x_count() > 0)
                                bom_row(
                                    id_drawer_divider_longitudinal(bb,i,n),
                                    "drawer_divider_longitudinal","DRAWER_DIVIDER",
                                    drawer_divider_thickness_resolved(),
                                    drawer_divider_longitudinal_length(),
                                    drawer_divider_part_height(),
                                    str("MOI-DIVIDER-GRID-1;",drawer_divider_mounting)
                                );
                        for (n=[0:max(0,drawer_divider_y_count()-1)])
                            if (drawer_divider_y_count() > 0)
                                bom_row(
                                    id_drawer_divider_transverse(bb,i,n),
                                    "drawer_divider_transverse","DRAWER_DIVIDER",
                                    drawer_divider_thickness_resolved(),
                                    drawer_divider_transverse_length(bb),
                                    drawer_divider_part_height(),
                                    str("MOI-DIVIDER-GRID-1;",drawer_divider_mounting)
                                );
                    }
                }

    // Doors.
    if (has_doors && door_face_height > 20) {
        if (mixed_bay_mode) {
            for (bb=[0:active_mixed_bay_count-1])
                if (mixed_bay_is_type(bb,"door"))
                    for (leaf=[0:mixed_bay_door_count(bb)-1])
                        bom_row(
                            id_mixed_door(bb,leaf),
                            "door","DOOR",
                            door_thickness,
                            mixed_bay_door_leaf_width(bb),
                            door_face_height,
                            str(
                                mixed_bay_door_leaf_hinge_side(bb,leaf),
                                ";",
                                fronts_inset_flush
                                    ? "inset_flush"
                                    : "overlay"
                            )
                        );
        }
        else {
            for (i=[0:door_count-1])
                bom_row(
                    id_legacy_door(i),
                    "door","DOOR",
                    door_thickness,
                    door_each_width(i),
                    door_face_height,
                    str(
                        door_hinge_side(i),
                        ";",
                        fronts_inset_flush
                            ? "inset_flush"
                            : "overlay"
                    )
                );
        }
    }

    echo("BOM_END");

    // Tiny valid object keeps command-line export workflows happy.
    square([0.01,0.01]);
}



// ---------------------------
// CALIBRATION / FIT TEST COUPON
// ---------------------------

// The coupon follows the currently configured cabinet. It only includes tests
// that are meaningful for the active construction:
//   - carcass tab/slot OR dado fit
//   - drawer corner tab/slot OR dado fit
//   - drawer-bottom dado/groove fit
//   - wood-slide horizontal side clearance
//
// Joinery samples use an ACTUAL offcut edge of the corresponding stock as the
// gauge. The wood-slide samples use an actual runner/rail-stock edge.
//
// The * marker in the engraving identifies the currently configured value.

calibration_carcass_fit_active =
    carcass_joint_geometry == "tab_slot"
    || carcass_joint_geometry == "dado";

calibration_drawer_fit_active =
    has_drawers
    && (
        drawer_joint_geometry == "tab_slot"
        || drawer_joint_geometry == "dado"
    );

calibration_bottom_fit_active =
    has_drawers
    && drawer_bottom_joinery == "dado";

calibration_wood_slide_fit_active =
    has_drawers
    && drawer_mount == "wood_rails";

function calibration_coupon_test_count() =
    (calibration_carcass_fit_active ? 1 : 0)
    + (calibration_drawer_fit_active ? 1 : 0)
    + (calibration_bottom_fit_active ? 1 : 0)
    + (calibration_wood_slide_fit_active ? 1 : 0);

function calibration_carcass_row_index() = 0;

function calibration_drawer_row_index() =
    calibration_carcass_fit_active ? 1 : 0;

function calibration_bottom_row_index() =
    (calibration_carcass_fit_active ? 1 : 0)
    + (calibration_drawer_fit_active ? 1 : 0);

function calibration_slide_row_index() =
    (calibration_carcass_fit_active ? 1 : 0)
    + (calibration_drawer_fit_active ? 1 : 0)
    + (calibration_bottom_fit_active ? 1 : 0);

calibration_coupon_margin = 12;
calibration_coupon_title_height = 24;
calibration_coupon_row_height = 52;
calibration_coupon_cell_width = 52;
calibration_coupon_slot_length = 24;
calibration_coupon_geometry_y_offset = 14;
calibration_coupon_frame_margin = 8;

function calibration_coupon_sample_count() =
    max(
        len(calibration_fit_offsets),
        len(calibration_slide_clearance_offsets)
    );

calibration_coupon_width =
    2*calibration_coupon_margin
    + calibration_coupon_sample_count()
      *calibration_coupon_cell_width;

calibration_coupon_height =
    2*calibration_coupon_margin
    + calibration_coupon_title_height
    + max(1,calibration_coupon_test_count())
      *calibration_coupon_row_height;

function calibration_coupon_row_y(row) =
    calibration_coupon_margin
    + row*calibration_coupon_row_height;

function calibration_coupon_sample_x(i,count) =
    calibration_coupon_margin
    + (
        calibration_coupon_sample_count()-count
      )*calibration_coupon_cell_width/2
    + (i+0.5)*calibration_coupon_cell_width;

function calibration_coupon_value(base,offset) =
    max(0,base+offset);

function calibration_coupon_round(v) =
    round(v*100)/100;

function calibration_coupon_value_label(base,offset) =
    str(
        calibration_coupon_round(
            calibration_coupon_value(base,offset)
        ),
        abs(offset) < 0.00001 ? "*" : ""
    );

function calibration_coupon_max_pocket_depth() =
    max(
        calibration_carcass_fit_active
        && carcass_joint_geometry == "dado"
            ? effective_dado_depth()
            : 0,
        calibration_drawer_fit_active
        && drawer_joint_geometry == "dado"
            ? effective_drawer_dado_depth()
            : 0,
        calibration_bottom_fit_active
            ? effective_drawer_bottom_dado_depth()
            : 0
    );

module calibration_coupon_registration_frame() {
    fw = export_bounding_box_frame_width;
    fm = calibration_coupon_frame_margin;

    difference() {
        translate([-fm,-fm])
            square([
                calibration_coupon_width+2*fm,
                calibration_coupon_height+2*fm
            ]);

        translate([-fm+fw,-fm+fw])
            square([
                calibration_coupon_width+2*fm-2*fw,
                calibration_coupon_height+2*fm-2*fw
            ]);
    }
}

module calibration_coupon_through_slot_samples(
    row,
    stock_thickness,
    base_clearance,
    offsets
) {
    count = len(offsets);
    y =
        calibration_coupon_row_y(row)
        + calibration_coupon_geometry_y_offset;

    for (i=[0:count-1]) {
        clearance =
            calibration_coupon_value(
                base_clearance,
                offsets[i]
            );
        sw = max(0.5,stock_thickness+clearance);
        sx =
            calibration_coupon_sample_x(i,count)
            - sw/2;

        translate([sx,y])
            slot_shape_2d(
                sw,
                calibration_coupon_slot_length
            );
    }
}

module calibration_coupon_pocket_samples(
    row,
    insert_thickness,
    base_clearance,
    offsets
) {
    count = len(offsets);
    y =
        calibration_coupon_row_y(row)
        + calibration_coupon_geometry_y_offset;

    for (i=[0:count-1]) {
        clearance =
            calibration_coupon_value(
                base_clearance,
                offsets[i]
            );
        pw = max(0.5,insert_thickness+clearance);
        px =
            calibration_coupon_sample_x(i,count)
            - pw/2;

        translate([px,y])
            square([
                pw,
                calibration_coupon_slot_length
            ]);
    }
}


// Through-cut coupon geometry.
module calibration_coupon_cut_geometry() {
    difference() {
        square([
            calibration_coupon_width,
            calibration_coupon_height
        ]);

        if (calibration_carcass_fit_active
            && carcass_joint_geometry == "tab_slot")
            calibration_coupon_through_slot_samples(
                calibration_carcass_row_index(),
                material_thickness,
                joint_fit_clearance,
                calibration_fit_offsets
            );

        if (calibration_drawer_fit_active
            && drawer_joint_geometry == "tab_slot")
            calibration_coupon_through_slot_samples(
                calibration_drawer_row_index(),
                drawer_material_thickness,
                drawer_joint_fit_clearance,
                calibration_fit_offsets
            );

        if (calibration_wood_slide_fit_active)
            calibration_coupon_through_slot_samples(
                calibration_slide_row_index(),
                wood_drawer_runner_thickness,
                wood_rail_side_clearance,
                calibration_slide_clearance_offsets
            );
    }
}


// Blind-pocket geometry. The engraving rows state the required depth.
module calibration_coupon_pocket_geometry() {
    if (calibration_carcass_fit_active
        && carcass_joint_geometry == "dado")
        calibration_coupon_pocket_samples(
            calibration_carcass_row_index(),
            material_thickness,
            dado_fit_clearance,
            calibration_fit_offsets
        );

    if (calibration_drawer_fit_active
        && drawer_joint_geometry == "dado")
        calibration_coupon_pocket_samples(
            calibration_drawer_row_index(),
            drawer_material_thickness,
            drawer_dado_fit_clearance,
            calibration_fit_offsets
        );

    if (calibration_bottom_fit_active)
        calibration_coupon_pocket_samples(
            calibration_bottom_row_index(),
            drawer_bottom_thickness,
            drawer_dado_fit_clearance,
            calibration_fit_offsets
        );
}


module calibration_coupon_center_text(
    txt,
    x,
    y,
    size=calibration_coupon_label_size
) {
    translate([x,y])
        text(
            txt,
            size=size,
            halign="center",
            valign="center"
        );
}

module calibration_coupon_left_text(
    txt,
    x,
    y,
    size=calibration_coupon_label_size
) {
    translate([x,y])
        text(
            txt,
            size=size,
            halign="left",
            valign="center"
        );
}

module calibration_coupon_sample_labels(
    row,
    base_clearance,
    offsets
) {
    count = len(offsets);
    y = calibration_coupon_row_y(row)+5;

    for (i=[0:count-1])
        calibration_coupon_center_text(
            calibration_coupon_value_label(
                base_clearance,
                offsets[i]
            ),
            calibration_coupon_sample_x(i,count),
            y,
            calibration_coupon_label_size*0.78
        );
}

module calibration_coupon_engrave_geometry() {
    title_y =
        calibration_coupon_height
        - calibration_coupon_margin
        - calibration_coupon_title_height/2;

    calibration_coupon_center_text(
        "CABINET FIT CALIBRATION",
        calibration_coupon_width/2,
        title_y+4,
        calibration_coupon_label_size*1.15
    );

    calibration_coupon_center_text(
        "* = configured value   clearances in mm",
        calibration_coupon_width/2,
        title_y-7,
        calibration_coupon_label_size*0.72
    );

    if (calibration_coupon_test_count() == 0)
        calibration_coupon_center_text(
            "NO ACTIVE FIT TESTS IN CURRENT CABINET",
            calibration_coupon_width/2,
            calibration_coupon_height/2,
            calibration_coupon_label_size
        );

    if (calibration_carcass_fit_active) {
        row = calibration_carcass_row_index();
        ry = calibration_coupon_row_y(row);

        calibration_coupon_left_text(
            carcass_joint_geometry == "tab_slot"
                ? str(
                    "CARCASS SLOT | insert actual ",
                    calibration_coupon_round(material_thickness),
                    " stock edge"
                  )
                : str(
                    "CARCASS DADO | stock ",
                    calibration_coupon_round(material_thickness),
                    " | depth ",
                    calibration_coupon_round(effective_dado_depth())
                  ),
            calibration_coupon_margin,
            ry+calibration_coupon_row_height-7,
            calibration_coupon_label_size*0.72
        );

        calibration_coupon_sample_labels(
            row,
            carcass_joint_geometry == "tab_slot"
                ? joint_fit_clearance
                : dado_fit_clearance,
            calibration_fit_offsets
        );
    }

    if (calibration_drawer_fit_active) {
        row = calibration_drawer_row_index();
        ry = calibration_coupon_row_y(row);

        calibration_coupon_left_text(
            drawer_joint_geometry == "tab_slot"
                ? str(
                    "DRAWER SLOT | insert actual ",
                    calibration_coupon_round(drawer_material_thickness),
                    " wall-stock edge"
                  )
                : str(
                    "DRAWER DADO | wall ",
                    calibration_coupon_round(drawer_material_thickness),
                    " | depth ",
                    calibration_coupon_round(
                        effective_drawer_dado_depth()
                    )
                  ),
            calibration_coupon_margin,
            ry+calibration_coupon_row_height-7,
            calibration_coupon_label_size*0.72
        );

        calibration_coupon_sample_labels(
            row,
            drawer_joint_geometry == "tab_slot"
                ? drawer_joint_fit_clearance
                : drawer_dado_fit_clearance,
            calibration_fit_offsets
        );
    }

    if (calibration_bottom_fit_active) {
        row = calibration_bottom_row_index();
        ry = calibration_coupon_row_y(row);

        calibration_coupon_left_text(
            str(
                "BOTTOM GROOVE | bottom stock ",
                calibration_coupon_round(drawer_bottom_thickness),
                " | depth ",
                calibration_coupon_round(
                    effective_drawer_bottom_dado_depth()
                )
            ),
            calibration_coupon_margin,
            ry+calibration_coupon_row_height-7,
            calibration_coupon_label_size*0.72
        );

        calibration_coupon_sample_labels(
            row,
            drawer_dado_fit_clearance,
            calibration_fit_offsets
        );
    }

    if (calibration_wood_slide_fit_active) {
        row = calibration_slide_row_index();
        ry = calibration_coupon_row_y(row);

        calibration_coupon_left_text(
            str(
                "WOOD SLIDE SIDE CLEARANCE | runner stock ",
                calibration_coupon_round(
                    wood_drawer_runner_thickness
                ),
                " | per side"
            ),
            calibration_coupon_margin,
            ry+calibration_coupon_row_height-7,
            calibration_coupon_label_size*0.72
        );

        calibration_coupon_sample_labels(
            row,
            wood_rail_side_clearance,
            calibration_slide_clearance_offsets
        );
    }
}


module calibration_coupon_cut() {
    calibration_coupon_registration_frame();
    calibration_coupon_cut_geometry();

    if (show_calibration_pockets_over_cut)
        %calibration_coupon_pocket_geometry();

    if (show_calibration_labels_over_cut)
        %calibration_coupon_engrave_geometry();
}

module calibration_coupon_pocket() {
    calibration_coupon_registration_frame();
    calibration_coupon_pocket_geometry();
}

module calibration_coupon_engrave() {
    calibration_coupon_registration_frame();
    calibration_coupon_engrave_geometry();
}


module carcass_cut_layout() {
    g = layout_gap;

    // Row 1: side panels.
    paint("side_left")
        translate([0,0])
            cabinet_side_panel_cut("left");

    paint("side_right")
        translate([resolved_cabinet_depth+g,0])
            cabinet_side_panel_cut("right");

    // Row 2: bottom + top parts.
    paint("bottom")
        translate([0,layout_y2])
            cabinet_bottom_cut();

    if (top_style == "full") {
        paint("top_full")
            translate([top_layout_x,layout_y2])
                difference() {
                    joined_horizontal_bank_receiver_cut(
                        0,resolved_cabinet_depth,"top");

                    worktop_registration_support_holes_2d(
                        0,resolved_cabinet_depth);
                }
    } else {
        paint("top_front")
            translate([top_layout_x,layout_y2])
                difference() {
                    joined_horizontal_bank_receiver_cut(
                        0,top_stretcher_depth,"top");

                    worktop_registration_support_holes_2d(
                        0,top_stretcher_depth);
                }

        paint("top_rear")
            translate([top_layout_x,
                       layout_y2+top_stretcher_depth+g])
                difference() {
                    joined_horizontal_bank_receiver_cut(
                        resolved_cabinet_depth-top_stretcher_depth,
                        top_stretcher_depth,"top");

                    worktop_registration_support_holes_2d(
                        resolved_cabinet_depth-top_stretcher_depth,
                        top_stretcher_depth);
                }
    }

    // Row 3: back construction + optional toe kick.
    if (back_style == "panel"
        || back_style == "structural_panel") {
        paint("back")
            translate([0,layout_y3])
                back_panel_cut();
    } else if (back_style == "stretchers") {
        for (b=[0:back_stretcher_count-1])
            paint("back_stretcher",b)
                translate([
                    0,
                    layout_y3
                    + b*(back_stretcher_height+g)
                ])
                    joined_back_stretcher_cut();
    }

    if (has_toe_kick)
        paint("toe_kick")
            translate([back_cut_width+g,layout_y3])
                joined_toe_kick_cut();

    // Row 4+: door-compartment shelves, then optional combo divider.
    if (!mixed_bay_mode && has_doors && door_shelf_count > 0) {
        for (s=[0:door_shelf_count-1]) {
            shelf_y = layout_y4+s*(shelf_depth+g);

            if (shelf_style == "fixed") {
                paint("shelf",s)
                    translate([0,shelf_y])
                        fixed_door_shelf_cut();
            } else {
                for (b=[0:door_adjustable_shelf_piece_count()-1])
                    paint("shelf",s*10+b)
                        translate([
                            door_adjustable_shelf_layout_x(b),
                            shelf_y
                        ])
                            adjustable_door_shelf_cut(b);
            }
        }
    }

    if (!mixed_bay_mode && cabinet_contents == "combo") {
        divider_y = layout_y4
                    + (has_doors ? door_shelf_count : 0)*(shelf_depth+g);

        paint("divider")
            translate([0,divider_y])
                joined_horizontal_bank_receiver_cut(
                    0,shelf_depth,"shelf");
    }

    // Generalized mixed-bay shelves. Each bay may choose adjustable or fixed.
    if (mixed_bay_mode && mixed_bay_total_shelf_count() > 0) {
        for (b=[0:active_mixed_bay_count-1])
            if (mixed_bay_is_shelfable(b) && mixed_bay_shelf_count(b) > 0)
                for (s=[1:mixed_bay_shelf_count(b)])
                    paint("shelf",mixed_bay_shelf_part_index(b,s))
                        translate([
                            0,
                            mixed_bay_shelf_layout_y(b,s)
                        ])
                            if (mixed_bay_shelf_style(b) == "fixed")
                                mixed_bay_fixed_shelf_cut(b);
                            else
                                mixed_bay_adjustable_shelf_cut(b);
    }

    // Full-depth structural partitions between generalized mixed bays.
    if (mixed_bay_partition_count() > 0) {
        for (p=[0:mixed_bay_partition_count()-1])
            paint("mixed_bay_partition",p)
                translate([
                    0,
                    mixed_bay_partition_layout_base_y
                    + p*mixed_bay_partition_layout_row_height
                ])
                    mixed_bay_partition_cut(p);
    }

    // Vertical hinge-mounting partitions for cabinets with >2 doors.
    if (door_hinge_partition_count() > 0) {
        for (p=[0:door_hinge_partition_count()-1])
            paint("door_hinge_partition",p)
                translate([
                    0,
                    door_hinge_partition_layout_base_y
                    + p*door_hinge_partition_layout_row_height
                ])
                    door_hinge_partition_cut();
    }

    // Vertical partitions between equal-width drawer banks.
    if (has_drawers && drawer_bank_partition_count() > 0) {
        for (p=[0:drawer_bank_partition_count()-1])
            paint("drawer_bank_partition",p)
                translate([
                    0,
                    drawer_bank_partition_layout_base_y
                    + p*drawer_bank_partition_layout_row_height
                ])
                    drawer_bank_partition_cut(p);
    }

    // Optional drawer separators have their own region immediately before
    // the drawer-box parts.
    if (drawer_separator_count > 0) {
        for (s=[0:drawer_separator_count-1]) {
            sy = drawer_separator_layout_base_y
                 + s*drawer_separator_layout_row_height;

            if (drawer_separator_style == "full") {
                paint("drawer_separator",s)
                    translate([0,sy])
                        joined_horizontal_panel_cut(
                            drawer_separator_full_depth,"separator");
            } else {
                paint("drawer_separator",s)
                    translate([0,sy])
                        joined_horizontal_panel_cut(
                            drawer_separator_stretcher_actual_depth,"separator");

                paint("drawer_separator",s)
                    translate([
                        0,
                        sy+drawer_separator_stretcher_actual_depth+g
                    ])
                        joined_horizontal_panel_cut(
                            drawer_separator_stretcher_actual_depth,"separator");
            }
        }
    }
}

module drawer_cut_layout() {
    if (has_drawers) {
        g = layout_gap;
        st = drawer_material_thickness;
        d  = drawer_box_depth;

        for (b=[0:active_drawer_bank_count()-1])
            if (drawer_bank_drawer_count(b) > 0)
                for (i=[0:drawer_bank_drawer_count(b)-1]) {
                ow = drawer_outer_width(b);
                bh = drawer_box_height(i,b);
                row_y = drawer_layout_row_y(b,i);
                pi = drawer_part_index(b,i);

                if (include_drawer_faces)
                    paint("drawer_face",pi)
                        translate([0,row_y])
                            drawer_face_cut(i,b);

                if (drawer_mount == "wood_rails") {
                    rail_x = max(drawer_face_width(b),ow) + g;
                    runner_x =
                        standalone_include_fixed_wood_rails_resolved
                            ? rail_x + resolved_wood_rail_depth + g
                            : rail_x;

                    if (standalone_include_fixed_wood_rails_resolved) {
                        paint("rail",pi)
                            translate([rail_x,row_y])
                                wood_fixed_rail_cut();
                        paint("rail",pi)
                            translate([rail_x,row_y+wood_rail_height+g])
                                wood_fixed_rail_cut();
                    }

                    paint("drawer_runner",pi)
                        translate([runner_x,row_y])
                            wood_drawer_runner_cut();
                    paint("drawer_runner",pi)
                        translate([
                            runner_x,
                            row_y+wood_drawer_runner_height+g
                        ])
                            wood_drawer_runner_cut();
                }

                side_y = drawer_layout_box_parts_y(b,i);

                paint("drawer_side_l",pi)
                    translate([0,side_y])
                        drawer_side_panel_cut(d,bh,i);

                paint("drawer_side_r",pi)
                    translate([d+g,side_y])
                        drawer_side_panel_cut(d,bh,i);

                paint("drawer_box_front",pi)
                    translate([2*(d+g),side_y])
                        drawer_cross_panel_cut(bh,true,b);

                paint("drawer_box_back",pi)
                    translate([2*(d+g),side_y+bh+g])
                        drawer_cross_panel_cut(bh,false,b);

                bottom_y = side_y + bh + 2*g;

                paint("drawer_bottom",pi)
                    translate([0,bottom_y])
                        drawer_bottom_cut(b);


                if (drawer_divider_active_for(b,i)) {
                    for (n=[0:max(0,drawer_divider_x_count()-1)])
                        if (drawer_divider_x_count() > 0)
                            paint("drawer_divider",pi)
                                translate([
                                    0,
                                    drawer_layout_divider_piece_y(b,i,true,n)
                                ])
                                    drawer_divider_longitudinal_cut(b,i,n);

                    for (n=[0:max(0,drawer_divider_y_count()-1)])
                        if (drawer_divider_y_count() > 0)
                            paint("drawer_divider",pi)
                                translate([
                                    0,
                                    drawer_layout_divider_piece_y(b,i,false,n)
                                ])
                                    drawer_divider_transverse_cut(b,i,n);
                }
            }
    }
}

module door_cut_layout() {
    if (has_doors && door_face_height > 20) {
        if (mixed_bay_mode) {
            for (b=[0:active_mixed_bay_count-1])
                if (mixed_bay_is_type(b,"door"))
                    for (leaf=[0:mixed_bay_door_count(b)-1])
                        paint("door",mixed_bay_door_part_index(b,leaf))
                            translate([
                                mixed_bay_door_layout_x(b,leaf),
                                door_layout_y
                            ])
                                mixed_bay_door_panel_cut(b,leaf);
        }
        else {
            for (i=[0:door_count-1])
                paint("door",i)
                    translate([
                        door_layout_part_x(i),
                        door_layout_y
                    ])
                        door_panel_cut(i);
        }
    }
}

// Blind operations are split by machining type/depth while retaining the
// combined pocket_layout for backwards-compatible CAM workflows.

module carcass_dado_operation_geometry_2d() {
    g = layout_gap;

    if (carcass_joint_geometry == "dado") {
        translate([0,-side_panel_bottom_z]) {
            all_side_dado_pockets_2d();
            mixed_bay_side_fixed_shelf_dado_pockets_2d("left");
        }

        translate([resolved_cabinet_depth+g,-side_panel_bottom_z]) {
            all_side_dado_pockets_2d();
            mixed_bay_side_fixed_shelf_dado_pockets_2d("right");
        }
    }

    // Dado receivers for automatic multi-door hinge partitions.
    if (door_hinge_partition_count() > 0
        && carcass_joint_geometry == "dado") {

        translate([0,layout_y2])
            bottom_door_hinge_partition_receiver_dado_pockets_2d();

        if (top_style == "full") {
            translate([top_layout_x,layout_y2])
                door_hinge_partition_receiver_dado_pockets_2d(
                    0,resolved_cabinet_depth);
        } else {
            translate([top_layout_x,layout_y2])
                door_hinge_partition_receiver_dado_pockets_2d(
                    0,top_stretcher_depth);

            translate([
                top_layout_x,
                layout_y2+top_stretcher_depth+g
            ])
                door_hinge_partition_receiver_dado_pockets_2d(
                    resolved_cabinet_depth-top_stretcher_depth,
                    top_stretcher_depth);
        }

        if (!mixed_bay_mode && cabinet_contents == "combo") {
            divider_y = layout_y4
                + (has_doors ? door_shelf_count : 0)
                  *(shelf_depth+g);

            translate([0,divider_y])
                door_hinge_partition_receiver_dado_pockets_2d(
                    0,shelf_depth);
        }
    }

    // Dado receivers for generalized mixed-bay partitions.
    if (mixed_bay_partition_count() > 0
        && carcass_joint_geometry == "dado") {

        translate([0,layout_y2])
            bottom_mixed_bay_partition_receiver_dado_pockets_2d();

        if (top_style == "full") {
            translate([top_layout_x,layout_y2])
                mixed_bay_partition_receiver_dado_pockets_2d(
                    0,resolved_cabinet_depth);
        } else {
            translate([top_layout_x,layout_y2])
                mixed_bay_partition_receiver_dado_pockets_2d(
                    0,top_stretcher_depth);

            translate([
                top_layout_x,
                layout_y2+top_stretcher_depth+g
            ])
                mixed_bay_partition_receiver_dado_pockets_2d(
                    resolved_cabinet_depth-top_stretcher_depth,
                    top_stretcher_depth);
        }
    }

    // Fixed mixed-bay shelf dados in the VERTICAL partitions. The combined
    // carcass-dado output shows the plan geometry for both partition faces.
    if (mixed_bay_partition_count() > 0
        && carcass_joint_geometry == "dado") {
        for (p=[0:mixed_bay_partition_count()-1])
            translate([
                0,
                mixed_bay_partition_layout_base_y
                + p*mixed_bay_partition_layout_row_height
            ])
                mixed_bay_partition_fixed_shelf_dado_pockets_2d(
                    p,"both");
    }

    // Dado receivers for internal drawer-bank partitions live in horizontal
    // bottom/top/combo-divider parts, not the cabinet sides.
    if (drawer_bank_partition_joinery_mode() == "dado"
        && drawer_bank_partition_count() > 0) {

        translate([0,layout_y2])
            bottom_drawer_bank_receiver_dado_pockets_2d();

        if (top_style == "full") {
            translate([top_layout_x,layout_y2])
                drawer_bank_receiver_dado_pockets_2d(
                    0,resolved_cabinet_depth);
        } else {
            translate([top_layout_x,layout_y2])
                drawer_bank_receiver_dado_pockets_2d(
                    0,top_stretcher_depth);

            translate([
                top_layout_x,
                layout_y2+top_stretcher_depth+g
            ])
                drawer_bank_receiver_dado_pockets_2d(
                    resolved_cabinet_depth-top_stretcher_depth,
                    top_stretcher_depth);
        }

        if (cabinet_contents == "combo") {
            divider_y = layout_y4
                + (has_doors ? door_shelf_count : 0)
                  *(shelf_depth+g);

            translate([0,divider_y])
                drawer_bank_receiver_dado_pockets_2d(
                    0,shelf_depth);
        }
    }

    // Blind dados for the separate stackable base-frame cross rails.
    if (stack_base_active
        && carcass_joint_geometry == "dado") {
        translate([
            0,
            stack_base_side_layout_y
        ])
            stack_base_side_dado_pockets_2d();

        translate([
            resolved_cabinet_depth+g,
            stack_base_side_layout_y
        ])
            stack_base_side_dado_pockets_2d();
    }

    // Structural-back dados in the bottom and rear-reaching top member.
    // Side-panel back dados are already part of all_side_dado_pockets_2d().
    if (structural_back_active
        && carcass_joint_geometry == "dado") {

        translate([0,layout_y2])
            bottom_back_receiver_dado_pockets_2d();

        if (top_style == "full") {
            translate([top_layout_x,layout_y2])
                back_horizontal_dado_pocket_2d(
                    0,resolved_cabinet_depth);
        } else {
            // Front stretcher does not reach the back and therefore receives
            // no structural-back dado.
            translate([
                top_layout_x,
                layout_y2+top_stretcher_depth+g
            ])
                back_horizontal_dado_pocket_2d(
                    resolved_cabinet_depth-top_stretcher_depth,
                    top_stretcher_depth);
        }
    }
}

module drawer_dado_operation_geometry_2d() {
    drawer_joinery_dado_pocket_layout();
}

module drawer_bottom_operation_geometry_2d() {
    drawer_bottom_groove_pocket_layout();
}


module drawer_divider_bottom_operation_geometry_2d() {
    if (has_drawers && include_drawer_divider_grid
        && drawer_divider_bottom_capture_active()) {
        for (b=[0:active_drawer_bank_count()-1])
            if (drawer_bank_drawer_count(b) > 0)
                for (i=[0:drawer_bank_drawer_count(b)-1])
                    if (drawer_divider_active_for(b,i)) {
                        bottom_y = drawer_layout_bottom_y(b,i);
                        paint("drawer_bottom",drawer_part_index(b,i))
                            translate([0,bottom_y])
                                drawer_divider_bottom_grooves_2d(b,i);
                    }
    }
}

module drawer_divider_perimeter_operation_geometry_2d() {
    if (has_drawers && include_drawer_divider_grid
        && drawer_divider_perimeter_capture_active()) {
        g = layout_gap;
        d = drawer_box_depth;
        for (b=[0:active_drawer_bank_count()-1])
            if (drawer_bank_drawer_count(b) > 0)
                for (i=[0:drawer_bank_drawer_count(b)-1])
                    if (drawer_divider_active_for(b,i)) {
                        bh = drawer_box_height(i,b);
                        side_y = drawer_layout_box_parts_y(b,i);
                        pi = drawer_part_index(b,i);
                        paint("drawer_side_l",pi)
                            translate([0,side_y])
                                drawer_divider_side_perimeter_grooves_2d(d,bh,b,i);
                        paint("drawer_side_r",pi)
                            translate([d+g,side_y])
                                drawer_divider_side_perimeter_grooves_2d(d,bh,b,i);
                        cross_x = 2*(d+g);
                        paint("drawer_box_front",pi)
                            translate([cross_x,side_y])
                                drawer_divider_cross_perimeter_grooves_2d(bh,b,i);
                        paint("drawer_box_back",pi)
                            translate([cross_x,side_y+bh+g])
                                drawer_divider_cross_perimeter_grooves_2d(bh,b,i);
                    }
    }
}

module shelf_pin_operation_geometry_2d() {
    g = layout_gap;

    if (!mixed_bay_mode
        && has_doors
        && shelf_style == "adjustable"
        && adjustable_shelf_hole_type == "blind") {

        translate([0,-side_panel_bottom_z])
            adjustable_shelf_pin_holes_pocket_2d();

        translate([resolved_cabinet_depth+g,-side_panel_bottom_z])
            adjustable_shelf_pin_holes_pocket_2d();
    }

    if (mixed_bay_mode
        && adjustable_shelf_hole_type == "blind") {
        translate([0,-side_panel_bottom_z])
            mixed_bay_side_shelf_pin_holes_pocket_2d("left");

        translate([resolved_cabinet_depth+g,-side_panel_bottom_z])
            mixed_bay_side_shelf_pin_holes_pocket_2d("right");
    }
}

module hinge_cup_operation_geometry_2d() {
    if (has_doors && effective_hinge_style == "euro_35mm")
        door_hinge_pocket_layout();
}

module face_registration_operation_geometry_2d() {
    if (has_drawers
        && active_drawer_face_registration
        && drawer_face_registration_face_hole == "half_depth")
        drawer_face_registration_pocket_layout();
}

module base_hardware_operation_geometry_2d() {
    if (base_hardware_active
        && include_base_hardware_drill_holes) {

        if (base_mounting_plate_active)
            translate([
                0,
                base_mounting_plate_layout_y
            ])
                base_hardware_holes_plate_2d();
        else
            translate([0,layout_y2])
                base_hardware_holes_bottom_2d();
    }
}

module worktop_registration_operation_geometry_2d() {
    if (active_worktop_registration)
        translate([0,worktop_layout_y])
            worktop_registration_worktop_pockets_2d();
}

module face_frame_dado_operation_geometry_2d() {
    if (face_frame_back_dado_active) {
        g = layout_gap;
        sw = effective_face_frame_side_stile_width;
        rail_x =
            (
                face_frame_center_stile_enabled
                    ? 3
                    : 2
            )*(sw+g);

        translate([
            0,
            face_frame_layout_y
        ])
            face_frame_stile_back_dado_pocket_2d(
                "left"
            );

        translate([
            sw+g,
            face_frame_layout_y
        ])
            face_frame_stile_back_dado_pocket_2d(
                "right"
            );

        translate([
            rail_x,
            face_frame_layout_y
        ])
            face_frame_top_rail_back_dado_pocket_2d();

        translate([
            rail_x,
            face_frame_layout_y
                + effective_face_frame_top_rail_width
                + g
        ])
            face_frame_bottom_rail_back_dado_pocket_2d();

        if (face_frame_mid_rail_active)
            translate([
                rail_x,
                face_frame_layout_y
                    + effective_face_frame_top_rail_width
                    + effective_face_frame_bottom_rail_width
                    + 2*g
            ])
                face_frame_mid_rail_back_dado_pocket_2d();
    }
}


module ganging_operation_geometry_2d() {
    if (ganging_dowel_active) {
        g = layout_gap;

        if (ganging_side_active("left"))
            translate([0,-side_panel_bottom_z])
                ganging_side_dowel_pockets_2d("left");

        if (ganging_side_active("right"))
            translate([
                resolved_cabinet_depth+g,
                -side_panel_bottom_z
            ])
                ganging_side_dowel_pockets_2d("right");
    }
}


module blind_operation_geometry_2d() {
    if (standalone_drawer_active) {
        drawer_dado_operation_geometry_2d();
        drawer_bottom_operation_geometry_2d();
        drawer_divider_bottom_operation_geometry_2d();
        drawer_divider_perimeter_operation_geometry_2d();
        face_registration_operation_geometry_2d();
    }
    else {
        carcass_dado_operation_geometry_2d();
        drawer_dado_operation_geometry_2d();
        drawer_bottom_operation_geometry_2d();
        drawer_divider_bottom_operation_geometry_2d();
        drawer_divider_perimeter_operation_geometry_2d();
        shelf_pin_operation_geometry_2d();
        hinge_cup_operation_geometry_2d();
        face_registration_operation_geometry_2d();
        base_hardware_operation_geometry_2d();
        worktop_registration_operation_geometry_2d();
        face_frame_dado_operation_geometry_2d();
        ganging_operation_geometry_2d();
    }
}

// OpenSCAD cannot preserve overlapping 2D solids as independent vector paths:
// it Boolean-unions them before SVG/DXF export. Therefore blind pockets are
// previewed with the % modifier but never subtracted from or unioned into the
// through-cut part geometry.

module accessory_cut_layout() {
    if (base_mounting_plate_active)
        paint("base_mounting_plate")
            translate([0,base_mounting_plate_layout_y])
                base_mounting_plate_cut();

    if (worktop_active)
        paint("worktop")
            translate([0,worktop_layout_y])
                worktop_cut();

    if (face_frame_active) {
        g = layout_gap;
        sw = effective_face_frame_side_stile_width;
        rail_x =
            (
                face_frame_center_stile_enabled
                    ? 3
                    : 2
            )*(sw+g);

        paint("face_frame")
            translate([0,face_frame_layout_y])
                face_frame_stile_cut();

        paint("face_frame")
            translate([sw+g,face_frame_layout_y])
                face_frame_stile_cut();

        if (face_frame_center_stile_enabled)
            paint("face_frame")
                translate([
                    2*(sw+g),
                    face_frame_layout_y
                ])
                    face_frame_center_stile_cut();

        paint("face_frame")
            translate([rail_x,face_frame_layout_y])
                face_frame_top_rail_cut();

        paint("face_frame")
            translate([
                rail_x,
                face_frame_layout_y
                    + effective_face_frame_top_rail_width
                    + g
            ])
                face_frame_bottom_rail_cut();

        if (face_frame_mid_rail_active)
            paint("face_frame")
                translate([
                    rail_x,
                    face_frame_layout_y
                        + effective_face_frame_top_rail_width
                        + effective_face_frame_bottom_rail_width
                        + 2*g
                ])
                    face_frame_mid_rail_cut();
    }

    if (stack_base_active) {
        g = layout_gap;

        paint("stack_base_side")
            translate([
                0,
                stack_base_side_layout_y
            ])
                stack_base_side_rail_cut();

        paint("stack_base_side")
            translate([
                resolved_cabinet_depth+g,
                stack_base_side_layout_y
            ])
                stack_base_side_rail_cut();

        paint("stack_base_cross")
            translate([
                0,
                stack_base_cross_layout_y
            ])
                stack_base_cross_rail_cut();

        paint("stack_base_cross")
            translate([
                stack_base_cross_rail_cut_width()+g,
                stack_base_cross_layout_y
            ])
                stack_base_cross_rail_cut();
    }
}


module cut_layout_parts_only() {
    if (standalone_drawer_active)
        drawer_cut_layout();
    else {
        carcass_cut_layout();
        drawer_cut_layout();
        door_cut_layout();
        accessory_cut_layout();
    }
}

module cut_layout() {
    stock_outline();

    // Common real geometry establishes the same SVG page/viewBox as pocket_layout.
    shared_export_bounding_box_2d();

    // Exported through-cut geometry stays completely intact.
    cut_layout_parts_only();

    // Preview only: exact dados / hinge cups / blind shelf-pin drilling shown
    // at their true positions without changing exported panel topology.
    if (show_blind_pockets_over_cut_layout)
        %blind_operation_geometry_2d();
}



// ---------------------------
// STANDALONE DRAWER COMPONENT
// ---------------------------

module standalone_drawer_enclosure_reference_3d() {
    if (
        standalone_drawer_active
        && !is_undef(show_enclosure_reference)
        && show_enclosure_reference
    ) {
        t = max(1,min(3,drawer_material_thickness/4));
        ow = standalone_enclosure_opening_width;
        oh = standalone_enclosure_opening_height;
        od = standalone_enclosure_usable_depth;

        // Preview-only translucent reference surfaces; never exported to
        // manufacturing geometry.
        %color([0.65,0.65,0.65,0.18]) {
            translate([-t,0,0])
                cube([t,od,oh]);

            translate([ow,0,0])
                cube([t,od,oh]);

            translate([0,0,-t])
                cube([ow,od,t]);

            translate([0,0,oh])
                cube([ow,od,t]);

            translate([0,od,0])
                cube([ow,t,oh]);
        }
    }
}

module standalone_drawer_assembly() {
    standalone_drawer_enclosure_reference_3d();
    all_drawers();
}

module standalone_drawer_print_layout() {
    g = layout_gap;
    st = drawer_material_thickness;
    d = drawer_box_depth;

    for (b=[0:active_drawer_bank_count()-1])
        if (drawer_bank_drawer_count(b) > 0)
            for (i=[0:drawer_bank_drawer_count(b)-1]) {
                ow = drawer_outer_width(b);
                bh = drawer_box_height(i,b);
                row_y = drawer_layout_row_y(b,i);
                pi = drawer_part_index(b,i);

                if (include_drawer_faces)
                    paint("drawer_face",pi)
                        translate([0,row_y,0])
                            drawer_face_print_part(i,b);

                if (drawer_mount == "wood_rails") {
                    rail_x = max(drawer_face_width(b),ow)+g;
                    runner_x =
                        standalone_include_fixed_wood_rails_resolved
                            ? rail_x+resolved_wood_rail_depth+g
                            : rail_x;

                    if (standalone_include_fixed_wood_rails_resolved) {
                        paint("rail",pi)
                            translate([rail_x,row_y,0])
                                linear_extrude(height=wood_rail_thickness)
                                    wood_fixed_rail_cut();

                        paint("rail",pi)
                            translate([
                                rail_x,
                                row_y+wood_rail_height+g,
                                0
                            ])
                                linear_extrude(height=wood_rail_thickness)
                                    wood_fixed_rail_cut();
                    }

                    paint("drawer_runner",pi)
                        translate([runner_x,row_y,0])
                            linear_extrude(
                                height=wood_drawer_runner_thickness
                            )
                                wood_drawer_runner_cut();

                    paint("drawer_runner",pi)
                        translate([
                            runner_x,
                            row_y+wood_drawer_runner_height+g,
                            0
                        ])
                            linear_extrude(
                                height=wood_drawer_runner_thickness
                            )
                                wood_drawer_runner_cut();
                }

                side_y = drawer_layout_box_parts_y(b,i);

                paint("drawer_side_l",pi)
                    translate([0,side_y,0])
                        drawer_side_print_part(d,bh,i,b);

                paint("drawer_side_r",pi)
                    translate([d+g,side_y,0])
                        drawer_side_print_part(d,bh,i,b);

                paint("drawer_box_front",pi)
                    translate([2*(d+g),side_y,0])
                        drawer_cross_panel_print_part(
                            bh,true,b,i);

                paint("drawer_box_back",pi)
                    translate([
                        2*(d+g),
                        side_y+bh+g,
                        0
                    ])
                        drawer_cross_panel_print_part(
                            bh,false,b,i);

                bottom_y = side_y+bh+2*g;

                paint("drawer_bottom",pi)
                    translate([0,bottom_y,0])
                        drawer_bottom_print_part(b,i);

                if (drawer_divider_active_for(b,i)) {
                    for (n=[0:max(0,drawer_divider_x_count()-1)])
                        if (drawer_divider_x_count() > 0)
                            paint("drawer_divider",pi)
                                translate([
                                    0,
                                    drawer_layout_divider_piece_y(b,i,true,n),
                                    0
                                ])
                                    linear_extrude(height=drawer_divider_thickness_resolved())
                                        drawer_divider_longitudinal_cut(b,i,n);
                    for (n=[0:max(0,drawer_divider_y_count()-1)])
                        if (drawer_divider_y_count() > 0)
                            paint("drawer_divider",pi)
                                translate([
                                    0,
                                    drawer_layout_divider_piece_y(b,i,false,n),
                                    0
                                ])
                                    linear_extrude(height=drawer_divider_thickness_resolved())
                                        drawer_divider_transverse_cut(b,i,n);
                }
            }
}

module standalone_drawer_bom_report() {
    echo("BOM_BEGIN");
    echo("BOM_HEADER|ID|QTY|CATEGORY|MATERIAL|THICKNESS_MM|CUT_W_MM|CUT_H_MM|NOTES");

    if (has_drawers)
        for (b=[0:active_drawer_bank_count()-1])
            if (drawer_bank_drawer_count(b) > 0)
                for (i=[0:drawer_bank_drawer_count(b)-1]) {
                    bh = drawer_box_height(i,b);

                    if (include_drawer_faces)
                        bom_row(
                            id_drawer_face(b,i),
                            "drawer_face","DRAWER_FRONT",
                            drawer_front_thickness,
                            drawer_face_width(b),
                            drawer_face_height_for(i,b),
                            fronts_inset_flush
                                ? "inset_flush"
                                : "overlay"
                        );

                    if (drawer_mount == "wood_rails") {
                        if (standalone_include_fixed_wood_rails_resolved) {
                            bom_row(
                                id_drawer_rail(b,i,0),
                                "drawer_rail","WOOD_RAIL",
                                wood_rail_thickness,
                                resolved_wood_rail_depth,
                                wood_rail_height,
                                "fixed_enclosure"
                            );
                            bom_row(
                                id_drawer_rail(b,i,1),
                                "drawer_rail","WOOD_RAIL",
                                wood_rail_thickness,
                                resolved_wood_rail_depth,
                                wood_rail_height,
                                "fixed_enclosure"
                            );
                        }

                        bom_row(
                            id_drawer_runner(b,i,0),
                            "drawer_runner","WOOD_RUNNER",
                            wood_drawer_runner_thickness,
                            resolved_wood_drawer_runner_depth,
                            wood_drawer_runner_height,
                            "drawer"
                        );
                        bom_row(
                            id_drawer_runner(b,i,1),
                            "drawer_runner","WOOD_RUNNER",
                            wood_drawer_runner_thickness,
                            resolved_wood_drawer_runner_depth,
                            wood_drawer_runner_height,
                            "drawer"
                        );
                    }

                    bom_row(
                        id_drawer_side(b,i,"left"),
                        "drawer_side","DRAWER_WALL",
                        drawer_material_thickness,
                        drawer_box_depth,bh,
                        drawer_joint_geometry
                    );
                    bom_row(
                        id_drawer_side(b,i,"right"),
                        "drawer_side","DRAWER_WALL",
                        drawer_material_thickness,
                        drawer_box_depth,bh,
                        drawer_joint_geometry
                    );
                    bom_row(
                        id_drawer_cross(b,i,true),
                        "drawer_front_box","DRAWER_WALL",
                        drawer_material_thickness,
                        drawer_cross_panel_width(b),bh,
                        drawer_joint_geometry
                    );
                    bom_row(
                        id_drawer_cross(b,i,false),
                        "drawer_back_box","DRAWER_WALL",
                        drawer_material_thickness,
                        drawer_cross_panel_width(b),bh,
                        drawer_joint_geometry
                    );
                    bom_row(
                        id_drawer_bottom(b,i),
                        "drawer_bottom","DRAWER_BOTTOM",
                        drawer_bottom_thickness,
                        drawer_bottom_width(b),
                        drawer_bottom_depth(),
                        drawer_bottom_joinery
                    );

                    if (drawer_divider_active_for(b,i)) {
                        for (n=[0:max(0,drawer_divider_x_count()-1)])
                            if (drawer_divider_x_count() > 0)
                                bom_row(
                                    id_drawer_divider_longitudinal(b,i,n),
                                    "drawer_divider_longitudinal","DRAWER_DIVIDER",
                                    drawer_divider_thickness_resolved(),
                                    drawer_divider_longitudinal_length(),
                                    drawer_divider_part_height(),
                                    str("MOI-DIVIDER-GRID-1;",drawer_divider_mounting)
                                );
                        for (n=[0:max(0,drawer_divider_y_count()-1)])
                            if (drawer_divider_y_count() > 0)
                                bom_row(
                                    id_drawer_divider_transverse(b,i,n),
                                    "drawer_divider_transverse","DRAWER_DIVIDER",
                                    drawer_divider_thickness_resolved(),
                                    drawer_divider_transverse_length(b),
                                    drawer_divider_part_height(),
                                    str("MOI-DIVIDER-GRID-1;",drawer_divider_mounting)
                                );
                    }
                }

    echo("BOM_END");
    square([0.01,0.01]);
}


// ---------------------------
// 3D PRINT / FIT-TEST LAYOUT
// ---------------------------

// Side panel laid flat with actual sheet thickness. Blind dados and blind
// adjustable-shelf holes are modeled as real pockets from the top face.
module cabinet_side_print_part(side="left") {
    difference() {
        linear_extrude(height=material_thickness)
            cabinet_side_panel_cut(side);

        if (carcass_joint_geometry == "dado")
            translate([
                0,0,
                material_thickness-effective_dado_depth()
            ])
                linear_extrude(
                    height=effective_dado_depth()+0.02
                )
                    translate([0,-side_panel_bottom_z]) {
                        all_side_dado_pockets_2d();
                        mixed_bay_side_fixed_shelf_dado_pockets_2d(side);
                    }

        if (!mixed_bay_mode
            && has_doors
            && shelf_style == "adjustable"
            && adjustable_shelf_hole_type == "blind") {

            dd = min(
                adjustable_shelf_hole_depth,
                material_thickness-0.5
            );

            translate([0,0,material_thickness-dd])
                linear_extrude(height=dd+0.02)
                    translate([0,-side_panel_bottom_z])
                        adjustable_shelf_pin_holes_pocket_2d();
        }

        if (mixed_bay_mode
            && adjustable_shelf_hole_type == "blind") {
            dd = min(
                adjustable_shelf_hole_depth,
                material_thickness-0.5
            );

            translate([0,0,material_thickness-dd])
                linear_extrude(height=dd+0.02)
                    translate([0,-side_panel_bottom_z])
                        mixed_bay_side_shelf_pin_holes_pocket_2d(side);
        }

        // Visualize blind ganging dowel bores in print_layout. The print view
        // uses the top extrusion face as the inspected OUTER side face for
        // both left/right parts.
        if (
            ganging_dowel_active
            && ganging_side_active(side)
        )
            translate([
                0,0,
                material_thickness
                - effective_ganging_dowel_depth
            ])
                linear_extrude(
                    height=
                        effective_ganging_dowel_depth
                        + 0.02
                )
                    translate([0,-side_panel_bottom_z])
                        ganging_side_dowel_pockets_2d(side);
    }
}

module door_print_part(i=0) {
    difference() {
        linear_extrude(height=door_thickness)
            door_panel_cut(i);

        if (effective_hinge_style == "euro_35mm") {
            dw = door_each_width(i);

            for (j=[0:hinge_count-1])
                translate([
                    hinge_local_x(dw,i),
                    hinge_local_z(j),
                    door_thickness
                        - min(
                            effective_hinge_cup_depth,
                            door_thickness-0.5
                          )
                ])
                    cylinder(
                        h=min(
                            effective_hinge_cup_depth,
                            door_thickness-0.5
                          )+0.02,
                        d=effective_hinge_cup_diameter
                    );
        }
    }
}

module mixed_bay_door_print_part(b=0,leaf=0) {
    difference() {
        linear_extrude(height=door_thickness)
            mixed_bay_door_panel_cut(b,leaf);

        if (effective_hinge_style == "euro_35mm") {
            for (j=[0:hinge_count-1])
                translate([
                    mixed_bay_door_hinge_local_x(b,leaf),
                    mixed_bay_hinge_z(j)-door_face_bottom_z,
                    door_thickness
                        - min(
                            effective_hinge_cup_depth,
                            door_thickness-0.5
                          )
                ])
                    cylinder(
                        h=min(
                            effective_hinge_cup_depth,
                            door_thickness-0.5
                          )+0.02,
                        d=effective_hinge_cup_diameter
                    );
        }
    }
}

module mixed_bay_partition_print_part(p=0) {
    difference() {
        linear_extrude(height=material_thickness)
            mixed_bay_partition_cut(p);

        if (carcass_joint_geometry == "dado") {
            dd = mixed_bay_fixed_shelf_dado_depth();

            // Shelf in bay p enters the LEFT partition face.
            translate([0,0,-0.01])
                linear_extrude(height=dd+0.02)
                    mixed_bay_partition_fixed_shelf_dado_pockets_2d(
                        p,"left");

            // Shelf in bay p+1 enters the RIGHT partition face.
            translate([0,0,material_thickness-dd-0.01])
                linear_extrude(height=dd+0.02)
                    mixed_bay_partition_fixed_shelf_dado_pockets_2d(
                        p,"right");
        }
    }
}

module cabinet_bottom_print_part() {
    difference() {
        linear_extrude(height=material_thickness)
            cabinet_bottom_cut();

        if (has_drawers
            && drawer_bank_partition_count() > 0
            && drawer_bank_partition_joinery_mode() == "dado") {
            dd = drawer_bank_partition_dado_depth();

            translate([
                0,0,
                material_thickness-dd
            ])
                linear_extrude(height=dd+0.02)
                    bottom_drawer_bank_receiver_dado_pockets_2d();
        }

        if (door_hinge_partition_count() > 0
            && carcass_joint_geometry == "dado") {
            dd = door_hinge_partition_dado_depth();

            translate([
                0,0,
                material_thickness-dd
            ])
                linear_extrude(height=dd+0.02)
                    bottom_door_hinge_partition_receiver_dado_pockets_2d();
        }

        if (mixed_bay_partition_count() > 0
            && carcass_joint_geometry == "dado") {
            dd = mixed_bay_partition_dado_depth();

            translate([
                0,0,
                material_thickness-dd
            ])
                linear_extrude(height=dd+0.02)
                    bottom_mixed_bay_partition_receiver_dado_pockets_2d();
        }

        if (structural_back_active
            && carcass_joint_geometry == "dado") {
            dd = structural_back_dado_depth;

            translate([
                0,0,
                material_thickness-dd
            ])
                linear_extrude(height=dd+0.02)
                    bottom_back_receiver_dado_pockets_2d();
        }

        if (base_hardware_active
            && !base_mounting_plate_active
            && include_base_hardware_drill_holes)
            translate([0,0,-0.01])
                linear_extrude(height=material_thickness+0.02)
                    base_hardware_holes_bottom_2d();
    }
}


module horizontal_bank_receiver_print_part(
    panel_y0,depth,receiver_face="top",door_receiver_face="same",
    tab_location="default"
) {
    actual_door_face =
        door_receiver_face == "same"
            ? receiver_face
            : door_receiver_face;

    difference() {
        linear_extrude(height=material_thickness)
            joined_horizontal_bank_receiver_cut(
                panel_y0,depth,tab_location);

        if (has_drawers
            && drawer_bank_partition_count() > 0
            && drawer_bank_partition_joinery_mode() == "dado") {
            dd = drawer_bank_partition_dado_depth();
            zcut = receiver_face == "top"
                ? material_thickness-dd
                : -0.01;

            translate([0,0,zcut])
                linear_extrude(height=dd+0.02)
                    drawer_bank_receiver_dado_pockets_2d(
                        panel_y0,depth);
        }

        if (door_hinge_partition_count() > 0
            && carcass_joint_geometry == "dado") {
            dd = door_hinge_partition_dado_depth();
            zcut = actual_door_face == "top"
                ? material_thickness-dd
                : -0.01;

            translate([0,0,zcut])
                linear_extrude(height=dd+0.02)
                    door_hinge_partition_receiver_dado_pockets_2d(
                        panel_y0,depth);
        }

        if (mixed_bay_partition_count() > 0
            && carcass_joint_geometry == "dado") {
            dd = mixed_bay_partition_dado_depth();
            zcut = receiver_face == "top"
                ? material_thickness-dd
                : -0.01;

            translate([0,0,zcut])
                linear_extrude(height=dd+0.02)
                    mixed_bay_partition_receiver_dado_pockets_2d(
                        panel_y0,depth);
        }

        if (structural_back_active
            && carcass_joint_geometry == "dado") {
            dd = structural_back_dado_depth;
            zcut = receiver_face == "top"
                ? material_thickness-dd
                : -0.01;

            translate([0,0,zcut])
                linear_extrude(height=dd+0.02)
                    back_horizontal_dado_pocket_2d(
                        panel_y0,depth);
        }

        if (base_hardware_active
            && !base_mounting_plate_active
            && include_base_hardware_drill_holes
            && receiver_face == "top"
            && panel_y0 == 0
            && depth == resolved_cabinet_depth)
            translate([0,0,-0.01])
                linear_extrude(height=material_thickness+0.02)
                    base_hardware_holes_bottom_2d();
    }
}

module print_layout() {
    g = layout_gap;

    // Carcass side panels.
    paint("side_left")
        translate([0,0,0])
            cabinet_side_print_part("left");

    paint("side_right")
        translate([resolved_cabinet_depth+g,0,0])
            cabinet_side_print_part("right");

    // Bottom + top members.
    paint("bottom")
        translate([0,layout_y2,0])
            cabinet_bottom_print_part();

    if (top_style == "full") {
        paint("top_full")
            translate([top_layout_x,layout_y2,0])
                difference() {
                    horizontal_bank_receiver_print_part(
                        0,resolved_cabinet_depth,"bottom","same","top");

                    translate([0,0,-0.01])
                        linear_extrude(
                            height=material_thickness+0.02
                        )
                            worktop_registration_support_holes_2d(
                                0,resolved_cabinet_depth);
                }
    } else {
        paint("top_front")
            translate([top_layout_x,layout_y2,0])
                difference() {
                    horizontal_bank_receiver_print_part(
                        0,top_stretcher_depth,"bottom","same","top");

                    translate([0,0,-0.01])
                        linear_extrude(
                            height=material_thickness+0.02
                        )
                            worktop_registration_support_holes_2d(
                                0,top_stretcher_depth);
                }

        paint("top_rear")
            translate([
                top_layout_x,
                layout_y2+top_stretcher_depth+g,
                0
            ])
                difference() {
                    horizontal_bank_receiver_print_part(
                        resolved_cabinet_depth-top_stretcher_depth,
                        top_stretcher_depth,
                        "bottom","same","top");

                    translate([0,0,-0.01])
                        linear_extrude(
                            height=material_thickness+0.02
                        )
                            worktop_registration_support_holes_2d(
                                resolved_cabinet_depth-top_stretcher_depth,
                                top_stretcher_depth);
                }
    }

    // Back construction + optional toe kick.
    if (back_style == "panel"
        || back_style == "structural_panel") {
        paint("back")
            translate([0,layout_y3,0])
                linear_extrude(
                    height=
                        back_style == "structural_panel"
                            ? material_thickness
                            : back_thickness
                )
                    back_panel_cut();
    } else if (back_style == "stretchers") {
        for (b=[0:back_stretcher_count-1])
            paint("back_stretcher",b)
                translate([
                    0,
                    layout_y3
                    + b*(back_stretcher_height+g),
                    0
                ])
                    linear_extrude(height=material_thickness)
                        joined_back_stretcher_cut();
    }

    if (has_toe_kick)
        paint("toe_kick")
            translate([back_cut_width+g,layout_y3,0])
                linear_extrude(height=material_thickness)
                    joined_toe_kick_cut();

    // Shelves.
    if (!mixed_bay_mode && has_doors && door_shelf_count > 0) {
        for (s=[0:door_shelf_count-1]) {
            shelf_y = layout_y4+s*(shelf_depth+g);

            if (shelf_style == "fixed") {
                paint("shelf",s)
                    translate([0,shelf_y,0])
                        linear_extrude(height=material_thickness)
                            fixed_door_shelf_cut();
            } else {
                for (b=[0:door_adjustable_shelf_piece_count()-1])
                    paint("shelf",s*10+b)
                        translate([
                            door_adjustable_shelf_layout_x(b),
                            shelf_y,
                            0
                        ])
                            linear_extrude(height=material_thickness)
                                adjustable_door_shelf_cut(b);
            }
        }
    }

    // Combo divider.
    if (!mixed_bay_mode && cabinet_contents == "combo") {
        divider_y = layout_y4
                    + (has_doors ? door_shelf_count : 0)
                      *(shelf_depth+g);

        paint("divider")
            translate([0,divider_y,0])
                horizontal_bank_receiver_print_part(
                    0,shelf_depth,"top","bottom","shelf");
    }

    // Generalized mixed-bay shelves.
    if (mixed_bay_mode && mixed_bay_total_shelf_count() > 0) {
        for (b=[0:active_mixed_bay_count-1])
            if (mixed_bay_is_shelfable(b) && mixed_bay_shelf_count(b) > 0)
                for (s=[1:mixed_bay_shelf_count(b)])
                    paint("shelf",mixed_bay_shelf_part_index(b,s))
                        translate([
                            0,
                            mixed_bay_shelf_layout_y(b,s),
                            0
                        ])
                            linear_extrude(height=material_thickness)
                                if (mixed_bay_shelf_style(b) == "fixed")
                                    mixed_bay_fixed_shelf_cut(b);
                                else
                                    mixed_bay_adjustable_shelf_cut(b);
    }

    // Generalized mixed-bay full-depth partitions.
    if (mixed_bay_partition_count() > 0) {
        for (p=[0:mixed_bay_partition_count()-1])
            paint("mixed_bay_partition",p)
                translate([
                    0,
                    mixed_bay_partition_layout_base_y
                    + p*mixed_bay_partition_layout_row_height,
                    0
                ])
                    mixed_bay_partition_print_part(p);
    }

    // Vertical door hinge partitions.
    if (door_hinge_partition_count() > 0) {
        for (p=[0:door_hinge_partition_count()-1])
            paint("door_hinge_partition",p)
                translate([
                    0,
                    door_hinge_partition_layout_base_y
                    + p*door_hinge_partition_layout_row_height,
                    0
                ])
                    linear_extrude(height=material_thickness)
                        door_hinge_partition_cut();
    }

    // Vertical drawer-bank partitions.
    if (has_drawers && drawer_bank_partition_count() > 0) {
        for (p=[0:drawer_bank_partition_count()-1])
            paint("drawer_bank_partition",p)
                translate([
                    0,
                    drawer_bank_partition_layout_base_y
                    + p*drawer_bank_partition_layout_row_height,
                    0
                ])
                    linear_extrude(height=material_thickness)
                        drawer_bank_partition_cut(p);
    }

    // Drawer separators.
    if (drawer_separator_count > 0) {
        for (s=[0:drawer_separator_count-1]) {
            sy = drawer_separator_layout_base_y
                 + s*drawer_separator_layout_row_height;

            if (drawer_separator_style == "full") {
                paint("drawer_separator",s)
                    translate([0,sy,0])
                        linear_extrude(height=material_thickness)
                            joined_horizontal_panel_cut(
                                drawer_separator_full_depth,"separator");
            } else {
                paint("drawer_separator",s)
                    translate([0,sy,0])
                        linear_extrude(height=material_thickness)
                            joined_horizontal_panel_cut(
                                drawer_separator_stretcher_actual_depth,"separator");

                paint("drawer_separator",s)
                    translate([
                        0,
                        sy+drawer_separator_stretcher_actual_depth+g,
                        0
                    ])
                        linear_extrude(height=material_thickness)
                            joined_horizontal_panel_cut(
                                drawer_separator_stretcher_actual_depth,"separator");
            }
        }
    }

    // Drawers and wood-slide parts.
    if (has_drawers) {
        st = drawer_material_thickness;
        d = drawer_box_depth;

        for (b=[0:active_drawer_bank_count()-1])
            if (drawer_bank_drawer_count(b) > 0)
                for (i=[0:drawer_bank_drawer_count(b)-1]) {
                ow = drawer_outer_width(b);
                bh = drawer_box_height(i,b);
                row_y = drawer_layout_row_y(b,i);
                pi = drawer_part_index(b,i);

                if (include_drawer_faces)
                    paint("drawer_face",pi)
                        translate([0,row_y,0])
                            drawer_face_print_part(i,b);

                if (drawer_mount == "wood_rails") {
                    rail_x = max(drawer_face_width(b),ow)+g;
                    runner_x = rail_x+resolved_wood_rail_depth+g;

                    paint("rail",pi)
                        translate([rail_x,row_y,0])
                            linear_extrude(height=wood_rail_thickness)
                                wood_fixed_rail_cut();

                    paint("rail",pi)
                        translate([
                            rail_x,
                            row_y+wood_rail_height+g,
                            0
                        ])
                            linear_extrude(height=wood_rail_thickness)
                                wood_fixed_rail_cut();

                    paint("drawer_runner",pi)
                        translate([runner_x,row_y,0])
                            linear_extrude(
                                height=wood_drawer_runner_thickness
                            )
                                wood_drawer_runner_cut();

                    paint("drawer_runner",pi)
                        translate([
                            runner_x,
                            row_y+wood_drawer_runner_height+g,
                            0
                        ])
                            linear_extrude(
                                height=wood_drawer_runner_thickness
                            )
                                wood_drawer_runner_cut();
                }

                side_y = drawer_layout_box_parts_y(b,i);

                paint("drawer_side_l",pi)
                    translate([0,side_y,0])
                        drawer_side_print_part(d,bh,i,b);

                paint("drawer_side_r",pi)
                    translate([d+g,side_y,0])
                        drawer_side_print_part(d,bh,i,b);

                paint("drawer_box_front",pi)
                    translate([2*(d+g),side_y,0])
                        drawer_cross_panel_print_part(
                            bh,true,b,i);

                paint("drawer_box_back",pi)
                    translate([
                        2*(d+g),
                        side_y+bh+g,
                        0
                    ])
                        drawer_cross_panel_print_part(
                            bh,false,b,i);

                bottom_y = side_y+bh+2*g;

                paint("drawer_bottom",pi)
                    translate([0,bottom_y,0])
                        drawer_bottom_print_part(b,i);

                if (drawer_divider_active_for(b,i)) {
                    for (n=[0:max(0,drawer_divider_x_count()-1)])
                        if (drawer_divider_x_count() > 0)
                            paint("drawer_divider",pi)
                                translate([
                                    0,
                                    drawer_layout_divider_piece_y(b,i,true,n),
                                    0
                                ])
                                    linear_extrude(height=drawer_divider_thickness_resolved())
                                        drawer_divider_longitudinal_cut(b,i,n);
                    for (n=[0:max(0,drawer_divider_y_count()-1)])
                        if (drawer_divider_y_count() > 0)
                            paint("drawer_divider",pi)
                                translate([
                                    0,
                                    drawer_layout_divider_piece_y(b,i,false,n),
                                    0
                                ])
                                    linear_extrude(height=drawer_divider_thickness_resolved())
                                        drawer_divider_transverse_cut(b,i,n);
                }
            }
    }

    // Doors, including true blind Euro cup pockets.
    if (has_doors && door_face_height > 20) {
        if (mixed_bay_mode) {
            for (b=[0:active_mixed_bay_count-1])
                if (mixed_bay_is_type(b,"door"))
                    for (leaf=[0:mixed_bay_door_count(b)-1])
                        paint("door",mixed_bay_door_part_index(b,leaf))
                            translate([
                                mixed_bay_door_layout_x(b,leaf),
                                door_layout_y,
                                0
                            ])
                                mixed_bay_door_print_part(b,leaf);
        } else {
            for (i=[0:door_count-1])
                paint("door",i)
                    translate([
                        door_layout_part_x(i),
                        door_layout_y,
                        0
                    ])
                        door_print_part(i);
        }
    }

    // Optional base mounting plate and separate worktop.
    if (base_mounting_plate_active)
        paint("base_mounting_plate")
            translate([
                0,
                base_mounting_plate_layout_y,
                0
            ])
                difference() {
                    linear_extrude(height=material_thickness)
                        base_mounting_plate_cut();

                    if (include_base_hardware_drill_holes)
                        translate([0,0,-0.01])
                            linear_extrude(height=material_thickness+0.02)
                                base_hardware_holes_plate_2d();
                }

    if (worktop_active)
        paint("worktop")
            translate([
                0,
                worktop_layout_y,
                0
            ])
                difference() {
                    linear_extrude(height=worktop_thickness)
                        worktop_cut();

                    if (active_worktop_registration)
                        translate([0,0,-0.01])
                            linear_extrude(
                                height=
                                    effective_worktop_registration_blind_depth
                                    + 0.02
                            )
                                worktop_registration_worktop_pockets_2d();
                }

    if (face_frame_active) {
        g = layout_gap;
        sw = effective_face_frame_side_stile_width;
        rail_x =
            (
                face_frame_center_stile_enabled
                    ? 3
                    : 2
            )*(sw+g);

        paint("face_frame")
            translate([0,face_frame_layout_y,0])
                face_frame_stile_print_part(
                    "left"
                );

        paint("face_frame")
            translate([sw+g,face_frame_layout_y,0])
                face_frame_stile_print_part(
                    "right"
                );

        if (face_frame_center_stile_enabled)
            paint("face_frame")
                translate([
                    2*(sw+g),
                    face_frame_layout_y,
                    0
                ])
                    linear_extrude(
                        height=effective_face_frame_thickness
                    )
                        face_frame_center_stile_cut();

        paint("face_frame")
            translate([rail_x,face_frame_layout_y,0])
                face_frame_top_rail_print_part();

        paint("face_frame")
            translate([
                rail_x,
                face_frame_layout_y
                    + effective_face_frame_top_rail_width
                    + g,
                0
            ])
                face_frame_bottom_rail_print_part();

        if (face_frame_mid_rail_active)
            paint("face_frame")
                translate([
                    rail_x,
                    face_frame_layout_y
                        + effective_face_frame_top_rail_width
                        + effective_face_frame_bottom_rail_width
                        + 2*g,
                    0
                ])
                    face_frame_mid_rail_print_part();
    }

    if (stack_base_active) {
        g = layout_gap;

        paint("stack_base_side")
            translate([
                0,
                stack_base_side_layout_y,
                0
            ])
                stack_base_side_rail_print_part();

        paint("stack_base_side")
            translate([
                resolved_cabinet_depth+g,
                stack_base_side_layout_y,
                0
            ])
                stack_base_side_rail_print_part();

        paint("stack_base_cross")
            translate([
                0,
                stack_base_cross_layout_y,
                0
            ])
                linear_extrude(height=material_thickness)
                    stack_base_cross_rail_cut();

        paint("stack_base_cross")
            translate([
                stack_base_cross_rail_cut_width()+g,
                stack_base_cross_layout_y,
                0
            ])
                linear_extrude(height=material_thickness)
                    stack_base_cross_rail_cut();
    }

}


// ---------------------------
// DADO / HARDWARE POCKET LAYOUT
// ---------------------------

module pocket_operation_layout(operation="combined") {
    shared_export_bounding_box_2d();

    // Preview-only side boundaries aid orientation for side-panel operations.
    if (operation == "combined"
        || operation == "carcass_dados"
        || operation == "shelf_pins"
        || operation == "ganging") {
        g = layout_gap;
        %square([resolved_cabinet_depth,cabinet_height]);
        translate([resolved_cabinet_depth+g,0])
            %square([resolved_cabinet_depth,cabinet_height]);
    }

    // Back-dado operation is machined on the REAR face of the segmented
    // face-frame strips. Preview the matching strip outlines for orientation.
    if (operation == "face_frame_dados"
        && face_frame_active) {
        g = layout_gap;
        sw = effective_face_frame_side_stile_width;
        rail_x =
            (
                face_frame_center_stile_enabled
                    ? 3
                    : 2
            )*(sw+g);

        translate([0,face_frame_layout_y])
            %face_frame_stile_cut();

        translate([sw+g,face_frame_layout_y])
            %face_frame_stile_cut();

        translate([rail_x,face_frame_layout_y])
            %face_frame_top_rail_cut();

        translate([
            rail_x,
            face_frame_layout_y
                + effective_face_frame_top_rail_width
                + g
        ])
            %face_frame_bottom_rail_cut();

        if (face_frame_mid_rail_active)
            translate([
                rail_x,
                face_frame_layout_y
                    + effective_face_frame_top_rail_width
                    + effective_face_frame_bottom_rail_width
                    + 2*g
            ])
                %face_frame_mid_rail_cut();
    }

    if (operation == "combined")
        blind_operation_geometry_2d();
    else if (operation == "carcass_dados")
        carcass_dado_operation_geometry_2d();
    else if (operation == "drawer_dados")
        drawer_dado_operation_geometry_2d();
    else if (operation == "bottom_grooves")
        drawer_bottom_operation_geometry_2d();
    else if (operation == "divider_bottom_grooves")
        drawer_divider_bottom_operation_geometry_2d();
    else if (operation == "divider_perimeter_grooves")
        drawer_divider_perimeter_operation_geometry_2d();
    else if (operation == "shelf_pins")
        shelf_pin_operation_geometry_2d();
    else if (operation == "hinge_cups")
        hinge_cup_operation_geometry_2d();
    else if (operation == "face_registration")
        face_registration_operation_geometry_2d();
    else if (operation == "base_hardware")
        base_hardware_operation_geometry_2d();
    else if (operation == "worktop_registration")
        worktop_registration_operation_geometry_2d();
    else if (operation == "face_frame_dados")
        face_frame_dado_operation_geometry_2d();
    else if (operation == "ganging")
        ganging_operation_geometry_2d();
}

module pocket_layout() {
    pocket_operation_layout("combined");
}

module pocket_carcass_dados_layout() {
    pocket_operation_layout("carcass_dados");
}

module pocket_drawer_dados_layout() {
    pocket_operation_layout("drawer_dados");
}

module pocket_bottom_grooves_layout() {
    pocket_operation_layout("bottom_grooves");
}

module pocket_divider_bottom_grooves_layout() {
    pocket_operation_layout("divider_bottom_grooves");
}

module pocket_divider_perimeter_grooves_layout() {
    pocket_operation_layout("divider_perimeter_grooves");
}

module pocket_shelf_pins_layout() {
    pocket_operation_layout("shelf_pins");
}

module pocket_hinge_cups_layout() {
    pocket_operation_layout("hinge_cups");
}

module pocket_face_registration_layout() {
    pocket_operation_layout("face_registration");
}

module pocket_base_hardware_layout() {
    pocket_operation_layout("base_hardware");
}

module pocket_worktop_registration_layout() {
    pocket_operation_layout("worktop_registration");
}

module pocket_face_frame_dados_layout() {
    pocket_operation_layout("face_frame_dados");
}

module pocket_ganging_layout() {
    pocket_operation_layout("ganging");
}


