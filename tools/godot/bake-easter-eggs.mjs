import fs from 'node:fs';
import {createCanvas,loadImage} from '@napi-rs/canvas';
const image=await loadImage('asset-sources/art/holiday/easter-eggs-v1.png');
const source=createCanvas(image.width,image.height),ctx=source.getContext('2d');
ctx.drawImage(image,0,0);
const pixels=ctx.getImageData(0,0,image.width,image.height).data;
for(let i=0;i<3;i++){
 let left=image.width,top=image.height,right=0,bottom=0;
 for(let y=0;y<image.height;y++)for(let x=Math.floor(i*image.width/3);x<Math.floor((i+1)*image.width/3);x++){
  if(pixels[(y*image.width+x)*4+3]<16)continue;
  left=Math.min(left,x);right=Math.max(right,x);top=Math.min(top,y);bottom=Math.max(bottom,y);
 }
 const h=128,w=Math.round((right-left+1)*h/(bottom-top+1));
 const out=createCanvas(w+4,h+4),draw=out.getContext('2d');
 draw.imageSmoothingEnabled=true;draw.imageSmoothingQuality='high';
 draw.drawImage(image,left,top,right-left+1,bottom-top+1,2,2,w,h);
 fs.writeFileSync(`godot/art/easter-eggs-v1-${i}.png`,out.toBuffer('image/png'));
}
console.log('CAIRN_EASTER_ART_OK: three compact transparent egg sprites');
