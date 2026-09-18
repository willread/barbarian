# Cairn recorded gameplay trailer

Local preview: http://127.0.0.1:3017/

Output: `E:/Cairn-build-tools/trailer/gameplay-cut/cairn-gameplay-trailer.mp4`

56 seconds, 1920×1080, 60 fps. Four user recordings from September 17, selected by readable actions and contrasting locations. All gameplay remains at original speed and framing, with the complete original HUD and captured effects/voices. The older staged 30-second cut is not used.

## Editorial structure

| Seconds | Content |
| --- | --- |
| 0–3 | Jump and impact opening |
| 3–5 | Three worlds to conquer / Twelve arenas |
| 5–11 | Citadel, swamp and furnace combat |
| 11–15 | Warden exchange |
| 15–17 | Chain hits / Crush your high score |
| 17–22 | Actual combo progression and crowd combat |
| 22–24 | Chicken running |
| 24–27 | Chicken eaten, visible health recovery |
| 27–30 | Lightning crowd control |
| 30–32 | Three bosses stand in your way |
| 32–41 | Warden, King, Saint |
| 41–45 | Furnace combat |
| 45–49 | Four impact cuts |
| 49–51 | Saint furnace threat |
| 51–56 | Cairn logo and genre |

The user explicitly excludes secrets from this trailer. No secret, cheat-code, hidden weapon, unlock or Easter-egg claims. No boss deaths. No invented availability claim: closing CTA remains unconfirmed. The approved itch.io copy informed the arcade score-chasing emphasis; it is not reproduced as trailer paragraphs.

## Artwork and audio

Original Cairn logo and licensed project Cinzel/Oswald typography. Editorial cards use darkened, softened recorded backgrounds, restrained gold rules, ember accents and a short settling motion. Cropping and motion apply only to cards; gameplay framing is untouched. These are reproducible graphics, not generated cinematic footage.

Ash Engine uses the original ElevenLabs source, normalized to -19 LUFS before mixing. The deep editorial volume pockets from the music auditions are removed; the source composition's own arrangement remains. Original gameplay audio is boosted by approximately 13 dB, with 8–12 ms edge fades to avoid cut clicks. A final peak limiter prevents overload. No additional generated voices. Final export uses H.264 and stereo 48 kHz AAC at 320 kbps.

## Reproduction and validation

From the repository root:

```powershell
node tools/trailer/gameplay-edit.mjs
node tools/trailer/gameplay-preview.mjs
```

Requires FFmpeg/ffprobe and the repository's @napi-rs/canvas. Media and intermediate files stay outside Git on E:. Original user recordings remain untouched in C:/Users/will/Videos. The edit script writes a precise edit-decisions.json beside the export and reuses unchanged gameplay intermediates; `--force` rebuilds them. `--cards-only` generates still card previews. The preview binds only to loopback and supports seeking and downloading.

Contact sheets inspected for gameplay, readable copy, full HUD, chicken run/pickup and boss coverage. Complete export decoded by FFmpeg; dimensions, 60 fps and 3,360-frame duration checked with ffprobe. Final audio measures -16.83 LUFS integrated and -1.79 dBTP; subjective sound balance still benefits from playback on the user's speakers. HTTP preview and byte-range seeking return 200/206 correctly. This export cannot recover fine detail already lost in the approximately 2.4 Mbps source captures.
