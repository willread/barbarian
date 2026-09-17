import fs from 'node:fs';
import {spawnSync} from 'node:child_process';
const directory='soundboard/enemy-voice-options-v1';
fs.mkdirSync(directory,{recursive:true});
const key=fs.readFileSync('.env.local','utf8').match(/^ELEVENLABS_API_KEY\s*=\s*(.+)$/m)?.[1].trim().replace(/^['"]|['"]$/g,'');
if(!key)throw Error('ElevenLabs key is not configured');
const characters=[
 ['marauder','Axe Marauder','A feral muscular human raider, raw adult male voice with coarse throat rasp and furious breath. Aggressive mid-low human register, not supernatural or bovine.',[
  ['Berserker bark','One explosive rasping RAAH battle bark on one breath.'],['Savage charge','One wild open-vowel battle yell, hoarse and slightly cracked.'],['Blood rage','A clipped growled HAH swelling into a brief furious yell.']]],
 ['warden','The Iron Warden','A proud crowned human warlord in brass plate. Powerful mature male baritone, disciplined commanding authority, natural human chest resonance, controlled grit. No monster growling.',[
  ['Commanding challenge','One thunderous controlled HAAH challenge, firm voiced finish.'],['Execution cry','One low forceful RAAH execution shout with restrained rasp.'],['Royal fury','One fierce short open-vowel battle cry, regal authority breaking into anger.']]],
 ['bearer','Bomb Thrower','A compact furnace demon carrying burning bombs. High-mid cracked demonic throat, hot wheezing rasp and papery ember crackle woven into the voice. Agile and spiteful, smaller and higher than a furnace giant.',[
  ['Ember screech','One hot cracked screech with a brief sizzling breath tail.'],['Coal hack','One hacking dry demonic bark followed by a tiny ember-like rasp.'],['Hell scream','One sharp rising hellish shriek, fierce nasal edge and scorched throat.']]],
 ['king','The Drowned King','An enormous drowned undead monarch from a black swamp. Deep waterlogged male throat, wet bubbling resonance and congested gurgle, exhausted ancient menace. Organic wet voice, no ocean ambience.',[
  ['Drowned challenge','One deep gurgling bellow emerging from a flooded throat.'],['Sunken wrath','A low choking growl that opens into a wet resonant roar.'],['Blackwater cry','One mournful bass howl with irregular watery throat flutter.']]],
 ['saint','The Kiln Saint','A towering possessed walking furnace. Vast cavernous sub-bass voice through a hollow iron chest, rough combustion breath and deep metallic resonance, slow and immense. Lower and heavier than the smaller bomb demon.',[
  ['Furnace bellow','One enormous low furnace-throat bellow, heavy iron resonance and short hot exhale.'],['Iron abyss','One ominous sub-bass groan erupting into a compact roaring cry.'],['Kiln wrath','One crushing deep demonic roar with a grainy burning breath tail.']]],
];
const jobs=characters.flatMap(([character,label,identity,variants])=>variants.map(([name,direction],index)=>({
 id:`${character}-${index+1}`,character,label,name,duration:2.0,
 prompt:`${identity} ${direction} Immediate onset, under 1.3s cry. Dry isolated voice. No words, music, weapons or ambience.`,
 file:`${character}-${index+1}.mp3`,source:`${character}-${index+1}-source.mp3`
})));
fs.writeFileSync(directory+'/manifest.json',JSON.stringify({provider:'ElevenLabs',model:'eleven_text_to_sound_v2',previewOnly:true,jobs},null,2)+'\n');
function convert(args){const r=spawnSync('ffmpeg',['-v','error','-y',...args],{encoding:'utf8',windowsHide:true});if(r.status!==0)throw Error('Audio conversion failed');}
let cursor=0;
async function worker(){while(cursor<jobs.length){
 const job=jobs[cursor++],source=directory+'/'+job.source;
 if(!fs.existsSync(source)){
  const response=await fetch('https://api.elevenlabs.io/v1/sound-generation?output_format=mp3_44100_128',{method:'POST',headers:{'xi-api-key':key,'Content-Type':'application/json'},body:JSON.stringify({text:job.prompt,duration_seconds:job.duration,prompt_influence:.75,model_id:'eleven_text_to_sound_v2'}),signal:AbortSignal.timeout(180000)});
  if(!response.ok){const error=await response.json();throw Error('Generation HTTP '+response.status+' for '+job.id+': '+JSON.stringify(error.detail));}
  fs.writeFileSync(source,Buffer.from(await response.arrayBuffer()));
 }
 convert(['-i',source,'-af','silenceremove=start_periods=1:start_duration=0.005:start_threshold=-45dB,loudnorm=I=-19:TP=-3:LRA=7,apad,atrim=duration=2,afade=t=out:st=1.8:d=0.2','-ar','44100','-c:a','libmp3lame','-q:a','2',directory+'/'+job.file]);
 console.log('Ready '+job.id+' '+job.name);
}}
await Promise.all([worker(),worker()]);
for(const [character] of characters){
 convert(['-i',`${directory}/${character}-1.mp3`,'-i',`${directory}/${character}-2.mp3`,'-i',`${directory}/${character}-3.mp3`,'-filter_complex','[0:a]apad=pad_dur=1[a];[1:a]apad=pad_dur=1[b];[a][b][2:a]concat=n=3:v=0:a=1[out]','-map','[out]','-c:a','libmp3lame','-q:a','2',`${directory}/${character}-preview.mp3`]);
}
console.log('ENEMY_VOICES_READY: 15 variants and 5 ordered preview reels');
