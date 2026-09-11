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
