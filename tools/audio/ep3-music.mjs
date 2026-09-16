import fs from 'node:fs';
const directory='soundboard/ep3-music';
fs.mkdirSync(directory,{recursive:true});
const key=fs.readFileSync('.env.local','utf8').match(/^ELEVENLABS_API_KEY\s*=\s*(.+)$/m)?.[1].trim().replace(/^['"]|['"]$/g,'');
if(!key)throw Error('ElevenLabs key is not configured');
const common='Instrumental dark sword-and-sorcery combat metal, FURNACE HEART: a colossal infernal foundry driven by a metal band. Downtuned baritone guitars and distorted bass dominate. Tight syncopated heavy riffs, strong acoustic kick and snare, deep toms, sparse struck-iron percussion accents integrated rhythmically. Relentless physical groove, threatening machinery, molten heat. NOT slow doom, NOT orchestral, NOT electronic dance music. No vocals, choir, organ, bright guitar solos or synth leads. Memorable repeating low guitar hook. Controlled clear bass with space for weapon impacts. No literal machine or fire sound effects. Consistent cyclic arrangement, immediate full groove, no intro, outro, fade, finale or tempo changes; compatible bar boundaries for a seamless game loop. ';
const jobs=[
 {id:'furnace-heart-piston',name:'Furnace Heart I — Piston',bpm:110,description:'Tight mechanical stop-start chugs and a crushing kick/snare groove.',detail:'110 BPM, D minor. Short clipped low guitar stabs, a distinctive three-hit pickup into a syncopated sixteenth-note riff. Dry powerful drums, precise unison bass. A gigantic piston cycling under pressure.'},
 {id:'furnace-heart-pressure',name:'Furnace Heart II — Pressure',bpm:116,description:'Rolling low riffs, deep toms and a relentless accelerating-feel groove.',detail:'116 BPM, D minor. Rolling low-register guitar ostinato with displaced accents, steady driving kick and deep tom responses. Tension from rhythm, never actual tempo changes. Sparse metallic strikes every few bars.'},
 {id:'furnace-heart-slag',name:'Furnace Heart III — Slag',bpm:104,description:'Thick gritty guitars and a lurching, bass-heavy industrial stomp.',detail:'104 BPM, D minor. Huge gritty low guitar riff with deliberate gaps and a slight swung subdivision, aggressive halftime backbeat over busy guitar rhythm. Bass slides into heavy root notes. The groove should feel dangerously massive, still energetic combat metal.'},
 {id:'furnace-heart-overdrive',name:'Furnace Heart IV — Overdrive',bpm:122,description:'The most urgent variant: fast palm-muted patterns and explosive drum accents.',detail:'122 BPM, D minor. Insistent alternating palm-muted low notes and open power chords, short controlled double-kick bursts, hard snare and hammer-like metal accents. A memorable descending riff answered by one rising dissonant chord. Fierce, focused, no shred solo.'}
].map(j=>({...j,music:true,prompt:common+j.detail,source:j.id+'-source.mp3',file:j.id+'.ogg'}));
fs.writeFileSync(directory+'/manifest.json',JSON.stringify({provider:'ElevenLabs',model:'music_v1',type:'music',collection:'EP3 · Furnace Heart',jobs},null,2)+'\n');
let cursor=0;
async function worker(){while(cursor<jobs.length){const job=jobs[cursor++],file=directory+'/'+job.source;
 if(fs.existsSync(file)){console.log('Retained '+job.name);continue;}
 console.log('Generating '+job.name);
 const response=await fetch('https://api.elevenlabs.io/v1/music?output_format=mp3_44100_128',{method:'POST',headers:{'xi-api-key':key,'Content-Type':'application/json'},body:JSON.stringify({model_id:'music_v1',prompt:job.prompt,music_length_ms:65000,force_instrumental:true}),signal:AbortSignal.timeout(300000)});
 if(!response.ok)throw Error('Music generation HTTP '+response.status+' for '+job.id);
 fs.writeFileSync(file,Buffer.from(await response.arrayBuffer()));console.log('Generated '+job.name);
}}
await Promise.all([worker(),worker()]);
