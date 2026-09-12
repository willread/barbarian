shader_type canvas_item;
uniform sampler2D region_mask;
uniform sampler2D painting;
uniform vec2 travel=vec2(0.);
uniform float period=6.;
uniform float clock=0.;
uniform bool smoke=false;
vec4 sample_flow(sampler2D source,vec2 uv,float p){
 float grow=smoke?1.+(p-.5)*.07:1.;
 vec2 offset=vec2((p-.5)*travel.x,(smoke?p:p-.5)*travel.y)-vec2((grow-1.)*.5,grow-1.);
 return texture(source,clamp((uv-offset)/grow,vec2(0.),vec2(1.)));
}
void fragment(){
 float a=fract(clock/period),b=fract(a+.5);
 vec4 c=sample_flow(painting,UV,a)*pow(sin(a*3.14159265),2.)+sample_flow(painting,UV,b)*pow(sin(b*3.14159265),2.);
 c.a*=texture(region_mask,UV).a;
 COLOR=c;
}


