import fs from 'node:fs';
import path from 'node:path';
import {createCanvas,loadImage} from '@napi-rs/canvas';
import {splitEpisodeSheet} from './split-episode-sheet.mjs';
import {screens,assetFiles,prepareAssets,drawScenery,drawAtmosphere,drawForeground} from '../../studies/backgrounds/swamp-v3/scene.js';
const out='godot/assets/',source='asset-sources/art/episodes/';
const stamp=out+'episodes-bake.json';
const inputs=[import.meta.filename,'tools/godot/split-episode-sheet.mjs',...fs.readdirSync(source).map(f=>source+f),...fs.readdirSync('studies/backgrounds/ashen-v1').map(f=>'studies/backgrounds/ashen-v1/'+f),...['scene.js',...screens.map(s=>s.file),...Object.values(assetFiles)].map(f=>'studies/backgrounds/swamp-v3/'+f)];
const version=inputs.map(f=>[f,fs.statSync(f).mtimeMs]);
if(fs.existsSync(stamp)&&fs.readFileSync(stamp,'utf8')===JSON.stringify(version)&&fs.existsSync(out+'ashen-4-base.png'))process.exit(0);
fs.copyFileSync(source+'mire-effect-v1.png',out+'mire-effect-v1.png');
for(const kind of ['witch','bearer','king','saint']){
 const sheet=await loadImage(source+kind+'.png'),cw=Math.floor(sheet.width/4),ch=Math.floor(sheet.height/2),cels=[];
 if(kind==='witch'||kind==='bearer'||kind==='king'){
  for(const [i,frame] of splitEpisodeSheet(sheet,kind).entries()){
   const file=`enemy-${kind}-${i}.png`;fs.writeFileSync(out+file,frame.image.toBuffer('image/png'));
   cels.push({file,left:frame.left,top:frame.top,width:frame.width,height:frame.height});
  }
  fs.writeFileSync(`godot/art/${kind}-atlas.json`,JSON.stringify({cellWidth:cw,cellHeight:ch,facing:1,cels},null,2)+'\n');
  continue;
 }
 for(let i=0;i<8;i++){
  const c=createCanvas(cw,ch),g=c.getContext('2d');
  if(kind==='witch'&&i<2){g.translate(cw,0);g.scale(-1,1)}
  g.drawImage(sheet,(i%4)*cw,Math.floor(i/4)*ch,cw,ch,0,0,cw,ch);
  const pix=g.getImageData(0,0,cw,ch);let x0=cw,y0=ch,x1=0,y1=0,transparent=0;
  for(let y=0;y<ch;y++)for(let x=0;x<cw;x++){const a=pix.data[(y*cw+x)*4+3];if(a<20)transparent++;if(a>35){x0=Math.min(x0,x);y0=Math.min(y0,y);x1=Math.max(x1,x);y1=Math.max(y1,y)}}
  if(transparent<cw*ch*.1)throw Error(kind+' needs transparent source art');
  const w=x1-x0+1,h=y1-y0+1,crop=createCanvas(w,h);crop.getContext('2d').drawImage(c,x0,y0,w,h,0,0,w,h);
  const file=`enemy-${kind}-${i}.png`;fs.writeFileSync(out+file,crop.toBuffer('image/png'));cels.push({file,left:x0,top:y0,width:w,height:h});
 }
 fs.writeFileSync(`godot/art/${kind}-atlas.json`,JSON.stringify({cellWidth:cw,cellHeight:ch,facing:1,cels},null,2)+'\n');
}
const images=await Promise.all(screens.map(s=>loadImage(path.resolve('studies/backgrounds/swamp-v3',s.file))));
const raw=Object.fromEntries(await Promise.all(Object.entries(assetFiles).map(async([k,f])=>[k,await loadImage('studies/backgrounds/swamp-v3/'+f)])));
const assets=prepareAssets(images,raw,createCanvas);
const emptyScenery=createCanvas(1280,720);
fs.writeFileSync(out+'swamp-bird-depth.png',assets.birdMask.toBuffer('image/png'));
function bakeLoop(key,rect,draw,foreground=false,still=false){
 const [x,y,w,h]=rect,fw=w,fh=h,count=still?1:288,columns=still?1:12,rows=still?1:24;
 const atlas=createCanvas(fw*columns,fh*rows),ag=atlas.getContext('2d'),c=createCanvas(1280,720),g=c.getContext('2d');
 for(let i=0;i<count;i++){g.clearRect(0,0,1280,720);draw(g,i/12);ag.drawImage(c,x,y,w,h,i%columns*fw,Math.floor(i/columns)*fh,fw,fh)}
 const file=key+'.png';fs.writeFileSync(out+file,atlas.toBuffer('image/png'));
 return {foreground,animation:{atlas:file,rect,columns,rows,count,fps:still?1:12,blend:false}};
}
const swamp=[];
for(let i=0;i<4;i++){
 const key='swamp-'+(i+1);fs.copyFileSync(path.resolve('studies/backgrounds/swamp-v3',screens[i].file),out+key+'-base.png');
 const rects=[[[145,70,75,200],[300,98,65,170],[450,140,65,145],[1120,375,160,110]],[[260,118,330,240]],[[240,90,135,140],[960,172,90,100]],[[338,90,135,185],[820,90,135,185]]];
 const regions=rects[i].map((rect,j)=>bakeLoop(key+'-v3-detail-'+j,rect,(g,t)=>{drawScenery(g,i,emptyScenery,assets,t,i===0?[true,false,true]:[true,true,true]);drawAtmosphere(g,i,t)}));
 const foregroundRects=[[[20,660,105,60],[1200,660,80,60]],[[1195,680,85,40]],[[0,682,80,38]],[]][i];
 for(const [j,rect] of foregroundRects.entries())regions.push(bakeLoop(key+'-v3-front-'+j,rect,(g,t)=>drawForeground(g,i,assets,t),true,!(i===0&&j===1)));
 swamp.push({key,title:screens[i].name,revision:3,birds:i===0,regions,walkable:{polygon:[[0,.72],[1,.72],[1,.92],[0,.92]]},framing:{bottom_crop:.03}});
}
fs.writeFileSync('godot/worlds/swamp.json',JSON.stringify(swamp,null,2)+'\n');
const ash=[];
for(const [i,file] of ['01-road.png','02-mouth.png','03-crucible.png','04-reliquary.png'].entries()){
 const key='ashen-'+(i+1);fs.copyFileSync('studies/backgrounds/ashen-v1/'+file,out+key+'-base.png');
 ash.push({key,title:['Ashfall Road','The Furnace Mouth','The Black Crucible','Saint’s Reliquary'][i],regions:[],walkable:{polygon:[[0,.73],[1,.73],[1,.92],[0,.92]]},framing:{bottom_crop:.03}});
}
fs.writeFileSync('godot/worlds/ashen.json',JSON.stringify(ash,null,2)+'\n');
fs.writeFileSync(stamp,JSON.stringify(version));
console.log('Baked two episodes: 8 backgrounds, separate swamp foreground loops, 32 creature poses.');
