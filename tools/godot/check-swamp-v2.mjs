import assert from 'node:assert/strict';
import fs from 'node:fs';
import {fileURLToPath} from 'node:url';
import {createCanvas,loadImage} from '@napi-rs/canvas';
import {screens,duration,assetFiles,prepareAssets,drawScenery,drawAtmosphere,drawForeground,drawActor} from '../../studies/backgrounds/swamp-v2/scene.js';
const root=new URL('../../studies/backgrounds/swamp-v2/',import.meta.url);
const images=await Promise.all(screens.map(s=>loadImage(fileURLToPath(new URL(s.file,root)))));
const art=Object.fromEntries(await Promise.all(Object.entries(assetFiles).map(async([key,file])=>[key,await loadImage(fileURLToPath(new URL(file,root)))])));
const assets=prepareAssets(images,art,createCanvas),canvas=createCanvas(1280,720),g=canvas.getContext('2d');
const sheet=createCanvas(1280,720),sg=sheet.getContext('2d');
const pixels=()=>Buffer.from(g.getImageData(0,0,1280,720).data);
function emptyRect(data,x,y,w,h){for(let row=y;row<y+h;row++)for(let col=x;col<x+w;col++)if(data[(row*1280+col)*4+3])return false;return true}
for(const key of ['branch','bough','roots','bell']){
  g.clearRect(0,0,1280,720);g.drawImage(art[key],0,0,1280,720);const d=pixels();let clear=0,opaque=0;
  for(let i=3;i<d.length;i+=4){if(d[i]===0)clear++;if(d[i]>200)opaque++}
  assert(clear>1280*720*.25&&opaque>1000,`${key}: missing usable transparency or artwork`);
}
for(let index=0;index<4;index++){
  function render(t,actor=false){drawScenery(g,index,images[index],assets,t);drawAtmosphere(g,index,t);if(actor)drawActor(g,.5,.85);drawForeground(g,index,assets,t);return pixels()}
  assert.deepEqual(render(0),render(duration),`${screens[index].name}: loop mismatch`);
  assert.notDeepEqual(render(0),render(2.3),'No scene motion');
  const before=render(duration-.001),after=render(.001);let sum=0;for(let i=0;i<before.length;i++)sum+=Math.abs(before[i]-after[i]);assert(sum/before.length<.3,'Visible seam discontinuity');
  for(const t of [0,2,4,6,8,12,18,23.99]){
    g.clearRect(0,0,1280,720);drawAtmosphere(g,index,t);assert(emptyRect(pixels(),0,476,1280,244),'Atmosphere intrudes on combat floor');
    g.clearRect(0,0,1280,720);drawForeground(g,index,assets,t);assert(emptyRect(pixels(),384,396,512,324),'Foreground obscures central combat area');
  }
  g.clearRect(0,0,1280,720);drawForeground(g,index,assets,3,{visible:false});assert(pixels().every(v=>v===0),'Foreground toggle failed');
  g.clearRect(0,0,1280,720);drawAtmosphere(g,index,3,[false,false]);assert(pixels().every(v=>v===0),'Atmosphere toggles failed');
  // Foreground off/motion off preserves a stable physical object, not an empty scene.
  g.clearRect(0,0,1280,720);drawForeground(g,index,assets,0,{motion:false});const still=pixels();
  g.clearRect(0,0,1280,720);drawForeground(g,index,assets,7,{motion:false});assert.deepEqual(still,pixels(),'Disabled foreground motion is not still');
  render(3,true);const snapshot=await loadImage(canvas.toBuffer('image/png'));sg.drawImage(snapshot,(index%2)*640,Math.floor(index/2)*360,640,360);
  if(process.argv.includes('--render'))fs.writeFileSync(new URL(`review-${index+1}.png`,root),canvas.toBuffer('image/png'));
  console.log(`${screens[index].name}: loop, motion, alpha, toggles, foreground clearance pass; seam mean ${(sum/before.length).toFixed(5)}`);
}
if(process.argv.includes('--render'))fs.writeFileSync(new URL('contact-sheet.png',root),sheet.toBuffer('image/png'));
