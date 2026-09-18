import fs from 'node:fs';
import {spawnSync} from 'node:child_process';
import {renderMotionTitle} from './motion-titles.mjs';

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
 {card:'arsenal',duration:2,note:'Dash. Charge. Unleash magic.'},
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
for(let i=0;i<shots.length;i++){
 const s=shots[i],dest=`${out}/shot-${String(i).padStart(2,'0')}.mkv`;
 const signature=JSON.stringify(s);
 if(fs.existsSync(dest)&&fs.existsSync(dest+'.json')&&fs.readFileSync(dest+'.json','utf8')===signature&&!process.argv.includes('--force')&&!s.card)continue;
 if(s.card){
  const backgrounds={worlds:[2,122.4],combo:[3,76.3],arsenal:[4,212.4],logo:[4,362.5]};
  const [clip,start]=backgrounds[s.card];
  const prev=shots[i-1];
  await renderMotionTitle({id:s.card,duration:s.duration,source:sources[clip-1],start,previous:prev?.clip?{source:sources[prev.clip-1],start:prev.start+prev.duration-1/60}:null,out,dest});
 }else{
  run(['-ss',String(s.start),'-i',sources[s.clip-1],'-map','0:v:0','-map','0:a:0','-vf','setsar=1','-af',`afade=t=in:d=0.008,afade=t=out:st=${s.duration-.012}:d=0.012`,'-t',String(s.duration),'-r','60','-c:v','libx264','-preset','fast','-crf','17','-pix_fmt','yuv420p','-c:a','pcm_s16le',dest]);
 }
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
