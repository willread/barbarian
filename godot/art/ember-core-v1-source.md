# Caged ember core

Built-in imagegen, using the approved option 3 concept sheet as reference.

Prompt: Edit reference concept sheet: isolate ONLY design 3, CAGED EMBER CORE (bottom-left large object). Produce a single game sprite of this same bomb, centered, entire object visible with 12 percent transparent margin, genuine transparent background, no ground, no shadow, no text, no panel, no other objects, no thumbnail. Preserve the angular roughly oval cage of chunky blackened forged iron ribs, hammered metallic highlights, top iron loop and lower collar, jagged dark clinker inside with glowing orange molten cracks. Faithfully match the approved concept: archaic heavy foundry equipment, not a modern bomb. Same three-quarter camera angle. Crisp readable silhouette and broad iron ribs for display at 60 pixels high. Warm internal ember illumination, restrained orange cracks (not a uniform blazing orange ball), cool-neutral metallic edge highlights. No external bloom baked outside the silhouette: dynamic glow will be added in-engine. Square PNG transparent asset.

Runtime: independently animated ember shader, additive near-source bloom, and two
PointLight2D lights for floor projection and nearby objects. Light strength tracks
the fuse and floor illuminance decreases with projectile height. HUD is outside
the lights' Z ranges. Source art remains intact.
