shader_type canvas_item;
uniform sampler2D temperature: filter_linear;
uniform vec2 face_size;
uniform vec2 domain;
uniform vec2 offset;
void fragment(){
    vec4 stone=texture(TEXTURE,UV);
    vec2 px=1./face_size;
    float inner=1.;
    float outer=0.;
    for(int i=0;i<8;i++){
        float angle=float(i)*.785398;
        vec2 direction=vec2(cos(angle),sin(angle));
        inner=min(inner,texture(TEXTURE,UV+direction*px*2.8).a);
        outer=max(outer,texture(TEXTURE,UV+direction*px*3.).a);
    }
    float heat=texture(temperature,(UV*face_size+offset)/domain).r;
    float edge=stone.a*(1.-inner);
    float glow=max(outer-stone.a,0.)*.32;
    vec3 ember=mix(vec3(.8,.07,.006),vec3(1.,.43,.065),smoothstep(.25,.85,heat));
    // Preserve the mineral detail: reflected fire catches the bevel, not the whole face.
    float grain=dot(stone.rgb,vec3(.3,.5,.2));
    vec3 lit=stone.rgb+ember*heat*(edge*(.65+grain)+.12);
    float halo=glow*heat;
    COLOR=vec4(mix(ember,lit,stone.a),max(stone.a,halo));
}
