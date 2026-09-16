# Homeward — ending music candidates

Four 22-second non-looping alternatives for the Episode 3 reunion epilogue:

1. **Embers:** intimate pan flute and fingerpicked nylon guitar, bittersweet to warm.
2. **Highlands:** rustic pan flute, steel-string guitar and a restrained walking pulse.
3. **Stillwater:** exposed breathy pan flute, sparse harp and long quiet pauses.
4. **Last Light:** pan-flute call and response, guitar and warm chamber strings.

Generated with ElevenLabs `music_v1`; exact prompts and source files are retained.
`node tools/audio/ending-music.mjs` preserves existing generations, normalizes to
-19 LUFS / -2 dBTP, applies a short end fade, and installs Ogg previews and metadata.
Each prompt requests space at 18–20 seconds for "I missed you, kid."

Preview in **Options → Sound → Music Player**. Existing music pauses while
previewing; candidates play once and can be restarted. All four are candidates:
none is assigned to the epilogue yet.
