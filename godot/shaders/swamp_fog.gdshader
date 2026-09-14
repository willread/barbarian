shader_type canvas_item;
uniform float clock=0.0;
uniform float area=1.0;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p){
 vec2 i=floor(p),f=fract(p);f=f*f*(3.0-2.0*f);
 return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}
float mist(vec2 p){return noise(p)*.57+noise(p*2.03+13.1)*.29+noise(p*4.07+5.7)*.14;}
void fragment(){
 float coverage=0.0;
 for(int i=0;i<9;i++){
  float n=float(i);
  // Layered banks travel across the arena and curl gently as they pass.
  float x=mod(n*.59+area*.31+clock*(.028+n*.0025),2.6)-.8;
  float y=.24+fract(n*.371+area*.17)*.70+sin(clock*.12+n*2.1)*.045;
  vec2 size=vec2(.24+fract(n*.43)*.18,.09+fract(n*.61)*.09);
  vec2 p=(UV-vec2(x,y))/size;
  p+=vec2(sin(p.y*2.0+clock*.16+n)*.12,cos(p.x*2.3-clock*.13+n)*.10);
  float billow=mist(p*2.3+vec2(-clock*.055,n*19.0+area+clock*.025));
  float edge=1.0-smoothstep(.25,1.2,length(p)+(.5-billow)*.42);
  coverage+=edge*smoothstep(.20,.82,billow)*.52;
 }
 float alpha=min(.43,coverage)*(1.0-smoothstep(.94,1.0,UV.y));
 COLOR=vec4(.65,.70,.67,alpha);
}
