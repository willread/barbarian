shader_type canvas_item;
uniform float age;
uniform float urgency;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p){vec2 i=floor(p),f=fract(p);f=f*f*(3.-2.*f);return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+1.),f.x),f.y);}
void fragment(){
 vec2 p=(UV-.5)*2.;p.y+=.13;
 float r=length(p*vec2(1.13,1.05));
 float grain=noise(p*90.);
 float edge=1.-smoothstep(.795,.815,r);
 vec3 normal=normalize(vec3(p/.81,sqrt(max(0.,1.-r*r/.66))));
 vec3 lamp=normalize(vec3(-.6,-.8,1.));
 float light=max(.08,dot(normal,lamp));
 float spec=pow(max(0.,dot(reflect(-lamp,normal),vec3(0,0,1))),42.);
 float reflection=pow(1.-abs(normal.x*.7+normal.y*.5+.18),12.);
 vec3 iron=mix(vec3(.075,.085,.10),vec3(.43,.48,.54),light);
 iron+=vec3(.8,.87,.94)*spec+vec3(.17,.20,.24)*reflection;
 iron*=.96+grain*.08;
 float band=1.-smoothstep(.045,.065,abs(p.y+p.x*.25));
 float rim=exp(-pow((abs(p.y+p.x*.25)-.058)*110.,2.));
 iron=mix(iron,iron*.32,band)+vec3(.33,.36,.40)*rim*light;
 float pulse=.5+.5*sin(age*(12.+urgency*20.));
 vec3 col=iron+vec3(.48,.06,.008)*urgency*urgency*pulse;
 float fuse=exp(-length((p-vec2(.12,-.87))*vec2(1.,1.7))*32.);
 col+=vec3(1.,.63,.15)*fuse*(1.+pulse);
 COLOR=vec4(col,max(edge,fuse));
}
