# Post-game and local high-score concepts

Design exploration only; no runtime changes. Generated with the built-in imagegen tool on 2026-09-13. All numbers are sample data.

## Visual direction

The post-game screen sits on top of the existing blood splatter effect. Keep the blood splatter visible behind the results panel, heading and actions; the generated battlefield scenery in the mockups is not the intended post-game background. This applies to every results state, including first scores and runs without a personal best. Judge text contrast and panel readability against the actual blood splatter during implementation. This clarification supersedes the backdrop descriptions in the original generation prompts; the images have not yet been regenerated to reflect it.

Keep the large final score, six session stats, dark stone, ivory type and restrained ember focus. Remove skulls, the double border and “The Legion Endures.” Use a single plain bronze panel edge. Use the same “High Scores” label in results and the main menu. There is no personal-record line or badge strip beneath the panel. Every eligible stat that beats its previous personal best gets its own “NEW PERSONAL BEST” label directly beneath its value, matching the score label's typography, amber color and restrained glow at a size appropriate to the stat cell. Multiple stat labels can appear together even when the final score is not a record. Reserve consistent space inside each cell so labels do not move the grid. Unbeaten stats show no record label or placeholder.

## Motion and button treatment

- Let the existing blood splatter remain the backdrop; bring in the heading and panel with a short fade and slight settling motion. Avoid continuous panel movement that makes stats harder to read.
- Proposed timing: count the final score from zero to its exact saved total over roughly 0.9 seconds, easing out near the end. Keep digit alignment and width stable. Session values can appear with a short stagger rather than six competing count-ups.
- Reveal earned personal-best labels as their values settle, with one brief amber emphasis, then hold them steady. The score label follows the same treatment. No looping celebration pulses across the stats.
- Buttons use the game's existing contour fire and heated lettering treatment, including its focus and activation behavior. Do not replace it with the generated outlined button plaques or a new fire imitation. Rise Again receives initial focus; keyboard, controller and pointer focus all drive the same effect.
- Actions remain responsive during the reveal; activating a button performs its action without waiting for the score animation. The animated number is presentation only and never changes the saved score. Returning from High Scores shows the settled results without replaying the reveal.
- These motion timings are proposed for implementation, not present in the static images. The generated images and original prompts also predate the per-stat label change above.

## Navigation

- Main menu: Begin / High Scores / Options / Quit. Begin remains the default focus.
- Results: High Scores / Rise Again / Quit to Title. Rise Again remains the default focus.
- Main menu -> High Scores -> Back to Menu, restoring High Scores focus.
- Results -> High Scores -> Back to Results, preserving the result and restoring High Scores focus. Opening the list never starts another run.
- The list shows up to 10 saved runs ordered by score, highest first. Selecting a row exposes its session details in the lower strip.
- Opening from results selects the current run if it placed. Otherwise show a separate “Latest run · Outside top 10” summary below the ranked rows without replacing a ranked entry. Opening from the menu selects rank 1.
- Save the finished run once before presenting results. Reopening either screen must not add a duplicate.
- Keep everything on this device. No online scores, accounts or network UI.

## States

| Condition | Score-area copy | List behavior |
| --- | --- | --- |
| No saved runs | Not applicable before a run | “No scores yet.” / “Finish your first run to set a score.” / Begin / Back to Menu. No fake zero-score rows. |
| First finished run | “First score recorded” | One real row; no invented previous best or percentage improvement. |
| New personal best | “New personal best” / “Previous best 116,200 · +12,250” | New rank 1, selected when opened from results. |
| Below personal best | “Personal best 128,450” / “12,250 from your best” | Show actual placement if within the top 10. No celebration styling. |
| Equal personal best | “Personal best matched” | Keep earlier run ahead on ties; do not claim an improvement. |
| Outside top 10 | Personal-best comparison plus “Outside your top 10” | Preserve the ranked list and show latest run separately when entering from results. |
| Other record earned | “NEW PERSONAL BEST” beneath each qualifying stat value, styled like the score record label; no bottom record line | Can occur for several stats, even when final score is below the personal best. |
| No other record | Omit per-stat record labels | No empty badge placeholders or “No records” message. |
| Victory | “The valley is free.” / Time: “Run time” | Outcome in selected details reads Victory. |

For the initial design, ranks refer to comparable runs. Full runs and chapter starts should not compete in the same table; expose a scope selector only if both are score-eligible. Keep scoring-rules versions with saved records so later balance changes can preserve old records separately. These are proposed behaviors, not implemented systems.

Per-stat records compare against saved records before the current run, independently of whether that run enters the score top 10. First runs establish baselines without claiming to beat a previous record; ties do not get “NEW PERSONAL BEST” labels. Proposed initial higher-is-better records are score, kills, best combo, peak multiplier and damage dealt. Time and damage taken remain descriptive until a comparable completion-based rule is defined: a quick death must not become a fastest-run or least-damage record. Keep personal stat records separately from the top-10 list so dropping a run from that list does not erase its records.

## Session data

Score and kills already exist in the game. Run duration excluding pauses, maximum combo, maximum multiplier, cumulative damage dealt and cumulative damage taken need dedicated end-of-run snapshots/tracking. Store the reached area, outcome, date and a stable run identifier alongside them. Damage taken can exceed starting health because healing exists.

## Deliverables

- `results-v2.png`: revised personal-best results screen.
- `menu-and-high-scores-v1.png`: main-menu entry and populated local list.
- `states-v1.png`: non-record results, first-run results and empty-list designs.
- `prompts.md`: exact generation prompts.

The generated typography and scenery are illustrative. These images are review references, not production UI assets. The outer outlines around individual screens on the comparison boards are presentation framing; omit those from the game. Only the stone panel gets a single border. The menu study illustrates entry placement; preserve the existing main-menu lettering and background during implementation rather than adopting the generated button plaques or changing scenery.
