import {execFileSync} from 'node:child_process';
// Preserve the existing chicken's voice; pair its cluck with a soft shell landing.
execFileSync('ffmpeg', ['-hide_banner','-loglevel','error','-y',
  '-i','godot/audio_options/chicken-2.mp3','-f','lavfi','-i','anoisesrc=color=pink:duration=0.16:amplitude=0.4',
  '-filter_complex','[0:a]atrim=0:0.6,asetpts=PTS-STARTPTS,afade=t=out:st=0.4:d=0.2,volume=0.8[c];[1:a]lowpass=f=700,afade=t=out:st=0:d=0.16,adelay=240|240[t];[c][t]amix=inputs=2:duration=longest,loudnorm=I=-21:TP=-4:LRA=7[out]',
  '-map','[out]','-c:a','libvorbis','-q:a','5','godot/audio/egg_lay.ogg'
], {windowsHide:true});
