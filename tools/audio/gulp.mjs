import fs from 'node:fs';
import {execFileSync} from 'node:child_process';
const key=fs.readFileSync('.env.local','utf8').match(/^ELEVENLABS_API_KEY\s*=\s*(.+)$/m)?.[1].trim().replace(/^['"]|['"]$/g,'');
const prompt='One short natural human gulp, a burly adult man swallowing a mouthful of food. Single low throaty glunk, close dry realistic foley with a tiny breath out. Under one second. No speech, no words, no chewing sequence, no cartoon whistle, no sword whoosh, no music, no reverb. Subtle bass body, clear swallow.';
const r=await fetch('https://api.elevenlabs.io/v1/sound-generation?output_format=mp3_44100_128',{method:'POST',headers:{'xi-api-key':key,'Content-Type':'application/json'},body:JSON.stringify({text:prompt,duration_seconds:1,prompt_influence:.85,model_id:'eleven_text_to_sound_v2'})});
if(!r.ok)throw Error('Generation HTTP '+r.status);
fs.writeFileSync('godot/audio/gulp-source.mp3',Buffer.from(await r.arrayBuffer()));
execFileSync('ffmpeg',['-y','-v','error','-i','godot/audio/gulp-source.mp3','-af','silenceremove=start_periods=1:start_threshold=-45dB,loudnorm=I=-19:TP=-3:LRA=7','-c:a','libvorbis','-q:a','5','godot/audio/gulp.ogg'],{windowsHide:true});
fs.writeFileSync('godot/audio/gulp-prompt.json',JSON.stringify({prompt,provider:'ElevenLabs',model:'eleven_text_to_sound_v2'},null,2));
