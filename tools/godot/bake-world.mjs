import fs from 'node:fs';
import path from 'node:path';
import {createCanvas,loadImage} from '@napi-rs/canvas';
const ids=['citadel-01-v6','citadel-02-v2','citadel-03-v2','citadel-04-v1'],screens=[];
for(const [i,id] of ids.entries()){
 const dir='studies/backgrounds/'+id,m=JSON.parse(fs.readFileSync(dir+'/screen.json')),key='citadel-'+(i+1);
 fs.copyFileSync(path.resolve(dir,m.frames[0]),'godot/assets/'+key+'-base.png');
 for(const [j,r] of m.regions.entries()){const file=key+'-loop-'+j+'.png';fs.copyFileSync(dir+'/'+r.animation.atlas,'godot/assets/'+file);r.animation.atlas=file}
 const c=createCanvas(1280,720),g=c.getContext('2d');for(const r of m.foreground||[]){g.beginPath();r.polygon.forEach(([x,y],n)=>n?g.lineTo(x*1280,y*720):g.moveTo(x*1280,y*720));g.closePath();g.save();g.clip();g.drawImage(await loadImage(path.resolve(dir,m.frames[0])),0,0,1280,720);g.restore()}
 fs.writeFileSync('godot/assets/'+key+'-foreground.png',c.toBuffer('image/png'));m.key=key;screens.push(m);
}
fs.mkdirSync('godot/worlds',{recursive:true});fs.writeFileSync('godot/worlds/citadel.json',JSON.stringify(screens,null,2)+'\n');
