import fs from 'node:fs';
import {loadImage} from '@napi-rs/canvas';
import {splitEpisodeSheet} from './split-episode-sheet.mjs';
for(const [kind,source,key] of [['saint','asset-sources/art/episodes/saint.png','saint-v2'],['saint-toss','godot/art/saint-toss-v2.png','saint-toss']]){
 // The existing four-figure roots layout is also a 2x2 transparent sheet.
 const image=await loadImage(source),frames=splitEpisodeSheet(image,kind==='saint-toss'?'king-roots':kind),columns=frames.length===4?2:4;
 const cels=frames.map((frame,i)=>{
  const file=`../art/${key}-${i}.png`;
  fs.writeFileSync('godot/assets/'+file,frame.image.toBuffer('image/png'));
  return {file,left:frame.left,top:frame.top,width:frame.width,height:frame.height};
 });
 fs.writeFileSync(`godot/art/${key}-atlas.json`,JSON.stringify({cellWidth:Math.floor(image.width/columns),cellHeight:Math.floor(image.height/2),referenceHeight:cels[0].height,facing:1,cels},null,2)+'\n');
 console.log('CAIRN_SAINT_ART_OK',key,frames.map(f=>[f.width,f.height]));
}
