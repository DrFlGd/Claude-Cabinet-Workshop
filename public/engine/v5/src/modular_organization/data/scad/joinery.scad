// Dynamic material context follows the part being cut, including nested exports.
function machining_material() = is_undef($machining_material) ? "carcass" : $machining_material;
function material_relief_value(part) =
 part=="drawer" ? (is_undef(drawer_slot_corner_relief)?"inherit":drawer_slot_corner_relief) :
 part=="divider" ? (is_undef(divider_slot_corner_relief)?"inherit":divider_slot_corner_relief) :
 part=="drawer_bottom" ? (is_undef(drawer_bottom_slot_corner_relief)?"none":drawer_bottom_slot_corner_relief) :
 (is_undef(carcass_slot_corner_relief)?"inherit":carcass_slot_corner_relief);
function material_tool_value(part) =
 part=="drawer" ? (is_undef(drawer_cnc_tool_diameter)?0:drawer_cnc_tool_diameter) :
 part=="divider" ? (is_undef(divider_cnc_tool_diameter)?0:divider_cnc_tool_diameter) :
 part=="drawer_bottom" ? (is_undef(drawer_bottom_cnc_tool_diameter)?0:drawer_bottom_cnc_tool_diameter) :
 (is_undef(carcass_cnc_tool_diameter)?0:carcass_cnc_tool_diameter);
function effective_slot_relief() = let(r=material_relief_value(machining_material())) r=="inherit"?slot_corner_relief:r;
function effective_slot_tool_diameter() = let(d=material_tool_value(machining_material())) d>0?d:cnc_tool_diameter;

// Verbatim reusable tab-spacing and open-edge slot-relief primitives from core_v4.
function slot_relief_is_dogbone() =
    effective_slot_relief() == "dogbone";

function slot_relief_is_tbone() =
    effective_slot_relief() == "t_bone"
    || effective_slot_relief() == "tbone"
    || effective_slot_relief() == "t-bone";

function slot_relief_is_active() =
    (slot_relief_is_dogbone() || slot_relief_is_tbone())
    && effective_slot_tool_diameter() > 0;

function slot_relief_radius() =
    max(0,effective_slot_tool_diameter()/2);

function slot_dogbone_inset() =
    slot_relief_radius()/sqrt(2);


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
                        circle(d=effective_slot_tool_diameter());
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


