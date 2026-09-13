# Results materials and lettering

`slate.png` is a project-bound material generated with built-in imagegen from the approved `studies/post-game/results-v4.png` reference. It is used as a texture behind live UI, not as a static screenshot.

`lettering.json`, `score-*.png`, `stat-*.png` and `label-*.png` are reproducible raster lettering baked by `node tools/godot/bake-results.mjs` from the existing project Cinzel and Oswald fonts and this stone material. Score glyphs preserve their baseline and bevel during live count-up; stat glyphs use condensed Oswald. The existing font licenses remain in `asset-sources/fonts/`. Menu actions continue to use the original menu/font/fire pipeline.

The dynamic shared Cinzel font in Controls, Hall of Legends and Results uses oversampled raster rendering. Runtime MSDF was producing broken joins in the variable font, notably on 8 and overlapping serifs.

## Exact imagegen material prompt

Generate a production game UI MATERIAL TEXTURE only. Flat front-facing orthographic close-up black cracked slate matching the center panel in supplied CAIRN results reference. Charcoal-black layered stone with many fine irregular gold-brown hairline cracks, occasional slightly larger cracks and subtle mineral flecks. Texture is richly tactile and visible at game UI scale, but dark enough behind ivory text. Broad natural variation, quiet center, not a repeating geometric pattern. Even neutral soft raking light from top left, no vignetting baked in, no perspective, no object silhouette. Fill the entire rectangular 3:2 image edge to edge with only stone material. Absolutely NO text, numerals, letters, symbols, borders, frame, trim, skulls, fire, blood, UI, labels, buttons or decoration. This will be tiled/scaled underneath live game text; do not reproduce the UI screenshot.
