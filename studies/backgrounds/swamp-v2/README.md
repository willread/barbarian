# The Sunken Wilds — motion and foreground v2

Local preview: http://localhost:3002/swamp-v2/index.html (`npm run level:editor`). V1 stays available at ../swamp-v1/index.html. This iteration is a background workshop, not a native combat change; no Godot build or export is needed.

## Four scenes

| Scene | Signature | Support | Foreground |
|---|---|---|---|
| Leechwater Crossing | Submerged wake traverses the pool, dissolves into bubbles (12s) | Gnats orbit (6s), gather/disperse (12s) | Static fallen cypress branch bottom-left, swaying reed tips bottom-right (6s) |
| Witch’s Hollow | Hollow exhales a rising, spreading cloud of spores (8s) | Small bone charms swing independently (6s / 8s) | Textured upper-right bough with hanging moss and bone talisman; subtle mesh sway (8s) |
| Drowned Procession | Only the left bell swings (8s) | Gravity-driven droplets and impact rings (3s, staggered) | Sparse lower-left reeds and a low broken branch; broad view of arches retained |
| Sunken Throne | Feathered root textures swell (8s), followed by amber sap illumination | Water rings spread outward in the same breath cycle | Heavy low root clusters in both corners, subtle synchronized breathing |

Every phase is deterministic and repeats over the 24-second common cycle. Particle phases and frequencies differ to avoid uniform motion. This is a procedural and texture-transform prototype, not a hand-drawn fluid atlas. No sound is added. The still-art control holds scenery and foreground at rest and hides atmosphere. Independent effect toggles hold the bell/roots still rather than removing the objects. Foreground has separate visibility and motion controls.

Layer order: base painting → local moving scenery → atmosphere → actor guide → foreground → review guides. Click anywhere on the canvas to position the actor's feet, constrained to the draft y=.68–.90 lane. Only the edges receive foreground coverage; the central x=.30–.70 combat corridor stays completely clear. Thin edge elements may overlap feet. The native upper crop guide remains available; composition and animation are still drafts for review.

## Assets and generation

Built-in OpenAI ImageGen was used, with original generated PNGs copied unchanged here:

- `fallen-branch.png`: isolated wide dark cypress branch, thick lower-left base, thin upper-right twigs, sparse olive moss, realistic weathered bark, transparent background.
- `hanging-bough.png`: isolated upper-right crooked cypress bough, trailing Spanish moss and one bone talisman, dark realistic swamp materials, transparent background.
- `roots.png`: isolated low heavy cypress root cluster curling from lower-left toward right, cracked dark bark and moss, transparent background. Mirrored/scaled at runtime for the opposite corner.
- `procession-clean.png`: reference-guided edit of v1 procession; remove only left bell and suspension chain, fill with distant forest, preserve scenery. Only a feathered local patch is consumed at runtime, so regenerated differences elsewhere cannot alter the painting.
- `bell.png`: reference-guided isolated recreation of the original left bronze funeral bell, matching front view and weathered bronze/moss, no chain or backdrop, transparent background. Toned down at runtime to match the surrounding ruins.

The complete prompts and original tool output identifiers are in `art-prompts.json`. The existing v1 paintings remain the base references. The code-native reeds, water rings, particles, tiny bone charms and actor silhouette are drawn on Canvas. Moving roots use feathered samples of the original throne painting; architecture and throne remain fixed.

## Verification

`node tools/godot/check-swamp-v2.mjs` checks full-scene endpoint equality, near-seam pixel differences, non-static motion, alpha cutouts, effect toggles, stopped foreground motion, clear central foreground corridor and atmosphere exclusion from the fighting floor. `--render` writes the four review frames and contact sheet in this folder. Generated stills are visual review aids, not animation proof. Browser checks cover actual screen selection, playback, foreground controls, actor placement and the loop scrubber.
