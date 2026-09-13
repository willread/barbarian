# Post-game and local high-score concepts

Design exploration only; no runtime changes. Generated with the built-in imagegen tool on 2026-09-13. All numbers are sample data.

## Visual direction

The post-game screen sits on top of the existing blood splatter effect. Keep the blood splatter visible behind the results panel, heading and actions; the generated battlefield scenery in the mockups is not the intended post-game background. This applies to every results state, including first scores and runs without a personal best. Judge text contrast and panel readability against the actual blood splatter during implementation. This clarification supersedes the backdrop descriptions in the original generation prompts; the images have not yet been regenerated to reflect it.

Keep the large final score, six session stats, dark stone, ivory type and restrained ember focus. Remove skulls, the double border and “The Legion Endures.” Use a single plain bronze panel edge. Use the same “High Scores” label in results and the main menu. Remove the duplicated best-score badge; show a secondary record highlight only when earned.

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
| Other record earned | Optional line such as “New longest combo · 36 hits” | Can occur even when final score is below the personal best. |
| No other record | Omit highlight text | No empty badge placeholders or “No records” message. |
| Victory | “The valley is free.” / Time: “Run time” | Outcome in selected details reads Victory. |

For the initial design, ranks refer to comparable runs. Full runs and chapter starts should not compete in the same table; expose a scope selector only if both are score-eligible. Keep scoring-rules versions with saved records so later balance changes can preserve old records separately. These are proposed behaviors, not implemented systems.

## Session data

Score and kills already exist in the game. Run duration excluding pauses, maximum combo, maximum multiplier, cumulative damage dealt and cumulative damage taken need dedicated end-of-run snapshots/tracking. Store the reached area, outcome, date and a stable run identifier alongside them. Damage taken can exceed starting health because healing exists.

## Deliverables

- `results-v2.png`: revised personal-best results screen.
- `menu-and-high-scores-v1.png`: main-menu entry and populated local list.
- `states-v1.png`: non-record results, first-run results and empty-list designs.
- `prompts.md`: exact generation prompts.

The generated typography and scenery are illustrative. These images are review references, not production UI assets. The outer outlines around individual screens on the comparison boards are presentation framing; omit those from the game. Only the stone panel gets a single border. The menu study illustrates entry placement; preserve the existing main-menu lettering and background during implementation rather than adopting the generated button plaques or changing scenery.
