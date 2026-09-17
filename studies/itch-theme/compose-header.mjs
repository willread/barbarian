import fs from 'node:fs';
import {createCanvas,loadImage} from '@napi-rs/canvas';
const root='studies/itch-theme/';
function png(file){const b=fs.readFileSync(file),parts=[b.subarray(0,8)];for(let i=8;i<b.length;){const n=b.readUInt32BE(i),t=b.toString('ascii',i+4,i+8);if(['IHDR','PLTE','tRNS','IDAT','IEND'].includes(t))parts.push(b.subarray(i,i+n+12));i+=n+12;}return Buffer.concat(parts);}
const bg=await loadImage(png(root+'assets/header-scenery-v4.png'));
const logo=await loadImage(png(root+'assets/banner.png'));
const c=createCanvas(bg.width,bg.height),g=c.getContext('2d');g.drawImage(bg,0,0);
const w=c.width*.43;g.drawImage(logo,(c.width-w)/2,c.height*.24,w,w*logo.height/logo.width);
// Clear sub-visible alpha specks left by generation at the canvas boundary.
g.clearRect(0,c.height-1,c.width,1);
fs.writeFileSync(root+'assets/header-v4.png',c.toBuffer('image/png'));
const edge=g.getImageData(0,c.height-1,c.width,1).data;if(edge.some((v,i)=>i%4===3&&v))throw Error('Opaque edge');console.log('Banner saved; bottom edge fully transparent.');
