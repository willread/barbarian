import fs from 'node:fs';
import {createCanvas,loadImage} from '@napi-rs/canvas';
const im=await loadImage('asset-sources/art/episodes/mire-oil-v2.png');
const c=createCanvas(1024,512),g=c.getContext('2d');
for(let i=0;i<4;i++){
 const w=im.width/4;
 g.drawImage(im,i*w,0,w,640,i*256+(256-w*.38)/2,8,w*.38,640*.38);
 g.drawImage(im,i*w,660,w,227,i*256,256+(256-227*256/w)/2,256,227*256/w);
}
const alpha=g.getImageData(0,0,1024,512).data;
if(alpha.filter((v,i)=>i%4===3&&v===0).length<1024*512*.2)throw Error('Oil sprites require real transparency');
fs.writeFileSync('godot/assets/mire-oil-v2.png',c.toBuffer('image/png'));
