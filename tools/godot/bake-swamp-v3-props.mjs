import fs from 'node:fs';
import {createCanvas,loadImage} from '@napi-rs/canvas';
const root='studies/backgrounds/swamp-v3/';
const sheet=await loadImage(root+'props.png');
const names=['moss','charm','rag','bell','banner','pendant','reeds','branch','heron'];
for(let i=0;i<9;i++){
 const col=i%3,row=Math.floor(i/3),x=Math.floor(col*sheet.width/3);
 let y=Math.floor(row*sheet.height/3),bottom=Math.floor((row+1)*sheet.height/3);
 if(i===0)bottom=Math.floor(sheet.height*.354);
 if(i===3)y=Math.floor(sheet.height*.354);
 const w=Math.floor((col+1)*sheet.width/3)-x,h=bottom-y;
 const cell=createCanvas(w,h),g=cell.getContext('2d');g.drawImage(sheet,x,y,w,h,0,0,w,h);
 const pixels=g.getImageData(0,0,w,h).data;let left=w,top=h,right=0,low=0,clear=0;
 for(let yy=0;yy<h;yy++)for(let xx=0;xx<w;xx++){const a=pixels[(yy*w+xx)*4+3];if(a>20){left=Math.min(left,xx);right=Math.max(right,xx);top=Math.min(top,yy);low=Math.max(low,yy)}else clear++}
 if(clear<w*h*.1)throw Error('Missing transparent background for '+names[i]);
 const out=createCanvas(right-left+5,low-top+5);out.getContext('2d').drawImage(cell,left,top,right-left+1,low-top+1,2,2,right-left+1,low-top+1);
 fs.writeFileSync(root+names[i]+'.png',out.toBuffer('image/png'));
 console.log(names[i],out.width,out.height);
}
