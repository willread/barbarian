import fs from 'node:fs';
import {spawnSync} from 'node:child_process';
const directory='soundboard/ending-music';
fs.mkdirSync(directory,{recursive:true});
const key=fs.readFileSync('.env.local','utf8').match(/^ELEVENLABS_API_KEY\s*=\s*(.+)$/m)?.[1].trim().replace(/^['"]|['"]$/g,'');
if(!key)throw Error('ElevenLabs key is not configured');
const common='Instrumental 22-second ending cue for a dark sword-and-sorcery game. A barbarian walks away from a burning fortress into the sunset with his rescued goat. Tender, weathered, quietly hopeful. Breath-rich acoustic PAN FLUTES are the unmistakable lead instrument, natural woody breath and human phrasing. Serious emotional resolution, not comedy. Start with space, introduce a memorable little melody early, gently warm and open by 12 seconds, leave the pan flute resting between 18 and 20 seconds for one short spoken line (DO NOT generate any voice), resolve with a final soft answer and natural decay by 22 seconds. No vocals or choir, no sound effects, no busy drums, no combat metal, no glossy spa production. ';
const jobs=[
 {id:'homeward-embers',name:'Homeward I — Embers',description:'Intimate pan flute and fingerpicked guitar; bittersweet, then warm.',detail:'68 BPM feel, D Dorian. Sparse close-recorded pan-flute three-note motif and dry fingerpicked nylon guitar. Low cello drone only at the beginning. Small, intimate, exhausted but relieved. Gradually resolve the initial minor shadow into a warm open guitar chord. No percussion.'},
 {id:'homeward-highlands',name:'Homeward II — Highlands',description:'Open-air folk melody, plucked strings and a gentle walking pulse.',detail:'72 BPM feel, G Mixolydian. Earthy wooden pan flute in a lilting folk phrase, restrained steel-string acoustic guitar and very sparse low hand-drum heartbeat. Wide open hills at sunset. A grounded walking pulse, noble and rustic, no jaunty dance, no orchestra.'},
 {id:'homeward-stillwater',name:'Homeward III — Stillwater',description:'Spacious solo pan flute, soft harp and long quiet pauses.',detail:'Free-time around 60 BPM, A minor moving toward C major warmth. Exposed low-register breathy pan flute, widely spaced small harp notes, almost inaudible bowed bass. Most minimal version, poignant silences, a fragile descending phrase answered by one hopeful rising note. No percussion or pads.'},
 {id:'homeward-lastlight',name:'Homeward IV — Last Light',description:'A fuller farewell with layered pan flutes and warm acoustic strings.',detail:'70 BPM feel, E Dorian resolving toward G major. Pan-flute solo begins alone, then a second pan flute answers in gentle harmony, acoustic guitar and restrained warm cello/viola sustain. Small chamber-folk scale, richer and more uplifting by the reunion, never a huge orchestra. No percussion.'}
].map(j=>({...j,prompt:common+j.detail,source:j.id+'-source.mp3',file:j.id+'.ogg',duration:22,loop:false}));
const manifest={provider:'ElevenLabs',model:'music_v1',collection:'Ending · Homeward',jobs};
fs.writeFileSync(directory+'/manifest.json',JSON.stringify(manifest,null,2)+'\n');
let cursor=0;
async function worker(){while(cursor<jobs.length){const job=jobs[cursor++],file=directory+'/'+job.source;
 if(!fs.existsSync(file)){
  console.log('Generating '+job.name);
  const response=await fetch('https://api.elevenlabs.io/v1/music?output_format=mp3_44100_128',{method:'POST',headers:{'xi-api-key':key,'Content-Type':'application/json'},body:JSON.stringify({model_id:'music_v1',prompt:job.prompt,music_length_ms:22000,force_instrumental:true}),signal:AbortSignal.timeout(300000)});
  if(!response.ok)throw Error('Music generation HTTP '+response.status+' for '+job.id);
  fs.writeFileSync(file,Buffer.from(await response.arrayBuffer()));
 }
 const converted=spawnSync('ffmpeg',['-v','error','-y','-i',file,'-af','atrim=duration=22,afade=t=in:d=0.025,afade=t=out:st=21.3:d=0.7,loudnorm=I=-19:TP=-2:LRA=9','-ar','44100','-c:a','libvorbis','-q:a','6',directory+'/'+job.file],{encoding:'utf8',windowsHide:true});
 if(converted.status!==0)throw Error(converted.stderr);
 fs.copyFileSync(directory+'/'+job.file,'godot/audio_options/'+job.file);
 console.log('Ready '+job.name);
}}
await Promise.all([worker(),worker()]);
fs.writeFileSync('godot/audio_options/ending-music.json',JSON.stringify(manifest,null,2)+'\n');
