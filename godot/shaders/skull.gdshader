shader_type canvas_item;
uniform sampler2D skull;
uniform float progress=1.;
void fragment(){
 float scale=exp(clamp(progress,0.,1.)*log(61.))-1.;
 vec2 p=(UV*vec2(1440.,810.)-vec2(720.,405.))/max(.001,scale)+vec2(256.);
 float inside=step(0.,p.x)*step(0.,p.y)*step(p.x,512.)*step(p.y,512.);
 float aperture=texture(skull,p/512.).r*inside;
 COLOR=vec4(0.,0.,0.,scale<.015?1.:1.-aperture);
}
