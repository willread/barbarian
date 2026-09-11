/* Timed pickups, dropped equipment and fluid-flipbook death effects. */
(()=>{
 const M=window.AshenMechanics,clamp=(v,a=0,b=1)=>Math.max(a,Math.min(b,v));
 class FieldEvents{
  constructor(){this.reset()}
  reset(){this.time=0;this.chicken=null;this.schedule=[{wave:2,at:5},{wave:4,at:7},{wave:6,at:6},{wave:8,at:9}];this.used=new Set()}
  wave(){this.time=0}
  step(dt,wave,hero){
   this.time+=dt;const event=this.schedule.find(e=>e.wave===wave&&!this.used.has(wave)&&this.time>=e.at);
   if(event&&!this.chicken){this.used.add(wave);this.chicken={id:90000+wave,x:90,y:610,dir:1,hp:1,age:0,roast:false,turn:0,hop:0,height:0};}
   const c=this.chicken;if(!c)return;c.age+=dt;
   if(c.roast){if(hero.hp>0&&!hero.down&&!hero.air&&Math.abs(hero.x-c.x)<45&&Math.abs(hero.y-c.y)<26){hero.hp=hero.max;this.chicken=null;}return}
   if(c.age>10){c.x+=c.dir*350*dt;if(c.x< -80||c.x>1520)this.chicken=null;return}
   if((c.turn-=dt)<=0){c.turn=.65+Math.random()*.7;const away=c.x>hero.x?1:-1;c.dir=Math.abs(c.x-hero.x)<180?away:(Math.random()<.2?-c.dir:c.dir);c.targetY=575+Math.random()*150;if(Math.random()<.28)c.hop=.3;}
   if(c.x<90)c.dir=1;if(c.x>1350)c.dir=-1;
   c.x+=c.dir*235*dt;c.y+=clamp((c.targetY||630)-c.y,-60,60)*dt;
   c.hop=Math.max(0,c.hop-dt);c.height=Math.sin(c.hop/.3*Math.PI)*5;
   const a=hero.attack;if(a&&a.age>=a.from&&a.age<=a.to&&Math.abs(c.y-hero.y)<32){
    // Grounded food target: projected blade reach, including the tip's radius.
    const reach=(a.box?a.box[0]+a.box[1]:a.reach)*M.SCALE;
    if((c.x-hero.x)*a.direction>-15&&(c.x-hero.x)*a.direction<reach+26){c.roast=true;c.hp=0;c.age=0;c.height=0;}
   }
  }
  draw(ctx,atlas){const c=this.chicken;if(!c||!atlas)return;ctx.save();ctx.translate(c.x,c.y-c.height*M.SCALE);ctx.scale(c.dir,1);atlas.paint(ctx,c.roast?10:c.hop?9:Math.floor(c.age*16)%8,88,1);ctx.restore()}
 }
 class Aftermath{
  constructor(){this.layer=document.createElement('canvas');this.layer.width=this.layer.height=640;this.mask=document.createElement('canvas');this.mask.width=this.mask.height=128;this.reset()}
  reset(){this.items=[];this.embers=[];this.scorches=[];this.burns=new WeakMap()}
  death(f,gear){
   f.gearDropped=true;f.burnSeed=Math.random()*100;f.engulf= .8+Math.random()*.5;
   for(const g of gear){const d={...g,owner:f,dir:1,get death(){return f.death},get height(){return this.z/M.SCALE},engulf:f.engulf,burnSeed:f.burnSeed,x:f.x,y:f.y,z:90+f.height*M.SCALE,vx:(f.down?.vx||0)*180+(Math.random()-.5)*160,vy:(Math.random()-.5)*60,vz:110+Math.random()*100,angle:Math.random()*6,spin:(Math.random()-.5)*13,ground:false};this.items.push(d);if(!f.player)this.burns.set(d,{points:[],scorched:true});}
   if(!f.player)this.burns.set(f,{points:[],scorched:false});
  }
  step(dt,fighters){
   for(const d of this.items)if(!d.ground){d.x+=d.vx*dt;d.y+=d.vy*dt;d.z+=d.vz*dt;d.vz-=700*dt;d.angle+=d.spin*dt;if(d.z<=0){d.z=0;d.ground=true;d.y=clamp(d.y,555,752);d.x=clamp(d.x,30,1410)}}
   this.items=this.items.filter(d=>d.owner.player||d.death<.15+d.engulf+.6);
   for(const f of fighters){const burn=this.burns.get(f);if(!burn)continue;
    if(f.down?.ground&&!burn.scorched){burn.scorched=true;this.scorches.push({x:f.x,y:f.y,r:(f.boss?85:45)*(f.size||1),seed:f.burnSeed})}
    if(f.death<.15+f.engulf+.6 && Math.random()<dt*55){this.embers.push({x:f.x+(Math.random()-.5)*90,y:f.y-f.height*M.SCALE-35-Math.random()*110,vx:(f.down?.vx||0)*160+(Math.random()-.5)*80,vy:-35-Math.random()*100,life:.5+Math.random(),max:1.5});}
   }
   this.embers=this.embers.filter(e=>{e.life-=dt;e.x+=e.vx*dt;e.y+=e.vy*dt;e.vx*=Math.exp(-dt*3);e.vy-=dt*20;return e.life>0});
  }
  ground(ctx){
   for(const s of this.scorches){ctx.save();ctx.translate(s.x,s.y);ctx.scale(1,.32);const g=ctx.createRadialGradient(0,0,s.r*.2,0,0,s.r);g.addColorStop(0,'#120d0bef');g.addColorStop(.6,'#17110dcc');g.addColorStop(1,'#140e0900');ctx.fillStyle=g;ctx.fillRect(-s.r,-s.r,s.r*2,s.r*2);ctx.restore()}
   for(const d of this.items){ctx.save();ctx.translate(d.x,d.y-d.z);const w=d.h*d.image.width/d.image.height;this.body(ctx,d,g=>{g.save();g.rotate(d.angle);g.drawImage(d.image,-w/2,-d.h/2,w,d.h);g.restore()});ctx.restore()}
  }
  body(ctx,f,paint){
   const burn=this.burns.get(f);if(!burn){paint(ctx);return}
   const phase=clamp((f.death-.15-f.engulf)/.6);if(phase>=1)return;
   const g=this.layer.getContext('2d');g.clearRect(0,0,640,640);g.save();g.translate(320,400);g.filter=`brightness(${1-clamp((f.death-.4)/1.1)*.78})`;paint(g);g.restore();
   if(phase>0){const m=this.mask.getContext('2d'),pixels=m.createImageData?.(128,128);if(pixels?.data){
    const d=pixels.data;for(let y=0;y<128;y++)for(let x=0;x<128;x++){
      const n=.5+.17*Math.sin(x*.19+f.burnSeed)*Math.cos(y*.16)+.16*Math.sin(x*.49+y*.27)+.1*Math.cos(y*.81-x*.7+f.burnSeed);
      const k=(y*128+x)*4,edge=n-phase;d[k]=255;d[k+1]=edge<.035?100:255;d[k+2]=edge<.035?12:255;d[k+3]=edge>0?255:0;
    }m.putImageData(pixels,0,0);g.globalCompositeOperation='destination-in';g.drawImage(this.mask,0,0,640,640);g.globalCompositeOperation='source-over';
    // Hot irregular erosion front, restricted to surviving body pixels.
    for(let i=0;i<d.length;i+=4){if(d[i+1]===255)d[i+3]=0;}m.putImageData(pixels,0,0);g.globalCompositeOperation='source-atop';g.drawImage(this.mask,0,0,640,640);g.globalCompositeOperation='source-over';
   }}
   // Sample only opaque surviving pixels, so ignition follows the current pose
   // and the eroding silhouette instead of a guessed rectangle around it.
   const pixels=g.getImageData?.(0,0,640,640),solid=[];
   if(pixels?.data)for(let y=0;y<640;y+=4)for(let x=0;x<640;x+=4)if(pixels.data[(y*640+x)*4+3]>180)solid.push([x-320,y-400]);
   burn.points=Array.from({length:Math.min(4,solid.length)},(_,i)=>{const p=solid[Math.floor(solid.length*(i+.5)/4)];return {x:p[0],y:p[1],scale:f.owner?Math.min(.45,f.h/200):.55,offset:i*13+f.burnSeed}});
   ctx.drawImage(this.layer,-320,-400);
  }
  flames(ctx,f,fire,smoke){
   const b=this.burns.get(f);if(!b||!fire||f.death>3.3)return;
   for(const d of this.items)if(d.owner===f&&!f.player)this.flames(ctx,d,fire,smoke);
   const life=.15+f.engulf+.6,fade=1-clamp((f.death-life+.25)/.25),s=f.size||1;
   if(f.death<.15){ctx.save();ctx.translate(f.x,f.y);ctx.scale(1,.3);const g=ctx.createRadialGradient(0,0,0,0,0,170);g.addColorStop(0,`rgba(255,204,136,${.6*(1-f.death/.15)})`);g.addColorStop(1,'#ff880000');ctx.fillStyle=g;ctx.fillRect(-170,-170,340,340);ctx.restore()}
   for(const p of b.points){const frame=Math.floor((f.death*30+p.offset)%64),sx=frame%8*128,sy=Math.floor(frame/8)*192,w=155*p.scale*s,h=230*p.scale*s;
    ctx.save();ctx.globalAlpha=clamp(fade)*.9;ctx.globalCompositeOperation='screen';ctx.drawImage(fire,sx,sy,128,192,f.x+p.x*s*(f.dir||1)-w/2,f.y-f.height*M.SCALE+p.y*s-h*.95,w,h);ctx.restore();
    if(smoke&&f.death>.5){ctx.save();ctx.globalAlpha=.65*(1-clamp((f.death-2.3)));ctx.drawImage(smoke,sx,sy,128,192,f.x+p.x*s*(f.dir||1)-w/2,f.y-f.height*M.SCALE+p.y*s-h,w,h);ctx.restore()}
   }
  }
  sparks(ctx){for(const e of this.embers){ctx.globalAlpha=clamp(e.life/.4);ctx.fillStyle=e.life>.7?'#fff1bf':e.life>.3?'#ef7926':'#9d2815';ctx.fillRect(e.x,e.y,2,3)}ctx.globalAlpha=1}
 }
 window.AshenEvents={FieldEvents,Aftermath};
})();
