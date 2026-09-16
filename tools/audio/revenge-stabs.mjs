import fs from 'node:fs';
import {spawnSync} from 'node:child_process';
const directory='soundboard/cutscenes/stab-options';
fs.mkdirSync(directory,{recursive:true});
const key=fs.readFileSync('.env.local','utf8').match(/^ELEVENLABS_API_KEY\s*=\s*(.+)$/m)?.[1].trim().replace(/^['"]|['"]$/g,'');
if(!key)throw Error('ElevenLabs key is not configured');
const common='Isolated descending three-note sting: DUN, DUN, DUNNNNN. Exactly three attacks at 0, 0.4, 0.8 seconds, stepping DOWN in pitch, short short long. Final note decays to 3 seconds. No extra notes, voice or backing. ';
const jobs=[
 {id:'iron',name:'Iron',detail:'Dry mid-gain electric guitar power chords. Warm rough tube amp, tight two short chords then one deep ringing chord. Understated classic heavy-rock menace. No drums.'},
 {id:'doom',name:'Doom',detail:'Low downtuned electric guitar with thick fuzzy amp tone. Three descending power chords, spacious and weighty, final note blooms into a dark low sustain. No percussion, no piercing high frequencies.'},
 {id:'omen',name:'Omen',detail:'Low bowed cello and bass trombone in unison, short short long descending chords. Vintage gothic cinematic DUN DUN DUNNNN. Dry attacks, dark woody brass sound, tiny room decay. No guitar, no drums.'},
 {id:'hex',name:'Hex',detail:'Twangy baritone electric guitar with a little spring reverb and gritty edge. Three clearly descending ominous notes, short short long. Dark western meets sword-and-sorcery, final low note hangs in the air. No drums.'}
].map(j=>({...j,prompt:common+j.detail,file:j.id+'.mp3',source:j.id+'-source.mp3'}));
fs.writeFileSync(directory+'/manifest.json',JSON.stringify({provider:'ElevenLabs',model:'eleven_text_to_sound_v2',jobs},null,2)+'\n');
let cursor=0;
async function worker(){while(cursor<jobs.length){const job=jobs[cursor++];
 const response=await fetch('https://api.elevenlabs.io/v1/sound-generation?output_format=mp3_44100_128',{method:'POST',headers:{'xi-api-key':key,'Content-Type':'application/json'},body:JSON.stringify({text:job.prompt,duration_seconds:3,prompt_influence:.65,model_id:'eleven_text_to_sound_v2'}),signal:AbortSignal.timeout(180000)});
 if(!response.ok){const error=await response.json();throw Error('Generation HTTP '+response.status+' for '+job.id+': '+JSON.stringify(error.detail));}
 fs.writeFileSync(directory+'/'+job.source,Buffer.from(await response.arrayBuffer()));
 const result=spawnSync('ffmpeg',['-v','error','-y','-i',directory+'/'+job.source,'-af','afade=t=out:st=2.4:d=0.6,loudnorm=I=-19:TP=-3:LRA=7','-ar','44100','-c:a','libmp3lame','-q:a','2',directory+'/'+job.file],{encoding:'utf8',windowsHide:true});
 if(result.status!==0)throw Error(result.stderr);
 console.log('Ready '+job.name);
}}
await Promise.all([worker(),worker()]);
