shader_type canvas_item;
uniform float highlight=0.0;
uniform vec4 region=vec4(0.0,0.0,1.0,1.0);
void fragment(){
 vec4 stone=texture(TEXTURE,UV);
 vec2 local=(UV-region.xy)/region.zw;
 float sweep=pow(max(0.0,1.0-abs(fract(TIME*.22)*1.8-.4-local.x)*7.0),3.0);
 float edge=pow(clamp(max(abs(local.x-.5)*2.0,abs(local.y-.5)*2.0),0.0,1.0),10.0);
 vec3 light=vec3(1.0,.48,.12)*(edge*.16+sweep*.12);
 COLOR=vec4(stone.rgb*(1.0+highlight*.28)+light*highlight,stone.a);
}
