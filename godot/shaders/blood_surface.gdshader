shader_type canvas_item;
float decode(vec4 c){return (c.r*255.*256.+c.g*255.)*8./65535.;}
float amount(sampler2D field,vec2 uv){return decode(texture(field,uv));}
void fragment(){
 vec2 px=vec2(1./320.,1./180.);
 float v=amount(TEXTURE,UV);
 float nx=(amount(TEXTURE,UV-vec2(px.x,0.))-amount(TEXTURE,UV+vec2(px.x,0.)))*2.2;
 float ny=(amount(TEXTURE,UV-vec2(0.,px.y))-amount(TEXTURE,UV+vec2(0.,px.y)))*2.2;
 float inv=inversesqrt(1.+nx*nx+ny*ny);
 float diffuse=max(0.,(-nx*.4-ny*.5+.7)*inv);
 float highlight=pow(max(0.,(-nx*.28-ny*.38+.881)*inv),65.);
 COLOR=vec4(vec3(48.+54./(1.+v*.6)+diffuse*21.+highlight*175.,2.+diffuse*5.+highlight*139.,7.+diffuse*8.+highlight*132.)/255.,clamp((v-.035)*18.,0.,1.));
}
