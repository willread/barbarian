shader_type canvas_item;
render_mode unshaded;
uniform sampler2D stone: repeat_enable, filter_linear_mipmap;
uniform vec2 screen_size=vec2(1440.,810.);
uniform vec4 opening=vec4(0.,0.,1440.,810.);
uniform float game_scale=1.;
void fragment(){
 vec2 p=UV*screen_size;
 vec2 nearest=clamp(p,opening.xy,opening.zw);
 vec2 outward=p-nearest;
 float distance_to_opening=length(outward);
 vec2 direction=outward/max(distance_to_opening,.001);
 float unit=max(game_scale,.1);
 vec2 stone_uv=p/(512.*unit);
 vec3 rock=texture(stone,stone_uv).rgb;
 float grain=dot(rock,vec3(.299,.587,.114));
 // A rough, broad chamfer slopes down toward the opening. Texture continues
 // across its face, with a small perspective compression instead of a flat band.
 float bevel_width=(28.+(grain-.3)*9.)*unit;
 float face=1.-smoothstep(bevel_width-1.5*unit,bevel_width+1.5*unit,distance_to_opening);
 float slope=clamp(distance_to_opening/bevel_width,0.,1.);
 vec2 face_uv=stone_uv+direction*(1.-slope)*face*.014;
 rock=texture(stone,face_uv).rgb;
 vec3 normal=normalize(vec3(-direction*1.6*face,1.));
 vec3 light=normalize(vec3(-.65,-.8,1.));
 float diffuse=max(dot(normal,light),0.);
 float ridge=exp(-pow((distance_to_opening-bevel_width)/(1.1*unit),2.));
 float facing_light=max(dot(-direction,normalize(vec2(-.65,-.8))),0.);
 float recess=smoothstep(0.,5.*unit,distance_to_opening);
 float illumination=mix(.88,.16+1.65*pow(diffuse,1.4),face);
 vec3 color=rock*vec3(.72,.75,.79)*illumination;
 color+=rock*ridge*(.16+.95*facing_light);
 color*=mix(.08,1.,recess);
 COLOR=vec4(color,1.);
}
