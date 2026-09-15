shader_type canvas_item;
#include "res://shaders/ashen_track.gdshaderinc"
uniform float clock=0.0;
uniform float area=1.0;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p){vec2 i=floor(p),f=fract(p);f=f*f*(3.0-2.0*f);return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);}
float plume(vec2 uv,vec2 source,vec2 size){
 vec2 p=(uv-source)/size;
 float rise=clamp(-p.y,0.0,1.0);
 float curl=sin(rise*7.0-clock*.7+source.x*19.0)*.13*rise;
 return (1.0-smoothstep(.15,.7,abs(p.x+curl)/(0.3+rise)))*smoothstep(-.08,.08,-p.y)*(1.0-smoothstep(.65,1.0,rise));
}
vec2 banner(vec2 uv,vec4 rect,float phase){
 vec2 p=(uv-rect.xy)/rect.zw;
 float mask=smoothstep(0.0,.12,p.x)*(1.0-smoothstep(.88,1.0,p.x))*smoothstep(0.0,.15,p.y)*(1.0-smoothstep(.90,1.0,p.y));
 mask*=step(0.0,p.x)*step(p.x,1.0)*step(0.0,p.y)*step(p.y,1.0);
 return vec2(sin(p.y*5.0-clock*1.9+phase)*.0015*p.y*mask,0.0);
}
void fragment(){
 vec2 uv=UV;
 if(area<1.5){uv+=banner(UV,vec4(.041,.288,.028,.183),0.0)+banner(UV,vec4(.917,.342,.035,.166),1.7);}
 else if(area>3.5){uv+=banner(UV,vec4(.31,.34,.035,.21),1.1)+banner(UV,vec4(.66,.34,.035,.21),2.8);}
 float lane=1.0-smoothstep(.65,.73,uv.y);
 float sources=0.0;
 if(area<1.5){sources=plume(uv,vec2(.70,.36),vec2(.12,.28))+plume(uv,vec2(.79,.25),vec2(.09,.22));}
 else if(area<2.5){sources=plume(uv,vec2(.50,.67),vec2(.25,.53))+plume(uv,vec2(.30,.50),vec2(.14,.25))+plume(uv,vec2(.73,.55),vec2(.15,.28));}
 else if(area<3.5){sources=plume(uv,vec2(.405,.60),vec2(.13,.49))+plume(uv,vec2(.64,.62),vec2(.12,.38))+plume(uv,vec2(.84,.61),vec2(.12,.39));}
 else{sources=plume(uv,vec2(.20,.70),vec2(.15,.43))+plume(uv,vec2(.80,.70),vec2(.15,.43))+plume(uv,vec2(.50,.70),vec2(.20,.35));}
 // Two advected turbulence scales bend the image like rising hot air,
 // with much less displacement on the playable paving and at screen edges.
 vec2 flow=vec2(uv.x*72.0,uv.y*39.0+clock*1.7);
 vec2 turbulence=vec2(noise(flow),noise(flow+vec2(17.2,4.8)))-.5;
 turbulence+=(vec2(noise(flow*2.13+clock*.31),noise(flow*2.13+23.1))-.5)*.36;
 float edges=smoothstep(0.0,.035,uv.x)*(1.0-smoothstep(.965,1.0,uv.x));
 float ground=smoothstep(.72,.78,uv.y)*(1.0-smoothstep(.84,.98,uv.y));
 float strength=(.00055*lane+min(sources,1.4)*.0028*lane+ground*.00045)*edges;
 uv+=turbulence*vec2(1.0,.48)*strength;
 // The narrow pour stays attached to the left lip and receiving trough.
 float lava=0.0;
 if(area>2.5 && area<3.5){
  float center=.408-(uv.y-.20)*.012;
  lava=(1.0-smoothstep(.003,.008,abs(uv.x-center)))*smoothstep(.195,.225,uv.y)*(1.0-smoothstep(.49,.518,uv.y));
  lava=max(lava,(1.0-smoothstep(.009,.020,abs(uv.x-.416)))*smoothstep(.508,.525,uv.y)*(1.0-smoothstep(.57,.592,uv.y)));
  uv.x+=sin(uv.y*57.0-clock*4.0)*.00065*lava;
 }
 vec4 paint=texture(TEXTURE,clamp(uv,vec2(.001),vec2(.999)));
 if(area<1.5){paint=road_scene(clamp(uv,vec2(.001),vec2(.999)));}
 // Animate only painted fire/lava; iron and stone keep their original colour.
 float hot=smoothstep(.12,.42,paint.r-paint.b)*smoothstep(.25,.6,paint.r);
 float fire=noise(vec2(uv.x*160.0,uv.y*85.0+clock*4.4));
 float flicker=.35+.4*fire+.25*sin(clock*2.7+uv.x*39.0);
 if(area>1.5 && area<2.5){
  // Spatially offset noise gives each window and torch its own irregular
  // burn. Slow fuel variation and faster flutter avoid a synchronized pulse.
  float fuel=noise(vec2(uv.x*23.0+uv.y*11.0,clock*2.5));
  float flutter=noise(vec2(uv.x*41.0-uv.y*9.0+17.0,clock*6.0));
  float tips=noise(vec2(uv.x*67.0+uv.y*31.0+5.0,clock*10.5));
  float burn=fuel*.60+flutter*.30+tips*.10;
  // Modulate down as well as up so bright painted flame cores visibly
  // flicker instead of disappearing into an already saturated highlight.
  paint.rgb*=1.0+hot*lane*(burn-.5)*.85;
  paint.rgb+=vec3(.045,.018,.002)*hot*lane*burn;
 }else{
  paint.rgb+=vec3(.16,.052,.006)*hot*lane*flicker;
 }
 // Bright streaks advect downward, with independently changing hot rivulets.
 if(lava>0.0){
  float flow_lava=noise(vec2(uv.x*900.0,uv.y*170.0-clock*25.0));
  float rivulet=noise(vec2(uv.x*1700.0+7.0,uv.y*73.0-clock*11.0));
  paint.rgb*=1.0+lava*hot*((flow_lava*.7+rivulet*.3)-.5)*.95;
  paint.rgb+=vec3(.11,.055,.006)*lava*hot*flow_lava;
 }
 // Painted smoke moves without displacing the furnace architecture.
 float gray=1.0-smoothstep(.03,.16,abs(paint.r-paint.b));
 float smoke=gray*smoothstep(.17,.34,paint.r)*(1.0-smoothstep(.55,.72,paint.r))*lane;
 float billow=noise(vec2(uv.x*19.0-clock*.06,uv.y*24.0+clock*.25));
 paint.rgb+=vec3(.035,.030,.025)*(billow-.5)*smoke*min(sources+float(area<1.5),1.0);
 COLOR=paint;
}
