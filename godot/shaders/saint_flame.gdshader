shader_type canvas_item;
render_mode unshaded;
uniform float age;
uniform float power;
uniform float reach;
uniform vec2 origin;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p){vec2 i=floor(p),f=fract(p);f=f*f*(3.-2.*f);return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+1.),f.x),f.y);}
void fragment(){
 vec2 p=UV*vec2(1500,400)-vec2(20,440)-origin;
 float along=p.x/max(reach,1.);
 float width=(65.+65.*clamp(along,0.,1.))*power;
 float curl=sin(p.x*.023-age*15.)*12.*along;
 float n=noise(vec2(p.x*.016-age*12.,p.y*.038));
 n=n*.65+noise(vec2(p.x*.045-age*21.,p.y*.075))*.35;
 float edge=abs(p.y+curl)/max(width,1.);
 float envelope=smoothstep(-5.,15.,p.x)*(1.-smoothstep(power*.88,power,max(0.,along)));
 float flame=(1.-smoothstep(.42,1.,edge))*smoothstep(.16,.56,n)*envelope*step(.005,power);
 float core=clamp(1.-edge*.72-along*.35+n*.2,0.,1.);
 vec3 color=mix(vec3(.55,.035,.002),vec3(1.,.43,.018),core);
 color=mix(color,vec3(1.,.94,.65),smoothstep(.72,1.,core));
 float glow=exp(-length(p/vec2(60.,75.)))*smoothstep(.4,1.1,age)*(1.-smoothstep(2.3,2.6,age))*.5;
 COLOR=vec4(color+vec3(1.,.18,.015)*glow,max(flame,glow));
}
