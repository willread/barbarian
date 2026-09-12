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
