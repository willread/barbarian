import assert from 'node:assert/strict';
import fs from 'node:fs';
import {createCanvas,loadImage} from '@napi-rs/canvas';
import {duration,screens,assetFiles,prepareAssets,drawScenery,drawAtmosphere,drawForeground} from '../../studies/backgrounds/swamp-v3/scene.js';
const root='studies/backgrounds/swamp-v3/';
const images=await Promise.all(screens.map(s=>loadImage(root+s.file)));
const raw=Object.fromEntries(await Promise.all(Object.entries(assetFiles).map(async([key,file])=>[key,await loadImage(root+file)])));
const art=prepareAssets(images,raw),c=createCanvas(1280,720),g=c.getContext('2d'),sheet=createCanvas(1280,720),sg=sheet.getContext('2d');
const render=(i,t,enabled=[true,true,true])=>{drawScenery(g,i,images[i],art,t,enabled);drawAtmosphere(g,i,t,enabled);drawForeground(g,i,art,t);return Buffer.from(g.getImageData(0,0,1280,720).data)};
for(let i=0;i<4;i++){
 const start=render(i,0),end=render(i,duration);let delta=0;for(let k=0;k<start.length;k++)delta+=Math.abs(start[k]-end[k]);assert(delta/start.length<.01,'loop endpoints');
 assert.notDeepEqual(start,render(i,2.3),'scene must animate');
 for(let e=0;e<screens[i].effects.length;e++){const on=render(i,12);const enabled=[true,true,true];enabled[e]=false;assert.notDeepEqual(on,render(i,12,enabled),'effect toggle '+i+':'+e)}
 render(i,i===0?12:2.3);fs.writeFileSync(root+'review-'+(i+1)+'.png',c.toBuffer('image/png'));sg.drawImage(await loadImage(c.toBuffer('image/png')),i%2*640,Math.floor(i/2)*360,640,360);
 g.clearRect(0,0,1280,720);drawForeground(g,i,art,2.3);
 const center=g.getImageData(256,0,768,720).data;assert(!center.some((v,k)=>k%4===3&&v>0),'foreground must leave central 60% clear');
}
fs.writeFileSync(root+'contact-sheet.png',sheet.toBuffer('image/png'));
console.log('CAIRN_SWAMP_V3_OK: four distinct scenes, per-effect controls, seamless loops and unobstructed foreground corridor');
