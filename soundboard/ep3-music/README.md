# Furnace Heart — episode 3 music candidates

Four instrumental ElevenLabs music_v1 variants of the infernal-foundry combat theme:

- Piston — 110 BPM, precise stop-start guitar and mechanical groove.
- Pressure — 116 BPM, rolling riffs and deep tom responses.
- Slag — 104 BPM, gritty industrial stomp with swung subdivisions.
- Overdrive — 122 BPM, urgent palm-muted riffs and controlled double-kick bursts.

Audition in the game's **Options → Sound → Music Player**. The existing episode assignment remains available until a candidate is chosen.

`node tools/audio/ep3-music.mjs` retains existing sources and generates missing tracks. `python tools/audio/loop-ep3-music.py` prepares bar-aligned loops with a 40 ms splice and -19 LUFS target. `node tools/audio/install-ep3-music.mjs` installs the Oggs and metadata for the internal player. Generation prompts, source filenames, tempo estimates and loop measurements are recorded in `manifest.json`; credentials remain local.
