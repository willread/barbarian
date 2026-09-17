import fs from 'node:fs';
import path from 'node:path';
import {createCanvas,loadImage} from '@napi-rs/canvas';
import {foregroundRegion} from '../../studies/backgrounds/foreground.js';
const ids=['citadel-01-v6','citadel-02-v2','citadel-03-v4','citadel-04-v2'],screens=[];
for(const [i,id] of ids.entries()){
 const dir='studies/backgrounds/'+id,m=JSON.parse(fs.readFileSync(dir+'/screen.json')),key='citadel-'+(i+1);
 fs.copyFileSync(path.resolve(dir,m.frames[0]),'godot/assets/'+key+'-base.png');
 for(const [j,r] of m.regions.entries()){const file=key+'-loop-'+j+'.png';fs.copyFileSync(dir+'/'+r.animation.atlas,'godot/assets/'+file);r.animation.atlas=file}
 const c=createCanvas(1280,720),g=c.getContext('2d'),painting=await loadImage(path.resolve(dir,m.frames[0]));
 for(const r of m.foreground||[])g.drawImage(foregroundRegion(painting,r,1280,720,createCanvas),0,0);
 fs.writeFileSync('godot/assets/'+key+'-foreground.png',c.toBuffer('image/png'));m.key=key;screens.push(m);
}
fs.mkdirSync('godot/worlds',{recursive:true});fs.writeFileSync('godot/worlds/citadel.json',JSON.stringify(screens,null,2)+'\n');
