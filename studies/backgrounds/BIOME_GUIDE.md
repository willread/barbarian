# World 1 — Fallen Citadel visual contract

The approved aqueduct (citadel-01-v5) is the visual reference for this biome. Every new screen must be compared with it before approval. Keep these common across all screens:

- Cold weathered grey masonry, blackened iron, sparse dead vegetation and restrained copper/amber dusk and fire. No bright magical colour accents or a new architectural culture.
- Realistic worn materials and comparable texture density. Dry matte paving; avoid a glossy floor or painted highlights suggesting animated reflections.
- Same lateral camera height, restrained perspective and character scale. Canvas 16:9; a review figure is approximately 22% of image height. This is a scale guide, not an exact gameplay sprite.
- Clear continuous left-to-right floor. Walkable polygons describe FEET, entirely on supporting ground. Keep clearance from walls, rubble and drops, including at both entry edges. Avoid dramatic shape changes that imply the player can walk onto scenery.
- Vary enclosure, skyline, focal architecture and foreground-to-background distances. Do not repeat the waterfall/aqueduct silhouette; do not add giant statues as a default focal point.
- Motion stays within explicit approved masks. Keep masonry and iron stationary. Glows may modulate brightness without displacing architecture. Preserve loop continuity and the original painting outside animated areas.

## Foreground convention

Optional `foreground: [{name, polygon}]` uses normalized coordinates in the same image space as animation and walk masks. These polygons redraw the matching painting pixels AFTER actors and world effects, BEFORE HUD/UI. They represent always-front, static scenery, not collision and not Y-sorted scenery. Foreground must use the exact same image transform as the background.

Use very sparingly: low corner rubble or an occasional edge prop, no full-width front wall, no central obstruction and no large areas hiding combat. Design the walkable region separately so actors do not enter solid props. Foreground masks do not make a solid object traversable. Keep the actor's head, torso and weapon readable. Tight outlines prevent patches of the floor being redrawn over feet.

The workshop implements this compositing with scale silhouettes and editable polygons. Native gameplay now consumes these masks through the chapter asset bake. Foreground renders after actors and effects, before HUD and transition UI.

## Review each screen

Compare against the approved reference using the editor's reference toggle. Turn on actor preview and walkable outline, place the gold actor along rear/front and entry edges, and toggle foreground compositing to inspect occlusion. Confirm clean floor, readable silhouettes, matching materials/light and restrained foreground before approving. Animation/mask approval and composition approval are separate.

## Current screen 2 review

Breached Gate matches the stone/iron/dusk palette and uses the same broad paving scale. Its close gatehouse intentionally replaces the aqueduct's open vista. Its two low corner rubble masks are optional, unapproved draft boundaries. The apparent warm sheen on several paving stones should remain under review against the matte-ground guideline. Banners remain static in this first pass.

## HUD framing and upper crop allowance
The native arena fills the window width at uniform scale and anchors its bottom above the independently sized HUD. At 16:9 the upper approximately 23% of the 16:9 painting is cropped. Upper sky, roofs and arch crowns are expendable; put essential landmarks and combat cues below that band. Keep the fighting floor and actor silhouettes in the lower area. Wider windows crop more from the top; tall windows reveal more vertical space. Never shrink the whole arena merely to preserve upper scenery.

Per-screen framing: `framing.bottom_crop` is the normalized bottom slice hidden behind the HUD. The aqueduct uses 0.08; other screens default to zero. The entire world moves together, keeping actors, animated regions and foreground registered. Layout refreshes on screen changes. The editor exposes Bottom crop % with a three-percent margin beneath the walkable polygon, and shows both cropped bands in the 16:9 guide. Export edited JSON to apply framing changes to the game.
