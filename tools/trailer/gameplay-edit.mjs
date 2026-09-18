import fs from 'node:fs';
import {spawnSync} from 'node:child_process';
import {createCanvas,loadImage,GlobalFonts} from '@napi-rs/canvas';

const out='E:/Cairn-build-tools/trailer/gameplay-cut';
fs.mkdirSync(out,{recursive:true});
const sources=['19-12-14','19-15-19','19-21-11','19-28-41'].map(t=>`C:/Users/will/Videos/2026-09-17 ${t}.mp4`);
// Source seconds, real-time footage. No changes to HUD, combat state or camera.
const shots=[
 {clip:2,start:119.4,duration:3,note:'Opening jump and slam'},
 {card:'worlds',duration:2},
 {clip:1,start:51.1,duration:2,note:'Citadel axe impact'},
 {clip:3,start:159.2,duration:2,note:'Swamp enemy launched'},
 {clip:4,start:206.1,duration:2,note:'Ashen furnace jump attack'},
 {clip:2,start:236.5,duration:4,note:'Warden sword exchange'},
 {card:'combo',duration:2},
 {clip:3,start:78.3,duration:3.5,note:'Combo reaches 10x'},
 {clip:3,start:167.8,duration:1.5,note:'Crowd combat and blood'},
 {clip:1,start:44.2,duration:2,note:'Chicken running'},
 {clip:2,start:150.5,duration:3,note:'Chicken eaten; health rises'},
 {clip:3,start:163.6,duration:3,note:'Lightning crowd control'},
 {card:'arsenal',duration:2},
 {clip:2,start:251.3,duration:3,note:'Warden melee escalation'},
 {clip:3,start:380.5,duration:3,note:'King roots and rolling attack'},
 {clip:4,start:373,duration:3,note:'Saint bomb volley'},
 {clip:4,start:206.1,duration:4,note:'Furnace melee payoff'},
 {clip:3,start:68.4,duration:1,note:'Lightning accent'},
 {clip:2,start:120.7,duration:1,note:'Burning melee accent'},
 {clip:4,start:212.4,duration:1,note:'Jump accent'},
 {clip:3,start:160.7,duration:1,note:'Launched enemy accent'},
 {clip:4,start:360.5,duration:2,note:'Saint furnace threat'},
 {card:'logo',duration:5},
];
let elapsed=0;for(const s of shots){s.timeline=elapsed;elapsed+=s.duration;}
if(elapsed!==56)throw Error('Timeline must be 56 seconds');
fs.writeFileSync(out+'/edit-decisions.json',JSON.stringify({duration:elapsed,sources,shots},null,2));
const run=args=>{const p=spawnSync('ffmpeg',['-hide_banner','-loglevel','error','-y',...args],{windowsHide:true,maxBuffer:12*1024*1024});if(p.status!==0)throw Error(p.stderr.toString());return p.stdout;};
GlobalFonts.registerFromPath('asset-sources/fonts/cinzel.ttf','Cinzel');
GlobalFonts.registerFromPath('asset-sources/fonts/oswald.ttf','Oswald');
const backgrounds={worlds:[4,147],combo:[3,80],arsenal:[3,165],logo:[4,358]};
const copy={worlds:['THREE WORLDS','TO CONQUER','TWELVE ARENAS'],combo:['CHAIN HITS.','CRUSH YOUR HIGH SCORE.',''],arsenal:['THREE BOSSES','STAND IN YOUR WAY','']};
const logo=await loadImage('godot/art/cairn-logo.png');
for(const [id,[clip,time]] of Object.entries(backgrounds)){
 const bg=await loadImage(run(['-ss',String(time),'-i',sources[clip-1],'-frames:v','1','-f','image2pipe','-vcodec','png','pipe:1']));
 const canvas=createCanvas(1920,1080),g=canvas.getContext('2d');
 // Deliberately cropped/softened art on editorial cards only; gameplay is untouched.
 g.filter='blur(7px)';g.drawImage(bg,0,130,1920,830,0,0,1920,1080);g.filter='none';
 g.fillStyle='rgba(7,9,11,.83)';g.fillRect(0,0,1920,1080);
 const glow=g.createRadialGradient(960,820,0,960,820,850);glow.addColorStop(0,'rgba(149,47,16,.22)');glow.addColorStop(1,'rgba(0,0,0,0)');g.fillStyle=glow;g.fillRect(0,0,1920,1080);
 g.strokeStyle='#806340';g.lineWidth=2;g.beginPath();g.moveTo(640,294);g.lineTo(930,294);g.moveTo(990,294);g.lineTo(1280,294);g.stroke();
 g.save();g.translate(960,294);g.rotate(Math.PI/4);g.fillStyle='#c49b61';g.fillRect(-7,-7,14,14);g.restore();
 g.textAlign='center';
 if(id==='logo'){
  const w=1330,h=w*logo.height/logo.width;g.drawImage(logo,(1920-w)/2,485-h/2,w,h);
  g.font='34px Oswald';g.fillStyle='#c9baa4';g.fillText('A DARK FANTASY ARCADE BRAWLER',960,766);
 }else{
  const [a,b,c]=copy[id];const gold=g.createLinearGradient(0,420,0,670);gold.addColorStop(0,'#fff0d3');gold.addColorStop(.5,'#dbb879');gold.addColorStop(1,'#a77842');
  g.shadowColor='#000';g.shadowBlur=22;g.font='bold 104px Cinzel';g.fillStyle=gold;g.fillText(a,960,505);g.font=`bold ${b.length>20?85:104}px Cinzel`;g.fillText(b,960,635);
  g.shadowBlur=0;g.font='31px Oswald';g.fillStyle='#c9baa4';g.fillText(c,960,753);
 }
 // Deterministic fine ember flecks, not a replacement for gameplay effects.
 for(let n=0;n<85;n++){const x=(n*677+151)%1920,y=820+(n*79)%260;g.fillStyle=`rgba(221,132,61,${.08+(n%5)*.045})`;g.fillRect(x,y,1+n%3,1+n%4);}
 fs.writeFileSync(`${out}/${id}.png`,canvas.toBuffer('image/png'));
}
if(process.argv.includes('--cards-only'))process.exit(0);
for(let i=0;i<shots.length;i++){
 const s=shots[i],dest=`${out}/shot-${String(i).padStart(2,'0')}.mkv`;
 const signature=JSON.stringify(s);
 if(fs.existsSync(dest)&&fs.existsSync(dest+'.json')&&fs.readFileSync(dest+'.json','utf8')===signature&&!process.argv.includes('--force')&&!s.card)continue;
 const inputs=s.card?['-loop','1','-framerate','60','-i',`${out}/${s.card}.png`,'-f','lavfi','-i','anullsrc=r=48000:cl=stereo']:['-ss',String(s.start),'-i',sources[s.clip-1]];
 const vf=s.card?`zoompan=z='1.018-0.018*min(on/24,1)+0.008*on/${s.duration*60}':x='iw/2-iw/zoom/2':y='ih/2-ih/zoom/2':d=1:s=1920x1080:fps=60,fade=t=in:d=0.067${s.card==='logo'?',fade=t=out:st=4.65:d=0.35':''}`:'setsar=1';
 run([...inputs,'-map','0:v:0','-map',s.card?'1:a:0':'0:a:0','-vf',vf,'-af',`afade=t=in:d=0.008,afade=t=out:st=${s.duration-.012}:d=0.012`,'-t',String(s.duration),'-r','60','-c:v','libx264','-preset','fast','-crf','17','-pix_fmt','yuv420p','-c:a','pcm_s16le',dest]);
 fs.writeFileSync(dest+'.json',signature);
 console.log(`Rendered ${i+1}/${shots.length}: ${s.note||s.card}`);
}
const list=shots.map((s,i)=>`file 'shot-${String(i).padStart(2,'0')}.mkv'`).join('\n');fs.writeFileSync(out+'/concat.txt',list);
run(['-f','concat','-safe','0','-i',out+'/concat.txt','-c','copy',out+'/picture.mkv']);
// Use the untouched ElevenLabs source: remove the deep editorial gain pockets.
run(['-i','E:/Cairn-build-tools/trailer/music-options/ash-engine-source.mp3','-af','atrim=duration=56,apad=whole_dur=56,loudnorm=I=-19:TP=-2:LRA=7,afade=t=out:st=55.35:d=0.65','-ar','48000','-c:a','pcm_s24le',out+'/ash-engine-edit.wav']);
const filter="[0:a]volume=4.5[sfx];[sfx][1:a]amix=inputs=2:normalize=0:duration=first,alimiter=limit=0.88:level=false:latency=true[a]";
run(['-i',out+'/picture.mkv','-i',out+'/ash-engine-edit.wav','-filter_complex',filter,'-map','0:v','-map','[a]','-c:v','copy','-c:a','aac','-b:a','320k','-ar','48000','-t','56','-movflags','+faststart',out+'/cairn-gameplay-trailer.mp4']);
console.log(out+'/cairn-gameplay-trailer.mp4');
