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
const root=process.cwd(),out=path.resolve(process.argv[2]||'godot/assets');
fs.mkdirSync(out,{recursive:true});
const write=(name,c)=>fs.writeFileSync(path.join(out,name+'.png'),c.toBuffer('image/png'));
const manifest={menu:{}};
// Bake the existing dynamic stone material for the finite menu vocabulary.
GlobalFonts.registerFromPath('asset-sources/fonts/anton.ttf','Anton');
const materialImage=await loadImage('asset-sources/art/menu-stone-material-v1.png');
const material=createCanvas(materialImage.width,materialImage.height);material.getContext('2d').drawImage(materialImage,0,0);
Object.defineProperty(material,'naturalWidth',{value:material.width});
Object.defineProperty(material,'complete',{value:true});
let stone=fs.readFileSync('tools/asset-bake-source/stone-text.js','utf8');stone=stone.replace(' let frame=0;',' window.bakeStone=(el)=>{cache.clear();paint(el)}; return; let frame=0;');
const fakeDoc={documentElement:{dataset:{}},createElement:()=>{const c=createCanvas(1,1);c.setAttribute=()=>{};return c;}};
const sc={window:{},document:fakeDoc,Image:function(){return material},getComputedStyle:el=>el.computed,console,Math,Float32Array,Map};vm.createContext(sc);vm.runInContext(stone,sc);
manifest.menu=manifest.menu||{};
const labels=Array.from('ABCDEFGHIJKLMNOPQRSTUVWXYZ?');
for(const label of labels){
 if(manifest.menu[label]&&fs.existsSync(path.join(out,`menu-${manifest.menu[label].id}.png`))&&fs.existsSync(path.join(out,`menu-${manifest.menu[label].id}-fuel.png`)))continue;
 const el={textContent:label,getClientRects:()=>[1],dataset:{},computed:{fontSize:'75',letterSpacing:'3'},querySelector:()=>true,classList:{add(){}},style:{setProperty(){}}};sc.window.bakeStone(el);const r=el._stoneFrames,id=label==='?'?'cheat-question':label.toLowerCase().replace(/[^a-z0-9]+/g,'-').replace(/-$/,'');
 fs.writeFileSync(path.join(out,`menu-${id}.png`),Buffer.from(r.url.split(',')[1],'base64'));
 const c=createCanvas(r.sw,r.sh),g=c.getContext('2d'),p=g.createImageData(r.sw,r.sh);for(let i=0;i<r.fuel.length;i++){p.data[i*4]=p.data[i*4+1]=p.data[i*4+2]=255;p.data[i*4+3]=r.fuel[i]*255;}g.putImageData(p,0,0);write(`menu-${id}-fuel`,c);
 manifest.menu[label]={id,width:r.width,height:r.height,fw:r.fw,fh:r.fh,pad:r.firePad};
 if(global.gc)global.gc();
}
fs.writeFileSync(path.join(out,'cheat-letters.json'),JSON.stringify(manifest));
console.log('Asset conversion complete: '+out);

