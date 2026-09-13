// Use the same stone renderer and material as Controls, Hall and the score HUD.
import fs from 'node:fs';
import vm from 'node:vm';
import {createCanvas,loadImage,GlobalFonts} from '@napi-rs/canvas';
const out='godot/art/results';
GlobalFonts.registerFromPath('asset-sources/fonts/cinzel.ttf','Cinzel');
GlobalFonts.registerFromPath('asset-sources/fonts/oswald.ttf','Oswald');
const image=await loadImage('asset-sources/art/menu-stone-material-v1.png');
const material=createCanvas(image.width,image.height);material.getContext('2d').drawImage(image,0,0);
Object.defineProperty(material,'naturalWidth',{value:material.width});
Object.defineProperty(material,'complete',{value:true});
let source=fs.readFileSync('tools/asset-bake-source/stone-text.js','utf8');
source=source.replace(' let frame=0;',' window.bakeStone=(el)=>{cache.clear();paint(el)}; return; let frame=0;');
source=source.replace('size*scale*.045','size*scale*.025').replace('size*scale*.12','size*scale*.035').replace('stone*.78+shine*.72+8','stone*.9+shine+45').replace('stone*.77+shine*.73+8','stone*.82+shine*.9+36').replace('stone*.74+shine*.75+7','stone*.64+shine*.7+24');
const document={documentElement:{dataset:{}},createElement:()=>{const c=createCanvas(1,1);c.setAttribute=()=>{};return c;}};
const scope={window:{},document,Image:function(){return material},getComputedStyle:el=>el.computed,console,Math,Float32Array,Map};
vm.createContext(scope);vm.runInContext(source,scope);
const manifest={glyphs:{},labels:{}};
function bounds(c){
 const p=c.getContext('2d').getImageData(0,0,c.width,c.height).data;
 let x0=c.width,y0=c.height,x1=0,y1=0;
 for(let y=0;y<c.height;y++)for(let x=0;x<c.width;x++)if(p[(y*c.width+x)*4+3]>8){x0=Math.min(x0,x);y0=Math.min(y0,y);x1=Math.max(x1,x);y1=Math.max(y1,y)}
 return {x:x0,y:y0,w:x1-x0+1,h:y1-y0+1};
}
async function render(text,family,tracking=1){
 const el={textContent:text,getClientRects:()=>[1],dataset:{stoneFont:family},computed:{fontSize:'75',letterSpacing:String(tracking)},querySelector:()=>true,classList:{add(){}},style:{setProperty(){}}};
 scope.window.bakeStone(el);
 const img=await loadImage(el._stoneFrames.url),c=createCanvas(img.width,img.height);c.getContext('2d').drawImage(img,0,0);
 return c;
}
for(const [kind,family,chars] of [['score','Cinzel','0123456789,'],['stat','Oswald','0123456789,:×HITS ']]){
 manifest.glyphs[kind]={};
 const zero=await render('0',family),box=bounds(zero),pad=75*.28*3;
 for(const ch of chars){
  const c=ch===' '?createCanvas(70,zero.height):await render(ch,family),file=`${kind}-${ch.codePointAt(0)}.png`;
  fs.writeFileSync(`${out}/${file}`,c.toBuffer('image/png'));
  manifest.glyphs[kind][ch]={file,width:c.width,height:c.height,advance:ch===' '?50:c.width-pad*2+3,pad,baseline:box.y+box.h,cap:box.h};
 }
}
for(const text of ['EVEN HEROES FALL.','THE VALLEY IS FREE.','FINAL SCORE','STATS','ENEMIES SLAIN','TIME SURVIVED','RUN TIME','BEST COMBO','PEAK MULTIPLIER','DAMAGE DEALT','DAMAGE TAKEN','NEW']){
 const c=await render(text,'Cinzel',text.endsWith('.')?1:3),box=bounds(c);
 const file=`label-${text.toLowerCase().replace(/[^a-z]+/g,'-').replace(/-$/,'')}.png`;
 fs.writeFileSync(`${out}/${file}`,c.toBuffer('image/png'));
 manifest.labels[text]={file,width:c.width,height:c.height,advance:box.w,pad:box.x,baseline:box.y+box.h,cap:box.h};
 if(text==='NEW'){
  const glow=createCanvas(c.width,c.height),g=glow.getContext('2d');
  for(const [blur,color] of [[30,'#ff7600'],[12,'#ffb82b'],[4,'#ffeab0']]){g.shadowColor=color;g.shadowBlur=blur;g.drawImage(c,0,0)}
  g.globalCompositeOperation='destination-out';g.drawImage(c,0,0);
  fs.writeFileSync(`${out}/new-glow.png`,glow.toBuffer('image/png'));
 }
}
fs.writeFileSync(`${out}/lettering.json`,JSON.stringify(manifest));
console.log('Baked results with shared Hall/HUD stone material and glyph-shaped NEW bloom.');
