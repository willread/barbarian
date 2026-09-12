shader_type canvas_item;
uniform sampler2D background:hint_screen_texture,filter_linear;
uniform float clock=0.;
void fragment(){
 float band=step(.33,UV.y)*step(UV.y,.66);
 float amount=.8*sin(clamp((UV.y-.33)/.33,0.,1.)*3.14159265)*band;
 vec2 delta=vec2(sin(UV.y*810.*.051-clock*3.14159265)*amount/1440.,0.);
 COLOR=mix(texture(background,SCREEN_UV),texture(background,SCREEN_UV+delta),.3);
}
