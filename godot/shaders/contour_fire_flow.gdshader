shader_type canvas_item;
render_mode blend_disabled;
uniform sampler2D history:hint_screen_texture,filter_linear;
uniform sampler2D fuel_mask:filter_linear;
uniform vec2 domain;
uniform vec2 fuel_size;
uniform float clock=0.;
uniform float delta=0.016667;
uniform bool reset=true;
uniform bool emitting=true;
uniform float strength=1.;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p){vec2 i=floor(p),f=fract(p);f=f*f*(3.-2.*f);return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);}
float mask_at(vec2 p){vec2 uv=(p-vec2(32.))/fuel_size;return texture(fuel_mask,clamp(uv,vec2(0),vec2(1))).a*step(0.,uv.x)*step(0.,uv.y)*step(uv.x,1.)*step(uv.y,1.);}
vec4 state(vec2 p){if(reset)return vec4(.5,.5,0.,0.);return texture(history,clamp(p/domain,vec2(0),vec2(1)));}
void fragment(){
 vec2 p=SCREEN_UV*domain;
 vec4 old=state(p);
 vec2 velocity=(old.rg-.5)*180.;
 vec4 carried=state(p-velocity*delta);
 float heat=carried.b;
 vec2 q=p*.075+vec2(0.,clock*.65);
 // Curl of a smooth noise potential supplies small evolving eddies, not a sine-wave bend.
 vec2 curl=vec2(noise(q+vec2(0,.12))-noise(q-vec2(0,.12)),-noise(q+vec2(.12,0))+noise(q-vec2(.12,0)))/.24;
 vec2 normal=vec2(mask_at(p-vec2(1.5,0))-mask_at(p+vec2(1.5,0)),mask_at(p-vec2(0,1.5))-mask_at(p+vec2(0,1.5)));
 velocity=(carried.rg-.5)*180.;
 velocity+=(curl*115.+vec2(0.,-145.*heat)+normal*100.)*delta;
 velocity*=exp(-delta*2.8);
 velocity=clamp(velocity,vec2(-65.),vec2(65.));
 float nearby=max(max(mask_at(p+vec2(2.,0)),mask_at(p-vec2(2.,0))),max(mask_at(p+vec2(0,2.)),mask_at(p-vec2(0,2.))));
 float edge=max(length(normal),nearby-mask_at(p));
 float patches=noise(p*.16+vec2(clock*.7,-clock*1.8));
 float flicker=.12+1.25*smoothstep(.27,.76,patches);
 float source=smoothstep(.04,.5,edge)*flicker*strength*(emitting?1.:0.);
 heat=max(heat-delta*(1.05+.95*noise(q*1.9)),source);
 float boundary=smoothstep(0.,12.,min(min(p.x,domain.x-p.x),min(p.y,domain.y-p.y)));
 COLOR=vec4(velocity/180.+.5,clamp(heat,0.,1.)*boundary,1.);
}

