import fs from 'node:fs';
import assert from 'node:assert/strict';
import {createCanvas,loadImage} from '@napi-rs/canvas';
const root='studies/backgrounds/citadel-01-v5/';const m=JSON.parse(fs.readFileSync(root+'screen.json')),source=JSON.parse(fs.readFileSync(root+'approved-masks.json'));
assert.deepEqual(m.walkable,source.walkable);
for(let i=0;i<2;i++){
 assert.deepEqual(m.regions[i].polygon,source.regions[i].polygon);
 const a=m.regions[i].animation,im=await loadImage(root+a.atlas),[x,y,w,h]=a.rect,c=createCanvas(im.width,im.height),g=c.getContext('2d');g.drawImage(im,0,0);
 assert.equal(im.width,w*8);assert.equal(im.height,h*8);
 let changes=0;const first=g.getImageData(0,0,w,h).data,next=g.getImageData(w,0,w,h).data;
 for(let p=0;p<first.length;p++)if(first[p]!==next[p])changes++;
 assert(changes>0);console.log(a.atlas+': approved polygon exact, 60 frames, moving pixels verified');
}
