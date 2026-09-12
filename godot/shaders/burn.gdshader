shader_type canvas_item;
uniform float burn_age=0.0;
uniform float engulf=1.0;
uniform float seed=0.0;
uniform float electric=0.0;
uniform float hit_glow=0.0;
void fragment(){
 vec4 c=texture(TEXTURE,UV)*COLOR;
 if(burn_age>0.0){
  float phase=clamp((burn_age-.15-engulf)/.6,0.,1.);
  vec2 p=UV*128.;
  float n=.5+.17*sin(p.x*.19+seed)*cos(p.y*.16)+.16*sin(p.x*.49+p.y*.27)+.1*cos(p.y*.81-p.x*.7+seed);
  c.rgb*=1.-clamp((burn_age-.4)/1.1,0.,1.)*.78;
  if(phase>0.){c.a*=step(phase,n);if(n-phase<.035)c.rgb=vec3(1.,.39,.047);}
  if(phase>=1.)c.a=0.;
 }
 c.rgb*=1.+hit_glow*2.2;
 if(electric>0.)c.rgb=mix(c.rgb,vec3(dot(c.rgb,vec3(.3,.59,.11))),.85)*(1.7+1.8*step(.67,fract(TIME*10.)));
 COLOR=c;
}
