// Modular Organization: equipment_stand — source entrypoint; units mm.
// Modular Organization v5 — Equipment Stands. Units: mm.
// X left/right, Y front/back, Z up. CUT coordinates use inside faces up.
// Shared part definitions drive assembly, CUT, POCKET, labels and BOM.
include <cleat.scad>
include <joinery.scad>

/* [Materials / Measured Thickness] */

material_thickness = 18.00; // [0.01:0.01:100]

tray_thickness = 18.00; // [0.01:0.01:100]

custom_back_thickness = 6.00; // [0.01:0.01:100]

cleat_thickness = 18.00; // [0.01:0.01:100]

/* [Machining / Tool and Kerf] */

router_bit_diameter = 6.35;

/* [Machining / Shared Slot Relief] */

slot_corner_relief = "dogbone"; // [none,dogbone,t_bone]

/* [Machining / Side Panels] */

side_relief = "dogbone"; // [none,dogbone,tbone]

/* [Machining / Frame Joints] */

// Relief for this material only. Inherit preserves the shared setting.
carcass_slot_corner_relief = "inherit"; // [inherit,none,dogbone,t_bone]
// Cutter diameter in mm. Zero inherits the shared cutter diameter.
carcass_cnc_tool_diameter = 0; // [0:0.01:50]


dado_depth = 6;

fit_clearance = 0.2;

joint_fit_clearance = 0.20; // [0:0.01:2]

/* [Sizing / Envelope] */

sizing_mode = "equipment"; // [equipment,manual]

device_width = 430;

device_depth = 470;

device_height = 510;

side_clearance = 20;

rear_clearance = 40;

top_clearance = 80;

service_clearance = 500;

overall_width = 600;

overall_depth = 620;

overall_height = 750;

/* [Structure / Layout] */

side_style = "skeletonized"; // [solid,skeletonized]

side_frame_margin = 65;

minimum_rib_width = 55;

cutout_corner_radius = 12;

// Windows per bay; diagonal braces are protected material between openings.
side_window_count = 1; // [1:3]

brace_style = "diagonal"; // [diagonal,cross,none]

mirror_sides = true;

base_gap = 25;

upper_bay_enabled = false;

upper_bay_height = 220;

/* [Structure / Top] */

top_style = "panel"; // [panel,frame]

/* [Structure / Back and Braces] */

// auto preserves v5 bay stretchers/french-cleat backers.
// panel is an applied back; structural_panel is captured and follows frame joinery.
back_style = "auto"; // [auto,panel,structural_panel,stretchers,none]

back_stretcher_count = 2; // [1:1:8]

back_stretcher_height = 100;

back_stretcher_edge_margin = 30;

back_stretcher_inset = 0;

back_rail_height = 90;

/* [Structure / Frame Joinery] */

joinery_style = "screw"; // [butt,screw,dado,tab_slot]

// Main-engine tab placement and corner-relief settings.
tab_count_mode = "adaptive"; // [adaptive,fixed]

joint_tab_count = 3; // [1:1:8]

target_tab_spacing = 180;

max_auto_tab_count = 6; // [1:1:10]

joint_tab_width = 35;

joint_tab_edge_margin = 15;

minimum_joint_web = 30;

/* [Trays / Layout] */

tray_count = 1; // [1:4]

tray_inset = 10;

tray_cheek_height = 70;

tray_lip_height = 20;

tray_handle = "finger_pull"; // [finger_pull,none]

rear_cable_opening = true;

cable_opening_width = 60;

cable_opening_depth = 20;

// Requested maximum motion; validation rejects travel beyond the slide rating.
tray_extension = 450;

/* [Mounting / French Cleats] */

mount_mode = "freestanding"; // [freestanding,wall_mount_french_cleat]

cleat_angle = 45;

cleat_height = 90;

cleat_wall_width = 0;

cleat_stand_width = 0;

cleat_top_setback = 25;

cleat_rail_count = 2; // [1:4]

cleat_vertical_gap = 0.5;

lower_stabilizer_enabled = true;

anti_tip_enabled = true;

/* [Hardware / Slides] */

slide_type = "side_mount"; // [side_mount,fixed_runner]

metal_slide_clearance_per_side = 12.7;

metal_slide_length = 450;

metal_slide_front_setback = 3;

metal_slide_envelope_height = 45;

slide_supported_travel = 450;

// Informational user-supplied rating, never a certified assembly rating.
slide_load_rating_kg = 45;

equipment_mass_kg = 20;

/* [Hardware / Slide Drilling] */

include_metal_slide_holes = true;

metal_slide_cabinet_holes_x = [37,133,229,325];

metal_slide_drawer_holes_x = [37,133,229,325];

metal_slide_cabinet_hole_diameter = 5;

metal_slide_drawer_hole_diameter = 5;

slide_drill_depth = 8;

/* [Hardware / Wood Runners] */

runner_width = 20;

runner_height = 20;

// Fixed runner retention screws pass down through the tray; field-drill the runners.
runner_stop_diameter = 5;

/* [Hardware / Cleat Fasteners] */

cleat_fastener_spacing = 150;

stud_spacing = 406.4;

cleat_fastener_diameter = 6;

cleat_edge_margin = 22;

cleat_safety_factor = 2;

/* [Output / View] */

output_mode = "assembly"; // [assembly,flat_3d,cut_layout,engrave_layout,bom,pocket_carcass_dados,pocket_slide_holes]

// Preview only: extension of every tray, clamped to configured supported travel.
preview_extension = 0;

/* [Output / Visibility] */

show_hardware = true;

show_equipment = false;

show_wall_rails = true;

/* [Output / Flat Layout] */

layout_gap = 25;

/* [Output / Labels] */

label_parts = true;

/* [System / Reports] */

validation_report = "summary"; // [off,summary,verbose]

system_contract_report = "summary"; // [off,summary,verbose]

dimension_report = "summary";

/* [Hidden] */

// Internal section: Hidden

$fn=32;
t=material_thickness;
tt=tray_thickness;
N=tray_count;
wall=mount_mode=="wall_mount_french_cleat";
sg=slide_type=="fixed_runner" ? 2 : metal_slide_clearance_per_side;
W=sizing_mode=="equipment" ? device_width+2*side_clearance+4*t+2*sg : overall_width;
D=sizing_mode=="equipment" ? tray_inset+max(device_depth+(tray_lip_height>0 ? t : 0)+(rear_cable_opening ? cable_opening_depth : 0),metal_slide_length+metal_slide_front_setback)+rear_clearance+t : overall_depth;
pitch=tt+device_height+top_clearance+t;
H=sizing_mode=="equipment" ? t+base_gap+N*pitch+(upper_bay_enabled ? upper_bay_height+t : 0) : overall_height;
IW=W-2*t;
TW=IW-2*sg;
TD=D-tray_inset-rear_clearance-t;
seat=joinery_style=="dado" ? dado_depth : joinery_style=="tab_slot" ? t : 0;
cnc_tool_diameter=router_bit_diameter;
structural=back_style=="structural_panel";
applied=back_style=="panel";
external_backers=wall && back_style!="auto" && back_style!="none";
backerW=external_backers ? W : IW;
mountY=D+(applied ? custom_back_thickness : 0)+(external_backers ? t : 0);
backN=back_style=="stretchers" ? back_stretcher_count : back_style=="auto" && !wall ? N : 0;
function back_z(i)=back_style=="auto" ? tz(i)+pitch-t-back_rail_height :
 back_stretcher_count<=1 ? (H-back_stretcher_height)/2 :
 t+back_stretcher_edge_margin+i*(H-2*t-2*back_stretcher_edge_margin-back_stretcher_height)/(back_stretcher_count-1);
function back_h()=back_style=="auto" ? back_rail_height : back_stretcher_height;
function back_y()=D-(back_style=="auto" ? 0 : back_stretcher_inset);
function horizontal_y(p)=p[5]==2 ? D-back_rail_height : 0;
function horizontal_z(p)=p[5]==0 ? 0 : p[5]==3 ? shelf_z() : H-t;
function horizontal_span(p)=p[3]-(structural && p[5]!=3 && p[5]!=1 ? t : structural && top_style=="panel" && p[5]==1 ? t : structural && p[5]==2 ? t : 0);
function side_joint(p)=p[1]=="horizontal" || p[1]=="back" || p[1]=="structural";
function joint_span(p)=p[1]=="structural" ? H-2*t : p[1]=="horizontal" ? horizontal_span(p) : p[3];
CW=cleat_stand_width==0 ? IW : cleat_stand_width;
WW=cleat_wall_width==0 ? W : cleat_wall_width;
crise=cleat_thickness*tan(cleat_angle);
ch=2*cleat_height-crise+cleat_vertical_gap;
ext=slide_type=="fixed_runner" ? 0 : min(max(0,preview_extension),tray_extension);
function tz(i)=t+base_gap+i*pitch;
function slide_z(i)=tz(i)+tt+tray_cheek_height/2;
function shelf_z()=H-upper_bay_height-t;
function cleat_z(i)=H-cleat_top_setback-ch-i*(N>1 ? pitch : max(ch+20,(H-cleat_top_setback-ch-t-(lower_stabilizer_enabled ? back_rail_height+20 : 0))/max(1,cleat_rail_count-1)));
function cleat_holes(w,step)=[for(x=[cleat_edge_margin:step:w-cleat_edge_margin]) x];
// Each part: [id,kind,width,height,thickness,index].
parts=concat(
 [["SIDE_L","side",D,H,t,0],["SIDE_R","side",D,H,t,1],
  ["BASE","horizontal",IW+2*seat,D,t,0]],
 top_style=="panel" ? [["TOP","horizontal",IW+2*seat,D,t,1]] :
 [["TOP_FRONT","horizontal",IW+2*seat,back_rail_height,t,1],["TOP_REAR","horizontal",IW+2*seat,back_rail_height,t,2]],
 upper_bay_enabled ? [["UPPER_SHELF","horizontal",IW+2*seat,D-(structural ? t : 0),t,3]] : [],
 [for(i=[0:N-1]) each [
  [str("TRAY_",i+1),"tray",TW,TD,tt,i],
  [str("CHEEK_L_",i+1),"cheek",TD,tray_cheek_height,t,i],
  [str("CHEEK_R_",i+1),"cheek",TD,tray_cheek_height,t,i]]],
 backN>0 ? [for(i=[0:backN-1]) [str("BACK_",i+1),"back",IW+2*seat,back_h(),t,i]] : [],
 structural ? [["STRUCTURAL_BACK","structural",IW+2*seat,H-2*t+2*seat,t,0]] : [],
 applied ? [["PANEL_BACK","applied",W,H,custom_back_thickness,0]] : [],
 tray_lip_height>0 ? [for(i=[0:N-1]) [str("LIP_",i+1),"lip",TW-2*t,tray_lip_height,t,i]] : [],
 slide_type=="fixed_runner" ? [for(i=[0:N-1]) for(s=[0:1]) [str("RUNNER_",i+1,"_",s),"runner",TD,runner_height,runner_width,i]] : [],
 wall ? [for(i=[0:cleat_rail_count-1]) each [
  [str("CLEAT_STAND_",i+1),"cleat_stand",CW,cleat_height,cleat_thickness,i],
  [str("CLEAT_WALL_",i+1),"cleat_wall",WW,cleat_height,cleat_thickness,i],
  [str("CLEAT_BACKER_",i+1),"backer",backerW,ch,t,i]]] : [],
 wall && lower_stabilizer_enabled ? [["STABILIZER","spacer",W,back_rail_height,cleat_thickness,0]] : [],
 wall && lower_stabilizer_enabled && external_backers ? [["STABILIZER_SHIM","shim",W,back_rail_height,t,0]] : []);
function px(k)=k==0 ? 0 : px(k-1)+parts[k-1][2]+layout_gap;
LW=px(len(parts)-1)+parts[len(parts)-1][2];
LH=max([for(p=parts) p[3]]);

module check(ok,code,msg) { if(!ok) echo(str("CHECK|ERROR|",code,"|",msg)); }
module validate() {
 check(back_style=="auto" || back_style=="panel" || back_style=="structural_panel" || back_style=="stretchers" || back_style=="none","BACK_STYLE","Unsupported rear construction");
 check(!applied || custom_back_thickness>0,"BACK_STOCK","Applied back stock must be positive");
 check(back_style!="stretchers" || (back_stretcher_count>=1 && back_stretcher_count<=8 && floor(back_stretcher_count)==back_stretcher_count && back_stretcher_height>0 && back_stretcher_edge_margin>=0 && back_stretcher_inset>=0),"BACK_SETTINGS","Invalid stretcher count/height/margin/inset");
 check(back_style!="stretchers" || H-2*t-2*back_stretcher_edge_margin>=back_stretcher_count*back_stretcher_height+(back_stretcher_count-1)*minimum_joint_web,"BACK_OVERLAP","Stretchers do not fit with required spacing");
 check(back_style!="stretchers" || back_y()-t>=tray_inset+TD,"BACK_TRAY_COLLISION","Inset rear stretcher intersects closed tray");
 if(upper_bay_enabled && backN>0) for(i=[0:backN-1]) check(back_z(i)+back_h()<=shelf_z() || back_z(i)>=shelf_z()+t,"BACK_SHELF_COLLISION","Rear stretcher intersects upper shelf");
 if(joinery_style=="tab_slot") {
  check(tab_count_mode=="adaptive" || tab_count_mode=="fixed","TAB_COUNT_MODE","Invalid count mode");
  check(joint_fit_clearance>=0 && joint_fit_clearance<t/2 && joint_tab_width>=6 && joint_tab_edge_margin>=0 && minimum_joint_web>=router_bit_diameter && target_tab_spacing>0,"TAB_SETTINGS","Invalid tab fit, width, spacing or web");
  check(joint_tab_count>=1 && floor(joint_tab_count)==joint_tab_count && max_auto_tab_count>=1,"TAB_COUNT","Tab counts must be positive integers");
  check(slot_corner_relief=="none" || slot_corner_relief=="dogbone" || slot_corner_relief=="t_bone","SLOT_RELIEF","Invalid slot corner relief");
  for(p=parts) if(side_joint(p)) let(span=joint_span(p),n=effective_tab_count(span),w=tab_width_for(span)) {
   check(tab_start(span,0)>=joint_fit_clearance/2 && tab_start(span,n-1)+w<=span-joint_fit_clearance/2,"TAB_EDGE","Tab pattern runs outside member edge");
   check(n<=1 || (span-2*tab_margin(span))/n-w-joint_fit_clearance>=minimum_joint_web,"TAB_WEB","Fixed tab count violates minimum solid web");
  }
 }

 check(mount_mode=="freestanding" || mount_mode=="wall_mount_french_cleat","MOUNT_MODE","Unsupported mounting mode");
 check(slide_type=="side_mount" || slide_type=="fixed_runner","SLIDE_TYPE","Unsupported slide type");
 check(sizing_mode=="equipment" || sizing_mode=="manual","SIZING_MODE","Unsupported sizing mode");
 check(side_style=="solid" || side_style=="skeletonized","SIDE_STYLE","Unsupported side style");
 check(top_style=="panel" || top_style=="frame","TOP_STYLE","Unsupported top style");
 check(joinery_style=="butt" || joinery_style=="screw" || joinery_style=="dado" || joinery_style=="tab_slot","JOINERY_TYPE","Unsupported joinery");
 check(side_relief=="none" || side_relief=="dogbone" || side_relief=="tbone","RELIEF_TYPE","Unsupported relief");
 check(brace_style=="diagonal" || brace_style=="cross" || brace_style=="none","BRACE_STYLE","Unsupported brace style");
 check(layout_gap>=router_bit_diameter+5,"LAYOUT_GAP","Layout gap must separate cutter reliefs");
 check(min(back_rail_height,runner_width,runner_height)>0 && back_rail_height<D/2,"FRAME_RAIL","Invalid frame/runner dimensions");
 check(!upper_bay_enabled || upper_bay_height>0,"UPPER_BAY","Upper bay height must be positive");
 check(base_gap>=runner_height || slide_type!="fixed_runner","RUNNER_BASE","Runner intersects base");
 check(runner_width>sg+12 || slide_type!="fixed_runner","RUNNER_SUPPORT","Insufficient runner bearing beneath tray");
 check(t>0 && tt>0 && min(W,D,H)>0,"POSITIVE_STOCK","Stock and resolved dimensions must be positive");
 check(N>=1 && N<=4 && floor(N)==N,"TRAY_COUNT","Tray count must be an integer 1..4");
 check(side_window_count>=1 && side_window_count<=3 && floor(side_window_count)==side_window_count,"WINDOW_COUNT","Windows must be an integer 1..3");
 check(side_clearance>=0 && rear_clearance>=0 && top_clearance>=0 && tray_inset>=0 && base_gap>=0,"CLEARANCES","Clearances/inset/base gap must be nonnegative");
 check(min(device_width,device_depth,device_height)>0,"DEVICE_SIZE","Equipment dimensions must be positive");
 check(TW-2*t+0.001>=device_width+2*side_clearance && TD-(tray_lip_height>0 ? t : 0)-(rear_cable_opening ? cable_opening_depth : 0)+0.001>=device_depth,"DEVICE_FIT","Equipment must fit between tray cheeks and inside tray depth");
 check(tz(N-1)+tt+device_height+top_clearance-0.001 <= (upper_bay_enabled ? shelf_z() : H-t),"BAY_HEIGHT","Equipment/top clearance intersects top or upper shelf");
 check(tray_cheek_height>=metal_slide_envelope_height+10 && tray_cheek_height<=device_height+top_clearance,"SLIDE_BAND","Cheek must contain slide with edge margin and fit bay");
 check(slide_type=="fixed_runner" || (metal_slide_length>0 && metal_slide_length+metal_slide_front_setback<=TD && sg>0),"SLIDE_LENGTH","Slide must fit tray depth including front setback");
 check(tray_extension>=0 && tray_extension<=slide_supported_travel && tray_extension<=metal_slide_length,"SLIDE_TRAVEL","Requested travel exceeds slide supported travel/length");
 check(slide_type!="fixed_runner" || tray_extension==0,"RUNNER_TRAVEL","Fixed runners support a removable service tray only; set travel to zero");
 check(service_clearance>=tray_extension,"SERVICE_CLEARANCE","Front service clearance must cover full tray travel");
 check(slide_drill_depth>0 && slide_drill_depth<t,"DRILL_DEPTH","Slide pilot drilling must be blind and less than stock thickness");
 check((tray_lip_height==0 || tray_lip_height>=10) && tray_lip_height<=tray_cheek_height,"LIP_HEIGHT","Lip must fit inside cheeks");
 check(joinery_style!="dado" || (dado_depth>0 && dado_depth<t/2 && fit_clearance>=0),"DADO_DEPTH","Dado must leave more than half the side stock");
 check((D-2*side_frame_margin-(side_window_count-1)*minimum_rib_width)/side_window_count>2*cutout_corner_radius,"WINDOW_WIDTH","Too many windows for side depth");
 check(side_frame_margin>=minimum_rib_width && minimum_rib_width>=2*router_bit_diameter && router_bit_diameter>0,"RIB_WIDTH","Perimeter/ribs must accommodate the cutter");
 check(D>2*side_frame_margin && pitch>2*side_frame_margin+tray_cheek_height,"CUTOUT_ROOM","Bay must have room for protected perimeter and slide bands");
 check(cutout_corner_radius>=router_bit_diameter/2 && cutout_corner_radius<minimum_rib_width/2,"CUTOUT_RADIUS","Cutout radius must fit cutter and rib geometry");
 check(!rear_cable_opening || (cable_opening_width>0 && cable_opening_width<TW-2*t-20 && cable_opening_depth>0 && cable_opening_depth<=TD-device_depth+0.001-(tray_lip_height>0 ? t : 0)),"CABLE_OPENING","Cable relief must preserve tray and cheek material");
 if(rear_clearance<30 && !rear_cable_opening) echo("CHECK|WARN|CABLE_CLEARANCE|Small rear clearance without cable relief");
 for(a=concat(metal_slide_cabinet_holes_x,metal_slide_drawer_holes_x))
  check(!include_metal_slide_holes || slide_type=="fixed_runner" || (a>=10 && a<=metal_slide_length-10),"SLIDE_HOLE_EDGE","Slide hole must be at least 10mm from slide ends");
 check(min(metal_slide_cabinet_hole_diameter,metal_slide_drawer_hole_diameter)>0 && max(metal_slide_cabinet_hole_diameter,metal_slide_drawer_hole_diameter)<tray_cheek_height-20,"SLIDE_HOLE_SIZE","Slide hole diameter leaves inadequate band material");
 if(wall) {
  check(cleat_rail_count>=1 && cleat_rail_count<=4 && floor(cleat_rail_count)==cleat_rail_count,"CLEAT_COUNT","Rail count must be an integer 1..4");
  check(cleat_angle>=25 && cleat_angle<=60 && cleat_thickness>0 && cleat_height-crise>2*cleat_edge_margin,"CLEAT_PROFILE","Bevel must retain a full-thickness fastener land");
  check(CW<=IW && WW<=W && CW>=2*cleat_edge_margin+cleat_fastener_spacing && WW>=2*cleat_edge_margin+stud_spacing,"CLEAT_WIDTH","Cleats need at least two spaced fasteners and stand width must fit backer");
  check(cleat_fastener_spacing>0 && stud_spacing>0 && cleat_fastener_diameter>0 && cleat_edge_margin>=2*cleat_fastener_diameter,"CLEAT_FASTENER","Invalid spacing or fastener edge margin");
  check(cleat_vertical_gap>=0 && cleat_top_setback>=t && cleat_safety_factor>=1,"CLEAT_CLEARANCE","Invalid cleat gap/setback/safety metadata");
  for(i=[0:cleat_rail_count-1]) {
   check(cleat_z(i)>=t+(lower_stabilizer_enabled ? back_rail_height+20 : 0) && cleat_z(i)+ch<=H-t,"CLEAT_HEIGHT","Cleat/backer extends outside frame");
   if(i>0) check(cleat_z(i-1)-cleat_z(i)>=ch+10,"CLEAT_OVERLAP","Cleat rails/backers overlap");
  }
  echo("CHECK|WARN|WALL_LOAD_REVIEW|Verify wall anchors, studs, cleat engagement and extended-load overturning moment; geometry is not load certification");
 }
 if(slide_type=="side_mount" && slide_load_rating_kg<equipment_mass_kg*cleat_safety_factor)
  echo("CHECK|WARN|SLIDE_LOAD_METADATA|Entered slide rating is below equipment mass times safety factor; tray mass is additional");
 if(!wall) echo("CHECK|WARN|TIP_REVIEW|Extended trays and stacked equipment require independent stability assessment and anti-tip anchoring");
 if(slide_type=="side_mount") echo(include_metal_slide_holes ? "CHECK|WARN|HARDWARE_REFERENCE|Generic hole arrays require verification against the purchased slides before drilling" : "CHECK|WARN|HARDWARE_REFERENCE|Slide drilling disabled; verify purchased slide and field-drill its mounting pattern");
 echo("CHECK|INFO|VALIDATION_SCOPE|Geometric/manufacturing checks only; no structural certification or CAM verification");
}

module bar(a,b,width) { hull() { translate(a) circle(d=width); translate(b) circle(d=width); } }
module side_voids() {
 for(i=[0:N-1]) let(z0=tz(i)+tt+tray_cheek_height+minimum_rib_width/2,
 z1=min(tz(i)+pitch-side_frame_margin,H-side_frame_margin),
 ww=(D-2*side_frame_margin-(side_window_count-1)*minimum_rib_width)/side_window_count)
 for(j=[0:side_window_count-1]) let(x0=side_frame_margin+j*(ww+minimum_rib_width))
 if(z1-z0>2*cutout_corner_radius && ww>2*cutout_corner_radius)
 offset(r=cutout_corner_radius) offset(delta=-cutout_corner_radius)
 difference() {
  translate([x0,z0]) square([ww,z1-z0]);
  if(brace_style!="none") bar([x0,z0],[x0+ww,z1],minimum_rib_width);
  if(brace_style=="cross") bar([x0,z1],[x0+ww,z0],minimum_rib_width);
 }
}
module screw_holes(w,h) { for(x=[22,w-22]) translate([x,h/2]) circle(d=4); }
module rear_keepouts() {
 if(structural) translate([D-t-minimum_joint_web,0]) square([t+minimum_joint_web,H]);
 if(backN>0) for(i=[0:backN-1]) translate([back_y()-t-minimum_joint_web,back_z(i)-minimum_joint_web/2]) square([t+minimum_joint_web,back_h()+minimum_joint_web]);
}
module joint_blank(p) {
 if(joinery_style=="tab_slot" && side_joint(p)) {
  bodyz=p[1]=="structural" ? seat : 0;
  bodyh=p[1]=="structural" ? H-2*t : p[3];
  translate([seat,bodyz]) square([IW,bodyh]);
  for(i=[0:effective_tab_count(joint_span(p))-1]) for(x=[0,seat+IW])
   translate([x,bodyz+tab_start(joint_span(p),i)]) square([seat,tab_width_for(joint_span(p))]);
  if(p[1]=="structural") for(i=[0:effective_tab_count(IW)-1]) for(y=[0,seat+H-2*t])
   translate([seat+tab_start(IW,i),y]) square([tab_width_for(IW),seat]);
 } else square([p[2],p[3]]);
}
module side_slots() {
 c=joint_fit_clearance;
 for(q=parts) if(q[1]=="horizontal") for(i=[0:effective_tab_count(joint_span(q))-1])
 translate([horizontal_y(q)+tab_start(joint_span(q),i)-c/2,horizontal_z(q)-c/2])
 slot_shape_2d(tab_width_for(joint_span(q))+c,t+c,open_bottom=horizontal_z(q)==0,open_top=horizontal_z(q)==H-t);
 if(backN>0) for(b=[0:backN-1]) for(i=[0:effective_tab_count(back_h())-1])
 translate([back_y()-t-c/2,back_z(b)+tab_start(back_h(),i)-c/2]) slot_shape_2d(t+c,tab_width_for(back_h())+c,open_right=back_y()==D);
 if(structural) for(i=[0:effective_tab_count(H-2*t)-1])
 translate([D-t-c/2,t+tab_start(H-2*t,i)-c/2]) slot_shape_2d(t+c,tab_width_for(H-2*t)+c,open_right=true);
}
module part_outline(p) {
 difference() {
  joint_blank(p);
  if(p[1]=="side") {
   if(side_style=="skeletonized")
    difference() {
     if(p[5]==1 && !mirror_sides) translate([D,0]) mirror([1,0]) side_voids(); else side_voids();
     rear_keepouts();
    }
   if(joinery_style=="tab_slot") side_slots();
   // Pilot holes for horizontal butt joints; omit when housed in dados.
   if(joinery_style=="screw") for(z=concat([t/2,H-t/2],upper_bay_enabled ? [shelf_z()+t/2] : []))
    for(y=[22,D-22]) translate([y,z]) circle(d=4);
   // Back rails/backers are attached by end screws. Full rear stile is retained.
   if(joinery_style=="screw" && backN>0) for(i=[0:backN-1]) translate([back_y()-t/2,back_z(i)+back_h()/2]) circle(d=4);
   if(joinery_style=="screw" && structural) for(z=[t+30,H-t-30]) translate([D-t/2,z]) circle(d=4);
   if(wall && !external_backers) for(i=[0:cleat_rail_count-1]) for(z=[cleat_z(i)+22,cleat_z(i)+ch-22]) translate([D-t/2,z]) circle(d=4);
  }
  if(p[1]=="horizontal" && structural && (p[5]==0 || p[5]==2 || (p[5]==1 && top_style=="panel"))) {
   if(joinery_style=="tab_slot") for(i=[0:effective_tab_count(IW)-1])
    translate([seat+tab_start(IW,i)-joint_fit_clearance/2,p[3]-t-joint_fit_clearance/2])
     slot_shape_2d(tab_width_for(IW)+joint_fit_clearance,t+joint_fit_clearance,open_top=true);
   if(joinery_style=="screw") for(x=[30,p[2]-30]) translate([x,p[3]-t/2]) circle(d=4);
  }
  if(p[1]=="applied") for(x=[t/2,W-t/2]) for(z=[t/2,H/2,H-t/2]) translate([x,z]) circle(d=4);
  if(p[1]=="backer" && external_backers) for(x=[t/2,W-t/2]) for(z=[22,ch-22]) translate([x,z]) circle(d=4);
  if(p[1]=="horizontal") for(x=[30,p[2]-30]) for(y=[30,p[3]-30]) translate([x,y]) circle(d=6);
  if(p[1]=="tray") {
   if(rear_cable_opening) translate([(TW-cable_opening_width)/2,TD-cable_opening_depth]) square([cable_opening_width,cable_opening_depth+1]);
   if(tray_handle=="finger_pull") hull() for(x=[TW/2-35,TW/2+35]) translate([x,20]) circle(r=8);
   for(x=[t/2,TW-t/2]) for(y=[22,TD-22]) translate([x,y]) circle(d=4);
  }
  if(p[1]=="spacer" || p[1]=="shim") for(x=[t/2,W-t/2]) translate([x,p[3]/2]) circle(d=4);
  if(p[1]=="lip") screw_holes(p[2],p[3]);
  if(p[1]=="tray" && slide_type=="fixed_runner") for(x=[8,TW-8]) translate([x,TD-35]) circle(d=runner_stop_diameter);
  if(p[1]=="cleat_stand" || p[1]=="cleat_wall")
   for(x=cleat_holes(p[2],p[1]=="cleat_wall" ? stud_spacing : cleat_fastener_spacing))
    translate([x,p[1]=="cleat_wall" ? cleat_edge_margin : cleat_height-cleat_edge_margin]) circle(d=cleat_fastener_diameter);
  if(p[1]=="backer") for(x=cleat_holes(CW,cleat_fastener_spacing))
   translate([(backerW-CW)/2+x,ch-cleat_edge_margin]) circle(d=cleat_fastener_diameter);
  if(p[1]=="back" && anti_tip_enabled && p[5]==backN-1) screw_holes(p[2],p[3]);
 }
}
module dado_rect(w,h) {
 square([w,h]);
 if(side_relief!="none") for(x=[0,w]) for(y=[0,h])
 translate([x+(x==0 ? 1 : -1)*(side_relief=="dogbone" ? router_bit_diameter/2/sqrt(2) : 0),
 y+(y==0 ? 1 : -1)*(side_relief=="dogbone" ? router_bit_diameter/2/sqrt(2) : router_bit_diameter/2)]) circle(d=router_bit_diameter);
}
module pockets(p,mode) {
 if(mode=="pocket_carcass_dados" && joinery_style=="dado") {
  if(p[1]=="side") {
   if(backN>0) for(i=[0:backN-1]) translate([back_y()-t-fit_clearance/2,back_z(i)-fit_clearance/2]) dado_rect(t+fit_clearance,back_h()+fit_clearance);
   if(structural) translate([D-t-fit_clearance/2,t-seat-fit_clearance/2]) dado_rect(t+fit_clearance,H-2*t+2*seat+fit_clearance);
  }
  if(p[1]=="horizontal" && structural && (p[5]==0 || p[5]==2 || (p[5]==1 && top_style=="panel")))
   translate([0,p[3]-t-fit_clearance/2]) dado_rect(p[2],t+fit_clearance);
 }

 if(mode=="pocket_carcass_dados" && joinery_style=="dado" && p[1]=="side")
 for(q=parts) if(q[1]=="horizontal")
 translate([horizontal_y(q),horizontal_z(q)-fit_clearance/2]) dado_rect(q[3],t+fit_clearance);
 if(mode=="pocket_slide_holes" && include_metal_slide_holes && slide_type=="side_mount") {
  if(p[1]=="side") for(i=[0:N-1]) for(x=metal_slide_cabinet_holes_x)
   translate([tray_inset+metal_slide_front_setback+x,slide_z(i)]) circle(d=metal_slide_cabinet_hole_diameter);
  if(p[1]=="cheek") for(x=metal_slide_drawer_holes_x)
   translate([metal_slide_front_setback+x,tray_cheek_height/2]) circle(d=metal_slide_drawer_hole_diameter);
 }
}
module panel3(p) {
 if(p[1]=="cleat_stand" || p[1]=="cleat_wall") intersection() {
  linear_extrude(p[4]) part_outline(p);
  multmatrix([[1,0,0,0],[0,0,1,0],[0,1,0,0],[0,0,0,1]])
   translate([0,0,p[1]=="cleat_stand" ? -(cleat_height-crise+cleat_vertical_gap) : 0])
    mo_cleat_profile(p[2],cleat_thickness,cleat_height,cleat_angle,p[1]=="cleat_stand" ? "stand" : "wall",cleat_vertical_gap);
 } else difference() {
  linear_extrude(p[4]) part_outline(p);
  translate([0,0,p[1]=="horizontal" && p[5]!=0 ? -0.1 : p[4]-dado_depth]) linear_extrude(dado_depth+0.1) pockets(p,"pocket_carcass_dados");
  translate([0,0,p[1]=="cheek" ? -0.1 : p[4]-slide_drill_depth]) linear_extrude(slide_drill_depth+0.1) pockets(p,"pocket_slide_holes");
 }
}
// Extruded side inside face points toward interior; right side reverses normal.
module side3(p,x,right=false) {
 multmatrix([[0,0,right ? -1 : 1,x],[1,0,0,0],[0,1,0,0],[0,0,0,1]]) panel3(p);
}
module vertical3(p,x,y,z) { translate([x,y,z]) rotate([90,0,0]) panel3(p); }
module cleat3(p) {
 i=p[5]; w=p[2]; stand=p[1]=="cleat_stand";
 x=(W-w)/2;
 z=cleat_z(i);
 difference() {
  translate([x,mountY,z]) mo_cleat_profile(w,cleat_thickness,cleat_height,cleat_angle,stand ? "stand" : "wall",cleat_vertical_gap);
  for(hx=cleat_holes(w,stand ? cleat_fastener_spacing : stud_spacing))
   translate([x+hx,mountY-0.1,z+(stand ? ch-cleat_edge_margin : cleat_edge_margin)]) rotate([-90,0,0]) cylinder(h=cleat_thickness+0.2,d=cleat_fastener_diameter);
 }
}
module assemble_part(p) {
 k=p[1]; i=p[5];
 if(k=="side") side3(p,i==0 ? 0 : W,i==1);
 else if(k=="horizontal") translate([t-seat,i==2 ? D-back_rail_height : 0,i==0 ? 0 : i==3 ? shelf_z() : H-t]) panel3(p);
 else if(k=="tray") translate([t+sg,tray_inset-ext,tz(i)]) panel3(p);
 else if(k=="cheek") translate([t+sg,tray_inset-ext,tz(i)+tt]) side3(p,p[0]==str("CHEEK_L_",i+1) ? 0 : TW,p[0]!=str("CHEEK_L_",i+1));
 else if(k=="lip") vertical3(p,t+sg+t,tray_inset-ext+t,tz(i)+tt);
 else if(k=="back") vertical3(p,t-seat,back_y(),back_z(i));
 else if(k=="structural") vertical3(p,t-seat,D,t-seat);
 else if(k=="applied") vertical3(p,0,D+custom_back_thickness,0);
 else if(k=="backer") vertical3(p,external_backers ? 0 : t,mountY,cleat_z(i));
 else if(k=="cleat_stand" || (k=="cleat_wall" && show_wall_rails)) cleat3(p);
 else if(k=="spacer") vertical3(p,0,mountY+cleat_thickness,t);
 else if(k=="shim") vertical3(p,0,mountY,t);
 else if(k=="runner") translate([0,tray_inset,0]) side3(p,p[0]==str("RUNNER_",i+1,"_0") ? t : W-t-runner_width);
}
module assembly() {
 for(p=parts) color(p[1]=="cleat_wall" ? [0.5,0.55,0.6] : [0.78,0.65,0.45])
 if(p[1]=="runner") translate([0,0,tz(p[5])-runner_height]) assemble_part(p); else assemble_part(p);
 if(show_hardware && slide_type=="side_mount") for(i=[0:N-1]) for(s=[0:1]) color([0.65,0.68,0.72]) {
  translate([s==0 ? t : W-t-sg,tray_inset+metal_slide_front_setback,slide_z(i)-metal_slide_envelope_height/2]) cube([sg/2,metal_slide_length,metal_slide_envelope_height]);
  translate([s==0 ? t+sg/2 : W-t-sg/2,tray_inset+metal_slide_front_setback-ext,slide_z(i)-metal_slide_envelope_height/2]) cube([sg/2,metal_slide_length,metal_slide_envelope_height]);
 }
 if(show_equipment) for(i=[0:N-1]) %translate([(W-device_width)/2,tray_inset-ext+(tray_lip_height>0 ? t : 0),tz(i)+tt]) cube([device_width,device_depth,device_height]);
}
module registration() { difference() {translate([-20,-20]) square([LW+40,LH+40]); translate([-19,-19]) square([LW+38,LH+38]);} }
module layout(mode) {
 registration();
 for(k=[0:len(parts)-1]) let(p=parts[k]) translate([px(k),0])
 if(mode=="cut_layout") part_outline(p);
 else if(mode=="engrave_layout" && label_parts) translate([min(p[2]/2,60),min(p[3]/2,12)]) text(p[0],size=5,halign="center");
 else pockets(p,mode);
}
module interface(id,standard,role,key,o,n=[0,0,1],u=[1,0,0],v=[0,1,0],tags="external") {
 echo(str("INTERFACE|ID=",id,"|STANDARD=",standard,"|KIND=equipment|OWNER=equipment_stand|FACE=datum|MATE=standard_and_key|DATUM=local_mm|ROLE=",role,"|KEY=",key,"|TAGS=",tags));
 echo(str("INTERFACE_FRAME|ID=",id,"|OX=",o[0],"|OY=",o[1],"|OZ=",o[2],"|UX=",u[0],"|UY=",u[1],"|UZ=",u[2],"|VX=",v[0],"|VY=",v[1],"|VZ=",v[2],"|NX=",n[0],"|NY=",n[1],"|NZ=",n[2]));
}
module reports() {
 echo(str("EXPORT_FRAME|X0=-20|Y0=-20|X1=",LW+20,"|Y1=",LH+20,"|FW=1"));
 if(validation_report!="off") validate();
 if(dimension_report!="off") {
  echo(str("DIM|equipment_stand|W=",W,"|D=",D,"|H=",H,"|TRAY_W=",TW,"|TRAY_D=",TD,"|COUNT=",N));
  echo(str("DIM|machining|DADO_DEPTH=",seat,"|SLIDE_PILOT_DEPTH=",slide_drill_depth,"|CLEAT_BEVEL_ANGLE=",cleat_angle,"|CLEAT_RISE=",crise));
 }
 if(system_contract_report!="off") {
  echo("SYSTEM|CONTRACT=MOI-4|ENGINE=modular_organization_v5");
  echo(str("MODULE|ID=equipment_stand|KIND=equipment_stand|W=",W,"|D=",(wall ? mountY+cleat_thickness : D+(applied ? custom_back_thickness : 0)),"|H=",H));
  echo("COVERAGE|SCOPE=equipment_stand|CHECKS=equipment_fit;travel;slide_bands;cleat_land;rib_width;stock;cut_and_pocket_contours|STRUCTURAL=false");
  interface("stack.top","MOI-EQUIP-STACK-1","male",str("W=",W,";D=",D,";T=",t,";SEAT=",seat),[0,0,H]);
  interface("stack.bottom","MOI-EQUIP-STACK-1","female",str("W=",W,";D=",D,";T=",t,";SEAT=",seat),[0,0,0],[0,0,-1]);
  if(wall) interface("mount.wall","MOI-MOUNT-CLEAT-1","female",mo_cleat_key(cleat_thickness,cleat_height,cleat_angle,cleat_vertical_gap),[W/2,mountY,cleat_z(0)+cleat_height],[0,1,0],[1,0,0],[0,0,1]);
  else interface("mount.floor","MOI-FLOOR-1","peer",str("W=",W,";D=",D),[0,0,0],[0,0,-1]);
  for(i=[0:N-1]) {
   interface(str("tray.",i+1),"MOI-EQUIP-TRAY-1","host",str("W=",TW,";D=",TD,";TRAVEL=",tray_extension),[t+sg,tray_inset,tz(i)],[0,0,1],[1,0,0],[0,1,0],"internal");
   interface(str("bay.",i+1),"MOI-DEVICE-BAY-1","host",str("W=",TW-2*t,";D=",TD,";H=",device_height+top_clearance),[t+sg+t,tray_inset,tz(i)+tt],[0,0,1],[1,0,0],[0,1,0],"internal");
   echo(str("KEEPOUT|ID=tray.motion.",i+1,"|X=",t,"|Y=",tray_inset-tray_extension,"|Z=",tz(i),"|W=",IW,"|D=",TD+tray_extension,"|H=",tt+device_height));
   for(s=[0:1]) interface(str("tray.",i+1,".slide.",s==0 ? "left" : "right"),"MOI-EQUIP-TRAY-1","host",str("L=",metal_slide_length,";GAP=",sg,";H=",metal_slide_envelope_height),[s==0 ? t : W-t,tray_inset,slide_z(i)],[s==0 ? 1 : -1,0,0],[0,1,0],[0,0,1],"internal");
   for(s=[0:1]) for(hx=metal_slide_cabinet_holes_x) if(include_metal_slide_holes && slide_type=="side_mount")
    echo(str("FEATURE|ID=slide_hole.",i+1,".",s,".",hx,"|OWNER=",s==0 ? "SIDE_L" : "SIDE_R","|OP=pocket_slide_holes|X=",tray_inset+metal_slide_front_setback+hx,"|Y=",slide_z(i),"|D=",metal_slide_cabinet_hole_diameter,"|DEPTH=",slide_drill_depth));
   for(s=[0:1]) echo(str("FEATURE_OWNER|ID=slide.",i+1,".",s,"|PART=",s==0 ? "SIDE_L" : "SIDE_R","|INTERFACE=tray.",i+1));
  }
 }
 if(output_mode=="bom") {
  for(p=parts) echo(str("BOM|",p[0],"|1|",p[1],"|plywood|",p[4],"|",p[2],"|",p[3],"|",p[1]=="cleat_stand" || p[1]=="cleat_wall" ? str("SECONDARY BEVEL ",cleat_angle,"deg; blank dimensions; see machining guide") : p[1]=="cheek" ? "outside face up; pilot depth from outside" : "inside face up"));
  echo(str("HARDWARE|ID=slides|QTY=",slide_type=="side_mount" ? N : 0,"|UNIT=pair|LENGTH=",metal_slide_length,"|RATING_KG=",slide_load_rating_kg));
  if(slide_type=="fixed_runner") echo(str("HARDWARE|ID=runner_retention_screws|QTY=",2*N,"|NOTE=remove for service tray; field drill runner vertically through tray holes"));
  echo(str("HARDWARE|ID=assembly_screws|QTY=",8+N*14+(upper_bay_enabled ? 4 : 0),"|UNIT=minimum estimate|NOTE=choose length for actual stock and joints"));
  echo("HARDWARE|ID=stack_bolts|QTY=4 per joint when stacking|NOTE=6mm holes; choose bolt length for two panels plus washers and nuts");
  if(anti_tip_enabled) echo("HARDWARE|ID=anti_tip_bracket|QTY=1|NOTE=select anchors for substrate");
  if(wall) echo(str("HARDWARE|ID=wall_anchors|QTY=",cleat_rail_count*len(cleat_holes(WW,stud_spacing)),"|NOTE=stud layout is a guide; verify actual wall"));
 }
}
reports();
if(output_mode=="assembly") assembly();
else if(output_mode=="flat_3d") for(k=[0:len(parts)-1]) translate([px(k),0,0]) panel3(parts[k]);
else if(output_mode!="bom") layout(output_mode);
