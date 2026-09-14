import fs from 'node:fs';
import {createCanvas,loadImage} from '@napi-rs/canvas';
const out='godot/art/branding/';
const image=await loadImage(out+'cairn-mark-v2.png');
function raster(size){
 const canvas=createCanvas(size,size),ctx=canvas.getContext('2d');
 ctx.imageSmoothingEnabled=true;ctx.imageSmoothingQuality='high';
 ctx.drawImage(image,0,0,size,size);
 return canvas.toBuffer('image/png');
}
for(const size of [32,180,256])fs.writeFileSync(out+`cairn-icon-${size}.png`,raster(size));
// Windows ICO with full-alpha PNG images at every common shell size.
const sizes=[16,24,32,48,64,128,256],images=sizes.map(raster);
const header=Buffer.alloc(6+16*sizes.length);header.writeUInt16LE(1,2);header.writeUInt16LE(sizes.length,4);
let offset=header.length;
images.forEach((png,i)=>{const p=6+i*16;header[p]=sizes[i]%256;header[p+1]=sizes[i]%256;header.writeUInt16LE(1,p+4);header.writeUInt16LE(32,p+6);header.writeUInt32LE(png.length,p+8);header.writeUInt32LE(offset,p+12);offset+=png.length;});
fs.writeFileSync(out+'cairn.ico',Buffer.concat([header,...images]));
console.log('Baked gray cairn icons: PNG 32/180/256 and ICO 16 through 256.');
