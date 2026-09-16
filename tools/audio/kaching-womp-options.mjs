import fs from 'node:fs';
import {spawnSync} from 'node:child_process';

const fast=process.argv.includes('--fast-womp');
const directory=fast?'soundboard/kaching-womp-options/fast':'soundboard/kaching-womp-options';
fs.mkdirSync(directory,{recursive:true});
const key=fs.readFileSync('.env.local','utf8').match(/^ELEVENLABS_API_KEY\s*=\s*(.+)$/m)?.[1].trim().replace(/^['"]|['"]$/g,'');
if(!key)throw Error('ElevenLabs key is not configured');
const jobs=[
 {id:'kaching-1',name:'Ka-ching 1 — Classic Register',duration:2.5,prompt:'Isolated classic mechanical cash register KA-CHING sound. One crisp lever clack, spring-loaded drawer slides open, bright authentic brass bell rings with a short natural decay. Recognizable vintage shop register, close dry recording, satisfying and concise. No voices, music, ambience or repeated transactions.'},
 {id:'kaching-2',name:'Ka-ching 2 — Heavy Brass',duration:2.5,prompt:'One rich old-fashioned cash register KA-CHING. Heavy iron mechanism gives a chunky metallic ka-CHUNK immediately followed by a clear high brass bell CHING and two tiny coins clinking in the drawer. Weighty antique register, warm resonant metal, crisp studio sound. No music, speech or background noise.'},
 {id:'kaching-3',name:'Ka-ching 3 — Coin Jackpot',duration:3,prompt:'Short playful cash register KA-CHING reward sound: fast register click and drawer spring, brilliant ringing bell, followed by a brief sparkling handful of coins tumbling into a metal tray. Single transaction, energetic satisfying payoff, realistic metal texture, clean isolated recording. No music, speech or ambience.'},
 {id:'kaching-4',name:'Ka-ching 4 — Punchy Arcade',duration:2,prompt:'Punchy exaggerated arcade cash register KA-CHING sound effect. Quick tight mechanical ka-click followed by a sharp bright double-metallic CHING with a sparkling high bell tail. One concise cartoon money reward, instantly recognizable register, strong attack and clean finish. No speech, backing music, ambience or long coin shower.'},
 {id:'womp-1',name:'Womp 1 — Classic Sad Trombone',duration:3,prompt:'Isolated comedic sad trombone WOMP WOOOMP. Exactly two descending low brass notes, first short, second lower and longer, with a drooping slide and gentle wah on the final note. Classic disappointed failure sting, dry warm acoustic trombone, expressive and unmistakable. No voice, drums, backing music or extra melody.'},
 {id:'womp-2',name:'Womp 2 — Muted and Pitiful',duration:3,prompt:'A lonely plunger-muted trombone plays WOMP WOOOMP, exactly two notes stepping down. First note pinched and short, second note lower, longer and slowly bending downward with a very sad wah-wah finish. Small pathetic comedic disappointment, intimate dry recording. No voice, accompaniment, percussion or other notes.'},
 {id:'womp-3',name:'Womp 3 — Big Deflated Tuba',duration:3.5,prompt:'Deep comic tuba and bass trombone in unison play WOMP WOOOOOMP. Exactly two descending notes: one short round low note then a much lower long flabby brass note sagging in pitch as breath runs out. Huge defeated disappointment, warm acoustic brass, clean isolated sound. No voice, percussion, backing music or extra notes.'},
 {id:'womp-4',name:'Womp 4 — Retro Synth Failure',duration:2.5,prompt:'Short retro arcade sadness WOMP WOOOMP sting. Exactly two descending notes on a round analog synth brass patch, short first note then a lower sustained note with a drooping pitch bend and low-pass wah closing at the end. Funny defeated disappointment, rich soft tone, clear attack. No voice, drums, backing track or extra melody.'},
].filter(job=>!fast||job.id.startsWith('womp-')).map(job=>({
 ...job,
 ...(fast?{duration:1.8,prompt:'Very quick WOMP WOMP, exactly two descending notes. First at 0 seconds, second at 0.35 seconds, fully finished by 1.6 seconds, brief decay. '+[
  'Classic warm acoustic sad trombone, dry and comedic, second note droops downward.',
  'Pitiful plunger-muted trombone, pinched nasal wah-wah tone, second note droops downward.',
  'Deep deflated tuba and bass trombone together, round low comic brass, second note sags in pitch.',
  'Retro analog synth brass with a closing low-pass wah, round soft comic failure tone.'
 ][Number(job.id.slice(-1))-1]+' No voice, backing music, percussion, extra notes or opening silence.'}:{}),
 file:job.id+'.mp3',source:job.id+'-source.mp3'
}));
fs.writeFileSync(directory+'/manifest.json',JSON.stringify({provider:'ElevenLabs',model:'eleven_text_to_sound_v2',jobs},null,2)+'\n');
let cursor=0;
async function worker(){while(cursor<jobs.length){
 const job=jobs[cursor++],source=directory+'/'+job.source;
 if(!fs.existsSync(source)){
  const response=await fetch('https://api.elevenlabs.io/v1/sound-generation?output_format=mp3_44100_128',{method:'POST',headers:{'xi-api-key':key,'Content-Type':'application/json'},body:JSON.stringify({text:job.prompt,duration_seconds:job.duration,prompt_influence:.65,model_id:'eleven_text_to_sound_v2'}),signal:AbortSignal.timeout(180000)});
  if(!response.ok)throw Error('Generation HTTP '+response.status+' for '+job.id);
  fs.writeFileSync(source,Buffer.from(await response.arrayBuffer()));
 }
 const result=spawnSync('ffmpeg',['-v','error','-y','-i',source,'-af',`atrim=duration=${job.duration},afade=t=out:st=${job.duration-.2}:d=0.2,loudnorm=I=-19:TP=-3:LRA=7`,'-ar','44100','-c:a','libmp3lame','-q:a','2',directory+'/'+job.file],{encoding:'utf8',windowsHide:true});
 if(result.status!==0)throw Error('Audio conversion failed for '+job.id);
 console.log('Ready '+job.name);
}}
await Promise.all([worker(),worker()]);
