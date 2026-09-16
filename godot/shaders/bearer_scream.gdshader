shader_type canvas_item;
render_mode unshaded;
uniform float age;
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
 float blast=smoothstep(.59,.68,age)*(1.-smoothstep(1.,1.25,age));
 float power=.10*warn+blast*.9;
 vec4 mouth=jet(p,vec2(86.,-166.),normalize(vec2(1.,.15)),205.,64.,1.,power);
 vec4 chest=jet(p,vec2(11.,-137.),normalize(vec2(.9,.35)),225.,83.,8.,power);
 vec4 furnace=jet(p,vec2(14.,-207.),normalize(vec2(.1,-1.)),88.,70.,15.,power);
 vec4 fire=mix(mouth,chest,chest.a);fire.a=max(mouth.a,chest.a);
 fire.rgb=mix(fire.rgb,furnace.rgb,furnace.a);fire.a=max(fire.a,furnace.a);
 float glow=exp(-length((p-vec2(11.,-137.))/vec2(48.,40.)))*warn*(1.-smoothstep(1.,1.3,age))*.18;
 COLOR=vec4(fire.rgb+vec3(1.,.17,.01)*glow,max(fire.a,glow));
}
