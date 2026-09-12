shader_type canvas_item;
void fragment(){
 float heat=texture(TEXTURE,UV).b;
 vec3 red=vec3(.6,.035,.004),orange=vec3(1.,.28,.012),ivory=vec3(1.,.92,.65);
 vec3 color=mix(red,orange,smoothstep(.08,.5,heat));
 color=mix(color,ivory,smoothstep(.6,1.,heat));
 COLOR=vec4(color,smoothstep(.035,.3,heat)*.94);
}
