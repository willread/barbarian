# Episode 2 music options

Local comparison: http://localhost:3001/ep2-music/index.html

Four instrumental ElevenLabs candidates; the game selection is unchanged. The page has gapless decoded-buffer playback, volume, loop-boundary audition, downloads, and a browser-local favorite.

Generate missing sources with `node tools/audio/ep2-music.mjs`; prepare loops with `python tools/audio/loop-ep2-music.py`. Source files are retained. The manifest records prompts, cut points, estimated tempo, seam measurements and output duration. Generation requires the existing locally configured key; it is never included in these files.

Loops use whole-bar candidate cuts, a 40 ms splice and -19 LUFS normalization. Musical continuity should be auditioned with the boundary button as well as the waveform checks. The reference is the current EP2 music_game-3 track.

To preview, copy this directory into E:/Cairn-build-tools/build/web/ep2-music while the existing local preview server runs.
