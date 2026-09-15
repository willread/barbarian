"""Beat-aligned loop edits, retained sources, matched loudness, and seam measurements."""
import json, pathlib, subprocess, wave
import numpy as np

directory=pathlib.Path('soundboard/ep2-music')
manifest=json.loads((directory/'manifest.json').read_text(encoding='utf-8'))
sr=44100
def decode(path):
    return np.frombuffer(subprocess.check_output(['ffmpeg','-v','error','-i',str(path),'-f','f32le','-ac','2','-ar',str(sr),'-']),np.float32).reshape(-1,2)
for job in manifest['jobs']:
    samples=decode(directory/job['source']); mono=samples.mean(axis=1)
    hop=441
    energy=np.sqrt(np.mean(mono[:len(mono)//hop*hop].reshape(-1,hop)**2,axis=1))
    onset=np.maximum(0,np.diff(energy,prepend=energy[0]))
    lo=int(6000/(job['bpm']*1.08));hi=int(6000/(job['bpm']*.92))
    lag=max(range(lo,hi+1),key=lambda k:np.dot(onset[:-k],onset[k:]))
    beat=lag*.01
    # Search musical-length cuts with similar local timbre/level at both ends.
    candidates=[]
    for start in range(40,min(800,len(onset)//3)):
        if onset[start]<np.percentile(onset[:800],85):continue
        for bars in [12,14,16]:
            predicted=start+int(bars*4*beat*100)
            if predicted+20>=len(onset):continue
            end=predicted-5+int(np.argmax(onset[predicted-5:predicted+6]))
            a=start*hop;b=end*hop;n=1764
            left=samples[a:a+8820];right=samples[b:b+8820]
            if len(right)!=len(left):continue
            spec_a=np.abs(np.fft.rfft(left.mean(axis=1)*np.hanning(len(left))))
            spec_b=np.abs(np.fft.rfft(right.mean(axis=1)*np.hanning(len(right))))
            similarity=float(np.dot(spec_a,spec_b)/(np.linalg.norm(spec_a)*np.linalg.norm(spec_b)+1e-12))
            ratio=float(abs(np.log((np.mean(left**2)+1e-9)/(np.mean(right**2)+1e-9))))
            score=similarity-.15*ratio+.025*bars
            candidates.append((score,a,b,bars))
    assert candidates,job['id']+' has no usable musical loop'
    _,a,b,bars=max(candidates)
    n=1764;t=np.linspace(0,1,n,dtype=np.float32)[:,None]
    joined=np.concatenate([samples[a+n:b],samples[b:b+n]*(1-t)+samples[a:a+n]*t])
    temp=pathlib.Path('E:/Cairn-build-tools/ep2-music-loop.wav')
    with wave.open(str(temp),'wb') as f:
        f.setnchannels(2);f.setsampwidth(2);f.setframerate(sr)
        f.writeframes((np.clip(joined,-1,1)*32767).astype('<i2').tobytes())
    out=directory/job['file']
    subprocess.run(['ffmpeg','-v','error','-y','-i',str(temp),'-af','loudnorm=I=-19:TP=-2:LRA=9','-ar',str(sr),'-c:a','libvorbis','-q:a','6',str(out)],check=True)
    final=decode(out)
    seam=float(np.max(abs(final[-1]-final[0])))
    assert np.isfinite(final).all() and 35<len(final)/sr<65
    assert np.max(abs(final))<1 and seam<.08,(job['id'],seam)
    job['loop']={'duration':len(final)/sr,'estimated_bpm':round(60/beat,2),'bars':bars,'source_start':a/sr,'source_end':b/sr,'splice_seconds':n/sr,'seam_peak_difference':seam,'peak':float(np.max(abs(final))),'loudness_target_lufs':-19}
    print('Loop ready:',job['name'],job['loop'],flush=True)
(directory/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf-8')
