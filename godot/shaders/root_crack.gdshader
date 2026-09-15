shader_type canvas_item;
render_mode unshaded, blend_mul;
uniform float progress=0.0;
uniform float opacity=1.0;
void fragment(){
 vec4 crack=texture(TEXTURE,UV);
 // Multiply only the narrow fissure, retaining the floor's own color and texture.
 float spread=abs(UV.x-.5)*1.3+abs(UV.y-.5)*.25;
 float reveal=smoothstep(spread-.16,spread+.10,progress);
 float strength=(.4+.6*progress)*reveal*opacity*crack.a;
 COLOR=vec4(mix(vec3(1.0),crack.rgb*.52,strength),1.0);
}
