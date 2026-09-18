# Cairn recorded gameplay trailer

Local preview: http://127.0.0.1:3017/

Output: `E:/Cairn-build-tools/trailer/gameplay-cut/cairn-gameplay-trailer.mp4`

56 seconds, 1920×1080, 60 fps. Four user recordings from September 17, selected by readable actions and contrasting locations. All gameplay remains at original speed and framing, with the complete original HUD and captured effects/voices. The older staged 30-second cut is not used.

## Editorial structure

| Seconds | Content |
| --- | --- |
| 0–3 | Jump and impact opening |
| 3–5 | Three worlds to conquer |
| 5–11 | Citadel, swamp and ashen ranged-enemy combat |
| 11–15 | Warden charge tell, rush and player knockdown |
| 15–17 | Chain hits / Crush your high score |
| 17–22 | Actual combo progression and crowd combat |
| 22–24 | Chicken running |
| 24–27 | Chicken eaten, visible health recovery |
| 27–30 | Lightning crowd control |
| 30–32 | Dash. Charge. Unleash magic. |
| 32–41 | Warden, King, Saint |
| 41–45 | Furnace combat |
| 45–49 | Four impact cuts |
| 49–51 | Saint furnace threat |
| 51–56 | Cairn logo over continuing gameplay |

The user explicitly excludes secrets from this trailer. No secret, cheat-code, hidden weapon, unlock or Easter-egg claims. No boss deaths. No invented availability claim: closing CTA remains unconfirmed. The approved itch.io copy informed the arcade score-chasing emphasis; it is not reproduced as trailer paragraphs.

## Artwork and audio

The latest revision uses a generated carved-stone lettering sheet explicitly matched to the shareware screen's chipped limestone, dimensional bevels and bronze edges. The final CAIRN mark is the actual game logo. Both are rendered in Godot with the production ContourFire, contour_fire_flow/surface, stone_temperature and hot_stone code, copied unchanged into an isolated offline rendering project on E:. Fire remains active for the entire visible title hold. The original title approach/recoil timing is adapted from game.gd. All titles, including the final logo, stay over moving gameplay; no background illustration replaces the ending. Native-title movie captures run at 1080p60 and are composited into the existing edit. No game build or gameplay code is modified.

The previous Canvas/Anton motion treatment is superseded. Rendering source is native-titles.gd and native-titles.mjs; generated type source is asset-sources/marketing/trailer-stone-titles.png.

Ash Engine uses the original ElevenLabs source, normalized to -19 LUFS before mixing. The deep editorial volume pockets from the music auditions are removed; the source composition's own arrangement remains. Original gameplay audio is boosted by approximately 13 dB, with 8–12 ms edge fades to avoid cut clicks. A final peak limiter prevents overload. No additional generated voices. Final export uses H.264 and stereo 48 kHz AAC at 320 kbps.

## Reproduction and validation

From the repository root:

```powershell
node tools/trailer/gameplay-edit.mjs
node tools/trailer/gameplay-preview.mjs
```

Requires FFmpeg/ffprobe and the repository's @napi-rs/canvas. Media and intermediate files stay outside Git on E:. Original user recordings remain untouched in C:/Users/will/Videos. The edit script writes a precise edit-decisions.json beside the export and reuses unchanged gameplay intermediates; `--force` rebuilds them. Motion title check frames and the final poster are generated alongside the export. The preview binds only to loopback and supports seeking and downloading.

Contact sheets inspected for gameplay, readable copy, full HUD, chicken run/pickup and boss coverage. Complete export decoded by FFmpeg; dimensions, 60 fps and 3,360-frame duration checked with ffprobe. Final revised mix: -16.68 LUFS integrated, -1.81 dBTP. Full export decodes successfully: 3,360 frames, 56 seconds. Subjective sound balance still benefits from playback on the user's speakers. HTTP preview and byte-range seeking return 200/206 correctly. This export cannot recover fine detail already lost in the approximately 2.4 Mbps source captures.

## Variety revision

All text groups now center at (960,540). The edit contains one tagged lightning sequence, one two-second eating/pickup sequence, and one 1.5-second running-chicken shot. Removed the extra lightning accent, a marauder segment containing both an incidental pickup and a subsequent cast, and the rapid montage�s repeated original frames. New material includes the citadel bell courtyard, witch melee and mire pools, shield launch and skeletal melee. Full HUD and original speed remain.

Run `node tools/trailer/footage-catalog.mjs` after rendering to produce the searchable catalogue and exact selection audit. Preview: http://127.0.0.1:3018/footage-catalog.html . All four recordings are covered in 34 contiguous approximate scene bins using overview contact sheets, with denser sampling of selected actions. These are human-reviewed element tags, not exhaustive frame-level object detections. The audit checks selected source intervals including title backgrounds, and reports zero reused intervals. Incidental food on the ground is distinguished from an eating action.
