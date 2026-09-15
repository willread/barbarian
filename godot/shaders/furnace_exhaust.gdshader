shader_type canvas_item;
uniform float clock=0.0;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p){
 vec2 i=floor(p),f=fract(p);f=f*f*(3.0-2.0*f);
 return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}
float turbulence(vec2 p){return noise(p)*.57+noise(p*2.03+17.1)*.29+noise(p*4.07+5.3)*.14;}
vec4 exhaust(vec2 pixel,vec2 mouth,float direction,float seed){
 vec2 d=pixel-mouth;
 float along=d.x*direction;
 if(along < -9.0 || along > 205.0 || d.y < -205.0 || d.y > 75.0){return vec4(0.0);}
 float age=clamp(along/165.0,0.0,1.2);
 // Pressure sends the jet down the angled pipe before buoyancy lifts it.
 float center=38.0*sin(age*2.4)-135.0*age*age;
 center+=sin(age*5.7-clock*.52+seed)*12.0*age;
 float width=16.0+age*42.0;
 float crossflow=(d.y-center)/width;
 float fade=smoothstep(-6.0,4.0,along)*(1.0-smoothstep(.68,1.18,age));
 // Advected, domain-warped turbulence breaks the edge into rolling billows.
 vec2 flow=vec2(along*.031-clock*(.63+seed*.009),crossflow*1.6+seed);
 vec2 curl=vec2(noise(flow*.73+seed),noise(flow*.81+11.0))-.5;
 float billow=turbulence(flow+curl*1.3);
 float edge=1.0-smoothstep(.35,1.12,abs(crossflow)+(0.5-billow)*1.05);
 float pressure=.86+.08*sin(clock*.81+seed)+.06*sin(clock*1.37+seed*2.0);
 float density=edge*fade*smoothstep(.14,.82,billow)*pressure;
 float alpha=1.0-exp(-density*1.7);
 // Warm underside catches furnace light; the upper curls remain ashen gray.
 float light=clamp(.52-crossflow*.18+(billow-.5)*.55,0.0,1.0);
 vec3 color=mix(vec3(.24,.225,.21),vec3(.53,.50,.46),light);
 color+=vec3(.085,.029,.006)*exp(-age*4.0)*max(crossflow,0.0);
 return vec4(color,alpha);
}
void fragment(){
 vec2 p=UV*vec2(1440.0,810.0);
 vec4 left=exhaust(p,vec2(501.0,302.0),-1.0,2.7);
 vec4 right=exhaust(p,vec2(1073.0,426.0),1.0,8.3);
 // The right outlet is partially hidden by the sloping bridge parapet.
 right.a*=1.0-smoothstep(578.0-p.x*.139,582.0-p.x*.139,p.y);
 float a=left.a+right.a*(1.0-left.a);
 vec3 color=(left.rgb*left.a+right.rgb*right.a*(1.0-left.a))/max(a,.0001);
 // The bridge rail and combat paving stay in front of the exhaust.
 float bridge=1.0-smoothstep(472.0,493.0,p.y);
 COLOR=vec4(color,a*bridge);
}
