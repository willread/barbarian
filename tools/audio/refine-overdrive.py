"""Choose complete eight-bar phrases using multi-band musical context at the join."""
import json, pathlib, subprocess, wave
import numpy as np

folder=pathlib.Path('soundboard/ep3-music')
manifest=json.loads((folder/'manifest.json').read_text())
job=next(j for j in manifest['jobs'] if j['id']=='furnace-heart-overdrive')
sr=44100
def decode(path):
    return np.frombuffer(subprocess.check_output(['ffmpeg','-v','error','-i',str(path),'-f','f32le','-ac','2','-ar',str(sr),'-']),np.float32).reshape(-1,2)
samples=decode(folder/job['source'])
mono=samples.mean(axis=1)
hop=441
frames=np.lib.stride_tricks.sliding_window_view(mono,4096)[::hop]
spectrum=np.abs(np.fft.rfft(frames*np.hanning(4096),axis=1))
frequency=np.fft.rfftfreq(4096,1/sr)
bands=np.stack([np.log1p(spectrum[:,(frequency>=lo)&(frequency<hi)].mean(axis=1)) for lo,hi in [(35,90),(90,180),(180,350),(350,700),(700,1400),(1400,2800),(2800,5600),(5600,12000)]],axis=1)
bands=(bands-bands.mean(axis=0))/(bands.std(axis=0)+1e-8)
onset=np.maximum(0,np.diff(bands,axis=0,prepend=bands[:1])).mean(axis=1)
beat=.49
context=196 # Compare a full bar either side: rhythm and tonal continuity.
candidates=[]
for bars in [24,32]:
    length=round(bars*4*beat*100)
    for start in range(context,min(1000,len(bands)-length-context-1)):
        if onset[start]<np.percentile(onset,65):continue
        predicted=start+length
        for end in range(predicted-8,predicted+9):
            if end+context>=len(bands):continue
            a=bands[start-context:start+context]
            b=bands[end-context:end+context]
            similarity=float(np.mean(a*b))
            rhythm=float(np.corrcoef(onset[start-context:start+context],onset[end-context:end+context])[0,1])
            score=similarity+rhythm*.6-abs(end-predicted)*.015
            candidates.append((score,start,end,bars,rhythm))
score,start,end,bars,rhythm=max(candidates)
a=start*hop;b=end*hop;n=3528 # 80 ms; preserve the full phrase's duration.
t=np.linspace(0,1,n,dtype=np.float32)[:,None]
joined=np.concatenate([samples[a+n:b],samples[b:b+n]*(1-t)+samples[a:a+n]*t])
temp=pathlib.Path('E:/Cairn-build-tools/overdrive-refined.wav')
with wave.open(str(temp),'wb') as out:
    out.setnchannels(2);out.setsampwidth(2);out.setframerate(sr)
    out.writeframes((np.clip(joined,-1,1)*32767).astype('<i2').tobytes())
destination=folder/job['file']
subprocess.run(['ffmpeg','-v','error','-y','-i',str(temp),'-af','loudnorm=I=-19:TP=-2:LRA=9','-ar',str(sr),'-c:a','libvorbis','-q:a','6',str(destination)],check=True)
final=decode(destination)
seam=float(np.max(np.abs(final[-1]-final[0])))
assert np.isfinite(final).all() and seam<.08 and np.max(np.abs(final))<1
job['loop']={'duration':len(final)/sr,'estimated_bpm':bars*4*60/((b-a)/sr),'bars':bars,'source_start':a/sr,'source_end':b/sr,'splice_seconds':n/sr,'seam_peak_difference':seam,'peak':float(np.max(np.abs(final))),'loudness_target_lufs':-19,'method':'eight-bar phrase groups, full-bar spectral and percussion matching on both sides of seam','rhythm_correlation':rhythm}
(folder/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
print('Overdrive revised loop:',job['loop'])
