// Lossless migration of the existing Canvas asset preparation, not a game runtime.
import fs from 'node:fs';
import path from 'node:path';
import vm from 'node:vm';
import {createRequire} from 'node:module';
const require=createRequire(import.meta.url);
let canvasLib;
try{canvasLib=require('@napi-rs/canvas')}catch{canvasLib=require('C:/Users/will/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/@napi-rs/canvas')}
const {createCanvas,loadImage,GlobalFonts}=canvasLib;
const root=process.cwd(),out=path.resolve(process.argv[2]||'godot/assets');
fs.mkdirSync(out,{recursive:true});
const write=(name,c)=>fs.writeFileSync(path.join(out,name+'.png'),c.toBuffer('image/png'));
const document={createElement:()=>createCanvas(1,1)};
const sandbox={window:{},document,console,Math,Float32Array,Int32Array,Uint8ClampedArray,Set,Map};
vm.createContext(sandbox);
for(const file of ['animation','mechanics','hero-rig','enemy-art','enemy-rig','enemies','environments'])vm.runInContext(fs.readFileSync(`public/${file}.js`,'utf8'),sandbox);
const A=sandbox.window.AshenAnimation,R=sandbox.window.AshenHeroRig;
const configs={
 'hero-pickup-unarmed-v1':{columns:4,rows:2,frames:8},'hero-cast-unarmed-v1':{columns:4,rows:2,frames:8},
 'hero-walk-unarmed-v8':{columns:4,rows:1,frames:4},'hero-actions-unarmed-v8':{columns:4,rows:2,frames:8,breathRegion:[.5,.275,.3,.11]},
 'hero-reactions-unarmed-v8':{columns:4,rows:3,frames:12},'hero-extra-unarmed-v8':{columns:4,rows:3,frames:12},'hero-close-unarmed-v8':{columns:4,rows:3,frames:12},
 'enemy-walk-v4':{columns:4,rows:1,frames:4,scale:.88,facing:-1},'enemy-attack-v4':{columns:4,rows:1,frames:4,scale:1.08,facing:-1},'enemy-charge-v5':{columns:4,rows:1,frames:4,scale:1.2,facing:-1},'enemy-combat-v3':{scale:1.07},
 'enemy-bone-v1':{},'enemy-shield-v1':{},'enemy-marauder-v1':{},'enemy-champion-v1':{},
 'weapons-v8':{columns:2,rows:1,frames:2},'enemy-equipment-v1':{columns:4,rows:1,frames:4},'chicken-v1':{columns:4,rows:3,frames:12}
};
const atlases={},manifest={atlases:{},weapons:R.weapons,enemyArt:sandbox.window.AshenEnemyArt,attacks:sandbox.window.AshenMechanics.attacks,roster:sandbox.window.AshenEnemies.roster,environments:{}};
for(const [name,config]of Object.entries(configs)){
 const decoded=A.decodeChroma(await loadImage(`public/art/${name}.png`));
 if(name==='chicken-v1'){const g=decoded.getContext('2d'),p=g.getImageData(0,0,decoded.width,decoded.height);for(let i=0;i<p.data.length;i+=4)p.data[i+3]*=A.clamp((p.data[i]-Math.min(p.data[i+1],p.data[i+2])-7)/18);g.putImageData(p,0,0)}
 atlases[name]=new A.Atlas(decoded,config);
}
const rig=new R.HeroRig(atlases,atlases['weapons-v8']);
for(const [name,atlas] of Object.entries(atlases)){
 if(!atlas.cels)throw Error('Cel extraction failed '+name);
 const meta={cellWidth:atlas.cellWidth,cellHeight:atlas.cellHeight,scale:atlas.scale,facing:atlas.facing,cels:[]};
 for(let i=0;i<atlas.cels.length;i++){
  const cel=atlas.cels[i],entry={left:cel.left,top:cel.top,width:cel.image.width,height:cel.image.height,file:`${name}-${i}.png`};
  write(`${name}-${i}`,cel.image);
  if(name.startsWith('hero-')){const l=rig.layout({atlas:name,frame:i});entry.rig={scale:l.scale,grip:l.grip,hand2:l.hand2,angle:l.angle,behind:!!l.key.behind};}
  meta.cels.push(entry);
 }
 manifest.atlases[name]=meta;
 console.log('Prepared '+name);
}
for(let i=0;i<48;i++)write(`hero-idle-${i}`,atlases['hero-actions-unarmed-v8'].breathingCel(atlases['hero-actions-unarmed-v8'].cels[0],i*.1+.00001));
for(const [key,file,far]of [['valley','valley'],['swamp','swamp-concept-v4'],['cinder','cinder-concept-v6','cinder-concept-v5']]){
 const env=new sandbox.window.AshenEnvironments.Environment(await loadImage(`public/art/${file}.png`),key,1440,810,null,null,far?await loadImage(`public/art/${far}.png`):null);
 write(`${key}-base`,env.base);if(env.near)write(`${key}-near`,env.near);
 manifest.environments[key]={near:!!env.near,splashes:env.splashes,layers:env.layers.map((l,i)=>{write(`${key}-layer-${i}`,l.texture);write(`${key}-mask-${i}`,l.mask);return {x:l.x,y:l.y,w:l.w,h:l.h,dx:l.dx,dy:l.dy,period:l.period,smoke:!!l.smoke,near:!!l.near};})};
}
for(const name of ['fluid-fire-v2-0','fluid-fire-v2-1','fluid-fire-v2-2','fluid-fire-v2-3','fluid-smoke-v1','cairn-title-v1','hud-bronze-v1','menu-stone-material-v1'])fs.copyFileSync(`public/art/${name}.png`,path.join(out,name+'.png'));
fs.copyFileSync('public/fonts/anton.ttf',path.join(out,'anton.ttf'));
fs.copyFileSync('public/fonts/cinzel.ttf',path.join(out,'cinzel.ttf'));
// Bake the existing dynamic stone material for the finite menu vocabulary.
GlobalFonts.registerFromPath('public/fonts/anton.ttf','Anton');
const materialImage=await loadImage('public/art/menu-stone-material-v1.png');
const material=createCanvas(materialImage.width,materialImage.height);material.getContext('2d').drawImage(materialImage,0,0);
Object.defineProperty(material,'naturalWidth',{value:material.width});
Object.defineProperty(material,'complete',{value:true});
let stone=fs.readFileSync('public/stone-text.js','utf8');stone=stone.replace(' let frame=0;',' window.bakeStone=paint; return; let frame=0;');
const fakeDoc={documentElement:{dataset:{}},createElement:()=>{const c=createCanvas(1,1);c.setAttribute=()=>{};return c;}};
const sc={window:{},document:fakeDoc,Image:function(){return material},getComputedStyle:el=>el.computed,console,Math,Float32Array,Map};vm.createContext(sc);vm.runInContext(stone,sc);
manifest.menu={};
for(const label of ['BEGIN','OPTIONS','SOUND: ON','SOUND: OFF','FULLSCREEN: ON','FULLSCREEN: OFF','BACK','RESUME BATTLE','RETURN TO TITLE','RISE AGAIN','THE BATTLE WAITS.','EVEN HEROES FALL.','A LEGEND RISES.']){
 const el={textContent:label,getClientRects:()=>[1],dataset:{},computed:{fontSize:'75',letterSpacing:'3'},querySelector:()=>true,classList:{add(){}},style:{setProperty(){}}};sc.window.bakeStone(el);const r=el._stoneFrames,id=label.toLowerCase().replace(/[^a-z]+/g,'-').replace(/-$/,'');
 fs.writeFileSync(path.join(out,`menu-${id}.png`),Buffer.from(r.url.split(',')[1],'base64'));
 const c=createCanvas(r.sw,r.sh),g=c.getContext('2d'),p=g.createImageData(r.sw,r.sh);for(let i=0;i<r.fuel.length;i++){p.data[i*4]=p.data[i*4+1]=p.data[i*4+2]=255;p.data[i*4+3]=r.fuel[i]*255;}g.putImageData(p,0,0);write(`menu-${id}-fuel`,c);
 manifest.menu[label]={id,width:r.width,height:r.height,fw:r.fw,fh:r.fh,pad:r.firePad};
}
fs.writeFileSync(path.join(out,'manifest.json'),JSON.stringify(manifest));
console.log('Asset conversion complete: '+out);

