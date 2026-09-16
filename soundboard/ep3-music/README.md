# Furnace Heart — episode 3 music candidates

Four instrumental ElevenLabs music_v1 variants of the infernal-foundry combat theme:

- Piston — 110 BPM, precise stop-start guitar and mechanical groove.
- Pressure — 116 BPM, rolling riffs and deep tom responses.
- Slag — 104 BPM, gritty industrial stomp with swung subdivisions.
- Overdrive — 122 BPM, urgent palm-muted riffs and controlled double-kick bursts.

**Overdrive is the selected episode 3 theme.** The internal **Options → Sound → Music Player** shows only assigned game themes; the three unused candidates are retained here as source assets.

Overdrive starts with its original opening. After the first 49.35 seconds it repeats from 2.26 seconds, retaining the 47.09-second musical loop without cutting off the initial entry. The runtime reads this loop offset from the installed manifest.

`node tools/audio/ep3-music.mjs` retains existing sources and generates missing tracks. `python tools/audio/loop-ep3-music.py` prepares initial loops. Then run `python tools/audio/refine-overdrive.py` to replace Overdrive's original 26-bar edit with a 24-bar phrase loop, matching percussion and spectral context across the join, with an 80 ms splice and -19 LUFS target. `node tools/audio/install-ep3-music.mjs` installs the Oggs and metadata. Prompts, source filenames, tempo estimates and loop measurements are recorded in `manifest.json`; credentials remain local.
