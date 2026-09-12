"""Prepare generated audio for Godot; never reads or packages credentials."""
import pathlib,subprocess,json
folder=pathlib.Path('godot/audio')
report=[]
for source in folder.glob('*.mp3'):
    duration=float(subprocess.check_output(['ffprobe','-v','error','-show_entries','format=duration','-of','default=nw=1:nk=1',str(source)]))
    output=source.with_suffix('.ogg')
    if source.stem.startswith('music_'):
        overlap=3 if source.stem=='music_menu' else 2
        end=duration-overlap
        graph=f'[0:a]asplit=3[m][t][h];[m]atrim=start={overlap}:end={end},asetpts=PTS-STARTPTS[mid];[t]atrim=start={end},asetpts=PTS-STARTPTS[tail];[h]atrim=end={overlap},asetpts=PTS-STARTPTS[head];[tail][head]acrossfade=d={overlap}:c1=tri:c2=tri[join];[mid][join]concat=n=2:v=0:a=1,loudnorm=I=-19:TP=-2:LRA=9[out]'
        args=['-filter_complex',graph,'-map','[out]']
    else:
        args=['-af','silenceremove=start_periods=1:start_duration=0.005:start_threshold=-45dB,loudnorm=I=-18:TP=-2:LRA=7,afade=t=in:d=0.003','-ac','1']
    subprocess.run(['ffmpeg','-hide_banner','-loglevel','error','-y','-i',str(source),*args,'-ar','44100','-c:a','libvorbis','-q:a','5',str(output)],check=True)
    report.append({'file':output.name,'source_duration':duration,'bytes':output.stat().st_size})
    print('Prepared',output.name,flush=True)
(folder/'preparation-report.json').write_text(json.dumps(report,indent=2))
