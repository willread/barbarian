import fs from 'node:fs';
import {execFileSync} from 'node:child_process';
const key=fs.readFileSync('.env.local','utf8').match(/^ELEVENLABS_API_KEY\s*=\s*(.+)$/m)?.[1].trim().replace(/^['"]|['"]$/g,'');
if(!key)throw Error('ElevenLabs key is not configured');
const jobs=[
 ['oil-gurgle','Oil gurgle','Close realistic thick black oil bubbling in a small puddle. Irregular deep hollow glugs, small wet bubbles inflating and popping, viscous liquid slowly churning. Gross organic liquid Foley, intimate and detailed, restrained low end. Continuous seamless loop. No voice, music, synth tones, cartoon sounds or ambience.'],
 ['sticky-slurp','Sticky slurp','Disgusting sticky suction and wet slurping as several oily hands slowly pull through thick slime. Soft stretched squelches and sucking pops interspersed with small bubbling gurgles. Realistic close-miked liquid Foley, wet and slimy, no creature vocalization, speech, music, electronic sounds or rhythmic pulse. Continuous seamless loop.'],
 ['tar-bubbles','Tar bubbles','Small tar pool simmering with thick wet bubbles. Uneven bloops and rupturing viscous bubble membranes, tiny liquid spatters, occasional deeper gurgle. Realistic wet texture, dark fantasy game hazard, close dry recording, no wind, fire crackle, voices, tonal humming or music. Continuous seamless loop.'],
 ['sludge-churn','Sludge churn','Slow churning gelatinous black sludge, gross wet mouthlike suction without any actual voice. Thick liquid folds over itself with drawn-out slurps, soft sticky squishes and low bubbling. Organic physical Foley, not a monster growl. No speech, music, synth, cartoon boings or huge cinematic bass. Continuous seamless loop.']
];
const directory='studies/backgrounds/mire-v2/';
for(const [id,label,prompt] of jobs){
 const raw=directory+'eleven-'+id+'-source.mp3';
 if(!fs.existsSync(raw)){
  const response=await fetch('https://api.elevenlabs.io/v1/sound-generation?output_format=mp3_44100_128',{method:'POST',headers:{'xi-api-key':key,'Content-Type':'application/json'},body:JSON.stringify({text:prompt,duration_seconds:8,prompt_influence:.7,model_id:'eleven_text_to_sound_v2',loop:true})});
  if(!response.ok)throw Error('ElevenLabs generation HTTP '+response.status);
  fs.writeFileSync(raw,Buffer.from(await response.arrayBuffer()));
 }
 execFileSync('ffmpeg',['-hide_banner','-loglevel','error','-y','-i',raw,'-af','loudnorm=I=-20:TP=-3:LRA=8','-c:a','libvorbis','-q:a','5',directory+'eleven-'+id+'.ogg'],{windowsHide:true});
 console.log('Ready: '+label);
}
fs.writeFileSync(directory+'elevenlabs-options.json',JSON.stringify({provider:'ElevenLabs',model:'eleven_text_to_sound_v2',loop:true,jobs:jobs.map(([id,label,prompt])=>({id:'eleven-'+id,label,prompt}))},null,2));
