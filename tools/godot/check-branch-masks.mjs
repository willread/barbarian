import fs from 'node:fs';
import assert from 'node:assert/strict';
import {createCanvas,loadImage} from '@napi-rs/canvas';
import {foregroundRegion} from '../../studies/backgrounds/foreground.js';
const root='studies/backgrounds/citadel-03-v3/',level=JSON.parse(fs.readFileSync(root+'screen.json'));
const image=await loadImage(root+level.frames[0]);
let removed=0,retained=0;
for(const region of level.foreground.filter(r=>r.dark_silhouette)){
 const before=foregroundRegion(image,{...region,dark_silhouette:false},1280,720,createCanvas).getContext('2d').getImageData(0,0,1280,720).data;
 const after=foregroundRegion(image,region,1280,720,createCanvas).getContext('2d').getImageData(0,0,1280,720).data;
 for(let i=0;i<before.length;i+=4){
  if(!before[i+3])continue;
  const light=before[i]*.2126+before[i+1]*.7152+before[i+2]*.0722;
  if(light>=43){assert.equal(after[i+3],0,'Paving must not cover the actor');removed++}
  if(after[i+3]>128)retained++;
 }
}
assert(removed>100&&retained>100);
console.log(`BRANCH_MASKS_OK: ${removed} paving pixels removed; ${retained} dark branch pixels retained`);
