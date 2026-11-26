// Blind tab-in-pocket joinery primitives.
//
// Shared, argument-driven helpers: nothing here reads a cabinet setting, so any
// cabinet type or product can use them. Units are millimetres.
//
// A blind tab joint is a tab on one part (the male part) that stops inside a
// pocket milled into the inside face of the other part (the receiver), instead
// of passing through it. The receiver's outside face stays unbroken. A pocket
// that reaches the receiver's edge is open on that side, so the male part can
// be dropped in from that direction. The construction follows CNC furniture
// plans for stackable workshop cabinets: in 18 mm sheet the pockets are 14 mm
// deep (4 mm of the outside face left), the tabs 13 mm long (1 mm short of the
// pocket floor), and the router's round corners are relieved on both parts:
//
//   - receiver: relief circles at the pocket's closed inside corners, so the
//     square corners of the tab reach the corners of the pocket;
//   - male part: "T-bone" relief circles on the shoulder line beside each tab
//     root, so the shoulder seats against the sharp mouth of the pocket rather
//     than standing off it on the cutter's fillet.
//
// Layouts are 2D in the part's own plane; extrude them for 3D models.

// Depth of a blind pocket in a receiver of thickness t that leaves `skin` of
// the outside face. Always leaves at least 0.5 mm and removes at least 0.5 mm.
function tp_pocket_depth(t,skin) =
    max(0.5,min(t-0.5,t-max(0,skin)));

// Tab length for that pocket, stopping `end_clearance` short of its floor.
function tp_tab_length(t,skin,end_clearance) =
    max(0.5,tp_pocket_depth(t,skin)-max(0,end_clearance));

// Relief circle centres for a rectangular pocket [0,w] x [0,h].
// relief: "none" | "dogbone" | "t_bone". open = [left,right,bottom,top]: a
// corner with an open wall is not relieved (the cutter already passes it).
// T-bone reliefs run along the pocket's longer wall.
function tp_pocket_relief_centres(w,h,tool_d,relief="t_bone",open=[false,false,false,false]) =
    let(r=tool_d/2,d=r/sqrt(2))
    relief == "none" || tool_d <= 0 ? [] : [
        for (ix=[0:1]) for (iy=[0:1])
            if (!open[ix] && !open[2+iy])
                let(
                    cx=ix == 0 ? 0 : w,
                    cy=iy == 0 ? 0 : h,
                    sx=ix == 0 ? 1 : -1,
                    sy=iy == 0 ? 1 : -1
                )
                relief == "dogbone" ? [cx+sx*d,cy+sy*d]
                : w >= h ? [cx+sx*r,cy] : [cx,cy+sy*r]
    ];

// Pocket (or through slot) outline with corner reliefs.
module tp_pocket_2d(w,h,tool_d,relief="t_bone",open=[false,false,false,false]) {
    union() {
        square([w,h]);
        for (c=tp_pocket_relief_centres(w,h,tool_d,relief,open))
            translate(c) circle(d=tool_d);
    }
}

// Shoulder reliefs for one tab on the male part. The tab spans [x0,x0+w]
// along the shoulder line y = y_shoulder. Each relief circle has the cutter's
// radius and sits on the shoulder line just outside the tab, so it passes
// through the sharp root corner and the shoulder seats on the pocket mouth.
// Subtract the result from the male part.
module tp_tab_root_reliefs_2d(x0,w,y_shoulder,tool_d) {
    if (tool_d > 0) {
        r = tool_d/2;
        for (cx=[x0-r,x0+w+r])
            translate([cx,y_shoulder])
                circle(r=r);
    }
}

// Centres of the gaps beside and between tabs on a joint of length `span`,
// for screw or pilot holes. `starts` are the tab start positions (ascending)
// and `w` the tab width; a gap shorter than `min_gap` gets no hole.
function tp_web_centres(span,starts,w,min_gap) =
    let(
        n=len(starts),
        a=concat([0],[for (s=starts) s+w]),
        b=concat([for (s=starts) s],[span])
    )
    [for (i=[0:n]) if (b[i]-a[i] >= min_gap) (a[i]+b[i])/2];
