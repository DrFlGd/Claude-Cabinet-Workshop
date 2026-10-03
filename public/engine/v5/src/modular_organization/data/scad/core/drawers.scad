module drawer_side_tab_slots_2d(d,bh) {
    $machining_material = "drawer";
    if (drawer_joint_geometry == "tab_slot") {
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
    $machining_material = "drawer";
    if (drawer_joint_geometry == "dado") {
        c = drawer_dado_fit_clearance;
        st = drawer_material_thickness;

        translate([-c/2,-c/2])
            square([st+c,bh+c]);

        translate([d-st-c/2,-c/2])
            square([st+c,bh+c]);
    }
}

module drawer_side_bottom_groove_pocket_2d(d,bh) {
    $machining_material = "drawer";
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
    $machining_material = "drawer";
    drawer_side_corner_dado_pockets_2d(d,bh);
    drawer_side_bottom_groove_pocket_2d(d,bh);
}

// Blind bottom groove in a drawer front/back panel, local width/height.
module drawer_cross_panel_bottom_pocket_2d(bh,b=0) {
    $machining_material = "drawer";
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
    $machining_material = "drawer";
    c = drawer_dado_fit_clearance;
    st = drawer_material_thickness;

    if (drawer_joint_geometry == "dado") {
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
    $machining_material = "drawer";
    if (drawer_joint_geometry == "tab_slot") {
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



// Screw pilot guides for drawer front/back edges. Geometry shared by CUT and 3D.
function drawer_screw_low(bh) = max(drawer_screw_edge_margin,
    drawer_bottom_joinery=="dado" ? drawer_bottom_inset+drawer_bottom_thickness+drawer_screw_hole_diameter/2+2 : drawer_screw_edge_margin);
function drawer_screw_heights(bh) = let(lo=drawer_screw_low(bh), hi=bh-drawer_screw_edge_margin)
    hi-lo>=drawer_screw_hole_diameter+4 ? [lo,hi] : [(lo+hi)/2];
module drawer_screw_check(bh) {
    $machining_material = "drawer";
    if(drawer_joinery_style=="screw" && (drawer_screw_hole_diameter<=0 || drawer_screw_edge_margin<drawer_screw_hole_diameter ||
       bh-drawer_screw_edge_margin<drawer_screw_low(bh)))
        echo("CHECK|ERROR|DRAWER_SCREW_MARGIN|Drawer screw guides do not fit the panel height or bottom groove");
}
module drawer_screw_guides_2d(d,bh) {
    $machining_material = "drawer";
    drawer_screw_check(bh);
    if(drawer_joinery_style=="screw") for(y=[drawer_material_thickness/2,d-drawer_material_thickness/2])
        for(z=drawer_screw_heights(bh)) round_hole_2d(y,z,drawer_screw_hole_diameter);
}
module drawer_screw_guides_3d(x0,y0,z0,d,bh) {
    $machining_material = "drawer";
    drawer_screw_check(bh);
    if(drawer_joinery_style=="screw") for(y=[drawer_material_thickness/2,d-drawer_material_thickness/2])
        for(z=drawer_screw_heights(bh)) round_hole_x_3d(x0-1,y0+y,z0+z,drawer_material_thickness+2,drawer_screw_hole_diameter);
}

// ---------- Drawer side panel ----------

module drawer_side_panel_3d(x0,y0,z0,d,bh,i=0,side="left",b=0) {
    $machining_material = "drawer";
    st = drawer_material_thickness;

    difference() {
        translate([x0,y0,z0]) cube([st,d,bh]);

        drawer_side_through_joinery_3d(
            x0,y0,z0,d,bh);
        drawer_screw_guides_3d(x0,y0,z0,d,bh);

        drawer_side_blind_joinery_3d(
            x0,y0,z0,d,bh,side);

        drawer_divider_side_perimeter_grooves_3d(
            x0,y0,z0,d,bh,b,i,side);

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
    $machining_material = "drawer";
    difference() {
        cut_part(d,bh);

        drawer_side_tab_slots_2d(d,bh);
        drawer_screw_guides_2d(d,bh);

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
    $machining_material = "drawer";
    st = drawer_material_thickness;
    iw = drawer_inner_width(b);
    ow = drawer_outer_width(b);

    difference() {
        if (drawer_joint_geometry == "butt") {
            cut_part(iw,bh);
        }
        else if (drawer_joint_geometry == "dado") {
            cut_part(
                iw+2*effective_drawer_dado_depth(),
                bh
            );
        }
        else if (drawer_joint_geometry == "tab_slot") {
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
    x0,y_panel,z0,bh,is_front=true,b=0,i=0
) {
    $machining_material = "drawer";
    st = drawer_material_thickness;
    iw = drawer_inner_width(b);
    ow = drawer_outer_width(b);
    dd = effective_drawer_dado_depth();

    difference() {
        union() {
            if (drawer_joint_geometry == "butt") {
                sheet_box(
                    [iw,st,bh],
                    [x0+st,y_panel,z0]
                );
            }
            else if (drawer_joint_geometry == "dado") {
                sheet_box(
                    [iw+2*dd,st,bh],
                    [x0+st-dd,y_panel,z0]
                );
            }
            else if (drawer_joint_geometry == "tab_slot") {
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

        drawer_divider_cross_perimeter_grooves_3d(
            x0,y_panel,z0,bh,is_front,b,i);

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



// ---------- Drawer divider-grid geometry ----------

// Flat divider profile.  The extra bottom extension is the tongue that enters
// a locating groove in the drawer bottom.  Interlocking slots are cut through
// half the profile from alternating top/bottom directions.
module drawer_divider_longitudinal_cut(b=0,i=0,n=0) {
    $machining_material = "divider";
    l = drawer_divider_longitudinal_length();
    h = drawer_divider_part_height();
    pd = drawer_divider_perimeter_extension();
    nw = drawer_divider_interlock_width();
    nd = drawer_divider_interlock_depth();
    top_slot = drawer_divider_interlock_orientation == "longitudinal_top";

    difference() {
        cut_part(l,h);
        for (j=[0:max(0,drawer_divider_y_count()-1)])
            if (drawer_divider_y_count() > 0) {
                cx = pd + drawer_divider_y_position(j);
                translate([
                    cx-nw/2,
                    top_slot ? h-nd : -0.01
                ])
                    slot_shape_2d(
                        nw,nd+0.02,
                        false,false,
                        !top_slot,top_slot
                    );
            }
    }
}

module drawer_divider_transverse_cut(b=0,i=0,n=0) {
    $machining_material = "divider";
    l = drawer_divider_transverse_length(b);
    h = drawer_divider_part_height();
    pd = drawer_divider_perimeter_extension();
    nw = drawer_divider_interlock_width();
    nd = drawer_divider_interlock_depth();
    top_slot = drawer_divider_interlock_orientation == "transverse_top";

    difference() {
        cut_part(l,h);
        for (j=[0:max(0,drawer_divider_x_count()-1)])
            if (drawer_divider_x_count() > 0) {
                cx = pd + drawer_divider_x_position(b,j);
                translate([
                    cx-nw/2,
                    top_slot ? h-nd : -0.01
                ])
                    slot_shape_2d(
                        nw,nd+0.02,
                        false,false,
                        !top_slot,top_slot
                    );
            }
    }
}

// Bottom-panel pocket geometry in the bottom's own width/depth coordinates.
module drawer_divider_bottom_grooves_2d(b=0,i=0) {
    $machining_material = "drawer_bottom";
    if (drawer_divider_active_for(b,i)
        && drawer_divider_bottom_capture_active()) {
        off = drawer_divider_bottom_inner_offset();
        gw = drawer_divider_groove_width();
        iw = drawer_inner_width(b);
        id = drawer_inner_depth();

        for (n=[0:max(0,drawer_divider_x_count()-1)])
            if (drawer_divider_x_count() > 0)
                translate([
                    off+drawer_divider_x_position(b,n)-gw/2,
                    off
                ])
                    slot_shape_2d(gw,id);

        for (n=[0:max(0,drawer_divider_y_count()-1)])
            if (drawer_divider_y_count() > 0)
                translate([
                    off,
                    off+drawer_divider_y_position(n)-gw/2
                ])
                    slot_shape_2d(iw,gw);
    }
}

// Side-wall pocket geometry. Local X is drawer depth, local Y is height.
// Only transverse dividers terminate in left/right sides.
module drawer_divider_side_perimeter_grooves_2d(d,bh,b=0,i=0) {
    $machining_material = "drawer";
    if (drawer_divider_active_for(b,i)
        && drawer_divider_perimeter_capture_active()) {
        gw = drawer_divider_groove_width();
        zf = drawer_divider_floor_z_local();
        for (n=[0:max(0,drawer_divider_y_count()-1)])
            if (drawer_divider_y_count() > 0)
                translate([
                    drawer_material_thickness+drawer_divider_y_position(n)-gw/2,
                    zf
                ])
                    square([gw,max(0.1,drawer_divider_height)]);
    }
}

// Front/back-wall pocket geometry. Local X is panel width, local Y is height.
// Only longitudinal dividers terminate in the front/back panels.
module drawer_divider_cross_perimeter_grooves_2d(bh,b=0,i=0) {
    $machining_material = "drawer";
    if (drawer_divider_active_for(b,i)
        && drawer_divider_perimeter_capture_active()) {
        gw = drawer_divider_groove_width();
        zf = drawer_divider_floor_z_local();
        xoff = drawer_cross_panel_inner_x_offset();
        for (n=[0:max(0,drawer_divider_x_count()-1)])
            if (drawer_divider_x_count() > 0)
                translate([
                    xoff+drawer_divider_x_position(b,n)-gw/2,
                    zf
                ])
                    square([gw,max(0.1,drawer_divider_height)]);
    }
}

module drawer_divider_side_perimeter_grooves_3d(x0,y0,z0,d,bh,b=0,i=0,side="left") {
    $machining_material = "drawer";
    if (drawer_divider_active_for(b,i)
        && drawer_divider_perimeter_capture_active()) {
        gw = drawer_divider_groove_width();
        pd = effective_drawer_divider_perimeter_groove_depth();
        st = drawer_material_thickness;
        cut_x = side == "left" ? x0+st-pd-0.01 : x0-0.01;
        for (n=[0:max(0,drawer_divider_y_count()-1)])
            if (drawer_divider_y_count() > 0)
                translate([
                    cut_x,
                    y0+st+drawer_divider_y_position(n)-gw/2,
                    z0+drawer_divider_floor_z_local()
                ])
                    cube([pd+0.02,gw,max(0.1,drawer_divider_height)]);
    }
}

module drawer_divider_cross_perimeter_grooves_3d(x0,y_panel,z0,bh,is_front=true,b=0,i=0) {
    $machining_material = "drawer";
    if (drawer_divider_active_for(b,i)
        && drawer_divider_perimeter_capture_active()) {
        gw = drawer_divider_groove_width();
        pd = effective_drawer_divider_perimeter_groove_depth();
        st = drawer_material_thickness;
        cut_y = is_front ? y_panel+st-pd-0.01 : y_panel-0.01;
        for (n=[0:max(0,drawer_divider_x_count()-1)])
            if (drawer_divider_x_count() > 0)
                translate([
                    x0+st+drawer_divider_x_position(b,n)-gw/2,
                    cut_y,
                    z0+drawer_divider_floor_z_local()
                ])
                    cube([gw,pd+0.02,max(0.1,drawer_divider_height)]);
    }
}

module drawer_divider_bottom_grooves_3d(x0,y0,z0,b=0,i=0) {
    $machining_material = "drawer_bottom";
    if (drawer_divider_active_for(b,i)
        && drawer_divider_bottom_capture_active()) {
        gw = drawer_divider_groove_width();
        gd = effective_drawer_divider_bottom_groove_depth();
        st = drawer_material_thickness;
        iw = drawer_inner_width(b);
        id = drawer_inner_depth();
        topz = z0+drawer_bottom_inset+drawer_bottom_thickness;

        for (n=[0:max(0,drawer_divider_x_count()-1)])
            if (drawer_divider_x_count() > 0)
                translate([
                    x0+st+drawer_divider_x_position(b,n)-gw/2,
                    y0+st,
                    topz-gd-0.01
                ])
                    linear_extrude(height=gd+0.02) slot_shape_2d(gw,id);

        for (n=[0:max(0,drawer_divider_y_count()-1)])
            if (drawer_divider_y_count() > 0)
                translate([
                    x0+st,
                    y0+st+drawer_divider_y_position(n)-gw/2,
                    topz-gd-0.01
                ])
                    linear_extrude(height=gd+0.02) slot_shape_2d(iw,gw);
    }
}

module drawer_divider_grid_3d(x0,y0,z0,bh,b=0,i=0) {
    $machining_material = "drawer";
    if (drawer_divider_active_for(b,i)) {
        t = drawer_divider_thickness_resolved();
        pd = drawer_divider_perimeter_extension();
        be = drawer_divider_bottom_extension();
        ph = drawer_divider_part_height();
        nd = drawer_divider_interlock_depth();
        nw = drawer_divider_interlock_width();
        basez = z0+drawer_divider_floor_z_local()-be;
        long_top = drawer_divider_interlock_orientation == "longitudinal_top";

        // Front-to-back dividers.
        for (n=[0:max(0,drawer_divider_x_count()-1)])
            if (drawer_divider_x_count() > 0) {
                xc = x0+drawer_material_thickness+drawer_divider_x_position(b,n);
                difference() {
                    translate([xc-t/2,y0+drawer_material_thickness-pd,basez])
                        cube([t,drawer_divider_longitudinal_length(),ph]);
                    for (j=[0:max(0,drawer_divider_y_count()-1)])
                        if (drawer_divider_y_count() > 0) {
                            yc = y0+drawer_material_thickness+drawer_divider_y_position(j);
                            translate([
                                xc-t/2-0.02,
                                yc-nw/2,
                                long_top ? basez+ph-nd : basez-0.01
                            ])
                                cube([t+0.04,nw,nd+0.02]);
                        }
                }
            }

        // Left-to-right dividers.
        for (n=[0:max(0,drawer_divider_y_count()-1)])
            if (drawer_divider_y_count() > 0) {
                yc = y0+drawer_material_thickness+drawer_divider_y_position(n);
                difference() {
                    translate([x0+drawer_material_thickness-pd,yc-t/2,basez])
                        cube([drawer_divider_transverse_length(b),t,ph]);
                    for (j=[0:max(0,drawer_divider_x_count()-1)])
                        if (drawer_divider_x_count() > 0) {
                            xc = x0+drawer_material_thickness+drawer_divider_x_position(b,j);
                            translate([
                                xc-nw/2,
                                yc-t/2-0.02,
                                long_top ? basez-0.01 : basez+ph-nd
                            ])
                                cube([nw,t+0.04,nd+0.02]);
                        }
                }
            }
    }
}

// ---------- Drawer bottom ----------

module drawer_bottom_3d(x0,y0,z0,b=0,i=0) {
    $machining_material = "drawer_bottom";
    bdd =
        drawer_bottom_joinery == "dado"
            ? effective_drawer_bottom_dado_depth()
            : 0;

    difference() {
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
        drawer_divider_bottom_grooves_3d(x0,y0,z0,b,i);
    }
}

module drawer_bottom_cut(b=0) {
    $machining_material = "drawer_bottom";
    cut_part(
        drawer_bottom_width(b),
        drawer_bottom_depth()
    );
}


// ---------- Flat blind-pocket helpers for CAM / print layout ----------

module drawer_side_print_part(d,bh,i=0,b=0) {
    $machining_material = "drawer";
    difference() {
        linear_extrude(height=drawer_material_thickness)
            drawer_side_panel_cut(d,bh,i);

        if (drawer_joint_geometry == "dado"
            || drawer_bottom_joinery == "dado") {

            translate([
                0,0,
                drawer_material_thickness
                    - max(
                        drawer_joint_geometry == "dado"
                            ? effective_drawer_dado_depth()
                            : 0,
                        drawer_bottom_joinery == "dado"
                            ? effective_drawer_bottom_dado_depth()
                            : 0
                    )
            ])
                linear_extrude(
                    height=max(
                        drawer_joint_geometry == "dado"
                            ? effective_drawer_dado_depth()
                            : 0,
                        drawer_bottom_joinery == "dado"
                            ? effective_drawer_bottom_dado_depth()
                            : 0
                    ) + 0.02
                )
                    drawer_side_dado_pockets_2d(d,bh);
        }

        if (drawer_divider_active_for(b,i)
            && drawer_divider_perimeter_capture_active()) {
            pd = effective_drawer_divider_perimeter_groove_depth();
            translate([0,0,drawer_material_thickness-pd])
                linear_extrude(height=pd+0.02)
                    drawer_divider_side_perimeter_grooves_2d(d,bh,b,i);
        }
    }
}

// Uses a single print-face orientation for blind bottom/divider grooves.
module drawer_cross_panel_print_part(bh,is_front=false,b=0,i=0) {
    $machining_material = "drawer";
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

        if (drawer_divider_active_for(b,i)
            && drawer_divider_perimeter_capture_active()) {
            pd = effective_drawer_divider_perimeter_groove_depth();
            translate([0,0,drawer_material_thickness-pd])
                linear_extrude(height=pd+0.02)
                    drawer_divider_cross_perimeter_grooves_2d(bh,b,i);
        }
    }
}

module drawer_bottom_print_part(b=0,i=0) {
    $machining_material = "drawer_bottom";
    difference() {
        linear_extrude(height=drawer_bottom_thickness)
            drawer_bottom_cut(b);

        if (drawer_divider_active_for(b,i)
            && drawer_divider_bottom_capture_active()) {
            gd = effective_drawer_divider_bottom_groove_depth();
            translate([0,0,drawer_bottom_thickness-gd])
                linear_extrude(height=gd+0.02)
                    drawer_divider_bottom_grooves_2d(b,i);
        }
    }
}


// ---------- Drawer dado pocket layout ----------

module drawer_joinery_dado_pocket_layout() {
    $machining_material = "drawer";
    if (has_drawers && drawer_joint_geometry == "dado") {
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
    $machining_material = "drawer";
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
    $machining_material = "drawer";
    drawer_joinery_dado_pocket_layout();
    drawer_bottom_groove_pocket_layout();
}


// Drawer-mounted portion of the two-piece wooden slide.
// This is intentionally separate from drawer_box() so it can be grouped with
// the drawer in every drawer-only display mode, even when drawer boxes are
// hidden and only drawer fronts are being previewed.
module drawer_mounted_wood_slides(i=0,b=0) {
    $machining_material = "drawer";
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
    $machining_material = "drawer";
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
    $machining_material = "drawer";
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
    $machining_material = "drawer";
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
    $machining_material = "drawer";
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
    $machining_material = "drawer";
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
                x0-explode,y0,z0,d,bh,i,"left",b);

        paint("drawer_side_r",pi)
            drawer_side_panel_3d(
                x0+ow-st+explode,y0,z0,d,bh,i,"right",b);
    }

    if (show_drawer_box_front_back) {
        paint("drawer_box_front",pi)
            drawer_cross_panel_3d(
                x0,y0,z0,bh,true,b,i);

        paint("drawer_box_back",pi)
            drawer_cross_panel_3d(
                x0,y0+d-st,z0,bh,false,b,i);
    }

    if (show_drawer_bottoms)
        paint("drawer_bottom",pi)
            drawer_bottom_3d(x0,y0,z0,b,i);

    if (show_drawer_dividers && drawer_divider_active_for(b,i))
        paint("drawer_divider",pi)
            drawer_divider_grid_3d(x0,y0,z0,bh,b,i);

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
    z0 = mixed_bay_door_bottom_z(b);

    difference() {
        sheet_box(
            [dw,door_thickness,mixed_bay_door_height(b)],
            [x0,decorative_front_y(door_thickness),z0]
        );

        if (effective_hinge_style != "none") {
            hx = x0 + mixed_bay_door_hinge_local_x(b,leaf);

            for (j=[0:hinge_count-1]) {
                hz = mixed_bay_hinge_z(j,b);

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
            hz = z0 + mixed_bay_door_handle_local_z(b);

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
        cut_part(dw,mixed_bay_door_height(b));

        if (effective_hinge_style != "none") {
            hx = mixed_bay_door_hinge_local_x(b,leaf);

            for (j=[0:hinge_count-1]) {
                hz = mixed_bay_hinge_z(j,b)-mixed_bay_door_bottom_z(b);

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
            hz = mixed_bay_door_handle_local_z(b);

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
            for (b=[0:layout_bay_count-1])
                if (mixed_bay_is_type(b,"door"))
                    for (leaf=[0:mixed_bay_door_count(b)-1]) {
                        door_layout_x = mixed_bay_door_layout_x(b,leaf);
                        hx = door_layout_x
                             + mixed_bay_door_hinge_local_x(b,leaf);

                        for (j=[0:hinge_count-1])
                            round_hole_2d(
                                hx,
                                door_layout_y
                                    + mixed_bay_hinge_z(j,b)
                                    - mixed_bay_door_bottom_z(b),
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
            for (b=[0:layout_bay_count-1])
                if (mixed_bay_is_type(b,"door") && mixed_bay_door_height(b) > 20)
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


