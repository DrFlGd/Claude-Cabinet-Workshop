// Rectangular section tree. Public rows remain ordinary editable SCAD arrays.
// parent,order,axis,size_mode,size,contents,count,height_mode,step,weights,separator,shelves
function sec_children(i) = [for(k=[0:len(section_nodes)-1]) if(section_nodes[k][0]==i) k];
function sec_sum(a,i=0) = i>=len(a)?0:a[i]+sec_sum(a,i+1);
function sec_gap(i) = section_nodes[i][10]=="none"?0:material_thickness;
function sec_root() = [face_frame_active?face_frame_inner_left_x:material_thickness,front_opening_bottom_z,face_frame_active?face_frame_clear_width:inner_width,front_opening_top_z-front_opening_bottom_z];
function sec_span(i,parent) = let(k=sec_children(section_nodes[i][0]),axis=section_nodes[section_nodes[i][0]][2],available=(axis=="x"?parent[2]:parent[3])-sec_gap(section_nodes[i][0])*(len(k)-1),fixed=sec_sum([for(c=k) section_nodes[c][3]=="mm"?section_nodes[c][4]:0]),weights=sec_sum([for(c=k) section_nodes[c][3]=="weight"?section_nodes[c][4]:0])) section_nodes[i][3]=="mm"?section_nodes[i][4]:(available-fixed)*section_nodes[i][4]/max(0.001,weights);
function sec_rect(i,depth=0) = assert(depth<=8,"Section nesting exceeds eight levels") i==0?sec_root():let(p=section_nodes[i][0],r=sec_rect(p,depth+1),axis=section_nodes[p][2],before=[for(c=sec_children(p)) if(section_nodes[c][1]<section_nodes[i][1]) c],offset=sec_sum([for(c=before) sec_span(c,r)+sec_gap(p)]),span=sec_span(i,r)) axis=="x"?[r[0]+offset,r[1],span,r[3]]:[r[0],r[1]+r[3]-offset-span,r[2],span];
function sec_leaves() = [for(i=[0:len(section_nodes)-1]) if(section_nodes[i][2]=="leaf") i];
function sec_dividers() = [for(i=[0:len(section_nodes)-1]) if(section_nodes[i][2]!="leaf" && sec_gap(i)>0) for(c=sec_children(i)) if(section_nodes[c][1]>0) let(p=sec_rect(i),r=sec_rect(c),vertical=section_nodes[i][2]=="x") [str("SEC-",i+1,"-DIV-",section_nodes[c][1]),vertical?r[0]-material_thickness:p[0],vertical?p[1]:r[1]+r[3],vertical?material_thickness:p[2],vertical?p[3]:material_thickness,section_nodes[i][10]=="rail"?min(80,usable_depth):usable_depth,vertical]];
function sec_shelves() = [for(i=sec_leaves()) if(section_nodes[i][5]!="drawers") let(r=sec_rect(i),n=section_nodes[i][5]=="open"?section_nodes[i][6]:section_nodes[i][11]) if(n>0) for(s=[1:n]) [str("SEC-",i+1,"-SH-",s),r[0],r[1]+r[3]*s/(n+1)-material_thickness/2,r[2],material_thickness,max(1,usable_depth-10),false]];
function sec_panels() = concat(sec_dividers(),sec_shelves());
// Separate registered bands; deliberately not an optimized sheet nest.
function sec_band() = 12*(cabinet_height+resolved_cabinet_width+resolved_cabinet_depth+layout_gap);
function sec_panel_y(i) = (len(sec_leaves())+1)*sec_band()+i*(max(cabinet_height,resolved_cabinet_width,resolved_cabinet_depth)+layout_gap);
module sec_validate(){
 assert(len(section_nodes)>0 && len(section_nodes)<=31,"Use 1 to 31 section nodes");
 assert(section_nodes[0][0]==-1,"Root section must have parent -1");
 assert(width_basis=="outside" && depth_basis=="outside","Section layout requires outside-envelope sizing");
 for(i=[0:len(section_nodes)-1]){
  n=section_nodes[i];r=sec_rect(i);children=sec_children(i);
  assert(len(n)==12,str("Invalid section row ",i+1));
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
 echo("WARN|SECTION_SUPPORTS|Interior section panels/rails/shelves use butt-fit blanks; provide suitable cleats, brackets or shop-drilled fasteners. Cabinet-side slide/hinge mounting holes are transferred during fitting; drawer/door machining remains in the exports.");
}
module sec_leaf(i,mode,section_depth){
 r=sec_rect(i);n=section_nodes[i];
 // Re-resolve existing drawer/door geometry in a virtual opening. No duplicate carcass is emitted.
 cabinet_width=r[2]+2*material_thickness;
 cabinet_height=r[3]+2*material_thickness;
 cabinet_depth=section_depth;
 active_cabinet_layout_mode="legacy";
 cabinet_contents=n[5]=="drawers"?"drawers":n[5]=="doors"?"doors":"open";
 front_facing_style="none";
 front_width_style="inset";
 fronts_cover_bottom_lip=false;
 extend_top_drawer_face_to_top=false;
 bottom_above_toe=0;has_toe_kick=false;base_hardware_active=false;worktop_active=false;
 drawer_bank_count=1;drawer_bank_layout_mode="shared";
 drawer_count=n[5]=="drawers"?n[6]:1;door_count=n[5]=="doors"?n[6]:0;door_shelf_count=0;
 drawer_height_mode=n[7];drawer_graduated_step=n[8];drawer_height_weights=n[9];
 include_drawer_separators=false;include_door_hinge_partitions=false;
 width_basis="outside";depth_basis="outside";
 top_style="full";
 $section_id=str("SEC-",i+1);
 include <core.scad>
 include <layouts_modules.scad>
 if(has_drawers){
  echo(str("DIM|SECTION_MACHINING|",$section_id,"|DRAWER_DADO_DEPTH=",drawer_joint_geometry=="dado"?effective_drawer_dado_depth():0,"|BOTTOM_GROOVE_DEPTH=",drawer_bottom_joinery=="dado"?effective_drawer_bottom_dado_depth():0,"|FACE_REGISTRATION_DEPTH=",active_drawer_face_registration?drawer_face_registration_blind_depth():0));
  assert(drawer_outer_width(0)>2*drawer_material_thickness+20 && drawer_box_depth>2*drawer_material_thickness+20,"Section is too small for its drawer hardware");
  for(d=[0:drawer_count-1])assert(drawer_face_nominal_height(d)>2*drawer_vertical_clearance+40,"Drawer fronts are too short for safe box clearance");
 }
 if(has_doors)echo(str("DIM|SECTION_MACHINING|",$section_id,"|HINGE_CUP_DEPTH=",effective_hinge_style=="euro_35mm"?effective_hinge_cup_depth:0,"|MACHINING_FACE=door_back"));
 if(has_doors)assert(door_each_width(0)>40 && door_face_height>40,"Door opening is too small");
 if(mode=="assembly"||mode=="drawers_only"){all_drawers();if(mode=="assembly")doors();}
 else if(mode=="bom")bom_report();
 else if(mode=="cut_layout"){drawer_cut_layout();door_cut_layout();}
 else if(mode=="engrave_layout"){drawer_engrave_labels();door_engrave_labels();}
 else if(mode=="flat_3d"||mode=="print_layout"){
  if(has_drawers)standalone_drawer_print_layout();
  if(has_doors)for(d=[0:door_count-1])translate([door_layout_part_x(d),door_layout_y,0])door_print_part(d);
 }
 else {
  if(mode=="pocket_layout"||mode=="pocket_drawer_dados")drawer_dado_operation_geometry_2d();
  if(mode=="pocket_layout"||mode=="pocket_bottom_grooves")drawer_bottom_operation_geometry_2d();
  if(mode=="pocket_layout"||mode=="pocket_divider_bottom_grooves")drawer_divider_bottom_operation_geometry_2d();
  if(mode=="pocket_layout"||mode=="pocket_divider_perimeter_grooves")drawer_divider_perimeter_operation_geometry_2d();
  if(mode=="pocket_layout"||mode=="pocket_hinge_cups")hinge_cup_operation_geometry_2d();
  if(mode=="pocket_layout"||mode=="pocket_face_registration")face_registration_operation_geometry_2d();
 }
}
module sec_registration(){
 if(include_shared_export_bounding_box)translate([-export_bounding_box_margin,-export_bounding_box_margin])difference(){
  square([sec_band()+2*export_bounding_box_margin,sec_panel_y(len(sec_panels()))+2*export_bounding_box_margin]);
  translate([export_bounding_box_frame_width,export_bounding_box_frame_width])square([sec_band()+2*export_bounding_box_margin-2*export_bounding_box_frame_width,sec_panel_y(len(sec_panels()))+2*export_bounding_box_margin-2*export_bounding_box_frame_width]);
 }
}
module section_layout_output(){
 sec_validate();leaves=sec_leaves();panels=sec_panels();
 if(output_mode=="assembly"||output_mode=="carcass_only"||output_mode=="drawers_only"){
  if(output_mode!="drawers_only"){
   carcass();face_frame_assembly_3d();
   for(p=panels)color([0.72,0.52,0.32])translate([p[1],0,p[2]])cube([p[3],p[5],p[4]]);
  }
  if(output_mode!="carcass_only")for(i=leaves)let(r=sec_rect(i))translate([r[0]-material_thickness,front_reference_y,r[1]-material_thickness])sec_leaf(i,output_mode,resolved_cabinet_depth);
 }else if(output_mode=="bom"){
  bom_report();for(i=leaves)sec_leaf(i,"bom",resolved_cabinet_depth);
  for(p=panels)bom_row(p[0],p[6]?"section_partition":"section_shelf","CARCASS",material_thickness,p[6]?p[5]:p[3],p[6]?p[4]:p[5],"butt_fit_blank; shop_install_supports");
 }else if(output_mode=="flat_3d"||output_mode=="print_layout"){
  print_layout();
  for(j=[0:len(leaves)-1])translate([0,(j+1)*sec_band(),0])sec_leaf(leaves[j],output_mode,resolved_cabinet_depth);
  if(len(panels)>0)for(j=[0:len(panels)-1])let(p=panels[j])translate([0,sec_panel_y(j),0])linear_extrude(material_thickness)cut_part(p[6]?p[5]:p[3],p[6]?p[4]:p[5]);
 }else if(output_mode=="cut_layout"||output_mode=="engrave_layout"||substr_category(output_mode)=="pocket"){
  sec_registration();
  if(output_mode=="cut_layout"){carcass_cut_layout();accessory_cut_layout();}
  else if(output_mode=="engrave_layout"){carcass_engrave_labels();face_frame_engrave_labels();accessory_engrave_labels();}
  else if(output_mode=="pocket_layout")blind_operation_geometry_2d();
  else if(output_mode=="pocket_carcass_dados")carcass_dado_operation_geometry_2d();
  else if(output_mode=="pocket_base_hardware")base_hardware_operation_geometry_2d();
  else if(output_mode=="pocket_worktop_registration")worktop_registration_operation_geometry_2d();
  else if(output_mode=="pocket_face_frame_dados")face_frame_dado_operation_geometry_2d();
  else if(output_mode=="pocket_ganging")ganging_operation_geometry_2d();
  for(j=[0:len(leaves)-1])translate([0,(j+1)*sec_band()])sec_leaf(leaves[j],output_mode,resolved_cabinet_depth);
  if(len(panels)>0)for(j=[0:len(panels)-1])let(p=panels[j])translate([0,sec_panel_y(j)]){
   if(output_mode=="cut_layout")cut_part(p[6]?p[5]:p[3],p[6]?p[4]:p[5]);
   if(output_mode=="engrave_layout")engraving_label(p[0],p[6]?p[5]:p[3],p[6]?p[4]:p[5]);
  }
 }else assert(false,"This output mode is not supported by section layout");
}
