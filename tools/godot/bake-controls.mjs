// Lossless migration of the existing Canvas asset preparation, not a game runtime.
import fs from 'node:fs';
import {spawnSync} from 'node:child_process';
import path from 'node:path';
import vm from 'node:vm';
import {createRequire} from 'node:module';
const require=createRequire(import.meta.url);
let canvasLib;
try{canvasLib=require('@napi-rs/canvas')}catch{canvasLib=require('C:/Users/will/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/@napi-rs/canvas')}
const {createCanvas,loadImage,GlobalFonts}=canvasLib;
const root=process.cwd(),out=path.resolve('godot/art/controls');
fs.mkdirSync(out,{recursive:true});
const write=(name,c)=>fs.writeFileSync(path.join(out,name+'.png'),c.toBuffer('image/png'));
const manifest=JSON.parse(fs.readFileSync('godot/assets/manifest.json',"utf8"));
// Bake the existing dynamic stone material for the finite menu vocabulary.
GlobalFonts.registerFromPath('asset-sources/fonts/cinzel.ttf','Cinzel');
const materialImage=await loadImage('asset-sources/art/menu-stone-material-v1.png');
const material=createCanvas(materialImage.width,materialImage.height);material.getContext('2d').drawImage(materialImage,0,0);
Object.defineProperty(material,'naturalWidth',{value:material.width});
Object.defineProperty(material,'complete',{value:true});
let stone=fs.readFileSync('tools/asset-bake-source/stone-text.js','utf8');stone=stone.replace(' let frame=0;',' window.bakeStone=(el)=>{cache.clear();paint(el)}; return; let frame=0;');
const fakeDoc={documentElement:{dataset:{}},createElement:()=>{const c=createCanvas(1,1);c.setAttribute=()=>{};return c;}};
stone=stone.replace('size*scale*.045','size*scale*.025').replace('size*scale*.12','size*scale*.035').replace('stone*.78+shine*.72+8','stone*.9+shine+45').replace('stone*.77+shine*.73+8','stone*.82+shine*.9+36').replace('stone*.74+shine*.75+7','stone*.64+shine*.7+24');
const sc={window:{},document:fakeDoc,Image:function(){return material},getComputedStyle:el=>el.computed,console,Math,Float32Array,Map};vm.createContext(sc);vm.runInContext(stone,sc);
manifest.menu=manifest.menu||{};
const cache=new Map();
async function lettering(text){
 if(cache.has(text))return cache.get(text);
 const el={textContent:text,getClientRects:()=>[1],dataset:{stoneFont:'Cinzel'},computed:{fontSize:'75',letterSpacing:'1'},querySelector:()=>true,classList:{add(){}},style:{setProperty(){}}};
 sc.window.bakeStone(el);const img=await loadImage(el._stoneFrames.url);const result=crop(img);cache.set(text,result);return result;
}
function crop(img){
 const c=createCanvas(img.width,img.height),g=c.getContext('2d');g.drawImage(img,0,0);const p=g.getImageData(0,0,c.width,c.height).data;let x0=c.width,y0=c.height,x1=0,y1=0;
 for(let y=0;y<c.height;y++)for(let x=0;x<c.width;x++)if(p[(y*c.width+x)*4+3]>8){x0=Math.min(x0,x);x1=Math.max(x1,x);y0=Math.min(y0,y);y1=Math.max(y1,y)}
 return {img,x:x0,y:y0,w:x1-x0+1,h:y1-y0+1};
}

for(const text of ['CONTROLS','Move','Attack','Jump','Magic','Run','Spin','Charge','Jump attack','Pause']) {const r=await lettering(text);const c=createCanvas(r.w,r.h);c.getContext('2d').drawImage(r.img,r.x,r.y,r.w,r.h,0,0,r.w,r.h);fs.writeFileSync(path.join(out,text.toLowerCase().replaceAll(' ','-')+'.png'),c.toBuffer('image/png'));}
