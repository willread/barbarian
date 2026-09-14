import fs from 'node:fs';
import {execFileSync} from 'node:child_process';
// Seeded, periodic liquid Foley: descending bubble resonances and wet suction bursts.
const rate=44100,seconds=8,n=rate*seconds,out=new Float64Array(n);let seed=19871;
const random=()=>{seed=(Math.imul(seed,1664525)+1013904223)>>>0;return seed/4294967296};
for(let e=0;e<95;e++){
 const start=Math.floor(random()*n),slurp=e%7===0,duration=slurp?.35+random()*.45:.06+random()*.18;
 const f=slurp?95+random()*85:170+random()*520;let phase=0,low=0;
 for(let j=0;j<duration*rate;j++){
  const t=j/rate,u=t/duration,env=Math.sin(Math.PI*u)**(slurp?1.1:.6)*Math.exp(-u*(slurp?.6:2.5));
  phase+=2*Math.PI*f*(.3+.7*Math.exp(-u*5))/rate;
  low+=.075*((random()*2-1)-low);
  const wet=slurp?low*(.65+.35*Math.sin(phase*.37))+Math.sin(phase)*.13:Math.sin(phase)*.65+Math.sin(phase*1.87)*.1+low*.3;
  out[(start+j)%n]+=wet*env*(slurp?.7:.23);
 }
}
const peak=Math.max(...Array.from({length:800},(_,i)=>Math.max(...out.subarray(i*n/800,(i+1)*n/800).map(Math.abs))));
const wav=Buffer.alloc(44+n*2);wav.write('RIFF');wav.writeUInt32LE(36+n*2,4);wav.write('WAVEfmt ',8);wav.writeUInt32LE(16,16);wav.writeUInt16LE(1,20);wav.writeUInt16LE(1,22);wav.writeUInt32LE(rate,24);wav.writeUInt32LE(rate*2,28);wav.writeUInt16LE(2,32);wav.writeUInt16LE(16,34);wav.write('data',36);wav.writeUInt32LE(n*2,40);
for(let i=0;i<n;i++)wav.writeInt16LE(Math.round(out[i]/peak*.72*32767),44+i*2);
const temp='E:/Cairn-build-tools/mire-liquid.wav';fs.writeFileSync(temp,wav);
execFileSync('ffmpeg',['-hide_banner','-loglevel','error','-y','-i',temp,'-stream_loop','-1','-i','godot/audio/gulp.ogg','-filter_complex','[0:a]lowpass=f=2600[a];[1:a]asetrate=32000,aresample=44100,lowpass=f=1300,volume=0.18[b];[a][b]amix=inputs=2:duration=first:normalize=0,alimiter=limit=0.85,afade=t=in:d=0.015,afade=t=out:st=7.985:d=0.015[out]','-map','[out]','-t','8','-c:a','libvorbis','-q:a','5','godot/audio/mire_loop.ogg'],{windowsHide:true});
console.log('Baked eight-second bubbling suction loop');
