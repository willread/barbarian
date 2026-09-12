import fs from 'node:fs';
import path from 'node:path';
import {createCanvas,loadImage} from '@napi-rs/canvas';
import {interiorWeights,sampleInterior} from './background-sampling.mjs';
const dir=process.argv[2]||'studies/backgrounds/citadel-02-v1',m=JSON.parse(fs.readFileSync(path.join(dir,'screen.json'))),[w,h]=m.size;
const base=createCanvas(w,h),g=base.getContext('2d');g.drawImage(await loadImage(path.join(dir,'base.png')),0,0,w,h);const pixels=g.getImageData(0,0,w,h).data;
function mask(poly){const c=createCanvas(w,h),g=c.getContext('2d');g.fillStyle='white';g.beginPath();poly.forEach(([x,y],i)=>i?g.lineTo(x*w,y*h):g.moveTo(x*w,y*h));g.closePath();g.fill();return g.getImageData(0,0,w,h).data}
for(const [index,r] of m.regions.entries()){
 const coverage=mask(r.polygon),motion=interiorWeights(mask(r.motion_polygon),w,h,0,1);
 const x=Math.floor(Math.min(...r.polygon.map(p=>p[0]))*w),y=Math.floor(Math.min(...r.polygon.map(p=>p[1]))*h),cw=Math.ceil(Math.max(...r.polygon.map(p=>p[0]))*w)-x+1,ch=Math.ceil(Math.max(...r.polygon.map(p=>p[1]))*h)-y+1;
 const atlas=createCanvas(cw*8,ch*8),ag=atlas.getContext('2d'),frame=createCanvas(cw,ch),fg=frame.getContext('2d');
 for(let f=0;f<60;f++){
  const data=fg.createImageData(cw,ch),t=f/30,a=f/60,b=(a+.5)%1,wa=1-Math.abs(2*a-1),wb=1-wa;
  for(let py=0;py<ch;py++)for(let px=0;px<cw;px++){
   const xx=x+px,yy=y+py,n=yy*w+xx,i=(py*cw+px)*4,alpha=coverage[n*4+3];if(!alpha)continue;
   const warm=Math.max(0,Math.min(1,(pixels[n*4]-pixels[n*4+2])/85));
   const pulse=1+warm*(.055*Math.sin(t*Math.PI*2+index*2)+.035*Math.sin(t*Math.PI*5+index));
   for(let k=0;k<3;k++){
    const original=pixels[n*4+k],sa=sampleInterior(pixels,motion,w,h,xx,yy+12*(a-.5),k),sb=sampleInterior(pixels,motion,w,h,xx,yy+12*(b-.5),k),total=(sa===null?0:wa)+(sb===null?0:wb);
    const value=total>0?((sa??0)*wa+(sb??0)*wb)/total:original;
    data.data[i+k]=(original+(value-original)*motion[n]) *pulse;
   }data.data[i+3]=alpha;
  }
  fg.putImageData(data,0,0);ag.drawImage(frame,(f%8)*cw,Math.floor(f/8)*ch);
 }
 const name=`brazier-${index+1}.png`;fs.writeFileSync(path.join(dir,name),atlas.toBuffer('image/png'));r.animation={atlas:name,rect:[x,y,cw,ch],columns:8,count:60,fps:30};
}
fs.writeFileSync(path.join(dir,'screen.json'),JSON.stringify(m,null,2)+'\n');console.log(dir+': localized fire loops baked');
