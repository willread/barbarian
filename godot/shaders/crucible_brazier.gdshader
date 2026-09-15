shader_type canvas_item;
uniform float clock=0.0;
float hash(float n){return fract(sin(n*127.1)*43758.5453);}
float flicker(float t){float i=floor(t),f=fract(t);return mix(hash(i),hash(i+1.0),f*f*(3.0-2.0*f));}
void fragment(){
 vec4 paint=texture(TEXTURE,UV);
 float hot=smoothstep(.15,.5,paint.r-paint.b)*smoothstep(.25,.75,paint.r);
 float burn=flicker(clock*3.7)*.65+flicker(clock*8.1+47.0)*.35;
 paint.rgb*=1.0+hot*(burn-.5)*.85;
 paint.rgb+=vec3(.07,.025,.002)*hot*burn;
 COLOR=paint;
}
