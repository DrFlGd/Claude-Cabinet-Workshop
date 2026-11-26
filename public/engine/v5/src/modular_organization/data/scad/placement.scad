// Cut-layout placement helpers shared by every frontend that lays its parts out
// from a placement table (the cabinet layouts and the products).
//
// The including file defines:
//   cut_layout_placement_table  [[id, x, y, width, height, paint name, paint index], ...]
//   apply_kerf_compensation, kerf
//   module paint(name, index)  (colours a placed part)
// Positions are the part's lower-left corner in the flat layout (mm), sizes the
// nominal cut rectangle; kerf compensation widens the exported outline by kerf/2
// on every side, which placement_rect() includes. layout_overlaps() lists every
// pair of placed rectangles that share area, for CHECK|ERROR|LAYOUT_OVERLAP.
function placement_index(id) =
    let(
        t = cut_layout_placement_table,
        m = len(t) == 0 ? [] : [for (i=[0:len(t)-1]) if (t[i][0] == id) i]
    )
    len(m) > 0 ? m[0] : -1;

// Exported rectangle [x, y, w, h] of a placement, including kerf compensation.
function placement_rect(p) =
    let(k = apply_kerf_compensation ? kerf : 0)
    [p[1]-k/2,p[2]-k/2,p[3]+k,p[4]+k];

function placement_rects_overlap(a,b,eps=0.001) =
    a[0] < b[0]+b[2]-eps && b[0] < a[0]+a[2]-eps
    && a[1] < b[1]+b[3]-eps && b[1] < a[1]+a[3]-eps;

// Every pair of cut-layout parts whose exported rectangles share area:
// [id A, id B, overlap width, overlap height].
function layout_overlaps() =
    let(t = cut_layout_placement_table, n = len(t))
    n < 2 ? [] :
    [for (i=[0:n-2]) for (j=[i+1:n-1])
        let(a = placement_rect(t[i]), b = placement_rect(t[j]))
        if (placement_rects_overlap(a,b))
            [t[i][0],t[j][0],
             min(a[0]+a[2],b[0]+b[2])-max(a[0],b[0]),
             min(a[1]+a[3],b[1]+b[3])-max(a[1],b[1])]];

// Kerf compensation for through-cut geometry: the finished 2D part (outline
// minus its holes, slots and notches) is offset outward by half the kerf, so
// outlines grow and every opening shrinks by the same amount. A cutter that
// removes `kerf` along the path then leaves each part and each joint at its
// nominal size. Pocket and engrave layouts are not offset; CAM owns those.
module kerf_compensated() {
    if (apply_kerf_compensation && kerf > 0)
        offset(delta=kerf/2) children();
    else
        children();
}

// Paints and positions one cut-layout part from the table.
module placed(id) {
    i = placement_index(id);
    assert(i >= 0,str("No cut-layout placement record for part ",id));
    p = cut_layout_placement_table[i];
    paint(p[5],p[6])
        translate([p[1],p[2]])
            kerf_compensated()
                children();
}

// PLACE records: where each part sits in the flat cut layout (mm, part origin
// at its lower-left corner, before kerf compensation).
module placement_report() {
    for (p=cut_layout_placement_table)
        echo(str("PLACE|",p[0],"|X=",p[1],"|Y=",p[2],"|W=",p[3],"|H=",p[4]));
}
