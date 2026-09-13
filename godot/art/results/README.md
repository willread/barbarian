# Results materials and lettering

Current lettering is baked using the existing `tools/asset-bake-source/stone-text.js` renderer and `asset-sources/art/menu-stone-material-v1.png`, with the exact Hall/Controls/HUD relief and palette settings. `new-glow.png` is a multi-radius bloom following the NEW glyph alpha. The earlier custom ivory/fissure implementation described below has been superseded; `slate-fine.png` is still the panel material.

`slate-fine.png` is the revised runtime panel material, generated from the approved `results-v4.png` reference to match its fine cellular fissures rather than the earlier material's broad marble-like veins. The original `slate.png` remains the reproducible glyph baker's mineral source. Ivory glyph fissures are deterministic, mask-clipped strokes in `bake-results.mjs`.

Exact revised material prompt: "Use case: stylized-concept. Production game material asset. Use the attached approved UI mockup solely as the material reference. Create a flat orthographic texture of ONLY the black finely cracked surface inside its score panel, edge-to-edge, landscape 3:2. Closely match its small irregular cellular cracks, subtle dark bronze hairline fissures and charcoal stone islands with quiet rough highlights. Dense fine irregular craquelure, not long diagonal veins, not marble, not gold streaks. Muted near-black overall, subtle tactile detail; no large-scale lighting gradient. Absolutely no text, numbers, borders, frame, blood, buttons or other UI. The result will be a texture behind separately drawn live text."

`slate.png` is a project-bound material generated with built-in imagegen from the approved `studies/post-game/results-v4.png` reference. It is used as a texture behind live UI, not as a static screenshot.

`lettering.json`, `score-*.png`, `stat-*.png` and `label-*.png` are reproducible raster lettering baked by `node tools/godot/bake-results.mjs` from the existing project Cinzel and Oswald fonts and this stone material. Score glyphs preserve their baseline and bevel during live count-up; stat glyphs use condensed Oswald. The existing font licenses remain in `asset-sources/fonts/`. Menu actions continue to use the original menu/font/fire pipeline.

The dynamic shared Cinzel font in Controls, Hall of Legends and Results uses oversampled raster rendering. Runtime MSDF was producing broken joins in the variable font, notably on 8 and overlapping serifs.

## Exact imagegen material prompt

Generate a production game UI MATERIAL TEXTURE only. Flat front-facing orthographic close-up black cracked slate matching the center panel in supplied CAIRN results reference. Charcoal-black layered stone with many fine irregular gold-brown hairline cracks, occasional slightly larger cracks and subtle mineral flecks. Texture is richly tactile and visible at game UI scale, but dark enough behind ivory text. Broad natural variation, quiet center, not a repeating geometric pattern. Even neutral soft raking light from top left, no vignetting baked in, no perspective, no object silhouette. Fill the entire rectangular 3:2 image edge to edge with only stone material. Absolutely NO text, numerals, letters, symbols, borders, frame, trim, skulls, fire, blood, UI, labels, buttons or decoration. This will be tiled/scaled underneath live game text; do not reproduce the UI screenshot.
