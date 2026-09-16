shader_type canvas_item;
render_mode unshaded;
uniform float age;
uniform float flame_power;
uniform vec4 jet_0;
uniform vec4 jet_1;
uniform vec4 jet_2;
uniform vec2 direction_0;
uniform vec2 direction_1;
uniform vec2 direction_2;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p){vec2 i=floor(p),f=fract(p);f=f*f*(3.-2.*f);return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+1.),f.x),f.y);}
vec4 jet(vec2 p,vec2 origin,vec2 direction,float reach,float width,float seed,float power){
 vec2 delta=p-origin;
 float along=dot(delta,direction)/reach;
 float side=dot(delta,vec2(-direction.y,direction.x));
 float n=noise(vec2(along*9.-age*18.,side*.07+seed));
 n=n*.65+noise(vec2(along*21.-age*29.,side*.15+seed))*.35;
 float taper=width*(.25+max(0.,along)*.8)*power;
 float shape=(1.-smoothstep(.45,1.,abs(side+sin(along*12.-age*20.+seed)*along*7.)/max(1.,taper)));
 shape*=smoothstep(-.03,.025,along)*(1.-smoothstep(power*.55,power,along));
 shape*=smoothstep(.13,.6,n);
 float core=clamp(1.-along*.85-abs(side)/max(1.,taper)*.5+n*.3,0.,1.);
 vec3 color=mix(vec3(.65,.045,.004),vec3(1.,.49,.035),core);
 color=mix(color,vec3(1.,.91,.53),smoothstep(.76,1.,core));
 return vec4(color,shape);
}
void fragment(){
 vec2 p=UV*vec2(480.,350.)-vec2(170.,340.);
 float warn=smoothstep(0.,.6,age);

 vec4 mouth=jet(p,jet_0.xy,direction_0,jet_0.z,jet_0.w,1.,flame_power);
 vec4 chest=jet(p,jet_1.xy,direction_1,jet_1.z,jet_1.w,8.,flame_power);
 vec4 furnace=jet(p,jet_2.xy,direction_2,jet_2.z,jet_2.w,15.,flame_power);
 vec4 fire=mix(mouth,chest,chest.a);fire.a=max(mouth.a,chest.a);
 fire.rgb=mix(fire.rgb,furnace.rgb,furnace.a);fire.a=max(fire.a,furnace.a);
 float glow=exp(-length((p-vec2(11.,-137.))/vec2(48.,40.)))*warn*(1.-smoothstep(1.,1.3,age))*.18;
 COLOR=vec4(fire.rgb+vec3(1.,.17,.01)*glow,max(fire.a,glow));
}
