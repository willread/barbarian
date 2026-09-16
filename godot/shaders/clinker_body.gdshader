shader_type canvas_item;
render_mode unshaded;
uniform float age;
uniform float urgency;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p){vec2 i=floor(p),f=fract(p);f=f*f*(3.-2.*f);return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+1.),f.x),f.y);}
void fragment(){
 vec4 rock=texture(TEXTURE,UV);
 // Animate exposed molten cracks while the forged cage stays rigid.
 float ember=smoothstep(.12,.48,rock.r-rock.b)*smoothstep(.22,.65,rock.r);
 float flow=noise(UV*vec2(19.,27.)+vec2(age*.7,-age*3.8));
 float pulse=.5+.5*sin(age*(15.+urgency*20.));
 float heat=.7+flow*.6+urgency*.6+pow(urgency,3.)*pulse*.8;
 rock.rgb*=1.+ember*(heat-1.);
 rock.rgb+=vec3(.28,.12,.018)*ember*(flow*.5+urgency*pulse);
 COLOR=rock;
}
