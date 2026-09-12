import fs from 'node:fs';
import vm from 'node:vm';
import {execFileSync} from 'node:child_process';
const folder='soundboard';
const original=fs.readFileSync('tools/audio/generate.mjs','utf8');
const effects=vm.runInNewContext(original.slice(original.indexOf('const effects=')+14,original.indexOf('\nconst common=')).replace(/;\s*$/,''));
const manifest=JSON.parse(fs.readFileSync(folder+'/manifest.json','utf8'));
// These existing nine previews were generated before shortening the shared prefix.
const longStyle='Premium dark fantasy game menu sound design. Dark, heavy, bassy physical stone and aged iron. Close forceful transient with dense low mid body and controlled deep bass, audible on normal speakers. No music, voices, bright digital bleeps or long cinematic risers. One isolated event, immediate onset. ';
const shortStyle='Dark fantasy menu Foley. Heavy stone and aged iron, deep bass and dense low mids. One isolated impact, immediate onset, short decay. No music, voices, bleeps or risers. ';
for(const j of manifest.jobs)if(!['drop-1','drop-2','drop-4'].includes(j.id)&&j.prompt.startsWith(shortStyle))j.prompt=longStyle+j.prompt.slice(shortStyle.length);
const variants=[['Raw weight','Close, dry and physical','Close dry realistic recording, dense low-mid body, restrained room tail.'],['Deep impact','Deeper, heavier and more forceful','Emphasize deep weight and dark low frequencies with a stronger transient, natural and tactile.'],['Rough texture','More grit, strain and material detail','More organic rough texture, layered material detail, forceful and gritty, no bright synthetic sheen.'],['Dark resonance','A fuller body and short, ominous tail','Dark full resonant body with a short natural stone chamber tail, controlled bass, intimate not distant.']];
const animal=new Set(['chicken','chicken_hit']);const voice=new Set(['hero_effort','hero_pain','roar','death']);
for(const [group,duration,event] of effects){if(group.startsWith('menu_'))continue;for(let i=0;i<4;i++){
 const [name,description,direction]=variants[i];
 const special=animal.has(group)?['Natural close recording.','Lower fuller natural bird timbre, NOT a monster.','Rougher feather and breath detail, clearly a real chicken.','Slightly hollow natural chest resonance, realistic bird.'][i]:voice.has(group)?['Close dry chest voice.','Lower powerful chest resonance, natural human or creature voice.','Rougher strained breath and gravelly texture.','Deep resonant chest tone and short crypt room decay.'][i]:direction;
 const prompt='Dark sword-and-sorcery game SFX. No music, words or unrelated background. One event, immediate onset. '+event+' '+special;
 manifest.jobs.push({id:group+'-'+(i+1),group,label:group.replaceAll('_',' ').replace(/^./,c=>c.toUpperCase()),name,description:event+' '+description.toLowerCase()+'.',duration,prompt});
}}
for(const group of ['music_menu','music_game'])for(let i=0;i<4;i++){
 const moods=group==='music_menu'?['Slow doom','Iron procession','Subterranean dread','War altar']:['Crushing groove','Low-end assault','War march','Relentless siege'];
 const riffs=['Slow thick sustained chords and a crushing half-time riff','Syncopated palm-muted low chugs with a memorable dark motif','Sparse ominous bass-heavy guitar drones alternating with massive riffs','Dense rolling low-register riffs and thunderous tom-driven drums'];
 const prompt='Instrumental dark sword-and-sorcery game metal. DEEP BASSY downtuned baritone guitars dominate, thick low distorted riffs, bass guitar doubling the roots, powerful natural drums. No vocals, choir, bright solos or synth leads. '+(group==='music_menu'?'Brooding doom metal at 80 BPM. ':'Driving combat groove metal at 120 BPM. ')+riffs[i]+'. D minor, ancient battlefield atmosphere. Seamless repeating loop structure, no intro or ending, compatible downbeats at beginning and end. Leave space for game sound effects.';
 manifest.jobs.push({id:group+'-'+(i+1),group,label:group==='music_menu'?'Menu music':'Gameplay music',name:moods[i],description: riffs[i]+'. '+(group==='music_menu'?'Brooding 80 BPM.':'Driving 120 BPM.'),duration:60000,music:true,prompt});
}
// Stable retryable manifest; never contains credentials.
manifest.jobs=[...new Map(manifest.jobs.map(j=>[j.id,j])).values()];
fs.writeFileSync(folder+'/manifest.json',JSON.stringify(manifest,null,2));
const env=fs.readFileSync('.env.local','utf8');const key=env.match(/^ELEVENLABS_API_KEY\s*=\s*(.+)$/m)?.[1].trim().replace(/^['"]|['"]$/g,'');if(!key)throw Error('Missing local credential');
let cursor=0,failed=0;
async function worker(){while(cursor<manifest.jobs.length){const j=manifest.jobs[cursor++];const raw=folder+'/'+j.id+'-source.mp3',out=folder+'/'+j.id+'.mp3';if(fs.existsSync(out))continue;try{
 if(!fs.existsSync(raw)){const body=j.music?{prompt:j.prompt,music_length_ms:j.duration,force_instrumental:true}:{text:j.prompt,duration_seconds:j.duration,prompt_influence:.7,model_id:'eleven_text_to_sound_v2'};
 const r=await fetch('https://api.elevenlabs.io/v1/'+(j.music?'music':'sound-generation')+'?output_format=mp3_44100_128',{method:'POST',headers:{'xi-api-key':key,'Content-Type':'application/json'},body:JSON.stringify(body),signal:AbortSignal.timeout(240000)});
 if(!r.ok){const e=await r.json().catch(()=>({}));console.log(j.id+' HTTP '+r.status+' '+(e.detail?.status||''));failed++;continue;}fs.writeFileSync(raw,Buffer.from(await r.arrayBuffer()));}
 let args=['-af','silenceremove=start_periods=1:start_duration=0.005:start_threshold=-45dB,loudnorm=I=-18:TP=-2:LRA=7,afade=t=in:d=0.003'];
 if(j.music){const d=Number(execFileSync('ffprobe',['-v','error','-show_entries','format=duration','-of','default=nw=1:nk=1',raw],{encoding:'utf8',windowsHide:true}));const cross=2;
 args=['-filter_complex',`[0:a]asplit=3[m][t][h];[m]atrim=start=${cross}:end=${d-cross},asetpts=PTS-STARTPTS[mid];[t]atrim=start=${d-cross},asetpts=PTS-STARTPTS[tail];[h]atrim=end=${cross},asetpts=PTS-STARTPTS[head];[tail][head]acrossfade=d=${cross}:c1=tri:c2=tri[join];[mid][join]concat=n=2:v=0:a=1,loudnorm=I=-19:TP=-2:LRA=9[out]`,'-map','[out]'];}
 execFileSync('ffmpeg',['-hide_banner','-loglevel','error','-y','-i',raw,...args,'-c:a','libmp3lame','-b:a','192k',out],{windowsHide:true});console.log('Prepared '+j.id);
 }catch{failed++;console.log(j.id+' generation/preparation failed');}}}
await Promise.all([worker(),worker()]);if(failed)process.exitCode=1;

fs.mkdirSync("godot/audio_options",{recursive:true});
for(const j of manifest.jobs){const file=folder+"/"+j.id+".mp3";if(fs.existsSync(file))fs.copyFileSync(file,"godot/audio_options/"+j.id+".mp3");}
fs.copyFileSync(folder+"/manifest.json","godot/audio_options/manifest.json");
