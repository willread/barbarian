shader_type canvas_item;
uniform float clock=0.0;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p){vec2 i=floor(p),f=fract(p);f=f*f*(3.-2.*f);return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);}
float cloud(vec2 p){return noise(p)*.57+noise(p*2.03+7.1)*.29+noise(p*4.11+19.7)*.14;}
vec4 smoke(vec2 p,vec2 source,float height,float width,float seed){
 float rise=(source.y-p.y)/height;
 if(rise<0. || rise>1. || abs(p.x-source.x)>width*2.)return vec4(0.);
 float drift=sin(rise*5.-clock*.32+seed)*width*.27*rise;
 float x=(p.x-source.x-drift)/(width*(.24+rise*.85));
 vec2 flow=vec2(x*1.8+seed,rise*5.-clock*.44);
 vec2 warp=vec2(noise(flow*.7),noise(flow*.8+13.))-.5;
 float n=cloud(flow+warp*1.5);
 float edge=1.-smoothstep(.25,1.15,abs(x)+(n-.5)*.85);
 float fade=smoothstep(0.,.07,rise)*(1.-smoothstep(.65,1.,rise));
 float alpha=edge*fade*smoothstep(.18,.8,n)*.73;
 vec3 tint=mix(vec3(.105,.10,.10),vec3(.29,.27,.25),n);
 tint+=vec3(.26,.085,.015)*exp(-rise*7.);
 return vec4(tint,alpha);
}
vec4 flame(vec2 p,vec2 source,vec2 extent,float seed){
 vec2 q=(p-source)/extent;
 float rise=-q.y;
 if(rise<0. || rise>1. || abs(q.x)>1.4)return vec4(0.);
 float fuel=.82+.18*noise(vec2(seed,clock*3.));
 float curl=sin(rise*9.-clock*4.5+seed)*.13*rise;
 float n=cloud(vec2(q.x*4.+seed,rise*7.-clock*3.4));
 float shape=(1.-rise/fuel)*.6-abs(q.x+curl)+(n-.5)*.48;
 float a=smoothstep(-.10,.17,shape)*smoothstep(0.,.10,rise)*(1.-smoothstep(.65,1.,rise));
 vec3 color=mix(vec3(.95,.18,.012),vec3(1.,.78,.27),clamp(shape*2.3,0.,1.));
 return vec4(color,a*.82);
}
vec4 over(vec4 back,vec4 front){float a=front.a+back.a*(1.-front.a);return vec4((front.rgb*front.a+back.rgb*back.a*(1.-front.a))/max(a,.0001),a);}
void fragment(){
 vec2 p=UV*vec2(1440.,810.);
 vec4 v=smoke(p,vec2(354.,238.),255.,84.,2.);
 v=over(v,smoke(p,vec2(1082.,238.),185.,53.,8.));
 v=over(v,smoke(p,vec2(340.,446.),192.,67.,12.));
 v=over(v,smoke(p,vec2(1100.,446.),150.,43.,19.));
 v=over(v,flame(p,vec2(340.,444.),vec2(21.,80.),3.));
 v=over(v,flame(p,vec2(1100.,444.),vec2(22.,86.),13.));
 v=over(v,flame(p,vec2(354.,238.),vec2(22.,54.),7.));
 v=over(v,flame(p,vec2(1082.,238.),vec2(23.,59.),17.));
 v=over(v,flame(p,vec2(542.,449.),vec2(12.,40.),23.));
 v=over(v,flame(p,vec2(897.,449.),vec2(12.,42.),29.));
 // All added atmosphere stays behind and above the playable paving.
 COLOR=vec4(v.rgb,v.a*(1.-smoothstep(545.,565.,p.y)));
}
