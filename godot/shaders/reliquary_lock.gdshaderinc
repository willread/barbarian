// Two independent locking collars index around the fixed central seal.
// Source coordinates are registered to the original 1672 x 941 painting.
float lock_step(float time,float period,float angle,float offset){
 float cycle=(time+offset)/period;
 return (floor(cycle)+smoothstep(.18,.72,fract(cycle)))*angle;
}
float lock_band(vec2 uv){
 float radius=length(uv*vec2(1672.0,941.0)-vec2(835.0,407.0));
 float inner=smoothstep(96.0,98.0,radius)*(1.0-smoothstep(130.0,132.0,radius));
 float outer=smoothstep(144.0,146.0,radius)*(1.0-smoothstep(162.0,164.0,radius));
 return max(inner,outer);
}
vec2 lock_uv(vec2 uv,float time){
 vec2 center=vec2(835.0,407.0);
 vec2 p=uv*vec2(1672.0,941.0)-center;
 float angle=length(p)<138.0?lock_step(time,18.0,-.523598776,3.0):lock_step(time,14.0,.392699082,0.0);
 float c=cos(angle),s=sin(angle);
 return (center+vec2(c*p.x-s*p.y,s*p.x+c*p.y))/vec2(1672.0,941.0);
}
