shader_type canvas_item;
uniform bool menu_palette=false;
uniform bool yellow_palette=false;
uniform vec4 accent_color : source_color = vec4(0.);
uniform float opacity=1.0;
void fragment(){
 float heat=texture(TEXTURE,UV).b;
 vec3 red=vec3(.6,.035,.004),orange=vec3(1.,.28,.012),ivory=vec3(1.,.92,.65);
 vec3 color=mix(red,orange,smoothstep(.08,.5,heat));
 color=mix(color,ivory,smoothstep(.6,1.,heat));
 if(menu_palette){
  vec3 shadow=vec3(.14,.025,.024);
  vec3 body=vec3(.62,.15,.09);
  vec3 core=vec3(.88,.77,.66);
  color=mix(shadow,body,smoothstep(.12,.65,heat));
  color=mix(color,core,smoothstep(.72,1.,heat));
 }
 if(yellow_palette){
  color=mix(vec3(.72,.30,.008),vec3(1.,.83,.035),smoothstep(.08,.42,heat));
  color=mix(color,vec3(1.,.98,.70),smoothstep(.55,.95,heat));
 }
 if(accent_color.a>0.){
  color=mix(accent_color.rgb*.38,accent_color.rgb,smoothstep(.08,.45,heat));
  color=mix(color,mix(accent_color.rgb,vec3(1.,.98,.84),.58),smoothstep(.65,1.,heat));
 }
 COLOR=vec4(color,smoothstep(.035,.3,heat)*.94*opacity);
}
