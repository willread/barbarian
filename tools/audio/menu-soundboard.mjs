import fs from 'node:fs';
import {execFileSync} from 'node:child_process';
const folder='soundboard';
const style='Dark fantasy menu Foley. Heavy stone and aged iron, deep bass and dense low mids. One isolated impact, immediate onset, short decay. No music, voices, bleeps or risers. ';
const groups=[
 ['selection','Selection / highlight',[
 ['Stone detent','A compact stone knock with a gritty edge.','One short dense stone detent locking into a notch. Dry granite knock, low chesty thock and very brief grit.',.6],
 ['Iron catch','A blunt iron clunk with a short bass tail.','One thick iron catch engaging, dull heavy low clunk with restrained metallic rattle. Tight and tactile.',.6],
 ['Crypt latch','A hollow, wooden-and-stone tomb latch.','One ancient oak and stone crypt latch shifting and seating, hollow dark low knock and brief dusty scrape.',.7],
 ['Basalt nudge','A muted rock movement ending in a low bump.','One very short rough basalt block nudge ending in a deep rounded bump, dense compressed stone body, little treble.',.65]]],
 ['activation','Click / activate',[
 ['Seal breaker','A hard stone crack over a deep impact.','One thick stone seal punched inward, sharp compact rocky crack atop a heavy bass thud, small debris tail.',1.0],
 ['Iron verdict','A decisive hammer blow to thick iron.','One heavy hammer strikes a massive dull iron plate, deep low metallic THUNK, no ringing high ping, short resonant decay.',.9],
 ['Tomb lock','A massive locking bolt slams home.','One huge ancient iron tomb bolt slams home against stone. Layered mechanical clack and thick low end impact, brief chain settle.',1.0],
 ['Obsidian crush','A dense crushing crunch with a bass pulse.','One dense obsidian stone crushed under a heavy press, visceral low crunchy impact with a short deep pressure thump, no explosion.',.9]]],
 ['drop','Menu item landing',[
 ['Monolith','A giant stone slab hits bedrock.','One massive carved granite monolith drops onto bedrock. Huge heavy initial THUD, deep sub bass weight, gritty stone fracture and brief settling chips. No preceding whoosh.',1.5],
 ['Iron altar','A heavy iron block lands on stone.','One enormous iron altar lands on stone floor, crushing low metallic KLANG THUNK, deep dark resonant body with grit and compact settling rattle. No bright ringing.',1.5],
 ['Buried titan','A subterranean thump with dusty rubble.','One colossal stone foot slams packed earth over bedrock, thunderously heavy muffled bass thump, rough midrange impact, dusty rubble cascading briefly.',1.6],
 ['Sarcophagus','A tomb lid slams shut with a second settling knock.','One massive stone sarcophagus lid drops shut. Crushing low stone-on-stone thunk then one much quieter settling knock, brief grit, cavernous but controlled low resonance.',1.6]]]
];
const jobs=groups.flatMap(([group,label,items])=>items.map(([name,description,prompt,duration],i)=>({id:group+'-'+(i+1),group,label,name,description,duration,prompt:style+prompt})));
fs.writeFileSync(folder+'/manifest.json',JSON.stringify({provider:'ElevenLabs',date:new Date().toISOString(),jobs},null,2));
const env=fs.readFileSync('.env.local','utf8');
const key=env.match(/^ELEVENLABS_API_KEY\s*=\s*(.+)$/m)?.[1].trim().replace(/^['"]|['"]$/g,'');
if(!key)throw Error('Missing local credential');
let cursor=0,failed=0;
async function worker(){while(cursor<jobs.length){const j=jobs[cursor++];const raw=folder+'/'+j.id+'-source.mp3';try{
if(!fs.existsSync(raw)){
 const r=await fetch('https://api.elevenlabs.io/v1/sound-generation?output_format=mp3_44100_128',{method:'POST',headers:{'xi-api-key':key,'Content-Type':'application/json'},body:JSON.stringify({text:j.prompt,duration_seconds:j.duration,prompt_influence:.75,model_id:'eleven_text_to_sound_v2'}),signal:AbortSignal.timeout(180000)});
 if(!r.ok){const error=await r.json().catch(()=>({})); console.log(j.id+' HTTP '+r.status+' '+(error.detail?.status||''));failed++;continue;}
 fs.writeFileSync(raw,Buffer.from(await r.arrayBuffer()));
}
execFileSync('ffmpeg',['-hide_banner','-loglevel','error','-y','-i',raw,'-af','silenceremove=start_periods=1:start_duration=0.005:start_threshold=-45dB,loudnorm=I=-18:TP=-2:LRA=7,afade=t=in:d=0.003','-c:a','libmp3lame','-b:a','192k',folder+'/'+j.id+'.mp3'],{windowsHide:true});
console.log('Prepared '+j.id);
}catch{failed++;console.log(j.id+' generation or preparation failed');}}}
await Promise.all([worker(),worker()]);
if(failed)process.exitCode=1;
