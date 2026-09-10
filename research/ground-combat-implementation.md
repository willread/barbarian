# Ground-combat reverse engineering and implementation

Follow-up to `golden-axe-mechanics.md`, using the same user-supplied World ROM and deterministic NTSC emulator. No ROM code, graphics, emulator binaries or save states are shipped in the site. The browser mechanics are an original JavaScript implementation of the observations below.

## Verified locomotion

`public/mechanics.js` runs at the observed **59.92274340431231 updates/second**, independently of browser rendering. One source coordinate unit becomes **4.5 canvas units**, consistently for horizontal movement, depth, height and reach. The stage layout and four-wave progression are our own.

The checked-in `golden-axe-fixtures.json` contains numeric RAM observations, not extracted executable code. `node test-mechanics.mjs` compares every update of eight scenarios: walk/release, reverse, diagonal/release, held air steering, released air steering, run/release, running jump, and running attack. Position is compensated by accumulated camera displacement at RAM `FFC208`; raw screen position otherwise gives misleading apparent deceleration when the source camera starts scrolling. The source occasionally retains a negative 0.125-unit landing fraction; our drawing clamps this to the ground plane.

| Rule | Verified behavior |
|---|---|
| Walk | Velocity ramps 0.5 → 1 → 1.5 units/update; release subtracts 0.5; reversal passes through zero |
| Depth | Immediate ±1 units/update; stops immediately on release |
| Diagonal | Independent depth; horizontal displacement is reduced by 0.5 toward zero, not vector normalization |
| Double tap | Same horizontal direction accepts **16 neutral updates** between presses, rejects 17; opposite press clears the latch |
| Run | Target speed ±4, acceleration 0.5; four animation keys over 32 updates; no depth steering |
| Run release | First release update retains velocity; subsequent neutral updates decelerate by 0.5 |
| Jump | Input update enters jump, two transition updates, first upward displacement on update 3; -5.5 launch, +0.25 gravity |
| Air steering | ±0.0625 acceleration toward ±1.5, no depth movement; horizontal release sets velocity immediately to zero |
| Standing jump | Peak 63.25; ground reached at update 47, landing handling at 48, neutral at 49 |
| Running jump | Clears run velocity, launches at -7; same gradual air steering; higher and longer arc |
| Running attack | A committed shoulder-charge hop, -2.125 launch; gravity 0.125 ascending, 0.25 while descending below +2, then 0.125; contact stops horizontal travel |

The walk and run cadence advances with simulation updates instead of distance traveled. This preserves the original foot cadence during acceleration and diagonal movement.

## Combat selection, locks and active windows

Followed `006F6E–007096` through its target queries at `0070C2`, `00BB3E` and the animation sequencers at `008608/008642`. The header bytes describe terminal frame, active frame, frame count and duration. The sequencer sets the active flag from the **previous** frame index before advancing; simply assigning damage to the first displayed contact image was one update early. Counts below include the input/selection update as age 1.

| Action | Input through return to neutral | Active ages / observed first damage | Source evidence |
|---|---|---|---|
| Unselected swing | 22 updates | No active flag | State 0C, table 03A460 header 4,4,4,5 |
| Alternating ordinary blows | 18 | 8–12; 2 enemy HP damage | States 10/14; 03A474/03A488 headers 3,1,4,5 |
| Pommel blow | 22 | 13–17; 2 damage | State 20; 03A618 header 4,2,4,5 |
| Front-kick finisher | 39 | 15–20; 4 damage, knockdown | State 1C; 03A4CC header 6,2,7,6; live return at t139 after input t101 |
| Throw | 45 | Observed damage at 8; 4 damage | State 24; target-specific interaction, 03A4EC |
| Jump attack | 11-update initial phase | 7–10; 6 damage | 0076F6–007796, 03A60C; returns to jump |
| Attack + jump together | 45 | 27–32; 12 damage | State 28 backward attack, 03A520 header 8,5,9,6 |

The standing selection probe finds the tested soldier at **43 source units**, misses at 44. It accepts a depth difference of 7 and rejects **8**. This is validated for this hero/target pair; the ROM uses per-character rectangles, so these are not universal reach values for every character. The homage applies the measured pair's limits to its current roster, rechecking distance, facing, depth and height on **each active update**, and remembering struck target IDs to prevent repeated damage within one swing.

After two ordinary blows, the target's stagger state and distance choose the next move. The selector adds 4 to horizontal distance before testing 28 and 44: a sufficiently close staggered soldier can be thrown, intermediate range selects pommel blows, later stagger selects a kick. This replaces the old kill-count-dependent damage bonus. The two ordinary blows alternate logically, while sharing the established painted slash sequence.

An attack edge during the locked interval is **discarded**, not queued. Holding attack does not repeat a ground swing. Normal movement/jump cannot cancel a ground attack. Air attacks keep jump integration running and terminate on landing. The deeper held-button downward-stab branch (`007738–007766`, conditional on terrain/height) is not enabled in our flat-stage adaptation.

## Collision rectangles

`collision-boxes.py` follows `00BE78–00BEC0` and samples the frame-selected indices into hero table `0399AC` and soldier table `040252`. Entries are `[x offset, width, y offset, height]` relative to each actor's projected root. The implementation mirrors them with facing and offsets them by actual jump height. This replaces the old generic height cutoff, which incorrectly made shallow jumps immune.

| Active move | Canonical right-facing rectangle |
|---|---|
| First ordinary blow | `[16,24,-64,40]` |
| Alternate ordinary blow | `[20,32,-64,40]` |
| Pommel | `[16,16,-40,16]` |
| Kick | `[16,40,-48,24]` |
| Soldier first/third blow | `[-5,31,-46,13]` |
| Soldier second blow | `[-13,39,-75,23]` |
| Soldier charge | `[-4,13,-44,28]` |

Ground guard, attack and stagger body rectangles use representative captured entries; the player changes from a tall first stagger to a lower second stagger. Exact per-frame body variation and the remaining air/throw/back-attack rectangles use simplified bounds. The distinction between the **selection probe** at input and the **active weapon rectangle** matters: the second slash can reach farther once selected.

## Hit reactions, recovery and damage

Enemy reaction dispatch `00EA60–00EBBA` chooses stagger from the incoming action and current reaction category. First ordinary stagger is 15 + 20 plus transition = **36 updates** (`00FA1E`); the second is 25 + 35 plus transition = **61** (`00FA6E`). Both hold the target in place, cancelling its strike; the later vulnerable interval supports deliberate follow-ups. Our counter represents the complete interval rather than all source reaction flags.

Player light-hit animation takes 6/11 updates, followed by a 65-update recovery wait (`007C1E`, `007ED6`). A further hit can interrupt that recovery, allowing the source enemy's sequence to connect. Heavy hits knock the player into a -4.25 vertical / ±2 horizontal arc (`007D5E`), then a down/get-up interval. Getting up grants **96 updates** of protection (`007F10`), rather than applying the old universal 0.8-second invulnerability after every touch. The exact immunity countdown in the ROM is state-dependent; our equivalent counts simulation updates.

Soldier launch speed ±3.375 and -4 vertical follows the knockback/throw handlers at `00F85E/00F99A`. The throw briefly binds the victim to the thrower (source countdown band 56–29), then releases it behind them. The homage preserves that relationship with a whole-body victim sprite; its landing/get-up presentation and simplified throw collision are adaptations, not a transplant of the entire enemy state machine.

Source player health was 48 and base soldier health 16. The HUD retains 100% player health, mapping one source HP to 100/48 percent. Ordinary enemy blows remove 2 source HP, the third/charge 4. Soldier variants use 16/24 HP; our Warden uses 32. Existing wave rewards and scoring remain original to Ashen Axe.

## Enemy behavior

The previously extracted counterpart is definitively **type 38**, the stage-one horned club soldier, initialized at `00F3C2` and sharing the `00E498` decision dispatch. The painted skeleton uses this soldier behavior as the chosen equivalent; this is **not a decoded Golden Axe skeleton AI**.

Decoded and applied:

- Direction table `00C5DE` supplies independent ±0.5 axes; faster variants use 0.625. No easing or normalized pursuit.
- `00CB4A` assigns two player approach slots (`FFC700/FFC708`), one per side. `00CD40` uses a ±33-unit target offset for type 2. The implementation reserves one engaged fighter on either side and positions waiting fighters farther out.
- Approach decisions run every three updates (`00E81A–00E826`), with a narrow ±2 depth correction band and asymmetric -9/+7 horizontal tolerance (`00CDD4`). This replaces a per-render chase directly into the player's center.
- Distance tests 0x78 (120) and 0x62 (98) govern source run/charge decisions (`00E706`, `00E786`). The homage permits a committed charge from aligned long range, then enforces a cooldown to keep the adapted arena readable.
- The tested enemy's first attack includes an initial delay: 51 updates, active from age 29. Subsequent strikes take 40/41 updates, active from age 18. The shared active check is at `00D14C` (animation index 2). Connected sequences escalate 2 → 2 → 4 HP, with the final blow knocking down.
- `00EA34–00EA40` only continues the sequence when the target is in a hit reaction. Our enemy continues only after a connected hit against a still-standing target; moving clear of the lane makes the committed strike miss.
- Player hits cancel pending enemy contacts. Non-engaged enemies do not all initiate attacks on the same update.

The full source scheduler includes RNG tables, two-player targeting, mounts, terrain/ledge tests and additional enemy types. Our deterministic slot assignment, 40-update post-sequence rest, charge cooldown, waiting distance and Warden difficulty are **adaptations** of the decoded behavior, not falsely claimed byte-exact replicas.

## Magic

From restored stage-one state, testing 1, 2, 3 and 4 pots produced the same 267-update input-to-return envelope. Source actors freeze while `FFC104` bit 3 is set. Pot consumption occurs on update 2. The tested soldier loses 4 HP for 1/2 pots and 8 for 3/4 pots at completion.

The later user-requested responsiveness pass deliberately departs from this timing: Stormcall hits at age 6 (about 0.10s), deals 8 damage, fades out by age 42 (0.70s), and never freezes the actors. A visible 0–100 meter replaces pots. It starts full, requires 100 to cast, and gains 12 for a connected axe hit plus 20 for an axe kill. Magic hits/kills cannot refill it; wave transitions do not grant charge. Full charge becomes available after the current attack, jump or recovery ends. Eight painted lightning/dust cels replace procedural wavy lines, with ground contact registered separately for each row.

## Reproduction and validation

Local extraction scripts in ignored `work/golden-axe/`:

- `finish-mechanics.py`: controlled movement runs, attack scenarios, target spacing, natural enemy behavior, animation headers; writes `traces/finished-mechanics.json`.
- `combat-boundaries.py`: selected hit/miss, early vs ready repeat input, 43/44 reach and 7/8 depth boundaries, reaction transitions.
- `extra-pose-guides.py`: captures the actual run, charge, air attack, pommel, throw, backward attack and kick poses for painted redraws.
- `emu.py`, `show-code.py`, the supplied ROM, local core and prepared save states are required. No ROM download is performed.

`test-mechanics.mjs` compares the movement implementation to captured numeric observations and verifies combat boundaries, late entry into an active window, stagger selection and knockdown. `test-game.mjs` exercises the running application at 30/60/120/144 render Hz, pause/focus loss, simultaneous controls, fast magic damage with continued actor simulation, charge thresholds and kill bonuses, attack interruption, restart, defeat and wave completion. Offline rendering uses real textures. The production build is required before publishing.

## Scope

This completes the remaining **applicable ground movement/combat/enemy pass** for the current one-hero flat arena. It is not a complete disassembly or reimplementation of Golden Axe. Mounted combat, co-op, other playable heroes, actual skeleton/boss-specific AI, terrain/scrolling stage progression and PAL timing are outside this adaptation. Painted transitions, simplified collision rectangles and original wave design remain visible differences.
