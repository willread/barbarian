# Results and Hall of Legends implementation

Latest layout: post-game actions always form a centered vertical stack, retaining their sequential drop-in and yellow fire. Heading, panel and menu are sized together and vertically centered, with panel scrolling reserved for short/narrow windows. `AREA X/4` is inside the score half below FINAL SCORE, at the same 71px local baseline center and 14px lettering height as the top stat labels (12px in compact layout). The defeat heading is `EVEN HEROES FALL` without a period. Tests verify centered, non-overlapping stacked actions at every supported test size; these changes supersede the horizontal-action notes below.

Latest text treatment: the right-hand section is **STATS**. `bake-results.mjs` now invokes the same `stone-text.js` renderer, menu stone material, bevel, extrusion and palette transforms used by the Hall/Controls heading and HUD score baker. Runtime brightness matches the HUD. Cinzel headings/score and Oswald stats retain live content and shared glyph baselines. This replaces the custom ivory renderer described in earlier revision notes below. NEW combines a letter-shaped, multi-radius amber bloom with broader reflected light and a brighter stone core.

## Mockup comparison revision

The subsequent refinement removes horizontal rules between individual stats and the decorative rules beside score NEW. The score is vertically centered above its comparison, with NEW directly below it. Results and Hall use the HUD's `AREA X/4` wording. Score comparisons use parentheses around the positive delta. The lettering baker uses medium score/stat weights, lighter headline weight, less saturated ivory, finer grain and shallower bevels/shadows.

Rise Again is anchored to the viewport center; symmetric space is reserved using the wider side action so both edge gaps stay equal. Footer drop-ins use staggered relative offsets, preserving their responsive destinations during resizing, with existing landing sounds. Results, Hall and Controls opt into this entrance; returning to the existing results screen does not restart it. Tests cover stagger timing, center alignment, equal gaps, responsive bounds and exported-pack loading. The native regression suite passes; Web and the single Windows executable were rebuilt after the game closed, including the preceding yellow-flame and Hall-lock changes.

Compared the live screens directly with `results-v4.png` and `hall-of-legends-v1.png`. Results now uses the reference's fine cellular cracked material (`slate-fine.png`), small-cap headline, wider section lettering, larger stat labels and numbers, fissured ivory score glyphs, and a prominent Rise Again action. The shared menu renderer accepts per-action emphasis and a footer height limit; the existing lettering, hit targets and fire remain in use. Portrait footers equalize the three actions and reserve more height. Post-game flames retain their requested yellow palette.

Hall now has the reference's title/table spacing, brighter table text, selection triangle, readable day/month/year dates, and a two-line stone title in narrow windows. Its title assets use the Controls baker. Ten rows fit at 1280×720; smaller windows scroll. Hall remains disabled on the main menu until a run has established a score.

Verification for this revision: native regression suite and real browser renders/navigation at 1280×720 and 540×960. The local Web export is updated. The Windows executable update remains pending while the player's Cairn process is open. The reference's generated lettering and simulated fire are interpreted through the game's existing fonts and interactive effects; these are actual runtime captures, not the concept images.

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
