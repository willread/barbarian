shader_type canvas_item;
render_mode blend_disabled;
uniform sampler2D history:hint_screen_texture,filter_nearest;
uniform vec4 positions[64];
uniform vec4 shapes[64];
uniform float amounts[64];
uniform int count=0;
uniform bool clear=true;
uniform float age=0.;
uniform float ticks=1.;
float field(vec2 p){
 if(clear||p.x<0.||p.x>=320.||p.y<0.||p.y>=180.)return 0.;
 vec2 c=texture(history,(p+.5)/vec2(320.,180.)).rg;
 return (c.r*255.*256.+c.g*255.)*8./65535.;
}
float down(float v){float m=max(0.,v-.12);return min(m*.38,m*m*.075);}
float flux(float a,float b){float f=clamp((a-b)*.025,-.08,.08);return f>0.?min(f,max(0.,a-.12)*.12):-min(-f,max(0.,b-.12)*.12);}
void fragment(){
 vec2 p=floor(SCREEN_UV*vec2(320.,180.));
 float v=field(p),rate=1.-smoothstep(1.8,3.8,age);
 float change=down(field(p-vec2(0.,1.)))-down(v);
 if(p.x>0.)change+=flux(field(p-vec2(1.,0.)),v);
 if(p.x<319.)change-=flux(v,field(p+vec2(1.,0.)));
 v+=change*rate*ticks;
 for(int i=0;i<64;i++){
  if(i>=count)break;
  vec4 d=positions[i],s=shapes[i];vec2 delta=p-d.xy;
  float bound=max(d.z,d.w)*2.7;
  if(abs(delta.x)>bound||abs(delta.y)>bound)continue;
  vec2 uv=vec2(delta.x*cos(s.x)+delta.y*sin(s.x),-delta.x*sin(s.x)+delta.y*cos(s.x))/d.zw;
  float theta=atan(uv.y,uv.x);
  float contour=1.+s.w*(.22*sin(theta*s.z+s.y)+.085*sin(theta*(s.z+3.)-s.y));
  v+=amounts[i]*exp(-dot(uv,uv)/(contour*contour)*2.8);
 }
 float encoded=floor(clamp(v/8.,0.,1.)*65535.+.5);
 COLOR=vec4(floor(encoded/256.)/255.,mod(encoded,256.)/255.,0.,1.);
}
