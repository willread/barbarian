# Results and Hall of Legends implementation

The native game now uses the results panel above its existing blood splatter, a 0.9-second score count-up, per-stat NEW markers, and existing stone/fire menu actions. Both defeat and victory end in this view. Hall of Legends is available from the title and results, and Back restores the originating view without adding another score or replaying the results reveal.

The visual parity revision replaces the initial flat text and nearly black panel with carved Cinzel headline/score glyphs, condensed Oswald stat numerals, cracked-slate material, a single bevelled bronze edge, section rules and amber record halos. Layout proportions now follow the approved results-v4 reference. The slate is cropped without distortion in wide and portrait panels. The lettering is baked from the project's fonts, remains live during score animation, and preserves its texture and bevels at arbitrary score values. Rebuild it with `node tools/godot/bake-results.mjs`; the material's exact imagegen prompt is recorded in `godot/art/results/README.md`.

Controls, Hall of Legends and the remaining dynamic results copy now use oversampled raster Cinzel. This removes the broken joins and holes caused by switching that variable font into MSDF mode at runtime. Native captures checked Controls as well as both new screens. The browser preview was also inspected at 1280×720 and 540×960 with Hall navigation, scrolling, and return to results; it logged no browser errors. The saved implementation screenshots now show that revised browser render.

The hall follows the controls screen: stone heading, readable table, subtle row separators, existing Back action. It has no subtitle, extra run-detail panel or place counter. Wide windows use columns; narrow windows stack the same information in each row. The heading and actions stay fixed while overflow scrolls. Mouse wheel/scrollbar and keyboard/controller row navigation are supported. In very short results windows the stats panel also scrolls; Page Up/Down and the mouse wheel expose the remaining stats.

Records are local in Godot's `user://records.json`, with a temporary-file write and previous-save backup. The top ten use stable score ordering; equal scores retain the earlier run first. Personal bests persist independently of top-ten retention. First runs establish baselines; equal/below-best scores don't claim NEW. Duration excludes pauses. Damage totals count actual health removed, including healing followed by further damage, and display whole units. Damage/time do not receive misleading least-damage/fastest-death awards.

Current scoring scope is the full Citadel run, versioned `citadel-v1`. There is no partial chapter-start mode in the current game; future incompatible rules should use a separate scope.

## Local review

- Normal game: http://localhost:3001/
- Direct results review: http://localhost:3001/?results-preview
- Windows: `E:/Cairn-build-tools/build/windows/Cairn.exe`
- Windows review mode: launch the executable with `--results-preview`.

Review mode seeds sample records in memory only. It never writes them into the player's records. Command-line tests/captures and headless runs likewise avoid the player's record file. Normal play persists real records.

## Verification

- `npm run godot:test` passed: record persistence/backup recovery, ties and independent bests, screen navigation, responsive bounds, combat tracking, plus the existing native regression suite. The existing wave/audio test emits a one-object shutdown warning; it completes successfully.
- `npm run godot:build` exported Web and the single Windows executable successfully.
- `tests/results_ui.gd` passed against both actual exported packs, covering imported UI assets as well as navigation.
- Native rendering inspected at 1920×1080, 1280×720, 640×360 and 540×960, including empty, first-run, tied-score and populated views. The test capture option is `--capture-results`.
- The controls navigation test now waits for audio-thread cleanup before shutdown. The pause test's main-menu assertion includes the new Hall of Legends entry.

Implementation is in `godot/scripts/run_records.gd`, `results_view.gd`, `hall_view.gd`, and their game/menu integration. The Hall title is baked with the same Cinzel stone treatment as Controls; its menu action uses the existing Anton stone renderer and contour-fire data.
