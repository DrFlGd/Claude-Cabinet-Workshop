// Section layout tree (cabinet_layout_mode = "sections").
//
// section_nodes is a flat list of rows, parents before children:
//   [parent, order, axis, size_mode, size, contents, count, height_mode, step,
//    weights, separator, shelves, hinge_side, shelf_style]
// axis is "leaf", "x" (children side by side, left to right) or "z" (children
// stacked, top to bottom). A split's separator is "panel", "rail" (stacked
// splits only: a front rail) or "none". A leaf holds "drawers" (count drawers
// sized by height_mode/step/weights), "doors" (count = 1 or 2 doors, with
// `shelves` shelves behind them) or "open" (count = shelves). hinge_side
// (single doors) and shelf_style ("fixed"/"adjustable") are optional; designs
// saved with twelve columns use single_door_hinge_side and fixed shelves.
//
// Every leaf is one bay of the shared bay construction in core/resolve.scad.
// The geometry below is resolved once into sec_rects, sec_bounds, sec_vmembers
// and sec_hmembers there.

function sec_n() = len(sec_rows);
function sec_children(i) =
    sec_n()==0 ? [] : [for(k=[0:sec_n()-1]) if(sec_rows[k][0]==i) k];
function sec_child_at(i,order) =
    let(k=[for(c=sec_children(i)) if(sec_rows[c][1]==order) c]) len(k)>0 ? k[0] : -1;
function sec_sum(a,i=0) = i>=len(a)?0:a[i]+sec_sum(a,i+1);
function sec_gap(i) = sec_rows[i][10]=="none"?0:material_thickness;
function sec_root() = [
    face_frame_active?face_frame_inner_left_x:material_thickness,
    front_opening_bottom_z,
    face_frame_active?face_frame_clear_width:inner_width,
    front_opening_top_z-front_opening_bottom_z
];
function sec_span(i,parent) =
    let(
        k=sec_children(sec_rows[i][0]),
        axis=sec_rows[sec_rows[i][0]][2],
        available=(axis=="x"?parent[2]:parent[3])-sec_gap(sec_rows[i][0])*(len(k)-1),
        fixed=sec_sum([for(c=k) sec_rows[c][3]=="mm"?sec_rows[c][4]:0]),
        weights=sec_sum([for(c=k) sec_rows[c][3]=="weight"?sec_rows[c][4]:0])
    )
    sec_rows[i][3]=="mm"?sec_rows[i][4]:(available-fixed)*sec_rows[i][4]/max(0.001,weights);
function sec_rect(i,depth=0) =
    assert(depth<=8,"Section nesting exceeds eight levels")
    i==0?sec_root():
    let(
        p=sec_rows[i][0],
        r=sec_rect(p,depth+1),
        axis=sec_rows[p][2],
        before=[for(c=sec_children(p)) if(sec_rows[c][1]<sec_rows[i][1]) c],
        offset=sec_sum([for(c=before) sec_span(c,r)+sec_gap(p)]),
        span=sec_span(i,r)
    )
    axis=="x"?[r[0]+offset,r[1],span,r[3]]:[r[0],r[1]+r[3]-offset-span,r[2],span];

// Dividers: one between each pair of neighbouring children of a split that has
// a separator. [node, k] is the divider before child k (left of it in a side by
// side split, above it in a stacked split).
function sec_member_nodes(axis) =
    sec_n()==0 ? [] : [
        for(i=[0:sec_n()-1])
            if(sec_rows[i][2]==axis && sec_gap(i)>0)
                let(n=len(sec_children(i)))
                    for(k=[1:max(1,n-1)]) if(k<n) [i,k]
    ];
function sec_find(list,i,k) =
    len(list)==0 ? -2 :
    let(m=[for(j=[0:len(list)-1]) if(list[j][0]==i && list[j][1]==k) j]) len(m)>0?m[0]:-2;

// [left, right, bottom, top] of node i: -1 the carcass, -2 a split without a
// divider, otherwise a vertical (left/right) or horizontal (bottom/top) divider.
function sec_bound(i) =
    i==0 ? [-1,-1,-1,-1] :
    let(
        p=sec_rows[i][0],
        pb=sec_bound(p),
        k=sec_rows[i][1],
        last=k==len(sec_children(p))-1,
        divided=sec_gap(p)>0
    )
    sec_rows[p][2]=="x"
        ? [k==0?pb[0]:divided?sec_find(sec_vm_nodes,p,k):-2,
           last?pb[1]:divided?sec_find(sec_vm_nodes,p,k+1):-2,
           pb[2],pb[3]]
        : [pb[0],pb[1],
           last?pb[2]:divided?sec_find(sec_hm_nodes,p,k+1):-2,
           k==0?pb[3]:divided?sec_find(sec_hm_nodes,p,k):-2];

// Structural extent [x0,z0,x1,z1] of node i: its opening, widened to the carcass
// sides, bottom and top where it meets them (they differ behind a face frame).
function sec_struct(i) =
    let(r=sec_rects[i],b=sec_bounds[i])
    [
        b[0]==-1 ? material_thickness : r[0],
        b[2]==-1 ? carcass_interior_bottom_z() : r[1],
        b[1]==-1 ? resolved_cabinet_width-material_thickness : r[0]+r[2],
        b[3]==-1 ? carcass_interior_top_z() : r[1]+r[3]
    ];

function sec_leaf_shelf_style(row) =
    len(row)>13 && (row[13]=="fixed"||row[13]=="adjustable") ? row[13] : "fixed";
function sec_leaf_hinge_side(row) =
    len(row)>12 && (row[12]=="left"||row[12]=="right") ? row[12] : single_door_hinge_side;

module sec_validate(){
 assert(len(section_nodes)>0 && len(section_nodes)<=31,"Use 1 to 31 section nodes");
 assert(section_nodes[0][0]==-1,"Root section must have parent -1");
 assert(width_basis=="outside" && depth_basis=="outside","Section layout requires outside-envelope sizing");
 for(i=[0:len(section_nodes)-1]){
  n=section_nodes[i];r=sec_rects[i];children=sec_children(i);
  assert(len(n)==12||len(n)==14,str("Invalid section row ",i+1));
  assert(i==0 || (n[0]>=0 && n[0]<i),"Parents must precede children");
  assert(n[2]=="leaf"||n[2]=="x"||n[2]=="z","Unknown split axis");
  assert(n[3]=="weight"||n[3]=="mm","Unknown section size mode");
  assert(n[4]>0 && r[2]>=60 && r[3]>=60,str("Section ",i+1," is too small or exceeds its parent"));
  assert(n[5]=="drawers"||n[5]=="doors"||n[5]=="open","Unknown contents");
  assert(n[10]=="panel"||n[10]=="rail"||n[10]=="none","Unknown separator");
  assert(!(n[2]=="x"&&n[10]=="rail"),"Vertical splits require panels or no divider");
  assert(n[2]=="leaf"?len(children)==0:len(children)>=2,"A split requires at least two children");
  if(n[2]!="leaf"){
   assert(len([for(c=children) if(section_nodes[c][3]=="weight") c])>0,"Keep at least one flexible child in each split");
   for(order=[0:len(children)-1])assert(len([for(c=children) if(section_nodes[c][1]==order) c])==1,"Child order must be unique and consecutive");
  }
  if(n[2]=="leaf"){
   assert(n[6]==floor(n[6])&&n[6]>=0&&n[6]<=8,"Invalid section count");
   assert(n[5]!="doors"||(n[6]>=1&&n[6]<=2),"Door sections need one or two doors");
   assert(n[5]!="drawers"||n[6]>=1,"Drawer banks need at least one drawer");
   assert(n[7]=="equal"||n[7]=="graduated"||n[7]=="custom_weights","Invalid drawer height mode");
   assert(n[8]>=0 && n[11]>=0 && n[11]<=8 && n[11]==floor(n[11]),"Invalid graduated step or shelf count");
   if(n[5]=="drawers" && n[7]=="custom_weights")assert(len(n[9])>=n[6] && min(n[9])>0,"Provide a positive height weight for each drawer");
   echo(str("DIM|SECTION|S",i+1,"|X=",r[0],"|Z=",r[1],"|W=",r[2],"|H=",r[3],"|CONTENTS=",n[5]));
  }
 }
}
