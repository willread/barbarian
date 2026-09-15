shader_type canvas_item;
uniform sampler2D scene: hint_screen_texture, filter_linear, repeat_disable;
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
void fragment(){
 vec2 uv=UV;
 float sources=0.0;
 if(area<1.5){sources=plume(uv,vec2(.70,.36),vec2(.12,.28))+plume(uv,vec2(.79,.25),vec2(.09,.22));}
 else if(area<2.5){sources=plume(uv,vec2(.50,.67),vec2(.25,.53))+plume(uv,vec2(.30,.50),vec2(.14,.25))+plume(uv,vec2(.73,.55),vec2(.15,.28));}
 else if(area<3.5){sources=plume(uv,vec2(.405,.60),vec2(.13,.49))+plume(uv,vec2(.64,.62),vec2(.12,.38))+plume(uv,vec2(.84,.61),vec2(.12,.39));}
 else{sources=plume(uv,vec2(.20,.70),vec2(.15,.43))+plume(uv,vec2(.80,.70),vec2(.15,.43))+plume(uv,vec2(.50,.70),vec2(.20,.35));}
 // Tall rising cells and broad heat sheets refract almost the entire scene.
 // Source plumes stay stronger, while the nearest paving and frame edges ease out.
 vec2 flow=vec2(uv.x*58.0+clock*.12,uv.y*18.0+clock*1.45);
 vec2 turbulence=vec2(noise(flow),noise(flow+vec2(17.2,4.8)))-.5;
 turbulence+=(vec2(noise(flow*2.13+clock*.31),noise(flow*2.13+23.1))-.5)*.36;
 turbulence+=(vec2(noise(uv*vec2(21.0,10.0)+vec2(0.0,clock*.4)),noise(uv*vec2(18.0,8.0)+vec2(19.0,clock*.33)))-.5)*.30;
 float edges=smoothstep(0.0,.035,uv.x)*(1.0-smoothstep(.965,1.0,uv.x));
 float ground=smoothstep(.62,.78,uv.y)*(1.0-smoothstep(.91,1.0,uv.y));
 float atmosphere=(.35+.65*smoothstep(.02,.28,uv.y))*(1.0-smoothstep(.93,1.0,uv.y));
 float strength=(.0032*atmosphere+min(sources,1.4)*.0048+ground*.0022)*edges;
 vec2 offset=turbulence*vec2(1.0,.30)*strength;

 vec2 screen_offset=offset*SCREEN_PIXEL_SIZE/ max(fwidth(UV),vec2(.00001));
 COLOR=texture(scene,clamp(SCREEN_UV+screen_offset,SCREEN_PIXEL_SIZE,vec2(1.0)-SCREEN_PIXEL_SIZE));
}
