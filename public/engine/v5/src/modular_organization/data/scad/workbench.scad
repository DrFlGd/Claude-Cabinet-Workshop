// Modular Organization: workbench — source entrypoint; units mm.
// Modular workbench: an egg-crate base frame on casters with a grid of registration tabs,
// cabinet modules that drop onto whole grid cells (and stack), and a puzzle-jointed
// worksurface with dog holes. X along the frame length (columns), Y front to back (rows),
// Z up. CUT coordinates show each part with its machined face up.
// Every part comes from one part table that drives assembly, CUT, POCKET, labels and BOM.
// See docs/MODULAR_WORKBENCH.md for the reference dimensions these defaults reproduce.
include <joinery.scad>
include <tab_pocket.scad>

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

// Drawer box sides, fronts and backs (cut from the shelf sheet in the reference set).
drawer_box_thickness = 12.00; // [3:0.01:40]

// Drawer box bottoms.
drawer_bottom_thickness = 12.00; // [3:0.01:40]

// Handle drilling jig plate and fence.
jig_thickness = 12.00; // [3:0.01:40]

/* [Machining / Tool and Kerf] */

// Cutter for through cuts and pockets; inside corners get at least its radius.
router_bit_diameter = 6.00; // [0.5:0.01:25]

/* [Machining / Shared Slot Relief] */

// Relief cut in the inside corners of slots and pockets so square parts seat fully.
slot_corner_relief = "dogbone"; // [none,dogbone,t_bone]

/* [Machining / Screw Marks] */

// Shallow drill marks where the assembly screws go (sides, back, bottom, rails, drawer box fronts and face panels).
include_screw_marks = true;

// Diameter of each screw mark.
screw_mark_diameter = 4.5; // [1:0.1:10]

// Depth of each screw mark.
screw_mark_depth = 1.5; // [0.2:0.1:5]

// Cell centre to the screws into the frame strips, along each strip line under a module.
frame_screw_offset = 78; // [10:0.5:190]

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

/* [Structure / Layout] */

// One row per module: [column, row, cells wide, cells deep, height mm, contents door|open|drawers|drawer_door|framed, shelves, facing front|back|left|right, hinge left|right, drawers, drawer columns 1|2]. Later rows stack on earlier ones.
// Drawer columns 2 puts two drawers side by side on every level of a drawers module at least two cells wide, beside a centre partition.
modules = [[0,0,1,1,730,"door",1,"front","left"],[1,0,2,1,730,"door",1,"front","right"],[0,1,1,1,730,"door",1,"back","right"],[1,1,1,1,730,"door",1,"back","right"],[2,1,1,1,730,"door",1,"back","right"]];

/* [Structure / Stacking] */

// Loose keys cut from frame stock locate a stacked module: each sits in a pocket in a top rail of the module below and in a registration pocket under the module above.
include_stack_keys = true;

/* [Structure / Faces] */

// Framed modules: width of the face panel around its rounded opening.
face_opening_border = 40; // [10:1:200]

// Framed modules: corner radius of the opening.
face_opening_radius = 60; // [0:1:300]

/* [Structure / Top] */

// Module top rails: depth of each rail.
top_rail_width = 75; // [30:1:200]

// Hand slots in the top rails, centred on the dog-hole rows.
include_hand_slots = true;

// Length of each hand slot.
hand_slot_length = 100; // [30:1:300]

// Width of each hand slot.
hand_slot_width = 25; // [10:1:60]

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

/* [Fronts / Layout and Reveals] */

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

/* [Drawers / Layout] */

// Height of each drawer front above the door of a drawer-and-door module.
combo_drawer_height = 150; // [60:1:600]

// Gap between the back of a drawer box and the module back.
drawer_rear_clearance = 5; // [0:1:100]

// Target height of each finger in the drawer box corner joints (an odd number of fingers is used).
drawer_finger_pitch = 35; // [10:1:150]

// Depth of the blind pockets in the box sides, front and back that take the bottom's tongues.
drawer_bottom_pocket_depth = 6; // [1:0.1:30]

// Length of the bottom's tongues; shorter than the pockets are deep.
drawer_bottom_tongue = 5; // [1:0.1:30]

/* [Drawers / Clearances] */

// Space left above and below each drawer box inside its share of the module.
drawer_vertical_clearance = 20; // [4:0.5:100]

// Drawer bottoms sit this far above the lower edge of the box.
drawer_bottom_inset = 8; // [0:0.5:60]

/* [Hardware / Hinges] */

// Concealed hinge cup diameter.
hinge_cup_diameter = 35; // [10:0.1:60]

// Concealed hinge cup depth.
hinge_cup_depth = 12; // [1:0.1:30]

// Hinge cup centre from the hinge edge of the door.
hinge_cup_center_from_door_edge = 21; // [5:0.1:60]

// Hinge cup centre from the top and bottom of the door.
hinge_end_offset = 87.5; // [20:0.1:300]

// Front edge of the module side to the hinge mounting-plate screws.
hinge_plate_setback = 37; // [10:0.1:100]

// Spacing of the two mounting-plate screws, centred on the hinge.
hinge_plate_screw_spacing = 32; // [10:0.1:80]

/* [Hardware / Slides] */

// Side-mount ball-bearing slides: space between the drawer box and each module side.
metal_slide_clearance_per_side = 12.7; // [0:0.1:40]

// Slide length; 0 picks the longest standard length (250 to 700 mm in 50 mm steps) that fits the module.
metal_slide_length = 0; // [0:10:1000]

// Slides start this far behind the front edge of the module sides.
metal_slide_front_setback = 3; // [0:0.5:50]

// Height of the slide profile; a drawer box must be taller.
metal_slide_envelope_height = 45; // [10:1:100]

/* [Hardware / Slide Drilling] */

// Drill the slide screw holes in the module sides and drawer boxes.
include_metal_slide_holes = true;

// Screw holes of the cabinet member, from the front of the slide (holes past the slide's end are left out).
metal_slide_cabinet_holes_x = [37,133,229,325];

// Screw holes of the drawer member, from the front of the slide.
metal_slide_drawer_holes_x = [37,133,229,325];

// Cabinet member screw hole diameter.
metal_slide_cabinet_hole_diameter = 5; // [1:0.1:10]

// Drawer member screw hole diameter (drilled through the box side).
metal_slide_drawer_hole_diameter = 5; // [1:0.1:10]

// Depth of the pilot holes in the module sides.
slide_drill_depth = 8; // [1:0.5:30]

// Holes closer than this to the rear end of the slide are left out.
metal_slide_hole_rear_margin = 10; // [0:1:100]

// Through holes in a drawer partition: one binding post (sex bolt) fixes the slides on both faces; match the post's barrel.
partition_slide_hole_diameter = 6; // [3:0.1:12]

/* [Hardware / Handles] */

// Plywood pulls cut from handle stock; none leaves the doors undrilled.
handle_style = "square"; // [none,square,rounded,chamfered,straight_bar,traditional]

// Screw clearance holes for the pulls (140 mm centres).
handle_hole_diameter = 4.5; // [2:0.1:10]

// Pilot holes drilled 15 mm into the ends of the pull's legs.
handle_pilot_diameter = 3.5; // [1:0.1:8]

// Add the drilling jig (block, plate and fence) for the pulls' pilot holes to the cut files.
include_handle_jig = false;

// Dowels that locate the drilling block on the jig plate.
jig_dowel_diameter = 8; // [3:0.1:12]

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
output_mode = "assembly"; // [assembly,flat_3d,cut_layout,engrave_layout,bom,pocket_carcass_dados,pocket_drawer_dados,pocket_hinge_cups,pocket_shelf_pins,pocket_slide_holes,pocket_screw_marks]

/* [Output / Visibility] */

// Show the casters.
show_hardware = true;

// Show the worksurface in the assembly.
show_worksurface = true;

// Show doors, drawer faces, face panels and pulls in the assembly.
show_doors = true;

// Show the drawer slides in the assembly.
show_drawer_slides = true;

/* [Output / Flat Layout] */

// Stock sheet the cut files are nested onto.
stock_width = 2440; // [300:1:5000]

// Short side of the stock sheet.
stock_height = 1220; // [300:1:5000]

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
tx=drawer_box_thickness; tbb=drawer_bottom_thickness;
cl=joint_fit_clearance;
fl=finger_length;
hf=frame_height;
Zf=caster_height;
Zbase=Zf+hf;
rr=router_bit_diameter/2;
relief_on=slot_corner_relief!="none" && router_bit_diameter>0;

// ---------- modules ----------
function mget(m,i,d)=len(m)>i && !is_undef(m[i]) ? m[i] : d;
CONTENTS=["door","open","drawers","drawer_door","framed"];
function norm_contents(c)=len([for(x=CONTENTS) if(x==c) 1])>0 ? c : "door";
function norm_module(m)=[max(0,floor(mget(m,0,0))),max(0,floor(mget(m,1,0))),max(1,floor(mget(m,2,1))),max(1,floor(mget(m,3,1))),
 mget(m,4,730),norm_contents(mget(m,5,"door")),max(0,min(8,floor(mget(m,6,1)))),
 let(f=mget(m,7,"front")) (f=="back" || f=="left" || f=="right") ? f : "front",mget(m,8,"right")=="left" ? "left" : "right",
 max(1,min(8,floor(mget(m,9,3)))),mget(m,10,1)==2 ? 2 : 1];
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
function mdrawers(k)=MODS[k][9];
function mdcols(k)=MODS[k][10];
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
// Drawers: n equal fronts over the whole height, or n fronts of combo_drawer_height above a door.
function drawer_n(k)=mcontents(k)=="drawers" || mcontents(k)=="drawer_door" ? mdrawers(k) : 0;
// Band of drawer j (j = 0 is the top drawer): [z0,z1] of its share of the module height.
function drawer_band(k,j)=let(H=mH(k),p=mcontents(k)=="drawers" ? H/drawer_n(k) : combo_drawer_height) [H-(j+1)*p,H-j*p];
// Part of the height behind the door (or the whole height without drawers).
function door_band(k)=[0,mcontents(k)=="drawer_door" ? mH(k)-drawer_n(k)*combo_drawer_height : mH(k)];
VC=drawer_vertical_clearance;
SC=metal_slide_clearance_per_side;
function dbox_z(k,j)=max(tc,drawer_band(k,j)[0])+VC/2;
function dbox_h(k,j)=min(mH(k)-tc,drawer_band(k,j)[1])-max(tc,drawer_band(k,j)[0])-VC;
// Drawer columns: two side by side beside a centre partition, on all-drawer modules two or more cells wide.
function dcols(k)=mcontents(k)=="drawers" && mdcols(k)==2 && mW(k)>=2*C-0.01 ? 2 : 1;
function has_partition(k)=dcols(k)==2;
function PX(k)=mW(k)/2;                                          // partition centre
function dcell_w(k)=dcols(k)==2 ? (mWi(k)-tc)/2 : mWi(k);       // opening of one column
function dbox_x0(k,c=0)=c==1 ? PX(k)+tc/2+SC : tc+SC;
function dbox_w(k)=dcell_w(k)-2*SC;
function pcol(p)=len(p)>9 ? p[9] : 0;
function dsuffix(k,c)=dcols(k)==2 ? (c==0 ? "L" : "R") : "";
SLIDES=[250,300,350,400,450,500,550,600,650,700];
// Room for a slide (and so the box) between the module's front edge and the back panel.
function slide_room(k)=mDc(k)-tc-drawer_rear_clearance;
function slide_auto(k)=let(fit=[for(s=SLIDES) if(s<=slide_room(k)) s]) len(fit)>0 ? max(fit) : 0;
function slide_len(k)=metal_slide_length>0 ? metal_slide_length : slide_auto(k);
// Box depth (the slide length), never below 100 mm so a failing design still draws.
function dbox_d(k)=max(100,slide_len(k));
function dfront_h(k,j)=drawer_band(k,j)[1]-drawer_band(k,j)[0]-door_gap;
function dfront_w(k)=mW(k)/dcols(k)-door_gap;
function dfront_x0(k,c)=c*mW(k)/dcols(k)+door_gap/2;
function dslide_z(k,j)=dbox_z(k,j)+dbox_h(k,j)/2;
function dslide_holes(k,list)=[for(x=list) if(x>=10 && x<=slide_len(k)-metal_slide_hole_rear_margin) x];
// Partition tenons, in local y: one through the bottom in the middle half of each cell row (clear of
// the registration pockets), and one through each top rail.
function partition_tenons_bottom(k)=[for(j=[0:1:mD(k)/C-1]) let(a=max(j*C+C/4,td+10),b=min(j*C+3*C/4,mD(k)-tc-10)) if(b-a>=20) [a,b]];
function partition_tenons_top(k)=[for(y0=[td,back_rail_y0(k)]) [y0+15,y0+RW-15]];
function partition_mortise(k,t)=[PX(k)-(tc+cl)/2,t[0]-cl/2,PX(k)+(tc+cl)/2,t[1]+cl/2];
function rail_mortises(k)=has_partition(k) ? [for(t=partition_tenons_top(k)) partition_mortise(k,t)] : [];
// Handle on a drawer front: centred across it, handle_top_offset below its top or half way down.
function dhandle_v(k,j)=dfront_h(k,j)-min(handle_top_offset,dfront_h(k,j)/2);
// Corner finger joints of the drawer boxes: an odd number of equal fields up the box height.
function dfields(bh)=let(n=max(1,round((bh/drawer_finger_pitch-1)/2))) [for(i=[0:2*n]) [i*bh/(2*n+1),(i+1)*bh/(2*n+1)]];
function dbottom_fingers(S)=fingers(S,60,60,30);
// Shelf pins stay below the drawers of a drawer-and-door module; all-drawer modules have none.
function shelf_zone_top(k)=door_band(k)[1];
function pin_heights(k)=let(top=shelf_zone_top(k),z0=tc+shelf_pin_first_height,n=floor((top-shelf_pin_top_clearance-z0)/shelf_pin_pitch)+1)
 mcontents(k)=="drawers" || n<1 ? [] : [for(i=[0:n-1]) z0+i*shelf_pin_pitch];
function sum(v,i=0)=i>=len(v) ? 0 : v[i]+sum(v,i+1);
function dedupe(L)=[for(i=[0:1:len(L)-1]) if(i==0 || L[i]!=L[i-1]) L[i]];
function shelf_holes(k)=let(P=pin_heights(k),n=mshelves(k),z0=tc+shelf_pin_first_height)
 len(P)==0 || n==0 ? [] : dedupe([for(i=[1:n]) let(target=tc+(shelf_zone_top(k)-2*tc)*i/(n+1)) P[max(0,min(len(P)-1,round((target-z0)/shelf_pin_pitch)))]]);
// Highest a shelf may reach: under the top rails, or under the lowest drawer box.
function shelf_ceiling(k)=mcontents(k)=="drawer_door" ? dbox_z(k,drawer_n(k)-1) : mH(k)-tc;
function shelf_z(k,i)=shelf_holes(k)[i]+shelf_pin_diameter/2;
function door_count(k)=mcontents(k)!="door" && mcontents(k)!="drawer_door" ? 0 : mW(k)<=C+0.01 ? 1 : 2;
function door_w(k)=mW(k)/door_count(k)-door_gap;
function door_h(k)=door_band(k)[1]-door_band(k)[0]-door_gap;
// Fronts that open: doors and drawers must not open into another module.
function opens(k)=door_count(k)>0 || drawer_n(k)>0;
function door_x0(k,j)=j*mW(k)/door_count(k)+door_gap/2;
function door_hinge_left(k,j)=door_count(k)==1 ? mhinge(k)=="left" : j==0;
function hinge_count(Hd)=Hd>1500 ? 4 : Hd>1000 ? 3 : 2;
function hinge_vs(Hd)=let(n=hinge_count(Hd)) [for(i=[0:n-1]) hinge_end_offset+i*(Hd-2*hinge_end_offset)/(n-1)];

// ---------- handles ----------
// Every handle in the set screws on at 140 mm centres from the back of the door, into 15 mm pilot
// holes drilled in the ends of its two legs. The profiles are generated from the reference set's
// dimensions (lengths, leg widths, radii, chamfer angle and arc radii); see docs/MODULAR_WORKBENCH.md.
// Every profile dimension lies in the plane of the handle stock, so none depends on handle_thickness:
// thicker stock makes the same profile taller across the door. What does depend on it scales with
// th: the pull's placement on its hole line, the pilot holes at th/2, and the jig (block thickness,
// fence height th+7, guide holes th/2 above the plate).
// Each profile is drawn with the feet on y = 0 and is the solid minus handle_air(): the finger
// recess between the legs and, on the traditional pull, the notches under its wings.
HSP=140;
HL=handle_style=="chamfered" ? 184 : handle_style=="straight_bar" ? 202 : handle_style=="traditional" ? 210 : 162;
HH=handle_style=="chamfered" ? 42 : handle_style=="traditional" ? 49 : 45;
has_handles=handle_style!="none";
module round_convex(r) { offset(r=r) offset(delta=-r) children(); }
module round_concave(r) { offset(r=-r) offset(delta=r) children(); }
module mirror_x(L) { children(); translate([L,0]) mirror([1,0]) children(); }
// Traditional pull: a crown arc through the ends (17 mm high) and the middle (full height), wings
// whose undersides follow a second, flatter arc that also forms the recess top (34 mm), rounded
// tips tangent to both arcs, and legs leaning in at 8 degrees with 6.5 and 15 mm fillets.
TR_END=17; TR_APEX=34; TR_R2=217.667; TR_TIP=4.419; TR_LEG=[24,46]; TR_LEAN=8; TR_NOTCH_R=6.5; TR_RECESS_R=15;
TR_R1=((HL/2)*(HL/2)+(HH-TR_END)*(HH-TR_END))/(2*(HH-TR_END));
TR_C1=HH-TR_R1; TR_C2=TR_APEX-TR_R2;            // y of the two arc centres (both on x = HL/2)
// Tip circle centre: |P-C1| = R1-r and |P-C2| = R2+r.
TR_TY=(pow(TR_R1-TR_TIP,2)-pow(TR_R2+TR_TIP,2))/(2*(TR_C2-TR_C1))+(TR_C1+TR_C2)/2;
TR_TX=HL/2-sqrt(pow(TR_R1-TR_TIP,2)-pow(TR_TY-TR_C1,2));
function tr_face(x0,s,y)=x0+s*y*tan(TR_LEAN);   // a leaning leg face, s = +1 leans right going up
module tr_disc2() { translate([HL/2,TR_C2]) circle(r=TR_R2,$fn=720); }
module tr_band(x0,s0,x1,s1) { polygon([[tr_face(x0,s0,-10),-10],[tr_face(x1,s1,-10),-10],[tr_face(x1,s1,60),60],[tr_face(x0,s0,60),60]]); }
// Fillet between the inner leg face and the recess arc: its centre lies 15 mm off the face and
// R2-15 from the arc centre; TR_FY is where it meets the face (the recess is widest there).
TR_T=tan(TR_LEAN); TR_A=TR_LEG[1]+TR_RECESS_R/cos(TR_LEAN)-HL/2; TR_Q=TR_R2-TR_RECESS_R;
TR_FCY=let(qa=TR_T*TR_T+1,qb=-2*TR_A*TR_T-2*TR_C2,qc=TR_A*TR_A+TR_C2*TR_C2-TR_Q*TR_Q) (-qb+sqrt(qb*qb-4*qa*qc))/(2*qa);
TR_FY=TR_FCY-TR_RECESS_R*sin(TR_LEAN);
// The finger recess between the legs (open below the feet).
module handle_recess() {
 L=HL;
 if(handle_style=="square") intersection() { translate([0,-1]) square([L,31]); hull() for(x=[52,L-52]) translate([x,0]) circle(r=30); }
 else if(handle_style=="rounded") intersection() { translate([22,-1]) square([L-44,31]); hull() { translate([22,-1]) square([L-44,11]); for(x=[42,L-42]) translate([x,10]) circle(r=20); } }
 else if(handle_style=="chamfered") hull() { translate([33,-1]) square([L-66,1]); mirror_x(L) { translate([40.5,9.301]) circle(r=7.5); translate([56.337,12]) circle(r=15); } }
 else if(handle_style=="straight_bar") translate([42,-1]) { round_convex(10) square([L-84,31]); square([L-84,11]); }
 else if(handle_style=="traditional") round_convex(TR_RECESS_R) intersection() { tr_disc2(); tr_band(TR_LEG[1],-1,L-TR_LEG[1],1); }
}
module handle_air() {
 handle_recess();
 if(handle_style=="traditional") mirror_x(HL) round_convex(TR_NOTCH_R) intersection() { tr_disc2(); tr_band(-20,0,TR_LEG[0],1); }
}
module handle_solid() {
 L=HL; H=HH;
 if(handle_style=="square") hull() { square([L,H-3]); for(x=[3,L-3]) translate([x,H-3]) circle(r=3); }
 else if(handle_style=="rounded") intersection() { square([L,H]); hull() { square([L,3]); for(x=[42,L-42]) translate([x,3]) circle(r=42); } }
 else if(handle_style=="chamfered") intersection() { square([L,H]); hull() { square([L,1]); mirror_x(L) { translate([7.5,6.038]) circle(r=7.5); translate([47.138,27]) circle(r=15); } } }
 else if(handle_style=="straight_bar") round_concave(10) union() { translate([0,30]) round_convex(5) square([L,15]); for(x=[20,L-42]) translate([x,0]) square([22,31]); }
 else if(handle_style=="traditional") {
  // crown arc, trimmed at each end by the wedge between the tip circle's two tangent points
  difference() {
   intersection() { translate([L/2,TR_C1]) circle(r=TR_R1,$fn=720); square([L,H]); }
   mirror_x(L) let(a=atan2(TR_TY-TR_C1,TR_TX-L/2),b0=atan2(TR_C2-TR_TY,L/2-TR_TX),b=b0<a ? b0+360 : b0)
    translate([TR_TX,TR_TY]) polygon([[0,0],50*[cos(a),sin(a)],50*[cos((a+b)/2),sin((a+b)/2)],50*[cos(b),sin(b)]]);
  }
  mirror_x(L) translate([TR_TX,TR_TY]) circle(r=TR_TIP);
 }
}
module handle_profile() { difference() { handle_solid(); handle_air(); } }
// Handle drilling jig: a block shaped like the finger recess (cut from handle stock), a plate with a
// mortise for a fence, and the fence with two guide holes at 140 mm centres, half the handle stock
// above the plate. The pull lies flat over the block with its feet against the fence, and the leg
// pilot holes are drilled through the fence. Dowels in two holes 70 apart, 15 mm from the fence,
// locate the block on the plate.
HBX=handle_style=="square" || handle_style=="rounded" ? 22 : handle_style=="chamfered" ? 33 : handle_style=="straight_bar" ? 42 : tr_face(TR_LEG[1],-1,TR_FY);
HBH=handle_style=="traditional" ? TR_APEX : handle_style=="chamfered" ? 27 : 30;   // recess height
module handle_block() {
 difference() {
  intersection() { handle_recess(); square([HL,HBH+1]); }
  for(s=[-1,1]) translate([HL/2+s*HSP/4,15]) circle(d=jig_dowel_diameter);
 }
}
tj=jig_thickness;
JIG_L=HSP+100; JIG_FY=10;                     // plate length; notched edge to the fence mortise
JIG_D=JIG_FY+tj+75;                           // plate depth
JIG_FH=th+7;                                  // fence height above the plate
JIG_TAB=40;                                   // fence tab length
module jig_plate() {
 difference() {
  intersection() {
   round_convex(10) square([JIG_L,JIG_D]);
   round_concave(8) round_convex(8) difference() {
    square([JIG_L,JIG_D]);
    // drill clearance notches under the guide holes
    for(s=[-1,1]) translate([JIG_L/2+s*HSP/2,0]) polygon([[-26,-1],[26,-1],[15,10],[-15,10]]);
   }
  }
  translate([JIG_L/2-(JIG_TAB+cl)/2,JIG_FY-cl/2]) tp_pocket_2d(JIG_TAB+cl,tj+cl,router_bit_diameter,relief_on ? "t_bone" : "none");
  for(s=[-1,1]) translate([JIG_L/2+s*HSP/4,JIG_FY+tj+15]) circle(d=jig_dowel_diameter);
  for(x=[17,JIG_L-17]) translate([x,16]) circle(d=handle_hole_diameter);
 }
}
module jig_fence() {
 difference() {
  union() {
   translate([0,tj]) hull() { square([JIG_L,1]); for(x=[10,JIG_L-10]) translate([x,JIG_FH-10]) circle(r=10); }
   translate([JIG_L/2-JIG_TAB/2,0]) square([JIG_TAB,tj+0.01]);
  }
  if(relief_on) tp_tab_root_reliefs_2d(JIG_L/2-JIG_TAB/2,JIG_TAB,tj,router_bit_diameter);
  for(s=[-1,1]) translate([JIG_L/2+s*HSP/2,tj+th/2]) circle(d=handle_pilot_diameter);
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

// ---------- stacking keys ----------
// A module standing on another is located by loose keys: frame-stock blocks the size of a frame
// tab, twice as tall, each standing in a pocket in a top rail of the module below and in one of
// the registration pockets under the module above (every cell of a bottom has four).
KEY_L=registration_tab_length+2*registration_clearance;   // pocket length
KEY_W=tf+2*registration_clearance;                        // pocket width
// The four registration sites of a cell, in world coordinates: [x, y, axis of the key's length].
function cell_sites(c)=let(x=c[0]*C,y=c[1]*C,i0=frame_rail_inset) [[x+C/2,y+i0,"x"],[x+C/2,y+C-i0,"x"],[x+i0,y+C/2,"y"],[x+C-i0,y+C/2,"y"]];
// World XY to module k's local frame (the inverse of mmatrix's rotation is its transpose).
function to_local(k,p)=let(M=mmatrix(k),dx=p[0]-M[0][3],dy=p[1]-M[1][3]) [M[0][0]*dx+M[1][0]*dy,M[0][1]*dx+M[1][1]*dy];
function local_axis(k,ax)=msideways(k) ? (ax=="x" ? "y" : "x") : ax;
// Pocket rectangle [x0,y0,x1,y1] of a site in module k's local frame.
function site_rect(k,s)=let(q=to_local(k,[s[0],s[1]]),la=local_axis(k,s[2]),hx=(la=="x" ? KEY_L : KEY_W)/2,hy=(la=="x" ? KEY_W : KEY_L)/2) [q[0]-hx,q[1]-hy,q[0]+hx,q[1]+hy];
function rail_body(k,back)=let(y0=back ? back_rail_y0(k) : td) [tc,y0,mW(k)-tc,y0+RW];
function rect_inside(r,b,m)=r[0]>=b[0]+m && r[1]>=b[1]+m && r[2]<=b[2]-m && r[3]<=b[3]-m;
function rects_meet(a,b,m)=a[0]<b[2]+m && b[0]<a[2]+m && a[1]<b[3]+m && b[1]<a[3]+m;
function slot_centre_y(k,back)=back ? mD(k)-dog_hole_pitch/2 : dog_hole_pitch/2;
function slot_rects(k,back)=include_hand_slots ? [for(i=[0:mW(k)/C-1]) for(x=[i*C+C/4,i*C+3*C/4])
 [x-hand_slot_length/2,slot_centre_y(k,back)-hand_slot_width/2,x+hand_slot_length/2,slot_centre_y(k,back)+hand_slot_width/2]] : [];
function site_on_rail(k,s,back)=let(r=site_rect(k,s)) rect_inside(r,rail_body(k,back),3) && len([for(h=concat(slot_rects(k,back),rail_mortises(k))) if(rects_meet(r,h,3)) 1])==0;
// [upper module, lower module, world x, world y, axis, in the lower module's back rail]
KEYS=include_stack_keys ? [for(u=[0:1:NM-1]) if(mz(u)>Zbase+0.01) for(j=[0:1:u-1]) if(share(j,u) && abs(mtop(j)-mz(u))<0.01)
 for(c=cells_of(u)) if(covers(j,c)) for(s=cell_sites(c)) for(b=[false,true]) if(site_on_rail(j,s,b)) [u,j,s[0],s[1],s[2],b]] : [];
function keys_under(u)=len([for(q=KEYS) if(q[0]==u) 1]);

// ---------- part table ----------
// [id, kind, module (or strip/panel index), w, h, t, ox, oy, extra]; (ox,oy) is the lower-left of the outline in local coordinates.
CROSS_COLS=frame_cross_members=="every_column" ? [for(c=[0:cols-1]) c] : cols==1 ? [0] : [0,cols-1];
LONG_Y=[for(r=[0:rows-1]) for(o=[frame_rail_inset,C-frame_rail_inset]) r*C+o];
CROSS_X=[for(c=CROSS_COLS) for(o=[frame_rail_inset,C-frame_rail_inset]) c*C+o];
HT=registration_tab_height;
// Drawer parts carry their level j at index 8 and their column c (0 left, 1 right) at index 9.
function drawer_parts(k)=let(id=str("M",k+1,"-DRAWER-"),Bw=dbox_w(k),Ld=dbox_d(k))
 [for(j=[0:1:drawer_n(k)-1]) for(c=[0:1:dcols(k)-1]) let(d=str(id,j+1,dsuffix(k,c),"-"),bh=dbox_h(k,j),tg=drawer_bottom_tongue) each concat(
  [[str(d,"SIDE-L"),"dr_side_l",k,Ld,bh,tx,0,0,j,c],[str(d,"SIDE-R"),"dr_side_r",k,Ld,bh,tx,0,0,j,c],
   [str(d,"FRONT"),"dr_front",k,Bw,bh,tx,0,0,j,c],[str(d,"BACK"),"dr_back",k,Bw,bh,tx,0,0,j,c],
   [str(d,"BOTTOM"),"dr_bottom",k,Bw-2*tx+2*tg,Ld-2*tx+2*tg,tbb,tx-tg,tx-tg,j,c],
   [str(d,"FACE"),"dr_face",k,dfront_w(k),dfront_h(k,j),td,0,0,j,c]],
  has_handles ? [[str(d,"HANDLE"),"dr_handle",k,HL,HH,th,0,0,j,c]] : [])];
function module_parts(k)=let(id=str("M",k+1,"-"),W=mW(k),D=mD(k),H=mH(k),Wi=mWi(k),Dc=mDc(k),nd=door_count(k))
 concat(
 [[str(id,"SIDE-L"),"side_l",k,Dc,H,tc,0,0,0],[str(id,"SIDE-R"),"side_r",k,Dc,H,tc,0,0,0],
  [str(id,"BOTTOM"),"bottom",k,Wi+2*fl,Dc,tc,tc-fl,0,0],
  [str(id,"BACK"),"back",k,Wi+2*fl,H,tc,tc-fl,0,0],
  [str(id,"RAIL-F"),"rail_f",k,Wi+2*fl,RW,tc,tc-fl,td,0],
  [str(id,"RAIL-B"),"rail_b",k,Wi+2*fl,RW+tc,tc,tc-fl,back_rail_y0(k),0]],
 [for(i=[0:1:len(shelf_holes(k))-1]) [str(id,"SHELF-",i+1),"shelf",k,Wi-2*shelf_side_clearance,D-tc-shelf_rear_clearance-td-shelf_front_setback,ts,tc+shelf_side_clearance,td+shelf_front_setback,i]],
 [for(j=[0:1:nd-1]) [str(id,"DOOR-",j+1),"door",k,door_w(k),door_h(k),td,0,0,j]],
 has_handles ? [for(j=[0:1:nd-1]) [str(id,"HANDLE-",j+1),"handle",k,HL,HH,th,0,0,j]] : [],
 mcontents(k)=="framed" ? [[str(id,"FACE"),"face",k,W-door_gap,H-door_gap,td,0,0,0]] : [],
 has_partition(k) ? [[str(id,"PARTITION"),"partition",k,Dc-tc,H,tc,0,0,0]] : [],
 drawer_parts(k));
function panel_bbox(i)=let(R=panel_rect(i)) [max(R[0],-OV),max(R[1],-OV),min(R[2],FL+OV),min(R[3],FD+OV)];
parts=concat(
 [for(i=[0:len(LONG_Y)-1]) [str("FR-L",i+1),"frame_long",i,FL,hf+HT,tf,0,0,LONG_Y[i]]],
 [for(i=[0:len(CROSS_X)-1]) [str("FR-C",i+1),"frame_cross",i,FD,hf+HT,tf,0,0,CROSS_X[i]]],
 [for(k=[0:1:NM-1]) each module_parts(k)],
 [for(i=[0:1:len(KEYS)-1]) [str("KEY-",i+1),"stack_key",KEYS[i][1],registration_tab_length,2*HT,tf,0,0,KEYS[i]]],
 include_handle_jig && has_handles ? [["JIG-BLOCK","jig_block",0,HL-2*HBX,HBH,th,HBX,0,0],["JIG-PLATE","jig_plate",0,JIG_L,JIG_D,tj,0,0,0],["JIG-FENCE","jig_fence",0,JIG_L,tj+JIG_FH,tj,0,0,0]] : [],
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
 difference() {
  union() {
   translate([tc,tc]) square([W-2*tc,Dc-tc]);
   for(f=bottom_side_fingers(k)) for(x=[tc-fl,W-tc]) translate([x,Dc-f[1]]) square([fl+0.01,f[1]-f[0]]);
   for(f=bottom_rear_fingers(k)) translate([tc+f[0],0]) square([f[1]-f[0],tc+0.01]);
  }
  // mortises for the drawer partition's tenons (v runs from the back)
  if(has_partition(k)) for(t=partition_tenons_bottom(k)) let(r=partition_mortise(k,t)) pocket_rect(r[0],D-r[3],r[2],D-r[1]);
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
  for(r=rail_mortises(k)) if(r[1]>=y0 && r[3]<=y0+RW) pocket_rect(r[0],r[1],r[2],r[3]);
 }
}
// Drawer partition: u = depth from the module's front edge, v = height from the module's underside.
// Tenons pass through the bottom and both top rails and finish flush with their outer faces.
module partition_outline(p) {
 k=p[2]; L=p[3]; H=mH(k);
 difference() {
  union() {
   translate([0,tc]) square([L,H-2*tc]);
   for(t=partition_tenons_bottom(k)) translate([t[0]-td,0]) square([t[1]-t[0],tc+0.01]);
   for(t=partition_tenons_top(k)) translate([t[0]-td,H-tc-0.01]) square([t[1]-t[0],tc+0.01]);
  }
  if(relief_on) {
   for(t=partition_tenons_bottom(k)) tp_tab_root_reliefs_2d(t[0]-td,t[1]-t[0],tc,router_bit_diameter);
   for(t=partition_tenons_top(k)) tp_tab_root_reliefs_2d(t[0]-td,t[1]-t[0],H-tc,router_bit_diameter);
  }
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
// Face panel of a framed module: inside face up, a rounded opening inside a border.
module face_outline(p) {
 w=p[3]; h=p[4]; b=face_opening_border; r=max(0,min(face_opening_radius,(w-2*b)/2-1,(h-2*b)/2-1));
 difference() {
  square([w,h]);
  translate([b,b]) round_convex(r) square([w-2*b,h-2*b]);
 }
}
// Drawer face: u = from its right edge seen from the front, v = height; inside face up.
module dr_face_outline(p) {
 k=p[2]; j=p[8]; w=p[3];
 difference() {
  square([w,p[4]]);
  if(has_handles) for(s=[-1,1]) translate([w/2+s*HSP/2,dhandle_v(k,j)]) circle(d=handle_hole_diameter);
 }
}
// Drawer box side: u = depth from the box front (left side) or from its back (right side), v = height.
// The odd fields at both ends are notched for the box front and back; the even fields are its fingers.
module dr_side_outline(p) {
 L=p[3]; F=dfields(p[4]);
 difference() {
  square([L,p[4]]);
  for(i=[1:2:len(F)-1]) {
   pocket_rect(0,F[i][0]-cl/2,tx,F[i][1]+cl/2,open_l=true);
   pocket_rect(L-tx,F[i][0]-cl/2,L,F[i][1]+cl/2,open_r=true);
  }
 }
}
// Drawer box front or back: u = across the box, v = height; the even fields at the ends are notched.
module dr_cross_outline(p) {
 L=p[3]; F=dfields(p[4]); n=len(F);
 difference() {
  square([L,p[4]]);
  for(i=[0:2:n-1]) let(y0=F[i][0]-(i==0 ? 0 : cl/2),y1=F[i][1]+(i==n-1 ? 0 : cl/2)) {
   pocket_rect(0,y0,tx,y1,open_l=true,open_b=i==0,open_t=i==n-1);
   pocket_rect(L-tx,y0,L,y1,open_r=true,open_b=i==0,open_t=i==n-1);
  }
 }
}
// Drawer bottom in the box's plan (u across, v front to back): tongues on all four edges, with
// T-bone reliefs at their roots so the shoulders seat against the inside faces of the box.
module dr_bottom_outline(p) {
 k=p[2]; Bw=dbox_w(k); Ld=dbox_d(k); tg=drawer_bottom_tongue;
 FX=dbottom_fingers(Bw-2*tx); FY=dbottom_fingers(Ld-2*tx);
 difference() {
  union() {
   translate([tx,tx]) square([Bw-2*tx,Ld-2*tx]);
   for(f=FX) for(y=[tx-tg,Ld-tx-0.01]) translate([tx+f[0],y]) square([f[1]-f[0],tg+0.01]);
   for(f=FY) for(x=[tx-tg,Bw-tx-0.01]) translate([x,tx+f[0]]) square([tg+0.01,f[1]-f[0]]);
  }
  if(relief_on) {
   for(f=FX) for(y=[tx,Ld-tx]) tp_tab_root_reliefs_2d(tx+f[0],f[1]-f[0],y,router_bit_diameter);
   for(f=FY) for(x=[tx,Bw-tx]) multmatrix([[0,1,0,0],[1,0,0,0],[0,0,1,0],[0,0,0,1]]) tp_tab_root_reliefs_2d(tx+f[0],f[1]-f[0],x,router_bit_diameter);
  }
 }
}
// Blind pockets for the bottom's tongues on the inside face of a box side, front or back.
module dr_bottom_pockets(p) {
 L=p[3]; bi=drawer_bottom_inset;
 for(f=dbottom_fingers(L-2*tx)) pocket_rect(tx+f[0]-cl/2,bi-cl/2,tx+f[1]+cl/2,bi+tbb+cl/2);
}
function dside_u(p,y)=p[1]=="dr_side_r" ? p[3]-y : y;
module slide_holes(p) {
 k=p[2];
 if(include_metal_slide_holes) {
  if(p[1]=="side_l" || p[1]=="side_r") for(j=[0:1:drawer_n(k)-1]) for(x=dslide_holes(k,metal_slide_cabinet_holes_x))
   translate([side_u(p,metal_slide_front_setback+x),dslide_z(k,j)]) circle(d=metal_slide_cabinet_hole_diameter);
  if(p[1]=="dr_side_l" || p[1]=="dr_side_r") for(x=dslide_holes(k,metal_slide_drawer_holes_x))
   translate([dside_u(p,metal_slide_front_setback+x),p[4]/2]) circle(d=metal_slide_drawer_hole_diameter);
  // one through hole per screw position takes a binding post for the slides on both faces
  if(p[1]=="partition") for(j=[0:1:drawer_n(k)-1]) for(x=dslide_holes(k,metal_slide_cabinet_holes_x))
   translate([metal_slide_front_setback+x,dslide_z(k,j)]) circle(d=partition_slide_hole_diameter);
 }
}
// Pockets in a top rail for the stacking keys of the module above.
module rail_key_pockets(p) {
 back=p[1]=="rail_b";
 for(q=KEYS) if(q[1]==p[2] && q[5]==back) let(r=site_rect(p[2],[q[2],q[3],q[4]])) pocket_rect(r[0],r[1],r[2],r[3]);
}
// Screw marks: shallow drill points on the machined face where the assembly screws go.
function web_gaps(F,span)=let(a=concat([0],[for(f=F) f[1]]),b=concat([for(f=F) f[0]],[span])) [for(i=[0:1:len(F)]) if(b[i]-a[i]>=screw_mark_diameter+2) (a[i]+b[i])/2];
function on_frame(k)=mz(k)<=Zbase+0.01;
function under_worksurface(k)=include_worksurface && abs(mtop(k)-Ztop)<0.01;
function slot_edge(k,back)=include_hand_slots ? (back ? mD(k)-dog_hole_pitch/2-hand_slot_width/2 : dog_hole_pitch/2+hand_slot_width/2) : (back ? mD(k)-tc : td);
function screw_marks(p)=let(k=p[1],m=p[2]) !include_screw_marks ? [] :
 k=="side_l" || k=="side_r" ? let(Dc=mDc(m),H=mH(m),BF=back_fingers(H),Lf=H/(2*len(BF)+1),SF=bottom_side_fingers(m)) concat(
  [for(i=[0:1:len(BF)-1]) [side_u(p,Dc-tc/2),(2*i+0.5)*Lf]],                                  // into the back, between its fingers
  [for(i=[0:1:len(SF)-1]) [side_u(p,((i==0 ? 0 : SF[i-1][1])+SF[i][0])/2),tc/2]],             // into the bottom, in front of each finger
  [for(y0=[0,back_rail_y0(m)-td]) for(c=[rail_finger[0]/2,(rail_finger[1]+RW)/2]) [side_u(p,y0+c),H-tc/2]],  // into the top rails
  // hinge mounting plates, on both sides so a single door can be hung either way
  door_count(m)>0 ? [for(v=hinge_vs(door_h(m))) for(s=[-1,1]) [side_u(p,hinge_plate_setback),door_gap/2+v+s*hinge_plate_screw_spacing/2]] : []) :
 k=="back" ? concat([for(c=web_gaps(bottom_rear_fingers(m),mWi(m))) [tc+c,tc/2]],                // into the bottom
  has_partition(m) ? [for(f=[1:3]) [PX(m),tc+(mH(m)-2*tc)*f/4]] : []) :                         // into the partition
 k=="bottom" && on_frame(m) ? let(D=mD(m),i0=frame_rail_inset,o=frame_screw_offset)              // down into the frame strips
  [for(i=[0:mW(m)/C-1]) for(j=[0:mD(m)/C-1]) let(x=i*C,y=j*C) each concat(
   [for(cx=[x+i0,x+C-i0]) for(s=[-1,1]) [cx,D-(y+C/2)+s*o]],
   [for(cy=[y+i0,y+C-i0]) for(s=[-1,1]) [x+C/2+s*o,D-cy]])] :
 k=="rail_f" || k=="rail_b" ? let(back=k=="rail_b",y0=back ? back_rail_y0(m) : td,inner=back ? y0 : y0+RW) concat(
  back ? [for(f=rail_rear_fingers(m)) [tc+(f[0]+f[1])/2,y0+RW+tc/2]] : [],                     // down into the back
  under_worksurface(m) ? [for(i=[0:mW(m)/C-1]) for(x=[i*C+C/4,i*C+3*C/4]) [x,(inner+slot_edge(m,back))/2]] : []) :  // up into the worksurface
 k=="dr_front" ? let(L=p[3],h=p[4],lo=drawer_bottom_inset+tbb+12,hi=h-15)                          // into the drawer face
  [for(u=[tx+25,L-tx-25]) for(v=hi-lo>=15 ? [lo,hi] : [(drawer_bottom_inset+tbb+h)/2]) [u,v]] :
 k=="face" ? let(w=p[3],H=mH(m)) [for(u=[tc/2-door_gap/2,w+door_gap/2-tc/2]) for(z=[H/4,3*H/4]) [u,z-door_gap/2]] : [];  // into the module sides
module screw_mark_holes(p) { for(q=screw_marks(p)) translate(q) circle(d=screw_mark_diameter); }
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
 else if(k=="face") face_outline(p);
 else if(k=="dr_face") dr_face_outline(p);
 else if(k=="dr_handle") handle_profile();
 else if(k=="dr_side_l" || k=="dr_side_r") dr_side_outline(p);
 else if(k=="dr_front" || k=="dr_back") dr_cross_outline(p);
 else if(k=="dr_bottom") dr_bottom_outline(p);
 else if(k=="stack_key") square([p[3],p[4]]);
 else if(k=="jig_block") handle_block();
 else if(k=="jig_plate") jig_plate();
 else if(k=="jig_fence") jig_fence();
 else if(k=="partition") partition_outline(p);
}
module part_pockets(p,mode) {
 k=p[1];
 if(mode=="pocket_carcass_dados") {
  if(k=="side_l" || k=="side_r") side_housings(p);
  if(k=="bottom") bottom_registration(p);
  if(k=="rail_f" || k=="rail_b") rail_key_pockets(p);
 }
 if(mode=="pocket_drawer_dados" && (k=="dr_side_l" || k=="dr_side_r" || k=="dr_front" || k=="dr_back")) dr_bottom_pockets(p);
 if(mode=="pocket_shelf_pins" && (k=="side_l" || k=="side_r")) side_pins(p);
 if(mode=="pocket_hinge_cups" && k=="door") door_cups(p);
 if(mode=="pocket_slide_holes") slide_holes(p);
 if(mode=="pocket_screw_marks") screw_mark_holes(p);
}
POCKET_MODES=["pocket_carcass_dados","pocket_drawer_dados","pocket_shelf_pins","pocket_hinge_cups","pocket_slide_holes","pocket_screw_marks"];
// Slide holes go through the drawer box sides and partitions and are blind pilots in the module sides.
function pocket_depth(mode,p)=mode=="pocket_carcass_dados" ? (p[1]=="side_l" || p[1]=="side_r" ? housing_depth : registration_pocket_depth) :
 mode=="pocket_drawer_dados" ? drawer_bottom_pocket_depth : mode=="pocket_shelf_pins" ? shelf_pin_depth :
 mode=="pocket_slide_holes" ? (p[1]=="dr_side_l" || p[1]=="dr_side_r" || p[1]=="partition" ? p[5] : slide_drill_depth) :
 mode=="pocket_screw_marks" ? screw_mark_depth : hinge_cup_depth;

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
 k=="face" ? [[-1,0,0,door_gap/2+p[3]],[0,0,1,0],[0,1,0,door_gap/2],[0,0,0,1]] :
 k=="partition" ? [[0,0,1,PX(m)-tc/2],[1,0,0,td],[0,1,0,0],[0,0,0,1]] :
 k=="dr_face" ? [[-1,0,0,dfront_x0(m,pcol(p))+p[3]],[0,0,1,0],[0,1,0,drawer_band(m,p[8])[0]+door_gap/2],[0,0,0,1]] :
 k=="dr_handle" ? [[1,0,0,dfront_x0(m,pcol(p))+dfront_w(m)/2-HL/2],[0,-1,0,0],[0,0,-1,drawer_band(m,p[8])[0]+door_gap/2+dhandle_v(m,p[8])+th/2],[0,0,0,1]] :
 k=="dr_side_l" ? [[0,0,1,dbox_x0(m,pcol(p))],[1,0,0,td],[0,1,0,dbox_z(m,p[8])],[0,0,0,1]] :
 k=="dr_side_r" ? [[0,0,-1,dbox_x0(m,pcol(p))+dbox_w(m)],[-1,0,0,td+dbox_d(m)],[0,1,0,dbox_z(m,p[8])],[0,0,0,1]] :
 k=="dr_front" ? [[-1,0,0,dbox_x0(m,pcol(p))+dbox_w(m)],[0,0,1,td],[0,1,0,dbox_z(m,p[8])],[0,0,0,1]] :
 k=="dr_back" ? [[1,0,0,dbox_x0(m,pcol(p))],[0,0,-1,td+dbox_d(m)],[0,1,0,dbox_z(m,p[8])],[0,0,0,1]] :
 k=="dr_bottom" ? [[1,0,0,dbox_x0(m,pcol(p))],[0,1,0,td],[0,0,1,dbox_z(m,p[8])+drawer_bottom_inset],[0,0,0,1]] :
 k=="stack_key" ? let(q=p[8],z=mtop(q[1])-HT) q[4]=="x" ? [[1,0,0,q[2]-p[3]/2],[0,0,-1,q[3]+t/2],[0,1,0,z],[0,0,0,1]] : [[0,0,1,q[2]-t/2],[1,0,0,q[3]-p[3]/2],[0,1,0,z],[0,0,0,1]] :
 k=="jig_plate" ? [[1,0,0,JX],[0,1,0,0],[0,0,1,0],[0,0,0,1]] :
 k=="jig_block" ? [[1,0,0,JX+JIG_L/2-HL/2],[0,1,0,JIG_FY+tj],[0,0,1,tj],[0,0,0,1]] :
 k=="jig_fence" ? [[1,0,0,JX],[0,0,-1,JIG_FY+tj],[0,1,0,0],[0,0,0,1]] :
 [[1,0,0,0],[0,1,0,0],[0,0,1,Ztop],[0,0,0,1]];
// The drilling jig stands assembled on the floor beside the bench.
JX=FL+worksurface_overhang+150;
function is_jig_part(k)=k=="jig_block" || k=="jig_plate" || k=="jig_fence";
function is_module_part(p)=p[1]!="frame_long" && p[1]!="frame_cross" && p[1]!="top" && p[1]!="stack_key" && !is_jig_part(p[1]);
module panel3(p) {
 difference() {
  linear_extrude(p[5]) part_outline(p);
  for(mode=POCKET_MODES) let(d=pocket_depth(mode,p))
   translate([0,0,p[5]-d-(d>=p[5] ? 0.1 : 0)]) linear_extrude(d+0.2) part_pockets(p,mode);
 }
}
module place3(p) {
 if(is_module_part(p)) multmatrix(mmatrix(p[2])) multmatrix(part_matrix(p)) panel3(p);
 else multmatrix(part_matrix(p)) panel3(p);
}
function part_colour(k)=k=="frame_long" || k=="frame_cross" || k=="stack_key" ? [0.72,0.58,0.40] : is_jig_part(k) ? [0.66,0.60,0.52] : k=="top" ? [0.85,0.70,0.48] : k=="door" || k=="dr_face" || k=="face" ? [0.83,0.69,0.50] : k=="handle" || k=="dr_handle" ? [0.55,0.42,0.28] : k=="shelf" || k=="dr_bottom" ? [0.86,0.75,0.58] : k=="dr_side_l" || k=="dr_side_r" || k=="dr_front" || k=="dr_back" ? [0.88,0.78,0.60] : [0.78,0.65,0.45];
function is_front_part(k)=k=="door" || k=="handle" || k=="dr_face" || k=="dr_handle" || k=="face";
// Side-mount slides as reference hardware: cabinet and drawer members, closed.
module slides() {
 for(k=[0:1:NM-1]) multmatrix(mmatrix(k)) for(j=[0:1:drawer_n(k)-1]) for(c=[0:1:dcols(k)-1]) for(x=[dbox_x0(k,c)-SC,dbox_x0(k,c)+dbox_w(k)])
  translate([x+SC*0.1,td+metal_slide_front_setback,dslide_z(k,j)-metal_slide_envelope_height/2]) cube([SC*0.8,slide_len(k),metal_slide_envelope_height]);
}
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
 for(p=parts) if((p[1]!="top" || show_worksurface) && (!is_front_part(p[1]) || show_doors)) color(part_colour(p[1])) place3(p);
 if(show_hardware) color([0.25,0.27,0.29]) casters();
 if(show_hardware && show_drawer_slides) color([0.62,0.65,0.69]) slides();
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
function bom_category(k)=k=="dr_side_l" || k=="dr_side_r" ? "drawer_side" : k=="dr_front" ? "drawer_front_box" : k=="dr_back" ? "drawer_back_box" :
 k=="dr_bottom" ? "drawer_bottom" : k=="dr_face" ? "drawer_face" : k=="dr_handle" ? "handle" : k=="face" ? "face_panel" : is_jig_part(k) ? "handle_jig" : k=="partition" ? "drawer_partition" : k;
function bom_note(p)=let(n=bom_note_base(p)) len(screw_marks(p))==0 ? n : n=="through cuts only" ? "machined face up: screw marks" : str(n,"; screw marks");
function bom_note_base(p)=let(k=p[1]) k=="bottom" ? "underside up: registration pockets" : k=="door" ? "inside face up: hinge cups" :
 k=="side_l" || k=="side_r" ? str("inside face up: housings",len(pin_heights(p[2]))>0 ? " and shelf pins" : "",drawer_n(p[2])>0 && include_metal_slide_holes ? " and slide pilot holes" : "") :
 k=="handle" || k=="dr_handle" ? "drill two 15 mm pilot holes into the leg ends" :
 (k=="rail_f" || k=="rail_b") && len([for(q=KEYS) if(q[1]==p[2] && q[5]==(k=="rail_b")) 1])>0 ? "top face up: stacking key pockets" :
 k=="dr_side_l" || k=="dr_side_r" ? str("inside face up: bottom pockets",include_metal_slide_holes ? "; slide holes through" : "") :
 k=="dr_front" || k=="dr_back" ? "inside face up: bottom pockets" : k=="stack_key" ? "stands in a top-rail pocket and the registration pocket above" :
 k=="jig_block" ? "cut from handle stock; dowel holes through" : k=="jig_plate" ? "fence mortise, dowel and mounting holes through" :
 k=="jig_fence" ? "drill the pull's leg pilots through its guide holes" :
 k=="partition" ? (include_metal_slide_holes ? "tenons through the bottom and top rails; slide binding-post holes through" : "tenons through the bottom and top rails") : "through cuts only";
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
 if(len([for(k=[0:1:NM-1]) if(drawer_n(k)>0) 1])>0) {
  check(drawer_bottom_tongue<drawer_bottom_pocket_depth && drawer_bottom_pocket_depth<tx-2,"DRAWER_BOTTOM_DEPTH","Drawer bottom pockets must be deeper than the tongues and leave 2 mm of the box stock");
  check(slide_drill_depth<tc,"SLIDE_DRILL_DEPTH","Slide pilot holes must stop inside the module sides");
  check(SC>0,"SLIDE_CLEARANCE","Side-mount slides need clearance beside the drawer boxes");
 }
 check(layout_gap>=router_bit_diameter+1,"LAYOUT_GAP","Layout gap must separate cutter paths");
 if(include_screw_marks) {
  check(screw_mark_depth<=min(tc,tx,td)-2,"SCREW_MARK_DEPTH","Screw marks must leave at least 2 mm of the stock they are marked in");
  check(frame_screw_offset>=KEY_L/2+screw_mark_diameter/2+2 && frame_screw_offset<=C/2-frame_rail_inset-tf/2-screw_mark_diameter/2,"FRAME_SCREWS","Frame screw marks must sit between a registration pocket and the crossing strip");
 }
 if(include_handle_jig) warn(has_handles,"HANDLE_JIG","No pull is selected, so the drilling jig is left out");
 // The pull's profile lies in the plane of its stock; the stock thickness is the pull's height across
 // the door, and the leg pilot holes sit half way through it.
 if(has_handles) check(th>=handle_pilot_diameter+6,"HANDLE_STOCK",str("Pull stock of ",th," mm leaves less than 3 mm around the ",handle_pilot_diameter," mm leg pilot holes"));
 check(NM>0 || !include_worksurface,"WORKSURFACE_SUPPORT","The worksurface needs at least one module to rest on");
 for(k=[0:1:NM-1]) {
  id=str("M",k+1);
  check(in_grid(k),"MODULE_GRID",str(id," does not fit the ",cols," × ",rows," grid"));
  check(len([for(c=cells_of(k)) if(abs(under_top(k,c)-mz(k))>0.01) 1])==0,"MODULE_SUPPORT",str(id," is not fully supported: the cells under it end at different heights"));
  check(mH(k)>=2*tc+RW && mH(k)<=2400,"MODULE_HEIGHT",str(id," height must be between ",2*tc+RW," and 2400 mm"));
  check(mDc(k)-tc>=2*RW+10,"MODULE_DEPTH",str(id," is too shallow for its top rails"));
  // The base frame's tabs locate modules on the frame; stacked modules are located by keys in the rails below.
  if(mz(k)>Zbase+0.01) {
   if(include_stack_keys) warn(keys_under(k)>=2,"STACK_KEYS",str(id," has ",keys_under(k)," stacking key",keys_under(k)==1 ? "" : "s"," on the module below; screw it down through its bottom"));
   else warn(false,"STACK_FASTENING",str(id," stands on another module without stacking keys; screw it down through its bottom"));
  }
  for(j=[0:1:NM-1]) if(blocks_front(k,j)) {
   if(opens(k)) check(false,"MODULE_FACING",str(id,"'s ",drawer_n(k)>0 ? "drawers" : "doors"," open into M",j+1,"; face it to an open side"));
   else warn(false,"MODULE_FACING",str(id,"'s open front is behind M",j+1));
  }
  if(mshelves(k)>0 && mcontents(k)!="drawers") warn(len(shelf_holes(k))==mshelves(k),"SHELF_POSITIONS",str(id," has room for ",len(shelf_holes(k))," of ",mshelves(k)," shelves on its pin holes"));
  for(i=[0:1:len(shelf_holes(k))-1]) check(shelf_z(k,i)+ts<=shelf_ceiling(k)-5,"SHELF_HEIGHT",str(id," shelf ",i+1," meets ",mcontents(k)=="drawer_door" ? "the drawers" : "the top rails"));
  if(drawer_n(k)>0) {
   check(slide_len(k)>0 && slide_len(k)<=slide_room(k),"SLIDE_LENGTH",str(id," has ",slide_room(k)," mm for its drawer slides",metal_slide_length>0 ? str("; ",metal_slide_length," mm slides do not fit") : "; the shortest standard slide is 250 mm"));
   for(j=[0:1:drawer_n(k)-1]) {
    check(dbox_h(k,j)>=max(metal_slide_envelope_height+4,drawer_bottom_inset+tbb+10),"DRAWER_HEIGHT",str(id," drawer ",j+1," box is ",dbox_h(k,j)," mm tall; it needs room for its slides and bottom (fewer drawers or a taller module)"));
    check(dbox_h(k,j)/len(dfields(dbox_h(k,j)))>=router_bit_diameter+2,"DRAWER_FINGERS",str(id," drawer ",j+1," corner fingers are narrower than the cutter"));
    if(has_handles) check(dfront_h(k,j)>=th+10 && dfront_w(k)>=HL+10,"HANDLE_POSITION",str(id," drawer ",j+1," front is too small for its pull"));
   }
   check(mcontents(k)!="drawer_door" || door_band(k)[1]>=tc+2*RW,"DRAWER_DOOR",str(id," has no room for a door below its ",drawer_n(k)," drawers"));
   warn(dbox_w(k)<=900,"DRAWER_WIDE",str(id," drawers are ",dbox_w(k)," mm wide; check the slide rating"));
   check(dbox_w(k)>=2*tx+50,"DRAWER_NARROW",str(id," drawer boxes are only ",dbox_w(k)," mm wide"));
  }
  if(mdcols(k)==2 && !has_partition(k)) warn(false,"DRAWER_COLUMNS",str(id,mcontents(k)!="drawers" ? " is not an all-drawer module" : " is one cell wide",", so its drawers stay one wide"));
  if(has_partition(k)) {
   check(RW-30>=20 && len(partition_tenons_bottom(k))>0,"PARTITION_TENONS",str(id," partition has no room for its tenons in the top rails or the bottom"));
   for(b=[false,true]) for(h=slot_rects(k,b)) for(r=rail_mortises(k)) check(!rects_meet(h,r,3),"PARTITION_RAIL",str(id," hand slots meet the partition mortises; use shorter hand slots"));
   if(include_metal_slide_holes) check(partition_slide_hole_diameter<metal_slide_envelope_height-10,"PARTITION_HOLES",str(id," partition holes are too large for the slides"));
  }
  if(mcontents(k)=="framed") check(face_opening_border>=tc+door_gap/2+2 && mW(k)-door_gap-2*face_opening_border>=40 && mH(k)-door_gap-2*face_opening_border>=40,"FACE_OPENING",str(id," face panel border must cover the carcass edges and leave an opening"));
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
 echo(str("CHECK|INFO|HARDWARE_REFERENCE|Verify casters, hinges",len([for(k=[0:1:NM-1]) if(drawer_n(k)>0) 1])>0 ? ", drawer slides and their hole arrays" : ""," and screws against the purchased hardware before drilling"));
 echo("CHECK|INFO|VALIDATION_SCOPE|Geometric/manufacturing checks only; no structural certification or CAM verification");
}
module reports() {
 echo(str("EXPORT_FRAME|X0=-20|Y0=-20|X1=",LW+20,"|Y1=",LH+20,"|FW=1"));
 if(validation_report!="off") validate();
 if(dimension_report!="off") {
  ow=FL+(include_worksurface ? 2*OV : 0); od=FD+(include_worksurface ? 2*OV : 0); oh=Ztop+(include_worksurface ? tw : 0);
  echo(str("DIM|CABINET|OUTSIDE|W=",ow,"|H=",oh,"|D=",od));
  echo(str("DIM|FRAME|W=",FL,"|D=",FD,"|H=",hf,"|CELLS=",cols,"x",rows,"|CELL=",C,"|TAB_H=",HT,"|CASTER_H=",Zf));
  for(k=[0:1:NM-1]) echo(str("DIM|MODULE|M",k+1,"|COL=",mcol(k)+1,"|ROW=",mrow(k)+1,"|W=",mW(k),"|D=",mD(k),"|H=",mH(k),"|Z=",mz(k),"|CONTENTS=",mcontents(k),"|FACING=",mfacing(k),"|SHELVES=",len(shelf_holes(k)),"|DRAWERS=",drawer_n(k),mz(k)>Zbase+0.01 ? str("|STACK_KEYS=",keys_under(k)) : ""));
  for(k=[0:1:NM-1]) for(j=[0:1:drawer_n(k)-1]) for(c=[0:1:dcols(k)-1]) let(id=str("M",k+1,"-DRAWER-",j+1,dsuffix(k,c)),bh=dbox_h(k,j)) {
   echo(str("DIM|DRAWER|",id,"|OUTSIDE|W=",dbox_w(k),"|H=",bh,"|D=",dbox_d(k)));
   echo(str("DIM|DRAWER|",id,"|INSIDE_CLEAR|W=",dbox_w(k)-2*tx,"|H=",bh-drawer_bottom_inset-tbb,"|D=",dbox_d(k)-2*tx));
   echo(str("DIM|DRAWER|",id,"|OPENING|W=",dcell_w(k),"|H=",bh+VC,"|SIDE_CLEAR_PER_SIDE=",SC,"|VERT_CLEAR_PER_SIDE=",VC/2));
   echo(str("DIM|DRAWER_FACE|",id,"-FACE|W=",dfront_w(k),"|H=",dfront_h(k,j)));
   echo(str("DIM|SLIDE|",id,"|LENGTH=",slide_len(k),"|CENTRE_Z=",dslide_z(k,j),"|SETBACK=",metal_slide_front_setback));
  }
  for(k=[0:1:NM-1]) if(has_partition(k)) echo(str("DIM|PARTITION|M",k+1,"-PARTITION|D=",mDc(k)-tc,"|H=",mH(k),"|T=",tc,"|X=",PX(k),"|TENONS_BOTTOM=",len(partition_tenons_bottom(k)),"|TENONS_TOP=2|HOLE_D=",partition_slide_hole_diameter));
  for(k=[0:1:NM-1]) if(mcontents(k)=="framed") echo(str("DIM|FACE_PANEL|M",k+1,"-FACE|W=",mW(k)-door_gap,"|H=",mH(k)-door_gap,"|OPENING_W=",mW(k)-door_gap-2*face_opening_border,"|OPENING_H=",mH(k)-door_gap-2*face_opening_border,"|R=",face_opening_radius));
  if(len(KEYS)>0) echo(str("DIM|STACK_KEYS|QTY=",len(KEYS),"|W=",registration_tab_length,"|H=",2*HT,"|T=",tf,"|POCKET_DEPTH=",registration_pocket_depth));
  for(k=[0:1:NM-1]) for(j=[0:1:door_count(k)-1]) echo(str("DIM|DOOR|M",k+1,"-DOOR-",j+1,"|W=",door_w(k),"|H=",door_h(k),"|MOUNT=full_overlay|HINGE=",door_hinge_left(k,j) ? "left" : "right"));
  for(k=[0:1:NM-1]) for(i=[0:1:len(shelf_holes(k))-1]) echo(str("DIM|SHELF|M",k+1,"-SHELF-",i+1,"|STYLE=adjustable|CLEAR_SPAN_W=",mWi(k),"|CUT_W=",mWi(k)-2*shelf_side_clearance,"|D=",mD(k)-tc-shelf_rear_clearance-td-shelf_front_setback,"|Z=",shelf_z(k,i)));
  if(include_worksurface) echo(str("DIM|WORKSURFACE|W=",FL+2*OV,"|D=",FD+2*OV,"|Z=",Ztop,"|T=",tw,"|PANELS=",NP,"|DOG_HOLES=",len([for(i=[0:NP-1]) if(panel_dogs(i)) each dog_positions(i)])));
  if(has_handles) echo(str("DIM|HANDLE|STYLE=",handle_style,"|L=",HL,"|H=",HH,"|T=",th,"|HOLE_CENTRES=",HSP,"|PILOT_D=",handle_pilot_diameter,"|PILOT_DEPTH=15|QTY=",len([for(p=parts) if(p[1]=="handle" || p[1]=="dr_handle") 1])));
  if(include_handle_jig && has_handles) echo(str("DIM|HANDLE_JIG|BLOCK=",HL-2*HBX,"x",HBH,"x",th,"|PLATE=",JIG_L,"x",JIG_D,"x",tj,"|FENCE=",JIG_L,"x",tj+JIG_FH,"x",tj,"|GUIDE_HOLE_HEIGHT=",th/2,"|DOWEL_D=",jig_dowel_diameter));
  if(include_screw_marks) echo(str("DIM|SCREW_MARKS|QTY=",len([for(p=parts) each screw_marks(p)]),"|D=",screw_mark_diameter,"|DEPTH=",screw_mark_depth));
  echo(str("DIM|machining|HOUSING_DEPTH=",housing_depth,"|REGISTRATION_POCKET_DEPTH=",registration_pocket_depth,"|HINGE_CUP_DEPTH=",hinge_cup_depth,"|SHELF_PIN_DEPTH=",shelf_pin_depth,"|HALF_LAP=",hf/2,"|DRAWER_BOTTOM_POCKET_DEPTH=",drawer_bottom_pocket_depth,"|SLIDE_PILOT_DEPTH=",slide_drill_depth,"|SCREW_MARK_DEPTH=",include_screw_marks ? screw_mark_depth : 0));
 }
 if(system_contract_report!="off") {
  echo("SYSTEM|CONTRACT=MOI-4|ENGINE=modular_organization_v5");
  echo(str("MODULE|ID=workbench|KIND=workbench|W=",FL,"|D=",FD,"|H=",Ztop+(include_worksurface ? tw : 0)));
  echo("COVERAGE|SCOPE=workbench|CHECKS=grid_fit;module_support;stack_keys;facing;shelf_pins;hinge_room;handle_room;handle_stock;drawer_fit;drawer_partition;slide_length;screw_marks;hand_slots;dog_holes;puzzle_neck;stock;cut_and_pocket_contours|STRUCTURAL=false");
 }
 check(layout_gap>0,"LAYOUT_OVERLAP",str("layout_gap is ",layout_gap," mm; parts of the flat cut layout would overlap."));
 if(output_mode=="bom") {
  for(p=parts) echo(str("BOM|",p[0],"|1|",bom_category(p[1]),"|plywood|",p[5],"|",p[3],"|",p[4],"|",bom_note(p)));
  for(k=[0:NPART-1]) echo(str("PLACE|",parts[k][0],"|X=",PL[k][0],"|Y=",PL[k][1],"|W=",parts[k][3],"|H=",parts[k][4]));
  doors=len([for(p=parts) if(p[1]=="door") 1]);
  echo(str("HARDWARE|ID=casters|QTY=",Zf>0 ? 4 : 0,"|UNIT=plate casters|LENGTH=",Zf,"|NOTE=mounting plates under the outer strip crossings"));
  echo(str("HARDWARE|ID=cup_hinges|QTY=",sum([for(k=[0:1:NM-1]) door_count(k)>0 ? door_count(k)*hinge_count(door_h(k)) : 0]),"|UNIT=full overlay|NOTE=",hinge_cup_diameter," mm cups"));
  echo(str("HARDWARE|ID=shelf_pins|QTY=",4*len([for(p=parts) if(p[1]=="shelf") 1]),"|UNIT=",shelf_pin_diameter," mm pins"));
  echo(str("HARDWARE|ID=wood_screws_35mm|QTY=",sum([for(k=[0:1:NM-1]) 21+4*(mspx(k)*mspy(k)-1)+(has_partition(k) ? 3 : 0)]),"|UNIT=minimum estimate|NOTE=carcass joints; choose length for the stock"));
  // Each drawer (one per column) runs on a pair of slides; beside a partition the cabinet members of
  // the two neighbouring slides share binding posts through the partition instead of screws.
  ndr=sum([for(k=[0:1:NM-1]) drawer_n(k)*dcols(k)]);
  for(L=metal_slide_length>0 ? [metal_slide_length] : SLIDES) let(q=sum([for(k=[0:1:NM-1]) if(slide_len(k)==L) drawer_n(k)*dcols(k)])) if(q>0)
   echo(str("HARDWARE|ID=drawer_slides_",L,"|QTY=",q,"|UNIT=pairs of side-mount full-extension slides|LENGTH=",L,"|NOTE=",SC," mm clearance per side"));
  posts=include_metal_slide_holes ? sum([for(k=[0:1:NM-1]) if(has_partition(k)) drawer_n(k)*len(dslide_holes(k,metal_slide_cabinet_holes_x))]) : 0;
  if(posts>0) echo(str("HARDWARE|ID=slide_binding_posts|QTY=",posts,"|UNIT=binding posts (sex bolts)|NOTE=fix the slides on both faces of a drawer partition through one ",partition_slide_hole_diameter," mm hole"));
  cabinet_members=sum([for(k=[0:1:NM-1]) drawer_n(k)*2]);
  echo(str("HARDWARE|ID=wood_screws_15mm|QTY=",doors*(4+(has_handles ? 2 : 0))+ndr*(4+(has_handles ? 2 : 0)+2*len(metal_slide_drawer_holes_x))+cabinet_members*len(metal_slide_cabinet_holes_x)+4*len([for(p=parts) if(p[1]=="face") 1]),"|UNIT=minimum estimate|NOTE=hinges, handles, slides, drawer faces and face panels"));
  if(len(KEYS)>0) echo(str("HARDWARE|ID=stack_screws|QTY=",2*len([for(k=[0:1:NM-1]) if(mz(k)>Zbase+0.01) 1]),"|UNIT=minimum estimate|NOTE=optional screws down through each stacked module's bottom"));
 }
}
reports();
if(output_mode=="assembly") assembly();
else if(output_mode=="flat_3d") for(k=[0:NPART-1]) translate([PL[k][0]-parts[k][6],PL[k][1]-parts[k][7],0]) panel3(parts[k]);
else if(output_mode=="cut_layout" || output_mode=="engrave_layout" || len([for(m=POCKET_MODES) if(m==output_mode) 1])>0) layout(output_mode);
