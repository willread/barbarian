import fs from 'node:fs';
const directory='soundboard/ep2-music';
fs.mkdirSync(directory,{recursive:true});
const key=fs.readFileSync('.env.local','utf8').match(/^ELEVENLABS_API_KEY\s*=\s*(.+)$/m)?.[1].trim().replace(/^['"]|['"]$/g,'');
if(!key)throw Error('ElevenLabs key is not configured');
const common='Instrumental dark sword-and-sorcery game metal for a sunken swamp kingdom. DEEP BASSY down-tuned baritone guitars dominate, thick low-register distorted riffs, real bass guitar doubling the roots, natural heavy acoustic drums. D minor. Slow, brooding, oppressive ancient menace, not fast combat metal. No vocals, choir, synth leads, bright solos, orchestral trailer hits, sound effects, or ambient water. Clear low end with room for game effects. Maintain a consistent cyclic riff and drum pattern throughout, no intro, no outro, no fade, no final crash, no build-up. Start immediately on the full groove and finish still playing that same groove on compatible bar boundaries for seamless looping. ';
const jobs=[
 {id:'blackwater',name:'Blackwater',bpm:66,description:'Crawling doom riff; thick sustained low chords and spacious half-time drums.',detail:'66 BPM, crawling doom metal. A memorable descending four-note low guitar motif, long gritty ringing chords between palm-muted notes. Huge restrained kick and deep snare, sparse cymbals. Weight and dread, very little upper-register activity.'},
 {id:'drowned-procession',name:'Drowned Procession',bpm:72,description:'A heavy funeral march with low guitar pulses and deep toms.',detail:'72 BPM, slow funeral procession. Repeating low syncopated power-chord pulses, deep floor toms and an ominous deliberate kick pattern. Small dissonant low guitar intervals, disciplined steady march, thick bass. No military snare rolls.'},
 {id:'roots-below',name:'Roots Below',bpm:60,description:'The sparsest option: sustained baritone guitars, sub-heavy bass and patient drums.',detail:'60 BPM, spacious hypnotic doom. Long resonant down-tuned guitar chords with a quiet second baritone guitar playing a low two-note answering motif. Deep warm distorted bass, minimal slow drums, dark organic amplifier sustain. Keep real guitars present, not ambient synth music.'},
 {id:'bog-iron',name:'Bog Iron',bpm:76,description:'A slow swamp groove with dragging palm-muted riffs and a heavier backbeat.',detail:'76 BPM, slow sludgy groove metal. A dragging low palm-muted riff with a slight swung feel, saturated baritone guitar grit, thick bass doubling riff. Deliberate half-time drums and occasional low tom accents. Brooding and menacing, no speed-up or double-kick barrage.'}
].map(j=>({...j,prompt:common+j.detail,source:j.id+'-source.mp3',file:j.id+'.ogg'}));
fs.writeFileSync(directory+'/manifest.json',JSON.stringify({provider:'ElevenLabs',model:'music_v1',jobs},null,2)+'\n');
let cursor=0;
async function worker(){while(cursor<jobs.length){const job=jobs[cursor++],file=directory+'/'+job.source;
 if(fs.existsSync(file)){console.log('Retained '+job.name);continue;}
 console.log('Generating '+job.name);
 const response=await fetch('https://api.elevenlabs.io/v1/music?output_format=mp3_44100_128',{method:'POST',headers:{'xi-api-key':key,'Content-Type':'application/json'},body:JSON.stringify({model_id:'music_v1',prompt:job.prompt,music_length_ms:65000,force_instrumental:true}),signal:AbortSignal.timeout(300000)});
 if(!response.ok)throw Error('Music generation HTTP '+response.status+' for '+job.id);
 fs.writeFileSync(file,Buffer.from(await response.arrayBuffer()));console.log('Generated '+job.name);
}}
await Promise.all([worker(),worker()]);
