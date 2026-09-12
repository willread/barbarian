shader_type canvas_item;
uniform float age=0.0;
uniform float seed=0.0;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p){vec2 i=floor(p),f=fract(p);f=f*f*(3.0-2.0*f);return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);}
void fragment(){
 vec4 base=texture(TEXTURE,UV)*COLOR;
 vec2 p=UV*5.0+vec2(seed,-age*.7);
 float n=noise(p)*.6+noise(p*2.1+age*.15)*.28+noise(p*4.2)*.12;
 float density=smoothstep(.22,.72,n);
 // Soft translucent edges, irregular internal density and subdued upper lighting.
 base.a*=density;
 base.rgb*=.77+.34*n+.12*(1.0-UV.y);
 COLOR=base;
}
