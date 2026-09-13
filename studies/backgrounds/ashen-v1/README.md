# The Ashen Depths — native episode backgrounds

Four generated 16:9 paintings based on the approved Ashen concept board: Ashfall Road, Furnace Mouth, Black Crucible, Saint's Reliquary. Broad continuous basalt floors keep the episode-one combat and progression structure.

Native atmosphere lives in `godot/scripts/ashen_scenery.gd` and `godot/shaders/ashen_heat.gdshader`: drifting ash, vent exhales, falling slag sparks, breathing furnace seams. Foreground chains, iron braces and the crucible wheel render independently above actors. All loops divide a 24-second master cycle and pause with the game.

`tools/godot/bake-episodes.mjs` copies paintings and writes walkable bounds. Preview through BEGIN → EP 3 in the native game. The same bake brings the swamp's separate scenery and transparent foreground loops into EP 2.
