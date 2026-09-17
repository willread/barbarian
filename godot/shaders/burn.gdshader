shader_type canvas_item;
uniform float burn_age=0.0;
uniform float engulf=1.0;
uniform float seed=0.0;
uniform float electric=0.0;
uniform float hit_glow=0.0;
uniform float exposure=1.0;
uniform float shadow_lift=0.0;
uniform float tonal_contrast=1.0;
void fragment(){
 vec4 c=texture(TEXTURE,UV)*COLOR;
 c.rgb=min(vec3(1.0),c.rgb*exposure+vec3(shadow_lift)*(vec3(1.0)-c.rgb));
 c.rgb=pow(max(c.rgb,vec3(0.0)),vec3(tonal_contrast));
 if(burn_age>0.0){
  // Consume from the top toward the feet; noise only roughens the burn front.
  float phase=clamp((burn_age-.15)/(engulf+.6),0.,1.);
  float edge=UV.y+.018*sin(UV.x*39.+seed)+.009*sin(UV.x*83.-seed);
  float front=mix(-.04,1.04,phase);
  c.rgb*=1.-clamp(burn_age/(engulf+.6),0.,1.)*.78;
  c.a*=smoothstep(front-.012,front+.012,edge);
  float ember=(1.-smoothstep(.008,.045,abs(edge-front)))*step(front,edge);
  c.rgb=mix(c.rgb,vec3(1.,.24,.025),ember);
  if(phase>=1.)c.a=0.;
 }
 c.rgb*=1.+hit_glow*2.2;
 if(electric>0.)c.rgb=mix(c.rgb,vec3(dot(c.rgb,vec3(.3,.59,.11))),.85)*(1.7+1.8*step(.67,fract(TIME*10.)));
 COLOR=c;
}
