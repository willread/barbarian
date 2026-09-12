export async function createBakedLoops(image,regions,width,height,base){
 const canvas=document.createElement('canvas');canvas.width=width;canvas.height=height;const g=canvas.getContext('2d');
 const atlases=await Promise.all(regions.map(r=>new Promise((resolve,reject)=>{const im=new Image();im.onload=()=>resolve(im);im.onerror=reject;im.src=base+r.animation.atlas})));
 const layer=document.createElement('canvas');layer.width=width;layer.height=height;const l=layer.getContext('2d');
 function path(ctx,polygon){ctx.beginPath();polygon.forEach(([x,y],i)=>i?ctx.lineTo(x*width,y*height):ctx.moveTo(x*width,y*height));ctx.closePath()}
 return {updateRegions(next){regions=next},render(time,water=true,bounds=false,fire=true,blend=true){
  g.clearRect(0,0,width,height);g.drawImage(image,0,0,width,height);
  regions.forEach((r,i)=>{if(!(i===0?water:fire))return;const a=r.animation,[x,y,w,h]=a.rect,t=((time*a.fps)%a.count+a.count)%a.count,f=Math.floor(t),fraction=blend?t-f:0;
   l.clearRect(0,0,width,height);l.globalCompositeOperation='lighter';
   const draw=(n,opacity)=>{l.globalAlpha=opacity;l.drawImage(atlases[i],n%a.columns*w,Math.floor(n/a.columns)*h,w,h,x,y,w,h)};
   draw(f,1-fraction);if(fraction)draw((f+1)%a.count,fraction);l.globalAlpha=1;l.globalCompositeOperation='source-over';
   g.save();path(g,r.polygon);g.clip();g.drawImage(layer,0,0);if(bounds){g.fillStyle=i?'#ffa33340':'#22ffc040';g.fill()}g.restore();
  });return canvas;
 },checkLoop(){this.render(0);const a=g.getImageData(0,0,width,height).data;this.render(2);const b=g.getImageData(0,0,width,height).data;let max=0;for(let i=0;i<a.length;i++)max=Math.max(max,Math.abs(a[i]-b[i]));return max}}
}
