import fs from 'node:fs';
import {spawnSync} from 'node:child_process';
import {createCanvas,loadImage,GlobalFonts} from '@napi-rs/canvas';
const out='E:/Cairn-build-tools/itch-artwork';fs.mkdirSync(out,{recursive:true});
fs.mkdirSync(out+'/screenshots',{recursive:true});
const captures=[['01-citadel-under-pressure', '19-15-19',146],['02-swamp-lightning','19-21-11',69],['03-forge-aerial-combat','19-28-41',207],['04-king-charge','19-21-11',383],['05-saint-bomb-volley','19-28-41',381.5]];
for(const [name,clip,at] of captures){const p=spawnSync('ffmpeg',['-y','-hide_banner','-loglevel','error','-ss',String(at),'-i',`C:/Users/will/Videos/2026-09-17 ${clip}.mp4`,'-frames:v','1','-q:v','2',`${out}/screenshots/${name}.jpg`],{windowsHide:true});if(p.status!==0)throw Error(p.stderr.toString());}
GlobalFonts.registerFromPath('asset-sources/fonts/anton.ttf','Anton');
GlobalFonts.registerFromPath('asset-sources/fonts/oswald.ttf','Oswald');
const logo=await loadImage('godot/art/maximum-force-logo.png');
for(const size of [512,256]){
 const c=createCanvas(size,size),g=c.getContext('2d');g.scale(size/512,size/512);
 g.fillStyle='#111317';g.fillRect(0,0,512,512);
 const glow=g.createRadialGradient(256,230,10,256,230,300);glow.addColorStop(0,'#3b2720');glow.addColorStop(1,'#111317');g.fillStyle=glow;g.fillRect(0,0,512,512);
 g.drawImage(logo,280,15,1410,720,40,92,432,221);
 g.fillStyle='#e9e7df';g.textAlign='center';g.font='51px Anton';g.fillText('MAXIMUM',256,386);g.fillText('FORCE',256,447);
 fs.writeFileSync(`${out}/maximum-force-profile-${size}.png`,c.toBuffer('image/png'));
}
// The full existing transparent lockup is also supplied, unchanged in design.
const lock=createCanvas(1024,512),lg=lock.getContext('2d');lg.drawImage(logo,0,0,1024,512);fs.writeFileSync(out+'/maximum-force-lockup-transparent.png',lock.toBuffer('image/png'));
const names=fs.readdirSync(out+'/screenshots').filter(n=>n.endsWith('.jpg'));
const sheet=createCanvas(1200,Math.ceil(names.length/2)*370),sg=sheet.getContext('2d');sg.fillStyle='#111';sg.fillRect(0,0,sheet.width,sheet.height);
for(let i=0;i<names.length;i++){const x=i%2*600,y=Math.floor(i/2)*370;sg.drawImage(await loadImage(out+'/screenshots/'+names[i]),x,y,600,337.5);sg.fillStyle='#eee';sg.font='18px Oswald';sg.fillText(names[i],x+12,y+362);}
fs.writeFileSync(out+'/screenshot-contact.jpg',sheet.toBuffer('image/jpeg'));
const source='asset-sources/marketing/itch-keyart.png';
if(fs.existsSync(source)){
 const art=await loadImage(source),frames=out+'/cover-frames';fs.mkdirSync(frames,{recursive:true});
 for(let i=0;i<48;i++){
  const t=i/48*Math.PI*2,c=createCanvas(630,500),g=c.getContext('2d');
  const scale=Math.max(630/art.width,500/art.height)*1.025,w=art.width*scale,h=art.height*scale;
  g.drawImage(art,(630-w)/2,(500-h)/2,w,h);
  const shade=g.createLinearGradient(0,0,380,0);shade.addColorStop(0,'rgba(3,7,11,.65)');shade.addColorStop(1,'rgba(3,7,11,0)');g.fillStyle=shade;g.fillRect(0,0,630,500);
  g.shadowColor='#050505';g.shadowBlur=8;g.fillStyle='#f3eee2';g.font='104px Anton';g.fillText('CAIRN',26,126);g.shadowBlur=0;
  g.font='19px Oswald';g.fillStyle='#d1c4ad';g.fillText('DARK FANTASY',30,160);g.fillText('ARCADE COMBAT',30,184);
  for(let p=0;p<22;p++){const phase=(i/48+p/22)%1,x=(p*137)%630+7*Math.sin(t+p),y=500-phase*440;g.globalAlpha=Math.sin(phase*Math.PI)*.65;g.fillStyle=p%4===0?'#ffe2a3':'#df7130';g.fillRect(x,y,1+p%2,2+p%3);}
  g.globalAlpha=1;fs.writeFileSync(`${frames}/${String(i).padStart(3,'0')}.png`,c.toBuffer('image/png'));
  if(i===0){fs.writeFileSync(out+'/cairn-cover-630x500.png',c.toBuffer('image/png'));const thumb=createCanvas(315,250);thumb.getContext('2d').drawImage(c,0,0,315,250);fs.writeFileSync(out+'/cairn-cover-315x250.png',thumb.toBuffer('image/png'));}
 }
 const r=spawnSync('ffmpeg',['-y','-hide_banner','-loglevel','error','-framerate','12','-i',frames+'/%03d.png','-filter_complex','split[a][b];[a]palettegen=max_colors=128[p];[b][p]paletteuse=dither=bayer:bayer_scale=4','-loop','0',out+'/cairn-cover-animated-630x500.gif'],{windowsHide:true});if(r.status!==0)throw Error(r.stderr.toString());
}
const files=fs.readdirSync(out).filter(n=>/\.(png|gif)$/.test(n));
const html=`<!doctype html><meta charset="utf-8"><title>Cairn · itch artwork</title><style>body{background:#101115;color:#e8e1d3;font:16px system-ui;margin:40px}h1{font-size:28px}section{display:flex;flex-wrap:wrap;gap:24px}figure{margin:0 0 30px;background:#1b1c20;padding:16px}img{display:block;max-width:630px;max-height:500px;width:auto;height:auto}figcaption{margin-top:12px}a{color:#edc58d}.screens img{max-width:640px}</style><h1>CAIRN — itch.io artwork</h1><p>Local review · Click a filename to download. Screenshots are unretouched gameplay.</p><section>${files.map(n=>`<figure><img src="${n}"><figcaption><a href="${n}" download>${n}</a> · ${(fs.statSync(out+'/'+n).size/1024).toFixed(0)} KB</figcaption></figure>`).join('')}</section><h2>Gameplay screenshots</h2><section class="screens">${names.map(n=>`<figure><img src="screenshots/${n}"><figcaption><a href="screenshots/${n}" download>${n}</a></figcaption></figure>`).join('')}</section>`;
fs.writeFileSync(out+'/index.html',html);console.log(out);
