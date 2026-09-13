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
const manifest=JSON.parse(fs.readFileSync(path.join(out,"manifest.json"),"utf8"));
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
const labels=[...Array.from({length:10},(_,i)=>String(i)),...Array.from({length:10},(_,i)=>`${i+1}X`),...Array.from({length:4},(_,i)=>`AREA ${i+1}/4`),...Array.from({length:3},(_,i)=>`WAVE ${i+1}/3`),'BOSS'];
for(const label of labels){
 if(manifest.menu["HUD "+label]&&fs.existsSync(path.join(out,`menu-${manifest.menu["HUD "+label].id}.png`))&&fs.existsSync(path.join(out,`menu-${manifest.menu["HUD "+label].id}-fuel.png`)))continue;
 const el={textContent:label,getClientRects:()=>[1],dataset:{stoneFont:'Cinzel'},computed:{fontSize:'75',letterSpacing:'1'},querySelector:()=>true,classList:{add(){}},style:{setProperty(){}}};sc.window.bakeStone(el);const r=el._stoneFrames,id='hud-'+label.toLowerCase().replace(/[^a-z0-9]+/g,'-').replace(/-$/,'');
 fs.writeFileSync(path.join(out,`menu-${id}.png`),Buffer.from(r.url.split(',')[1],'base64'));
 const c=createCanvas(r.sw,r.sh),g=c.getContext('2d'),p=g.createImageData(r.sw,r.sh);for(let i=0;i<r.fuel.length;i++){p.data[i*4]=p.data[i*4+1]=p.data[i*4+2]=255;p.data[i*4+3]=r.fuel[i]*255;}g.putImageData(p,0,0);write(`menu-${id}-fuel`,c);
 manifest.menu["HUD "+label]={id,width:r.width,height:r.height,fw:r.fw,fh:r.fh,pad:r.firePad};
 if(global.gc)global.gc();
}
fs.writeFileSync(path.join(out,'manifest.json'),JSON.stringify(manifest));
console.log('Asset conversion complete: '+out);

