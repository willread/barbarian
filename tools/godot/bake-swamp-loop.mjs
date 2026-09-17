// One atlas per process keeps native canvas allocations bounded during episode builds.
import fs from 'node:fs';
import {createCanvas,loadImage} from '@napi-rs/canvas';
import {screens,assetFiles,prepareAssets,drawScenery,drawAtmosphere,drawForeground} from '../../studies/backgrounds/swamp-v3/scene.js';
const [key,index,rectText,mode]=process.argv.slice(2),area=Number(index);
const root='studies/backgrounds/swamp-v3/';
const images=await Promise.all(screens.map(s=>loadImage(root+s.file)));
const raw=Object.fromEntries(await Promise.all(Object.entries(assetFiles).map(async([k,f])=>[k,await loadImage(root+f)])));
const assets=prepareAssets(images,raw,createCanvas);
if(mode==='mask'){
 fs.writeFileSync('godot/assets/swamp-bird-depth.png',assets.birdMask.toBuffer('image/png'));
}else{
 const [x,y,w,h]=JSON.parse(rectText),still=mode==='rocks',count=still?1:288,columns=still?1:12,rows=still?1:24;
 const atlas=createCanvas(w*columns,h*rows),ag=atlas.getContext('2d'),canvas=createCanvas(1280,720),g=canvas.getContext('2d'),empty=createCanvas(1280,720);
 for(let i=0;i<count;i++){
  g.clearRect(0,0,1280,720);
  if(still)drawForeground(g,area,assets,0,{image:images[area]});
  else{drawScenery(g,area,empty,assets,i/12,area===0?[true,false,true]:[true,true,true]);drawAtmosphere(g,area,i/12)}
  ag.drawImage(canvas,x,y,w,h,i%columns*w,Math.floor(i/columns)*h,w,h);
 }
 fs.writeFileSync('godot/assets/'+key+'.png',atlas.toBuffer('image/png'));
}
