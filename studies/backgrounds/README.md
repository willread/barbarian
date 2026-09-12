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
Water uses explicit stone exclusion polygons, applied after edge softening, and identical source/destination water coverage. Fire motion uses a separate narrow flame mask; the broad glow mask only modulates light. Debug: green is moving water, bright yellow is moving flame, dim orange is lighting-only coverage. Source sampling cannot use the broad glow region.

## Standalone geometry editor
Run `npm run level:editor` and open http://localhost:3002/ . This serves the source workshop directly, without building or starting Godot. The game preview also retains its workshop link.

Enable **Edit geometry**, choose a shape, and drag its handles. Double-click an edge to insert a vertex; select a handle and press Delete/Backspace to remove it (minimum three). Shift-drag translates the selected polygon. Undo/Redo and Ctrl+Z/Ctrl+Y are supported. Water exclusions, flame motion, glow coverage and the walkable polygon are separate editable shapes; Add stone exclusion creates another hole to refine.

Geometry autosaves in this browser per screen. Export level JSON to preserve a portable copy and give it to the agent for incorporation in the source manifest. Import JSON restores that geometry. Browser saves do not modify repository files. Reset to source is undoable.

For targeted regeneration, select the region, enter instructions, and Export region request. The JSON contains the complete edited level, selected polygon and a black/white PNG mask. Give that file to the agent; generation is intentionally not automatic. Preview edits affect existing motion masks immediately and do not regenerate artwork. Historical V1/V2 frame-loop descriptions above refer to archived approaches; current V4 uses masked texture flow.
