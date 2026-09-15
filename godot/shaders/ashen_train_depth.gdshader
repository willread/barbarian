shader_type canvas_item;
varying vec2 scene_position;
void vertex(){scene_position=VERTEX;}
float box(vec2 p,vec4 r){return step(r.x,p.x)*step(p.x,r.z)*step(r.y,p.y)*step(p.y,r.w);}
void fragment(){
 vec4 wagon=COLOR;
 vec2 p=scene_position;
 // Original painting coordinates mapped into the 1440 x 810 world.
 // Supports, banner poles and parked cars are in front of the rear rail.
 float hidden=box(p,vec4(109,306,167,474));
 hidden=max(hidden,box(p,vec4(438,376,479,513)));
 hidden=max(hidden,box(p,vec4(726,392,776,534)));
 hidden=max(hidden,box(p,vec4(1169,351,1208,535)));
 hidden=max(hidden,box(p,vec4(51,224,61,440)));
 hidden=max(hidden,box(p,vec4(72,237,100,385)));
 hidden=max(hidden,box(p,vec4(1357,279,1365,536)));
 // The two abandoned wagons stay on the front track, while the train passes behind.
 float cart1=box(p,vec4(587,0,650,438))*step(399.0+(p.x-587.0)*.15,p.y);
 float cart2=box(p,vec4(978,0,1051,494))*step(453.0+(p.x-978.0)*.14,p.y);
 hidden=max(hidden,max(cart1,cart2));
 // Exit behind the rock shoulder at the right end of the viaduct.
 hidden=max(hidden,smoothstep(1230.0,1260.0,p.x));
 wagon.a*=1.0-hidden;
 COLOR=wagon;
}
