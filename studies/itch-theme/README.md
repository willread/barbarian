# Cairn — Stone & Bronze itch.io theme study

Local preview: http://localhost:3014/ . Start from the repository root with
`node studies/itch-theme/serve.mjs`. No packages or build step required.

The preview's Theme recipe link opens the complete research and setup guide.
`theme.json` is a human-readable recipe, not a supported itch.io import format.
Paste only `description.html` into itch.io's description HTML editor. Do not
upload `index.html`, JavaScript, or `preview.css` as a theme.

## Scope and accuracy

Uses the ordinary theme editor with a smaller original Cairn logo over a full-width firelit stone war hall, no
subtitle, a continuous stone page background, Cinzel headings, Libre Baskerville body,
bronze links and a bronze native button. BG2 is #101213 at 68% opacity. The same
translucent panel spans header and body, revealing one background beneath the alpha-faded header. The stone also extends outside the panel. No separate panel
texture, custom button shape, bevel, or other custom-CSS effect is simulated.
The documented desktop column is 960px and the description is 553px. Platform
chrome, gaps, native buttons, and responsive breakpoints are approximated.
The mockup is not the live itch.io renderer and needs a final draft-page check.
No custom CSS approval is needed for the proposed theme. Actual control names
for background fit and available font-size increments must be confirmed there.

The local toolbar lets reviewers switch between downloadable and browser
layouts. Both explicitly retain Sidebar. Browser mode is a placement mockup,
not an embedded game build; Run game opens the existing localhost:3001 server.
Price, final release state, credits, requirements, and uploaded builds remain
publishing decisions. The local Download Now button explains that it is inert.

The local trailer player maps to the public supported-host trailer URL on itch.io
(YouTube or Vimeo for video); do not treat a raw local MP4 URL as that field.
The server reads E:/Cairn-build-tools/trailer/cairn-first-cut.mp4 without copying
the video into Git. Other machines need that file or a changed server mapping.

## Current header

`assets/header-v4.png` is the uploadable PNG banner. The original logo is scaled
to 43% of the banner width and composited over generated `header-scenery-v4.png`; its
lettering is not regenerated. Run `node studies/itch-theme/compose-header.mjs`
to reproduce. Header padding is zero so artwork fills the panel width. Only the bottom edge
breaks into transparent jagged stone, revealing the shared page texture and the bottom
edge is fully transparent. No custom CSS is required.

## Assets

- `assets/masthead-v1.png`: unused first-iteration promotional art, built-in image generation.
  Exact generation prompt: `masthead-prompt.txt`. Native output 2172 × 724;
  Retained for history; not displayed in the current concept.
- `assets/banner.png`: original transparent Cairn logo source and embed mockup.
- `assets/panel-stone.png`: unmodified `godot/art/stone-border-v1.png`, used as the page background.
- `assets/background.png`: original `godot/art/title-background.png`, used in the browser embed mockup only.
- `assets/aqueduct.jpg`, `foundry.jpg`, `keep.jpg`: actual native trailer frames
  at 1.1, 9.5 and 19 seconds, extracted with ffmpeg without visual alterations.
  These are staged gameplay from the previous trailer, not latest-build captures.
- `assets/cinzel.ttf` and OFL: existing project font and license.

The listing cover is separate from the page banner. itch.io specifies a 315:250
cover ratio (minimum 315 × 250; 630 × 500 suggested), and recommends 3–5 screenshots.
A listing cover was not generated as part of this theme study.

## Primary sources, checked 2026-09-16

- https://itch.io/docs/creators/design — standard controls, columns, banner,
  typography, trailer hosts, responsive behavior.
- https://itch.io/docs/creators/css-guide — 960px/553px geometry; account approval
  for CSS; scope to #wrapper; custom- class prefixes; retain platform footer.
- https://itch.io/docs/creators/getting-started — cover ratio, screenshots,
  description formatting, project setup and draft visibility.
- https://itch.io/docs/creators/html5 — uploaded HTML5 builds and click-to-play.

No game code changed; no native export required. The preview and all 13 local
image/font/content routes were checked over HTTP, including video byte ranges.
The original logo and stone texture were checked for byte identity with their
source files. Browser visual QA and live itch.io validation were not performed.
No live itch.io account was changed or content published.

Current delivery: E:/Cairn-build-tools/itch-page-assets (loose files, no ZIP).
The background is panel-stone-fine.jpg: 1600 x 1600, JPEG quality 70, 560638 bytes.
A mirrored 2 x 2 arrangement reduces displayed stone scale by half while joining
the texture edges. Original source PNG is retained. Run package-kit.ps1 to refresh
the folder; it no longer creates an archive.

Latest background supersedes the mirrored version: stone-tile-512.jpg, 512 x 512,
39369 bytes. New staggered masonry generated with built-in image generation,
reduced and compressed with opposing borders matched in a narrow feather band.
Reviewed as a 2 x 2 repeat. Use repeat both directions at original size, not cover.

Header v4 replaces the foreground carved head with a slumped skeleton and removes
the rightmost of the three background statues. The unused first masthead is
archived at E:/Cairn-build-tools/itch-theme-generated/unused-masthead-v1.png.
