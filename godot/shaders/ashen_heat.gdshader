shader_type canvas_item;
uniform float clock=0.0;
uniform float area=1.0;
void fragment(){
 vec4 paint=texture(TEXTURE,UV);
 float hot=smoothstep(.12,.42,paint.r-paint.b)*smoothstep(.25,.6,paint.r);
 float behind_lane=1.0-smoothstep(.64,.7,UV.y);
 float pulse=.5-.5*cos(clock*6.2831853/8.0);
 float flicker=.5+.3*sin(clock*6.2831853/3.0+UV.y*35.0)+.2*sin(clock*6.2831853/2.0+UV.x*60.0);
 paint.rgb+=vec3(.20,.065,.008)*hot*behind_lane*(area>3.5 ? pulse : flicker);
 COLOR=paint;
}
