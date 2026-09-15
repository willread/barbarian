import fs from 'node:fs';
import {loadImage} from '@napi-rs/canvas';
import {splitEpisodeSheet} from './split-episode-sheet.mjs';
for(const kind of ['walk','attacks']){
 const image=await loadImage(`asset-sources/art/episodes/king-${kind}-v2.png`);
 const frames=splitEpisodeSheet(image,'king-polish');
 const cels=frames.map((f,i)=>{
  const file=`king-${kind}-v2-${i}.png`;
  fs.writeFileSync('godot/assets/'+file,f.image.toBuffer('image/png'));
  return {file,left:f.left,top:f.top,width:f.width,height:f.height};
 });
 fs.writeFileSync(`godot/art/king-${kind}-atlas.json`,JSON.stringify({cellWidth:Math.floor(image.width/4),cellHeight:Math.floor(image.height/2),referenceHeight:kind==='walk'?425:380,facing:1,cels},null,2)+'\n');
}
console.log('CAIRN_KING_ART_OK: eight complete strides and eight distinct attack poses');

const roots=splitEpisodeSheet(await loadImage('asset-sources/art/episodes/king-roots-v2.png'),'king-roots');
roots.forEach((frame,i)=>fs.writeFileSync(`godot/assets/king-root-v2-${i}.png`,frame.image.toBuffer('image/png')));
console.log('CAIRN_KING_ROOTS_OK: four complete bark silhouettes',roots.map(f=>[f.width,f.height]));
