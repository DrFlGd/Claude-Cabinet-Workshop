// French-cleat wall mounting shared by any cabinet type or product. Units are mm.
//
// Two ways to hang a module on a beveled wall rail:
//   - a beveled hanger board screwed to the module's back (the "stand" half of
//     mo_cleat_profile in cleat.scad) resting on the rail (the "wall" half);
//   - CNC side hooks: the rear edge of each side panel is cut into a hook whose
//     underside is the same bevel, so the sides hang directly on the rail.
// Every function takes its sizes as arguments. Hook outlines are in a panel's own
// (u, v) plane: u from the wall (u = 0) toward the front, v up.
//
// Inside corners that a mating part's square edge must reach get a relief whose
// cutter travels along the corner's bisector (wm_corner_relief); for a 90 degree
// corner this is the dog-bone of tab_pocket.scad, and for the acute corner where
// a hook's bevel meets the panel it opens just enough for the rail's sharp lip.

// Vertical rise of a bevel across a board of thickness ct.
function wm_rise(ct, angle) = ct*tan(angle);

// Bottom of the wall rail carrying a hanger or hook whose top is at `top` and whose
// height is ch. The rail's bevel lies `gap` below the hanger's (0: bearing).
function wm_rail_bottom(top, ch, ct, angle, gap=0) = top - 2*ch + wm_rise(ct, angle) - gap;

// Height the module must be lifted to hang it straight down: the hook tip has to
// pass over the rail's front lip.
function wm_hang_lift(ct, angle, gap=0) = wm_rise(ct, angle) + gap;

// Unit vector.
function wm_unit(v) = v/norm(v);

// Inside-corner relief. P is the corner, d1 and d2 point from P along its two walls
// into the open side (the cutter's side). Returns [far, near] cutter centres: at
// `far` the cutter touches both walls, at `near` its edge passes through P. Cut the
// hull of the cutter at both (wm_relief_2d).
function wm_corner_relief(P, d1, d2, tool_d) =
    let(r = tool_d/2, a = wm_unit(d1), b = wm_unit(d2), m = wm_unit(a + b),
        th = acos(max(-1, min(1, a*b))))
    [P + r/sin(th/2)*m, P + r*m];

module wm_relief_2d(centres, tool_d) {
    if (tool_d > 0) hull() for (c=centres) translate(c) circle(d=tool_d);
}

// Points rounding a convex corner P whose walls run from P along d1 and d2, with
// radius r, ordered from the d1 wall to the d2 wall.
function wm_round_corner(P, d1, d2, r, steps=8) =
    r <= 0 ? [P] :
    let(a = wm_unit(d1), b = wm_unit(d2), th = acos(max(-1, min(1, a*b))),
        t = r/tan(th/2), m = wm_unit(a + b), C = P + r/sin(th/2)*m,
        T1 = P + t*a, T2 = P + t*b,
        a1 = atan2(T1[1] - C[1], T1[0] - C[0]), a2 = atan2(T2[1] - C[1], T2[0] - C[0]),
        da = (a2 - a1 + 540) % 360 - 180)
    [for (i=[0:steps]) C + r*[cos(a1 + da*i/steps), sin(a1 + da*i/steps)]];

// CNC side hook. The hook is the part of a panel behind the module's back, ct deep
// (u 0..ct), from its top `top_v` down to a tip at (0, tip_v) and up the bevel to
// the inside corner (ct, tip_v + rise). Returns those outline points in order:
// (0, top_v), the rounded tip, (ct, tip_v + rise). The caller closes the outline.
function wm_hook_points(ct, angle, tip_v, top_v, tip_r=0) =
    concat([[0, top_v]],
           wm_round_corner([0, tip_v], [0, 1], [cos(angle), sin(angle)], tip_r),
           [[ct, tip_v + wm_rise(ct, angle)]]);

// Relief centres for the hook's inside corner, where the bevel meets the panel's
// face at u = ct (the rail's front lip seats there).
function wm_hook_relief(ct, angle, tip_v, tool_d) =
    wm_corner_relief([ct, tip_v + wm_rise(ct, angle)], [0, -1], [-cos(angle), -sin(angle)], tool_d);

// Lowest point of that relief (v).
function wm_hook_relief_bottom(ct, angle, tip_v, tool_d) =
    let(c = wm_hook_relief(ct, angle, tip_v, tool_d)) min(c[0][1], c[1][1]) - tool_d/2;

// A rounded tip must leave a flat on the bevel and fit within the hook's height.
function wm_tip_ok(ct, ch, angle, tip_r) =
    let(th = 90 - angle, t = tip_r/tan(th/2))
    tip_r >= 0 && t < ct/cos(angle)/2 && t < ch/2;

// Screw stations along a board of length L: as many as fit at `pitch` (at least
// two when L allows), centred, at least `end` from both ends.
function wm_screw_stations(L, pitch, end) =
    let(span = L - 2*end)
    span <= 0 ? [L/2] :
    let(n = max(2, floor(span/max(1, pitch)) + 1), step = span/(n - 1))
    [for (i=[0:n-1]) end + i*step];

// Rail positions of a cleat wall with rails every `pitch` mm (0: one rail), from the
// rail at z0, that overlap the height range [lo, hi].
function wm_other_rails(z0, ch, pitch, lo, hi) =
    pitch <= 0 ? [] :
    [for (k=[-20:20]) if (k != 0) let(z = z0 + k*pitch) if (z < hi && z + ch > lo) z];
