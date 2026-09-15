shader_type canvas_item;
uniform sampler2D depth_mask;
varying vec2 painting_uv;
void vertex(){painting_uv=VERTEX/vec2(1280.0,720.0);}
void fragment(){COLOR.a*=texture(depth_mask,painting_uv).a;}
