shader_type canvas_item;
uniform float clock = 0.0;
uniform vec2 grid = vec2(8.0,8.0);
uniform float frame_count = 60.0;
uniform float fps = 30.0;
void fragment(){
 float frame=mod(clock*fps,frame_count);float a=floor(frame);float b=mod(a+1.0,frame_count);
 vec2 tile_a=vec2(mod(a,grid.x),floor(a/grid.x));vec2 tile_b=vec2(mod(b,grid.x),floor(b/grid.x));
 vec2 pixel=TEXTURE_PIXEL_SIZE*grid;vec2 local=clamp(UV,pixel*.5,vec2(1.0)-pixel*.5);
 COLOR=mix(texture(TEXTURE,(tile_a+local)/grid),texture(TEXTURE,(tile_b+local)/grid),fract(frame));
}
