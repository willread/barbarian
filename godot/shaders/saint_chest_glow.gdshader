shader_type canvas_item;
render_mode unshaded, blend_add;
uniform float heat;
uniform float age;
void fragment(){
 vec4 source=texture(TEXTURE,UV);
 // Only the furnace opening and its rim, not the helmet, hammer or chains.
 vec2 p=(UV-vec2(.603,.302))/vec2(.105,.145);
 float opening=(1.-smoothstep(.68,1.12,abs(p.x)))*(1.-smoothstep(.72,1.13,abs(p.y)));
 float ember=smoothstep(.05,.30,source.r-source.b);
 float flicker=.9+.06*sin(age*29.+UV.y*37.)+.04*sin(age*43.-UV.x*51.);
 vec3 color=mix(vec3(1.,.23,.015),vec3(1.,.72,.24),ember);
 COLOR=vec4(color,source.a*opening*heat*flicker*(.22+ember*.6));
}
