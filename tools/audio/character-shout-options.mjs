import fs from 'node:fs';
import {spawnSync} from 'node:child_process';
const directory='soundboard/character-shout-options-v2';
fs.mkdirSync(directory,{recursive:true});
const key=fs.readFileSync('.env.local','utf8').match(/^ELEVENLABS_API_KEY\s*=\s*(.+)$/m)?.[1].trim().replace(/^['"]|['"]$/g,'');
if(!key)throw Error('Audio generation key is not configured');
const characters=[
 ['marauder','Axe Marauder','Rough, mid-low male voice. A vicious, reckless berserker.', ['A short feral battle yell.','A sharp angry attack bark.','A hoarse shout of wild excitement.','A snarling shout of rage.']],
 ['warden','Iron Warden','Strong mature male baritone. An intimidating, disciplined warlord.', ['A short commanding battle shout.','A forceful, contemptuous attack cry.','A deep defiant challenge.','A controlled shout breaking into fury.']],
 ['bearer','Bomb Thrower','High, scratchy male voice. A nasty, frantic little brute.', ['A short spiteful attack screech.','A sharp excited battle yelp.','A raspy, taunting shout.','A furious cracked yell.']],
 ['king','Drowned King','Very deep, hoarse male voice. An ancient exhausted king with slow, bitter anger.', ['A short mournful battle bellow.','A weary growl rising into an angry shout.','A low, menacing challenge.','A strained roar of bitter rage.']],
 ['saint','Kiln Saint','Huge bass male voice, coarse and powerful. A relentless, fanatical giant.', ['A short thunderous battle bellow.','A guttural attack roar with tremendous effort.','A deep furious shout.','A rumbling growl opening into a forceful bellow.']],
];
const jobs=characters.flatMap(([character,label,voice,variants])=>variants.map((delivery,i)=>({id:`${character}-${i+1}`,character,label,prompt:`${voice} ${delivery} One nonverbal vocalization, about one second. Dry isolated voice, no words, music or added effects.`,file:`${character}-${i+1}.mp3`})));
fs.writeFileSync(`${directory}/manifest.json`,JSON.stringify({provider:'ElevenLabs',model:'eleven_text_to_sound_v2',previewOnly:true,jobs},null,2)+'\n');
function convert(args){const r=spawnSync('ffmpeg',['-v','error','-y',...args],{encoding:'utf8',windowsHide:true});if(r.status!==0)throw Error('Audio conversion failed');}
let cursor=0;
async function worker(){while(cursor<jobs.length){
 const job=jobs[cursor++],source=`${directory}/${job.id}-source.mp3`;
 if(!fs.existsSync(source)){
  const response=await fetch('https://api.elevenlabs.io/v1/sound-generation?output_format=mp3_44100_128',{method:'POST',headers:{'xi-api-key':key,'Content-Type':'application/json'},body:JSON.stringify({text:job.prompt,duration_seconds:1.5,prompt_influence:.5,model_id:'eleven_text_to_sound_v2'}),signal:AbortSignal.timeout(180000)});
  if(!response.ok)throw Error(`Generation HTTP ${response.status} for ${job.id}`);
  fs.writeFileSync(source,Buffer.from(await response.arrayBuffer()));
 }
 convert(['-i',source,'-af','silenceremove=start_periods=1:start_duration=0.005:start_threshold=-45dB,loudnorm=I=-19:TP=-3:LRA=7,apad,atrim=duration=1.5,afade=t=out:st=1.4:d=0.1','-ar','44100','-c:a','libmp3lame','-q:a','2',`${directory}/${job.file}`]);
 console.log(`Ready ${job.id}`);
}}
await Promise.all([worker(),worker()]);
for(const [character] of characters){
 const inputs=Array.from({length:4},(_,i)=>['-i',`${directory}/${character}-${i+1}.mp3`]).flat();
 convert([...inputs,'-filter_complex','[0:a]apad=pad_dur=1[a];[1:a]apad=pad_dur=1[b];[2:a]apad=pad_dur=1[c];[a][b][c][3:a]concat=n=4:v=0:a=1[out]','-map','[out]','-c:a','libmp3lame','-q:a','2',`${directory}/${character}-preview.mp3`]);
}
console.log('CHARACTER_SHOUTS_READY');
