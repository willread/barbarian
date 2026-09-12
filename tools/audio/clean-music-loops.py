import pathlib,subprocess,numpy as np,json,wave
root=pathlib.Path('.');report=[]
items=[(pathlib.Path('godot/audio')/(g+'.mp3'),pathlib.Path('godot/audio')/(g+'.ogg'),80 if g=='music_menu' else 120) for g in ['music_menu','music_game']]
items += [(p,pathlib.Path('godot/audio_options')/(p.name.replace('-source','').replace('.mp3','.ogg')),80 if 'menu' in p.name else 120) for p in pathlib.Path('soundboard').glob('music_*-source.mp3')]
for src,out,bpm in items:
 raw=subprocess.check_output(['ffmpeg','-v','error','-i',str(src),'-f','f32le','-ac','2','-ar','44100','-'])
 samples=np.frombuffer(raw,np.float32).reshape(-1,2);mono=samples.mean(axis=1);hop=441
 energy=np.sqrt(np.mean(mono[:len(mono)//hop*hop].reshape(-1,hop)**2,axis=1));onset=np.maximum(0,np.diff(energy,prepend=energy[0]))
 lo=int(6000/(bpm*1.08));hi=int(6000/(bpm*.92));lag=max(range(lo,hi+1),key=lambda k:np.dot(onset[:-k],onset[k:]))
 beat=lag*.01;start=int(np.argmax(onset[:200]))*.01
 bars=int(((len(samples)/44100)-start-.2)/(beat*4));target=start+bars*4*beat
 center=int(target*100);end=(center-8+int(np.argmax(onset[max(0,center-8):center+9])))*.01
 a=int(start*44100);b=int(end*44100);n=1764
 assert b+n<len(samples) and b>a+44100*40
 t=np.linspace(0,1,n,dtype=np.float32)[:,None]
 joined=np.concatenate([samples[a+n:b],samples[b:b+n]*(1-t)+samples[a:a+n]*t])
 temp=pathlib.Path('E:/Cairn-build-tools/music-loop.wav')
 with wave.open(str(temp),'wb') as f:f.setnchannels(2);f.setsampwidth(2);f.setframerate(44100);f.writeframes((np.clip(joined,-1,1)*32767).astype('<i2').tobytes())
 subprocess.run(['ffmpeg','-v','error','-y','-i',str(temp),'-af','loudnorm=I=-19:TP=-2:LRA=9','-c:a','libvorbis','-q:a','6',str(out)],check=True)
 report.append({'file':str(out),'estimated_bpm':60/beat,'start':start,'end':end,'length':len(joined)/44100,'blend_seconds':.04,'seam_peak_difference':float(np.max(abs(joined[-1]-joined[0])))})
 print('Looped',out.name,flush=True)
pathlib.Path('soundboard/music-loop-report.json').write_text(json.dumps(report,indent=2))
