# External resources

Maintain this file when adding, replacing or removing external resources. Record the source, local path, license and actual use. Do not assume reference material is licensed for redistribution.

## Font comparison candidates (downloaded 2026-09-11)

All nine candidate font files were downloaded from the Google Fonts repository. Each accompanying OFL.txt was downloaded and checked for SIL Open Font License 1.1. Files are unmodified, self-hosted and used in `/font-options.html`; Anton is now also the active game menu font, selected by the user. OFL allows commercial use and embedding; preserve the license/copyright notices and observe reserved-name rules when modifying fonts.

| Family | Source | Local font | License |
|---|---|---|---|
| Anton | [Anton-Regular.ttf](https://github.com/google/fonts/blob/main/ofl/anton/Anton-Regular.ttf) | `public/fonts/anton.ttf` | `public/fonts/anton-OFL.txt` — SIL OFL 1.1 |
| Bebas Neue | [BebasNeue-Regular.ttf](https://github.com/google/fonts/blob/main/ofl/bebasneue/BebasNeue-Regular.ttf) | `public/fonts/bebasneue.ttf` | `public/fonts/bebasneue-OFL.txt` — SIL OFL 1.1 |
| Oswald | [Oswald[wght].ttf](https://github.com/google/fonts/blob/main/ofl/oswald/Oswald[wght].ttf) | `public/fonts/oswald.ttf` | `public/fonts/oswald-OFL.txt` — SIL OFL 1.1 |
| Teko | [Teko[wght].ttf](https://github.com/google/fonts/blob/main/ofl/teko/Teko[wght].ttf) | `public/fonts/teko.ttf` | `public/fonts/teko-OFL.txt` — SIL OFL 1.1 |
| Archivo Black | [ArchivoBlack-Regular.ttf](https://github.com/google/fonts/blob/main/ofl/archivoblack/ArchivoBlack-Regular.ttf) | `public/fonts/archivoblack.ttf` | `public/fonts/archivoblack-OFL.txt` — SIL OFL 1.1 |
| Russo One | [RussoOne-Regular.ttf](https://github.com/google/fonts/blob/main/ofl/russoone/RussoOne-Regular.ttf) | `public/fonts/russoone.ttf` | `public/fonts/russoone-OFL.txt` — SIL OFL 1.1 |
| Black Ops One | [BlackOpsOne-Regular.ttf](https://github.com/google/fonts/blob/main/ofl/blackopsone/BlackOpsOne-Regular.ttf) | `public/fonts/blackopsone.ttf` | `public/fonts/blackopsone-OFL.txt` — SIL OFL 1.1 |
| Bungee | [Bungee-Regular.ttf](https://github.com/google/fonts/blob/main/ofl/bungee/Bungee-Regular.ttf) | `public/fonts/bungee.ttf` | `public/fonts/bungee-OFL.txt` — SIL OFL 1.1 |
| Cinzel | [Cinzel[wght].ttf](https://github.com/google/fonts/blob/main/ofl/cinzel/Cinzel[wght].ttf) | `public/fonts/cinzel.ttf` | `public/fonts/cinzel-OFL.txt` — SIL OFL 1.1 |

## Previously used resources

- **Grenze Gotisch**: previous menu font, replaced with Anton; retained locally for historical reference. Source: https://github.com/google/fonts/tree/main/ofl/grenzegotisch . Local `public/fonts/grenze-gotisch.ttf`; SIL OFL 1.1 notice at `public/fonts/grenze-gotisch-OFL.txt`.
- **Impact / Haettenschweiler / Arial Black / Georgia**: earlier or fallback system-font references. No font binaries copied into this project. These are not represented as freely licensed; the comparison candidates above are the freely licensed replacement options.
- **Geist / Geist Mono**: existing `next/font/google` imports in `app/layout.tsx`. Upstream https://github.com/vercel/geist-font ; SIL OFL 1.1 upstream. Build tooling manages font delivery; not downloaded for this comparison.
- **Cairn title and menu stone texture**: created with the built-in image-generation tool, not third-party stock. Local `public/art/cairn-title-v1.png`, `public/art/menu-stone-material-v1.png`. Generated in this task from the approved concept; not assigned an invented open-source license.
- **NPM dependencies**: exact resolved packages are in `package-lock.json`; package-specific notices remain in their distributions. This ledger does not replace individual dependency licenses.

## References only (not permission to redistribute)

- User-supplied Golden Axe ROM: `C:/Users/will/Downloads/Golden Axe (World).zip`. Proprietary reference for earlier mechanics research; no redistribution rights inferred.
- User-supplied Vecteezy blood reference: `vecteezy_horror-blood-drip-background_74139446.mp4`. Visual reference, not copied into the shipped menu/blood effect. License not supplied.
- David Torno CG Blood: https://www.provideocoalition.com/cg-blood/ — visual/technical reference; not copied code or media.
- NVIDIA Blood Shader paper: https://download.nvidia.com/developer/SDK/Individual_Samples/DEMOS/Direct3D9/src/HLSL_BloodShader/docs/HLSL_BloodShader.pdf — research reference.
- Codrops Rain Effect: https://tympanus.net/codrops/2015/11/04/rain-water-effect-experiments/ — research reference.

## Scope

This records the known resources from the current work and conversation. It is not a completed provenance audit of every pre-existing file under public/art or research. Unknown earlier assets must be verified before claiming a complete licensing audit.

## Selected menu font

Anton selected by the user. Unmodified `public/fonts/anton.ttf`, SIL OFL 1.1. Runtime stone-face texturing, narrow bevels and dark textured sidewalls are rendered by project code; the font binary is unmodified. Existing generated `public/art/menu-stone-material-v1.png` is reused for front and side surfaces.

## Godot port (2026-09-11)

- **Godot Engine 4.7.2 Standard and matching export templates**: downloaded from https://godotengine.org/download/windows/ using the official downloads.godotengine.org endpoints. MIT license; bundled engine third-party notices apply (https://godotengine.org/license/). Tools and exports are local on E:/Cairn-build-tools, not committed binary dependencies.
- **@napi-rs/canvas**: existing bundled runtime used by tools/godot asset-conversion scripts; upstream https://github.com/Brooooooklyn/canvas, MIT. Used only during asset preparation, not shipped as a game runtime.
- **Anton and Cinzel**: existing unmodified SIL OFL fonts reused in Godot; notices copied into generated assets and included in exports. Cinzel replaces the old browser/system Georgia references for portable HUD and results text.
- **Existing game artwork**: converted locally from public/art using the existing project's extraction and colour correction; no new stock art, ROM sprites, or reference video copied into the port. The scope limitations above still apply.

## Maximum Force opening splash
- User-supplied artwork: codex-clipboard-3e35ee56-7ca4-441c-b71a-40c6cb7e22e7.png, supplied in this task.
- Stored unchanged at godot/art/maximum-force-reference.png. UI displays only the photorealistic panel; no third-party license inferred.

## Responsive screen layers
- `godot/art/title-background.png`, `cairn-logo.png`, `maximum-force-logo.png`, and `studio-background.png`: generated with OpenAI image generation from the existing Cairn artwork and user-supplied Maximum Force reference for this project. Backgrounds contain no lettering; logos have transparency. Original source art retained.
- `godot/art/maximum-force-white-v2.png`: imagegen-created clean white variant from the metallic logo, followed by an imagegen black-background correction. No deterministic source-mask conversion.
- `godot/art/hero-spin-source.png`: imagegen-generated eight-cell unarmed hero spin study using the existing hero-actions-unarmed-v8 character reference. `spin-*.png` and `spin-atlas.json` are game-ready keyed/normalized cels and authored weapon sockets produced by `scripts/bake_spin.gd`.

### Ground-impact reference (implementation guidance only)
- Kate Kruse, Ground Impact VFX: https://frontfangs.artstation.com/projects/QrnV5Z � layered shockwave/dust/debris reference. No downloaded artwork or third-party code used; the dust shader and particles are project code.

### Skeleton archer (2026-09-11)
Built-in ImageGen created `godot/art/archer-source.png` and the chroma-key edit `archer-keyed.png`; runtime cels and metadata are baked with `godot/scripts/bake_archer.gd`. No downloaded art. Prompt: 4x2 whole-body sprite sheet, realistic dark-fantasy thin skeleton, green tattered frock, quiver and wooden bow, consistent right-facing idle/retreat/draw/release/hurt poses. Follow-up: preserve sprites and replace background with flat #FF00FF.

Archer quiver-reach pose: built-in ImageGen, `godot/art/archer-quiver-source.png`, baked as `archer-8.png`. Prompt: same green-frock skeleton, right-facing, bow lowered, right hand reaching behind shoulder to grasp an arrow in quiver; flat magenta key background.

Spin color correction: built-in ImageGen edit saved as `godot/art/hero-spin-neutral-source.png`, referenced the normal hero atlas. Prompt: preserve exact sheet layout, poses and wrist/foot registration; replace red/orange skin with neutral tan, cream highlights, umber leather and muted bronze matching the normal hero; keep green key background. Re-baked into existing spin cels.

### ElevenLabs audio (2026-09-11)
Generated via the user's ElevenLabs account: 26 sound effects (`eleven_text_to_sound_v2`) and two instrumental music compositions (default Music API model). Source MP3s, playback Oggs, and complete prompts/settings are under `godot/audio/`. User direction: deep bassy distorted guitars, dark sword-and-sorcery; menu doom groove, faster combat groove. Audio is subject to the account's applicable ElevenLabs terms. Processing uses FFmpeg loudness normalization and loop crossfades. Credentials remain in ignored `.env.local` and are never included in assets or exports.

### Creature and blood revision (2026-09-11)
- Built-in OpenAI ImageGen: `godot/art/minotaur-source.png` (16 minotaur poses), `archer-death-source.png` (reference-guided archer fall poses), and revised `hero-spin-neutral-source.png` (neutral olive/tan color correction). Derived runtime cels baked with `godot/scripts/bake_creature_update.gd` and `bake_spin.gd`. No external stock imagery. Legacy `legion` roster identifier now renders an unarmed minotaur.

### Menu soundboard (2026-09-12)
- 116 ElevenLabs generated alternatives: four each for 27 effects and two music tracks, including highlight, activation and landing. Prompts and descriptions: `soundboard/manifest.json`; generation: `tools/audio/menu-soundboard.mjs` and `tools/audio/full-soundboard.mjs`. Runtime copies in `godot/audio_options/`. Source MP3s retained, listening copies trimmed and normalized to -18 LUFS / -2 dBTP using FFmpeg. Credentials read only from ignored `.env.local`. F8 opens the hidden in-game soundboard, pauses play, and applies selected variants immediately; local selections persist in user://soundboard.cfg. Music uses a two-second wrap crossfade and -19 LUFS normalization.

### Individually designed SFX, revision 2 (2026-09-12)
- Regenerated 96 active-effect alternatives with ElevenLabs. Each option has an individually authored material/action/transient/decay prompt, not a shared four-adjective template. Exact prompts and sources: `soundboard/revision-2/`; reproducible generator: `tools/audio/refine-soundboard.mjs`. Normalized listening copies replace the matching runtime option IDs. Music and disabled footsteps/bow draws retain their previous assets. Sound-lab tooltips expose each exact prompt.

### Jump slam thunder (2026-09-12)
- Four ElevenLabs thunderous ground-impact alternatives generated by `tools/audio/slam-boom.mjs`; source audio and exact prompts in `soundboard/slam-boom/`. Default runtime slam uses `godot/audio/slam_boom.ogg`. Retired footsteps, bow draw, and separate ground-arrow assets remain on disk but have no runtime sound slot or soundboard entry. Arrow ground contacts use the same arrow_hit event and mix level as character contacts.

### Magic invocation shout (2026-09-12)
- Four ElevenLabs human battle-shout performances with natural echo; sources and exact prompts in `soundboard/magic-shout/`, generator `tools/audio/magic-shout.mjs`. Default `godot/audio/magic_shout.ogg`, F8 alternatives `magic_shout-1` through `magic_shout-4`. Shout starts at cast tick 13 as the weapon rises, before lightning at tick 20.

### Block/resistance thud (2026-09-12)
- Four ElevenLabs deep dull impact options; exact prompts and sources in `soundboard/resist-thud/`, generator `tools/audio/resist-thud.mjs`. Default `godot/audio/resist.ogg`. Used for shield blocks, heavy-enemy charge resistance, and committed enemy reactions.

### Short human magic shouts (2026-09-12)
- Regenerated all four invocation shouts with ElevenLabs at 1.3 seconds, requesting one 400�500ms human syllable and a brief diffuse echo. Exact prompts and original generations: `soundboard/magic-shout-short/`; generator: `tools/audio/magic-shout-short.mjs`. Replaces existing magic_shout option IDs and default Ogg, preserving sound-lab volume/selection settings.

### Impact/burn audio and loops (2026-09-12)
- ElevenLabs generated four charge_hit and four death_fire variants. Exact prompts and sources are in `soundboard/charge_hit/` and `soundboard/death_fire/`. Default Ogg streams generated from option 1.
- `tools/audio/clean-music-loops.py` creates beat-aligned, 40ms seam-blended Ogg loops from retained music sources. Measurements in `soundboard/music-loop-report.json`.
- Legacy public artwork/fonts relocated to `asset-sources/`; required conversion/parity helpers relocated to `tools/asset-bake-source/`. Historical paths above describe original provenance.

- Enemy death flame flutter revision: four independently generated ElevenLabs effects, replacing crackling death-fire options. Exact prompts and unprocessed sources: `soundboard/death_fire/flutter-v2/`. Soft onset/fade, 2.4 kHz low-pass and -19 LUFS normalization; option 1 supplies the default. Generated with `tools/audio/death_fire.mjs`.

- Four additional axe swing variants (axe-5 through axe-8), generated independently with ElevenLabs from prompts based on Heavy chop: tighter, darker, rougher and weightier. Original options and default preserved. Prompts and raw sources: `soundboard/axe-heavy-chop/`; generator: `tools/audio/axe-heavy-chop.mjs`. Same -18 LUFS preparation as the reference option.

- Cairn stacked-stone app mark: built-in image generation from user-supplied Cairn A reference (2026-09-12). Master, PNG sizes, Windows ICO and prompt provenance in `godot/art/branding/`.

- HUD portrait atlas `godot/art/hero-portrait-v1.png`: built-in image generation, using the existing hero title artwork as identity reference. Prompt: 6 columns (neutral, left, right, pain, small speaking mouth, wide speaking mouth) by 4 rows (healthy, scratched, bruised/bloody, severely battered), consistent head scale and photorealistic dark fantasy lighting.
- Dinner voice line supplied by user: ElevenLabs Maverick, 2026-09-12T15_27_24. Converted to Ogg at -18 LUFS; volume envelope sampled at 30 Hz for mouth animation. Runtime clip and extendable line definitions: `godot/voice/`.

- Citadel background workshop v1: built-in image-generated concept and four-frame animation draft. Sources, workflow and prompts documented in `studies/backgrounds/README.md`. Not approved or integrated into gameplay.

- Citadel study V2: eight-frame sheet generated with the built-in image tool from V1 frame 0, requesting cyclic downward water and upward flame motion with fixed scenery. Source retained in `studies/backgrounds/citadel-01-v2/`; review caveats in the workshop README.

- 2026-09-12: World 1 screen 2 background, `studies/backgrounds/citadel-02-v1/base.png`, generated using built-in OpenAI imagegen. Prompt and provenance in that folder's README.md. No stock download or third-party asset. Animation atlases are locally baked texture flow.

- 2026-09-12: World 1 screens 3 and 4, `studies/backgrounds/citadel-03-v1/base.png` and `studies/backgrounds/citadel-04-v1/base.png`, generated using built-in OpenAI imagegen. Full prompts saved in each screen README.md. Local texture-flow fire atlases; no stock assets downloaded.

- Register-to-unlock speech: user-provided Downloads clip `ElevenLabs_2026-09-12T20_53_27_Maverick - Commanding and Powerful_pvc_sp85_s50_sb80_se50_b_m2.mp3`, converted to `godot/voice/register-unlock.ogg` for locked-episode feedback.

- Hero grab/toss/swallow: imagegen-derived `asset-sources/art/hero-eat-v1.png`, color-matched using the existing hero pickup sheet as reference. Runtime frames prepared by `tools/godot/bake-eat.mjs`.
- Gulp: ElevenLabs text-to-sound v2, generated with `tools/audio/gulp.mjs`; prompt retained in `godot/audio/gulp-prompt.json`.

- Weapon concept board: studies/weapons/armory-v1.png, built-in imagegen using the existing weapons-v8.png as reference. Design only; twelve rigid one-handed weapon concepts.

- Selected armory sprites: imagegen recreation of approved concept board, `asset-sources/art/armory-selected-v1.png`; extraction and hand pivots in `tools/godot/bake-armory.mjs`. Four axe-behavior skins, no additional combat mechanics.

- Holiday accessories: built-in imagegen, `asset-sources/art/holiday-v1.png`, Santa hat, pumpkin head and candy cane. Alpha-preserving sprite extraction and pose attachment metadata: `tools/godot/bake-holiday.mjs`.

Score HUD mockups (2026-09-12): studies/score-hud/directions-v1.png generated using OpenAI imagegen with current game reference. Suggested fonts Cinzel, Oswald and Rajdhani are SIL OFL 1.1; licenses: https://github.com/google/fonts/blob/main/ofl/cinzel/OFL.txt , https://github.com/google/fonts/blob/main/ofl/oswald/OFL.txt , https://github.com/google/fonts/blob/main/ofl/rajdhani/OFL.txt . Concept lettering is illustrative; no runtime font changes.
Implemented HUD font: Cinzel, The Cinzel Project Authors, SIL OFL 1.1. Source https://github.com/google/fonts/tree/main/ofl/cinzel ; font and license retained in asset-sources/fonts/cinzel.ttf and cinzel-OFL.txt.

Controls approval mockup (2026-09-12): Kenney Input Prompts 1.5, CC0, https://kenney.nl/assets/input-prompts . Used Xbox and PlayStation SVG glyphs retained in studies/controls/icons with original LICENSE.txt. Reuses the existing licensed Cinzel HUD font and original stone Back artwork. No runtime integration yet.

Controls runtime (2026-09-12): selected Kenney CC0 SVG glyphs copied to godot/art/controls and recolored white (geometry unchanged); ICONS-LICENSE.txt retained. Existing Cinzel OFL font and license copied beside them; action textures use the existing HUD material pipeline via tools/godot/bake-controls.mjs.

## Cairn voice refresh
Four user-supplied ElevenLabs Cairn voice recordings from Downloads (2026-09-13 filename timestamps): register-unlock, dinner, first big enemy, and first full mana. Exact original filenames and transcripts: godot/voice/lines.json. Converted to normalized Ogg Vorbis; no new third-party recording assets downloaded.


## Enemy impact sound pool
Twelve independently generated ElevenLabs text-to-sound v2 effects, September 12, 2026. Detailed individual prompts, labels and durations are recorded in soundboard/enemy-impact/manifest.json and godot/audio_options/manifest.json. Source recordings are retained beside that manifest; normalized Vorbis game assets live in godot/audio_options. Reproduce with tools/audio/enemy-impact.mjs (reads ignored local credentials).

