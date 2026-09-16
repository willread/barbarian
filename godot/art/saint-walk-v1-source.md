# Kiln Saint walk cycle

Created with built-in imagegen, referencing `asset-sources/art/episodes/saint.png`. Final prompt requested eight sequential right-facing profile walking poses in a 4x2 transparent sheet: wide heel contact, weight acceptance, lifted passing foot and opposite contact, repeated on the other leg. Preserve closed riveted furnace chest, skull helmet, massive pauldrons, ragged skirt, plated boots, trailing chains and lowered furnace hammer. Require visible knee bends, alternating planted feet, body weight shift, hammer counter-swing and chain follow-through; fixed scale/floor baseline, full silhouettes, no text, shadows or scenery.

Extract complete silhouettes with `node tools/godot/bake-saint.mjs`. Runtime uses eight frames per 220 world-pixel gait cycle, scaled by actor size. Reverse the cycle when retreating to keep the leg motion consistent with travel.
