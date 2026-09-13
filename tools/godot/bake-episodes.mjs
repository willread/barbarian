import fs from 'node:fs';
import path from 'node:path';
import {createCanvas,loadImage} from '@napi-rs/canvas';
import {screens,assetFiles,prepareAssets,drawScenery,drawAtmosphere,drawForeground} from '../../studies/backgrounds/swamp-v2/scene.js';
const out='godot/assets/',source='asset-sources/art/episodes/';
const stamp=out+'episodes-bake.json';
const inputs=[import.meta.filename,...fs.readdirSync(source).map(f=>source+f),...fs.readdirSync('studies/backgrounds/ashen-v1').map(f=>'studies/backgrounds/ashen-v1/'+f),'studies/backgrounds/swamp-v2/scene.js'];
const version=inputs.map(f=>[f,fs.statSync(f).mtimeMs]);
if(fs.existsSync(stamp)&&fs.readFileSync(stamp,'utf8')===JSON.stringify(version)&&fs.existsSync(out+'ashen-4-base.png'))process.exit(0);
for(const kind of ['witch','bearer','king','saint']){
 const sheet=await loadImage(source+kind+'.png'),cw=Math.floor(sheet.width/4),ch=Math.floor(sheet.height/2),cels=[];
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
const images=await Promise.all(screens.map(s=>loadImage(path.resolve('studies/backgrounds/swamp-v2',s.file))));
const raw=Object.fromEntries(await Promise.all(Object.entries(assetFiles).map(async([k,f])=>[k,await loadImage('studies/backgrounds/swamp-v2/'+f)])));
const assets=prepareAssets(images,raw,createCanvas);
const emptyScenery=createCanvas(1280,720);
function bakeLoop(key,rect,draw,foreground=false){
 const [x,y,w,h]=rect,fw=Math.ceil(w/2),fh=Math.ceil(h/2),count=96,columns=8,rows=12;
 const atlas=createCanvas(fw*columns,fh*rows),ag=atlas.getContext('2d'),c=createCanvas(1280,720),g=c.getContext('2d');
 for(let i=0;i<count;i++){g.clearRect(0,0,1280,720);draw(g,i/4);ag.drawImage(c,x,y,w,h,i%columns*fw,Math.floor(i/columns)*fh,fw,fh)}
 const file=key+'.png';fs.writeFileSync(out+file,atlas.toBuffer('image/png'));
 return {foreground,animation:{atlas:file,rect,columns,rows,count,fps:4}};
}
const swamp=[];
for(let i=0;i<4;i++){
 const key='swamp-'+(i+1);fs.copyFileSync(path.resolve('studies/backgrounds/swamp-v2',screens[i].file),out+key+'-base.png');
 const rects=[[340,265,790,190],[180,130,510,315],[190,70,875,380],[180,200,930,260]];
 const regions=[bakeLoop(key+'-ambient',rects[i],(g,t)=>{drawScenery(g,i,emptyScenery,assets,t);drawAtmosphere(g,i,t)})];
 // Actual transparent foreground is rendered after actors, using its own atlas.
 const foregroundRects=i===1?[[970,65,310,325]]:i===3?[[0,565,430,155],[915,585,365,135]]:i===0?[[0,610,365,110],[1220,620,60,100]]:[[0,640,150,80]];
 for(const [j,rect] of foregroundRects.entries())regions.push(bakeLoop(key+'-front-'+j,rect,(g,t)=>drawForeground(g,i,assets,t),true));
 swamp.push({key,title:screens[i].name,regions,walkable:{polygon:[[0,.72],[1,.72],[1,.92],[0,.92]]},framing:{bottom_crop:.03}});
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
