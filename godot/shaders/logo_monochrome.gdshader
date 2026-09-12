shader_type canvas_item;
uniform float blend=0.;
void fragment(){
    vec4 logo=texture(TEXTURE,UV);
    COLOR=vec4(mix(logo.rgb,vec3(1.),blend),logo.a);
}
