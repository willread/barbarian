shader_type canvas_item;
uniform float formation=0.0;
uniform float pose=0.0;
// -1 previews the full cel; 0 is mud; 1..4 are independently sorted hands.
uniform int part=-1;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p){
 vec2 i=floor(p),f=fract(p);f=f*f*(3.0-2.0*f);
 return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}
float cel(float step_index){
 // Existing warning -> submerged hands -> open hands -> grasp, and back again.
 if(step_index<.5)return 0.0;
 if(step_index<1.5)return 3.0;
 if(step_index<2.5)return 1.0;
 return 2.0;
}
vec2 pose_uv(vec2 edge,float step_index,vec2 local){
 float f=cel(step_index);
 vec2 tile=vec2(mod(f,2.0),floor(f/2.0));
 return tile*.5+clamp(local*.5,edge,vec2(.5)-edge);
}
void fragment(){
 float frame=floor(pose+.5);
 vec4 sampled=texture(TEXTURE,pose_uv(TEXTURE_PIXEL_SIZE,part==0?0.0:frame,UV));
 float alpha=sampled.a;
 vec3 rgb=sampled.rgb;
 if(part>0){
  // Cut each hand from its own pose region, ending at its ground contact.
  vec4 bounds=vec4(0.0);
  if(frame<.5)alpha=0.0;
  else if(frame<1.5){
   if(part==1)bounds=vec4(.28,.35,.43,.70);
   if(part==2)alpha=0.0;
   if(part==3)bounds=vec4(.50,.57,.69,.83);
   if(part==4)bounds=vec4(.70,.43,.89,.74);
  }else if(frame<2.5){
   if(part==1)bounds=vec4(.12,.27,.29,.74);
   if(part==2)bounds=vec4(.32,.08,.51,.71);
   if(part==3)bounds=vec4(.49,.42,.69,.83);
   if(part==4)bounds=vec4(.70,.32,.89,.74);
  }else{
   if(part==1)bounds=vec4(.15,.34,.33,.74);
   if(part==2)bounds=vec4(.36,.10,.59,.71);
   if(part==3)bounds=vec4(.51,.46,.69,.83);
   if(part==4)bounds=vec4(.70,.35,.89,.74);
  }
  alpha*=step(bounds.x,UV.x)*step(UV.x,bounds.z)*step(bounds.y,UV.y)*(1.0-smoothstep(bounds.w-.025,bounds.w,UV.y));
 }
 // 32 progressive buildup steps reveal irregular wet islands within the oval.
 // The same fixed field is traversed backward on exit: no UV travel or scaling.
 float buildup=floor(formation*32.0)/32.0;
 float field=.65*noise(UV*vec2(13,9))+.35*noise(UV*vec2(31,19));
 float reveal=smoothstep(field-.12,field+.12,buildup*1.24-.12);
 if(part==0){
  // Feather the wet perimeter and retain the underlying soil's colour/detail.
  float rim=length((UV-vec2(.5,.72))/vec2(.51,.23));
  alpha*=.68*(1.0-smoothstep(.65,1.05,rim));
 }
 COLOR=vec4(rgb,alpha*reveal);
}
