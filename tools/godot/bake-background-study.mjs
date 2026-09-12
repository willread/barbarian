import fs from 'node:fs';
import path from 'node:path';
import {createCanvas,loadImage} from '@napi-rs/canvas';
const dir='studies/backgrounds/citadel-01-v5';
let m=JSON.parse(fs.readFileSync(process.argv[2]||'studies/backgrounds/citadel-01-v5/approved-masks.json','utf8'));
const waterfallOnly=process.argv.includes('--waterfall');
if(waterfallOnly){const current=JSON.parse(fs.readFileSync(path.join(dir,'screen.json'),'utf8'));current.regions[0].polygon=m.regions[0].polygon;m=current;}
m.id='citadel-01-v5';m.status='Approved masks / baked flow loops awaiting animation review';
m.notes='60 baked frames over two seconds. Original painting stays fixed. Optional interpolation blends adjacent frames; the underlying motion is texture advection, not newly hand-drawn frames.';
m.frames=['../citadel-01-v3/base.png'];
const [w,h]=m.size,base=createCanvas(w,h),ctx=base.getContext('2d');
ctx.drawImage(await loadImage('studies/backgrounds/citadel-01-v3/base.png'),0,0,w,h);
const pixels=ctx.getImageData(0,0,w,h).data;
function mask(poly){const c=createCanvas(w,h),g=c.getContext('2d');g.fillStyle='white';g.beginPath();poly.forEach(([x,y],i)=>i?g.lineTo(x*w,y*h):g.moveTo(x*w,y*h));g.closePath();g.fill();return g.getImageData(0,0,w,h).data}
const masks=m.regions.map(r=>mask(r.polygon)),flame=mask(m.regions[1].motion_polygon);
const smooth=(a,b,x)=>{const t=Math.max(0,Math.min(1,(x-a)/(b-a)));return t*t*(3-2*t)};
const mix=(a,b,t)=>a+(b-a)*t;
function sample(x,y,k){x=Math.max(0,Math.min(w-1,x));y=Math.max(0,Math.min(h-1,y));const ix=Math.floor(x),iy=Math.floor(y),jx=Math.min(w-1,ix+1),jy=Math.min(h-1,iy+1);return mix(mix(pixels[(iy*w+ix)*4+k],pixels[(iy*w+jx)*4+k],x-ix),mix(pixels[(jy*w+ix)*4+k],pixels[(jy*w+jx)*4+k],x-ix),y-iy)}
function coverage(data,x,y){if(x<0||x>=w||y<0||y>=h)return 0;return data[(Math.floor(y)*w+Math.floor(x))*4+3]/255}
for(let r=0;r<m.regions.length;r++){
 if(waterfallOnly&&r!==0)continue;
 const poly=m.regions[r].polygon,x=Math.floor(Math.min(...poly.map(p=>p[0]))*w)-2,y=Math.floor(Math.min(...poly.map(p=>p[1]))*h)-2,cw=Math.ceil(Math.max(...poly.map(p=>p[0]))*w)-x+2,ch=Math.ceil(Math.max(...poly.map(p=>p[1]))*h)-y+2;
 const atlas=createCanvas(cw*8,ch*8),ag=atlas.getContext('2d'),frame=createCanvas(cw,ch),fg=frame.getContext('2d');
 for(let f=0;f<60;f++){
  const out=fg.createImageData(cw,ch),t=f/30,a=f/60,b=(a+.5)%1,wa=1-Math.abs(a*2-1),wb=1-wa;
  for(let py=0;py<ch;py++)for(let px=0;px<cw;px++){
   const xx=x+px,yy=y+py,idx=(py*cw+px)*4,alpha=coverage(masks[r],xx,yy);if(!alpha)continue;
   let dx,dy,amount=1;
   if(r===0){const splash=smooth(.52,.58,yy/h);dx=mix(.003,(xx/w-.16)*.7,splash)*w;dy=mix(.06,.008,splash)*h;amount=.88}
   else {dx=.002*Math.sin(yy/h*170+t*Math.PI*2)*w;dy=-.032*h;amount=coverage(flame,xx,yy)}
   const ax=xx-dx*(a-.5),ay=yy-dy*(a-.5),bx=xx-dx*(b-.5),by=yy-dy*(b-.5),ma=coverage(r===0?masks[0]:flame,ax,ay),mb=coverage(r===0?masks[0]:flame,bx,by);
   const warm=smooth(.035,.20,(sample(xx,yy,0)-sample(xx,yy,2))/255),pulse=r?1+warm*(.09*Math.sin(t*Math.PI*2)+.045*Math.sin(t*Math.PI*5+xx/w*9)):1;
   for(let k=0;k<3;k++){const original=sample(xx,yy,k);out.data[idx+k]=mix(original,mix(original,sample(ax,ay,k),ma)*wa+mix(original,sample(bx,by,k),mb)*wb,amount)*pulse}out.data[idx+3]=Math.round(alpha*255);
  }
  fg.putImageData(out,0,0);ag.drawImage(frame,(f%8)*cw,Math.floor(f/8)*ch);
 }
 const filename=r?'fire.png':'waterfall.png';fs.writeFileSync(path.join(dir,filename),atlas.toBuffer('image/png'));m.regions[r].animation={atlas:filename,rect:[x,y,cw,ch],columns:8,count:60,fps:30};
}
fs.writeFileSync(path.join(dir,'screen.json'),JSON.stringify(m,null,2)+'\n');
console.log(waterfallOnly?'Baked waterfall only: 60 frames, 2 second loop':'Baked waterfall and fire: 60 frames each, 2 second loops');
