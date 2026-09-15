uniform sampler2D road_clear: filter_linear, repeat_disable;
uniform sampler2D road_original: filter_linear, repeat_disable;
uniform vec2 cart_positions=vec2(720.0,1180.0);
float track_y(float x){
 // Surveyed wheel-contact points on the actual painted rail, in source pixels.
 if(x<170.0)return mix(407.0,435.0,x/170.0);
 if(x<530.0)return mix(435.0,481.0,(x-170.0)/360.0);
 if(x<720.0)return mix(481.0,500.0,(x-530.0)/190.0);
 if(x<1180.0)return mix(500.0,565.0,(x-720.0)/460.0);
 return mix(565.0,610.0,(x-1180.0)/320.0);
}
float cart_mask(vec2 local,float half_width){
 float down=local.y-local.x*.145+32.0;
 float body=(1.0-smoothstep(half_width-3.0-down*.13,half_width-2.0-down*.13,abs(local.x)))*smoothstep(-1.0,0.0,down)*(1.0-smoothstep(25.0,27.0,down));
 float lip=(1.0-smoothstep(half_width-1.0,half_width,abs(local.x)))*smoothstep(-3.0,-2.0,down)*(1.0-smoothstep(1.5,2.5,down));
 float wheels=max(1.0-smoothstep(4.0,5.4,length(local-vec2(-half_width*.60,-4.0))),1.0-smoothstep(4.0,5.4,length(local-vec2(half_width*.60,2.5))));
 return max(body,max(lip,wheels));
}
float track_box(vec2 p,vec4 b){return step(b.x,p.x)*step(p.x,b.z)*step(b.y,p.y)*step(p.y,b.w);}
float track_beam(vec2 p,vec2 a,vec2 b){
 vec2 delta=b-a;
 float t=clamp(dot(p-a,delta)/dot(delta,delta),0.0,1.0);
 return 1.0-smoothstep(2.0,4.0,length(p-a-delta*t));
}
vec4 road_scene(vec2 uv){
 vec2 p=uv*vec2(1672.0,941.0);
 vec4 original=texture(road_original,uv);
 vec4 clean=texture(road_clear,uv);
 // One continuous track region; the original painting remains outside it.
 float region=smoothstep(340.0,365.0,p.y)*(1.0-smoothstep(635.0,655.0,p.y));
 vec4 scene=mix(original,clean,region);
 float supports=track_box(p,vec4(125,354,210,565));
 supports=max(supports,track_box(p,vec4(505,433,560,600)));
 supports=max(supports,track_box(p,vec4(839,452,907,650)));
 supports=max(supports,track_box(p,vec4(1353,408,1407,657)));
 supports=max(supports,track_box(p,vec4(60,257,119,527)));
 // Use painted structure coverage within the support regions, preserving open gaps.
 float iron=1.0-smoothstep(.24,.43,max(clean.r,max(clean.g,clean.b)));
 float occlusion=supports*iron;
 // Sloping gantry braces also cross in front of passing cart bodies.
 occlusion=max(occlusion,track_beam(p,vec2(897.0,483.0),vec2(1100.0,554.0))*iron);
 // Front guard rails occlude the wheels and lower bodies, rather than floating below them.
 float rail_band=smoothstep(track_y(p.x)-11.0,track_y(p.x)-8.0,p.y);
 occlusion=max(occlusion,rail_band*iron);
 occlusion=max(occlusion,smoothstep(1382.0,1425.0,p.x));
 for(int i=0;i<2;i++){
  vec2 anchor=i==0?vec2(720.0,500.0):vec2(1180.0,565.0);
  float x=cart_positions[i];
  vec2 local=p-vec2(x,track_y(x));
  if(abs(local.x)<49.0 && local.y>-44.0 && local.y<12.0){
   float mask=cart_mask(local,i==0?41.0:47.0)*(1.0-occlusion);
   vec4 cart=texture(road_original,(anchor+local)/vec2(1672.0,941.0));
   scene=mix(scene,cart,mask);
  }
 }
 return scene;
}
