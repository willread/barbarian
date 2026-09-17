import fs from 'node:fs';
import {loadImage,createCanvas} from '@napi-rs/canvas';
import {splitEpisodeSheet} from './split-episode-sheet.mjs';
const source=await loadImage('asset-sources/art/iron-warden-v2.png');
// Decode the generated chroma backdrop using the established animation key.
const image=createCanvas(source.width,source.height),ctx=image.getContext('2d');
ctx.drawImage(source,0,0);
const pixels=ctx.getImageData(0,0,image.width,image.height),d=pixels.data;
const clamp=n=>Math.max(0,Math.min(1,n));
for(let i=0;i<d.length;i+=4){
 const neutral=Math.max(d[i],d[i+2]),excess=d[i+1]-neutral;
 if(excess>8){
  const key=Math.max(clamp((excess-8)/64),clamp((excess/Math.max(1,d[i+1])-.35)/.25));
  d[i+3]=Math.round(d[i+3]*(1-key));d[i+1]=neutral;
 }
}
ctx.putImageData(pixels,0,0);
const frames=splitEpisodeSheet(image,'warden-v2');
const cels=frames.map((f,i)=>{
 const file=`iron-warden-v1-${i}.png`;
 fs.writeFileSync('godot/assets/'+file,f.image.toBuffer('image/png'));
 return {file,left:f.left,top:f.top,width:f.width,height:f.height};
});
fs.writeFileSync('godot/art/warden-atlas.json',JSON.stringify({cellWidth:Math.floor(image.width/4),cellHeight:Math.floor(image.height/4),referenceHeight:cels[0].height,facing:1,cels},null,2)+'\n');
console.log('CAIRN_WARDEN_ART_OK: 16 integrated axe poses',cels.map(c=>[c.width,c.height]));
