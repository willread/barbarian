shader_type canvas_item;
uniform float age=0.;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p){vec2 i=floor(p),f=fract(p);f=f*f*(3.-2.*f);return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+1.),f.x),f.y);}
float fbm(vec2 p){return noise(p)*.55+noise(p*2.03)*.27+noise(p*4.11)*.13+noise(p*8.2)*.05;}
void fragment(){
 vec2 p=UV*vec2(660.,540.)-vec2(330.,410.);
 float t=max(age,.001),spread=1.-exp(-t*12.);
 vec3 color=vec3(0.);float alpha=0.;
 // Ground pressure wave shares the gameplay footprint, followed by dusty turbulence.
 float ground=length(p/vec2(220.,85.));
 float ring=exp(-pow((ground-(1.-exp(-t*16.)))*25.,2.))*exp(-t*7.);
 color=vec3(.9,.62,.3);alpha=ring*.8;
 for(int i=0;i<11;i++){
  float f=float(i);float h=hash(vec2(f,4.));
  vec2 center=vec2(sin(f*2.4)*(45.+h*110.)*spread,-35.-h*100.*spread-t*(28.+h*44.));
  float radius=(55.+h*38.)*(.12+spread)*(1.+t*.35);
  vec2 q=(p-center)/radius;
  float n=fbm(q*3.5+vec2(f*7.,-t*1.4));
  float density=1.-smoothstep(.52,1.12,length(q)+(n-.5)*.7);
  density*=smoothstep(0.,.04,t)*(1.-smoothstep(1.1,2.4,t))*.84;
  float heat=clamp(1.25-t*1.55-length(q)*.3+(n-.5)*1.5,0.,1.);
  vec3 soot=mix(vec3(.045,.04,.037),vec3(.29,.25,.21),n);
  vec3 fire=mix(vec3(.65,.055,.008),vec3(1.,.47,.045),smoothstep(.25,.7,heat));
  fire=mix(fire,vec3(1.,.91,.6),smoothstep(.78,1.,heat));
  vec3 cloud=mix(soot,fire,smoothstep(.08,.42,heat));
  color=mix(color,cloud,density);alpha=density+alpha*(1.-density);
 }
 for(int i=0;i<24;i++){
  float f=float(i),h=hash(vec2(f,9.)),a=f*2.399;
  vec2 v=vec2(cos(a)*(120.+h*420.),-80.-h*370.);
  vec2 pos=v*t+vec2(0.,280.*t*t);
  vec2 d=p-pos;float spark=exp(-length(d/vec2(2.+h*2.,4.+h*7.)))* (1.-smoothstep(.35,1.1,t));
  color=mix(color,vec3(1.,.48,.1),spark);alpha=max(alpha,spark);
 }
 float flash=exp(-length(p/vec2(110.,85.)))*exp(-t*24.);
 COLOR=vec4(color+vec3(1.,.8,.4)*flash,clamp(alpha+flash,0.,1.));
}
