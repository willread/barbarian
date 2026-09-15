shader_type canvas_item;
uniform float clock=0.0;
uniform float area=1.0;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p){vec2 i=floor(p),f=fract(p);f=f*f*(3.0-2.0*f);return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);}
void fragment(){
 // Thin, broken soot veils hug the frame. They never form an opaque fog bank.
 vec2 p=UV*vec2(5.0,13.0)+vec2(-clock*(.055+area*.009),clock*.018);
 float n=noise(p)+noise(p*2.07+11.0)*.45;
 float low=smoothstep(.81,.96,UV.y);
 float sides=1.0-smoothstep(.02,.20,min(UV.x,1.0-UV.x));
 float ribbon=1.0-smoothstep(.035,.15,abs(UV.y-(.88+sin(UV.x*7.0-clock*.12+area)*.025)));
 float alpha=smoothstep(.58,1.2,n)*(low*.075+sides*.045+ribbon*.035);
 COLOR=vec4(mix(vec3(.27,.25,.23),vec3(.38,.30,.24),float(area>1.5)),alpha);
}
