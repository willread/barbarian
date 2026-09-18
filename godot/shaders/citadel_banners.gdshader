shader_type canvas_item;
uniform float clock=0.;
vec2 cloth(vec2 uv,vec4 bounds,float seed){
 vec2 pixel=uv*vec2(1672.,941.);
 vec2 q=(pixel-bounds.xy)/bounds.zw;
 float inside=step(0.,q.x)*step(q.x,1.)*step(0.,q.y)*step(q.y,1.);
 float free_end=smoothstep(0.,.22,q.y);
 float edge=smoothstep(0.,.1,q.x)*(1.-smoothstep(.9,1.,q.x))*(1.-smoothstep(.91,1.,q.y));
 float gust=.75+.25*sin(clock*.47+seed);
 float wave=sin(clock*1.65-q.y*3.8+seed)*5.5*gust+sin(clock*3.1-q.y*10.+seed)*1.8*q.y;
 return vec2(wave*free_end*edge*inside,sin(clock*1.7+seed-q.y*5.)*1.1*q.y*edge*inside)/vec2(1672.,941.);
}
void fragment(){
 vec2 shift=cloth(UV,vec4(24,10,117,430),.2);
 shift+=cloth(UV,vec4(313,203,104,290),1.7);
 shift+=cloth(UV,vec4(540,327,86,187),2.9);
 shift+=cloth(UV,vec4(712,216,94,164),4.3);
 shift+=cloth(UV,vec4(1124,331,84,197),5.8);
 shift+=cloth(UV,vec4(1257,203,108,294),7.1);
 shift+=cloth(UV,vec4(1532,10,115,434),8.9);
 vec4 original=texture(TEXTURE,UV);
 vec4 moved=texture(TEXTURE,UV+shift);
 // Confine deformation to dark cloth rather than bending adjacent pale stone.
 float cloth_mask=1.-smoothstep(.11,.23,max(original.r,max(original.g,original.b)));
 COLOR=mix(original,moved,cloth_mask);
}
