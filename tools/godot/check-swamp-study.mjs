import assert from 'node:assert/strict';
import fs from 'node:fs';
import {createCanvas,loadImage} from '@napi-rs/canvas';
import {screens,duration,drawEffects} from '../../studies/backgrounds/swamp-v1/loops.js';
const root=new URL('../../studies/backgrounds/swamp-v1/',import.meta.url);
const canvas=createCanvas(1280,720),g=canvas.getContext('2d');
const sheet=createCanvas(1280,720),sg=sheet.getContext('2d');
for(let i=0;i<screens.length;i++){
 const im=await loadImage(new URL(screens[i].file,root).pathname.replace(/^\/(\w:)/,'$1'));
 function sample(t,enabled){g.clearRect(0,0,1280,720);drawEffects(g,i,t,enabled);return Buffer.from(g.getImageData(0,0,1280,720).data)}
 const start=sample(0),end=sample(duration);assert.deepEqual(start,end,`${screens[i].name}: loop endpoint mismatch`);
 assert.notDeepEqual(start,sample(1.1),`${screens[i].name}: no motion`);
 assert(sample(1.1,[false,false]).every(v=>v===0),'Disabled effects must be transparent');
 for(const t of [0,.5,1.1,2,4,6,7.99]){const pixels=sample(t);assert(pixels.subarray(1280*4*Math.ceil(720*.66)).every(v=>v===0),'Animation spills onto fighting floor')}
 // Endpoint equality alone cannot catch a discontinuity immediately before wrap.
 const before=sample(7.999),after=sample(.001);let delta=0;for(let j=3;j<before.length;j+=4)delta+=Math.abs(before[j]-after[j]);assert(delta/(1280*720)<.2,'Visible alpha discontinuity at seam');
 g.drawImage(im,0,0,1280,720);drawEffects(g,i,1.1);sg.drawImage(await loadImage(canvas.toBuffer('image/png')),(i%2)*640,Math.floor(i/2)*360,640,360);
 console.log(`${screens[i].name}: periodic, moving, toggleable; floor clear; seam alpha delta ${(delta/(1280*720)).toFixed(5)}`);
}
if(process.argv.includes('--contact-sheet'))fs.writeFileSync(new URL('contact-sheet.png',root),sheet.toBuffer('image/png'));

