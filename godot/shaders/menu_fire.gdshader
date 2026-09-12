shader_type canvas_item;
uniform float clock=0.;
uniform vec2 pixels=vec2(200.,160.);
void fragment(){
 float heat=texture(TEXTURE,UV).a*.9;
 for(int i=1;i<14;i++){
  float y=float(i)*.55;
  float curl=.16*sin(UV.x*pixels.x*.71+UV.y*pixels.y*.33+clock*7.1)+.12*sin(UV.x*pixels.x*.37-UV.y*pixels.y*.19-clock*9.3);
  float fuel=texture(TEXTURE,UV+vec2(curl*float(i)*.22,y)/pixels).a;
  float cooling=.065+.025*(.5+.5*sin(UV.x*pixels.x*.57+UV.y*pixels.y*.13-clock*6.));
  heat=max(heat,fuel*(.88+.1*sin(UV.x*pixels.x*.11+clock*3.))*pow(.96,float(i))-float(i)*cooling);
 }
 vec3 fire=vec3(min(1.,heat*850./255.),clamp((heat-.2)*430./255.,0.,1.),max(0.,(heat-.68)*650./255.));
 COLOR=vec4(fire*1.15,clamp((heat-.07)*450./255.,0.,.902));
}
