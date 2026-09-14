# Episode 2 background review v3

Local preview: http://localhost:3002/swamp-v3/index.html

Review study only; native game assets remain unchanged.

| Scene | Animated details | Foreground |
| --- | --- | --- |
| Leechwater Crossing | Windblown moss, crossing marsh bird flock with independent wingbeats, rooted reeds | Sparse low branch and reeds at edges |
| The Witch’s Hollow | Nine varied skull, bird skull, paired bone and rib charms; fluttering rags; drifting fungal spores | Small corner branch |
| The Drowned Procession | Two independently swinging bells on short iron yokes with internal clappers, burning funeral brazier and rising embers | Small corner debris |
| The Sunken Throne | Rippling royal standards, turning iron pendants | None |

New paintings separate the open crossing, inhabited hollow, paired bell ruins and enlarged royal dais. Generated cutouts retain transparency and aspect ratio. Cloth and moss deform in narrow strips from fixed attachments; no animation crossfades or blur. Foreground is a separate canvas. All motion repeats over 24 seconds.

Use individual effect toggles, pause/frame step, timeline, speed, foreground isolation, actor guide, previous-scene comparison and PNG export to review. Previous-scene comparison shows the original painting.

Art provenance and prompts are in art-prompts.json. Rebuild isolated sprites with node tools/godot/bake-swamp-v3-props.mjs. Validate loops, effect controls and foreground clearance with node tools/godot/check-swamp-v3.mjs; it also renders review images and a contact sheet.

Revision: larger scene 1 motion, varied generated bone props, shorter bell suspension and funeral fire. Scene 4 is unchanged. revision-prompts.json records the new prop sheet and existing game fire source. Rebuild the additional props with node tools/godot/bake-swamp-v3-revision.mjs.
