# Trailer music auditions

Four original ElevenLabs `music_v1` compositions using explicit section durations, empty lyric arrays and instrumental direction. No reference audio, artist imitation, third-party track or game recording was uploaded. These are new scores, not extracts from the existing game music.

| Track | Direction |
| --- | --- |
| Iron Oath | Down-tuned heavy groove metal; physical, memorable guitar motif. |
| Ash Engine | Industrial metal; syncopated guitar and struck-metal rhythmic pressure. |
| War Crown | Orchestral metal; guitars with low brass, strings and war drums. |
| Blood Rush | Thrash; urgent picked riffs and double-time subdivisions. |

The compositions follow sections at 0, 4, 16, 30, 38, 45 and 51 seconds. Direction within sections calls for card punctuation and a lightning lift at 31.5 seconds. Editorial gain pockets at 3–4, 15–16, 30–31.5 and 49–51 seconds give the title beats and game sounds room. All end at 56 seconds. These cues are arranged for PLAN.md; exact musical attacks still need to be fitted to the chosen gameplay edit. Full HUD and natural gameplay continuity remain required.

## Listen locally

Run `node tools/trailer/music-preview.mjs`, then open http://127.0.0.1:3016/ . The server binds to loopback and only exposes the audition page and allowlisted audio/metadata. It does not expose the repository or environment files.

The player has waveforms, all shot-list cue buttons, shared volume and optional same-timestamp A/B switching. Only one option plays at once. WAV and MP3 download links are on each card. No footage or SFX is mixed into these auditions.

## Files and reproduction

Outputs live at `E:/Cairn-build-tools/trailer/music-options/`:

- `*-source.mp3`: original ElevenLabs output, 44.1 kHz / 128 kbps.
- `*.wav`: edited 56-second stereo masters, 48 kHz / 24-bit, derived from the compressed source; conversion does not add source detail.
- `*.mp3`: 192 kbps listening copies.
- `generation-manifest.json`: exact composition requests without credentials.
- `tracks.json`: local preview descriptions and measured waveform peaks.

`node tools/trailer/music-options.mjs` generates missing sources using the existing local ElevenLabs configuration, then renders previews. Existing source files are reused; there is no automatic paid retry. `node tools/trailer/music-options.mjs --render-only` only rerenders local sources and makes no API calls. Node and FFmpeg/FFprobe must be available. The API key is read locally, never printed or saved into outputs.

## Verification

All four WAVs decoded successfully: exactly 56.000 seconds, stereo, 48 kHz, 24-bit. Measured integrated loudness is -16.00 LUFS for each. True peaks: Iron Oath -4.99 dBTP; Ash Engine -3.79 dBTP; War Crown -2.78 dBTP; Blood Rush -4.58 dBTP. No clipping. Browser verification covered loading the four options, playback, cue seeking and switching at the same timestamp. Musical taste and final synchronization should be judged in the local player and against the actual footage; technical checks do not substitute for a listening review.

API reference: https://elevenlabs.io/docs/api-reference/music/compose
