// Shared manufacturing layouts, validation, and output switch — V10 mixed-bay core.
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
    str("B",b+1,"-D",i+1);

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
        cabinet_depth,side_panel_cut_height
    );

    engraving_label_at(
        cabinet_depth+g,0,id_side("right"),
        cabinet_depth,side_panel_cut_height
    );

    engraving_label_at(
        0,layout_y2,id_bottom(),
        bottom_panel_width,cabinet_depth
    );

    if (top_style == "full") {
        engraving_label_at(
            top_layout_x,layout_y2,id_top_full(),
            joined_w,cabinet_depth
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
        for (bb=[0:mixed_bay_count-1])
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
                            rail_x+wood_rail_depth+g;

                        engraving_label_at(
                            rail_x,row_y,
                            id_drawer_rail(bb,i,0),
                            wood_rail_depth,wood_rail_height
                        );

                        engraving_label_at(
                            rail_x,
                            row_y+wood_rail_height+g,
                            id_drawer_rail(bb,i,1),
                            wood_rail_depth,wood_rail_height
                        );

                        engraving_label_at(
                            runner_x,row_y,
                            id_drawer_runner(bb,i,0),
                            wood_drawer_runner_depth,
                            wood_drawer_runner_height
                        );

                        engraving_label_at(
                            runner_x,
                            row_y+wood_drawer_runner_height+g,
                            id_drawer_runner(bb,i,1),
                            wood_drawer_runner_depth,
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
            for (bb=[0:mixed_bay_count-1])
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


module engrave_layout() {
    stock_outline();

    // Same real registration frame as CUT/POCKET outputs.
    shared_export_bounding_box_2d();

    // Helpful in the GUI but excluded from SVG/DXF exports.
    if (show_cut_outlines_in_engrave_preview)
        %cut_layout_parts_only();

    carcass_engrave_labels();
    drawer_engrave_labels();
    door_engrave_labels();
    accessory_engrave_labels();
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
            material_thickness,cabinet_depth,side_panel_cut_height,
            full_width_bottom_active ? "sits_on_full_width_bottom" : "side");
    bom_row(id_side("right"),"carcass","CARCASS",
            material_thickness,cabinet_depth,side_panel_cut_height,
            full_width_bottom_active ? "sits_on_full_width_bottom" : "side");

    bom_row(id_bottom(),"carcass","CARCASS",
            material_thickness,bottom_panel_width,cabinet_depth,
            full_width_bottom_active ? "full_width" : joinery_style);

    if (top_style == "full")
        bom_row(id_top_full(),"carcass","CARCASS",
                material_thickness,joined_w,cabinet_depth,joinery_style);
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
        for (bb=[0:mixed_bay_count-1])
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
                            "applied"
                        );

                    if (drawer_mount == "wood_rails") {
                        bom_row(
                            id_drawer_rail(bb,i,0),
                            "drawer_rail","WOOD_RAIL",
                            wood_rail_thickness,
                            wood_rail_depth,wood_rail_height,
                            "fixed"
                        );
                        bom_row(
                            id_drawer_rail(bb,i,1),
                            "drawer_rail","WOOD_RAIL",
                            wood_rail_thickness,
                            wood_rail_depth,wood_rail_height,
                            "fixed"
                        );
                        bom_row(
                            id_drawer_runner(bb,i,0),
                            "drawer_runner","WOOD_RUNNER",
                            wood_drawer_runner_thickness,
                            wood_drawer_runner_depth,
                            wood_drawer_runner_height,
                            "drawer"
                        );
                        bom_row(
                            id_drawer_runner(bb,i,1),
                            "drawer_runner","WOOD_RUNNER",
                            wood_drawer_runner_thickness,
                            wood_drawer_runner_depth,
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
            for (bb=[0:mixed_bay_count-1])
                if (mixed_bay_is_type(bb,"door"))
                    for (leaf=[0:mixed_bay_door_count(bb)-1])
                        bom_row(
                            id_mixed_door(bb,leaf),
                            "door","DOOR",
                            door_thickness,
                            mixed_bay_door_leaf_width(bb),
                            door_face_height,
                            mixed_bay_door_leaf_hinge_side(bb,leaf)
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
                    door_hinge_side(i)
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
        translate([cabinet_depth+g,0])
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
                        0,cabinet_depth);

                    worktop_registration_support_holes_2d(
                        0,cabinet_depth);
                }
    } else {
        paint("top_front")
            translate([top_layout_x,layout_y2])
                difference() {
                    joined_horizontal_bank_receiver_cut(
                        0,top_stretcher_depth);

                    worktop_registration_support_holes_2d(
                        0,top_stretcher_depth);
                }

        paint("top_rear")
            translate([top_layout_x,
                       layout_y2+top_stretcher_depth+g])
                difference() {
                    joined_horizontal_bank_receiver_cut(
                        cabinet_depth-top_stretcher_depth,
                        top_stretcher_depth);

                    worktop_registration_support_holes_2d(
                        cabinet_depth-top_stretcher_depth,
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
                    0,shelf_depth);
    }

    // Generalized mixed-bay shelves. Each bay may choose adjustable or fixed.
    if (mixed_bay_mode && mixed_bay_total_shelf_count() > 0) {
        for (b=[0:mixed_bay_count-1])
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
                            drawer_separator_full_depth);
            } else {
                paint("drawer_separator",s)
                    translate([0,sy])
                        joined_horizontal_panel_cut(
                            drawer_separator_stretcher_actual_depth);

                paint("drawer_separator",s)
                    translate([
                        0,
                        sy+drawer_separator_stretcher_actual_depth+g
                    ])
                        joined_horizontal_panel_cut(
                            drawer_separator_stretcher_actual_depth);
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
                    runner_x = rail_x + wood_rail_depth + g;

                    paint("rail",pi)
                        translate([rail_x,row_y])
                            wood_fixed_rail_cut();
                    paint("rail",pi)
                        translate([rail_x,row_y+wood_rail_height+g])
                            wood_fixed_rail_cut();

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
            for (b=[0:mixed_bay_count-1])
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

        translate([cabinet_depth+g,-side_panel_bottom_z]) {
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
                    0,cabinet_depth);
        } else {
            translate([top_layout_x,layout_y2])
                door_hinge_partition_receiver_dado_pockets_2d(
                    0,top_stretcher_depth);

            translate([
                top_layout_x,
                layout_y2+top_stretcher_depth+g
            ])
                door_hinge_partition_receiver_dado_pockets_2d(
                    cabinet_depth-top_stretcher_depth,
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
                    0,cabinet_depth);
        } else {
            translate([top_layout_x,layout_y2])
                mixed_bay_partition_receiver_dado_pockets_2d(
                    0,top_stretcher_depth);

            translate([
                top_layout_x,
                layout_y2+top_stretcher_depth+g
            ])
                mixed_bay_partition_receiver_dado_pockets_2d(
                    cabinet_depth-top_stretcher_depth,
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
                    0,cabinet_depth);
        } else {
            translate([top_layout_x,layout_y2])
                drawer_bank_receiver_dado_pockets_2d(
                    0,top_stretcher_depth);

            translate([
                top_layout_x,
                layout_y2+top_stretcher_depth+g
            ])
                drawer_bank_receiver_dado_pockets_2d(
                    cabinet_depth-top_stretcher_depth,
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

    // Structural-back dados in the bottom and rear-reaching top member.
    // Side-panel back dados are already part of all_side_dado_pockets_2d().
    if (structural_back_active
        && joinery_style == "dado") {

        translate([0,layout_y2])
            bottom_back_receiver_dado_pockets_2d();

        if (top_style == "full") {
            translate([top_layout_x,layout_y2])
                back_horizontal_dado_pocket_2d(
                    0,cabinet_depth);
        } else {
            // Front stretcher does not reach the back and therefore receives
            // no structural-back dado.
            translate([
                top_layout_x,
                layout_y2+top_stretcher_depth+g
            ])
                back_horizontal_dado_pocket_2d(
                    cabinet_depth-top_stretcher_depth,
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

        translate([cabinet_depth+g,-side_panel_bottom_z])
            adjustable_shelf_pin_holes_pocket_2d();
    }

    if (mixed_bay_mode
        && adjustable_shelf_hole_type == "blind") {
        translate([0,-side_panel_bottom_z])
            mixed_bay_side_shelf_pin_holes_pocket_2d("left");

        translate([cabinet_depth+g,-side_panel_bottom_z])
            mixed_bay_side_shelf_pin_holes_pocket_2d("right");
    }
}

module hinge_cup_operation_geometry_2d() {
    if (has_doors && hinge_style == "euro_35mm")
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

module blind_operation_geometry_2d() {
    carcass_dado_operation_geometry_2d();
    drawer_dado_operation_geometry_2d();
    drawer_bottom_operation_geometry_2d();
    shelf_pin_operation_geometry_2d();
    hinge_cup_operation_geometry_2d();
    face_registration_operation_geometry_2d();
    base_hardware_operation_geometry_2d();
    worktop_registration_operation_geometry_2d();
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
}


module cut_layout_parts_only() {
    carcass_cut_layout();
    drawer_cut_layout();
    door_cut_layout();
    accessory_cut_layout();
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
    }
}

module door_print_part(i=0) {
    difference() {
        linear_extrude(height=door_thickness)
            door_panel_cut(i);

        if (hinge_style == "euro_35mm") {
            dw = door_each_width(i);

            for (j=[0:hinge_count-1])
                translate([
                    hinge_local_x(dw,i),
                    hinge_local_z(j),
                    door_thickness
                        - min(
                            hinge_cup_depth,
                            door_thickness-0.5
                          )
                ])
                    cylinder(
                        h=min(
                            hinge_cup_depth,
                            door_thickness-0.5
                          )+0.02,
                        d=hinge_cup_diameter
                    );
        }
    }
}

module mixed_bay_door_print_part(b=0,leaf=0) {
    difference() {
        linear_extrude(height=door_thickness)
            mixed_bay_door_panel_cut(b,leaf);

        if (hinge_style == "euro_35mm") {
            for (j=[0:hinge_count-1])
                translate([
                    mixed_bay_door_hinge_local_x(b,leaf),
                    mixed_bay_hinge_z(j)-door_face_bottom_z,
                    door_thickness
                        - min(
                            hinge_cup_depth,
                            door_thickness-0.5
                          )
                ])
                    cylinder(
                        h=min(
                            hinge_cup_depth,
                            door_thickness-0.5
                          )+0.02,
                        d=hinge_cup_diameter
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
    panel_y0,depth,receiver_face="top",door_receiver_face="same"
) {
    actual_door_face =
        door_receiver_face == "same"
            ? receiver_face
            : door_receiver_face;

    difference() {
        linear_extrude(height=material_thickness)
            joined_horizontal_bank_receiver_cut(
                panel_y0,depth);

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
            && depth == cabinet_depth)
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
        translate([cabinet_depth+g,0,0])
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
                        0,cabinet_depth,"bottom");

                    translate([0,0,-0.01])
                        linear_extrude(
                            height=material_thickness+0.02
                        )
                            worktop_registration_support_holes_2d(
                                0,cabinet_depth);
                }
    } else {
        paint("top_front")
            translate([top_layout_x,layout_y2,0])
                difference() {
                    horizontal_bank_receiver_print_part(
                        0,top_stretcher_depth,"bottom");

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
                        cabinet_depth-top_stretcher_depth,
                        top_stretcher_depth,
                        "bottom");

                    translate([0,0,-0.01])
                        linear_extrude(
                            height=material_thickness+0.02
                        )
                            worktop_registration_support_holes_2d(
                                cabinet_depth-top_stretcher_depth,
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
                    0,shelf_depth,"top","bottom");
    }

    // Generalized mixed-bay shelves.
    if (mixed_bay_mode && mixed_bay_total_shelf_count() > 0) {
        for (b=[0:mixed_bay_count-1])
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
                                drawer_separator_full_depth);
            } else {
                paint("drawer_separator",s)
                    translate([0,sy,0])
                        linear_extrude(height=material_thickness)
                            joined_horizontal_panel_cut(
                                drawer_separator_stretcher_actual_depth);

                paint("drawer_separator",s)
                    translate([
                        0,
                        sy+drawer_separator_stretcher_actual_depth+g,
                        0
                    ])
                        linear_extrude(height=material_thickness)
                            joined_horizontal_panel_cut(
                                drawer_separator_stretcher_actual_depth);
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
                    runner_x = rail_x+wood_rail_depth+g;

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
            for (b=[0:mixed_bay_count-1])
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

}


// ---------------------------
// DADO / HARDWARE POCKET LAYOUT
// ---------------------------

module pocket_operation_layout(operation="combined") {
    shared_export_bounding_box_2d();

    // Preview-only side boundaries aid orientation for side-panel operations.
    if (operation == "combined"
        || operation == "carcass_dados"
        || operation == "shelf_pins") {
        g = layout_gap;
        %square([cabinet_depth,cabinet_height]);
        translate([cabinet_depth+g,0])
            %square([cabinet_depth,cabinet_height]);
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


if (output_mode == "assembly"
    || output_mode == "carcass_only"
    || output_mode == "drawers_only") {

    echo("Assembly visibility:");
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

echo("Cabinet preset:");
echo("  preset = ", cabinet_preset);
echo("  envelope = ",
     cabinet_width, " x ",
     cabinet_height, " x ",
     cabinet_depth, " mm");
echo("  layout mode = ", cabinet_layout_mode);
if (mixed_bay_mode)
    echo("  contents = generalized mixed vertical bays");
else
    echo("  contents = ", cabinet_contents);
echo("  mount style = ", active_mount_style);
echo("  base style = ", active_base_style);
echo("  bottom width style = ",
     full_width_bottom_active ? "full_width" : "joined");

if (bottom_width_style == "full_width"
    && !full_width_bottom_active)
    echo("WARNING: full_width bottom requires a zero-height floor bottom; falling back to joined bottom for this configuration.");

if (full_width_bottom_active)
    echo("  full-width bottom = ",
         cabinet_width, " x ", cabinet_depth,
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

echo("Rear construction:");
echo("  style = ", back_style);

if (back_style == "panel") {
    echo("  applied back size = ",
         cabinet_width, " x ",
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



// ---------------------------
// BASIC VALIDATION / FEEDBACK
// ---------------------------

if (mixed_bay_mode) {
    echo("Mixed bay layout:");
    echo("  bay count = ", mixed_bay_count);
    echo("  bay types = ", mixed_bay_types);
    echo("  width weights = ", mixed_bay_width_weights);
    echo("  structural partitions = ", mixed_bay_partition_count());

    for (b=[0:mixed_bay_count-1]) {
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
                b < len(mixed_bay_door_counts)
                    ? round(mixed_bay_door_counts[b])
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

    if (mixed_bay_count > 1 && !include_mixed_bay_partitions)
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
        for (b=[0:mixed_bay_count-1])
            if (mixed_bay_is_type(b,"door")) {
                echo("  bay ", b+1,
                     " doors = ", mixed_bay_door_count(b),
                     ", leaf width = ", mixed_bay_door_leaf_width(b), " mm",
                     mixed_bay_door_count(b) == 1
                        ? str(", hinge side = ", mixed_bay_door_hinge_side(b))
                        : ", paired outward hinges");

                if (hinge_style == "euro_35mm"
                    && mixed_bay_door_leaf_width(b)
                       < 2*hinge_cup_center_from_door_edge
                         + hinge_cup_diameter)
                    echo("WARNING: Door leaf in mixed bay ", b+1,
                         " is narrow relative to the configured Euro hinge cup geometry.");
            }
    }
    else {
        echo("  width weights = ", door_width_weights);

        for (i=[0:door_count-1]) {
            echo("  door ", i+1,
                 " width = ", door_each_width(i), " mm");

            if (hinge_style == "euro_35mm"
                && door_each_width(i)
                   < 2*hinge_cup_center_from_door_edge
                     + hinge_cup_diameter)
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
    echo("  cabinet-depth edge tabs = ", effective_tab_count(cabinet_depth));
    echo("  shelf-depth edge tabs   = ", effective_tab_count(shelf_depth));
    echo("  top-stretcher edge tabs = ", effective_tab_count(top_stretcher_depth));
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




if (fronts_cover_bottom_lip) {
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
         wood_rail_depth, " x ",
         wood_rail_height, " x ",
         wood_rail_thickness, " mm");
    echo("  drawer runner size = ",
         wood_drawer_runner_depth, " x ",
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




if (front_width_style == "full_overlay") {
    echo("Fronts use full-overlay width:");
    echo("  left X = ", front_panel_x, " mm");
    echo("  total front width = ", front_panel_width, " mm");
}

if (door_hinge_partition_count() > 0 && hinge_style == "none") {
    echo("Door partitions:");
    echo("  count = ", door_hinge_partition_count());
    echo("  front-to-back depth = ", door_hinge_partition_actual_depth, " mm");
    echo("  joinery follows carcass = ", joinery_style);
}

if (has_doors && hinge_style != "none") {
    echo("Door hinge hardware:");
    echo("  style = ", hinge_style);
    echo("  hinge count = ", hinge_count);

    if (hinge_style == "euro_35mm") {
        echo("  cup = ", hinge_cup_diameter,
             " mm diameter x ", hinge_cup_depth, " mm deep");
        echo("  export pocket_layout for blind cup pockets");
    }

    echo("  cabinet plate line = ",
         hinge_plate_center_from_front, " mm from front");

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

    for (b=[0:mixed_bay_count-1])
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
     || output_mode == "pocket_worktop_registration")
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
         hinge_cup_depth, " mm");

if (output_mode == "pocket_face_registration")
    echo("Pocket operation: drawer-face registration, depth = ",
         drawer_face_registration_blind_depth(), " mm");


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

if (output_mode == "assembly") {
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
