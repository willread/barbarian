import fs from 'node:fs';
import path from 'node:path';
import vm from 'node:vm';
import {createRequire}from'node:module';
const require=createRequire(import.meta.url);
let lib;try{lib=require('@napi-rs/canvas')}catch{lib=require('C:/Users/will/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/@napi-rs/canvas')}
const{createCanvas,loadImage,Path2D}=lib;
const out=path.resolve(process.argv[2]||'godot/assets');
const {skull:shape,eyes,hud:code}=JSON.parse(fs.readFileSync('tools/asset-bake-source/drawing.json','utf8'));
const c=createCanvas(512,512),ctx=c.getContext('2d');ctx.translate(256,281);ctx.fillStyle='#fff';
vm.runInNewContext(shape+'ctx.fill(skull);ctx.fillStyle="#000";'+eyes,{ctx,Path2D});
fs.writeFileSync(path.join(out,'skull-mask.png'),c.toBuffer('image/png'));
// Use the existing bronze renderer so all frame crops and protruding details match.
const hudTexture=await loadImage('asset-sources/art/hud-bronze-v1.png'),crestImage=await loadImage('asset-sources/art/hud-bronze-top-extended-v2.png');
const hudCrests=createCanvas(2172,66),cg=hudCrests.getContext('2d');cg.drawImage(crestImage,0,0,2172,66,0,0,2172,66);
const p=cg.getImageData(0,0,2172,66);for(let i=0;i<p.data.length;i+=4){const x=i/4%2172,d=p.data;d[i+3]=x>110&&x<2062?0:255*Math.max(0,Math.min(1,(d[i]-Math.max(d[i+1],d[i+2])*1.12-6)/18));}cg.putImageData(p,0,0);
const hud=createCanvas(1440,296),h=hud.getContext('2d');h.fillText=()=>{};

vm.runInNewContext(code+'drawHUD();',{hudTexture,hudCrests,$:()=>hud,displayedHealth:0,displayedMana:0,canCast:()=>false,clamp:v=>Math.max(0,Math.min(1,v)),weapons:{axe:{}},weaponId:'axe',weaponAtlas:null,score:0,wave:1,encounters:Array(8)});
fs.writeFileSync(path.join(out,'hud-native-frame.png'),hud.toBuffer('image/png'));
console.log('Exact skull and HUD artwork prepared');
const manifest=JSON.parse(fs.readFileSync(path.join(out,'manifest.json'),'utf8'));
for(const [name,atlas]of Object.entries(manifest.atlases))if(name.startsWith('hero-'))for(const cel of atlas.cels){
 const r=cel.rig,s=r.scale,img=await loadImage(path.join(out,cel.file)),c=createCanvas(cel.width,cel.height),g=c.getContext('2d');
 g.beginPath();for(const hand of [r.grip,r.hand2].filter(Boolean)){const x=hand[0]/s-(cel.left-atlas.cellWidth*.5),y=hand[1]/s+cel.height;g.moveTo(x+8/s,y);g.arc(x,y,8/s,0,Math.PI*2);}g.clip();g.drawImage(img,0,0);
 fs.writeFileSync(path.join(out,cel.file.replace('.png','-hands.png')),c.toBuffer('image/png'));
}


