import fs from 'node:fs';
import {spawnSync} from 'node:child_process';
const directory='soundboard/short-shout-options-v1';
fs.mkdirSync(directory,{recursive:true});
const key=fs.readFileSync('.env.local','utf8').match(/^ELEVENLABS_API_KEY\s*=\s*(.+)$/m)?.[1].trim().replace(/^['"]|['"]$/g,'');
if(!key)throw Error('Audio generation key is not configured');
const prompts=[
 'One short, forceful male battle shout. Dry recording. No words or effects.',
 'One brief, rough, low-pitched aggressive yell. Dry recording. No words or effects.',
 'One sharp, raspy male attack cry, under one second. Dry recording. No words or effects.',
 'One short, deep male shout of effort. Dry recording. No words or effects.',
 'One brief, angry male yell. Dry recording. No words or effects.',
 'One loud, breathy male battle cry, under one second. Dry recording. No words or effects.',
 'One short, hoarse male shout. Dry recording. No words or effects.',
 'One quick, powerful male attack grunt. Dry recording. No words or effects.',
 'One brief, low male battle yell. Dry recording. No words or effects.',
 'One short, raw male cry of rage. Dry recording. No words or effects.',
 'One sharp, forceful male shout of effort. Dry recording. No words or effects.',
 'One brief, gravelly male battle shout. Dry recording. No words or effects.',
];
const jobs=prompts.map((prompt,i)=>({id:i+1,prompt,file:`shout-${i+1}.mp3`}));
fs.writeFileSync(`${directory}/manifest.json`,JSON.stringify({provider:'ElevenLabs',model:'eleven_text_to_sound_v2',previewOnly:true,jobs},null,2)+'\n');
function convert(args){const r=spawnSync('ffmpeg',['-v','error','-y',...args],{encoding:'utf8',windowsHide:true});if(r.status!==0)throw Error('Audio conversion failed');}
let cursor=0;
async function worker(){while(cursor<jobs.length){
 const job=jobs[cursor++],source=`${directory}/shout-${job.id}-source.mp3`;
 if(!fs.existsSync(source)){
  const response=await fetch('https://api.elevenlabs.io/v1/sound-generation?output_format=mp3_44100_128',{method:'POST',headers:{'xi-api-key':key,'Content-Type':'application/json'},body:JSON.stringify({text:job.prompt,duration_seconds:1.5,prompt_influence:.35,model_id:'eleven_text_to_sound_v2'}),signal:AbortSignal.timeout(180000)});
  if(!response.ok)throw Error(`Generation HTTP ${response.status} for shout ${job.id}`);
  fs.writeFileSync(source,Buffer.from(await response.arrayBuffer()));
 }
 convert(['-i',source,'-af','silenceremove=start_periods=1:start_duration=0.005:start_threshold=-45dB,loudnorm=I=-19:TP=-3:LRA=7,apad,atrim=duration=1.5,afade=t=out:st=1.4:d=0.1','-ar','44100','-c:a','libmp3lame','-q:a','2',`${directory}/${job.file}`]);
 console.log(`Ready shout ${job.id}`);
}}
await Promise.all([worker(),worker()]);
for(let start=1;start<=12;start+=4){
 const inputs=Array.from({length:4},(_,i)=>['-i',`${directory}/shout-${start+i}.mp3`]).flat();
 convert([...inputs,'-filter_complex','[0:a]apad=pad_dur=1[a];[1:a]apad=pad_dur=1[b];[2:a]apad=pad_dur=1[c];[a][b][c][3:a]concat=n=4:v=0:a=1[out]','-map','[out]','-c:a','libmp3lame','-q:a','2',`${directory}/preview-${start}-${start+3}.mp3`]);
}
console.log('SHORT_SHOUTS_READY');
