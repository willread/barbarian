import assert from 'node:assert/strict';
import {interiorWeights,sampleInterior} from './background-sampling.mjs';
const w=32,h=32,mask=new Uint8ClampedArray(w*h*4),pixels=new Uint8ClampedArray(w*h*4);
for(let y=5;y<27;y++)for(let x=5;x<27;x++){mask[(y*w+x)*4+3]=255;pixels[(y*w+x)*4]=100}
const weights=interiorWeights(mask,w,h);assert.equal(weights[5*w+5],0);assert(weights[16*w+16]>.9);
const poisoned=pixels.slice();for(let i=0;i<w*h;i++)if(weights[i]===0)poisoned[i*4]=255;
for(let y=0;y<31;y+=.7)for(let x=0;x<31;x+=.7)assert.equal(sampleInterior(pixels,weights,w,h,x,y,0),sampleInterior(poisoned,weights,w,h,x,y,0));
assert.equal(sampleInterior(pixels,weights,w,h,16.2,16.3,0),100);
assert.equal(sampleInterior(pixels,weights,w,h,-1,16,0),null);
console.log('Protected-edge sampling: excluded pixels cannot contaminate bilinear samples');
