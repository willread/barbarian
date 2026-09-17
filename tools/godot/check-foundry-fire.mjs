import fs from 'node:fs';
import assert from 'node:assert/strict';
import {createCanvas,loadImage} from '@napi-rs/canvas';
const root='studies/backgrounds/citadel-03-v3/',m=JSON.parse(fs.readFileSync(root+'screen.json'));
const r=m.regions[1],[x,y,w,h]=r.animation.rect;
const base=createCanvas(...m.size),bg=base.getContext('2d');
bg.drawImage(await loadImage(root+m.frames[0]),0,0,...m.size);
const original=bg.getImageData(x,y,w,h).data;
const image=await loadImage(root+r.animation.atlas),atlas=createCanvas(image.width,image.height),g=atlas.getContext('2d');g.drawImage(image,0,0);
let protectedSamples=0,animatedSamples=0;
for(let f=0;f<60;f++){
 const frame=g.getImageData(f%8*w,Math.floor(f/8)*h,w,h).data,t=f/30;
 for(let p=0;p<w*h;p++){
  const n=p*4;if(frame[n+3]<254)continue;
  const warm=Math.max(0,Math.min(1,(original[n]-original[n+2])/85));
  const pulse=1+warm*(.055*Math.sin(t*Math.PI*2+2)+.035*Math.sin(t*Math.PI*5+1));
  const protectedPixel=original[n]<145||original[n+1]<70||original[n]-original[n+2]<70;
  for(let k=0;k<3;k++){
   const delta=Math.abs(frame[n+k]-Math.min(255,original[n+k]*pulse));
   if(protectedPixel){assert(delta<=1,'Grate or dark masonry translated in frame '+f);protectedSamples++}
   else if(delta>2)animatedSamples++;
  }
 }
}
assert(protectedSamples>1000&&animatedSamples>100);
console.log('FOUNDRY_FIRE_OK: grate remains fixed through all 60 frames while bright fire animates');
