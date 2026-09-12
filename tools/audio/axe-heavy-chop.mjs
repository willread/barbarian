import fs from 'node:fs';
import {execFileSync} from 'node:child_process';
const options=[
 ['Heavy chop - tighter','A compact deep chop with a shorter air burst.','A large heavy axe swings downward once. Short deep FWOOM of displaced air, dense lower-mid body, tight accelerating onset and abrupt stop. Compact and weighty, less airy than a sword. No collision, impact, whistle, multiple swings or sustained wind. Isolated dark fantasy game sound, close dry recording.'],
 ['Heavy chop - darker','A darker, bassier version with subdued treble.','One large axe makes a powerful descending swing. A short dark FWUM of displaced air with thick bass and low-mid weight, softly gritty edge and a decisive short end. Actual heavy blade moving through air, not an impact. No bright whistle, clang, explosion, voice or long wind. Close dry dark fantasy effect.'],
 ['Heavy chop - rougher','The same low swing with a coarse rushing edge.','A massive axe swings downward once. Brief deep FWOOM with dense low-mid air displacement and a coarse dry rushing texture around it. Single heavy accelerating chop, abruptly ending. No contact, chopping wood, flesh, sword whistle, metal ringing, music or repeated swings. Close dark fantasy game recording.'],
 ['Heavy chop - weightier','A slightly broader low chop that still ends cleanly.','One weighty battle axe sweeps down through air. Short low FWOOM, a rounded heavy pressure pulse with dense lower-mid body, slight acceleration then a clean clipped end. Substantial physical blade mass without a hit sound. No sub-bass explosion, impact, high whistle, broad wind ambience, voice or music. Close dry recording.']
];
const directory='soundboard/axe-heavy-chop';fs.mkdirSync(directory,{recursive:true});
const key=fs.readFileSync('.env.local','utf8').match(/^ELEVENLABS_API_KEY\s*=\s*(.+)$/m)?.[1].trim().replace(/^['"]|['"]$/g,'');
if(!key)throw Error('Missing local credential');
const manifest=JSON.parse(fs.readFileSync('godot/audio_options/manifest.json','utf8'));
const jobs=[];
for(let i=0;i<options.length;i++){
 const [name,description,prompt]=options[i],id=`axe-${i+5}`,raw=`${directory}/${id}-source.mp3`;
 if(!fs.existsSync(raw)){
  const response=await fetch('https://api.elevenlabs.io/v1/sound-generation?output_format=mp3_44100_128',{method:'POST',headers:{'xi-api-key':key,'Content-Type':'application/json'},body:JSON.stringify({text:prompt,duration_seconds:.8,prompt_influence:.85,model_id:'eleven_text_to_sound_v2'}),signal:AbortSignal.timeout(180000)});
  if(!response.ok)throw Error(`Generation HTTP ${response.status}`);
  fs.writeFileSync(raw,Buffer.from(await response.arrayBuffer()));
 }
 execFileSync('ffmpeg',['-hide_banner','-loglevel','error','-y','-i',raw,'-af','silenceremove=start_periods=1:start_duration=0.005:start_threshold=-45dB,loudnorm=I=-18:TP=-2:LRA=7,afade=t=in:d=0.003','-c:a','libmp3lame','-b:a','192k',`godot/audio_options/${id}.mp3`],{windowsHide:true});
 jobs.push({id,group:'axe',label:'Axe',name,description,prompt,duration:.8});
 console.log(`Prepared ${id}`);
}
manifest.jobs=manifest.jobs.filter(j=>!jobs.some(n=>n.id===j.id));manifest.jobs.push(...jobs);
fs.writeFileSync('godot/audio_options/manifest.json',JSON.stringify(manifest,null,2));
fs.writeFileSync(`${directory}/manifest.json`,JSON.stringify({reference:'axe-1 / Heavy chop',jobs},null,2));
