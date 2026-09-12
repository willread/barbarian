// Lossless migration of the existing Canvas asset preparation, not a game runtime.
import fs from 'node:fs';
import {spawnSync} from 'node:child_process';
if(!process.env.MENU_BATCH){
 for(let i=1;i<=15;i++){const r=spawnSync(process.execPath,['--expose-gc',process.argv[1]],{env:{...process.env,MENU_BATCH:String(i)},stdio:'inherit',windowsHide:true});if(r.status!==0)process.exit(r.status||1);}
 process.exit(0);
}
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
const manifest=JSON.parse(fs.readFileSync(path.join(out,"manifest.json"),"utf8"));
// Bake the existing dynamic stone material for the finite menu vocabulary.
GlobalFonts.registerFromPath('public/fonts/anton.ttf','Anton');
const materialImage=await loadImage('public/art/menu-stone-material-v1.png');
const material=createCanvas(materialImage.width,materialImage.height);material.getContext('2d').drawImage(materialImage,0,0);
Object.defineProperty(material,'naturalWidth',{value:material.width});
Object.defineProperty(material,'complete',{value:true});
let stone=fs.readFileSync('public/stone-text.js','utf8');stone=stone.replace(' let frame=0;',' window.bakeStone=(el)=>{cache.clear();paint(el)}; return; let frame=0;');
const fakeDoc={documentElement:{dataset:{}},createElement:()=>{const c=createCanvas(1,1);c.setAttribute=()=>{};return c;}};
const sc={window:{},document:fakeDoc,Image:function(){return material},getComputedStyle:el=>el.computed,console,Math,Float32Array,Map};vm.createContext(sc);vm.runInContext(stone,sc);
manifest.menu=manifest.menu||{};
const labels=['BEGIN','OPTIONS','SOUND','DISPLAY','MUSIC: ON','MUSIC: OFF',...Array.from({length:101},(_,i)=>`VOLUME: ${i}`),'SOUND: ON','SOUND: OFF','FULLSCREEN: ON','FULLSCREEN: OFF','BACK','RESUME BATTLE','RETURN TO TITLE','RISE AGAIN','THE BATTLE WAITS.','EVEN HEROES FALL.','A LEGEND RISES.'];
for(const label of labels.slice((Number(process.env.MENU_BATCH)-1)*8,Number(process.env.MENU_BATCH)*8)){
 const el={textContent:label,getClientRects:()=>[1],dataset:{},computed:{fontSize:'75',letterSpacing:'3'},querySelector:()=>true,classList:{add(){}},style:{setProperty(){}}};sc.window.bakeStone(el);const r=el._stoneFrames,id=label.toLowerCase().replace(/[^a-z0-9]+/g,'-').replace(/-$/,'');
 fs.writeFileSync(path.join(out,`menu-${id}.png`),Buffer.from(r.url.split(',')[1],'base64'));
 const c=createCanvas(r.sw,r.sh),g=c.getContext('2d'),p=g.createImageData(r.sw,r.sh);for(let i=0;i<r.fuel.length;i++){p.data[i*4]=p.data[i*4+1]=p.data[i*4+2]=255;p.data[i*4+3]=r.fuel[i]*255;}g.putImageData(p,0,0);write(`menu-${id}-fuel`,c);
 manifest.menu[label]={id,width:r.width,height:r.height,fw:r.fw,fh:r.fh,pad:r.firePad};
 if(global.gc)global.gc();
}
fs.writeFileSync(path.join(out,'manifest.json'),JSON.stringify(manifest));
console.log('Asset conversion complete: '+out);

