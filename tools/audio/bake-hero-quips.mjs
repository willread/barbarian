import fs from 'node:fs';
import path from 'node:path';
import {spawnSync} from 'node:child_process';
const jobs=[['waves_coming','when-coming','ElevenLabs_2026-09-17T04_25_54_Cairn_gen_sp90_s50_sb75_se0_b_m2.mp3','When will they stop coming?',4],['goat_search','seen-goat','ElevenLabs_2026-09-17T04_26_24_Cairn_gen_sp90_s50_sb75_se0_b_m2.mp3','Has anyone seen my goat?',1]];
const lines=JSON.parse(fs.readFileSync('godot/voice/lines.json'));
jobs.push(['boss_saint','boss-saint','ElevenLabs_2026-09-17T04_39_15_Cairn_gen_sp90_s50_sb75_se0_b_m2.mp3',"It's time to extinguish your flame.",10]);
jobs.push(['nice_place','nice-place','ElevenLabs_2026-09-17T04_33_36_Cairn_gen_sp90_s50_sb75_se0_b_m2.mp3',"Nice place you've got here.",3]);
jobs.push(['low_health','feel-tomorrow','ElevenLabs_2026-09-17T04_34_19_Cairn_gen_sp90_s50_sb75_se0_b_m2.mp3',"I'm going to feel this tomorrow.",6]);
jobs.push(['knocked_aside','pay-for-that','ElevenLabs_2026-09-17T04_35_47_Cairn_gen_sp90_s50_sb75_se0_b_m2.mp3',"You'll pay for that.",7]);
jobs.push(['boss_champion','boss-champion','ElevenLabs_2026-09-17T04_36_39_Cairn_gen_sp90_s50_sb75_se0_b_m2.mp3',"Why don't you fall on your sword and save me the trouble?",10]);
jobs.push(['goat_home','goat-home','ElevenLabs_2026-09-17T04_37_24_Cairn_gen_sp90_s50_sb75_se0_b_m2.mp3',"Just give me my goat, and we can all go home.",1]);
for(const [id,name,source,text,priority] of jobs){
 const original=`asset-sources/audio/${source}`;
 if(!fs.existsSync(original)){fs.mkdirSync(path.dirname(original),{recursive:true});fs.copyFileSync(path.join(process.env.USERPROFILE,'Downloads',source),original);}
 const file=`godot/voice/${name}.ogg`;
 let r=spawnSync('ffmpeg',['-v','error','-y','-i',original,'-af','loudnorm=I=-18:TP=-2:LRA=11','-ar','44100','-c:a','libvorbis','-q:a','5',file],{windowsHide:true});
 if(r.status!==0)throw Error(r.stderr.toString());
 r=spawnSync('ffmpeg',['-v','error','-i',file,'-f','f32le','-ac','1','-ar','24000','pipe:1'],{windowsHide:true});
 if(r.status!==0)throw Error(r.stderr.toString());
 const envelope=[];
 for(let start=0;start<r.stdout.length;start+=3200){let sum=0,count=0;for(let p=start;p+4<=Math.min(start+3200,r.stdout.length);p+=4){sum+=r.stdout.readFloatLE(p)**2;count++;}envelope.push(Math.sqrt(sum/Math.max(count,1)));}
 const peak=Math.max(...envelope,.001);
 lines[id]={file:`res://voice/${name}.ogg`,priority,cooldown:0,fps:30,envelope:envelope.map(x=>Math.round(x/peak*1000)/1000),text,source};
}
fs.writeFileSync('godot/voice/lines.json',JSON.stringify(lines,null,2)+'\n');
