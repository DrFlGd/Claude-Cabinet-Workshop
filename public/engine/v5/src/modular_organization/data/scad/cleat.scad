// Reusable MOI-MOUNT-CLEAT-1 geometry. Local axes: X width, Y stock, Z height.
// angle is the slope above horizontal in the Y/Z section. Both halves share
// the same Y interval; their bevels meet with a vertical assembly gap.
module mo_cleat_profile(width, thickness, height, angle=45, half="wall", gap=0.5) {
    rise=thickness*tan(angle);
    section=half=="wall" ? [[0,0],[thickness,0],[thickness,height],[0,height-rise]]
        : [[0,height-rise+gap],[thickness,height+gap],
           [thickness,2*height-rise+gap],[0,2*height-rise+gap]];
    multmatrix([[0,0,1,0],[1,0,0,0],[0,1,0,0],[0,0,0,1]])
        linear_extrude(height=width) polygon(section);
}
function mo_cleat_key(thickness,height,angle,gap)=
    str("T=",thickness,";H=",height,";A=",angle,";G=",gap);
