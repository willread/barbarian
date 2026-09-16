import fs from 'node:fs';import vm from 'node:vm';import {createCanvas,loadImage} from '@napi-rs/canvas';
const sandbox={window:{},document:{createElement:()=>createCanvas(1,1)},console,Math,Float32Array,Int32Array,Uint8ClampedArray,Set,Map};vm.createContext(sandbox);vm.runInContext(fs.readFileSync('tools/asset-bake-source/animation.js','utf8'),sandbox);
const img=sandbox.window.AshenAnimation.decodeChroma(await loadImage('asset-sources/art/armory-selected-v1.png'));
const defs=[['gravecleaver',0,490,127,126,.76],['blacktooth',490,820,632,164,.81],['barrow_star',820,1210,1018,116,.78],['gatebreaker',1210,1672,1410,108,.76]];
const data={};
for(const [id,x0,x1,shaft,length,grip] of defs){const ctx=img.getContext('2d'),pixels=ctx.getImageData(x0,0,x1-x0,img.height);let l=x1-x0,r=0,t=img.height,b=0;for(let y=0;y<img.height;y++)for(let x=0;x<x1-x0;x++)if(pixels.data[(y*(x1-x0)+x)*4+3]>20){l=Math.min(l,x);r=Math.max(r,x);t=Math.min(t,y);b=Math.max(b,y);}
const c=createCanvas(r-l+1,b-t+1);c.getContext('2d').drawImage(img,x0+l,t,c.width,c.height,0,0,c.width,c.height);fs.writeFileSync(`godot/art/weapon-${id}.png`,c.toBuffer('image/png'));data[id]={file:`../art/weapon-${id}.png`,width:c.width,height:c.height,length,grip,pivot:(shaft-x0-l)/c.width};}
fs.writeFileSync('godot/art/armory.json',JSON.stringify(data,null,2));
