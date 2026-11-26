// Seam joinery: tabs, matching through slots and flanking screws along a seam
// between two panels, for any cabinet type or product. Units are millimetres.
//
// A seam is the line where the edge of one panel (the member) meets the face of
// another (the host). It is measured along its length from 0 and broken into the
// segments where both panels have material and nothing else is in the way (keep-
// outs are removed with sj_cut_all). The tabs of each segment come from the core
// tab planner in joinery.scad (effective_tab_count, tab_width_for, tab_center,
// which read the shared settings joint_tab_width, joint_tab_edge_margin,
// target_tab_spacing, minimum_joint_web, tab_count_mode, joint_tab_count and
// max_auto_tab_count), so every product sizes tabs exactly like the cabinets.
// Screws go in the webs beside and between the tabs (tp_web_centres in
// tab_pocket.scad), so the tab, its slot and the screws all derive from the same
// seam record. Include joinery.scad and tab_pocket.scad before this file.
//
// The planner keeps half a cutter diameter clear at both ends of every segment,
// so the shoulder reliefs beside the outer tabs (tp_tab_root_reliefs_2d) stay on
// the seam, and drops any tab whose slot (tab + fit clearance) would be narrower
// than the cutter.

// Remove [p, q] from a list of segments [[a, b], ...].
function sj_cut_interval(segs, p, q) = [for (s=segs) each
    (q <= s[0] || p >= s[1]) ? [s] :
    concat(p > s[0] ? [[s[0], p]] : [], q < s[1] ? [[q, s[1]]] : [])];

// Remove every interval of `list` from `segs`.
function sj_cut_all(segs, list, k=0) =
    k >= len(list) ? segs : sj_cut_all(sj_cut_interval(segs, list[k][0], list[k][1]), list, k + 1);

// Segments at least min_len long.
function sj_long(segs, min_len) = [for (s=segs) if (s[1] - s[0] >= min_len) s];

// Tabs [[a, b], ...] of one segment [a, b] from the core planner.
function sj_segment_tabs(a, b, tool_d, fit) =
    let(L = b - a)
    L <= 1 ? [] :
    let(n = effective_tab_count(L), w = tab_width_for(L))
    (w > L || w + fit < tool_d) ? [] :
    [for (i=[0:n-1]) let(c = a + tab_center(L, i)) [c - w/2, c + w/2]];

// Tabs of a seam made of segments. Half a cutter is kept clear at each segment end.
function sj_tabs(segs, tool_d, fit) =
    [for (s=segs) each sj_segment_tabs(s[0] + tool_d/2, s[1] - tool_d/2, tool_d, fit)];

// Smallest web that takes a screw: the hole plus a cutter-wide relief on each side
// and 1 mm of wood on each side of the hole.
function sj_screw_gap(screw_d, tool_d) = screw_d + 2*tool_d + 2;

// Screw stations along a seam with tabs: the centres of the webs beside and between
// the tabs of each segment that are at least sj_screw_gap wide. A segment without
// tabs gets none (see sj_screw_only for joints held by screws alone).
function sj_screws(segs, tabs, screw_d, tool_d) = [for (s=segs)
    let(ts = [for (q=tabs) if (q[0] >= s[0] - 1e-6 && q[1] <= s[1] + 1e-6) q])
    if (len(ts) > 0)
        each [for (c=tp_web_centres(s[1] - s[0], [for (q=ts) q[0] - s[0]], ts[0][1] - ts[0][0], sj_screw_gap(screw_d, tool_d))) s[0] + c]];

// Screw stations for a joint held by screws alone: where the planner would put tabs.
function sj_screw_only(segs, tool_d) =
    [for (q=sj_tabs(segs, tool_d, tool_d)) (q[0] + q[1])/2];

// Webs between neighbouring tabs of a seam (the solid wood left between slots).
function sj_webs(tabs) = len(tabs) < 2 ? [] : [for (i=[1:len(tabs)-1]) tabs[i][0] - tabs[i-1][1]];

// Interval [lo, hi] where the line axis = c crosses polygon pts (on the other axis);
// [] when it misses. axis 1: a horizontal line v = c, returning a u interval.
function sj_chord(pts, c, axis=1) =
    let(o = 1 - axis,
        xs = [for (i=[0:len(pts)-1]) let(a=pts[i], b=pts[(i+1)%len(pts)])
                if ((a[axis] <= c && b[axis] >= c) || (b[axis] <= c && a[axis] >= c))
                    each (a[axis] != b[axis] ? [a[o] + (b[o] - a[o])*(c - a[axis])/(b[axis] - a[axis])] : [a[o], b[o]])])
    len(xs) < 2 ? [] : [min(xs), max(xs)];

// Interval covered by a convex polygon across the whole band c0..c1: the common part of
// the chords at both band edges and at every vertex inside the band. [] when empty.
function sj_band(pts, c0, c1, axis=1) =
    let(cs = concat([c0 + 1e-6, c1 - 1e-6], [for (p=pts) if (p[axis] > c0 && p[axis] < c1) p[axis]]),
        ch = [for (c=cs) sj_chord(pts, c, axis)])
    len([for (x=ch) if (len(x) == 0) 1]) > 0 ? [] :
    let(lo = max([for (x=ch) x[0]]), hi = min([for (x=ch) x[1]])) hi > lo ? [lo, hi] : [];

// Point in polygon (ray casting).
function sj_inside(pts, p) = len([for (i=[0:len(pts)-1])
    let(a=pts[i], b=pts[(i+1)%len(pts)])
    if ((a[1] > p[1]) != (b[1] > p[1]))
        if (p[0] < a[0] + (b[0] - a[0])*(p[1] - a[1])/(b[1] - a[1])) 1]) % 2 == 1;

// A circle (centre, diameter) lies inside a polygon: its centre and eight rim points do.
function sj_circle_inside(pts, c, d) =
    sj_inside(pts, c) && len([for (k=[0:7]) let(q = c + d/2*[cos(45*k), sin(45*k)]) if (!sj_inside(pts, q)) 1]) == 0;

// Axis-aligned rectangles [x0, x1, y0, y1] that share area (more than eps).
function sj_rects_overlap(a, b, eps=0.001) =
    a[0] < b[1] - eps && b[0] < a[1] - eps && a[2] < b[3] - eps && b[2] < a[3] - eps;
