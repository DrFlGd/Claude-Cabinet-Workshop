// Modular Organization Layouts — fork v3 / Configurator API V3.
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
                id,
                size=engraving_text_size(id,w,h),
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
    echo(
        str(
            "BOM|",
            id,"|1|",
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
            full_width_bottom_active ? "full_width" : joinery_style);

    if (top_style == "full")
        bom_row(id_top_full(),"carcass","CARCASS",
                material_thickness,joined_w,resolved_cabinet_depth,joinery_style);
    else {
        bom_row(id_top_front(),"carcass","CARCASS",
                material_thickness,joined_w,top_stretcher_depth,joinery_style);
        bom_row(id_top_rear(),"carcass","CARCASS",
                material_thickness,joined_w,top_stretcher_depth,joinery_style);
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
            str("captured_",joinery_style)
        );
    else if (back_style == "stretchers")
        for (bb=[0:back_stretcher_count-1])
            bom_row(id_back_stretcher(bb),"back_stretcher","CARCASS",
                    material_thickness,joined_w,back_stretcher_height,joinery_style);

    if (has_toe_kick)
        bom_row(id_toe_kick(),"toe_kick","CARCASS",
                material_thickness,joined_w,toe_kick_height,joinery_style);

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
            str("top_stack_notch;",joinery_style)
        );

        bom_row(
            id_stack_base_side("right"),
            "stack_base_side","CARCASS",
            material_thickness,
            resolved_cabinet_depth,
            stack_base_height,
            str("top_stack_notch;",joinery_style)
        );

        bom_row(
            id_stack_base_cross(true),
            "stack_base_cross","CARCASS",
            material_thickness,
            stack_base_cross_rail_cut_width(),
            stack_base_height,
            joinery_style
        );

        bom_row(
            id_stack_base_cross(false),
            "stack_base_cross","CARCASS",
            material_thickness,
            stack_base_cross_rail_cut_width(),
            stack_base_height,
            joinery_style
        );
    }

    // Legacy shelves.
    if (!mixed_bay_mode && has_doors && door_shelf_count > 0)
        for (s=[0:door_shelf_count-1])
            if (shelf_style == "fixed")
                bom_row(id_legacy_shelf(s),"shelf_fixed","CARCASS",
                        material_thickness,joined_w,shelf_depth,joinery_style);
            else
                for (bb=[0:door_adjustable_shelf_piece_count()-1])
                    bom_row(id_legacy_shelf(s,bb),"shelf_adjustable","CARCASS",
                            material_thickness,
                            door_adjustable_shelf_piece_width(bb),
                            shelf_depth,"loose");

    if (!mixed_bay_mode && cabinet_contents == "combo")
        bom_row(id_combo_divider(),"divider","CARCASS",
                material_thickness,joined_w,shelf_depth,joinery_style);

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
                            ? joinery_style
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
                joinery_style
            );

    if (door_hinge_partition_count() > 0)
        for (p=[0:door_hinge_partition_count()-1])
            bom_row(
                id_door_partition(p),
                "door_partition","CARCASS",
                material_thickness,
                door_hinge_partition_actual_depth,
                door_hinge_partition_cut_height(),
                joinery_style
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
                    joinery_style
                );
            else {
                bom_row(
                    id_drawer_separator(s,0),
                    "drawer_separator","CARCASS",
                    material_thickness,
                    joined_w,drawer_separator_stretcher_actual_depth,
                    joinery_style
                );
                bom_row(
                    id_drawer_separator(s,1),
                    "drawer_separator","CARCASS",
                    material_thickness,
                    joined_w,drawer_separator_stretcher_actual_depth,
                    joinery_style
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
                        drawer_joinery_style
                    );
                    bom_row(
                        id_drawer_side(bb,i,"right"),
                        "drawer_side","DRAWER_WALL",
                        drawer_material_thickness,
                        drawer_box_depth,bh,
                        drawer_joinery_style
                    );
                    bom_row(
                        id_drawer_cross(bb,i,true),
                        "drawer_front_box","DRAWER_WALL",
                        drawer_material_thickness,
                        drawer_cross_panel_width(bb),bh,
                        drawer_joinery_style
                    );
                    bom_row(
                        id_drawer_cross(bb,i,false),
                        "drawer_back_box","DRAWER_WALL",
                        drawer_material_thickness,
                        drawer_cross_panel_width(bb),bh,
                        drawer_joinery_style
                    );
                    bom_row(
                        id_drawer_bottom(bb,i),
                        "drawer_bottom","DRAWER_BOTTOM",
                        drawer_bottom_thickness,
                        drawer_bottom_width(bb),
                        drawer_bottom_depth(),
                        drawer_bottom_joinery
                    );
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
    joinery_style == "tab_slot"
    || joinery_style == "dado";

calibration_drawer_fit_active =
    has_drawers
    && (
        drawer_joinery_style == "tab_slot"
        || drawer_joinery_style == "dado"
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
        && joinery_style == "dado"
            ? effective_dado_depth()
            : 0,
        calibration_drawer_fit_active
        && drawer_joinery_style == "dado"
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
            && joinery_style == "tab_slot")
            calibration_coupon_through_slot_samples(
                calibration_carcass_row_index(),
                material_thickness,
                joint_fit_clearance,
                calibration_fit_offsets
            );

        if (calibration_drawer_fit_active
            && drawer_joinery_style == "tab_slot")
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
        && joinery_style == "dado")
        calibration_coupon_pocket_samples(
            calibration_carcass_row_index(),
            material_thickness,
            dado_fit_clearance,
            calibration_fit_offsets
        );

    if (calibration_drawer_fit_active
        && drawer_joinery_style == "dado")
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
            joinery_style == "tab_slot"
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
            joinery_style == "tab_slot"
                ? joint_fit_clearance
                : dado_fit_clearance,
            calibration_fit_offsets
        );
    }

    if (calibration_drawer_fit_active) {
        row = calibration_drawer_row_index();
        ry = calibration_coupon_row_y(row);

        calibration_coupon_left_text(
            drawer_joinery_style == "tab_slot"
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
            drawer_joinery_style == "tab_slot"
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

    if (joinery_style == "dado") {
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
        && joinery_style == "dado") {

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
        && joinery_style == "dado") {

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
        && joinery_style == "dado") {
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
        && joinery_style == "dado") {
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
        && joinery_style == "dado") {

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
        face_registration_operation_geometry_2d();
    }
    else {
        carcass_dado_operation_geometry_2d();
        drawer_dado_operation_geometry_2d();
        drawer_bottom_operation_geometry_2d();
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
                        drawer_side_print_part(d,bh,i);

                paint("drawer_side_r",pi)
                    translate([d+g,side_y,0])
                        drawer_side_print_part(d,bh,i);

                paint("drawer_box_front",pi)
                    translate([2*(d+g),side_y,0])
                        drawer_cross_panel_print_part(
                            bh,true,b);

                paint("drawer_box_back",pi)
                    translate([
                        2*(d+g),
                        side_y+bh+g,
                        0
                    ])
                        drawer_cross_panel_print_part(
                            bh,false,b);

                bottom_y = side_y+bh+2*g;

                paint("drawer_bottom",pi)
                    translate([0,bottom_y,0])
                        linear_extrude(height=drawer_bottom_thickness)
                            drawer_bottom_cut(b);
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
                        drawer_joinery_style
                    );
                    bom_row(
                        id_drawer_side(b,i,"right"),
                        "drawer_side","DRAWER_WALL",
                        drawer_material_thickness,
                        drawer_box_depth,bh,
                        drawer_joinery_style
                    );
                    bom_row(
                        id_drawer_cross(b,i,true),
                        "drawer_front_box","DRAWER_WALL",
                        drawer_material_thickness,
                        drawer_cross_panel_width(b),bh,
                        drawer_joinery_style
                    );
                    bom_row(
                        id_drawer_cross(b,i,false),
                        "drawer_back_box","DRAWER_WALL",
                        drawer_material_thickness,
                        drawer_cross_panel_width(b),bh,
                        drawer_joinery_style
                    );
                    bom_row(
                        id_drawer_bottom(b,i),
                        "drawer_bottom","DRAWER_BOTTOM",
                        drawer_bottom_thickness,
                        drawer_bottom_width(b),
                        drawer_bottom_depth(),
                        drawer_bottom_joinery
                    );
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

        if (joinery_style == "dado")
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

        if (joinery_style == "dado") {
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
            && joinery_style == "dado") {
            dd = door_hinge_partition_dado_depth();

            translate([
                0,0,
                material_thickness-dd
            ])
                linear_extrude(height=dd+0.02)
                    bottom_door_hinge_partition_receiver_dado_pockets_2d();
        }

        if (mixed_bay_partition_count() > 0
            && joinery_style == "dado") {
            dd = mixed_bay_partition_dado_depth();

            translate([
                0,0,
                material_thickness-dd
            ])
                linear_extrude(height=dd+0.02)
                    bottom_mixed_bay_partition_receiver_dado_pockets_2d();
        }

        if (structural_back_active
            && joinery_style == "dado") {
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
            && joinery_style == "dado") {
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
            && joinery_style == "dado") {
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
            && joinery_style == "dado") {
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
                        drawer_side_print_part(d,bh,i);

                paint("drawer_side_r",pi)
                    translate([d+g,side_y,0])
                        drawer_side_print_part(d,bh,i);

                paint("drawer_box_front",pi)
                    translate([2*(d+g),side_y,0])
                        drawer_cross_panel_print_part(
                            bh,true,b);

                paint("drawer_box_back",pi)
                    translate([
                        2*(d+g),
                        side_y+bh+g,
                        0
                    ])
                        drawer_cross_panel_print_part(
                            bh,false,b);

                bottom_y = side_y+bh+2*g;

                paint("drawer_bottom",pi)
                    translate([0,bottom_y,0])
                        linear_extrude(height=drawer_bottom_thickness)
                            drawer_bottom_cut(b);
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


if (output_mode == "assembly"
    || output_mode == "carcass_only"
    || output_mode == "drawers_only") {

    echo("Assembly visibility:");

    if (standalone_drawer_active) {
        echo("  enclosure reference = ",
             !is_undef(show_enclosure_reference)
                ? show_enclosure_reference
                : false);
        echo("  drawer box sides = ", show_drawer_box_sides);
        echo("  drawer box front/back = ", show_drawer_box_front_back);
        echo("  drawer bottoms = ", show_drawer_bottoms);
        echo("  drawer faces = ", show_drawer_faces);
        echo("  drawer slide parts = ", show_drawer_slide_parts);
    }
    else {
        echo("  carcass sides = ", show_carcass_sides);
        echo("  carcass bottom = ", show_carcass_bottom);
        echo("  carcass top = ", show_carcass_top);
        echo("  toe kick = ", show_toe_kick);
        echo("  base hardware = ", show_base_hardware);
        echo("  worktop = ", show_worktop);
        echo("  back construction = ", show_back_construction);
        echo("  combo divider = ", show_combo_divider);
        echo("  shelves = ", show_shelves);
        echo("  door hinge partitions = ", show_door_hinge_partitions);
        echo("  drawer separators = ", show_drawer_separators);
        echo("  drawer bank partitions = ", show_drawer_bank_partitions);
        echo("  mixed bay partitions = ", show_mixed_bay_partitions);
        echo("  drawer box sides = ", show_drawer_box_sides);
        echo("  drawer box front/back = ", show_drawer_box_front_back);
        echo("  drawer bottoms = ", show_drawer_bottoms);
        echo("  drawer faces = ", show_drawer_faces);
        echo("  drawer slide parts = ", show_drawer_slide_parts);
        echo("  doors = ", show_doors);
    }
}

// ---------------------------
// CONFIGURATOR API V2
// ---------------------------
//
// V26 intentionally separates recipe selection from geometry. Front ends now
// expose direct configuration values. Recipes are data applied by the UI (or
// by a user before invoking OpenSCAD), not hidden geometry modes.

echo("API|MODULAR_ORGANIZATION|VERSION=2|ENGINE=2|PARENT=MODULAR_STORAGE_V35");
echo("API_COMPAT|MODULAR_STORAGE|VERSION=1|PARENT_ENGINE=35");

sizing_width_active = width_basis == "drawer_inside";
sizing_depth_active = depth_basis == "drawer_inside";
sizing_any_active = sizing_width_active || sizing_depth_active;

sizing_achieved_drawer_inside_width =
    sizing_target_bank_valid
        ? drawer_inner_width(sizing_target_bank_index)
        : 0;

sizing_achieved_drawer_inside_depth =
    sizing_target_bank_valid
        ? drawer_inner_depth()
        : 0;

sizing_target_tolerance = 0.02;

if (sizing_any_active) {
    if (!sizing_has_drawers)
        echo(str(
            "ERROR|DRAWER_TARGET_NO_DRAWERS",
            "|WIDTH_BASIS=",width_basis,
            "|DEPTH_BASIS=",depth_basis
        ));

    if (target_drawer_bank < 1
        || target_drawer_bank > sizing_bank_count)
        echo(str(
            "WARN|DRAWER_TARGET_BANK_CLAMPED",
            "|REQUESTED=",target_drawer_bank,
            "|EFFECTIVE=",sizing_target_bank_index+1,
            "|BANK_COUNT=",sizing_bank_count
        ));

    if (
        sizing_mixed_mode
        && sizing_has_drawers
        && !sizing_mixed_bay_is_drawer(
            sizing_target_bank_index
        )
    )
        echo(str(
            "ERROR|DRAWER_TARGET_BANK_NOT_DRAWER",
            "|BANK=",sizing_target_bank_index+1,
            "|TYPE=",
                sizing_mixed_bay_type(
                    sizing_target_bank_index
                )
        ));

    if (
        sizing_target_bank_valid
        && sizing_width_active
        && (
            target_dimension_policy == "exact"
                ? abs(
                    sizing_achieved_drawer_inside_width
                    - sizing_requested_drawer_inside_width
                  ) > sizing_target_tolerance
                : sizing_achieved_drawer_inside_width
                  < sizing_requested_drawer_inside_width
                    - sizing_target_tolerance
        )
    )
        echo(str(
            "ERROR|DRAWER_TARGET_UNMET",
            "|AXIS=width",
            "|REQUESTED=",
                sizing_requested_drawer_inside_width,
            "|ACHIEVED=",
                sizing_achieved_drawer_inside_width,
            "|POLICY=",target_dimension_policy
        ));

    if (
        sizing_target_bank_valid
        && sizing_depth_active
        && (
            target_dimension_policy == "exact"
                ? abs(
                    sizing_achieved_drawer_inside_depth
                    - sizing_requested_drawer_inside_depth
                  ) > sizing_target_tolerance
                : sizing_achieved_drawer_inside_depth
                  < sizing_requested_drawer_inside_depth
                    - sizing_target_tolerance
        )
    )
        echo(str(
            "ERROR|DRAWER_TARGET_UNMET",
            "|AXIS=depth",
            "|REQUESTED=",
                sizing_requested_drawer_inside_depth,
            "|ACHIEVED=",
                sizing_achieved_drawer_inside_depth,
            "|POLICY=",target_dimension_policy
        ));

    echo(str(
        "TARGET|DRAWER_INSIDE",
        "|BANK=",sizing_target_bank_index+1,
        "|MODE=",target_dimension_mode,
        "|POLICY=",target_dimension_policy,
        "|WIDTH_ACTIVE=",sizing_width_active,
        "|DEPTH_ACTIVE=",sizing_depth_active,
        "|REQUESTED_W=",
            sizing_requested_drawer_inside_width,
        "|ACHIEVED_W=",
            sizing_target_bank_valid
                ? sizing_achieved_drawer_inside_width
                : 0,
        "|REQUESTED_D=",
            sizing_requested_drawer_inside_depth,
        "|ACHIEVED_D=",
            sizing_target_bank_valid
                ? sizing_achieved_drawer_inside_depth
                : 0,
        "|CONFIGURED_CABINET_W=",cabinet_width,
        "|RESOLVED_CABINET_W=",resolved_cabinet_width,
        "|CONFIGURED_CARCASS_D=",cabinet_depth,
        "|RESOLVED_CARCASS_D=",resolved_cabinet_depth,
        "|RESOLVED_FINISHED_D=",cabinet_finished_depth
    ));

    if (sizing_modular_mode)
        echo(str(
            "INFO|MODULAR_TARGET",
            "|PITCH_X=",target_module_pitch_x,
            "|COUNT_X=",round(target_module_count_x),
            "|EDGE_CLEAR_X=",target_module_edge_clearance_x,
            "|PITCH_Y=",target_module_pitch_y,
            "|COUNT_Y=",round(target_module_count_y),
            "|EDGE_CLEAR_Y=",target_module_edge_clearance_y
        ));
}

// ---------------------------
// MODULAR ORGANIZATION SYSTEM CONTRACT REPORT
// ---------------------------
// These records are intentionally independent from DIM/BOM.  A project-level
// configurator can compare interface compatibility keys and visualize owned
// keepout regions without reverse-engineering finished vectors.
if (organization_system_report_enabled()) {
    echo(str(
        "SYSTEM|ENGINE|FAMILY=",organization_engine_family,
        "|VERSION=",organization_engine_version,
        "|PARENT=",organization_parent_engine,
        "|CONTRACT=",organization_interface_contract
    ));

    echo(str(
        "MODULE|KIND=",organization_module_kind(),
        "|W=",organization_module_width(),
        "|D=",organization_module_depth(),
        "|H=",organization_module_height(),
        "|COORD=front-left-bottom"
    ));

    echo(str(
        "COMPAT|CONTRACT=",organization_interface_contract,
        "|KEY_SCHEMA=2",
        "|STACK_STANDARD=MOI-STACK-1",
        "|GANG_STANDARD=MOI-GANG-1",
        "|JOINT_STANDARD=MOI-JOINT-1",
        "|DRAWER_STANDARD=MOI-DRAWER-1"
    ));

    echo(str(
        "COVERAGE|DOMAIN=external_interface_compatibility",
        "|STATUS=exhaustive",
        "|KEY_SCHEMA=2",
        "|NOTE=All geometry-driving fields for current MOI-STACK-1 and MOI-GANG-1 standards are signed"
    ));

    echo(str(
        "COVERAGE|DOMAIN=side_panel_machining",
        "|STATUS=exhaustive",
        "|FEATURES=",len(organization_features()),
        "|FAMILIES=",organization_side_feature_family_count(),
        "|NOTE=All current outer-side holes blind pockets and carcass joints are in the common collision ledger"
    ));

    echo(str(
        "COVERAGE|DOMAIN=whole_model_manufacturing_geometry",
        "|STATUS=requires_geometry_audit",
        "|NOTE=Use modular_organization_validate.py or the manufacturing exporter for exhaustive CUT/POCKET contour analysis"
    ));

    if (include_shared_export_bounding_box) {
        m = max(0,export_bounding_box_margin);
        fw = max(0.01,export_bounding_box_frame_width);
        echo(str(
            "EXPORT_FRAME|X0=",-m,"|Y0=",-m,
            "|X1=",export_layout_content_width+m,
            "|Y1=",export_layout_content_height+m,
            "|FW=",fw
        ));
    }

    for (r=organization_interfaces())
        echo(str(
            "INTERFACE|ID=",mo_interface_id(r),
            "|STANDARD=",mo_interface_standard(r),
            "|KIND=",mo_interface_kind(r),
            "|ROLE=",mo_interface_role(r),
            "|OWNER=",mo_interface_owner(r),
            "|FACE=",mo_interface_face(r),
            "|MATE=",mo_interface_mate(r),
            "|DATUM=",mo_interface_datum(r),
            "|KEY=",mo_interface_key(r),
            "|TAGS=",mo_interface_tags(r)
        ));

    for (fr=organization_interface_frames())
        echo(str(
            "INTERFACE_FRAME|ID=",fr[MO_FR_ID],
            "|OX=",fr[MO_FR_OX],"|OY=",fr[MO_FR_OY],"|OZ=",fr[MO_FR_OZ],
            "|UX=",fr[MO_FR_UX],"|UY=",fr[MO_FR_UY],"|UZ=",fr[MO_FR_UZ],
            "|VX=",fr[MO_FR_VX],"|VY=",fr[MO_FR_VY],"|VZ=",fr[MO_FR_VZ],
            "|NX=",fr[MO_FR_NX],"|NY=",fr[MO_FR_NY],"|NZ=",fr[MO_FR_NZ]
        ));

    for (k=organization_keepouts())
        echo(str(
            "KEEPOUT|ID=",k[MO_KO_ID],
            "|OWNER=",k[MO_KO_OWNER],
            "|SCOPE=",k[MO_KO_SCOPE],
            "|X0=",k[MO_KO_X0],"|X1=",k[MO_KO_X1],
            "|Y0=",k[MO_KO_Y0],"|Y1=",k[MO_KO_Y1],
            "|Z0=",k[MO_KO_Z0],"|Z1=",k[MO_KO_Z1],
            "|REASON=",k[MO_KO_REASON]
        ));

    if (organization_system_report_verbose()) {
        for (o=organization_feature_owner_classes())
            echo(str(
                "FEATURE_OWNER|CLASS=",o[0],
                "|INTERFACE=",o[1]
            ));

        for (f=organization_features())
            echo(str(
                "FEATURE|ID=",f[MO_F_ID],
                "|PART=",f[MO_F_PART],
                "|KIND=",f[MO_F_KIND],
                "|INTERFACE=",f[MO_F_INTERFACE],
                "|X0=",f[MO_F_X0],"|X1=",f[MO_F_X1],
                "|Y0=",f[MO_F_Y0],"|Y1=",f[MO_F_Y1],
                "|Z0=",f[MO_F_Z0],"|Z1=",f[MO_F_Z1],
                "|SHAPE=",f[MO_F_SHAPE],
                "|CY=",f[MO_F_CY],"|CZ=",f[MO_F_CZ],
                "|R=",f[MO_F_RADIUS],
                "|OP=",f[MO_F_OPERATION],
                "|SOURCE=",f[MO_F_SOURCE]
            ));
    }
}

// Machine-readable validation messages. Human-readable guidance below remains
// for OpenSCAD users; web clients can key off ERROR| / WARN| records.
if (resolved_cabinet_width <= 2*material_thickness)
    echo(str("ERROR|ENVELOPE_WIDTH_TOO_SMALL|W=",resolved_cabinet_width,"|CARCASS_T=",material_thickness));

if (cabinet_height <= 2*material_thickness)
    echo(str("ERROR|ENVELOPE_HEIGHT_TOO_SMALL|H=",cabinet_height,"|CARCASS_T=",material_thickness));

if (resolved_cabinet_depth <= material_thickness)
    echo(str("ERROR|ENVELOPE_DEPTH_TOO_SMALL|D=",resolved_cabinet_depth,"|CARCASS_T=",material_thickness));

if (active_cabinet_layout_mode == "mixed_bays"
    && len(active_mixed_bay_types) < active_mixed_bay_count)
    echo(str("ERROR|MIXED_BAY_TYPES_SHORT|COUNT=",active_mixed_bay_count,"|VALUES=",len(active_mixed_bay_types)));

if (active_cabinet_layout_mode == "mixed_bays"
    && len(active_mixed_bay_width_weights) < active_mixed_bay_count)
    echo(str("ERROR|MIXED_BAY_WEIGHTS_SHORT|COUNT=",active_mixed_bay_count,"|VALUES=",len(active_mixed_bay_width_weights)));

if (fronts_inset_flush && front_edge_reveal < 0.5)
    echo(str("WARN|INSET_REVEAL_SMALL|REVEAL=",front_edge_reveal));

if (face_frame_active && has_doors && effective_hinge_style != "none")
    echo(str("WARN|FACE_FRAME_HINGE_VERIFY|STYLE=",effective_hinge_style));

if (ganging_active) {
    if (ganging_dowel_active
        && effective_ganging_dowel_depth
           < ganging_dowel_depth)
        echo(str(
            "WARN|GANGING_DOWEL_DEPTH_CLAMPED",
            "|REQUESTED=",ganging_dowel_depth,
            "|EFFECTIVE=",effective_ganging_dowel_depth,
            "|CARCASS_T=",material_thickness
        ));

    if (!ganging_has_rear_column)
        echo(str(
            "WARN|GANGING_REAR_COLUMN_COLLAPSED",
            "|D=",resolved_cabinet_depth,
            "|FRONT_Y=",ganging_front_y,
            "|REAR_Y=",ganging_rear_y
        ));

    if (effective_ganging_station_count
        < requested_ganging_station_count)
        echo(str(
            "WARN|GANGING_STATION_COUNT_REDUCED",
            "|REQUESTED=",requested_ganging_station_count,
            "|EFFECTIVE=",effective_ganging_station_count,
            "|H=",cabinet_height
        ));

    // Preserve the canonical coordinates. Do not silently shift one side based
    // on interior hardware, because that would break pair registration.
    for (side=["left","right"])
        if (ganging_side_active(side))
            for (c=[0:effective_ganging_column_count-1])
                for (s=[0:effective_ganging_station_count-1]) {
                    if (
                        ganging_connector_active
                        && ganging_point_conflicts(
                            ganging_column_y(c),
                            ganging_connector_z(s),
                            side,
                            false
                        )
                    )
                        echo(str(
                            "WARN|GANGING_CONFLICT",
                            "|SIDE=",side,
                            "|COLUMN=",ganging_column_name(c),
                            "|STATION=",s+1,
                            "|FEATURE=connector",
                            "|Y=",ganging_column_y(c),
                            "|Z=",ganging_connector_z(s)
                        ));

                    if (
                        ganging_dowel_active
                        && ganging_point_conflicts(
                            ganging_column_y(c),
                            ganging_dowel_z(s),
                            side,
                            true
                        )
                    )
                        echo(str(
                            "WARN|GANGING_CONFLICT",
                            "|SIDE=",side,
                            "|COLUMN=",ganging_column_name(c),
                            "|STATION=",s+1,
                            "|FEATURE=dowel",
                            "|Y=",ganging_column_y(c),
                            "|Z=",ganging_dowel_z(s)
                        ));
                }

    echo(str(
        "INFO|GANGING_CANONICAL_PATTERN",
        "|DEPTH_MATCH_REQUIRED_FOR_REAR_COLUMN=true",
        "|HEIGHT_MATCH_RECOMMENDED=true",
        "|AUTO_RELOCATION=false"
    ));
}

if (!is_undef(design_type))
    echo(str("CONFIG|DESIGN_TYPE|",design_type));

if (!is_undef(design_name))
    echo(str("CONFIG|DESIGN_NAME|",design_name));

if (standalone_drawer_active) {
    echo(str(
        "TARGET|DRAWER_DESIGN",
        "|BASIS=",drawer_design_basis,
        "|HEIGHT_MODE=",enclosure_height_mode,
        "|MOUNT=",drawer_mount,
        "|FACE_STYLE=",drawer_face_style,
        "|OUTSIDE_W=",drawer_outer_width(0),
        "|OUTSIDE_D=",drawer_box_depth,
        "|OUTSIDE_H=",drawer_box_height(0,0),
        "|INSIDE_W=",drawer_inner_width(0),
        "|INSIDE_D=",drawer_inner_depth(),
        "|INSIDE_H=",drawer_inside_clear_height(0,0)
    ));

    if (
        drawer_design_basis == "enclosure"
        && enclosure_opening_width
           <= 2*standalone_mount_side_clearance
    )
        echo(str(
            "ERROR|DRAWER_STANDALONE_INVALID",
            "|AXIS=width",
            "|REASON=opening_too_narrow_for_mount",
            "|OPEN_W=",enclosure_opening_width,
            "|REQUIRED_SIDE_CLEAR=",
                standalone_mount_side_clearance
        ));

    if (
        drawer_design_basis == "enclosure"
        && enclosure_usable_depth
           <= standalone_effective_front_setback
              + drawer_back_clearance
    )
        echo(str(
            "ERROR|DRAWER_STANDALONE_INVALID",
            "|AXIS=depth",
            "|REASON=opening_too_shallow",
            "|OPEN_D=",enclosure_usable_depth,
            "|FRONT_SETBACK=",
                standalone_effective_front_setback,
            "|REAR_CLEAR=",drawer_back_clearance
        ));

    if (standalone_drawer_outer_width <= 0)
        echo("ERROR|DRAWER_STANDALONE_INVALID|AXIS=width|REASON=nonpositive_box");

    if (standalone_drawer_box_depth <= 0)
        echo("ERROR|DRAWER_STANDALONE_INVALID|AXIS=depth|REASON=nonpositive_box");

    if (standalone_drawer_box_height <= 0)
        echo("ERROR|DRAWER_STANDALONE_INVALID|AXIS=height|REASON=nonpositive_box");

    if (
        drawer_design_basis == "enclosure"
        && standalone_drawer_box_height
           > standalone_enclosure_opening_height+0.01
    )
        echo(str(
            "ERROR|DRAWER_STANDALONE_INVALID",
            "|AXIS=height",
            "|REASON=box_exceeds_opening",
            "|BOX_H=",standalone_drawer_box_height,
            "|OPEN_H=",standalone_enclosure_opening_height
        ));

    if (
        drawer_mount == "metal_slides"
        && effective_metal_slide_length > 0
        && drawer_box_depth > effective_metal_slide_length+25
    )
        echo(str(
            "WARN|DRAWER_SLIDE_LENGTH_MISMATCH",
            "|BOX_D=",drawer_box_depth,
            "|SLIDE_LENGTH=",effective_metal_slide_length
        ));

    if (drawer_design_basis == "modular_grid")
        echo(str(
            "INFO|MODULAR_TARGET",
            "|PITCH_X=",drawer_module_pitch_x,
            "|COUNT_X=",round(drawer_module_count_x),
            "|EDGE_CLEAR_X=",drawer_module_edge_clearance_x,
            "|PITCH_Y=",drawer_module_pitch_y,
            "|COUNT_Y=",round(drawer_module_count_y),
            "|EDGE_CLEAR_Y=",drawer_module_edge_clearance_y,
            "|INSIDE_H=",drawer_module_inside_height
        ));
}

// ---------------------------
// STRUCTURED DIMENSION REPORT
// ---------------------------
//
// Every machine-readable line starts with DIM| and uses millimeters.
// This reports FINISHED / ASSEMBLED geometry in addition to flat-part cut
// dimensions already available from BOM and manufacturing layouts.

module echo_dimension_report() {
    if (standalone_drawer_active && dimension_report != "off") {
        echo("========== DIMENSION REPORT ==========");
        echo("DIM|UNITS|mm");

        echo(str(
            "DIM|ENCLOSURE|OPENING",
            "|ROLE=",drawer_design_basis == "enclosure" ? "measured" : "required",
            "|W=",standalone_enclosure_opening_width,
            "|D=",standalone_enclosure_usable_depth,
            "|H=",standalone_enclosure_opening_height
        ));

        echo(str(
            "DIM|DRAWER|D1|OUTSIDE",
            "|W=",drawer_outer_width(0),
            "|D=",drawer_box_depth,
            "|H=",drawer_box_height(0,0)
        ));

        echo(str(
            "DIM|DRAWER|D1|INSIDE_CLEAR",
            "|W=",drawer_inner_width(0),
            "|D=",drawer_inner_depth(),
            "|H=",drawer_inside_clear_height(0,0)
        ));

        echo(str(
            "DIM|DRAWER|D1|OPENING",
            "|W=",drawer_bank_opening_width(0),
            "|D=",standalone_enclosure_usable_depth,
            "|H=",drawer_opening_height(0,0),
            "|SIDE_CLEAR_PER_SIDE=",drawer_side_clearance_per_side(0),
            "|VERT_CLEAR_PER_SIDE=",drawer_vertical_clearance_per_side(0),
            "|FRONT_SETBACK=",effective_drawer_front_setback,
            "|REAR_CLEARANCE=",drawer_back_clearance
        ));

        echo(str(
            "DIM|MATERIALS",
            "|DRAWER_WALL_T=",drawer_material_thickness,
            "|DRAWER_BOTTOM_T=",drawer_bottom_thickness,
            "|DRAWER_FACE_T=",drawer_front_thickness
        ));

        if (include_drawer_faces)
            echo(str(
                "DIM|DRAWER_FACE|D1-FACE",
                "|W=",drawer_face_width(0),
                "|H=",drawer_face_height_for(0,0),
                "|T=",drawer_front_thickness,
                "|MOUNT=",
                    fronts_inset_flush ? "inset_flush" : "overlay"
            ));

        if (dimension_report == "full")
            echo(str(
                "DIM|DRAWER_BOTTOM|D1-BOT",
                "|CUT_W=",drawer_bottom_width(0),
                "|CUT_D=",drawer_bottom_depth(),
                "|T=",drawer_bottom_thickness,
                "|FLOOR_TOP_Z_IN_BOX=",
                    drawer_bottom_inset+drawer_bottom_thickness
            ));

        echo("========== END DIMENSION REPORT ==========");
    }
    else if (dimension_report != "off") {
        echo("========== DIMENSION REPORT ==========");
        echo("DIM|UNITS|mm");

        echo(str(
            "DIM|CABINET|OUTSIDE",
            "|W=",resolved_cabinet_width,
            "|D=",cabinet_finished_depth,
            "|H=",cabinet_height
        ));

        echo(str(
            "DIM|CABINET|CLEAR_INTERIOR",
            "|W=",cabinet_clear_width(),
            "|D=",cabinet_clear_depth(),
            "|H=",cabinet_clear_height()
        ));

        echo(str(
            "DIM|CABINET|FRONT_OPENING",
            "|W=",inner_width,
            "|H=",cabinet_clear_height(),
            "|BOTTOM_Z=",front_opening_bottom_z,
            "|TOP_Z=",front_opening_top_z
        ));

        if (!is_undef(kitchen_model_code))
            echo(str(
                "DIM|KITCHEN",
                "|MODEL=",kitchen_model_code,
                "|FAMILY=",kitchen_family,
                "|NOMINAL_W_IN=",resolved_cabinet_width/25.4,
                "|NOMINAL_D_IN=",cabinet_finished_depth/25.4,
                "|NOMINAL_H_IN=",cabinet_height/25.4
            ));

        echo(str(
            "DIM|MATERIALS",
            "|CARCASS_T=",material_thickness,
            "|BACK_T=",
                back_style == "structural_panel"
                    ? material_thickness
                    : back_thickness,
            "|DRAWER_WALL_T=",drawer_material_thickness,
            "|DRAWER_BOTTOM_T=",drawer_bottom_thickness,
            "|DRAWER_FACE_T=",drawer_front_thickness,
            "|DOOR_T=",door_thickness
        ));

        if (face_frame_active)
            echo(str(
                "DIM|FACE_FRAME",
                "|W=",resolved_cabinet_width,
                "|H=",face_frame_height,
                "|T=",effective_face_frame_thickness,
                "|SIDE_STILE_W=",
                    effective_face_frame_side_stile_width,
                "|TOP_RAIL_W=",
                    effective_face_frame_top_rail_width,
                "|BOTTOM_RAIL_W=",
                    effective_face_frame_bottom_rail_width,
                "|CLEAR_OPEN_W=",face_frame_clear_width,
                "|CLEAR_OPEN_H=",face_frame_clear_height,
                "|OVERLAY=",effective_face_frame_overlay,
                "|CONSTRUCTION=",
                    face_frame_construction_resolved,
                "|BACK_DADO_DEPTH=",
                    effective_face_frame_back_dado_depth,
                "|BACK_DADO_CLEAR=",
                    effective_face_frame_back_dado_clearance,
                "|PROJECTION=",
                    face_frame_projection,
                "|MID_RAIL=",
                    face_frame_mid_rail_active
                        ? effective_face_frame_mid_rail_width
                        : 0
            ));

        if (ganging_active) {
            echo(str(
                "DIM|GANGING",
                "|STYLE=",ganging_style,
                "|SIDES=",ganging_sides,
                "|VERTICAL_PATTERN=",ganging_vertical_pattern,
                "|COLUMNS=",effective_ganging_column_count,
                "|STATIONS=",effective_ganging_station_count,
                "|FRONT_Y=",ganging_front_y,
                "|REAR_Y=",
                    ganging_has_rear_column
                        ? ganging_rear_y
                        : 0,
                "|DOWEL_D=",
                    ganging_dowel_active
                        ? effective_ganging_dowel_diameter
                        : 0,
                "|DOWEL_DEPTH=",
                    ganging_dowel_active
                        ? effective_ganging_dowel_depth
                        : 0,
                "|CONNECTOR_D=",
                    ganging_connector_active
                        ? effective_ganging_connector_hole_diameter
                        : 0
            ));

            if (dimension_report == "full")
                for (side=["left","right"])
                    if (ganging_side_active(side))
                        for (c=[0:effective_ganging_column_count-1])
                            for (s=[0:effective_ganging_station_count-1]) {
                                if (ganging_dowel_active)
                                    echo(str(
                                        "DIM|GANGING_POINT",
                                        "|ID=GANG-",
                                            side == "left" ? "L" : "R",
                                            "-",
                                            c == 0 ? "F" : "R",
                                            s+1,
                                            "-DOWEL",
                                        "|SIDE=",side,
                                        "|COLUMN=",ganging_column_name(c),
                                        "|STATION=",s+1,
                                        "|TYPE=dowel",
                                        "|Y=",ganging_column_y(c),
                                        "|Z=",ganging_dowel_z(s),
                                        "|D=",effective_ganging_dowel_diameter,
                                        "|DEPTH=",effective_ganging_dowel_depth
                                    ));

                                if (ganging_connector_active)
                                    echo(str(
                                        "DIM|GANGING_POINT",
                                        "|ID=GANG-",
                                            side == "left" ? "L" : "R",
                                            "-",
                                            c == 0 ? "F" : "R",
                                            s+1,
                                            "-CONN",
                                        "|SIDE=",side,
                                        "|COLUMN=",ganging_column_name(c),
                                        "|STATION=",s+1,
                                        "|TYPE=connector",
                                        "|Y=",ganging_column_y(c),
                                        "|Z=",ganging_connector_z(s),
                                        "|D=",effective_ganging_connector_hole_diameter,
                                        "|DEPTH=through"
                                    ));
                            }
        }

        echo(str(
            "DIM|FRONTS",
            "|MOUNT=",
                fronts_inset_flush
                    ? "inset_flush"
                    : "overlay",
            "|EDGE_REVEAL=",front_edge_reveal,
            "|DRAWER_GAP=",drawer_gap,
            "|DOOR_GAP=",door_gap,
            "|INTERIOR_SETBACK=",inset_front_interior_depth
        ));

        if (worktop_active)
            echo(str(
                "DIM|WORKTOP|",id_worktop(),
                "|W=",worktop_width,
                "|D=",worktop_depth,
                "|T=",worktop_thickness,
                "|SIDE_OVERHANG=",worktop_side_overhang,
                "|FRONT_OVERHANG=",worktop_front_overhang,
                "|BACK_OVERHANG=",worktop_back_overhang
            ));

        if (base_mounting_plate_active)
            echo(str(
                "DIM|BASE_MOUNTING_PLATE",
                "|W=",base_mounting_plate_width,
                "|D=",base_mounting_plate_depth,
                "|T=",material_thickness
            ));

        if (stackable_mode)
            echo(str(
                "DIM|STACKABLE",
                "|MODULE_PITCH=",stack_module_pitch,
                "|INTERFACE_DEPTH=",effective_stack_interface_depth,
                "|BASE_H=",stack_base_active ? stack_base_height : 0,
                "|PREVIEW_TOTAL_H=",stack_preview_total_height
            ));

        // Major compartment openings.
        if (mixed_bay_mode) {
            for (b=[0:active_mixed_bay_count-1])
                echo(str(
                    "DIM|BAY|B",b+1,
                    "|TYPE=",mixed_bay_type_normalized(b),
                    "|OPEN_W=",mixed_bay_opening_width(b),
                    "|CLEAR_D=",cabinet_clear_depth(),
                    "|CLEAR_H=",mixed_bay_clear_height(b)
                ));
        }
        else {
            if (has_drawers)
                for (b=[0:active_drawer_bank_count()-1])
                    if (drawer_bank_drawer_count(b) > 0)
                        echo(str(
                            "DIM|DRAWER_BANK|B",b+1,
                            "|OPEN_W=",drawer_bank_opening_width(b),
                            "|DRAWERS=",drawer_bank_drawer_count(b),
                            "|BOX_D=",drawer_box_depth,
                            "|SIDE_CLEAR_PER_SIDE=",
                                drawer_side_clearance_per_side(b),
                            "|VERT_CLEAR_PER_SIDE=",
                                drawer_vertical_clearance_per_side(b)
                        ));

            if (has_doors)
                echo(str(
                    "DIM|DOOR_REGION",
                    "|W=",inner_width,
                    "|D=",cabinet_clear_depth(),
                    "|H=",door_region_height
                ));
        }

        if (dimension_report == "full") {
            // Finished drawer boxes, storage volume, faces, and bottoms.
            if (has_drawers)
                for (b=[0:active_drawer_bank_count()-1])
                    if (drawer_bank_drawer_count(b) > 0) {
                        echo(str(
                            "DIM|DRAWER_BANK|B",b+1,
                            "|OPEN_W=",drawer_bank_opening_width(b),
                            "|BOX_OUTER_W=",drawer_outer_width(b),
                            "|BOX_OUTER_D=",drawer_box_depth,
                            "|BOX_INNER_W=",drawer_inner_width(b),
                            "|BOX_INNER_D=",drawer_inner_depth(),
                            "|SIDE_CLEAR_PER_SIDE=",
                                drawer_side_clearance_per_side(b)
                        ));

                        for (i=[0:drawer_bank_drawer_count(b)-1]) {
                            prefix = id_drawer_prefix(b,i);

                            echo(str(
                                "DIM|DRAWER|",prefix,
                                "|OUTSIDE",
                                "|W=",drawer_outer_width(b),
                                "|D=",drawer_box_depth,
                                "|H=",drawer_box_height(i,b)
                            ));

                            echo(str(
                                "DIM|DRAWER|",prefix,
                                "|INSIDE_CLEAR",
                                "|W=",drawer_inner_width(b),
                                "|D=",drawer_inner_depth(),
                                "|H=",drawer_inside_clear_height(i,b)
                            ));

                            echo(str(
                                "DIM|DRAWER|",prefix,
                                "|OPENING",
                                "|W=",drawer_bank_opening_width(b),
                                "|H=",drawer_opening_height(i,b),
                                "|SIDE_CLEAR_PER_SIDE=",
                                    drawer_side_clearance_per_side(b),
                                "|VERT_CLEAR_PER_SIDE=",
                                    drawer_vertical_clearance_per_side(b)
                            ));

                            if (include_drawer_faces)
                                echo(str(
                                    "DIM|DRAWER_FACE|",
                                    id_drawer_face(b,i),
                                    "|W=",drawer_face_width(b),
                                    "|H=",drawer_face_height_for(i,b),
                                    "|T=",drawer_front_thickness,
                                    "|MOUNT=",
                                        fronts_inset_flush
                                            ? "inset_flush"
                                            : "overlay"
                                ));

                            echo(str(
                                "DIM|DRAWER_BOTTOM|",
                                id_drawer_bottom(b,i),
                                "|CUT_W=",drawer_bottom_width(b),
                                "|CUT_D=",drawer_bottom_depth(),
                                "|T=",drawer_bottom_thickness,
                                "|FLOOR_TOP_Z_IN_BOX=",
                                    drawer_bottom_inset
                                    + drawer_bottom_thickness
                            ));
                        }
                    }

            // Finished door dimensions.
            if (has_doors) {
                if (mixed_bay_mode) {
                    for (b=[0:active_mixed_bay_count-1])
                        if (mixed_bay_is_type(b,"door"))
                            for (leaf=[0:mixed_bay_door_count(b)-1])
                                echo(str(
                                    "DIM|DOOR|",
                                    id_mixed_door(b,leaf),
                                    "|W=",mixed_bay_door_leaf_width(b),
                                    "|H=",door_face_height,
                                    "|T=",door_thickness,
                                    "|MOUNT=",
                                        fronts_inset_flush
                                            ? "inset_flush"
                                            : "overlay",
                                    "|HINGE=",
                                        mixed_bay_door_leaf_hinge_side(
                                            b,leaf)
                                ));
                }
                else {
                    for (i=[0:door_count-1])
                        echo(str(
                            "DIM|DOOR|",id_legacy_door(i),
                            "|W=",door_each_width(i),
                            "|H=",door_face_height,
                            "|T=",door_thickness,
                            "|MOUNT=",
                                fronts_inset_flush
                                    ? "inset_flush"
                                    : "overlay",
                            "|HINGE=",door_hinge_side(i)
                        ));
                }
            }

            // Shelf finished/cut dimensions.
            if (show_shelves) {
                if (mixed_bay_mode) {
                    for (b=[0:active_mixed_bay_count-1])
                        if (mixed_bay_is_shelfable(b)
                            && mixed_bay_shelf_count(b) > 0)
                            for (si=[1:mixed_bay_shelf_count(b)]) {
                                fixed =
                                    mixed_bay_shelf_style(b) == "fixed";

                                echo(str(
                                    "DIM|SHELF|",
                                    id_mixed_shelf(b,si),
                                    "|STYLE=",
                                        fixed ? "fixed" : "adjustable",
                                    "|CLEAR_SPAN_W=",
                                        mixed_bay_opening_width(b),
                                    "|CUT_W=",
                                        fixed
                                            ? mixed_bay_fixed_shelf_cut_width(b)
                                            : mixed_bay_adjustable_shelf_width(b),
                                    "|D=",shelf_depth,
                                    "|T=",material_thickness
                                ));
                            }
                }
                else if (has_doors && door_shelf_count > 0) {
                    if (shelf_style == "fixed") {
                        for (si=[0:door_shelf_count-1])
                            echo(str(
                                "DIM|SHELF|",id_legacy_shelf(si),
                                "|STYLE=fixed",
                                "|CUT_W=",joined_w,
                                "|D=",shelf_depth,
                                "|T=",material_thickness
                            ));
                    }
                    else {
                        for (si=[0:door_shelf_count-1])
                            for (sp=[0:door_adjustable_shelf_piece_count()-1])
                                echo(str(
                                    "DIM|SHELF|",
                                    id_legacy_shelf(si,sp),
                                    "|STYLE=adjustable",
                                    "|CUT_W=",
                                        door_adjustable_shelf_piece_width(sp),
                                    "|D=",shelf_depth,
                                    "|T=",material_thickness
                                ));
                    }
                }
            }
        }

        echo("========== END DIMENSION REPORT ==========");
    }
}


echo_dimension_report();

if (!is_undef(kitchen_model_code)) {
    echo("Kitchen catalog:");
    echo("  model code = ", kitchen_model_code);
    echo("  family = ", kitchen_family);
    echo("  nominal width = ",
         resolved_cabinet_width/25.4, " in");
    echo("  nominal depth = ",
         cabinet_finished_depth/25.4, " in");
    echo("  nominal height = ",
         cabinet_height/25.4, " in");
}

if (sizing_any_active) {
    echo("Fit-target sizing:");
    echo("  mode = ", target_dimension_mode);
    echo("  policy = ", target_dimension_policy);
    echo("  target bank / bay slot = ",
         sizing_target_bank_index+1);

    if (sizing_width_active)
        echo("  requested drawer inside width = ",
             sizing_requested_drawer_inside_width,
             " mm; achieved = ",
             sizing_achieved_drawer_inside_width,
             " mm");

    if (sizing_depth_active)
        echo("  requested drawer inside depth = ",
             sizing_requested_drawer_inside_depth,
             " mm; achieved = ",
             sizing_achieved_drawer_inside_depth,
             " mm");

    echo("  configured outside/carcase W x D = ",
         cabinet_width, " x ", cabinet_depth, " mm");
    echo("  resolved outside/carcase W x D = ",
         resolved_cabinet_width, " x ",
         resolved_cabinet_depth, " mm");

    if (sizing_modular_mode)
        echo("  modular target = ",
             round(target_module_count_x), " x ",
             round(target_module_count_y),
             " @ ",
             target_module_pitch_x, " x ",
             target_module_pitch_y,
             " mm pitch");
}

if (standalone_drawer_active) {
    echo("Standalone drawer:");
    echo("  design basis = ", drawer_design_basis);
    echo("  enclosure / required opening = ",
         standalone_enclosure_opening_width, " x ",
         standalone_enclosure_opening_height, " x ",
         standalone_enclosure_usable_depth, " mm");
    echo("  drawer outside = ",
         drawer_outer_width(0), " x ",
         drawer_box_height(0,0), " x ",
         drawer_box_depth, " mm");
    echo("  drawer inside clear = ",
         drawer_inner_width(0), " x ",
         drawer_inside_clear_height(0,0), " x ",
         drawer_inner_depth(), " mm");
    echo("  mount = ", drawer_mount);
    echo("  side clearance per side = ",
         drawer_side_clearance_per_side(0), " mm");
    echo("  vertical clearance per side = ",
         drawer_vertical_clearance_per_side(0), " mm");
    echo("  front setback / rear clearance = ",
         effective_drawer_front_setback, " / ",
         drawer_back_clearance, " mm");
    echo("  face style = ", drawer_face_style);
}
else {
echo("Cabinet configuration:");
echo("  design name = ", is_undef(design_name) ? "custom" : design_name);
echo("  envelope = ",
     resolved_cabinet_width, " x ",
     cabinet_height, " x ",
     resolved_cabinet_depth, " mm");
echo("  layout mode = ", active_cabinet_layout_mode);
if (mixed_bay_mode)
    echo("  contents = generalized mixed vertical bays");
else
    echo("  contents = ", cabinet_contents);
echo("  mount style = ", active_mount_style);
echo("  base style = ", active_base_style);
echo("  bottom width style = ",
     full_width_bottom_active ? "full_width" : "joined");

if (stackable_mode) {
    echo("Stackable module:");
    echo("  interface depth = ",
         effective_stack_interface_depth, " mm");
    echo("  front/back margins = ",
         effective_stack_front_margin, " / ",
         effective_stack_back_margin, " mm");
    echo("  canonical double-fillet radius = ",
         effective_stack_interface_corner_radius, " mm");
    echo("  vertical tangent between fillets = ",
         stack_interface_vertical_tangent_length, " mm");
    echo("  CNC cutter radius = ",
         stack_interface_tool_radius, " mm");
    echo("  minimum nominal radius for cutter + clearance = ",
         stack_interface_min_nominal_radius, " mm");
    echo("  female profile offset / fit clearance = ",
         effective_stack_interface_clearance, " mm");
    echo("  module stacking pitch = ",
         stack_module_pitch, " mm");
    echo("  assembly preview module count = ",
         max(1,stack_preview_count));
    echo("  preview total height = ",
         stack_preview_total_height, " mm");
    echo("  separate base frame = ",
         stack_base_active);

    if (stack_base_active)
        echo("  base frame height = ",
             stack_base_height, " mm");
}

if (bottom_width_style == "full_width"
    && !full_width_bottom_active)
    echo("WARNING: full_width bottom requires a zero-height floor bottom; falling back to joined bottom for this configuration.");

if (full_width_bottom_active)
    echo("  full-width bottom = ",
         resolved_cabinet_width, " x ", resolved_cabinet_depth,
         " mm; side panels sit on top of the bottom panel");

if (active_mount_style == "wall")
    echo("  floor base hardware = suppressed; cabinet bottom is at Z=0");

if (base_hardware_active) {
    echo("Base hardware:");
    echo("  type = ", active_base_style);
    echo("  mounting plate = ", base_mounting_plate_active);
    echo("  drill holes = ", include_base_hardware_drill_holes);

    if (base_mounting_plate_active)
        echo("  mounting plate size = ",
             base_mounting_plate_width, " x ",
             base_mounting_plate_depth, " x ",
             material_thickness, " mm");

    if (active_base_style == "casters")
        echo("  nominal caster height = ", caster_height, " mm");
    else
        echo("  nominal leveler height = ", leveler_height, " mm");
}

if (worktop_active) {
    echo("Worktop:");
    echo("  size = ",
         worktop_width, " x ",
         worktop_depth, " x ",
         worktop_thickness, " mm");
    echo("  side/front/back overhang = ",
         worktop_side_overhang, " / ",
         worktop_front_overhang, " / ",
         worktop_back_overhang, " mm");

    if (active_worktop_registration) {
        echo("  registration holes = ",
             worktop_registration_hole_count,
             " per front/rear row");
        echo("  registration diameter = ",
             worktop_registration_hole_diameter, " mm");
        echo("  support/stretcher holes = through");
        echo("  worktop pockets = blind from underside, depth ",
             effective_worktop_registration_blind_depth, " mm");
        echo("  export pocket_worktop_registration for worktop underside machining.");
    }
}

if (has_doors
    && active_mount_style == "wall"
    && (mixed_bay_mode || cabinet_contents == "doors")) {
    echo("Wall cabinet door top:");
    echo("  flush to cabinet top = ", wall_doors_flush_top);
    echo("  visible door top Z = ", door_face_top_z, " mm");
}

if (stackable_mode
    && stack_interface_corner_radius
       < stack_interface_min_nominal_radius)
    echo("NOTE: stack interface radius was increased so BOTH radiused shoulders remain machinable after female fit clearance is applied.");

if (stackable_mode
    && stack_interface_corner_radius
       > stack_interface_max_nominal_radius)
    echo("NOTE: stack interface radius was clamped so two tangent fillets fit inside the configured interface depth / center span.");

if (stackable_mode
    && stack_interface_max_nominal_radius
       < stack_interface_min_nominal_radius)
    echo("WARNING: interface depth/span is too small for the selected cutter plus clearance. Increase stack_interface_depth or reduce cutter/clearance.");

if (stackable_mode
    && top_style != "stretchers")
    echo("WARNING: stackable modules are intended to use top_style=stretchers so the mating tongue can enter the center top recess.");

if (stackable_mode
    && abs(bottom_above_toe-effective_stack_interface_depth) > 0.01)
    echo("WARNING: stackable module bottom plane should equal stack interface depth; check the front-end bottom_above_toe resolver.");

if (stackable_mode
    && top_stretcher_depth > effective_stack_front_margin)
    echo("WARNING: front top stretcher is deeper than the front stacking ear.");

if (stackable_mode
    && top_stretcher_depth > effective_stack_back_margin)
    echo("WARNING: rear top stretcher is deeper than the rear stacking ear.");

if (stack_base_active
    && stack_base_height <= effective_stack_interface_depth)
    echo("WARNING: stack_base_height should be greater than stack_interface_depth.");

if (stackable_mode
    && full_width_bottom_active)
    echo("WARNING: full-width bottom is not recommended for the stackable interface; use the joined bottom at stack-interface height.");

echo("Rear construction:");
echo("  style = ", back_style);

if (back_style == "panel") {
    echo("  applied back size = ",
         resolved_cabinet_width, " x ",
         simple_back_height, " x ",
         back_thickness, " mm");
}
else if (back_style == "structural_panel") {
    echo("  structural back material = carcass stock");
    echo("  finished rear plane = flush with cabinet back");
    echo("  body size between supports = ",
         inner_width, " x ",
         captured_back_height, " x ",
         material_thickness, " mm");
    echo("  flat cut envelope = ",
         back_cut_width, " x ",
         back_cut_height, " mm");
    echo("  structural back joinery = ", joinery_style);
    echo("  usable interior depth reduced to ",
         usable_depth, " mm");

    if (joinery_style == "dado")
        echo("  structural back dado depth = ",
             structural_back_dado_depth, " mm");

    if (joinery_style == "butt"
        && include_butt_registration_holes)
        echo("  side registration holes follow butt-registration settings");
}
else if (back_style == "stretchers") {
    echo("  stretcher count = ", back_stretcher_count);
    echo("  each stretcher height = ",
         back_stretcher_height, " mm");
    echo("  stretcher material thickness = ",
         material_thickness, " mm");
    echo("  rear stretchers use carcass side joinery = ",
         joinery_style);
}


}


// ---------------------------
// BASIC VALIDATION / FEEDBACK

// Structured design-health output inherited from v35.  Human-readable legacy warnings below
// are retained for OpenSCAD users; these CHECK records give the web UI and
// manufacturing exporter stable severity/code fields.
function validation_enabled() =
    is_undef(validation_report) ? true : validation_report != "off";
function validation_verbose() =
    !is_undef(validation_report) && validation_report == "verbose";

module validation_check(severity,code,message) {
    if (validation_enabled())
        echo(str("CHECK|",severity,"|",code,"|",message));
}

if (validation_enabled()) {
    validation_check("INFO","ENGINE","Modular Organization v3 geometry validation");

    validation_check(
        "INFO","INTERFACE_CONTRACT",
        str(organization_interface_contract," / parent ",organization_parent_engine)
    );

    if (organization_keepout_validation_enabled())
        for (c=organization_feature_keepout_conflicts())
            validation_check(
                organization_keepout_conflict_severity(),
                "INTERFACE_KEEPOUT_CONFLICT",
                str(
                    "Feature ",c[0]," owned by ",c[2],
                    " intersects keepout ",c[1]," owned by ",c[3],"."
                )
            );

    for (c=organization_feature_feature_conflicts())
        validation_check(
            "ERROR","MACHINING_FEATURE_COLLISION",
            str(
                "Features ",c[0]," (",c[2],") and ",c[1],
                " (",c[3],") overlap on part ",c[4],"."
            )
        );

    validation_check(
        "INFO","VALIDATION_COVERAGE",
        str(
            "Side-panel machining collision ledger is exhaustive for ",
            len(organization_features())," active features across ",
            organization_side_feature_family_count(),
            " feature families; full-layout CUT/POCKET coverage is completed by modular_organization_validate.py."
        )
    );

    // V2 retires the separate ganging-point conflict checker. Ganging holes and
    // dowels are now ordinary ledger features and are checked by the same exact
    // feature/keepout and feature/feature paths as every other side operation.

    if (resolved_cabinet_width <= 0
        || resolved_cabinet_depth <= 0
        || cabinet_height <= 0)
        validation_check("ERROR","CABINET_ENVELOPE",
            "Cabinet width, depth, and height must all be greater than zero.");

    if (material_thickness <= 0)
        validation_check("ERROR","CARCASS_THICKNESS",
            "Carcass material thickness must be greater than zero.");

    if (stock_width <= 0 || stock_height <= 0)
        validation_check("ERROR","STOCK_SIZE",
            "Manufacturing stock width and height must be greater than zero.");

    if (resolved_cabinet_depth > max(stock_width,stock_height)
        || cabinet_height > max(stock_width,stock_height))
        validation_check("WARN","SIDE_EXCEEDS_STOCK",
            "A cabinet-side bounding dimension exceeds the longest configured stock dimension.");

    if (joinery_style == "tab_slot") {
        if (joint_tab_width <= 0)
            validation_check("ERROR","TAB_WIDTH",
                "joint_tab_width must be greater than zero.");

        if (minimum_joint_web < 0)
            validation_check("ERROR","JOINT_WEB",
                "minimum_joint_web cannot be negative.");

        if (slot_relief_is_active() && cnc_tool_diameter <= 0)
            validation_check("ERROR","RELIEF_TOOL",
                "CNC corner relief requires cnc_tool_diameter greater than zero.");

        if (slot_relief_is_active() && cnc_tool_diameter > joint_tab_width)
            validation_check("WARN","RELIEF_LARGER_THAN_TAB",
                "CNC tool diameter is larger than the nominal tab width; inspect relief geometry before cutting.");

        for (loc=["bottom","top","shelf","separator"])
            if (location_tab_placement(loc) == "custom"
                && len(location_tab_custom_centers(loc)) > 0
                && len(location_tab_custom_centers_resolved(
                    loc == "bottom" ? resolved_cabinet_depth
                    : loc == "top" ? (top_style == "full" ? resolved_cabinet_depth : top_stretcher_depth)
                    : loc == "shelf" ? shelf_depth
                    : drawer_separator_full_depth,
                    loc
                )) < len(location_tab_custom_centers(loc)))
                validation_check("WARN",str("CUSTOM_TAB_",loc),
                    str("One or more custom ",loc," tab centers fall outside the usable edge and were ignored."));

        if (stackable_mode
            && location_tab_placement("bottom") == "stack_safe"
            && !stack_safe_bottom_tabs_possible(resolved_cabinet_depth))
            validation_check("WARN","STACK_BOTTOM_TAB_FALLBACK",
                "Stack-safe bottom tabs do not fit inside the current stacking pads; automatic placement is being used.");
    }

    if (joinery_style == "dado" && dado_depth >= material_thickness)
        validation_check("WARN","DADO_DEPTH_CLAMP",
            "Carcass dado depth reaches/exceeds stock thickness and is clamped by the geometry engine.");

    if (has_doors && effective_hinge_style == "euro_35mm"
        && effective_hinge_cup_depth >= door_thickness)
        validation_check("WARN","HINGE_CUP_DEPTH",
            "Configured hinge cup depth reaches/exceeds door thickness.");

    if (validation_verbose()) {
        validation_check("INFO","EDGE_POLICY",
            str("edge_joinery_policy=",resolved_edge_joinery_policy()));
        if (joinery_style == "tab_slot") {
            validation_check("INFO","BOTTOM_TAB_POLICY",
                str(location_tab_placement("bottom")));
            validation_check("INFO","TOP_TAB_POLICY",
                str(location_tab_placement("top")));
            validation_check("INFO","SHELF_TAB_POLICY",
                str(location_tab_placement("shelf")));
            validation_check("INFO","SEPARATOR_TAB_POLICY",
                str(location_tab_placement("separator")));
        }
    }
}

// ---------------------------

if (mixed_bay_mode) {
    echo("Mixed bay layout:");
    echo("  bay count = ", active_mixed_bay_count);
    echo("  bay types = ", active_mixed_bay_types);
    echo("  width weights = ", active_mixed_bay_width_weights);
    echo("  structural partitions = ", mixed_bay_partition_count());

    for (b=[0:active_mixed_bay_count-1]) {
        echo("  bay ", b+1,
             ": type = ", mixed_bay_type(b),
             ", opening width = ", mixed_bay_opening_width(b), " mm",
             ", front width = ", mixed_bay_front_width(b), " mm");

        if (mixed_bay_type_normalized(b) != "drawers"
            && mixed_bay_type_normalized(b) != "door"
            && mixed_bay_type_normalized(b) != "open")
            echo("WARNING: Mixed bay ", b+1,
                 " has unsupported type '", mixed_bay_type(b),
                 "'. Use drawers, door/doors, open, or shelves.");

        if (mixed_bay_is_type(b,"door")) {
            requested_door_count =
                b < len(active_mixed_bay_door_counts)
                    ? round(active_mixed_bay_door_counts[b])
                    : 1;

            if (requested_door_count != 1 && requested_door_count != 2)
                echo("WARNING: Mixed bay ", b+1,
                     " door count must be 1 or 2; the generator clamps it to the supported range.");

            if (mixed_bay_door_count(b) == 1
                && mixed_bay_door_hinge_side(b) != "left"
                && mixed_bay_door_hinge_side(b) != "right")
                echo("WARNING: Mixed bay ", b+1,
                     " single-door hinge side must be left or right.");
        }

        if (mixed_bay_is_shelfable(b)
            && mixed_bay_shelf_count(b) > 0
            && mixed_bay_shelf_style(b) != "fixed"
            && mixed_bay_shelf_style(b) != "adjustable")
            echo("WARNING: Mixed bay ", b+1,
                 " shelf style '", mixed_bay_shelf_style(b),
                 "' is unsupported; use fixed or adjustable.");
    }

    if (active_mixed_bay_count > 1 && !include_mixed_bay_partitions)
        echo("WARNING: Mixed-bay partitions are disabled. Interior drawer/door/shelf bays may lack mounting and support surfaces.");
}

if (has_drawers) {
    echo(mixed_bay_mode ? "Mixed-bay drawer stacks:" : "Drawer banks:");
    echo("  active bank slots = ", active_drawer_bank_count());
    echo("  applied drawer faces = ", include_drawer_faces);

    if (!mixed_bay_mode) {
        echo("  layout mode = ", drawer_bank_layout_mode);
        echo("  width weights = ", drawer_bank_width_weights);
    }

    for (b=[0:active_drawer_bank_count()-1])
        if (drawer_bank_drawer_count(b) > 0) {
            echo("  bank/bay ", b+1,
                 ": opening width = ",
                 drawer_bank_opening_width(b), " mm",
                 ", face width = ",
                 drawer_face_width(b), " mm",
                 ", drawers = ",
                 drawer_bank_drawer_count(b),
                 ", height mode = ",
                 drawer_bank_height_mode_for(b));

            if (drawer_bank_opening_width(b)
                <= 2*drawer_material_thickness + 4)
                echo("WARNING: Drawer bay ", b+1,
                     " is very narrow relative to the drawer-wall thickness.");

            if (drawer_bank_height_mode_for(b) == "graduated")
                echo("    graduated step = ",
                     drawer_bank_graduated_step_for(b));

            for (i=[0:drawer_bank_drawer_count(b)-1]) {
                echo("    drawer ", i+1,
                     " weight = ", drawer_height_weight(i,b),
                     ", face height = ",
                     drawer_face_nominal_height(i,b), " mm");

                if (drawer_face_nominal_height(i,b)
                        < drawer_face_height_warning_threshold)
                    echo("WARNING: Bay ", b+1,
                         " drawer ", i+1,
                         " face height is under ",
                         drawer_face_height_warning_threshold,
                         " mm. Consider fewer drawers, different weights, or a taller cabinet.");
            }
        }

    if (!mixed_bay_mode && drawer_bank_count > 1) {
        echo("Drawer-bank partitions:");
        echo("  count = ", drawer_bank_partition_count());
        echo("  joinery = ", drawer_bank_partition_joinery_mode());
        echo("  depth = ", drawer_bank_partition_depth, " mm");
    }

    if (!mixed_bay_mode
        && drawer_bank_layout_mode == "independent"
        && include_drawer_separators)
        echo("NOTE: full-width horizontal drawer separators are suppressed in independent-bank mode because adjacent banks can have different drawer boundaries.");

    if (mixed_bay_mode && include_drawer_separators)
        echo("NOTE: full-width horizontal drawer separators are suppressed in mixed-bay mode.");

    if (!include_drawer_faces && include_drawer_handle_holes)
        echo("  handle holes moved to structural drawer box fronts");

    if (!include_drawer_faces && include_drawer_face_registration_holes)
        echo("  drawer-face registration holes suppressed because applied faces are disabled");
}

if (has_doors) {
    echo(mixed_bay_mode ? "Mixed-bay doors:" : "Door bays:");

    if (mixed_bay_mode) {
        for (b=[0:active_mixed_bay_count-1])
            if (mixed_bay_is_type(b,"door")) {
                echo("  bay ", b+1,
                     " doors = ", mixed_bay_door_count(b),
                     ", leaf width = ", mixed_bay_door_leaf_width(b), " mm",
                     mixed_bay_door_count(b) == 1
                        ? str(", hinge side = ", mixed_bay_door_hinge_side(b))
                        : ", paired outward hinges");

                if (effective_hinge_style == "euro_35mm"
                    && mixed_bay_door_leaf_width(b)
                       < 2*effective_hinge_cup_center_from_door_edge
                         + effective_hinge_cup_diameter)
                    echo("WARNING: Door leaf in mixed bay ", b+1,
                         " is narrow relative to the configured Euro hinge cup geometry.");
            }
    }
    else {
        echo("  width weights = ", door_width_weights);

        for (i=[0:door_count-1]) {
            echo("  door ", i+1,
                 " width = ", door_each_width(i), " mm");

            if (effective_hinge_style == "euro_35mm"
                && door_each_width(i)
                   < 2*effective_hinge_cup_center_from_door_edge
                     + effective_hinge_cup_diameter)
                echo("WARNING: Door ", i+1,
                     " is narrow relative to the configured Euro hinge cup geometry.");
        }
    }
}

if (has_doors && door_region_height < 100)
    echo("WARNING: Calculated door height is under 100 mm.");

if (!mixed_bay_mode && cabinet_contents == "combo" && combo_divider_bottom_z < front_opening_bottom_z)
    echo("WARNING: Combo door region is too short for the divider thickness.");

if (joinery_style == "dado" && dado_depth > material_thickness)
    echo("WARNING: dado_depth exceeds material_thickness; it is clamped internally.");

if (joinery_style == "tab_slot"
    && (
        slot_corner_relief == "dogbone"
        || slot_corner_relief == "t_bone"
        || slot_corner_relief == "tbone"
        || slot_corner_relief == "t-bone"
    )
    && cnc_tool_diameter <= 0)
    echo("WARNING: cnc_tool_diameter must be greater than zero for CNC corner relief.");



if (back_style == "stretchers"
    && back_stretcher_height <= 2*joint_tab_edge_margin
    && joinery_style == "tab_slot")
    echo("WARNING: back_stretcher_height is small relative to the tab edge margins.");

if (back_style == "stretchers"
    && back_stretcher_y < 0)
    echo("WARNING: back_stretcher_inset/depth places rear stretchers outside the cabinet.");

if (base_hardware_active
    && base_hardware_inset_x < base_hardware_half_x())
    echo("WARNING: base_hardware_inset_x is smaller than half the hardware footprint; centers are clamped inward.");

if (base_hardware_active
    && base_hardware_inset_y < base_hardware_half_y())
    echo("WARNING: base_hardware_inset_y is smaller than half the hardware footprint; centers are clamped inward.");

if (base_hardware_active
    && !base_mounting_plate_active)
    echo("NOTE: base hardware drilling is placed directly in the cabinet bottom because the mounting plate is disabled.");

if (worktop_active && worktop_thickness <= 0)
    echo("WARNING: worktop_thickness must be greater than zero.");

if (active_worktop_registration
    && worktop_registration_blind_depth
       >= worktop_thickness)
    echo("WARNING: worktop registration blind depth was clamped to preserve at least 0.5 mm of material at the finished top surface.");

if (active_worktop_registration
    && worktop_registration_hole_diameter <= 0)
    echo("WARNING: worktop registration hole diameter must be greater than zero.");

// Helpful console feedback for adaptive tab/slot sizing.
if (joinery_style == "tab_slot" && tab_count_mode == "adaptive") {
    echo("Adaptive joint counts:");
    echo("  cabinet-depth edge tabs = ", effective_tab_count(resolved_cabinet_depth));
    echo("  shelf-depth edge tabs   = ", effective_tab_count(shelf_depth));
    echo("  top-stretcher edge tabs = ", effective_tab_count(top_stretcher_depth));

    if (stackable_mode && joinery_style == "tab_slot") {
        echo("  bottom tab placement = ", resolved_bottom_tab_placement());
        echo(
            "  bottom tab centers from front = ",
            [
                for (i=[0:bottom_tab_count(resolved_cabinet_depth)-1])
                    bottom_tab_center(resolved_cabinet_depth,i)
            ],
            " mm"
        );

        if (
            resolved_bottom_tab_placement() == "stack_safe"
            && !stack_safe_bottom_tabs_possible(resolved_cabinet_depth)
        )
            echo(
                "WARN|Stack-safe bottom tab placement cannot fit inside the current front/rear stacking pads; using the normal automatic pattern. Increase stack_interface_front_margin/back_margin, reduce joint_tab_width, or use custom bottom tab centers."
            );
    }
    if (has_toe_kick)
        echo("  toe-kick edge tabs      = ",
             effective_tab_count(toe_kick_height));
}


if (drawer_separator_count > 0) {
    echo("Drawer separators enabled: ", drawer_separator_count);
    echo("  style                    = ", drawer_separator_style);
    echo("  effective drawer clearance = ", effective_drawer_vertical_clearance_for(0));
    if (!mixed_bay_mode && drawer_bank_count > 1)
        echo("NOTE: horizontal drawer separators are full-cabinet-width and assume shared drawer boundaries across banks.");
}




if (face_frame_active) {
    echo("Face frame:");
    echo("  overall = ",
         resolved_cabinet_width, " x ",
         face_frame_height, " x ",
         effective_face_frame_thickness, " mm");
    echo("  side stiles = ",
         effective_face_frame_side_stile_width, " mm");
    echo("  top/bottom rails = ",
         effective_face_frame_top_rail_width, " / ",
         effective_face_frame_bottom_rail_width, " mm");
    echo("  clear framed opening = ",
         face_frame_clear_width, " x ",
         face_frame_clear_height, " mm");
    echo("  nominal front overlay = ",
         effective_face_frame_overlay, " mm");
    echo("  construction = ",
         face_frame_construction_resolved);

    if (face_frame_back_dado_active) {
        echo("  back dado depth = ",
             effective_face_frame_back_dado_depth, " mm");
        echo("  back dado width = ",
             face_frame_back_dado_width, " mm");
        echo("  visible projection ahead of carcass = ",
             face_frame_projection, " mm");
        echo("  machine these pockets from the BACK of the face-frame strips");
    }

    if (face_frame_mid_rail_active)
        echo("  mid rail = ",
             effective_face_frame_mid_rail_width,
             " mm at Z ",
             face_frame_mid_rail_center_z);

    if (face_frame_center_stile_enabled)
        echo("  center stile = ",
             effective_face_frame_center_stile_width,
             " mm");
}

echo("Decorative front mounting:");
echo("  style = ",
     fronts_inset_flush ? "inset_flush" : "overlay");

if (fronts_inset_flush) {
    echo(
        face_frame_active
            ? "  visible front plane = flush with face-frame front"
            : "  visible front plane = flush with carcass front"
    );
    echo("  perimeter reveal = ", front_edge_reveal, " mm");
    echo("  interior setback behind fronts = ",
         inset_front_interior_depth, " mm");

    if (has_drawers && include_drawer_faces)
        echo("  drawer box front setback = ",
             effective_drawer_front_setback, " mm");

    if (has_doors)
        echo("  shelf / interior panel front setback = ",
             shelf_front_y, " mm");
}
else if (fronts_cover_bottom_lip) {
    echo("Front bottom-lip overlay = ", bottom_lip_overlay, " mm");

    if (mixed_bay_mode || cabinet_contents == "drawers")
        for (b=[0:active_drawer_bank_count()-1])
            if (drawer_bank_drawer_count(b) > 0)
                echo("Lowest drawer front bottom Z, bank/bay ", b+1,
                     " = ",
                     drawer_face_z(
                         drawer_bank_drawer_count(b)-1,b));

    if (has_doors)
        echo("Door front bottom Z = ", door_face_bottom_z);
}



if (has_toe_kick && side_toe_kick_cutout != "none") {
    echo("Side toe-kick cutout = ", side_toe_kick_cutout);
    echo("  notch depth  = ", toe_kick_setback, " mm");
    echo("  notch height = ", toe_kick_height, " mm");
}



if (back_style == "panel") {
    echo("Back panel joinery = none; nail/screw applied panel");
}
else if (back_style == "structural_panel") {
    echo("Structural back ties both sides and the rear-reaching bottom/top member.");
}



if (has_drawers && drawer_mount == "wood_rails") {
    echo("Wood slide system:");
    echo("  fixed rail size = ",
         resolved_wood_rail_depth, " x ",
         wood_rail_height, " x ",
         wood_rail_thickness, " mm");
    echo("  drawer runner size = ",
         resolved_wood_drawer_runner_depth, " x ",
         wood_drawer_runner_height, " x ",
         wood_drawer_runner_thickness, " mm");
    echo("  vertical running clearance = ",
         wood_rail_vertical_clearance, " mm");

    for (b=[0:active_drawer_bank_count()-1])
        if (drawer_bank_drawer_count(b) > 0)
            if (drawer_rail_z(
                    drawer_bank_drawer_count(b)-1,b)
                < bottom_above_toe + material_thickness)
                echo("WARNING: Lowest fixed wood rail in bank/bay ", b+1,
                     " intersects the cabinet bottom. Increase wood_drawer_runner_bottom_offset, reduce wood_rail_height, or increase drawer clearance.");
}



if (has_drawers
    && drawer_mount == "wood_rails"
    && include_wood_slide_registration_holes) {
    echo("Wood slide registration holes:");
    echo("  diameter = ", wood_slide_registration_hole_diameter, " mm");
    echo("  holes per rail/runner = ", wood_slide_registration_hole_count);
    echo("  rail mating holes are included in cabinet sides");
    echo("  runner mating holes are included in drawer sides");

    if (wood_drawer_runner_local_front() < 0)
        echo("WARNING: wood_drawer_runner_front_setback is ahead of the drawer side front.");

    if (!wood_drawer_runner_reg_valid(drawer_box_depth))
        echo("WARNING: No collision-free drawer-runner registration-hole interval remains after protecting the drawer corner joinery. Reduce hole diameter/count, move the runner, or increase drawer depth.");
}

if (joinery_style == "butt" && include_butt_registration_holes) {
    echo("Butt-joint registration holes enabled:");
    echo("  diameter = ", butt_registration_hole_diameter, " mm");
    echo("  holes are through cabinet sides and centered on mating panel edges");
    echo("  edge pilot holes in mating parts are drilled during assembly");
}




if (!fronts_inset_flush
    && front_width_style == "full_overlay") {
    echo("Fronts use full-overlay width:");
    echo("  left X = ", front_panel_x, " mm");
    echo("  total front width = ", front_panel_width, " mm");
}

if (door_hinge_partition_count() > 0 && effective_hinge_style == "none") {
    echo("Door partitions:");
    echo("  count = ", door_hinge_partition_count());
    echo("  front-to-back depth = ", door_hinge_partition_actual_depth, " mm");
    echo("  joinery follows carcass = ", joinery_style);
}

if (face_frame_back_dado_active
    && effective_face_frame_back_dado_depth
       >= effective_face_frame_thickness)
    echo("WARNING: face-frame back dado depth consumes the full facing thickness.");

if (face_frame_back_dado_active
    && face_frame_back_dado_width
       > effective_face_frame_side_stile_width)
    echo("WARNING: carcass thickness + face-frame dado clearance is wider than the side stile.");

if (face_frame_back_dado_active
    && face_frame_back_dado_width
       > effective_face_frame_top_rail_width)
    echo("WARNING: carcass thickness + face-frame dado clearance is wider than the top rail.");

if (face_frame_active
    && effective_face_frame_side_stile_width*2 >= resolved_cabinet_width)
    echo("WARNING: face-frame side stiles leave no usable cabinet opening.");

if (fronts_inset_flush
    && front_edge_reveal < 0.5)
    echo("NOTE: very small inset-front reveals can be sensitive to material movement, cabinet squareness, and hinge adjustment.");

if (fronts_inset_flush
    && has_drawers
    && include_drawer_faces
    && drawer_box_depth < 40)
    echo("WARNING: inset drawer fronts leave less than 40 mm of drawer-box depth after front/back clearances.");

if (face_frame_active
    && has_doors
    && effective_hinge_style != "none")
    echo("NOTE: face-frame door hinge mounting varies substantially by hardware family. Kitchen V2 defaults effective_hinge_style=none; verify any enabled drilling against the actual face-frame hinge.");

if (fronts_inset_flush
    && has_doors
    && effective_hinge_style == "euro_35mm")
    echo("NOTE: inset Euro doors usually require inset-specific hinges/plates. Verify hinge throw and mounting-plate geometry against the selected hardware.");

if (has_doors && effective_hinge_style != "none") {
    echo("Door hinge hardware:");
    echo("  style = ", effective_hinge_style);
    echo("  hinge count = ", hinge_count);

    if (effective_hinge_style == "euro_35mm") {
        echo("  cup = ", effective_hinge_cup_diameter,
             " mm diameter x ", effective_hinge_cup_depth, " mm deep");
        echo("  export pocket_layout for blind cup pockets");
    }

    echo("  cabinet plate line = ",
         effective_hinge_plate_center_from_front, " mm from front");

    if (mixed_bay_mode) {
        echo("  mixed-bay structural partitions = ",
             mixed_bay_partition_count());
        echo("  partition joinery follows carcass = ",
             joinery_style);
    }
    else if (door_count > 2) {
        if (door_hinge_partition_count() > 0) {
            echo("  full-depth door partitions = ",
                 door_hinge_partition_count());
            echo("  partition front-to-back depth = ",
                 door_hinge_partition_actual_depth, " mm");
            echo("  partition joinery follows carcass = ",
                 joinery_style);
        } else {
            echo("WARNING: More than 2 doors need internal hinge mounting structure; enable door hinge partitions or provide another mounting method.");
        }
    }


    if (2*hinge_end_offset > door_face_height)
        echo("WARNING: hinge_end_offset is too large for the calculated door height.");
}

if (include_drawer_handle_holes || include_door_handle_holes) {
    echo("Handle hole pattern = ", handle_hole_pattern);
    if (include_drawer_handle_holes)
        echo("  drawer handle target = ",
             include_drawer_faces ? "decorative face" : "drawer box front");
    echo("Handle hole diameter = ", handle_hole_diameter, " mm");

    if (handle_hole_pattern == "two_hole")
        echo("Handle hole spacing = ", handle_hole_spacing, " mm");
}



if (mixed_bay_mode && mixed_bay_total_shelf_count() > 0) {
    echo("Mixed-bay shelves:");
    echo("  total supplied shelf panels = ", mixed_bay_total_shelf_count());

    for (b=[0:active_mixed_bay_count-1])
        if (mixed_bay_is_shelfable(b) && mixed_bay_shelf_count(b) > 0)
            echo("  bay ", b+1,
                 " style = ", mixed_bay_shelf_style(b),
                 ", supplied shelves = ", mixed_bay_shelf_count(b),
                 ", part width = ",
                 mixed_bay_shelf_style(b) == "fixed"
                    ? mixed_bay_fixed_shelf_cut_width(b)
                    : mixed_bay_adjustable_shelf_width(b),
                 " mm");

    if (mixed_bay_any_fixed_shelves()) {
        echo("  fixed-shelf joinery = ", joinery_style);
        if (joinery_style == "dado")
            echo("  NOTE: internal partition shelf dados are modeled on the appropriate partition faces; machining may require flipping the partition.");
    }

    if (mixed_bay_any_adjustable_shelves()) {
        echo("  shelf pin diameter = ", adjustable_shelf_hole_diameter, " mm");
        echo("  shelf pin spacing = ", adjustable_shelf_hole_spacing, " mm");
        echo("  holes per row = ", mixed_bay_shelf_pin_count());
        echo("  outer-side hole type = ", adjustable_shelf_hole_type);
        echo("  internal partition shelf-pin holes = through");

        if (adjustable_shelf_hole_type == "blind")
            echo("  export pocket_layout for outer-side shelf-pin drilling");
    }
}
else if (has_doors && shelf_style == "adjustable") {
    echo("Adjustable shelves:");
    echo("  supplied shelf panels = ", door_shelf_count);
    echo("  shelf pin diameter = ", adjustable_shelf_hole_diameter, " mm");
    echo("  shelf pin spacing = ", adjustable_shelf_hole_spacing, " mm");
    echo("  holes per row = ", shelf_pin_count());
    echo("  hole type = ", adjustable_shelf_hole_type);

    if (adjustable_shelf_hole_type == "blind")
        echo("  export pocket_layout for shelf-pin drilling");
}

if (!mixed_bay_mode
    && door_hinge_partition_count() > 0
    && shelf_style == "adjustable") {
    echo("  internal partition shelf-pin holes = through (support both adjacent bays)");
    echo("  adjustable shelf panels per level = ",
         door_adjustable_shelf_piece_count());
}

if (slot_corner_relief == "dogbone")
    echo("Dogbone relief = diagonal inward cutter centers at r/sqrt(2); cutter edge passes through each nominal sharp corner.");

if (slot_corner_relief == "t_bone"
    || slot_corner_relief == "tbone"
    || slot_corner_relief == "t-bone")
    echo("T-bone relief = cutter center shifted inward along each slot's longest wall; the adjacent wall stays straight.");

if (output_mode == "print_layout")
    echo("print_layout uses actual part thicknesses and is suitable for STL/3MF export.");



if (has_drawers) {
    echo("Drawer box joinery:");
    echo("  side/front/back = ", drawer_joinery_style);
    echo("  bottom = ", drawer_bottom_joinery);

    if (drawer_joinery_style == "dado")
        echo("  drawer dado depth = ",
             effective_drawer_dado_depth(), " mm");

    if (drawer_bottom_joinery == "dado") {
        echo("  bottom dado depth = ",
             effective_drawer_bottom_dado_depth(), " mm");
        for (b=[0:active_drawer_bank_count()-1])
            if (drawer_bank_drawer_count(b) > 0)
                echo("  bottom panel size, bank/bay ", b+1, " = ",
                     drawer_bottom_width(b), " x ",
                     drawer_bottom_depth(), " mm");
        echo("  export pocket_layout for drawer bottom grooves");
    }

    if (drawer_joinery_style == "tab_slot") {
        echo("  drawer tab/slot clearance = ", drawer_joint_fit_clearance, " mm");
        echo("  drawer tab corner relief follows slot_corner_relief");
    }

    if (drawer_joinery_style == "dado"
        || drawer_bottom_joinery == "dado")
        echo("  drawer blind dados are modeled in print_layout");
}

if (drawer_dado_depth >= drawer_material_thickness)
    echo("WARNING: drawer_dado_depth is clamped below drawer wall thickness.");

if (drawer_bottom_dado_depth >= drawer_material_thickness)
    echo("WARNING: drawer_bottom_dado_depth is clamped below drawer wall thickness.");



echo("Fit / tolerance settings:");
echo("  carcass tab-slot clearance = ",
     joint_fit_clearance, " mm");
echo("  carcass dado clearance = ",
     dado_fit_clearance, " mm");

if (has_drawers) {
    echo("  drawer tab-slot clearance = ",
         drawer_joint_fit_clearance, " mm");
    echo("  drawer dado clearance = ",
         drawer_dado_fit_clearance, " mm");
}

if (ganging_active) {
    echo("Cabinet ganging / alignment:");
    echo("  style = ", ganging_style);
    echo("  active sides = ", ganging_sides);
    echo("  columns = ", effective_ganging_column_count);
    echo("  vertical stations = ",
         effective_ganging_station_count);
    echo("  front column from front = ",
         ganging_front_y, " mm");

    if (ganging_has_rear_column)
        echo("  rear column from front = ",
             ganging_rear_y, " mm");

    if (ganging_dowel_active) {
        echo("  alignment dowel = ",
             effective_ganging_dowel_diameter,
             " mm dia x ",
             effective_ganging_dowel_depth,
             " mm blind depth");
        echo("  export pocket_ganging from the OUTER cabinet side face");
    }

    if (ganging_connector_active)
        echo("  connector through hole = ",
             effective_ganging_connector_hole_diameter,
             " mm");

    echo("  pattern is canonical; detected conflicts are WARN| records and are not auto-shifted.");
}



if ((output_mode == "cut_layout"
     || output_mode == "engrave_layout"
     || output_mode == "pocket_layout"
     || output_mode == "pocket_carcass_dados"
     || output_mode == "pocket_drawer_dados"
     || output_mode == "pocket_bottom_grooves"
     || output_mode == "pocket_shelf_pins"
     || output_mode == "pocket_hinge_cups"
     || output_mode == "pocket_face_registration"
     || output_mode == "pocket_base_hardware"
     || output_mode == "pocket_worktop_registration"
     || output_mode == "pocket_face_frame_dados"
     || output_mode == "pocket_ganging")
    && include_shared_export_bounding_box) {
    echo("Shared export bounding box enabled:");
    echo("  content bounds = ",
         export_layout_content_width, " x ",
         export_layout_content_height, " mm");
    echo("  outer margin = ", export_bounding_box_margin, " mm");
    echo("  delete/ignore the outer dummy frame in CAM.");
}

if (output_mode == "cut_layout" && show_blind_pockets_over_cut_layout) {
    echo("cut_layout preview overlays exact blind-pocket geometry.");
    echo("  preview overlay is not included in SVG/DXF export.");
}



if (has_drawers && active_drawer_face_registration) {
    echo("Drawer face registration:");
    echo("  holes per drawer = ",
         drawer_face_registration_hole_count);
    echo("  diameter = ",
         drawer_face_registration_hole_diameter, " mm");
    echo("  spacing = ",
         drawer_face_registration_hole_spacing, " mm");
    echo("  decorative face hole = ",
         drawer_face_registration_face_hole);

    if (drawer_face_registration_face_hole == "half_depth") {
        echo("  face pocket depth = ",
             drawer_face_registration_blind_depth(), " mm");
        echo("  blind face holes are in pocket_layout");
    } else {
        echo("  decorative face holes are through-cut");
    }

    for (b=[0:active_drawer_bank_count()-1]) {
        if (drawer_bank_drawer_count(b) > 0) {
            for (i=[0:drawer_bank_drawer_count(b)-1]) {
                if (drawer_face_reg_box_local_z(i,b)
                        < drawer_face_registration_hole_diameter
                    || drawer_face_reg_box_local_z(i,b)
                        > drawer_box_height(i,b)
                          - drawer_face_registration_hole_diameter)
                    echo("WARNING: drawer face registration vertical position is close to/outside a drawer box-front edge in bank/bay ", b+1, ".");

                if (drawer_face_reg_face_local_z(i,b)
                        < drawer_face_registration_hole_diameter
                    || drawer_face_reg_face_local_z(i,b)
                        > drawer_face_height_for(i,b)
                          - drawer_face_registration_hole_diameter)
                    echo("WARNING: drawer face registration vertical position is close to/outside a decorative face edge in bank/bay ", b+1, ".");
            }

            if (drawer_face_registration_hole_count > 1
                && (drawer_face_registration_hole_count-1)
                   *drawer_face_registration_hole_spacing
                   > drawer_cross_panel_width(b)
                     - 2*drawer_face_registration_hole_diameter)
                echo("WARNING: drawer face registration spacing is too wide for the drawer box front in bank/bay ", b+1, ".");
        }
    }
}



if (output_mode == "pocket_carcass_dados") {
    echo("Pocket operation: carcass / partition dados");
    if (joinery_style == "dado")
        echo("  carcass dado depth = ", effective_dado_depth(), " mm");
    if (drawer_bank_partition_joinery_mode() == "dado"
        && drawer_bank_partition_count() > 0)
        echo("  bank-partition receiver depth = ",
             drawer_bank_partition_dado_depth(), " mm");
    if (mixed_bay_partition_count() > 0 && joinery_style == "dado")
        echo("  mixed-bay partition receiver depth = ",
             mixed_bay_partition_dado_depth(), " mm");
}

if (output_mode == "pocket_drawer_dados")
    echo("Pocket operation: drawer corner dados, depth = ",
         effective_drawer_dado_depth(), " mm");

if (output_mode == "pocket_bottom_grooves")
    echo("Pocket operation: drawer bottom grooves, depth = ",
         effective_drawer_bottom_dado_depth(), " mm");

if (output_mode == "pocket_shelf_pins")
    echo("Pocket operation: blind shelf pins, depth = ",
         adjustable_shelf_hole_depth, " mm");

if (output_mode == "pocket_hinge_cups")
    echo("Pocket operation: hinge cups, depth = ",
         effective_hinge_cup_depth, " mm");

if (output_mode == "pocket_face_registration")
    echo("Pocket operation: drawer-face registration, depth = ",
         drawer_face_registration_blind_depth(), " mm");

if (output_mode == "pocket_face_frame_dados")
    echo("Pocket operation: face-frame BACK dados/rabbets, depth = ",
         effective_face_frame_back_dado_depth, " mm");

if (output_mode == "pocket_ganging") {
    if (ganging_dowel_active)
        echo("Pocket operation: blind cabinet-ganging alignment dowels, OUTER side face, depth = ",
             effective_ganging_dowel_depth, " mm");
    else
        echo("Pocket operation: no blind ganging features for the current ganging_style; connector holes are through features in cut_layout.");
}


if (output_mode == "calibration_coupon_cut"
    || output_mode == "calibration_coupon_pocket"
    || output_mode == "calibration_coupon_engrave") {

    echo("Calibration coupon:");
    echo("  coupon size = ",
         calibration_coupon_width, " x ",
         calibration_coupon_height, " mm");
    echo("  * marks the currently configured clearance.");
    echo("  use actual material offcut EDGES as the fit gauges.");

    if (calibration_carcass_fit_active) {
        echo("  carcass joinery test = ", joinery_style);
        echo("    stock thickness = ", material_thickness, " mm");
        echo("    candidate clearances = ",
             [for (o=calibration_fit_offsets)
                 calibration_coupon_value(
                     joinery_style == "tab_slot"
                         ? joint_fit_clearance
                         : dado_fit_clearance,
                     o
                 )
             ]);

        if (joinery_style == "dado")
            echo("    pocket depth = ",
                 effective_dado_depth(), " mm");
    }

    if (calibration_drawer_fit_active) {
        echo("  drawer corner joinery test = ",
             drawer_joinery_style);
        echo("    wall-stock thickness = ",
             drawer_material_thickness, " mm");
        echo("    candidate clearances = ",
             [for (o=calibration_fit_offsets)
                 calibration_coupon_value(
                     drawer_joinery_style == "tab_slot"
                         ? drawer_joint_fit_clearance
                         : drawer_dado_fit_clearance,
                     o
                 )
             ]);

        if (drawer_joinery_style == "dado")
            echo("    pocket depth = ",
                 effective_drawer_dado_depth(), " mm");
    }

    if (calibration_bottom_fit_active) {
        echo("  drawer-bottom groove test:");
        echo("    bottom-stock thickness = ",
             drawer_bottom_thickness, " mm");
        echo("    candidate clearances = ",
             [for (o=calibration_fit_offsets)
                 calibration_coupon_value(
                     drawer_dado_fit_clearance,
                     o
                 )
             ]);
        echo("    pocket depth = ",
             effective_drawer_bottom_dado_depth(), " mm");
    }

    if (calibration_wood_slide_fit_active) {
        echo("  wood-slide horizontal side-clearance test:");
        echo("    configured per-side clearance = ",
             wood_rail_side_clearance, " mm");
        echo("    runner-stock thickness = ",
             wood_drawer_runner_thickness, " mm");
        echo("    candidate per-side clearances = ",
             [for (o=calibration_slide_clearance_offsets)
                 calibration_coupon_value(
                     wood_rail_side_clearance,
                     o
                 )
             ]);
        echo("    corresponding rail/runner overlap = ",
             [for (o=calibration_slide_clearance_offsets)
                 wood_rail_thickness
                 - calibration_coupon_value(
                     wood_rail_side_clearance,
                     o
                   )
             ]);

        for (o=calibration_slide_clearance_offsets)
            if (calibration_coupon_value(
                    wood_rail_side_clearance,o)
                >= wood_rail_thickness)
                echo("WARNING: one wood-slide clearance sample removes all horizontal rail/runner overlap.");
    }

    echo("  deepest blind pocket = ",
         calibration_coupon_max_pocket_depth(), " mm");
    echo("  coupon CUT/POCKET/ENGRAVE files share one registration frame.");
}

// ---------------------------
// OUTPUT SWITCH
// ---------------------------

if (standalone_drawer_active && output_mode == "assembly") {
    standalone_drawer_assembly();
}
else if (standalone_drawer_active && output_mode == "print_layout") {
    standalone_drawer_print_layout();
}
else if (standalone_drawer_active && output_mode == "bom") {
    standalone_drawer_bom_report();
}
else if (standalone_drawer_active && output_mode == "drawers_only") {
    standalone_drawer_assembly();
}
else if (output_mode == "assembly") {
    assembly();
}
else if (output_mode == "cut_layout") {
    cut_layout();
}
else if (output_mode == "engrave_layout") {
    engrave_layout();
}
else if (output_mode == "calibration_coupon_cut") {
    calibration_coupon_cut();
}
else if (output_mode == "calibration_coupon_pocket") {
    calibration_coupon_pocket();
}
else if (output_mode == "calibration_coupon_engrave") {
    calibration_coupon_engrave();
}
else if (output_mode == "print_layout") {
    print_layout();
}
else if (output_mode == "pocket_layout") {
    pocket_layout();
}
else if (output_mode == "pocket_carcass_dados") {
    pocket_carcass_dados_layout();
}
else if (output_mode == "pocket_drawer_dados") {
    pocket_drawer_dados_layout();
}
else if (output_mode == "pocket_bottom_grooves") {
    pocket_bottom_grooves_layout();
}
else if (output_mode == "pocket_shelf_pins") {
    pocket_shelf_pins_layout();
}
else if (output_mode == "pocket_hinge_cups") {
    pocket_hinge_cups_layout();
}
else if (output_mode == "pocket_face_registration") {
    pocket_face_registration_layout();
}
else if (output_mode == "pocket_base_hardware") {
    pocket_base_hardware_layout();
}
else if (output_mode == "pocket_worktop_registration") {
    pocket_worktop_registration_layout();
}
else if (output_mode == "pocket_face_frame_dados") {
    pocket_face_frame_dados_layout();
}
else if (output_mode == "pocket_ganging") {
    pocket_ganging_layout();
}
else if (output_mode == "bom") {
    bom_report();
}
else if (output_mode == "carcass_only") {
    carcass();
}
else if (output_mode == "drawers_only") {
    all_drawers();
}
else {
    echo("Unknown output_mode.");
}
