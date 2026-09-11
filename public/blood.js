/* Persistent floor pigment, ballistic spray and transferable boot stains. */
(() => {
  class Blood {
    constructor(width, height) {
      this.width=width; this.height=height;
      this.floor=document.createElement('canvas'); this.floor.width=width; this.floor.height=height;
      this.ctx=this.floor.getContext('2d'); this.reset();
    }
    reset() {
      this.ctx.clearRect(0,0,this.width,this.height);
      this.drops=[]; this.emitters=new WeakMap(); this.wet=new Float32Array(Math.ceil(this.width/16)*Math.ceil(this.height/16));
      this.stride=Math.ceil(this.width/16); this.boots=new WeakMap(); this.marks=0; this.tracks=0;
    }
    cell(x,y) {return Math.floor(y/16)*this.stride+Math.floor(x/16)}
    stain(x,y,r,amount=1,track=false,angle=0) {
      if(x<0||x>=this.width||y<535||y>=this.height)return;
      const c=this.ctx; c.save(); c.translate(x,y); c.rotate(angle); c.scale(1,track?.65:.34);
      c.globalAlpha=Math.min(.86,amount*.8); c.fillStyle='#48070b';
      c.beginPath();
      const points=14;
      for(let i=0;i<=points;i++) {const a=i/points*Math.PI*2, rr=r*(.72+Math.random()*.4);const px=Math.cos(a)*rr,py=Math.sin(a)*rr;if(!i)c.moveTo(px,py);else c.lineTo(px,py)}
      c.closePath();c.fill();
      c.globalAlpha*=.65;c.fillStyle='#730c12';c.beginPath();c.ellipse(-r*.08,-r*.04,r*.63,r*.54,0,0,Math.PI*2);c.fill();
      c.globalAlpha*=.3;c.fillStyle='#bb5d53';c.beginPath();c.ellipse(-r*.18,-r*.24,r*.28,r*.055,-.2,0,Math.PI*2);c.fill();c.restore();
      if(!track) for(let yy=Math.floor((y-r*.34)/16);yy<=Math.floor((y+r*.34)/16);yy++)for(let xx=Math.floor((x-r)/16);xx<=Math.floor((x+r)/16);xx++){
        const k=yy*this.stride+xx;if(xx>=0&&xx<this.stride&&k>=0&&k<this.wet.length)this.wet[k]=1;
      }
      this.marks++;if(track)this.tracks++;
    }
    hit(f,direction,fatal=false) {
      const count=(fatal?36:18)+Math.floor(Math.random()*(fatal?17:11));
      // Knockback uses the newly applied launch; ordinary hits use prior motion.
      const units=window.AshenMechanics.SCALE/window.AshenMechanics.STEP;
      const horizontal=f.down?(f.down.ground?0:f.down.vx):(f.velocityX||0);
      const vertical=f.down?(f.down.ground?0:f.down.vz):(f.air?.vz??f.attack?.vz??0);
      const launched=!!f.down&&!f.down.ground;
      if(launched)this.emitters.set(f.down,{wait:0});
      const carryX=horizontal*units*(launched?1:.6),carryY=(f.velocityY||0)*units*.6,carryZ=-vertical*units*(launched?1:.45);
      const force=(launched?25:80)+Math.random()*(launched?65:120),fan=.45+Math.random()*.55,lift=(launched?10:35)+Math.random()*(launched?35:90);
      const sourceHeight=85+Math.random()*50+(f.height||0)*window.AshenMechanics.SCALE;
      this.stain(f.x,f.y,launched?7:fatal?42:19);
      for(let i=0;i<count;i++) {
        const angle=(Math.random()-.5)*fan,speed=force*(.5+Math.random()*.8);
        this.drops.push({x:f.x+(Math.random()-.5)*18,y:f.y+(Math.random()-.5)*12,z:sourceHeight+(Math.random()-.5)*24,
          vx:carryX+direction*Math.cos(angle)*speed,vy:carryY+Math.sin(angle)*speed*.6,vz:carryZ+lift+(Math.random()-.5)*280,
          gravity:launched?.25*units/window.AshenMechanics.STEP:850,drag:launched?0:.8,
          r:(fatal?5:3.5)+Math.random()*(fatal?5:4)});
      }
      if(this.drops.length>700)this.drops.splice(0,this.drops.length-700);
    }
    step(dt,fighters) {
      this.drops=this.drops.filter(d=>{
        d.x+=d.vx*dt;d.y+=d.vy*dt;d.z+=d.vz*dt;d.vz-=d.gravity*dt;d.vx*=Math.exp(-dt*d.drag);
        if(d.z<=0){this.stain(d.x,Math.max(540,Math.min(790,d.y)),d.r*2.3);return false}return true;
      });
      for(let i=0;i<this.wet.length;i++)this.wet[i]=Math.max(0,this.wet[i]-dt/65);
      for(const f of fighters){
        const emitter=f.down&&this.emitters.get(f.down);
        if(emitter&&!f.down.ground){
          emitter.wait-=dt;
          if(emitter.wait<=0){
            emitter.wait=.02+Math.random()*.025;
            const units=window.AshenMechanics.SCALE/window.AshenMechanics.STEP;
            // Fresh droplets detach at the body's CURRENT position throughout
            // ascent and descent. They lose momentum and hang behind the body.
            for(let i=0;i<2;i++)this.drops.push({
              x:f.x+(Math.random()-.5)*18,y:f.y+(Math.random()-.5)*10,
              z:60+(f.height||0)*window.AshenMechanics.SCALE+Math.random()*25,
              vx:f.down.vx*units*(.12+Math.random()*.18),vy:(Math.random()-.5)*35,
              vz:-f.down.vz*units*.12+(Math.random()-.5)*60,
              gravity:850,drag:1.6,r:3+Math.random()*4,trail:true,
            });
          }
        }else if(emitter)this.emitters.delete(f.down);
        let b=this.boots.get(f);if(!b){b={x:f.x,y:f.y,distance:0,coat:0,side:1};this.boots.set(f,b)}
        const dx=f.x-b.x,dy=f.y-b.y,travel=Math.hypot(dx,dy);b.x=f.x;b.y=f.y;
        if(f.air||f.height>3){b.distance=0;continue}
        const wet=this.wet[this.cell(f.x,f.y)]||0;b.coat=Math.max(b.coat,wet);b.distance+=Math.min(travel,40);
        if(b.distance>=20&&b.coat>.05){
          b.distance=0;b.side*=-1;
          const angle=Math.atan2(dy,dx||1);
          const x=f.x-Math.sin(angle)*b.side*9,y=f.y+Math.cos(angle)*b.side*5;
          this.stain(x,y,f.down?15:7,b.coat,true,angle);
          if(!f.down)this.stain(x-Math.cos(angle)*7,y-Math.sin(angle)*7,4,b.coat*.7,true,angle);
          b.coat*=.82;
        }
      }
      if(this.drops.length>700)this.drops.splice(0,this.drops.length-700);
    }
    drawGround(ctx){ctx.save();ctx.globalCompositeOperation='multiply';ctx.drawImage(this.floor,0,0);ctx.restore()}
    drawAir(ctx){
      ctx.save();ctx.lineCap='round';
      for(const d of this.drops){ctx.strokeStyle='#43060a';ctx.lineWidth=d.r;ctx.beginPath();ctx.moveTo(d.x,d.y-d.z);ctx.lineTo(d.x-d.vx*.014,d.y-d.z+d.vz*.014);ctx.stroke()}
      ctx.restore();
    }
  }
  window.AshenBlood=Blood;
})();
