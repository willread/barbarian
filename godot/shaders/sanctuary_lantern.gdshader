shader_type canvas_item;
uniform float clock=0.;
uniform float seed=0.;
void fragment(){
 vec4 original=texture(TEXTURE,UV);
 float hot=smoothstep(.16,.46,original.r-original.b)*smoothstep(.3,.7,original.r);
 float cage=smoothstep(.6,.65,UV.y)*(1.-smoothstep(.77,.82,UV.y));
 vec2 flow=vec2(sin(UV.y*97.-clock*6.+seed)*.003,cos(UV.x*80.+clock*4.1+seed)*.004)*hot*cage;
 vec4 paint=texture(TEXTURE,UV+flow);
 float flicker=.75+.17*sin(clock*7.3+UV.x*37.+seed)+.08*sin(clock*11.7+UV.y*53.+seed);
 paint.rgb*=1.+hot*(flicker-.7)*.7;
 paint.rgb+=vec3(.08,.025,.002)*hot*flicker;
 COLOR=paint;
}
