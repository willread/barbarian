shader_type canvas_item;
varying vec4 tint;
void vertex(){tint=COLOR;}
void fragment(){
 vec4 c=texture(TEXTURE,UV);
 // Use opaque neighboring color for pale matte contamination at feathered edges.
 float strongest=c.a;vec3 interior=c.rgb;
 for(int y=-1;y<=1;y++)for(int x=-1;x<=1;x++){
  vec4 n=texture(TEXTURE,UV+vec2(float(x),float(y))*TEXTURE_PIXEL_SIZE);
  if(n.a>strongest){strongest=n.a;interior=n.rgb;}
 }
 float pale=smoothstep(.55,.9,min(c.r,min(c.g,c.b)));
 c.rgb=mix(c.rgb,interior,pale*(1.-smoothstep(.45,.95,c.a)));
 COLOR=c*tint;
}
