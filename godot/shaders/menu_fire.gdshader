shader_type canvas_item;
uniform float clock=0.;
uniform vec2 pixels=vec2(200.,160.);
uniform float edge_spread=2.6;
void fragment(){
 // Expand the fuel around each glyph, not the word's rectangular bounds.
 // Horizontal expansion leaves the deliberately short upward reach intact.
 vec2 rim=vec2(edge_spread/pixels.x,0.);
 float heat=max(texture(TEXTURE,UV).a,max(texture(TEXTURE,UV-rim).a,texture(TEXTURE,UV+rim).a)*.86)*.9;
 for(int i=1;i<14;i++){
  float y=float(i)*.55;
  float curl=.16*sin(UV.x*pixels.x*.71+UV.y*pixels.y*.33+clock*7.1)+.12*sin(UV.x*pixels.x*.37-UV.y*pixels.y*.19-clock*9.3);
  vec2 at=UV+vec2(curl*float(i)*.22,y)/pixels;
  vec2 spread=rim*(.88+.12*sin(UV.y*pixels.y*.19+clock*2.1));
  float fuel=max(texture(TEXTURE,at).a,max(texture(TEXTURE,at-spread).a,texture(TEXTURE,at+spread).a)*.86);
  float cooling=.065+.025*(.5+.5*sin(UV.x*pixels.x*.57+UV.y*pixels.y*.13-clock*6.));
  heat=max(heat,fuel*(.88+.1*sin(UV.x*pixels.x*.11+clock*3.))*pow(.96,float(i))-float(i)*cooling);
 }
 vec3 fire=vec3(min(1.,heat*850./255.),clamp((heat-.2)*430./255.,0.,1.),max(0.,(heat-.68)*650./255.));
 COLOR=vec4(fire*1.15,clamp((heat-.07)*450./255.,0.,.902));
}
