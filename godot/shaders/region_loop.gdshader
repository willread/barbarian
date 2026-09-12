shader_type canvas_item;
uniform float clock = 0.0;
void fragment(){
 float frame=mod(clock*30.0,60.0);float a=floor(frame);float b=mod(a+1.0,60.0);
 vec2 tile_a=vec2(mod(a,8.0),floor(a/8.0));vec2 tile_b=vec2(mod(b,8.0),floor(b/8.0));
 vec2 pixel=TEXTURE_PIXEL_SIZE*8.0;vec2 local=clamp(UV,pixel*.5,vec2(1.0)-pixel*.5);
 COLOR=mix(texture(TEXTURE,(tile_a+local)/8.0),texture(TEXTURE,(tile_b+local)/8.0),fract(frame));
}
