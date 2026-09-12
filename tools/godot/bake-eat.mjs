import fs from 'node:fs';
import vm from 'node:vm';
import {createCanvas,loadImage} from '@napi-rs/canvas';
const sandbox={window:{},document:{createElement:()=>createCanvas(1,1)},console,Math,Float32Array,Int32Array,Uint8ClampedArray,Set,Map};vm.createContext(sandbox);
vm.runInContext(fs.readFileSync('tools/asset-bake-source/animation.js','utf8'),sandbox);
const A=sandbox.window.AshenAnimation;
const atlas=new A.Atlas(A.decodeChroma(await loadImage('asset-sources/art/hero-eat-v1.png')),{columns:4,rows:2,frames:8});
const scale=268/atlas.cels[0].image.height;
const data={cellWidth:atlas.cellWidth,cellHeight:atlas.cellHeight,facing:1,cels:[]};
for(let i=0;i<8;i++){const c=atlas.cels[i];fs.writeFileSync(`godot/art/eat-${i}.png`,c.image.toBuffer('image/png'));data.cels.push({file:`../art/eat-${i}.png`,left:c.left,top:c.top,width:c.image.width,height:c.image.height,rig:{scale,grip:[0,-140],angle:0,behind:false}});}
fs.writeFileSync('godot/art/eat-atlas.json',JSON.stringify(data));
