# Cairn — Bronze & Ash itch.io theme study

Local preview: http://localhost:3014/ . Start from the repository root with
`node studies/itch-theme/serve.mjs`. No packages or build step required.

The preview's Theme recipe link opens the complete research and setup guide.
`theme.json` is a human-readable recipe, not a supported itch.io import format.
Paste only `description.html` into itch.io's description HTML editor. Do not
upload `index.html`, JavaScript, or `preview.css` as a theme.

## Scope and accuracy

Uses the ordinary theme editor, with a new 3:1 masthead, existing atmospheric
background, Cinzel headings, Georgia body, bronze links and rust-red buttons.
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

## Assets

- `assets/masthead-v1.png`: new promotional art, built-in image generation.
  Exact generation prompt: `masthead-prompt.txt`. Native output 2172 × 724;
  shown without cropping. This ratio is a design choice, not an itch.io limit.
- `assets/banner.png`: original transparent Cairn logo used only in embed mockup.
- `assets/background.png`: original `godot/art/title-background.png`.
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
Measured contrast on the opaque panel: body 12.51:1, links 8.36:1; white text on
the button is 7.69:1. The panel is 96% opaque in the preview. Browser visual QA
and live itch.io validation were not performed.
No live itch.io account was changed or content published.
