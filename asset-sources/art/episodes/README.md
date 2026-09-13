# Episode creatures

Generated transparent eight-pose source sheets for the native Sunken Wilds and Ashen Depths episodes. Each sheet is four columns by two rows: idle, two walk poses, windup, release, recovery, hurt, corpse. The bake normalizes the witch's first two left-facing cells; the resulting atlases all face right.

`tools/godot/bake-episodes.mjs` crops alpha bounds and writes native textures and atlas metadata. Generated native textures live in the ignored `godot/assets` directory. Keep these source sheets for repeatable builds.

- Witch: hunched marsh crone, root cloak, bone-charms staff; 250px idle height.
- Bearer: undead furnace porter with slag backpack and rake; 260px.
- King: crowned drowned root monarch with root arm and exposed heart recovery; 390px.
- Saint: iron reliquary executioner with masked head, rake and open-chest recovery; 420px.

Design references: `studies/backgrounds/ashen-concepts-v1/` and the swamp studies. These are gameplay prototypes with eight authored poses, not full interpolated character animation rigs.

`mire-effect-v1.png` restores the original Bog Witch mockup's bubbling black sludge and grasping corpse hands. Its four equal cells are warning, eruption, active and collapse. The source has genuine transparency and renders at fighter depth, above feet near the center of its oval. `mire-prompt.json` records the built-in image generation prompts. The patch slows grounded movement by 72%, affects both sides, does not compound when overlapping, and collapses on the hag's death; jumping escapes it.
