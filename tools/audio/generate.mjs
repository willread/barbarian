import fs from 'node:fs';
import {execFileSync} from 'node:child_process';
const env=fs.readFileSync('.env.local','utf8');
const key=env.match(/^ELEVENLABS_API_KEY\s*=\s*(.+)$/m)?.[1].trim().replace(/^['"]|['"]$/g,'');
if(!key)throw Error('ElevenLabs key missing');
const output='godot/audio';fs.mkdirSync(output,{recursive:true});
const style='Dark sword-and-sorcery action game. Realistic close dry Foley, worn natural materials, weighty but not exaggerated. No music, no voices or background noise unless specified. One isolated event, immediate onset, short natural decay. ';
const effects=[
 ['sword',.7,'One fast steel sword swing through air, narrow sharp whoosh.'],
 ['axe',.8,'One forceful heavy axe swing through air, broad low whoosh.'],
 ['flesh',.7,'One sword striking flesh: solid short thud with wet cutting detail.'],
 ['heavy_hit',.9,'One heavy axe chop into flesh, dense low impact with brief wet tearing.'],
 ['bone',.7,'One hard strike breaking dry bone, brittle crack with fragments.'],
 ['shield',.8,'One heavy sword blocked by an old iron shield, dull clang, straps creak, short metallic tail.'],
 ['body_fall',1.0,'Heavy human body falls onto stone, solid thump and leather equipment settling.'],
 ['foot_stone',.5,'One heavy leather boot footstep on gritty stone.'],
 ['foot_earth',.5,'One heavy leather boot footstep on dry packed earth.'],
 ['landing',1.1,'Powerful weapon slam into stone ground, heavy impact then loose grit and dust scattering.'],
 ['bow_draw',.7,'Arrow pulled from leather quiver, feather rustle then wooden bow flex under string tension.'],
 ['bow_release',.5,'Wooden longbow string snaps forward releasing arrow, taut dry twang, short swift hiss.'],
 ['arrow_hit',.5,'Arrow punctures flesh, tight dry puncture and tiny wet thud.'],
 ['arrow_ground',.5,'Iron arrowhead hits gritty stone and wooden shaft vibrates briefly.'],
 ['hero_effort',.5,'One deep adult male warrior effort grunt, nonverbal, forceful breath, no words.'],
 ['hero_pain',.7,'One deep adult male warrior short hurt grunt, nonverbal, restrained and realistic.'],
 ['roar',1.2,'One menacing heavy armored undead warrior coarse battle roar, nonverbal, no words.'],
 ['death',1.5,'One deep male warrior final strained death cry and expelled breath, no words.'],
 ['lightning',1.8,'Violent natural lightning crack, branching electrical snaps and short deep thunder body.'],
 ['fire',2.5,'Body ignites in a short turbulent burst of realistic fire, irregular crackles fading to embers.'],
 ['chicken',.9,'A real chicken making two brief natural clucks, close isolated farm animal recording, no background.'],
 ['chicken_hit',.7,'A real startled chicken gives one short squawk with a wing flutter, no background.'],
 ['pickup',.7,'Brief leather rustle and satisfying small organic pickup sound, subtle warm low resonance.'],
 ['menu_land',.8,'Massive carved stone slab lands heavily, compact bass thunk, gritty scrape and settling chips.'],
 ['menu_select',.5,'Small heavy stone sliding a few centimeters, short coarse scrape and low knock.'],
 ['transition',1.2,'Ominous low rush of air through an ancient crypt, compact dark whoosh, no voices.']
];
const common='Instrumental dark sword-and-sorcery game metal. DEEP BASSY down-tuned baritone guitars, thick low-register distorted riffs, powerful distorted bass doubling riffs, natural heavy drums. Guitars dominate. No vocals, no choir, no synthesizer lead, no bright shrill solo. Cohesive D minor mood, ominous ancient battlefield. Steady repeating arrangement designed as a seamless game loop, no intro or ending, start and end on compatible downbeats. ';
const jobs=effects.map(([id,duration,text])=>({id,endpoint:'sound-generation',body:{text:style+text,duration_seconds:duration,prompt_influence:.65,model_id:'eleven_text_to_sound_v2'}}));
jobs.push({id:'music_menu',endpoint:'music',body:{prompt:common+'Slow crushing doom-metal groove at 80 BPM, spacious weighty half-time drums, memorable low four-note motif. Brooding anticipation.',music_length_ms:60000,force_instrumental:true}});
jobs.push({id:'music_game',endpoint:'music',body:{prompt:common+'Driving palm-muted low guitar groove at 120 BPM, relentless heavy drums, dark heroic low four-note motif. Energetic battle backing with room for combat sound effects.',music_length_ms:60000,force_instrumental:true}});
fs.writeFileSync(output+'/generation-manifest.json',JSON.stringify({provider:'ElevenLabs',date:new Date().toISOString(),jobs},null,2));
let cursor=0,failed=0;
async function worker(){while(cursor<jobs.length){const job=jobs[cursor++];const file=output+'/'+job.id+'.mp3';if(fs.existsSync(file))continue;
 try{const response=await fetch('https://api.elevenlabs.io/v1/'+job.endpoint+'?output_format=mp3_44100_128',{method:'POST',headers:{'xi-api-key':key,'Content-Type':'application/json'},body:JSON.stringify(job.body),signal:AbortSignal.timeout(240000)});
 if(!response.ok){const body=await response.json().catch(()=>({}));console.log(job.id+' FAILED HTTP '+response.status+' '+(body.detail?.status||''));failed++;continue;}
 fs.writeFileSync(file,Buffer.from(await response.arrayBuffer()));console.log('Generated '+job.id);
 }catch{console.log(job.id+' FAILED network/timeout');failed++;}
}}
await Promise.all([worker(),worker()]);
if(failed)process.exitCode=1;
