shader_type canvas_item;
render_mode blend_mul;
void fragment(){
 vec4 stain=texture(TEXTURE,UV);
 // Multiply leaves stone/soil detail visible; transparent ink is neutral white.
 vec3 pigment=mix(vec3(.68,.22,.25),stain.rgb,.22);
 COLOR=vec4(mix(vec3(1.),pigment,stain.a*.72),1.);
}
