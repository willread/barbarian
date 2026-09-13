shader_type canvas_item;
uniform bool golden=false;
void fragment(){
 vec2 p=(UV-.5)*2.0;
 float taper=.72+.12*p.y;
 vec2 q=vec2(p.x/taper,p.y/.86);
 float r=dot(q,q);
 float edge=1.0-smoothstep(.96,1.0,r);
 vec3 normal=normalize(vec3(q,sqrt(max(0.0,1.0-r))));
 float light=max(0.0,dot(normal,normalize(vec3(-.5,-.65,1.0))));
 float grain=fract(sin(dot(floor(UV*vec2(190,240)),vec2(12.9898,78.233)))*43758.5453)-.5;
 vec3 base=golden?vec3(.83,.48,.08):vec3(.83,.75,.59);
 vec3 shade=base*(.38+.68*light)+grain*.022;
 float shine=pow(max(0.0,dot(normal,normalize(vec3(-.35,-.45,1.0)))),golden?45.0:18.0);
 shade+=vec3(1.0,.94,.8)*shine*(golden?.65:.13);
 COLOR=vec4(shade,COLOR.a*edge);
}
