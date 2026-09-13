# The Sunken Wilds — background prototype v1

Run `npm run level:editor`, then open http://localhost:3002/swamp-v1/index.html . Four original 1672×941 paintings are displayed at 1280×720 in a standalone workshop. These are draft concepts, not approved geometry or native game integration.

1. Leechwater Crossing: open flooded forest; expanding marsh-gas rings and circling gnats.
2. The Witch’s Hollow: enclosed cypress shrine; rising fungal spores and wandering marsh lights.
3. The Drowned Procession: flooded funerary arches; gravity-driven droplets and timed splash rings. Bells remain static.
4. The Sunken Throne: empty root-bound court; two-beat amber sap illumination and low root mist. No boss is painted into the scenery.

The common visual contract is muted olive/brown, tactile drowned forest materials, fixed lateral camera, and continuous firm fighting ground. Draft foot positions span y=.68–.90. Actor scale is 22% of painting height. The optional crop guide marks the native arena's upper 23% crop. Background details are kept behind the fighting lane. No foreground cutout or collision geometry is proposed in this iteration.

Animation is Canvas 2D procedural overlays, not generated frame animation, baked sprites, or a native shader. The painting stays fixed. All motion repeats over eight seconds; wrapped effects fade at reset. There are independent toggles, still comparison, reduced-motion support, speed selection, pause, 30 Hz stepping, scrubbing, and seam playback. The `bounds` rectangles are review guides, not editable masks. Sap uses localized additive illumination; architecture is not displaced.

Validation: `node tools/godot/check-swamp-study.mjs` checks identical loop endpoints, actual motion, disabled transparency, an empty fighting-floor band, and near-seam alpha continuity. `--contact-sheet` exports a four-screen visual overview. Endpoint equality is not proof of artistic approval.

Art provenance: built-in OpenAI ImageGen, using `asset-sources/art/swamp-concept-v4.png` as the reference. Each prompt requested a single realistic 16:9 painting, no actors/UI, clear lower-third fighting lane, landmarks below the crop band, and the screen-specific architecture described above. Original outputs copied into this directory unchanged. The local preview is the deliverable; native integration and final animation baking are future work.

