import assert from 'node:assert/strict';
import {createCanvas,loadImage} from '@napi-rs/canvas';
import {splitEpisodeSheet} from './split-episode-sheet.mjs';
for(const kind of ['witch','bearer']){
 const source=await loadImage(`asset-sources/art/episodes/${kind}.png`),frames=splitEpisodeSheet(source,kind);
 assert.equal(frames.length,8);
 assert.ok(frames[4].width>source.width/4,`${kind}: release arm must extend beyond the old cell`);
 assert.ok(frames[5].sourceBounds[0]>(kind==='witch'?470:450),`${kind}: recovery must not inherit the previous hand`);
 if(kind==='witch')assert.ok(frames[0].sourceBounds[3]>source.height/2,'Restore the feet clipped by the old horizontal cut');
 else assert.ok(frames[7].left<0,'Restore the corpse spilling left of its old cell');
 for(const [i,frame] of frames.entries()){
  const c=createCanvas(frame.width,frame.height),g=c.getContext('2d');g.drawImage(frame.image,0,0);
  const d=g.getImageData(0,0,c.width,c.height).data,seen=new Uint8Array(c.width*c.height),sizes=[];
  for(let p=0;p<seen.length;p++){
   if(seen[p]||d[p*4+3]<128)continue;
   const stack=[p];seen[p]=1;let n=0;
   while(stack.length){const q=stack.pop(),x=q%c.width;n++;for(const next of [x?q-1:-1,x<c.width-1?q+1:-1,q-c.width,q+c.width])if(next>=0&&next<seen.length&&!seen[next]&&d[next*4+3]>=128){seen[next]=1;stack.push(next)}}
   if(n>200)sizes.push(n);
  }
  assert.equal(sizes.length,1,`${kind} ${i}: stray pieces from another pose`);
  assert.ok(sizes[0]>=frame.corePixels,`${kind} ${i}: cropped away part of the figure`);
 }
}
console.log('CAIRN_EPISODE_SPRITES_OK: all 16 complete poses, no neighboring limbs or row fragments');
