shader_type canvas_item;
uniform float age;
uniform float urgency;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p){vec2 i=floor(p),f=fract(p);f=f*f*(3.-2.*f);return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+1.),f.x),f.y);}
void fragment(){
 vec2 p=(UV-.5)*2.;p.y+=.13;
 float r=length(p*vec2(1.13,1.05));
 float grain=noise(p*39.);float n=noise(p*8.);
 float edge=1.-smoothstep(.74+n*.09,.79+n*.09,r);
 float z=sqrt(max(0.,1.-r*r));
 float light=max(.08,dot(normalize(vec3(p,z)),normalize(vec3(-.6,-.8,1.))));
 vec3 iron=mix(vec3(.045,.039,.033),vec3(.32,.25,.18),light)*( .65+grain*.6);
 float seam=pow(1.-abs(sin(p.x*17.+noise(p*5.)*9.)),22.)*.7;
 float band=1.-smoothstep(.055,.095,abs(p.y+p.x*.25));
 iron=mix(iron,vec3(.095,.085,.073)*(light+.4),band);
 float pulse=.6+.4*sin(age*(12.+urgency*15.));
 vec3 col=iron+vec3(1.,.19,.018)*seam*(.25+urgency*pulse);
 float fuse=exp(-length((p-vec2(.12,-.87))*vec2(1.,1.7))*32.);
 col+=vec3(1.,.63,.15)*fuse*(1.+pulse);
 COLOR=vec4(col,max(edge,fuse));
}
