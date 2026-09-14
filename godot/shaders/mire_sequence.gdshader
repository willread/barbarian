shader_type canvas_item;
uniform float formation=0.0;
uniform float pose=0.0;
uniform float clock=0.0;
uniform int part=0;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p){vec2 i=floor(p),f=fract(p);f=f*f*(3.0-2.0*f);return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);}
void fragment(){
 vec2 local=UV;
 float frame=mod(floor(clock*5.0),4.0);
 float row=1.0;
 float reveal=1.0;
 if(part==0){
  local=(UV-vec2(0,.46))/vec2(1,.60);
  float field=noise(UV*vec2(18,12));
  reveal=smoothstep(field-.12,field+.12,floor(formation*32.0)/32.0*1.24-.12);
 }else{
  row=0.0;
  float x=.05;float y=.19;float w=.32;float h=.61;
  if(part==2){x=.25;y=.02;w=.34;h=.74;}
  if(part==3){x=.44;y=.18;w=.34;h=.66;}
  if(part==4){x=.65;y=.14;w=.32;h=.67;}
  local=(UV-vec2(x,y))/vec2(w,h);
  if(part==1||part==4)local.x=1.0-local.x;
  frame=floor(clamp(pose,0.0,3.0)+.5);
  reveal=smoothstep(1.0-clamp(pose,0.0,1.0)-.06,1.0-clamp(pose,0.0,1.0)+.06,local.y);
  reveal*=step(.01,pose);
 }
 float inside=step(0.0,local.x)*step(local.x,1.0)*step(0.0,local.y)*step(local.y,1.0);
 vec2 uv=vec2(frame*.25,row*.5)+clamp(local*vec2(.25,.5),TEXTURE_PIXEL_SIZE,vec2(.25,.5)-TEXTURE_PIXEL_SIZE);
 vec4 ink=texture(TEXTURE,uv);
 float alpha=ink.a*inside*reveal;
 if(part==0)alpha*=.90;
 else alpha*=1.0-smoothstep(.91,.98,local.y);
 COLOR=vec4(ink.rgb,alpha);
}
