/* Animate the painting's own surfaces through fixed masks; rigid scenery never warps. */
(()=>{
 const TAU=Math.PI*2,clamp=v=>Math.max(0,Math.min(1,v));
 const canvas=(w,h)=>{const c=document.createElement('canvas');c.width=w;c.height=h;return c;};
 const configs={valley:{name:'The Valley'},swamp:{name:'Drowned Forest'},cinder:{name:'Cinder Wastes'}};
 class Environment{
 constructor(image,key,w,h,smoke,fire,farImage){this.key=key;this.config=configs[key];this.width=w;this.height=h;this.base=canvas(w,h);this.base.getContext('2d').drawImage(farImage||image,0,0,w,h);this.source=canvas(w,h);this.source.getContext('2d').drawImage(image,0,0,w,h);this.layers=[];this.splashes=[];
 const patch=(points,dx,dy,period,options={})=>this.add(points,dx,dy,period,options);
 const rect=(x,y,rw,rh)=>[[x,y],[x+rw,y],[x+rw,y+rh],[x,y+rh]];
 const fall=(x,top,bottom,r)=>{patch([[x-r*.5,top],[x+r*.5,top],[x+r*.62,bottom],[x-r*.62,bottom]],0,60,1.5,{blur:1});this.splashes.push([x,bottom,r]);};
 if(key==='swamp'){
  patch(rect(0,.537,1,.079),24,0,6,{blur:3,water:true});fall(.741,.323,.487,.035);
  patch([[.405,.395],[.5,.41],[.59,.465],[.69,.476],[.69,.51],[.42,.51]],27,-3,12,{blur:15,smoke:true});
 }else if(key==='valley'){
  [[.299,.39,.51,.017],[.509,.46,.533,.012],[.535,.46,.533,.013],[.258,.544,.599,.014],[.338,.544,.601,.014]].forEach(f=>fall(...f));
  patch([[.493,.556],[.565,.549],[.643,.567],[.638,.595],[.449,.599],[.441,.586]],22,0,6,{blur:3,water:true});
  patch([[.32,.489],[.37,.485],[.405,.515],[.45,.519],[.469,.556],[.456,.574],[.4,.553],[.375,.541],[.343,.546]],25,-4,12,{blur:12,smoke:true});
  patch([[.477,.515],[.513,.524],[.556,.525],[.589,.508],[.623,.515],[.637,.532],[.619,.551],[.569,.551],[.526,.548],[.486,.55]],20,-3,12,{blur:10,smoke:true});
 }else{
  // Actual near structure is cut from the new painting over the earlier far plate.
  this.near=canvas(w,h);const n=this.near.getContext('2d');n.drawImage(this.source,0,0);n.globalCompositeOperation='destination-in';const mask=canvas(w,h),m=mask.getContext('2d');m.filter='blur(1px)';m.fillStyle='#fff';m.beginPath();[[.195,.594],[.222,.437],[.225,.3],[.248,.167],[.312,.138],[.335,.195],[.371,.215],[.385,.242],[.476,.244],[.498,.196],[.537,.211],[.557,.251],[.562,.361],[.591,.479],[.62,.527],[.645,.599],[.638,.655],[.255,.659]].forEach(([x,y],i)=>i?m.lineTo(x*w,y*h):m.moveTo(x*w,y*h));m.closePath();m.fill();n.drawImage(mask,0,0);n.globalCompositeOperation='source-over';
  patch(rect(0,.572,1,.112),-35,0,6,{hot:true,blur:1,far:true});
  [[.104,.418,.507,.013],[.137,.532,.623,.014],[.194,.487,.548,.011]].forEach(([x,a,b,r])=>patch(rect(x-r/2,a,r,b-a),0,48,2,{hot:true,far:true}));
  patch([[.02,.105],[.097,.114],[.13,.237],[.107,.399],[.071,.383],[.024,.265]],-12,-68,6,{smoke:true,blur:10,far:true});
  patch([[.146,.333],[.176,.326],[.205,.426],[.187,.469],[.17,.46]],-7,-40,6,{smoke:true,blur:7,far:true});
  patch([[.30,0],[.51,0],[.555,.08],[.54,.28],[.48,.34],[.35,.28],[.30,.16]],-20,-90,6,{smoke:true,blur:18,near:true});
  patch([[.337,.247],[.408,.265],[.471,.279],[.49,.3],[.442,.31],[.381,.286]],18,0,3,{hot:true,blur:2,near:true});
  patch(rect(.456,.315,.026,.072),0,38,1.5,{hot:true,near:true});
  patch(rect(.462,.51,.028,.085),0,50,1.5,{hot:true,near:true});

 }
 }
 add(points,dx,dy,period,options){const w=this.width,h=this.height,pad=110;
 const minX=Math.max(0,Math.floor(Math.min(...points.map(p=>p[0]))*w)-pad),minY=Math.max(0,Math.floor(Math.min(...points.map(p=>p[1]))*h)-pad),maxX=Math.min(w,Math.ceil(Math.max(...points.map(p=>p[0]))*w)+pad),maxY=Math.min(h,Math.ceil(Math.max(...points.map(p=>p[1]))*h)+pad),rw=maxX-minX,rh=maxY-minY;
 const texture=canvas(rw,rh),mask=canvas(rw,rh),out=canvas(rw,rh);texture.getContext('2d').drawImage(options.far?this.base:this.source,minX,minY,rw,rh,0,0,rw,rh);const m=mask.getContext('2d');m.fillStyle='#fff';m.filter=`blur(${options.blur||2}px)`;m.beginPath();points.forEach(([x,y],i)=>i?m.lineTo(x*w-minX,y*h-minY):m.moveTo(x*w-minX,y*h-minY));m.closePath();m.fill();m.filter='none';
 if(options.hot){const pixels=texture.getContext('2d').getImageData(0,0,rw,rh),alpha=m.getImageData(0,0,rw,rh);for(let i=0;i<pixels.data.length;i+=4){const d=pixels.data;alpha.data[i+3]*=clamp((d[i]-d[i+2]-48)/85)*clamp((d[i]-100)/110);}m.putImageData(alpha,0,0);}
 if(options.smoke){
  const g=texture.getContext('2d');g.globalCompositeOperation='destination-in';g.drawImage(mask,0,0);g.globalCompositeOperation='destination-out';
  if(options.near&&this.near)g.drawImage(this.near,minX,minY,rw,rh,0,0,rw,rh);
  g.globalCompositeOperation='source-over';
 }
 this.layers.push({texture,mask,out,x:minX,y:minY,w:rw,h:rh,dx,dy,period,...options});
 }
 drawLayer(ctx,l,time){const g=l.out.getContext('2d');g.clearRect(0,0,l.w,l.h);g.globalCompositeOperation='lighter';
 // Complementary weights sum to one: the moving material replaces the static
 // painting inside its mask, rather than appearing as a faint extra overlay.
 for(let i=0;i<2;i++){const p=(time/l.period+i*.5)%1,weight=Math.sin(p*Math.PI)**2;g.globalAlpha=weight;const grow=l.smoke?1+(p-.5)*.07:1;const ox=(p-.5)*l.dx-(grow-1)*l.w/2,oy=(l.smoke?p:p-.5)*l.dy-(grow-1)*l.h;g.drawImage(l.texture,0,0,l.w,1,ox,oy-110,l.w*grow,110);g.drawImage(l.texture,ox,oy,l.w*grow,l.h*grow);}
 g.globalAlpha=1;g.globalCompositeOperation='destination-in';g.drawImage(l.mask,0,0);g.globalCompositeOperation='source-over';ctx.drawImage(l.out,l.x,l.y);
 }
 draw(ctx,time,reduced=false,camera=0){const w=this.width,h=this.height,t=((time%24)+24)%24;ctx.save();ctx.drawImage(this.base,0,0);
 if(!reduced)for(const l of this.layers)if(!l.near)this.drawLayer(ctx,l,t);
 if(this.near){ctx.save();if(!reduced)for(const l of this.layers)if(l.near&&l.smoke)this.drawLayer(ctx,l,t);ctx.drawImage(this.near,0,0);if(!reduced)for(const l of this.layers)if(l.near&&!l.smoke)this.drawLayer(ctx,l,t);ctx.restore();}
 if(!reduced){
 for(const [x,y,r]of this.splashes){for(let i=0;i<44;i++){const a=(t/.75+i/44)%1,side=Math.sin(i*21.73),px=x*w+side*r*w*a,py=y*h-r*w*.8*a+r*w*a*a;ctx.globalAlpha=Math.sin(a*Math.PI)**2*.45;ctx.fillStyle='#d5e0dd';ctx.beginPath();ctx.ellipse(px,py,.65,1,0,0,TAU);ctx.fill();}for(let i=0;i<4;i++){const a=(t/1.5+i/4)%1;ctx.globalAlpha=(1-a)*.16;ctx.strokeStyle='#c6d6d2';ctx.lineWidth=.7;ctx.beginPath();ctx.ellipse(x*w,y*h+2,r*w*(.3+a),1+a*3,0,0,TAU);ctx.stroke();}}ctx.globalAlpha=1;
 // Restricted optical shimmer over hot air, not a wobble applied to the art.
 if(this.key==='cinder'){this.heat??=canvas(w,h);const q=this.heat.getContext('2d');q.clearRect(0,0,w,h);q.drawImage(ctx.canvas,0,0,w,h);ctx.globalAlpha=.3;for(let y=Math.floor(h*.33);y<h*.66;y+=3){const a=.8*Math.sin((y/h-.33)/.33*Math.PI);ctx.drawImage(this.heat,0,y,w,3,Math.sin(y*.051-t*TAU/2)*a,y,w,3);}ctx.globalAlpha=1;}
 }ctx.restore();}
 dispose(){}
 }
 window.AshenEnvironments={Environment,configs};
})();
