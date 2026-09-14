# CAIRN manual mockup

Eight-page, 5.5 x 8.5 inch black-and-white booklet in reading order. The art direction is bold, moderately rough vintage fantasy ink: competent anatomy, thick contours, and restrained hatching.

Output: `../../output/pdf/cairn-manual-mockup.pdf`.

`build.py` contains editable copy and layout. Run it from any directory with Python, ReportLab and Pillow installed. It uses the repository's licensed Grenze Gotisch font and standard PDF Times/Helvetica faces. No game build or export is required.

`art/` holds the six selected illustrations, generated with the built-in image generation tool. `prompts.json` records the final prompt set. Earlier fine-engraving and deliberately crude experiments are not used in this edition.

The boss plate received one built-in image edit: "Remove the tiny signature / lettering at bottom right of this illustration, replace that tiny area with clean white background. Preserve all three characters, all linework, style, composition and dimensions exactly. No text or signature anywhere."

## Editorial status

The opening history, the barbarian's motivation, and all character biographies are proposed creative lore, not established canon. This is stated on page 2. Descriptive titles for generic enemy classes are editorial labels. The existing game supplies episode names, roster identities, visual character concepts, and the gameplay advice.

Sources checked: `godot/scripts/game.gd`, `godot/scripts/bindings.gd`, `godot/scripts/enemies.gd`, `godot/scripts/episode_combat.gd`, `godot/README.md`, `asset-sources/art/episodes/README.md`, and character source artwork. The code takes precedence over older README control descriptions. Seasonal/debug options are omitted from this compact mockup.

Print at actual size on half-letter stock, or use a PDF reader's booklet printing for folded letter sheets. The PDF is in reading order, not printer-imposed. Keep previews local.
