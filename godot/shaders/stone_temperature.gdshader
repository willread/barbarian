shader_type canvas_item;
render_mode blend_disabled;
uniform sampler2D history: hint_screen_texture, filter_linear;
uniform sampler2D flames: filter_linear;
uniform vec2 domain;
uniform float delta=0.016667;
uniform bool reset=true;
void fragment(){
    vec2 uv=SCREEN_UV;
    vec2 px=1.0/domain;
    float fire=texture(flames,uv).b;
    fire+=texture(flames,uv+vec2(3.,0.)*px).b;
    fire+=texture(flames,uv-vec2(3.,0.)*px).b;
    fire+=texture(flames,uv+vec2(0.,3.)*px).b;
    fire+=texture(flames,uv-vec2(0.,3.)*px).b;
    float old=reset?0.:texture(history,uv).r;
    float target=clamp(fire*.38,0.,1.);
    float temperature=mix(old,target,1.-exp(-delta*(target>old?3.8:1.15)));
    COLOR=vec4(vec3(temperature),1.);
}
