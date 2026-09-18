import fs from 'node:fs';
import path from 'node:path';
import {execFileSync,spawnSync} from 'node:child_process';

const out='E:/Cairn-build-tools/trailer/music-options';
fs.mkdirSync(out,{recursive:true});
const options=[
 {id:'iron-oath',name:'Iron Oath',tag:'Heavy groove metal',description:'Weighty low guitar hook, muscular drums, widening into an anthemic final assault.',styles:['120 BPM','D minor','downtuned baritone guitar groove metal','thick distorted bass','tight acoustic drums','memorable four-note low guitar hook','dark sword and sorcery','physical swagger and heroic menace']},
 {id:'ash-engine',name:'Ash Engine',tag:'Industrial metal',description:'Mechanical stop-start riffs and struck-metal rhythm, building into furnace-like pressure.',styles:['120 BPM','D minor','industrial groove metal','staccato low distorted guitars','dry piston-like kick and snare','rhythmic struck iron percussion','deep bass pulse','hostile infernal foundry energy','short syncopated memorable hook']},
 {id:'war-crown',name:'War Crown',tag:'Orchestral metal',description:'Barbarian war drums, low brass and strings supporting heavy guitars; the broadest cinematic build.',styles:['120 BPM','D minor','dark fantasy orchestral metal','heavy guitars lead the arrangement','low brass answering guitar motif','low string ostinato','huge acoustic tom ensemble','determined heroic tension','ominous ancient war march']},
 {id:'blood-rush',name:'Blood Rush',tag:'Thrash / speed metal',description:'Urgent alternate-picked riffs and a double-time finish; the most aggressive rhythmic direction.',styles:['120 BPM with double-time 240 BPM subdivisions in the climax','E minor','old school thrash metal','tight aggressive palm-muted guitars','driving electric bass','fast precise acoustic drums','short descending riff hook','raw controlled aggression','no guitar solo']}
];
const sections=[
 ['Impact and STEEL',4000,'Immediate short low guitar and drum attack, then a tense spacious hook. At local second 3 choke drums and let one low note ring for the STEEL card; launch the next section hard.'],
 ['Weapons and first boss; BLOOD',12000,'A clear memorable riff in a medium-density groove. Strong accents support weapon cuts and a threatening boss exchange. Last second is a dramatic choke and short resonant tail for BLOOD. Save maximum intensity for later.'],
 ['Combos and bomb return',14000,'Add a bass counter-rhythm and tighter drums; rising confidence and aggression, not maximum loudness. From local seconds 8 to 12 strip some percussion for a readable bomb-return action, then a strong payoff and drum pickup.'],
 ['THUNDER and lightning',8000,'Begin with a 1.5 second tense sparse suspended guitar swell, then at local second 1.5 explode into the main hook with wider doubled guitars and driving drums. This is the first major lift; keep melody low and leave room for game effects.'],
 ['Saint and escalation',7000,'Increase rhythmic subdivision and harmonic tension. Rolling tom fills, stronger bass and wider main hook; increasingly dangerous and exhilarating. No slowdown.'],
 ['Rapid montage and final threat',6000,'Maximum controlled energy. Four decisive accented attacks over the first four seconds for rapid cuts. Final two seconds reduce to a rising tense held note and low pulse, with a very brief breath immediately before the next section.'],
 ['CAIRN title and resolve',5000,'One enormous final tonic guitar chord and drum accent exactly at the start. Decisive satisfying resolution, then ringing guitar and dark reverberation decay naturally through the remaining five seconds. No new riff, no restart, no abrupt cutoff.']
];
const negative=['vocals','singing','spoken words','chanting','choir','lyrics','shrill guitar solos','bright pop melody','EDM drop','literal weapon sound effects','literal thunder sound effects','long ambient intro','constant maximum loudness','brickwall distortion'];
const jobs=options.map(o=>({...o,body:{model_id:'music_v1',respect_sections_durations:true,composition_plan:{positive_global_styles:[...o.styles,'instrumental','56 second tightly structured game trailer score','progressive arrangement building to a climax','clear transient detail and space for combat sounds','one consistent musical motif developed throughout'],negative_global_styles:negative,sections:sections.map(([section_name,duration_ms,direction])=>({section_name,duration_ms,positive_local_styles:[direction,'instrumental only'],negative_local_styles:negative,lines:[]}))}}}));
fs.writeFileSync(path.join(out,'generation-manifest.json'),JSON.stringify({provider:'ElevenLabs',created:new Date().toISOString(),jobs},null,2));
if(!process.argv.includes('--render-only')){
 const env=fs.readFileSync('.env.local','utf8');
 const key=env.match(/^ELEVENLABS_API_KEY\s*=\s*(.+)$/m)?.[1].trim().replace(/^['"]|['"]$/g,'');
 if(!key)throw Error('ElevenLabs key is not configured');
 let cursor=0;
 async function worker(){while(cursor<jobs.length){const job=jobs[cursor++];const dest=path.join(out,job.id+'-source.mp3');
  if(fs.existsSync(dest)){console.log('Retained '+job.name);continue;}
  console.log('Generating '+job.name);
  const response=await fetch('https://api.elevenlabs.io/v1/music?output_format=mp3_44100_128',{method:'POST',headers:{'xi-api-key':key,'Content-Type':'application/json'},body:JSON.stringify(job.body),signal:AbortSignal.timeout(600000)});
  if(!response.ok){const error=await response.json().catch(()=>({}));throw Error('Generation HTTP '+response.status+' '+JSON.stringify(error.detail?.status??error.detail?.type??'')+' for '+job.id);}
  fs.writeFileSync(dest,Buffer.from(await response.arrayBuffer()));console.log('Generated '+job.name);
 }}
 const results=await Promise.allSettled([worker(),worker()]);
 for(const r of results)if(r.status==='rejected'){console.error(r.reason.message);process.exitCode=1;}
 if(process.exitCode)process.exit(process.exitCode);
}

// Smooth editorial gain pockets enforce title-card space without changing gameplay audio.
const pockets=[[3,4,.36],[15,16,.36],[30,31.5,.25],[49,51,.48]];
const terms=pockets.map(([a,b,g])=>`if(between(t,${a-.08},${a}),1-(1-${g})*(t-${a-.08})/.08,if(between(t,${a},${b-.08}),${g},if(between(t,${b-.08},${b}),${g}+(1-${g})*(t-${b-.08})/.08,1)))`);
const volume=terms.join('*');
const run=(args,opts={})=>execFileSync('ffmpeg',['-hide_banner','-y',...args],{windowsHide:true,stdio:['ignore','pipe','pipe'],...opts});
for(const job of jobs){
 const source=path.join(out,job.id+'-source.mp3');
 const master=path.join(out,job.id+'.wav');
 const base=`atrim=duration=56,asetpts=PTS-STARTPTS,apad=whole_dur=56,volume='${volume}':eval=frame,afade=t=in:d=0.008,afade=t=out:st=55.4:d=0.6`;
 const measured=spawnSync('ffmpeg',['-hide_banner','-i',source,'-af',base+',loudnorm=I=-16:TP=-1.5:LRA=11:print_format=json','-f','null','-'],{windowsHide:true,encoding:'utf8'});
 if(measured.status!==0)throw Error('Loudness measurement failed for '+job.id);
 const m=JSON.parse(measured.stderr.match(/\{[^{}]*"input_i"[^{}]*\}/s)[0]);
 const norm=`loudnorm=I=-16:TP=-1.5:LRA=11:measured_I=${m.input_i}:measured_TP=${m.input_tp}:measured_LRA=${m.input_lra}:measured_thresh=${m.input_thresh}:offset=${m.target_offset}:linear=true`;
 run(['-i',source,'-af',base+','+norm,'-t','56','-ar','48000','-c:a','pcm_s24le',master]);
 run(['-i',master,'-c:a','libmp3lame','-b:a','192k',path.join(out,job.id+'.mp3')]);
 const raw=run(['-i',master,'-ac','1','-ar','4000','-f','f32le','pipe:1'],{maxBuffer:4*1024*1024});
 const samples=new Float32Array(raw.buffer,raw.byteOffset,raw.byteLength/4);const peaks=[];
 for(let i=0;i<560;i++){let peak=0;for(let j=i*400;j<Math.min(samples.length,(i+1)*400);j++)peak=Math.max(peak,Math.abs(samples[j]));peaks.push(Number(peak.toFixed(4)));}
 job.peaks=peaks;console.log('Rendered '+job.name+' — 56 seconds');
}
fs.writeFileSync(path.join(out,'tracks.json'),JSON.stringify(jobs.map(({body,...o})=>o)));
console.log('Music ready in '+out);
