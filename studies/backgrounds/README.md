# Background approval workshop
Open /background-study/index.html in the local preview. The study is intentionally independent of the Godot game: no combat loop or export is needed for artwork iterations. Copy studies/backgrounds into the preview's background-study directory after changes; the normal build also copies it.

Each immutable version folder contains screen.json, original concept, frame source and four registered frame images. Regions use normalized polygons, individually selectable and independently timed. Playback uses opaque frame replacement, never UV warping or frame crossfading. Current first draft: two regions, waterfall/splash and brazier. Mist remains static. Generated frame registration is imperfect and requires review; do not describe it as approved or final manual animation. Preview images are 1280x720; final high-resolution production art is pending approval.

Review composition and animation separately, record notes and export JSON. Local browser decisions are not automatically committed or deployed. After user approval, preserve the reviewed version and integrate its region/frame metadata with the native environment renderer. New iterations get sibling version folders.

Built-in image generation: concept prompt requested a 16:9 ruined aqueduct approach, matte fighting terrace, no statues/characters/UI, waterfall left and brazier right, muted blue-grey ruins and sunset. Frame prompt requested a 2x2 sheet of four identical-camera copies changing only descending waterfall/spray, ripples, flames and mist. Frames were generated, then split/resized for review with Pillow. No displacement shader or procedural particle overlay is used.

## V2 eight-frame loop review
Eight newly generated phases, 12 fps waterfall and 14 fps brazier. Version selector retains V1. Seam check repeats the last two and first two frames without interpolating or reversing flow. The source prompt specifies eight consecutive cyclic phases with pinned architecture, downward waterfall motion and upward curling flame; image generation still introduces registration differences. Per-region pixel-change measurements are recorded in screen.json: a similar seam delta only rules out an unusually large seam cut, not jitter across every frame. This is still unapproved draft artwork.

## V3 locked waterfall
V2 removed from active version selector; archived files retained. Uses the ORIGINAL concept painting as the immutable base. Hand-defined normalized waterfall/spray polygon, 3px soft edge, brightness-based water coverage to retain darker rock details. Only source water detail is advected downward; spray-area detail moves radially outward. Two phases offset by half a cycle blend with triangular weights; the zero-weight phase resets invisibly. No camera movement, generated scenery substitutions, or full-scene displacement.

The shader is in waterfall.js. Loop duration 2 seconds. The browser runs a real framebuffer comparison at t=0 and t=2 and displays the maximum channel difference. This verifies identical endpoints, not the artistic quality of motion. Seam review plays a short interval across the boundary. Frame step samples at 30Hz. This is a deterministic masked-flow prototype, not a hand-drawn frame atlas; it can be baked after motion approval. It deliberately leaves the other regions static. Native integration awaits user review.

## V4 waterfall coverage and brazier
Expanded waterfall perimeter and eased the brightness cutoff to include dim spray and water. Added separate fire coverage mask: bright warm flame texture travels upward, while the broader warm stone region receives only periodic lighting modulation. No masonry displacement in the fire region. Both use the two-second loop and independent region toggles. V3 retained for comparison.

### Mask refinement
Water uses a single editable polygon with identical source/destination water coverage. Fire motion uses a separate narrow flame mask; the broad glow mask only modulates light. Debug: green is moving water, bright yellow is moving flame, dim orange is lighting-only coverage. Source sampling cannot use the broad glow region.

## Standalone geometry editor
Run `npm run level:editor` and open http://localhost:3002/ . This serves the source workshop directly, without building or starting Godot. The game preview also retains its workshop link.

Enable **Edit geometry**, choose a shape, and drag its handles. Double-click an edge to insert a vertex; select a handle and press Delete/Backspace to remove it (minimum three). Shift-drag translates the selected polygon. Undo/Redo and Ctrl+Z/Ctrl+Y are supported. Water, flame motion, glow coverage and the walkable polygon are separate editable shapes. Refine their outlines directly; no per-image rock exclusions are used.

Geometry autosaves in this browser per screen. Export level JSON to preserve a portable copy and give it to the agent for incorporation in the source manifest. Import JSON restores that geometry. Browser saves do not modify repository files. Reset to source is undoable.

For targeted regeneration, Export level JSON and give the file to the agent with the regions to regenerate. The tool only previews animation and edits geometry.


## V5 approved geometry and baked loops
Uses the exact user export saved as citadel-01-v5/approved-masks.json, including the revised walkable outline. Waterfall and fire are baked into separate 60-frame atlases at 30 fps, with a two-second periodic advection cycle. This is a bake of texture flow, not regenerated AI art or hand-drawn fluid frames. The original painting stays fixed. Water uses the polygon directly without rock exclusions or colour-based exclusions. Fire motion uses its supplied flame polygon, with brightness variation in the broader glow polygon.

Rebuild: `node tools/godot/bake-background-study.mjs [edited-json]`. Adjacent-frame interpolation can be disabled. The loop renderer compares t=0 and t=2 when loaded; this checks periodicity, not visual quality. Masks may be narrowed in preview; expanding beyond baked coverage requires another bake. Source V4 remains available for comparison. No image generation service or new external resource was used for this iteration.

Water sampling refinement: a generic 3px inset plus 7px feather keeps border texels out of the donor texture. Bilinear taps are individually weighted and normalized against that inset, while destination motion eases down at the edge. This prevents outside pixels from bleeding into animation without rock-specific exclusions. Run `node tools/godot/check-background-sampling.mjs` for the contamination regression check. Texture advection remains an approximation of water motion; this does not make it a fluid simulation.

## World screen order
worlds.json records the approved World 1 screen 1 (citadel-01-v5) and draft screen 2 (citadel-02-v1). The selector defaults to screen 2 for review; the approved aqueduct remains selectable. Approval here locks the reviewed study assets and sequence designation; game progression integration is a separate step once the world screens are ready.

## Composition and foreground review
See BIOME_GUIDE.md for the shared visual and walkability contract. Actor scale / occlusion preview adds three simple human-sized silhouettes; click to place the gold figure when geometry editing is off. A green/red foot ring checks its foot point against the walk polygon. Foreground compositing redraws masked original painting pixels after these figures. Toggle it to inspect occlusion. Add/remove foreground masks in the geometry editor; they support the same vertex controls, undo, local saves and JSON exports. The reference toggle shows the approved aqueduct for palette/material comparison. These are preview tools, not native gameplay collision integration.
