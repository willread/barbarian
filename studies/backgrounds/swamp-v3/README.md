# Episode 2 background review v3

Local preview: http://localhost:3002/swamp-v3/index.html

Review study only; native game assets remain unchanged.

| Scene | Animated details | Foreground |
| --- | --- | --- |
| Leechwater Crossing | Hanging moss, perched heron neck movement, rooted reeds | Sparse low branch and reeds at edges |
| The Witch’s Hollow | Bone charms, fluttering rags, drifting fungal spores | Small corner branch |
| The Drowned Procession | Two independently swinging bells and clappers, loose chain | Small corner debris |
| The Sunken Throne | Rippling royal standards, turning iron pendants | None |

New paintings separate the open crossing, inhabited hollow, paired bell ruins and enlarged royal dais. Generated cutouts retain transparency and aspect ratio. Cloth and moss deform in narrow strips from fixed attachments; no animation crossfades or blur. Foreground is a separate canvas. All motion repeats over 24 seconds.

Use individual effect toggles, pause/frame step, timeline, speed, foreground isolation, actor guide, previous-scene comparison and PNG export to review. Previous-scene comparison shows the original painting.

Art provenance and prompts are in art-prompts.json. Rebuild isolated sprites with node tools/godot/bake-swamp-v3-props.mjs. Validate loops, effect controls and foreground clearance with node tools/godot/check-swamp-v3.mjs; it also renders review images and a contact sheet.
