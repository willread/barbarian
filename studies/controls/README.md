# Controls design — approval mockup

Design only. No runtime controls screen changes. Render with `node studies/controls/render.mjs` from the repository root. Open index.html to switch Combat / Menus with mouse or left/right arrows.

The design uses the actual Cinzel score HUD font and stone material pipeline for headings/actions, restrained plain Cinzel for bindings, and the actual Anton stone BACK texture from the menu. A single aligned action table replaces independent text lists. Combat and menu navigation are separated to avoid scrolling at 16:9. All simultaneous bindings remain supported; no remapping or behavior changes are proposed. Controller columns remain side by side in this reference view so neither preset is hidden. For narrow screens, the proposed implementation should retain the action column and allow horizontal paging between input families instead of shrinking the text to illegibility.

Research:
- Dark Souls official PC manual, pages 6–7: category-separated controls and aligned key/action entries. Adopt the grouping and scan order, not its bindings: https://shared.akamai.steamstatic.com/store_item_assets/steam/apps/211420/manuals/DarkSouls_PC_Manual_Online_GB.pdf
- Apple game controls guidance: expected controller UI behavior and recognizable glyphs: https://developer.apple.com/design/human-interface-guidelines/game-controls
- Kenney input prompt guidance: short labels, whitespace, readable contrast, scalable SVG glyphs: https://kenney.nl/knowledge-base/game-assets-2d/using-input-prompts
- Kenney Input Prompts 1.5: Xbox and PlayStation SVG glyphs. CC0. Only the used icons are retained under icons/, with original license: https://kenney.nl/assets/input-prompts

These are directly rendered component mockups, not generated concept lettering. Both 1920×1080 previews were visually checked. Build output and gameplay files are unchanged.

Implemented v2: combat only, no tabs or footer copy, white glyphs, shared animated stone Back button. Native captures include 1920x1080 and 540x960; 1280x720 was also checked. The live responsive view is in Options > Game > Controls. Original v1 concepts remain archived.
