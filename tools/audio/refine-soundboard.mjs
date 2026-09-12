import fs from 'node:fs';
import {execFileSync} from 'node:child_process';
// Four independently designed performances per event, not global adjective variants.
const designs={
selection:[
['Stone detent','A short granite knock, followed by grit.','A small granite locking tooth drops into a stone notch. Instant dry TOK with a dense low middle, followed by a tiny crumble of grit. Very short, no slide or rushing air.'],
['Iron pawl','A thick, blunt mechanical clunk.','A heavy iron ratchet pawl snaps into one deep tooth. One blunt KLOCK, low metallic body, tiny loose-metal tick afterward. No ringing, scrape, swing or hiss.'],
['Oak peg','A hollow, bassy wooden knock.','A thick oak peg is driven once into a hollow ancient wooden chest. Rounded low wooden KUNK, woody cavity resonance dies quickly. No metal, wind or scraping.'],
['Buried stone','A muffled low bump with a granular crunch.','A dense rock drops a few centimeters into packed gravel. Short muffled DUM with pebbles crunching at contact. Bass-forward solid impact, no air sweep or sustained sound.']],
activation:[
['Breaking seal','A sharp mineral fracture over a deep thud.','A thick stone seal is punched straight through. Immediate loud CRACK over a compact bass THUD, then three small fragments patter. The fracture dominates, no blade swing or wind.'],
['Iron hammer','A deadened iron impact with low resonance.','A heavy blacksmith hammer strikes thick cold iron once. Hard blunt TANK attack, dark low metallic body, rapidly damped tail. No high bell ring, no preparatory swing.'],
['Tomb bolt','Two closely spaced mechanical clunks.','A massive tomb lock engages: thick iron bolt clacks, then seats with a deeper CLUNK 80 milliseconds later. Short chain rattle dies behind it. Mechanical and bassy, no wind.'],
['Crushed slate','A crunchy, compact stone collapse.','One fist-sized stack of slate crushed under a stone press. Abrupt brittle KRRACK layered on a dense low knock, small gritty settling tail. Crunchy rather than swishing; no explosion.']],
drop:[
['Monolith','A huge stone thud and scattered rubble.','A massive granite slab lands flat on bedrock. Immediate chesty BOOM-THUNK with a hard stone crack, then small rubble patters for half a second. Heavy low-frequency weight, no falling-air lead-in.'],
['Iron altar','A heavy metallic crash with a short rattle.','An enormous iron block drops onto a stone plinth. Blunt low KLONG, dense vibrating iron body, short loose rivet rattle. Dry powerful contact, dark resonance, no whoosh or bright ringing.'],
['Packed earth','A muffled seismic thump with grinding grit.','A giant stone foot stamps compacted soil. Deep muffled WHUM combined with a tight gritty crunch, a few stones settle. Earthy low impact with almost no metallic treble; no wind.'],
['Sarcophagus lid','A stone slam followed by a quieter settling knock.','A massive stone coffin lid slams shut. One crushing bass THUNK, then one much quieter knock as it settles. Short gravelly stone chatter. Clearly two contacts, no sweeping or airy texture.']],
sword:[
['Narrow cut','A tight, fast cutting-air snap.','A thin steel blade makes one very fast short horizontal swing. Focused FWT with a crisp leading snap and a low narrow air body lasting 180 milliseconds. No hit, ring, long hiss or magical tail.'],
['Backhand','A compact lower-register reverse swing.','A heavy sword makes one short backhand cut close to the microphone. Low tight WUP, quick pressure snap, abrupt end. Distinctly short and punchy, no impact or ringing steel.'],
['Broad slash','A wider, fuller swing with a dry ending.','A broad steel sword slices once through still air. Fast dense SHWOP, low body rising to a brief cutting edge and stopping cleanly. Less hiss than a whip; no hit or sustained wind.'],
['Tip whistle','A brief thin whistle above a low air cut.','One fast sword tip passes close: a tiny high whistle rides over a short low FWOOT, both end together within a quarter second. No metal clang, collision, multiple swings or long tail.']],
axe:[
['Heavy chop','A low air displacement ending abruptly.','A large axe swings downward once. Short deep FWOOM of displaced air, dense lower-mid body and abrupt stop. No collision, no sword-like whistle, no broad sustained wind.'],
['Short cleave','A compressed, punchy swing.','One compact forceful axe swing from shoulder height. Low WUFF with a coarse leading edge, 200 millisecond body, clean cutoff. No blade contact, metallic ring or airy hiss.'],
['Two-handed sweep','A fuller low swing with leather grip detail.','A two-handed iron axe sweeps once close past the microphone. Low muscular WHUP with a tiny leather grip creak underneath. Brief and weighty, no impact, no piercing blade whistle.'],
['Overhead descent','A descending-pitch air thump.','A very heavy axe accelerates down from overhead. Dense short air BURR dropping in pitch to a low WUP, stops immediately. No hit, explosion, long wind or multiple swings.']],
flesh:[
['Dense cut','A meaty thud with a brief wet tear.','A sharp blade contacts a dense slab of meat. Immediate damp THACK followed by a short sticky tear. Low fleshy body and restrained wet detail. Contact only: no approach, blade swing or airy whoosh.'],
['Wet puncture','A compact puncture and small liquid pop.','A pointed weapon punctures thick flesh once. Tight low PUK, small wet pop, tiny fluid spatter. Dry close perspective, abrupt onset, no slash through air or metal ringing.'],
['Rib-side hit','A fleshy smack with a small hard crack.','A forceful strike into a meat-covered rib. Solid chesty THOK layered with one small dry bone crack and brief wetness. No swinging air, scream, prolonged slicing or squelchy comedy.'],
['Tearing wound','A blunt hit followed by fibrous tearing.','One heavy cutting impact in flesh. Deep muted DUK at contact, then short coarse fibrous RRP and a few wet droplets. Weight before wetness. No swoosh, metal ring or repeated attacks.']],
heavy_hit:[
['Cleaver impact','A thick, crunchy chop into meat and bone.','A massive cleaver bites through a thick joint. Immediate deep THUNK, dense bone KRAK and a short wet tear. Heavy compact physical impact, no blade swing or sweeping hiss.'],
['Crushed ribcage','A low thud under several tight fractures.','A heavy blunt weapon crushes a ribcage. One bassy DUM with two closely layered bone snaps, then a brief damp settling sound. Crunch dominates. No whoosh, explosion or voice.'],
['Buried axe','A deadened chop with sticky resistance.','An axe buries into a dense carcass. Chesty dead THOCK, wet compact crunch and tiny suction at the end. Very close and dark, no preparatory air sweep or long cutting noise.'],
['Joint breaker','A sharp crack over a dense body blow.','One crushing blow to a large joint. Loud dry KRAK on a low fleshy THUD, followed by a tiny wet splatter. Abrupt, brutal and short. No wind, blade whistle or multiple blows.']],
bone:[
['Long-bone snap','A deep woody crack with tiny fragments.','A thick dry femur snaps once. Loud hollow KRAK with a low woody body, then a few tiny brittle fragments tick. No metal, flesh squelch, blade swing or rushing air.'],
['Skull fracture','A hollow knock that collapses into crunch.','A dried skull struck and cracked open. Hollow low TOK immediately breaking into a short granular crunch. Tight close recording. No glass shatter, whoosh or explosion.'],
['Rib cluster','Several tight, brittle snaps in one impact.','A cluster of dry ribs breaks under one blow. Three rapid irregular KRIK cracks packed into 150 milliseconds, low impact underneath. No prolonged rattling, air slash or metal.'],
['Bone grind','A blunt knock and short gravelly fracture.','A heavy bone joint crushed once. Dense low KNUK followed by short coarse bone grating and a few dry chips. Rough organic texture, not glass, no sweep or airy sound.']],
shield:[
['Dead iron','A blunt shield clang with leather movement.','A weapon hits the flat of a thick iron shield once. Abrupt low KLANG with very short damped resonance and a leather strap creak. No preparatory swing, high bell ring or wind.'],
['Rim contact','A harder edge strike with a short iron chatter.','Steel strikes an old shield rim. Hard TAK over a dark metallic body, two tiny iron chatter ticks follow. Compact close contact, no long ring, scraping slash or whoosh.'],
['Wood-backed block','A woody thud beneath a metal clack.','A blade hits an iron-faced oak shield. Heavy hollow DOK layered with a sharp iron clack and brief wood creak. Blunt physical block, no air movement or extended ring.'],
['Shield buckle','A low metal flex and rattling strap fitting.','A massive blow makes a heavy shield flex. Low metallic BONK, small buckle rattle, short dull decay. Deep solid resistance, not a gong. No swoosh or continuous metallic scrape.']],
body_fall:[
['Stone collapse','A heavy body thump and equipment settling.','A heavy armored body falls flat on stone. Deep soft THUMP first, then two small armor clacks and leather settling. Body mass dominates. No scream, wind, sword swing or explosion.'],
['Side fall','Two close impacts from hip and shoulder.','A warrior collapses sideways onto hard earth. Heavy hip DUM followed 100 milliseconds later by a smaller shoulder thud, brief fabric rustle. No footsteps or air sweep.'],
['Armored heap','A dense thud with short coarse metal rattle.','An armored corpse drops into a heap. Bassy dead THUD with layered dull armor plates clattering for a quarter second. Short, close and heavy. No ring, slash, wind or vocalization.'],
['Unarmored fall','A muffled fleshy landing and grit.','A large unarmored body hits packed gravel. Broad low WHUMP, short fleshy slap and a few grains scraping. Organic mass, no metal and no whooshing motion.']],
landing:[
['Bedrock strike','A huge ground impact with a mineral crack.','A heavy axe head strikes bedrock. Instant hard stone KRAK over a powerful bass THUD, followed by scattering gravel. Ground contact only, no approach or sword-like sweep.'],
['Earth crater','A bassy thump with dense soil crunch.','An enormous weapon slams packed earth. Deep WHUD, compressed gritty crunch, small clods patter outward. Physical close impact, no wind burst, explosion or metallic whistle.'],
['Iron on flagstone','A blunt clang layered with breaking stone.','A broad iron blade slams a flagstone. Dark low KLANG and sharp stone fracture at exactly the same instant, short rubble tail. No swing sound or high ringing.'],
['Cracked slab','A sharp stone break and subterranean rumble.','A stone floor slab breaks under one huge hammer strike. Dry explosive KRAK on a low DUM, short uneven rubble clicks and a low 300 millisecond rumble. No whoosh or musical bass note.']],
bow_release:[
['Gut-string snap','A taut, woody pluck.','One heavy longbow releases. Tight low string TWANG with a woody bow-limb tick, short vibrating tail. No arrow flight whoosh, impact, high electronic zing or music.'],
['Dry bow','A short, sharp string clack.','A thick medieval bowstring snaps forward once. Dry compact TUNK with tiny fiber buzz, quickly damped. Close mechanism sound, no air sweep, metal or arrow collision.'],
['Heavy draw release','A lower elastic thunk.','A powerful wooden warbow releases a thick gut string. Deep elastic BWUNK, wood flex click, decay under 200 milliseconds. No laser sound, whistling air or impact.'],
['Recurve tick','A crisp pluck with a small wooden click.','One recurve bow releases. Sharp PLUK followed almost immediately by a small dry limb click. Natural taut fiber texture, no musical note, wind or blade slash.']],
arrow_hit:[
['Deep puncture','A small, dense wet thock.','An arrowhead punctures thick flesh and stops. One short damp TOK, tiny wet click and faint shaft vibration. No flight whoosh, metallic clang, voice or prolonged tearing.'],
['Leather penetration','A dry pop over a soft impact.','An arrow pierces leather clothing into flesh. Crisp leather POP layered on a muted fleshy duk. Brief close contact, no bow twang, wind, blade swing or scream.'],
['Bone graze','A tight puncture and tiny hard crack.','An arrow penetrates flesh and clips bone. Short wet TIK-THOK with a tiny dry crack. Small but forceful event, no whooshing air, metal ring or broad slash.'],
['Soft tissue','A damp plop and tiny liquid spit.','One arrow embeds in soft tissue. Compact low PUK with a brief wet spit and deadened ending. No sucking comedy, swishing blade, approach sound or vocalization.']],
arrow_ground:[
['Stone ricochet','A hard tick and wooden shaft chatter.','An arrowhead hits stone. Sharp iron TIK followed by two quiet wooden shaft taps. Small dry physical contact, no flying hiss, sword slash or long ring.'],
['Dirt embed','A dry granular thock.','An arrow embeds in packed soil. Short woody TUK with a little dirt crunch, nearly dead decay. No metallic ping, bow release, windy approach or voice.'],
['Gravel hit','A small clack and scattered grit.','An arrow lands in coarse gravel. Tight hard KLIK, two small pebble clicks and a faint shaft rattle. Isolated contact only, no whoosh or blade sound.'],
['Flagstone bounce','Two tiny hard contacts with a hollow shaft tap.','An arrow hits flagstone and bounces once. Thin TIK then lower woody TOK 90 milliseconds later, brief shaft buzz. No air sweep, long ringing or musical twang.']],
hero_effort:[
['Chest grunt','A short, forceful low grunt.','One adult male barbarian makes a short forceful closed-mouth HNNG effort grunt. Deep chest resonance, 200 milliseconds, abrupt exhalation. Voice only, no words, weapon, breath whoosh or music.'],
['Open exertion','A rough, compact hah.','One muscular adult male gives a low rough HAH during a heavy lift. Compact voiced onset and chesty body, not a scream. No words, swishing air, weapons or background.'],
['Gritted strain','A gravelly, teeth-clenched effort.','One deep adult male teeth-clenched GRNN exertion. Gravelly low vocal cords, short strain, sudden release. Dry close voice only, no words, airy swoosh or sound effects.'],
['Heavy exhale','A voiced low huh with chest weight.','One adult male warrior delivers a short bassy HUH. Strong vocal chest thump, brief coarse breath tail. Natural human effort, not a monster. No words, wind sweep or weapon sounds.']],
hero_pain:[
['Gut hit','An involuntary low ouff.','One adult male takes a gut punch and gives a low voiced OUF. Sudden constricted onset, brief breath release. Hurt vocalization only, no impact sound, words, blade or wind.'],
['Sharp pain','A short rasping agh.','One deep-voiced adult male cries a compact rasping AGH in pain. Brief forceful attack, gravelly throat, quick cutoff. No dialogue, sustained screaming, weapon or airy sweep.'],
['Suppressed pain','A clenched, dark groan.','One adult male suppresses pain through clenched teeth: low GNNH lasting half a second. Coarse chesty vocal strain with natural decay. No words, weapons, whoosh or music.'],
['Wounded breath','A cracked low uh and strained exhale.','One hurt adult male gives a short cracked UH followed by a small strained breath. Low register and close dry voice. No speech, scream, impact, swishing or background.']],
roar:[
['Bull bellow','A deep animal bellow with a coarse throat.','One enraged minotaur gives a deep bull-like BELLOW. Strong low voiced onset, rough bovine throat resonance, short growling end. No words, human speech, wind, weapons or musical effects.'],
['Battle bark','A brutal, compact guttural roar.','One huge humanoid beast makes a short guttural RAAH battle bark. Gravelly chest-heavy voice and abrupt finish. Not a long scream. No words, whoosh, metal or ambience.'],
['Chest growl','A low growl swelling into a rough bark.','A massive horned beast gives a brief low throat growl that becomes one coarse bark. Dense vibrating vocal body, natural animal texture. No speech, sword sounds or wind.'],
['Rasping challenge','A hoarse, forceful creature shout.','One large undead warrior utters a deep hoarse nonverbal challenge roar. Rough vibrating throat, sharp voiced beginning, gravelly decay. No words, music, weapons or rushing air.']],
death:[
['Fading groan','A low strained groan that loses strength.','One adult male warrior gives a final deep painful groan. Voiced AGHH starts strongly then falls in pitch and strength into a weak exhale. No words, body fall, blade sound or wind.'],
['Broken breath','A brief cry ending in a rattling breath.','One dying adult male emits a short coarse UGH, then a weak broken breath. Natural deep human vocal performance, intimate and restrained. No speech, impact, whoosh or music.'],
['Last strain','A clenched groan with a heavy final exhale.','One adult male final strained GNNHH relaxes into a low breath. Gravelly throat and fading chest voice. One brief performance, no words, screaming, metal or air-sweep effects.'],
['Falling cry','A short low cry with a downward pitch break.','One adult male death cry: a deep rough AH breaks downward in pitch and cuts into a faint breath. Human, not theatrical. No dialogue, sword slash, body impact or background.']],
lightning:[
['Close thunder','A violent crack followed by deep rolling thunder.','One lightning strike: instantaneous branching electrical KRAK, then a dense low thunder roll decaying quickly. Natural violent electrical attack, bassy body. No sword swing, laser, rising whoosh or music.'],
['Arc rupture','A sharp electrical snap with a short bass concussion.','One huge electrical arc discharges. Hard stuttering ZKRAK attack over a compact bass concussion, tiny irregular sparks afterward. No sustained buzz, air sweep, metallic slash or synth note.'],
['Forked strike','Several tightly grouped snaps under one thunder hit.','One forked lightning bolt hits. Three jagged near-simultaneous electrical cracks, one deep thunder THOOM underneath, fast decay. No approaching wind, weapon swoosh or long ambience.'],
['Heavy discharge','A dry electrical bang with a coarse crackling tail.','One powerful magical lightning discharge. Abrupt dry electrical BANG, low chesty rumble and short granular crackles. No airy sweep, metal ring, continuous hiss or musical bass.']],
fire:[
['Rolling combustion','Low roaring flames with irregular dry crackles.','A small intense pyre burns for two seconds. Dense low turbulent flame roar with uneven dry woodlike crackles and occasional ember pops. Already burning at onset, no ignition whoosh, wind sweep or voices.'],
['Greasy crackle','Wet sizzling combustion with small popping embers.','A burning carcass crackles and sizzles briefly. Low rough combustion body, irregular small wet pops and coarse ember ticks. No scream, airy whoosh, metal or musical effects.'],
['Ember furnace','A low furnace rumble with sparse hot snaps.','Close intense furnace flames: steady dark low combustion rumble punctuated by several sharp irregular ember snaps. Short natural fade. No swishing wind, explosion, blade or voices.'],
['Ragged blaze','A rough flame crackle that settles into embers.','A compact blaze gives coarse uneven crackling, a low flame flutter and dwindling dry ember pops. Natural fire, no big airy ignition swell, whoosh, weapons or music.']],
chicken:[
['Double cluck','Two low, natural chicken clucks.','A real hen gives two distinct close clucks: buk BUK. Low natural rounded bird voice with a short gap. No monster pitch, human voice, flapping, wind, weapons or music.'],
['Questioning hen','One drawn cluck followed by a short note.','A real hen makes a soft throaty brrook then a clipped buk. Clearly recognizable natural chicken vocalization. Dry quiet background, no effects, humans, air sweep or metal.'],
['Busy clucking','Three irregular, compact clucks.','One real chicken gives three quick uneven clucks, buk-buk BOK. Natural chesty poultry tone, not cartoon. No wings, wind, weapons, music or other animals.'],
['Throaty cluck','A single fuller, hollow chicken note.','One real hen gives a single hollow throaty BOK with a tiny rattly throat tail. Natural close bird recording. No pitch-shift monster, voice, whoosh or background.']],
chicken_hit:[
['Startled squawk','A short sharp chicken squawk.','One real chicken suddenly squawks BWAARK. Sharp natural poultry voice, brief coarse tail, immediate cutoff. No human scream, impact sound, wind, blade or music.'],
['Cluck to alarm','A cluck interrupted by a brief alarm cry.','One real hen makes buk-KWAK, a startled short alarm vocalization. Natural chicken throat texture, close dry recording. No cartoon voice, sweeping air, weapons or music.'],
['Rasping squawk','A coarse low bird alarm call.','One chicken gives a short coarse throaty KRAWK of surprise. Clearly poultry, natural restrained pitch and duration. No monster growl, human words, metal or whoosh.'],
['Wing panic','A quick chicken cry with two compact feather flaps.','One startled hen gives a clipped BWAK and two short dry feather flaps. The bird voice dominates; feather taps are brief. No extended wind, weapon swing, human voice or music.']],
pickup:[
['Leather bundle','A small weighty rustle and rounded tap.','A small leather food bundle is picked up and gripped. Compact dry leather crumple then a soft low palm tap. Tactile and short, no magical chime, swoosh or weapon noise.'],
['Satisfying bite','A compact organic crunch and low knock.','A subtle game healing pickup: one short dry organic crunch layered with a muted rounded knock. Close physical texture, no chewing voice, magic sparkle, wind or slash.'],
['Warm thock','A soft wooden knock with a small leather creak.','One low soft wooden THOK paired with a tiny leather grip creak. Short satisfying physical confirmation, dark natural tone. No melody, chime, weapon swing or air sweep.'],
['Cloth gather','A brief cloth crumple and dull settling bump.','Heavy coarse cloth is gathered once around a small object. Short textured crumple ending in a dull low bump. Dry close Foley, no long scrape, whoosh, metal or music.']],
transition:[
['Crypt gate','A low stone rumble ending in a heavy stop.','A massive stone crypt gate shifts briefly and stops. Low grinding rumble, granular rock contact and a final dull clunk. Dark mechanical movement, no airy sword swoosh or musical riser.'],
['Iron passage','A short low metal groan with chain movement.','A huge ancient iron door moves a little. Deep coarse metal groan with two dull chain links shifting, fading quickly. Physical bassy resonance, no wind, blade slash or melody.'],
['Subterranean pulse','A low pressure thump and short cavern resonance.','One deep subterranean pressure thump with a short dark cavern tail and faint grit falling. Rounded bass onset, no explosion crack, rushing air, sword sweep or music.'],
['Stone teeth','A brief sequence of heavy grinding stone contacts.','Two massive interlocking stone teeth slide past and engage. Coarse low GRR-KLUNK with granular vibration, short dead ending. No windy sweep, metal ring, vocals or music.']]
};
const manifest=JSON.parse(fs.readFileSync('soundboard/manifest.json','utf8'));
for(const j of manifest.jobs){if(!designs[j.group])continue;const [name,description,design]=designs[j.group][Number(j.id.split('-').at(-1))-1];j.name=name;j.description=description;j.prompt=design+' Isolated dark fantasy game sound, close dry recording.';j.revision=2;if(j.prompt.length>450)throw Error('Prompt too long '+j.id);}
fs.mkdirSync('soundboard/revision-2',{recursive:true});
fs.writeFileSync('soundboard/revision-2/manifest.json',JSON.stringify(manifest,null,2));
const key=fs.readFileSync('.env.local','utf8').match(/^ELEVENLABS_API_KEY\s*=\s*(.+)$/m)?.[1].trim().replace(/^['"]|['"]$/g,'');if(!key)throw Error('Missing local credential');
let cursor=0,failed=0;
const jobs=manifest.jobs.filter(j=>j.revision===2);
async function worker(){while(cursor<jobs.length){const j=jobs[cursor++],raw='soundboard/revision-2/'+j.id+'-source.mp3',out='soundboard/revision-2/'+j.id+'.mp3';try{
if(!fs.existsSync(raw)){const r=await fetch('https://api.elevenlabs.io/v1/sound-generation?output_format=mp3_44100_128',{method:'POST',headers:{'xi-api-key':key,'Content-Type':'application/json'},body:JSON.stringify({text:j.prompt,duration_seconds:j.duration,prompt_influence:.85,model_id:'eleven_text_to_sound_v2'}),signal:AbortSignal.timeout(180000)});if(!r.ok){const e=await r.json().catch(()=>({}));console.log(j.id+' HTTP '+r.status+' '+(e.detail?.status||''));failed++;continue;}fs.writeFileSync(raw,Buffer.from(await r.arrayBuffer()));}
execFileSync('ffmpeg',['-hide_banner','-loglevel','error','-y','-i',raw,'-af','silenceremove=start_periods=1:start_duration=0.005:start_threshold=-45dB,loudnorm=I=-18:TP=-2:LRA=7,afade=t=in:d=0.003','-c:a','libmp3lame','-b:a','192k',out],{windowsHide:true});console.log('Prepared '+j.id);
}catch{failed++;console.log(j.id+' generation/preparation failed');}}}
await Promise.all([worker(),worker()]);
if(failed){process.exitCode=1;}else{for(const j of jobs)fs.copyFileSync('soundboard/revision-2/'+j.id+'.mp3','godot/audio_options/'+j.id+'.mp3');fs.writeFileSync('godot/audio_options/manifest.json',JSON.stringify(manifest,null,2));console.log('Installed '+jobs.length+' individually designed effects');}
