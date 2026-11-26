// Modular Organization: workbench — source entrypoint; units mm.
// Modular workbench: an egg-crate base frame on casters with a grid of registration tabs,
// cabinet modules that drop onto whole grid cells (and stack), and a puzzle-jointed
// worksurface with dog holes. X along the frame length (columns), Y front to back (rows),
// Z up. CUT coordinates show each part with its machined face up.
// Every part comes from one part table that drives assembly, CUT, POCKET, labels and BOM.
// See docs/MODULAR_WORKBENCH.md for the reference dimensions these defaults reproduce.
include <joinery.scad>

/* [Materials / Stock] */

// Stock sheet the cut files are nested onto.
stock_width = 2440; // [300:1:5000]

// Short side of the stock sheet.
stock_height = 1220; // [300:1:5000]

/* [Materials / Measured Thickness] */

// Base frame strips.
frame_thickness = 18.00; // [3:0.01:40]

// Module sides, bottoms, backs and top rails.
carcass_thickness = 18.00; // [3:0.01:40]

// Door stock.
door_thickness = 18.00; // [3:0.01:40]

// Adjustable shelf stock (thinner sheet in the reference plans).
shelf_thickness = 12.00; // [3:0.01:40]

// Worksurface panel stock.
worksurface_thickness = 18.00; // [3:0.01:60]

// Stock the plywood pulls are cut from.
handle_thickness = 18.00; // [3:0.01:40]

/* [Machining / Tool and Kerf] */

// Cutter for through cuts and pockets; inside corners get at least its radius.
router_bit_diameter = 6.00; // [0.5:0.01:25]

/* [Machining / Shared Slot Relief] */

// Relief cut in the inside corners of slots and pockets so square parts seat fully.
slot_corner_relief = "dogbone"; // [none,dogbone,t_bone]

/* [Machining / Frame Joints] */

// Extra width of every slot, notch and housing across the mating stock (0 reproduces the reference plans).
joint_fit_clearance = 0.00; // [0:0.01:2]

// Depth of the housings in the module sides; fingers enter finger_length of it.
housing_depth = 14.00; // [1:0.01:40]

// Length of the back, bottom and rail fingers that enter the side housings.
finger_length = 13.00; // [1:0.01:40]

// Clearance on every side of a base-frame tab in a module's registration pocket.
registration_clearance = 0.50; // [0:0.01:5]

// Depth of the pockets under each module bottom that take the frame tabs; must exceed the tab height.
registration_pocket_depth = 14.00; // [1:0.01:40]

/* [Sizing / Modular Grid] */

// Small 2 × 2, medium 3 × 2, large 4 × 2 cells, or a custom grid.
frame_size = "medium"; // [small,medium,large,custom]

// Cells along the length of a custom frame.
grid_columns = 3; // [1:1:5]

// Cells front to back of a custom frame.
grid_rows = 2; // [1:1:3]

// Pitch of the grid cells; modules occupy whole cells.
cell_size = 400; // [250:1:600]

/* [Structure / Base] */

// Height of the base frame strips, without the registration tabs.
frame_height = 85; // [40:1:300]

// Strip centre lines sit this far inside every cell edge.
frame_rail_inset = 60; // [20:1:200]

// Cross strips under the end columns only (as the reference frames) or under every column.
frame_cross_members = "ends"; // [ends,every_column]

// Strip ends taper inwards by this much at the floor.
frame_foot_inset = 18.67; // [0:0.01:60]

// Tabs on top of the frame strips at every cell centre locate the modules.
registration_tab_length = 50; // [10:1:200]

// How far the tabs stand above the strips.
registration_tab_height = 13; // [1:0.1:40]

/* [Structure / Layout] */

// One row per module: [column, row, cells wide, cells deep, height mm, contents door|open, shelves, facing front|back|left|right, hinge left|right]. Later rows stack on earlier ones.
modules = [[0,0,1,1,730,"door",1,"front","left"],[1,0,2,1,730,"door",1,"front","right"],[0,1,1,1,730,"door",1,"back","right"],[1,1,1,1,730,"door",1,"back","right"],[2,1,1,1,730,"door",1,"back","right"]];

/* [Structure / Top] */

// Module top rails: depth of each rail.
top_rail_width = 75; // [30:1:200]

// Hand slots in the top rails, centred on the dog-hole rows.
include_hand_slots = true;

// Length of each hand slot.
hand_slot_length = 100; // [30:1:300]

// Width of each hand slot.
hand_slot_width = 25; // [10:1:60]

/* [Structure / Worktop] */

// Puzzle-jointed worksurface over the whole frame, resting on the modules.
include_worksurface = true;

// Worksurface overhang past the frame on every side.
worksurface_overhang = 50; // [0:1:200]

// Radius of the four outer worksurface corners.
worksurface_corner_radius = 15; // [0:1:100]

// all, none, or only the panels listed in worksurface_dog_hole_panels (numbered from 1).
worksurface_dog_holes = "all"; // [all,none,selected]

// Worksurface panels that get dog holes when dog holes are set to selected.
worksurface_dog_hole_panels = [1];

// Bench dog hole diameter.
dog_hole_diameter = 16; // [3:0.1:40]

// Dog hole grid pitch; the grid starts half a pitch in from each cell edge.
dog_hole_pitch = 100; // [40:1:300]

// Puzzle joints between worksurface panels: depth across the seam, pitch along it, dovetail flank angle.
puzzle_depth = 30; // [10:1:80]

// Distance between puzzle tabs along a seam.
puzzle_pitch = 180; // [60:1:400]

// Dovetail flank angle of the puzzle tabs, degrees.
puzzle_angle = 15; // [0:1:30]

// Gap cut around every puzzle tab on the receiving panel.
puzzle_clearance = 0.00; // [0:0.01:2]

/* [Doors / Layout] */

// Total gap around a door (half on each edge) and between stacked or neighbouring doors.
door_gap = 5; // [0:0.1:20]

/* [Shelves / Layout] */

// Shelves stop this far behind the front edge of the sides.
shelf_front_setback = 20; // [0:1:200]

// Gap between a shelf and the back panel.
shelf_rear_clearance = 5; // [0:1:100]

// Gap between a shelf and each side (0 reproduces the reference fit).
shelf_side_clearance = 0.00; // [0:0.01:5]

// Shelf pin hole diameter.
shelf_pin_diameter = 5; // [2:0.1:10]

// Shelf pin hole depth.
shelf_pin_depth = 10; // [2:0.1:30]

// Height of the lowest shelf pin hole above the module bottom.
shelf_pin_first_height = 175; // [20:1:1000]

// Spacing of the shelf pin holes.
shelf_pin_pitch = 50; // [10:1:200]

// No shelf pin holes closer than this to the module top.
shelf_pin_top_clearance = 200; // [20:1:1000]

// Front row of shelf pin holes, from the front edge of the side.
shelf_pin_front_inset = 90; // [20:1:300]

// Rear row of shelf pin holes, from the inside face of the back.
shelf_pin_rear_inset = 50; // [20:1:300]

/* [Hardware / Hinges] */

// Concealed hinge cup diameter.
hinge_cup_diameter = 35; // [10:0.1:60]

// Concealed hinge cup depth.
hinge_cup_depth = 12; // [1:0.1:30]

// Hinge cup centre from the hinge edge of the door.
hinge_cup_center_from_door_edge = 21; // [5:0.1:60]

// Hinge cup centre from the top and bottom of the door.
hinge_end_offset = 87.5; // [20:0.1:300]

/* [Hardware / Handles] */

// Plywood pulls cut from handle stock; none leaves the doors undrilled.
handle_style = "square"; // [none,square,rounded,chamfered,straight_bar,traditional]

// Screw clearance holes for the pulls (140 mm centres).
handle_hole_diameter = 4.5; // [2:0.1:10]

// Latch edge of the door to the handle centre.
handle_edge_offset = 117.5; // [20:0.1:600]

// Top of the door to the handle centre line.
handle_top_offset = 72.5; // [10:0.1:600]

/* [Hardware / Base] */

// Floor to the underside of the frame (caster mounting plate and wheel).
caster_height = 75; // [0:1:300]

// Square caster mounting plate under each outer frame crossing.
caster_plate_size = 60; // [20:1:200]

/* [Output / View] */

// What the engine renders: the assembly, flat parts, or a cut, pocket, engrave or BOM output.
output_mode = "assembly"; // [assembly,flat_3d,cut_layout,engrave_layout,bom,pocket_carcass_dados,pocket_hinge_cups,pocket_shelf_pins]

/* [Output / Visibility] */

// Show the casters.
show_hardware = true;

// Show the worksurface in the assembly.
show_worksurface = true;

// Show doors and pulls in the assembly.
show_doors = true;

/* [Output / Flat Layout] */

// Gap between parts in the flat cut layout.
layout_gap = 25; // [1:1:200]

/* [Output / Labels] */

// Engrave part labels in the engrave layout.
label_parts = true;

/* [System / Reports] */

validation_report = "summary"; // [off,summary,verbose]

system_contract_report = "summary"; // [off,summary,verbose]

dimension_report = "summary";

/* [Hidden] */

$fn=48;
// joinery.scad slot relief reads these.
cnc_tool_diameter=router_bit_diameter;
carcass_slot_corner_relief="inherit";
carcass_cnc_tool_diameter=0;
C=cell_size;
cols=frame_size=="small" ? 2 : frame_size=="medium" ? 3 : frame_size=="large" ? 4 : max(1,min(5,round(grid_columns)));
rows=frame_size=="custom" ? max(1,min(3,round(grid_rows))) : 2;
FL=cols*C; FD=rows*C;
tf=frame_thickness; tc=carcass_thickness; td=door_thickness; ts=shelf_thickness; tw=worksurface_thickness; th=handle_thickness;
cl=joint_fit_clearance;
fl=finger_length;
hf=frame_height;
Zf=caster_height;
Zbase=Zf+hf;
rr=router_bit_diameter/2;
relief_on=slot_corner_relief!="none" && router_bit_diameter>0;

// ---------- modules ----------
function mget(m,i,d)=len(m)>i && !is_undef(m[i]) ? m[i] : d;
function norm_module(m)=[max(0,floor(mget(m,0,0))),max(0,floor(mget(m,1,0))),max(1,floor(mget(m,2,1))),max(1,floor(mget(m,3,1))),
 mget(m,4,730),mget(m,5,"door")=="open" ? "open" : "door",max(0,min(8,floor(mget(m,6,1)))),
 let(f=mget(m,7,"front")) (f=="back" || f=="left" || f=="right") ? f : "front",mget(m,8,"right")=="left" ? "left" : "right"];
MODS=[for(m=modules) if(is_list(m)) norm_module(m)];
NM=len(MODS);
function mcol(k)=MODS[k][0];
function mrow(k)=MODS[k][1];
function mspx(k)=MODS[k][2];
function mspy(k)=MODS[k][3];
function mH(k)=MODS[k][4];
function mcontents(k)=MODS[k][5];
function mshelves(k)=MODS[k][6];
function mfacing(k)=MODS[k][7];
function mhinge(k)=MODS[k][8];
function msideways(k)=mfacing(k)=="left" || mfacing(k)=="right";
// Local module frame: X across the front (width), Y from the front face to the back, Z up.
function mW(k)=(msideways(k) ? mspy(k) : mspx(k))*C;
function mD(k)=(msideways(k) ? mspx(k) : mspy(k))*C;
function mDc(k)=mD(k)-td;
function mWi(k)=mW(k)-2*tc;
function cells_of(k)=[for(i=[0:mspx(k)-1]) for(j=[0:mspy(k)-1]) [mcol(k)+i,mrow(k)+j]];
function covers(k,c)=c[0]>=mcol(k) && c[0]<mcol(k)+mspx(k) && c[1]>=mrow(k) && c[1]<mrow(k)+mspy(k);
function in_grid(k)=mcol(k)+mspx(k)<=cols && mrow(k)+mspy(k)<=rows;
function share(a,b)=mcol(a)<mcol(b)+mspx(b) && mcol(b)<mcol(a)+mspx(a) && mrow(a)<mrow(b)+mspy(b) && mrow(b)<mrow(a)+mspy(a);
// Each module rests on the highest earlier module (or the frame) under its cells.
function zlist(k,acc)=k>=NM ? acc : zlist(k+1,concat(acc,[max(concat([Zbase],[for(j=[0:1:k-1]) if(share(j,k)) acc[j]+mH(j)]))]));
ZS=zlist(0,[]);
function mz(k)=ZS[k];
function mtop(k)=mz(k)+mH(k);
// Top of the stack below module k at cell c.
function under_top(k,c)=max(concat([Zbase],[for(j=[0:1:k-1]) if(covers(j,c)) mtop(j)]));
function column_top(c)=max(concat([Zbase],[for(j=[0:1:NM-1]) if(covers(j,c)) mtop(j)]));
Ztop=NM>0 ? max([for(k=[0:NM-1]) mtop(k)]) : Zbase+730;
// Local -> world transform of module k (proper rotation about Z, then translation).
function mmatrix(k)=let(x0=mcol(k)*C,y0=mrow(k)*C,z=mz(k),W=mW(k),D=mD(k),f=mfacing(k))
 f=="back" ? [[-1,0,0,x0+W],[0,-1,0,y0+D],[0,0,1,z],[0,0,0,1]] :
 f=="left" ? [[0,1,0,x0],[-1,0,0,y0+W],[0,0,1,z],[0,0,0,1]] :
 f=="right" ? [[0,-1,0,x0+D],[1,0,0,y0],[0,0,1,z],[0,0,0,1]] :
 [[1,0,0,x0],[0,1,0,y0],[0,0,1,z],[0,0,0,1]];
// The cells directly in front of a module's face, in world cell coordinates.
function front_cells(k)=let(f=mfacing(k))
 f=="front" ? [for(i=[0:mspx(k)-1]) [mcol(k)+i,mrow(k)-1]] :
 f=="back" ? [for(i=[0:mspx(k)-1]) [mcol(k)+i,mrow(k)+mspy(k)]] :
 f=="left" ? [for(j=[0:mspy(k)-1]) [mcol(k)-1,mrow(k)+j]] :
 [for(j=[0:mspy(k)-1]) [mcol(k)+mspx(k),mrow(k)+j]];
function blocks_front(k,j)=j!=k && mz(j)<mtop(k)-0.01 && mtop(j)>mz(k)+0.01 && len([for(c=front_cells(k)) if(covers(j,c)) 1])>0;

// Centred finger pattern: n fingers of length L with gap g between them, at least m from each end.
function finger_count(S,L,g,m)=max(1,floor((S-2*m+g)/(L+g)));
function fingers(S,L,g,m)=let(n=finger_count(S,L,g,m),o=(S-(n*L+(n-1)*g))/2) [for(i=[0:n-1]) [o+i*(L+g),o+i*(L+g)+L]];
// Back panel fingers into the side housings: 2n+1 equal fields, fingers on the odd ones.
function back_fingers(H)=let(n=max(1,round((H/105-1)/2)),L=H/(2*n+1)) [for(i=[0:n-1]) [(2*i+1)*L,(2*i+2)*L]];
function bottom_side_fingers(k)=fingers(mDc(k)-tc,80,80,40);   // from the carcass front
function bottom_rear_fingers(k)=fingers(mWi(k),80,80,40);      // from the inner left face
function rail_rear_fingers(k)=fingers(mWi(k),50,100,40);       // from the inner left face
RW=top_rail_width;
rail_finger=[RW/3,2*RW/3];
function back_rail_y0(k)=mD(k)-tc-RW;                            // local y of the back rail's front edge
// Shelf pin holes, from the module's floor.
function pin_heights(k)=let(H=mH(k),z0=tc+shelf_pin_first_height,n=floor((H-shelf_pin_top_clearance-z0)/shelf_pin_pitch)+1)
 n<1 ? [] : [for(i=[0:n-1]) z0+i*shelf_pin_pitch];
function sum(v,i=0)=i>=len(v) ? 0 : v[i]+sum(v,i+1);
function dedupe(L)=[for(i=[0:1:len(L)-1]) if(i==0 || L[i]!=L[i-1]) L[i]];
function shelf_holes(k)=let(P=pin_heights(k),n=mshelves(k),z0=tc+shelf_pin_first_height)
 len(P)==0 || n==0 ? [] : dedupe([for(i=[1:n]) let(target=tc+(mH(k)-2*tc)*i/(n+1)) P[max(0,min(len(P)-1,round((target-z0)/shelf_pin_pitch)))]]);
function shelf_z(k,i)=shelf_holes(k)[i]+shelf_pin_diameter/2;
function door_count(k)=mcontents(k)!="door" ? 0 : mW(k)<=C+0.01 ? 1 : 2;
function door_w(k)=mW(k)/door_count(k)-door_gap;
function door_h(k)=mH(k)-door_gap;
function door_x0(k,j)=j*mW(k)/door_count(k)+door_gap/2;
function door_hinge_left(k,j)=door_count(k)==1 ? mhinge(k)=="left" : j==0;
function hinge_count(Hd)=Hd>1500 ? 4 : Hd>1000 ? 3 : 2;
function hinge_vs(Hd)=let(n=hinge_count(Hd)) [for(i=[0:n-1]) hinge_end_offset+i*(Hd-2*hinge_end_offset)/(n-1)];

// ---------- handles ----------
// Every handle in the set screws on at 140 mm centres.
HSP=140;
HL=handle_style=="chamfered" ? 184 : handle_style=="straight_bar" ? 202 : handle_style=="traditional" ? 210 : 162;
HH=handle_style=="chamfered" ? 42 : handle_style=="traditional" ? 49 : 45;
has_handles=handle_style!="none";
module round_convex(r) { offset(r=r) offset(delta=-r) children(); }
module round_concave(r) { offset(r=-r) offset(delta=r) children(); }
module handle_profile() {
 L=HL; H=HH; c=L/2;
 if(handle_style=="square") difference() {
  round_convex(3) square([L,H]);
  intersection() { translate([22,-1]) square([L-44,31]); hull() { translate([52,0]) circle(r=30); translate([L-52,0]) circle(r=30); } }
  translate([22,-1]) square([L-44,1.01]);
 }
 else if(handle_style=="rounded") difference() {
  intersection() { square([L,H]); hull() { square([L,3]); translate([42,3]) circle(r=42); translate([L-42,3]) circle(r=42); } }
  intersection() { translate([22,-1]) square([L-44,31]); hull() { translate([22,-1]) square([L-44,11]); translate([42,10]) circle(r=20); translate([L-42,10]) circle(r=20); } }
 }
 else if(handle_style=="chamfered") round_concave(3) difference() {
  round_convex(3) polygon([[0,0],[L,0],[L,8],[L-44,H],[44,H],[0,8]]);
  round_convex(3) polygon([[33,-5],[L-33,-5],[L-33,10],[L-56,27],[56,27],[33,10]]);
 }
 else if(handle_style=="straight_bar") round_concave(10) union() {
  translate([0,30]) round_convex(5) square([L,15]);
  for(x=[20,L-42]) square([22,31]);
 }
 else if(handle_style=="traditional") {
  R=((L/2)*(L/2)+(H-17)*(H-17))/(2*(H-17));
  arc=[for(i=[0:24]) let(a=asin((L/2)/R)*(1-2*i/24)) [c+R*sin(a),H-R+R*cos(a)]];
  round_concave(4) difference() {
   polygon(concat([[24,0],[46,0],[46,6],[164,6],[164,0],[186,0],[186,7],[L,12]],[for(p=arc) p],[[0,12],[24,7]]));
   round_convex(6) polygon([[46,-5],[164,-5],[164,10],[152,28],[58,28],[46,10]]);
  }
 }
}

// ---------- worksurface panels ----------
OV=worksurface_overhang;
PD=puzzle_depth; PP=puzzle_pitch;
// [c0,r0,c1,r1]: column-major panels as in the reference tops (end columns full depth on 2-row grids).
function pair_panels(c0,c1)=[for(r=[0:rows-1]) for(c=[c0:2:c1-1]) [c,r,min(c+2,c1),r+1]];
PANELS=cols>=3 && rows==2 ?
 let(lastSingle=(cols-1)%2==1) concat([[0,0,1,2]],pair_panels(1,lastSingle ? cols-1 : cols),lastSingle ? [[cols-1,0,cols,2]] : []) :
 pair_panels(0,cols);
NP=len(PANELS);
function panel_rect(i)=let(p=PANELS[i])
 [p[0]*C-(p[0]==0 ? OV : PD/2),p[1]*C-(p[1]==0 ? OV : PD/2),p[2]*C+(p[2]==cols ? OV : PD/2),p[3]*C+(p[3]==rows ? OV : PD/2)];
// Seams: [axis "x"|"y", position, from, to] — a vertical seam runs along Y at x=position.
function v_seams()=[for(i=[0:NP-1]) for(j=[0:NP-1]) let(a=PANELS[i],b=PANELS[j]) if(a[2]==b[0] && a[1]<b[3] && b[1]<a[3]) ["x",a[2]*C,max(a[1],b[1]),min(a[3],b[3]),i,j]];
function h_seams()=[for(i=[0:NP-1]) for(j=[0:NP-1]) let(a=PANELS[i],b=PANELS[j]) if(a[3]==b[1] && a[0]<b[2] && b[0]<a[2]) ["y",a[3]*C,max(a[0],b[0]),min(a[2],b[2]),i,j]];
SEAMS=concat(v_seams(),h_seams());
// Seam span along its axis, row by row (columns for horizontal seams), stopping short of crossing seams.
// Vertical seams run row by row (horizontal seams may cross them at row boundaries);
// a horizontal seam runs as one segment between the vertical seams or outer edges it meets.
function seg_span(a,b,n)=let(a0=a*C-(a==0 ? OV : 0),a1=b*C+(b==n ? OV : 0)) [a==0 ? a0 : a0+PD/2,b==n ? a1 : a1-PD/2];
function seam_segments(s)=s[0]=="x" ? [for(r=[s[2]:s[3]-1]) seg_span(r,r+1,rows)] : [seg_span(s[2],s[3],cols)];
function tab_centres(seg)=let(len=seg[1]-seg[0],n=max(1,floor((len-PP/2)/PP)),m=(seg[0]+seg[1])/2) [for(k=[0:1:n-1]) m+(k-(n-1)/2)*PP];
BIG=FL+FD+4*OV+1000;
// Region on the low side (smaller x or y) of seam s, with dovetail tabs reaching into the high side.
module seam_low_region(s) {
 q=s[1]; tn=tan(puzzle_angle); r=max(rr+0.5,1);
 module oriented() { if(s[0]=="x") multmatrix([[0,1,0,0],[1,0,0,0],[0,0,1,0],[0,0,0,1]]) children(); else children(); }
 oriented() round_convex(r) round_concave(r) union() {
  // along-seam coordinate is X, across-seam is Y in this local sketch (mirrored back for "x" seams)
  translate([-BIG,-BIG]) square([3*BIG,BIG+q-PD/2]);
  for(seg=seam_segments(s)) let(T=tab_centres(seg),z0=len(T)>0 ? T[0]-PP/2 : seg[1],z1=len(T)>0 ? T[len(T)-1]+PP/2 : seg[1]) {
   // straight joint where no dovetails run
   translate([seg[0]-PD,q-PD/2-0.01]) square([max(0,z0-seg[0]+PD),PD/2+0.01]);
   translate([z1,q-PD/2-0.01]) square([max(0,seg[1]-z1+PD),PD/2+0.01]);
   for(c=T) polygon([[c-PP/4+PD/2*tn,q-PD/2-0.01],[c+PP/4-PD/2*tn,q-PD/2-0.01],[c+PP/4+PD/2*tn,q+PD/2],[c-PP/4-PD/2*tn,q+PD/2]]);
  }
 }
}
module top_outline() { translate([-OV,-OV]) offset(r=worksurface_corner_radius) offset(delta=-worksurface_corner_radius) square([FL+2*OV,FD+2*OV]); }
function panel_dogs(i)=worksurface_dog_holes=="all" || (worksurface_dog_holes=="selected" && len([for(n=worksurface_dog_hole_panels) if(n==i+1) 1])>0);
function dog_positions(i)=let(p=PANELS[i],P=dog_hole_pitch)
 [for(x=[P/2:P:FL]) for(y=[P/2:P:FD]) if(x>p[0]*C && x<p[2]*C && y>p[1]*C && y<p[3]*C) [x,y]];
// Joint band of seam s: the strip PD wide centred on the seam line, along each of its segments.
module seam_band(s) {
 q=s[1];
 for(seg=seam_segments(s)) if(s[0]=="x") translate([q-PD/2,seg[0]]) square([PD,seg[1]-seg[0]]);
  else translate([seg[0],q-PD/2]) square([seg[1]-seg[0],PD]);
}
// Part of the joint band that belongs to the low panel (its dovetails plus the straight ends).
module seam_low_part(s) { intersection() { seam_band(s); seam_low_region(s); } }
// World XY outline of panel i: its cells (plus overhang at the outer edges), with each joint band
// handed to the panel that owns it. Bands stop short of crossing seams, so T-junctions stay straight.
function panel_core(i)=let(p=PANELS[i])
 [p[0]*C-(p[0]==0 ? OV : 0),p[1]*C-(p[1]==0 ? OV : 0),p[2]*C+(p[2]==cols ? OV : 0),p[3]*C+(p[3]==rows ? OV : 0)];
module panel_world(i) {
 R=panel_core(i);
 LOW=[for(s=SEAMS) if(s[4]==i) s];
 HIGH=[for(s=SEAMS) if(s[5]==i) s];
 difference() {
  intersection() {
   top_outline();
   difference() {
    union() {
     translate([R[0],R[1]]) square([R[2]-R[0],R[3]-R[1]]);
     for(s=LOW) seam_low_part(s);
     for(s=HIGH) seam_band(s);
    }
    for(s=LOW) difference() { seam_band(s); seam_low_part(s); }
    for(s=HIGH) offset(delta=puzzle_clearance) seam_low_part(s);
   }
  }
  if(panel_dogs(i)) for(p=dog_positions(i)) translate(p) circle(d=dog_hole_diameter);
 }
}

// ---------- part table ----------
// [id, kind, module (or strip/panel index), w, h, t, ox, oy, extra]; (ox,oy) is the lower-left of the outline in local coordinates.
CROSS_COLS=frame_cross_members=="every_column" ? [for(c=[0:cols-1]) c] : cols==1 ? [0] : [0,cols-1];
LONG_Y=[for(r=[0:rows-1]) for(o=[frame_rail_inset,C-frame_rail_inset]) r*C+o];
CROSS_X=[for(c=CROSS_COLS) for(o=[frame_rail_inset,C-frame_rail_inset]) c*C+o];
HT=registration_tab_height;
function module_parts(k)=let(id=str("M",k+1,"-"),W=mW(k),D=mD(k),H=mH(k),Wi=mWi(k),Dc=mDc(k),nd=door_count(k))
 concat(
 [[str(id,"SIDE-L"),"side_l",k,Dc,H,tc,0,0,0],[str(id,"SIDE-R"),"side_r",k,Dc,H,tc,0,0,0],
  [str(id,"BOTTOM"),"bottom",k,Wi+2*fl,Dc,tc,tc-fl,0,0],
  [str(id,"BACK"),"back",k,Wi+2*fl,H,tc,tc-fl,0,0],
  [str(id,"RAIL-F"),"rail_f",k,Wi+2*fl,RW,tc,tc-fl,td,0],
  [str(id,"RAIL-B"),"rail_b",k,Wi+2*fl,RW+tc,tc,tc-fl,back_rail_y0(k),0]],
 [for(i=[0:1:len(shelf_holes(k))-1]) [str(id,"SHELF-",i+1),"shelf",k,Wi-2*shelf_side_clearance,D-tc-shelf_rear_clearance-td-shelf_front_setback,ts,tc+shelf_side_clearance,td+shelf_front_setback,i]],
 [for(j=[0:1:nd-1]) [str(id,"DOOR-",j+1),"door",k,door_w(k),door_h(k),td,0,0,j]],
 has_handles ? [for(j=[0:1:nd-1]) [str(id,"HANDLE-",j+1),"handle",k,HL,HH,th,0,0,j]] : []);
function panel_bbox(i)=let(R=panel_rect(i)) [max(R[0],-OV),max(R[1],-OV),min(R[2],FL+OV),min(R[3],FD+OV)];
parts=concat(
 [for(i=[0:len(LONG_Y)-1]) [str("FR-L",i+1),"frame_long",i,FL,hf+HT,tf,0,0,LONG_Y[i]]],
 [for(i=[0:len(CROSS_X)-1]) [str("FR-C",i+1),"frame_cross",i,FD,hf+HT,tf,0,0,CROSS_X[i]]],
 [for(k=[0:1:NM-1]) each module_parts(k)],
 include_worksurface ? [for(i=[0:NP-1]) let(B=panel_bbox(i)) [str("TOP-",i+1),"top",i,B[2]-B[0],B[3]-B[1],tw,B[0],B[1],0]] : []);
NPART=len(parts);

// ---------- 2D outlines (local coordinates, machined face up) ----------
module relief_at(p,dir) { if(relief_on) translate(p+rr/sqrt(2)*dir) circle(r=rr); }
// Pocket or notch rectangle [x0,y0]-[x1,y1] with dogbones at the corners that are not open.
module pocket_rect(x0,y0,x1,y1,open_l=false,open_r=false,open_b=false,open_t=false) {
 translate([x0,y0]) slot_shape_2d(x1-x0,y1-y0,open_l,open_r,open_b,open_t);
 // extend open edges so the cut clears the panel edge
 if(open_l) translate([x0-1,y0]) square([1.01,y1-y0]);
 if(open_r) translate([x1-0.01,y0]) square([1.01,y1-y0]);
 if(open_b) translate([x0,y0-1]) square([x1-x0,1.01]);
 if(open_t) translate([x0,y1-0.01]) square([x1-x0,1.01]);
}
function strip_tabs(p)=p[1]=="frame_long" ? [for(c=[0:cols-1]) c*C+C/2] : [for(r=[0:rows-1]) r*C+C/2];
function strip_slots(p)=p[1]=="frame_long" ? CROSS_X : LONG_Y;
module strip_outline(p) {
 L=p[3]; h=hf; top=p[1]=="frame_long";
 difference() {
  union() {
   round_convex(3) polygon([[frame_foot_inset,0],[L-frame_foot_inset,0],[L,max(h-8,h/2)],[L,h],[0,h],[0,max(h-8,h/2)]]);
   for(x=strip_tabs(p)) translate([x-registration_tab_length/2,h-1]) square([registration_tab_length,HT+1]);
  }
  for(x=strip_slots(p)) if(top) pocket_rect(x-(tf+cl)/2,h/2-cl/2,x+(tf+cl)/2,h,open_t=true);
   else pocket_rect(x-(tf+cl)/2,0,x+(tf+cl)/2,h/2+cl/2,open_b=true);
  for(x=strip_tabs(p)) { relief_at([x-registration_tab_length/2,h],[-1,1]); relief_at([x+registration_tab_length/2,h],[1,1]); }
 }
}
// Side panel: u = depth from the carcass front (left side) or from the carcass back (right side), v = height.
function side_u(p,y)=p[1]=="side_r" ? mDc(p[2])-y : y;
module side_housings(p) {
 k=p[2]; Dc=mDc(k); H=mH(k); right=p[1]=="side_r";
 // back panel fingers along the rear edge
 for(f=back_fingers(H)) let(a=side_u(p,Dc-tc-cl),b=side_u(p,Dc)) pocket_rect(min(a,b),f[0]-cl/2,max(a,b),f[1]+cl/2,open_l=right,open_r=!right);
 // bottom fingers along the bottom edge
 for(f=bottom_side_fingers(k)) let(a=side_u(p,f[0]-cl/2),b=side_u(p,f[1]+cl/2)) pocket_rect(min(a,b),0,max(a,b),tc+cl,open_b=true);
 // top rail fingers along the top edge
 for(y0=[0,back_rail_y0(k)-td]) let(a=side_u(p,y0+rail_finger[0]-cl/2),b=side_u(p,y0+rail_finger[1]+cl/2)) pocket_rect(min(a,b),H-tc-cl,max(a,b),H,open_t=true);
}
module side_pins(p) {
 k=p[2]; Dc=mDc(k);
 for(z=pin_heights(k)) for(y=[shelf_pin_front_inset,Dc-tc-shelf_pin_rear_inset]) translate([side_u(p,y),z]) circle(d=shelf_pin_diameter);
}
// Bottom: u = local x, v = distance from the module's back face (underside up).
module bottom_outline(p) {
 k=p[2]; W=mW(k); Dc=mDc(k); D=mD(k);
 union() {
  translate([tc,tc]) square([W-2*tc,Dc-tc]);
  for(f=bottom_side_fingers(k)) for(x=[tc-fl,W-tc]) translate([x,Dc-f[1]]) square([fl+0.01,f[1]-f[0]]);
  for(f=bottom_rear_fingers(k)) translate([tc+f[0],0]) square([f[1]-f[0],tc+0.01]);
 }
}
module bottom_registration(p) {
 k=p[2]; D=mD(k); a=tf+2*registration_clearance; b=registration_tab_length+2*registration_clearance; i0=frame_rail_inset;
 for(i=[0:mW(k)/C-1]) for(j=[0:mD(k)/C-1]) let(x=i*C,y=j*C) {
  for(cx=[x+i0,x+C-i0]) let(v=D-(y+C/2)) pocket_rect(cx-a/2,v-b/2,cx+a/2,v+b/2);
  for(cy=[y+i0,y+C-i0]) let(v=D-cy) pocket_rect(x+C/2-b/2,v-a/2,x+C/2+b/2,v+a/2);
 }
}
// Back: u = local x, v = height.
module back_outline(p) {
 k=p[2]; W=mW(k); H=mH(k);
 difference() {
  union() {
   translate([tc,0]) square([W-2*tc,H]);
   for(f=back_fingers(H)) for(x=[tc-fl,W-tc]) translate([x,f[0]]) square([fl+0.01,f[1]-f[0]]);
  }
  for(f=bottom_rear_fingers(k)) pocket_rect(tc+f[0]-cl/2,0,tc+f[1]+cl/2,tc+cl,open_b=true);
  for(f=rail_rear_fingers(k)) pocket_rect(tc+f[0]-cl/2,H-tc-cl,tc+f[1]+cl/2,H,open_t=true);
 }
}
// Rails and shelves: u = local x, v = local y.
module hand_slots(k,y) {
 if(include_hand_slots) for(i=[0:mW(k)/C-1]) for(x=[i*C+C/4,i*C+3*C/4])
  hull() for(s=[-1,1]) translate([x+s*(hand_slot_length/2-hand_slot_width/2),y]) circle(d=hand_slot_width);
}
module rail_outline(p) {
 k=p[2]; W=mW(k); D=mD(k); back=p[1]=="rail_b"; y0=back ? back_rail_y0(k) : td;
 difference() {
  union() {
   translate([tc,y0]) square([W-2*tc,RW]);
   for(x=[tc-fl,W-tc]) translate([x,y0+rail_finger[0]]) square([fl+0.01,rail_finger[1]-rail_finger[0]]);
   if(back) for(f=rail_rear_fingers(k)) translate([tc+f[0],y0+RW-0.01]) square([f[1]-f[0],tc+0.01]);
  }
  hand_slots(k,back ? D-dog_hole_pitch/2 : dog_hole_pitch/2);
 }
}
// Door: u = from the door's right edge (seen from the front), v = height; inside face up.
module door_outline(p) {
 k=p[2]; j=p[8]; w=door_w(k); h=door_h(k);
 difference() {
  square([w,h]);
  if(has_handles) let(u=door_hinge_left(k,j) ? handle_edge_offset : w-handle_edge_offset)
   for(s=[-1,1]) translate([u+s*HSP/2,h-handle_top_offset]) circle(d=handle_hole_diameter);
 }
}
module door_cups(p) {
 k=p[2]; j=p[8]; w=door_w(k); h=door_h(k);
 u=door_hinge_left(k,j) ? w-hinge_cup_center_from_door_edge : hinge_cup_center_from_door_edge;
 for(v=hinge_vs(h)) translate([u,v]) circle(d=hinge_cup_diameter);
}
module part_outline(p) {
 k=p[1];
 if(k=="frame_long" || k=="frame_cross") strip_outline(p);
 else if(k=="side_l" || k=="side_r") square([p[3],p[4]]);
 else if(k=="bottom") bottom_outline(p);
 else if(k=="back") back_outline(p);
 else if(k=="rail_f" || k=="rail_b") rail_outline(p);
 else if(k=="shelf") translate([p[6],p[7]]) square([p[3],p[4]]);
 else if(k=="door") door_outline(p);
 else if(k=="handle") handle_profile();
 else if(k=="top") panel_world(p[2]);
}
module part_pockets(p,mode) {
 k=p[1];
 if(mode=="pocket_carcass_dados") {
  if(k=="side_l" || k=="side_r") side_housings(p);
  if(k=="bottom") bottom_registration(p);
 }
 if(mode=="pocket_shelf_pins" && (k=="side_l" || k=="side_r")) side_pins(p);
 if(mode=="pocket_hinge_cups" && k=="door") door_cups(p);
}
function pocket_depth(mode,p)=mode=="pocket_carcass_dados" ? (p[1]=="bottom" ? registration_pocket_depth : housing_depth) : mode=="pocket_shelf_pins" ? shelf_pin_depth : hinge_cup_depth;

// ---------- 3D ----------
// Local part frame (u,v, z = thickness with z=t the machined face) -> module or world frame.
function part_matrix(p)=let(k=p[1],m=p[2],t=p[5])
 k=="frame_long" ? [[1,0,0,0],[0,0,-1,p[8]+tf/2],[0,1,0,Zf],[0,0,0,1]] :
 k=="frame_cross" ? [[0,0,1,p[8]-tf/2],[1,0,0,0],[0,1,0,Zf],[0,0,0,1]] :
 k=="side_l" ? [[0,0,1,0],[1,0,0,td],[0,1,0,0],[0,0,0,1]] :
 k=="side_r" ? [[0,0,-1,mW(m)],[-1,0,0,mD(m)],[0,1,0,0],[0,0,0,1]] :
 k=="bottom" ? [[1,0,0,0],[0,-1,0,mD(m)],[0,0,-1,tc],[0,0,0,1]] :
 k=="back" ? [[1,0,0,0],[0,0,-1,mD(m)],[0,1,0,0],[0,0,0,1]] :
 k=="rail_f" || k=="rail_b" ? [[1,0,0,0],[0,1,0,0],[0,0,1,mH(m)-tc],[0,0,0,1]] :
 k=="shelf" ? [[1,0,0,0],[0,1,0,0],[0,0,1,shelf_z(m,p[8])],[0,0,0,1]] :
 k=="door" ? [[-1,0,0,door_x0(m,p[8])+door_w(m)],[0,0,1,0],[0,1,0,door_gap/2],[0,0,0,1]] :
 k=="handle" ? let(j=p[8],u=door_hinge_left(m,j) ? handle_edge_offset : door_w(m)-handle_edge_offset,xc=door_x0(m,j)+door_w(m)-u)
  [[1,0,0,xc-HL/2],[0,-1,0,0],[0,0,-1,door_gap/2+door_h(m)-handle_top_offset+th/2],[0,0,0,1]] :
 [[1,0,0,0],[0,1,0,0],[0,0,1,Ztop],[0,0,0,1]];
function is_module_part(p)=p[1]!="frame_long" && p[1]!="frame_cross" && p[1]!="top";
module panel3(p) {
 difference() {
  linear_extrude(p[5]) part_outline(p);
  for(mode=["pocket_carcass_dados","pocket_shelf_pins","pocket_hinge_cups"]) let(d=pocket_depth(mode,p))
   translate([0,0,p[5]-d]) linear_extrude(d+0.1) part_pockets(p,mode);
 }
}
module place3(p) {
 if(is_module_part(p)) multmatrix(mmatrix(p[2])) multmatrix(part_matrix(p)) panel3(p);
 else multmatrix(part_matrix(p)) panel3(p);
}
function part_colour(k)=k=="frame_long" || k=="frame_cross" ? [0.72,0.58,0.40] : k=="top" ? [0.85,0.70,0.48] : k=="door" ? [0.83,0.69,0.50] : k=="handle" ? [0.55,0.42,0.28] : k=="shelf" ? [0.86,0.75,0.58] : [0.78,0.65,0.45];
module casters() {
 s=caster_plate_size;
 if(Zf>0) for(x=[CROSS_X[0],CROSS_X[len(CROSS_X)-1]]) for(y=[LONG_Y[0],LONG_Y[len(LONG_Y)-1]]) translate([x,y,0]) {
  translate([-s/2,-s/2,Zf-4]) cube([s,s,4]);
  translate([-s/6,-s/4,Zf*0.35]) cube([s/3,s/2,Zf*0.65-4]);
  translate([0,0,Zf*0.35]) rotate([0,90,0]) cylinder(r=Zf*0.35,h=s/4,center=true);
 }
}
// Render the parts whose ids are listed (used by the interference test).
module render_ids(ids) { for(p=parts) if(len([for(i=ids) if(i==p[0]) 1])>0) place3(p); }
module assembly() {
 for(p=parts) if((p[1]!="top" || show_worksurface) && ((p[1]!="door" && p[1]!="handle") || show_doors)) color(part_colour(p[1])) place3(p);
 if(show_hardware) color([0.25,0.27,0.29]) casters();
}

// ---------- flat layout ----------
// Rows of parts no longer than the stock sheet, layout_gap apart.
ROWMAX=max(stock_width,max([for(p=parts) p[3]]));
function place_rows(k,x,y,rh,acc)=k>=NPART ? acc :
 let(w=parts[k][3],h=parts[k][4],wrap=x>0 && x+w>ROWMAX,nx=wrap ? 0 : x,ny=wrap ? y+rh+layout_gap : y,nrh=wrap ? h : max(rh,h))
 place_rows(k+1,nx+w+layout_gap,ny,nrh,concat(acc,[[nx,ny]]));
PL=place_rows(0,0,0,0,[]);
LW=max([for(k=[0:NPART-1]) PL[k][0]+parts[k][3]]);
LH=max([for(k=[0:NPART-1]) PL[k][1]+parts[k][4]]);
module registration() { difference() { translate([-20,-20]) square([LW+40,LH+40]); translate([-19,-19]) square([LW+38,LH+38]); } }
module at_layout(k) { translate([PL[k][0]-parts[k][6],PL[k][1]-parts[k][7]]) children(); }
module layout(mode) {
 registration();
 for(k=[0:NPART-1]) let(p=parts[k]) {
  if(mode=="cut_layout") at_layout(k) part_outline(p);
  else if(mode=="engrave_layout") { if(label_parts) translate([PL[k][0]+min(p[3]/2,60),PL[k][1]+min(p[4]/2,12)]) text(p[0],size=5,halign="center"); }
  else at_layout(k) part_pockets(p,mode);
 }
}

// ---------- validation and reports ----------
module check(ok,code,msg) { if(!ok) echo(str("CHECK|ERROR|",code,"|",msg)); }
module warn(ok,code,msg) { if(!ok) echo(str("CHECK|WARN|",code,"|",msg)); }
module validate() {
 check(min(tf,tc,td,ts,tw,th)>0,"POSITIVE_STOCK","Every stock thickness must be positive");
 check(frame_rail_inset>tf && frame_rail_inset+registration_tab_length/2<C/2-tf/2,"FRAME_INSET","Strip inset must clear the cell edge and the tabs of the crossing strips");
 check(registration_tab_length+2*registration_clearance<C-2*frame_rail_inset-tf,"TAB_LENGTH","Registration tabs must fit between the crossing strips");
 check(registration_pocket_depth>HT && registration_pocket_depth<tc,"REGISTRATION_DEPTH","Registration pockets must be deeper than the tabs and shallower than the module bottom");
 check(housing_depth>fl && housing_depth<tc,"HOUSING_DEPTH","Housings must be deeper than the fingers and shallower than the side stock");
 check(fl>=tc/2,"FINGER_LENGTH",str("Fingers of ",fl," mm hold too little of ",tc," mm stock"));
 check(hf>=4*HT && hf/2>rr*2,"FRAME_HEIGHT","Frame strips are too low for the half-lap joints and tabs");
 check(layout_gap>=router_bit_diameter+1,"LAYOUT_GAP","Layout gap must separate cutter paths");
 check(NM>0 || !include_worksurface,"WORKSURFACE_SUPPORT","The worksurface needs at least one module to rest on");
 for(k=[0:1:NM-1]) {
  id=str("M",k+1);
  check(in_grid(k),"MODULE_GRID",str(id," does not fit the ",cols," × ",rows," grid"));
  check(len([for(c=cells_of(k)) if(abs(under_top(k,c)-mz(k))>0.01) 1])==0,"MODULE_SUPPORT",str(id," is not fully supported: the cells under it end at different heights"));
  check(mH(k)>=2*tc+RW && mH(k)<=2400,"MODULE_HEIGHT",str(id," height must be between ",2*tc+RW," and 2400 mm"));
  check(mDc(k)-tc>=2*RW+10,"MODULE_DEPTH",str(id," is too shallow for its top rails"));
  // Only the base frame has registration tabs; a module standing on another needs screws through its bottom.
  warn(mz(k)<=Zbase+0.01,"STACK_FASTENING",str(id," stands on another module without registration tabs; screw it down through its bottom"));
  for(j=[0:1:NM-1]) if(blocks_front(k,j)) {
   if(mcontents(k)=="door") check(false,"MODULE_FACING",str(id,"'s doors open into M",j+1,"; face it to an open side"));
   else warn(false,"MODULE_FACING",str(id,"'s open front is behind M",j+1));
  }
  if(mshelves(k)>0) warn(len(shelf_holes(k))==mshelves(k),"SHELF_POSITIONS",str(id," has room for ",len(shelf_holes(k))," of ",mshelves(k)," shelves on its pin holes"));
  for(i=[0:1:len(shelf_holes(k))-1]) check(shelf_z(k,i)+ts<=mH(k)-tc-5,"SHELF_HEIGHT",str(id," shelf ",i+1," meets the top rails"));
  if(len(shelf_holes(k))>0) warn(mWi(k)<=600 || ts>=18,"SHELF_SPAN",str(id," shelves span ",mWi(k)," mm in ",ts," mm stock; expect sag under load"));
  check(mDc(k)-tc-shelf_pin_rear_inset>shelf_pin_front_inset+20,"SHELF_PINS",str(id," is too shallow for two rows of shelf pins"));
  if(door_count(k)>0) {
   check(door_w(k)>=2*hinge_cup_center_from_door_edge+hinge_cup_diameter,"DOOR_WIDTH",str(id," doors are too narrow for their hinges"));
   check(door_h(k)>=2*hinge_end_offset+hinge_cup_diameter,"DOOR_HEIGHT",str(id," doors are too short for two hinges"));
   check(hinge_cup_depth<td-2,"HINGE_DEPTH","Hinge cups must leave at least 2 mm of door");
   warn(door_w(k)<=650,"DOOR_WIDE",str(id," doors are ",door_w(k)," mm wide; consider narrower modules"));
   if(has_handles) check(handle_edge_offset>=HL/2+5 && handle_edge_offset<=door_w(k)-HL/2-5 && handle_top_offset>=th/2+5 && handle_top_offset<=door_h(k)-th/2-5,"HANDLE_POSITION",str(id," handle does not fit on its door"));
  }
  if(include_hand_slots) check(hand_slot_width+12<=RW && dog_hole_pitch/2-hand_slot_width/2>=td+6 && dog_hole_pitch/2+hand_slot_width/2<=td+RW-6,"HAND_SLOT",str(id," hand slots do not fit inside the top rails"));
 }
 if(include_worksurface) {
  unsupported=[for(c=[0:cols-1]) for(r=[0:rows-1]) if(column_top([c,r])<Ztop-0.01) 1];
  warn(len(unsupported)==0,"WORKSURFACE_SUPPORT",str(len(unsupported)," of ",cols*rows," cells have nothing under the worksurface; it rests on the tallest modules only"));
  check(dog_hole_pitch/2-dog_hole_diameter/2>=PD/2+3,"DOG_HOLE_SEAM","Dog holes must stay clear of the puzzle joints");
  check(PP/4-PD/2*tan(puzzle_angle)>=2*rr+3,"PUZZLE_NECK","Puzzle dovetails are too narrow at the neck for the cutter");
  for(s=SEAMS) for(seg=seam_segments(s)) check(seg[1]-seg[0]>=PP,"PUZZLE_SEGMENT",str("A worksurface seam is shorter than one puzzle pitch (",seg[1]-seg[0]," mm)"));
  for(i=[0:NP-1]) let(B=panel_bbox(i)) warn(max(B[2]-B[0],B[3]-B[1])<=max(stock_width,stock_height) && min(B[2]-B[0],B[3]-B[1])<=min(stock_width,stock_height),"PANEL_STOCK",str("Worksurface panel ",i+1," is larger than the stock sheet"));
 }
 warn(FL<=max(stock_width,stock_height)-2*layout_gap,"STRIP_STOCK",str("Frame strips of ",FL," mm do not fit the stock sheet"));
 echo("CHECK|INFO|HARDWARE_REFERENCE|Verify casters, hinges and screws against the purchased hardware before drilling");
 echo("CHECK|INFO|VALIDATION_SCOPE|Geometric/manufacturing checks only; no structural certification or CAM verification");
}
module reports() {
 echo(str("EXPORT_FRAME|X0=-20|Y0=-20|X1=",LW+20,"|Y1=",LH+20,"|FW=1"));
 if(validation_report!="off") validate();
 if(dimension_report!="off") {
  ow=FL+(include_worksurface ? 2*OV : 0); od=FD+(include_worksurface ? 2*OV : 0); oh=Ztop+(include_worksurface ? tw : 0);
  echo(str("DIM|CABINET|OUTSIDE|W=",ow,"|H=",oh,"|D=",od));
  echo(str("DIM|FRAME|W=",FL,"|D=",FD,"|H=",hf,"|CELLS=",cols,"x",rows,"|CELL=",C,"|TAB_H=",HT,"|CASTER_H=",Zf));
  for(k=[0:1:NM-1]) echo(str("DIM|MODULE|M",k+1,"|COL=",mcol(k)+1,"|ROW=",mrow(k)+1,"|W=",mW(k),"|D=",mD(k),"|H=",mH(k),"|Z=",mz(k),"|CONTENTS=",mcontents(k),"|FACING=",mfacing(k),"|SHELVES=",len(shelf_holes(k))));
  for(k=[0:1:NM-1]) for(j=[0:1:door_count(k)-1]) echo(str("DIM|DOOR|M",k+1,"-DOOR-",j+1,"|W=",door_w(k),"|H=",door_h(k),"|MOUNT=full_overlay|HINGE=",door_hinge_left(k,j) ? "left" : "right"));
  for(k=[0:1:NM-1]) for(i=[0:1:len(shelf_holes(k))-1]) echo(str("DIM|SHELF|M",k+1,"-SHELF-",i+1,"|STYLE=adjustable|CLEAR_SPAN_W=",mWi(k),"|CUT_W=",mWi(k)-2*shelf_side_clearance,"|D=",mD(k)-tc-shelf_rear_clearance-td-shelf_front_setback,"|Z=",shelf_z(k,i)));
  if(include_worksurface) echo(str("DIM|WORKSURFACE|W=",FL+2*OV,"|D=",FD+2*OV,"|Z=",Ztop,"|T=",tw,"|PANELS=",NP,"|DOG_HOLES=",len([for(i=[0:NP-1]) if(panel_dogs(i)) each dog_positions(i)])));
  echo(str("DIM|machining|HOUSING_DEPTH=",housing_depth,"|REGISTRATION_POCKET_DEPTH=",registration_pocket_depth,"|HINGE_CUP_DEPTH=",hinge_cup_depth,"|SHELF_PIN_DEPTH=",shelf_pin_depth,"|HALF_LAP=",hf/2));
 }
 if(system_contract_report!="off") {
  echo("SYSTEM|CONTRACT=MOI-4|ENGINE=modular_organization_v5");
  echo(str("MODULE|ID=workbench|KIND=workbench|W=",FL,"|D=",FD,"|H=",Ztop+(include_worksurface ? tw : 0)));
  echo("COVERAGE|SCOPE=workbench|CHECKS=grid_fit;module_support;facing;shelf_pins;hinge_room;handle_room;hand_slots;dog_holes;puzzle_neck;stock;cut_and_pocket_contours|STRUCTURAL=false");
 }
 check(layout_gap>0,"LAYOUT_OVERLAP",str("layout_gap is ",layout_gap," mm; parts of the flat cut layout would overlap."));
 if(output_mode=="bom") {
  for(p=parts) echo(str("BOM|",p[0],"|1|",p[1],"|plywood|",p[5],"|",p[3],"|",p[4],"|",
   p[1]=="bottom" ? "underside up: registration pockets" : p[1]=="door" ? "inside face up: hinge cups" : p[1]=="side_l" || p[1]=="side_r" ? "inside face up: housings and shelf pins" : p[1]=="handle" ? "drill two 15 mm pilot holes into the leg ends" : "through cuts only"));
  for(k=[0:NPART-1]) echo(str("PLACE|",parts[k][0],"|X=",PL[k][0],"|Y=",PL[k][1],"|W=",parts[k][3],"|H=",parts[k][4]));
  doors=len([for(p=parts) if(p[1]=="door") 1]);
  echo(str("HARDWARE|ID=casters|QTY=",Zf>0 ? 4 : 0,"|UNIT=plate casters|LENGTH=",Zf,"|NOTE=mounting plates under the outer strip crossings"));
  echo(str("HARDWARE|ID=cup_hinges|QTY=",sum([for(k=[0:1:NM-1]) door_count(k)>0 ? door_count(k)*hinge_count(door_h(k)) : 0]),"|UNIT=full overlay|NOTE=",hinge_cup_diameter," mm cups"));
  echo(str("HARDWARE|ID=shelf_pins|QTY=",4*len([for(p=parts) if(p[1]=="shelf") 1]),"|UNIT=",shelf_pin_diameter," mm pins"));
  echo(str("HARDWARE|ID=wood_screws_35mm|QTY=",sum([for(k=[0:1:NM-1]) 21+4*(mspx(k)*mspy(k)-1)]),"|UNIT=minimum estimate|NOTE=carcass joints; choose length for the stock"));
  echo(str("HARDWARE|ID=wood_screws_15mm|QTY=",doors*(4+(has_handles ? 2 : 0)),"|UNIT=minimum estimate|NOTE=hinges and handles"));
 }
}
reports();
if(output_mode=="assembly") assembly();
else if(output_mode=="flat_3d") for(k=[0:NPART-1]) translate([PL[k][0]-parts[k][6],PL[k][1]-parts[k][7],0]) panel3(parts[k]);
else if(output_mode=="cut_layout" || output_mode=="engrave_layout" || output_mode=="pocket_carcass_dados" || output_mode=="pocket_hinge_cups" || output_mode=="pocket_shelf_pins") layout(output_mode);
