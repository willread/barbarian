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
const root=process.cwd(),out=path.resolve('studies/controls');
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
const glyphs={};for(const file of fs.readdirSync(path.join(out,'icons')).filter(f=>f.endsWith('.svg')))glyphs[file.slice(0,-4).replace(/_outline$/,'')]=await loadImage(path.join(out,'icons',file));
const back=crop(await loadImage('godot/assets/menu-'+manifest.menu.BACK.id+'.png'));
const keyRows=[
 ['Move','W A S D   /   Arrow keys',['xbox_stick_l','/','xbox_dpad'],['playstation_stick_l','/','playstation_dpad']],
 ['Attack','J   /   Z   /   Left mouse',['xbox_button_color_x'],['playstation_button_color_square']],
 ['Jump','K   /   X   /   Space',['xbox_button_color_a'],['playstation_button_color_cross']],
 ['Magic','L   /   C   /   Right mouse',['xbox_button_color_y'],['playstation_button_color_triangle']],
 ['Run','Shift',['xbox_rb'],['playstation_trigger_r1']],
 ['Spin','Hold attack',['Hold','xbox_button_color_x'],['Hold','playstation_button_color_square']],
 ['Charge','Run + attack',['xbox_rb','+','xbox_button_color_x'],['playstation_trigger_r1','+','playstation_button_color_square']],
 ['Jump attack','Jump, then attack',['xbox_button_color_a','then','xbox_button_color_x'],['playstation_button_color_cross','then','playstation_button_color_square']],
 ['Pause','Escape',['xbox_button_menu'],['playstation5_button_options']]
];
const menuRows=[
 ['Navigate','Arrow keys',['xbox_stick_l','/','xbox_dpad'],['playstation_stick_l','/','playstation_dpad']],
 ['Confirm','Enter   /   Space   /   Left mouse',['xbox_button_color_a'],['playstation_button_color_cross']],
 ['Back','Escape',['xbox_button_color_b'],['playstation_button_color_circle']],
 ['Adjust setting','Left / Right arrows',['xbox_dpad'],['playstation_dpad']],
 ['Fullscreen','Alt + Enter',['Display menu'],['Display menu']]
];
for(const [page,rows] of [['combat',keyRows],['menus',menuRows]]){
 const c=createCanvas(1920,1080),g=c.getContext('2d');
 g.fillStyle='#080909';g.fillRect(0,0,1920,1080);
 g.globalAlpha=.025;g.drawImage(material,0,0,1920,1080);g.globalAlpha=1;
 const haze=g.createRadialGradient(960,320,100,960,520,1040);haze.addColorStop(0,'#30312930');haze.addColorStop(1,'#000000bb');g.fillStyle=haze;g.fillRect(0,0,1920,1080);
 const paint=(r,x,y,h,align='center')=>{const w=r.w*h/r.h;g.drawImage(r.img,r.x,r.y,r.w,r.h,align==='left'?x:x-w/2,y-h/2,w,h)};
 const text=async(t,x,y,h=27,align='left')=>paint(await lettering(t),x,y,h,align);
 await text('CONTROLS',960,100,58,'center');
 function plain(t,x,y,size=22,color='#b5ae97',align='center'){g.font=`600 ${size}px Cinzel`;g.textAlign=align;g.textBaseline='middle';g.fillStyle=color;g.fillText(t,x,y)}
 plain('COMBAT',835,184,23,page==='combat'?'#ded1af':'#6f716b');plain('MENUS',1085,184,23,page==='menus'?'#ded1af':'#6f716b');
 g.fillStyle='#aa8960';g.fillRect((page==='combat'?835:1085)-75,207,150,2);
 function line(y,alpha=1){g.globalAlpha=alpha;g.fillStyle='#6d5c40';g.fillRect(170,y,1580,1);g.globalAlpha=1}
 const cols=[210,600,1280,1580];
 plain('ACTION',cols[0],258,21,'#a89775','left');plain('KEYBOARD / MOUSE',cols[1],258,21,'#a89775','left');plain('XBOX',cols[2],258,21,'#a89775');plain('PLAYSTATION',cols[3],258,21,'#a89775');line(290);
 async function prompts(items,x,y){
  const widths=items.map(t=>glyphs[t]?48:t==='then'?58:t==='Hold'?65:t.length>8?170:30);let start=x-widths.reduce((a,b)=>a+b,0)/2-(items.length-1)*6;
  for(let i=0;i<items.length;i++){const t=items[i],w=widths[i];if(glyphs[t]){g.globalAlpha=.86;g.drawImage(glyphs[t],start,y-24,48,48);g.globalAlpha=1}else plain(t,start+w/2,y,19,'#aaa797');start+=w+12}
 }
 for(let i=0;i<rows.length;i++){
  const y=324+i*58; if(i%2===0){g.fillStyle='#b0a17b06';g.fillRect(170,y-28,1580,56)}
  await text(rows[i][0],cols[0],y,27);plain(rows[i][1],cols[1],y,25,'#d0c9b4','left');await prompts(rows[i][2],cols[2],y);await prompts(rows[i][3],cols[3],y);line(y+29,.22);
 }
 line(324+(rows.length-1)*58+30);
 if(page==='combat')plain('Double-tap a direction to run.  All bindings work together.',960,865,20,'#8b887a');
 paint(back,960,971,72);
 fs.writeFileSync(path.join(out,`controls-${page}-v1.png`),c.toBuffer('image/png'));
}
console.log('Rendered controls mockups with Cinzel and original stone Back.');
