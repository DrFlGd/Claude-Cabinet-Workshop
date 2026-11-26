// Stacking locator primitives.
//
// Shared, argument-driven helpers: nothing here reads a cabinet setting, so any
// cabinet type or product whose boxes stack can use them. Units are millimetres.
//
// Two boxes locate on each other through their sides. The top edge of each
// lower side has a recess between two raised "ears"; the bottom edge of each
// upper side has the matching tongue, with its front and rear ends relieved.
// The tongue drops into the recess, which locates the boxes front to back; a
// bottom panel set between the lower box's top rails (see sl_nested_span)
// locates them side to side as well. Both edges come from one transition
// profile, so male and female always match; the female is then grown by the
// fit clearance with a true 2D offset.
//
// A transition runs from the HIGH level (an ear) down to the LOW level (the
// recess floor or the tongue's underside) over a horizontal run along the
// depth. Two flank shapes are available:
//
//   s_curve    two tangent quarter-circle fillets of radius r with a vertical
//              tangent between them (none when r = d/2). Run = 2 r.
//   chamfer_45 a straight 45-degree flank between two 45-degree fillets of
//              radius r, as in CNC stackable-cabinet plans (r = 15 mm in 18 mm
//              sheet). It is self-centring: a tongue set down slightly off
//              position slides into place. Run = d + (2 sqrt 2 - 2) r.
//
// Coordinates are 2D in the side's own plane: X along the depth (0 = front),
// Y up.

// Horizontal run of one transition of depth d.
function sl_flank_run(d,r,flank="s_curve") =
    flank == "chamfer_45"
        ? d+(2*sqrt(2)-2)*r
        : 2*r;

// Largest fillet radius that still fits a transition of depth d.
function sl_flank_max_radius(d,flank="s_curve") =
    flank == "chamfer_45"
        ? d/(2-sqrt(2))
        : d/2;

// Largest radius whose two transitions fit a recess or tongue span `span`
// with `gap` left between them.
function sl_flank_max_radius_for_span(d,span,flank="s_curve",gap=2) =
    flank == "chamfer_45"
        ? max(1,(span/2-gap/2-d)/(2*sqrt(2)-2))
        : max(1,span/4-gap/4);

// Horizontal shift of the flank at mid-height when the female is grown by a
// clearance c (offset perpendicular to the flank).
function sl_flank_mid_clearance_shift(c,flank="s_curve") =
    flank == "chamfer_45" ? c*sqrt(2) : c;

function sl_arc_points(cx,cz,r,a0,a1,segments=12) = [
    for (i=[0:segments])
        let(a=a0+(a1-a0)*i/segments)
            [cx+r*cos(a),cz+r*sin(a)]
];

// FRONT transition, returned HIGH -> LOW: it leaves the high level y = z0+d at
// x = x0 and reaches the low level y = z0 at x = x0 + sl_flank_run(...).
function sl_flank_points(x0,z0,d,r,flank="s_curve",segments=12) =
    flank == "chamfer_45"
        ? let(
            s=max(2,round(segments/2)),
            xc2=x0+d+(2*sqrt(2)-2)*r
          )
          concat(
              sl_arc_points(x0,z0+d-r,r,90,45,s),
              sl_arc_points(xc2,z0+r,r,225,270,s)
          )
        : concat(
              sl_arc_points(x0,z0+d-r,r,90,0,segments),
              [[x0+r,z0+r]],
              sl_arc_points(x0+2*r,z0+r,r,180,270,segments)
          );

// REAR transition of a part `depth` deep, the mirror of the front one about
// the depth's centre, returned LOW -> HIGH.
function sl_rear_flank_points(depth,margin,z0,d,r,flank="s_curve",segments=12) =
    let(fp=sl_flank_points(margin,z0,d,r,flank,segments))
    [for (i=[len(fp)-1:-1:0]) [depth-fp[i][0],fp[i][1]]];

// Female recess in the top edge (at y = top_z) of a side `depth` deep, before
// clearance: ears of front_margin and back_margin, floor d below the top.
module sl_recess_nominal_2d(depth,top_z,d,r,front_margin,back_margin,flank="s_curve",segments=12) {
    z0 = top_z-d;
    polygon(concat(
        sl_flank_points(front_margin,z0,d,r,flank,segments),
        sl_rear_flank_points(depth,back_margin,z0,d,r,flank,segments),
        [[depth-back_margin,top_z+2],[front_margin,top_z+2]]
    ));
}

// The recess to cut, grown by the fit clearance c.
module sl_recess_2d(depth,top_z,d,r,front_margin,back_margin,c=0,flank="s_curve",segments=12) {
    if (c > 0)
        offset(delta=c)
            sl_recess_nominal_2d(depth,top_z,d,r,front_margin,back_margin,flank,segments);
    else
        sl_recess_nominal_2d(depth,top_z,d,r,front_margin,back_margin,flank,segments);
}

// Front relief at the bottom edge (y = 0) of an upper side, leaving the tongue.
module sl_tongue_front_relief_2d(margin,d,r,flank="s_curve",segments=12) {
    fp = sl_flank_points(margin,0,d,r,flank,segments);
    low = fp[len(fp)-1];
    polygon(concat(
        [[-2,-2],[low[0],-2]],
        [for (i=[len(fp)-1:-1:0]) fp[i]],
        [[-2,d]]
    ));
}

// Both reliefs of a side `depth` deep: what to remove to leave the tongue.
module sl_tongue_reliefs_2d(depth,d,r,front_margin,back_margin,flank="s_curve",segments=12) {
    sl_tongue_front_relief_2d(front_margin,d,r,flank,segments);
    translate([depth,0])
        mirror([1,0,0])
            sl_tongue_front_relief_2d(back_margin,d,r,flank,segments);
}

// Depth range over which the tongue has its full height.
function sl_tongue_full_range(depth,d,r,front_margin,back_margin,flank="s_curve") =
    let(run=sl_flank_run(d,r,flank))
    [front_margin+run,depth-back_margin-run];

// Nested bottom: the depth range [y0, y1] of a bottom panel that drops between
// the lower box's front and rear top rails (rail_front, rail_back deep), with
// clearance c to each rail.
function sl_nested_span(depth,rail_front,rail_back,c=0) =
    [rail_front+max(0,c),depth-rail_back-max(0,c)];

// Depths of the screw holes that fix a nested bottom to the box below: one
// through each lower ear, between the rail's end (span_y0 = the bottom's
// front edge) and the recess flank, at mid-height of the interface. hole_d is
// the hole diameter; 2 mm of material is kept around each hole.
function sl_link_screw_ys(depth,span_y0,d,r,front_margin,back_margin,c,hole_d,flank="s_curve") =
    let(
        lo=span_y0+hole_d/2+2,
        shift=sl_flank_mid_clearance_shift(c,flank),
        half=sl_flank_run(d,r,flank)/2,
        fhi=front_margin+half-shift-hole_d/2-2,
        bhi=back_margin+half-shift-hole_d/2-2
    )
    [
        if (fhi >= lo) (lo+fhi)/2,
        if (bhi >= lo) depth-(lo+bhi)/2
    ];
