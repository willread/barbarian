shader_type canvas_item;
#include "res://shaders/ashen_track.gdshaderinc"
#include "res://shaders/reliquary_lock.gdshaderinc"
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
// Each post flame stays rooted at its grate; only the rising tongue deforms.
vec3 post_fire(vec2 uv,vec2 base,vec2 extent,float seed){
 vec2 p=(uv*vec2(1672.0,941.0)-base)/extent;
 float rise=clamp(-p.y,0.0,1.0);
 float mask=(1.0-smoothstep(.55,1.0,abs(p.x)))*smoothstep(0.0,.16,rise)*(1.0-smoothstep(.82,1.0,rise));
 float flutter=noise(vec2(seed+rise*5.0,clock*3.7));
 float curl=sin(rise*8.0-clock*(5.0+seed*.07)+seed);
 return vec3(vec2((curl*2.1+(flutter-.5)*3.0)*rise,(flutter-.5)*5.0*rise)*mask/vec2(1672.0,941.0),mask);
}
// Source-registered smoke: rising curls deform the pale painted puffs only.
vec3 reliquary_smoke(vec2 uv,vec2 base,vec2 extent,float seed){
 vec2 p=(uv*vec2(1672.,941.)-base)/extent;
 float rise=clamp(-p.y,0.,1.);
 float mask=(1.-smoothstep(.35,1.,abs(p.x)))*smoothstep(0.,.15,rise)*(1.-smoothstep(.72,1.,rise));
 float billow=noise(vec2(p.x*2.8+seed,p.y*3.7+clock*.72));
 float curl=sin(rise*8.-clock*1.15+seed);
 return vec3(vec2(curl*4.5*rise+(billow-.5)*4.,(billow-.5)*10.-sin(clock*.83+seed)*2.)*mask/vec2(1672.,941.),mask);
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
 // The narrow pour stays attached to the left lip and receiving trough.
 float lava=0.0;
 // Distant molten cascade: fixed cliff boundaries, falling internal channels.
 if(area<1.5){
  float center=.700+(uv.y-.30)*.055;
  lava=(1.0-smoothstep(.010,.033,abs(uv.x-center)))*smoothstep(.245,.265,uv.y)*(1.0-smoothstep(.425,.46,uv.y));
  vec4 source=texture(road_original,uv);
  float molten=smoothstep(.15,.4,source.r-source.b)*smoothstep(.3,.65,source.r);
  lava*=molten;
  uv.x+=sin(uv.y*130.0-clock*5.0)*.0012*lava;
  uv.y+=sin(uv.y*95.0-clock*7.0)*.002*lava;
 }
 if(area>2.5 && area<3.5){
  float center=.408-(uv.y-.20)*.012;
  lava=(1.0-smoothstep(.003,.008,abs(uv.x-center)))*smoothstep(.195,.225,uv.y)*(1.0-smoothstep(.49,.518,uv.y));
  lava=max(lava,(1.0-smoothstep(.009,.020,abs(uv.x-.416)))*smoothstep(.508,.525,uv.y)*(1.0-smoothstep(.57,.592,uv.y)));
  uv.x+=sin(uv.y*57.0-clock*4.0)*.00065*lava;
 }
 float post_mask=0.0;
 float reliquary_smoke_mask=0.0;
 if(area>3.5){
  vec3 puffs=reliquary_smoke(uv,vec2(421,254),vec2(43,77),1.);
  puffs+=reliquary_smoke(uv,vec2(1250,254),vec2(45,77),7.);
  puffs+=reliquary_smoke(uv,vec2(111,536),vec2(53,138),3.);
  puffs+=reliquary_smoke(uv,vec2(319,563),vec2(42,120),11.);
  puffs+=reliquary_smoke(uv,vec2(451,553),vec2(46,126),5.);
  puffs+=reliquary_smoke(uv,vec2(1218,553),vec2(46,126),17.);
  puffs+=reliquary_smoke(uv,vec2(1350,563),vec2(42,120),23.);
  puffs+=reliquary_smoke(uv,vec2(1555,536),vec2(53,138),29.);
  vec3 source=texture(TEXTURE,uv).rgb;
  float pale=(1.-smoothstep(.04,.15,abs(source.r-source.b)))*smoothstep(.15,.32,source.r);
  reliquary_smoke_mask=clamp(puffs.z,0.,1.)*pale;
  uv+=puffs.xy*pale;
  vec3 fires=post_fire(uv,vec2(188,312),vec2(30,62),2.);
  fires+=post_fire(uv,vec2(1482,310),vec2(29,62),13.);
  fires+=post_fire(uv,vec2(395,516),vec2(27,105),4.);
  fires+=post_fire(uv,vec2(1278,516),vec2(27,105),19.);
  fires+=post_fire(uv,vec2(461,561),vec2(21,44),6.);
  fires+=post_fire(uv,vec2(1212,562),vec2(21,44),22.);
  fires+=post_fire(uv,vec2(630,521),vec2(22,59),8.);
  fires+=post_fire(uv,vec2(1041,521),vec2(22,59),27.);
  fires+=post_fire(uv,vec2(145,630),vec2(16,39),10.);
  fires+=post_fire(uv,vec2(298,649),vec2(25,41),12.);
  fires+=post_fire(uv,vec2(1379,647),vec2(25,41),31.);
  fires+=post_fire(uv,vec2(1526,630),vec2(16,39),34.);
  fires+=post_fire(uv,vec2(132,532),vec2(20,36),15.);
  fires+=post_fire(uv,vec2(318,561),vec2(20,42),16.);
  fires+=post_fire(uv,vec2(1355,561),vec2(20,42),37.);
  fires+=post_fire(uv,vec2(1540,532),vec2(20,36),41.);
  uv+=fires.xy;
  post_mask=clamp(fires.z,0.,1.);
 }
 if(area>2.5 && area<3.5){
  vec3 posts=post_fire(uv,vec2(242,137),vec2(30,74),1.0);
  posts+=post_fire(uv,vec2(346,124),vec2(17,59),4.0);
  posts+=post_fire(uv,vec2(293,387),vec2(36,58),7.0);
  posts+=post_fire(uv,vec2(397,311),vec2(17,44),10.0);
  posts+=post_fire(uv,vec2(514,380),vec2(23,44),13.0);
  posts+=post_fire(uv,vec2(883,187),vec2(18,51),16.0);
  posts+=post_fire(uv,vec2(1285,302),vec2(23,40),19.0);
  posts+=post_fire(uv,vec2(1552,429),vec2(27,56),22.0);
  posts+=post_fire(uv,vec2(1220,510),vec2(25,38),25.0);
  posts+=post_fire(uv,vec2(1450,537),vec2(20,31),28.0);
  posts+=post_fire(uv,vec2(337,524),vec2(16,28),31.0);
  uv+=posts.xy;
  post_mask=clamp(posts.z,0.0,1.0);
 }
 vec4 paint=texture(TEXTURE,clamp(uv,vec2(.001),vec2(.999)));
 if(area<1.5){paint=road_scene(clamp(uv,vec2(.001),vec2(.999)));}
 if(area>3.5){
  // Sample rigidly rotated metal only inside the collars. The central sigil,
  // door frame and stairs stay fixed, with narrow feathered mechanical seams.
  float collar=lock_band(uv);
  if(collar>0.0){paint=mix(paint,texture(TEXTURE,lock_uv(uv,clock)),collar);}
 }
 // Animate only painted fire/lava; iron and stone keep their original colour.
 float hot=smoothstep(.12,.42,paint.r-paint.b)*smoothstep(.25,.6,paint.r);
 float fire=noise(vec2(uv.x*160.0,uv.y*85.0+clock*4.4));
 float flicker=.35+.4*fire+.25*sin(clock*2.7+uv.x*39.0);
 if((area>1.5 && area<2.5) || area>3.5){
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
 if(post_mask>0.0){
  float fuel=noise(vec2(uv.x*91.0+uv.y*37.0,clock*3.0));
  float flutter=noise(vec2(uv.x*143.0-uv.y*53.0,clock*8.5));
  paint.rgb*=1.0+post_mask*hot*((fuel*.65+flutter*.35)-.5)*1.15;
  paint.rgb+=vec3(.055,.023,.003)*post_mask*hot*flutter;
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
 if(reliquary_smoke_mask>0.){
  float rolling=noise(vec2(uv.x*71.+noise(uv*23.+clock*.1)*2.,uv.y*63.+clock*1.2));
  paint.rgb+=vec3(.11,.10,.09)*(rolling-.5)*reliquary_smoke_mask;
 }
 COLOR=paint;
}

