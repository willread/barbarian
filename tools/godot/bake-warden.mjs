import fs from 'node:fs';
import {loadImage} from '@napi-rs/canvas';
import {splitEpisodeSheet} from './split-episode-sheet.mjs';
const image=await loadImage('asset-sources/art/iron-warden-v1.png');
const frames=splitEpisodeSheet(image,'warden');
const cels=frames.map((f,i)=>{
 const file=`iron-warden-v1-${i}.png`;
 fs.writeFileSync('godot/assets/'+file,f.image.toBuffer('image/png'));
 return {file,left:f.left,top:f.top,width:f.width,height:f.height};
});
fs.writeFileSync('godot/art/warden-atlas.json',JSON.stringify({cellWidth:Math.floor(image.width/4),cellHeight:Math.floor(image.height/4),referenceHeight:cels[0].height,facing:1,cels},null,2)+'\n');
console.log('CAIRN_WARDEN_ART_OK: 16 integrated axe poses',cels.map(c=>[c.width,c.height]));
