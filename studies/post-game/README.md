# Results and Hall of Legends concepts

Implemented in native Godot. See `IMPLEMENTATION.md` for runtime behavior, verification and local previews. The imagegen files below remain design references with sample data; `implemented-results.png` and `implemented-hall.png` are actual game captures.

## Current previews

- `results-v4.png`: results over blood splatter, short NEW record labels and Hall of Legends action.
- `hall-of-legends-v1.png`: wide and narrow list layouts using controls-view styling.
- `prompts-v3.md`: exact prompts for these previews.

Earlier images and prompt files are retained as design history. Static images illustrate appearance, not working animation, exact runtime fire, scrolling or verified responsiveness. In particular, the generated scrollbar size is illustrative: implementation must derive its size from actual overflow and hide it when all rows fit.

## Results

The post-game UI overlays the existing blood splatter, visible around the heading, panel and actions. No generated battlefield backdrop, skulls or “The Legion Endures.” Keep the large score, six session stats, dark slate, ivory type and one plain bronze panel edge. No double border or ornamented corners.

Each qualifying value, including the final score, gets a compact amber **NEW** label directly beneath it. All labels use matching typography and restrained glow, scaled to fit their cells. Multiple stat records can appear independently of the score record. Reserve room within cells so labels never shift the grid. No bottom personal-record line, record strip, duplicate score badge, or placeholder labels.

Latest runtime refinements supersede the generated reference where specified: omit horizontal dividers between individual stats; vertically center the main score with NEW immediately below; use the HUD's `AREA X/4` copy with no chapter name. Previous-best comparisons use `Previous best 116,200 (+12,250)`. Center Rise Again on the viewport with equal edge gaps to the two side actions. Footer actions drop and land one at a time, including Hall and Controls Back actions, without replaying on return to an existing results view.

Actions: Hall of Legends / Rise Again / Quit to Title. Rise Again has initial focus. Preserve the game's existing free-standing stone lettering, contour fire, focus and activation behavior. No generated button plaques or new button styles.

### Motion

- Fade and slightly settle the heading and panel over the existing blood splatter. Keep the settled panel still for readability.
- Proposed score count-up: zero to exact saved total in roughly 0.9 seconds, easing out with stable digit alignment. Session stats can appear in a short stagger.
- Reveal each earned NEW label as its value settles, with one brief amber emphasis, then hold steady.
- Buttons remain actionable during the reveal. Animation affects presentation only, never saved values.
- Returning from Hall of Legends restores settled results without replaying the animation.

## Hall of Legends

Use **Hall of Legends** consistently for the screen title and its entry on both main menu and results. Main menu becomes Begin / Hall of Legends / Options / Quit, retaining existing lettering, fire, background and overall presentation. Begin remains the default.

Follow `godot/scripts/controls_view.gd`: flat near-black backdrop, centered stone heading, muted ivory Cinzel text, thin subdued separators and barely tinted alternating rows. No framed stone slab or new scenery.

The populated screen contains only its heading, ranked table, overflow scrollbar when needed, and existing bottom-centered **BACK** lettering with fire. No subtitle, caption above Back, expanded per-run stats, selected-run detail strip, place count or latest-run summary beneath the table.

### Layout and input

- Table uses the available width and height between heading and Back, with comfortable margins and readable rows. Avoid the large unused detail area in earlier previews.
- Wide layout: Rank / Score / Reached / Time / Date. Keep column headings pinned above the scrolling rows.
- Narrow layout: reflow each ranked entry into compact stacked lines: rank and score, reached location, then time and date. Keep all table information; do not shrink five columns to unreadable sizes.
- Heading and Back stay outside the scroll viewport. Reserve their height before sizing the table; rows must clip above the Back area and never overlap it.
- Allow vertical scrolling whenever content exceeds available height, including short landscape windows. No horizontal scrolling. Show a proportionate scrollbar only on overflow.
- Support mouse wheel, scrollbar dragging, keyboard and controller navigation. Keep the focused/current row visible as navigation scrolls. Escape/controller Back returns to the originating screen.
- Preserve row focus and a valid clamped scroll position across resizing. Long labels wrap within rows; font size has a readable minimum.
- Verify wide, narrow, short and resized windows during implementation, including enough rows to overflow. The mockup alone does not verify responsiveness.

### Records and navigation

- Keep the proposed local top 10 ordered by score descending. Earlier run stays ahead on ties. Scrolling is independent of capacity: even 10 records can overflow a small viewport.
- From results, highlight and reveal the current run if it placed. If outside the top 10, show that fact on results only; the list stays a clean ranked table.
- From the main menu, begin at the top of the list.
- Back returns to the originating menu or unchanged results and restores the Hall of Legends action's focus. The visible action is always simply BACK, without an explanatory caption.
- Save the finished run once before results; reopening screens never creates duplicates.
- All records stay on this device. No accounts, online scores or network UI.

## Empty and non-record states

| Condition | Behavior |
| --- | --- |
| No saved runs | In the table area: “No scores yet.” / “Finish your first run to set a score.” Existing-style Begin and Back actions. No fake zero rows, subtitle or place counter. |
| First run | “First score recorded”; no invented previous best, delta or NEW labels for beating a nonexistent record. |
| New best score | NEW below score; “Previous best 116,200 (+12,250)” comparison remains. |
| Below best | “Personal best 128,450” / “12,250 from your best”; show actual placement on results if applicable. No score celebration. |
| Tied best | “Personal best matched”; no NEW label. |
| Outside top 10 | Results show “Outside your top 10”; no separate summary in the list. |
| One or more stat records | NEW under each qualifying value even if the score is not a record. |
| No stat records | Omit labels without empty placeholders or “No records” copy. |
| Victory | “The valley is free.” and “Run time” instead of “Time survived.” Reached column can show completion. |

## Data and comparability

Score and kills already exist. Run time excluding pauses, maximum combo, maximum multiplier and cumulative damage dealt/taken need dedicated tracking and end-of-run snapshots. Store reached area, outcome, date and a stable run ID. Damage taken can exceed starting health because healing exists.

Per-stat records compare with saved records before the current run and persist independently of top-10 retention. Proposed higher-is-better records: score, kills, best combo, peak multiplier and damage dealt. Time and damage taken stay descriptive until a comparable completion-based rule exists; quick deaths must not earn fastest-run or least-damage records.

Keep full runs and chapter starts comparable within separate scopes if both are eligible. Store scoring-rules versions to preserve older records separately after balance changes. These remain implementation proposals.
