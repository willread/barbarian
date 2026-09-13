import fs from 'node:fs';
import {execFileSync} from 'node:child_process';
const designs=[
['Meaty hammerblow','Dense wet meat impact with a short low thump.','A single extremely heavy blunt strike into a thick slab of raw meat: immediate bassy THUD, compact wet compression, brief sticky release.'],
['Rib crusher','Brittle ribs break beneath a deep fleshy impact.','One brutal impact on a fleshy rib cage: deep rounded body thud followed immediately by two tiny brittle rib fractures and a damp squelch.'],
['Deep cleave','Heavy blade contact and a short wet tear.','One heavy cleaver sinks into thick raw meat: abrupt low chunky CHUNK, dense wet split, short fibrous tear ending dead. Contact only, absolutely no blade swoosh.'],
['Gut punch','Soft visceral collapse with substantial bass.','One powerful punch into a soaked heavy meat sack: low hollow WHUMP with a thick internal liquid churn and a tiny wet slap, compact and violent.'],
['Skull crunch','Hard dry crunch with a dark wet body.','One crushing blow to a monster skull: deep solid KLOCK, coarse bone crunch, tiny damp debris fall. Heavy and tactile rather than metallic.'],
['Tendon rip','A quick dense hit followed by fibrous tearing.','Single close combat impact: weighty low THOCK into flesh followed by one short gritty tendon tear and sticky snap.'],
['Wet backbreaker','Broad low crack and compressed flesh.','One massive blow crushing a bone inside thick muscle: bassy padded slam, broad woody bone crack, compressed wet pulp.'],
['Butcher block','Short percussive chop, thick and grounded.','One butcher cleaver impact on a heavy raw carcass resting on wood: dark low CHOCK, wet meat compression, tiny dry wooden undertone. No swing before contact.'],
['Organ rupture','Muffled internal burst under a heavy hit.','One brutal body impact ruptures a fluid filled organ: muted bass THUMP, short thick bubbling splat and immediate silence.'],
['Armor and flesh','Dull armor dent backed by a gruesome crunch.','One heavy blow dents leather covered armor into meat: dull low knock, coarse crunch, compact wet squish underneath. No ringing metal.'],
['Bone shear','Sharp small fracture above a bassy meat hit.','One powerful strike shears a thick bone inside a raw joint: bassy meaty THUD with one tight dry fracture and a very short sticky recoil.'],
['Pulpy execution','A deep crushing impact with a restrained splatter.','One devastating heavy weapon contact with a thick carcass: deep dense CRUMP, pulpy wet crush and several tiny droplets, all tightly clustered as one impact.']
];
const dir='soundboard/enemy-impact';fs.mkdirSync(dir,{recursive:true});
const key=fs.readFileSync('.env.local','utf8').match(/^ELEVENLABS_API_KEY\s*=\s*(.+)$/m)?.[1].trim().replace(/^['"]|['"]$/g,'');
if(!key)throw Error('Missing local credential');
const jobs=[];
for(let i=0;i<designs.length;i++){
 const [name,description,detail]=designs[i],id=`enemy-impact-${i+1}`;
 const prompt=`${detail} Dark fantasy melee contact. Close dry gruesome foley, strong bass and low-mid weight, subdued treble. Immediate onset, decay under one second. ONE hit only. No swoosh, sequence, vocals, music, ambience, riser or reverb.`;
 const raw=`${dir}/${id}-source.mp3`;
 if(!fs.existsSync(raw)){
 const r=await fetch('https://api.elevenlabs.io/v1/sound-generation?output_format=mp3_44100_128',{method:'POST',headers:{'xi-api-key':key,'Content-Type':'application/json'},body:JSON.stringify({text:prompt,duration_seconds:1,prompt_influence:.9,model_id:'eleven_text_to_sound_v2'}),signal:AbortSignal.timeout(180000)});
 if(!r.ok){const error=await r.json(); console.error(JSON.stringify(error.detail));throw Error(`Generation HTTP ${r.status}`);}
 fs.writeFileSync(raw,Buffer.from(await r.arrayBuffer()));
 }
 execFileSync('ffmpeg',['-v','error','-y','-i',raw,'-af','silenceremove=start_periods=1:start_duration=0.005:start_threshold=-45dB,loudnorm=I=-18:TP=-2:LRA=7,afade=t=in:d=0.003','-c:a','libvorbis','-q:a','5',`godot/audio_options/${id}.ogg`],{windowsHide:true});
 jobs.push({id,group:'enemy_impact',label:'Enemy hit impacts · random selection',name,description,prompt,duration:1});
 console.log(`Prepared ${id}`);
 fs.writeFileSync(`${dir}/manifest.json`,JSON.stringify({jobs},null,2));
}
const manifest=JSON.parse(fs.readFileSync('godot/audio_options/manifest.json','utf8'));
manifest.jobs=manifest.jobs.filter(j=>j.group!=='enemy_impact');manifest.jobs.push(...jobs);
fs.writeFileSync('godot/audio_options/manifest.json',JSON.stringify(manifest,null,2));

