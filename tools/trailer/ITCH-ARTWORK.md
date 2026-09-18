# Cairn itch.io artwork package

Preview: http://127.0.0.1:3018/

Files: E:/Cairn-build-tools/itch-artwork

## Upload choices

- Profile image: maximum-force-profile-512.png (512×512 PNG). 256×256 alternate included. Adapted from the existing Maximum Force identity; square with safe margins. Transparent full lockup also supplied for other uses.
- Project cover: cairn-cover-animated-630x500.gif (630×500, four-second looping native fire and drifting-spark animation, 48 frames, approximately 2.31 MB). Strong static first frame. Use cairn-cover-630x500.png if a still is preferred. 315×250 thumbnail included for checking small-size legibility.
- Screenshots: five 1920×1080 JPEG files in screenshots/. They are direct, unretouched frames from the user's recordings, retaining the entire HUD. Suggested upload order: 02, 03, 01, 04, 05. This leads with magic and contrasting scenery before showing player vulnerability and boss threats. No secrets shown.

The cover is promotional illustration, generated with the existing title-background.png as a character/style reference. It is not a gameplay screenshot. The cover's approved source is saved in asset-sources/marketing/itch-keyart.png. The cover uses the actual Cairn logo and licensed Cinzel typography. Sustained lower-edge fire is rendered with the game�s production ContourFire shaders via itch-fire.gd. Sparks have periodic lateral curls, varied speeds, short trails and warm bloom; the fire has a short loop-seam blend. The company identity derives from godot/art/maximum-force-logo.png. The existing profile exports remain pending clarification of the user�s truncated instruction; the latest cover-only iteration does not change them.

## Verified format guidance

Checked September 17, 2026:

- itch's official first-page guide specifies 315:250 cover aspect, minimum 315×250, recommends 630×500. Screenshots may be any size; 3–5 recommended: https://itch.io/docs/creators/getting-started
- Official quality guidelines explicitly support GIF covers and GIF screenshots: https://itch.io/docs/creators/quality-guidelines
- An itch administrator explains that profile images are cropped to the requested ratio and subject to the site's global image dimension cap: https://itch.io/t/1663307/profile-image-upload-error-message-does-not-make-sense
- All supplied individual upload files are below a conservative 3 MB budget. This avoids relying on a larger undocumented current limit. A 512×512 profile image is our export choice, not a claimed mandatory itch resolution.

## Build and validation

Run `node tools/trailer/itch-artwork.mjs` from the repository root, then `node tools/trailer/itch-preview.mjs` to serve locally. FFmpeg and @napi-rs/canvas required. Screenshot timestamps are specified in the build script. No game builds or publishing involved.

Inspected cover at 630×500 and 315×250, profile layout and gameplay contact sheet. GIF verified as 630×500, 48 frames and 4.00 seconds; periodic swirling particles and blended native flame frames loop over a fixed illustration. Screenshot files retain 1920×1080 dimensions. Keep files as supplied when uploading; no additional crops needed.
