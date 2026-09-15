# Episode 2 boss polish

Game preview: http://localhost:3001/ — start Episode 2, then press ~ and enter CEO to reach the King.

- Eight authored walking poses replace the two-frame shuffle.
- Separate four-pose horizontal sweep and overhead slam, with distinct windup, impact and recovery.
- Slam locks its target at commitment. Ground fissures warn before roots emerge; damage occurs once at 0.18 seconds, only within the visible footprint. Jump or move out of the marked lane to escape.
- Below half health, two additional eruptions follow at 0.16-second intervals. All roots die with their owner and no longer leave invisible movement barriers.
- Recovery exposes the King to full damage. Health stays at 65; a close sweep alternates with the ranged slam when the player stays close.
- Heavy impact, cracking wood, restrained shake and earth fragments accompany the strikes using existing game audio.

Source artwork: asset-sources/art/episodes/king-{walk,attacks}-v2.png. Prompts are recorded beside the sheets. Bake with tools/godot/bake-king.mjs; this runs in the normal native build.

Focused validation: king_polish.gd, king_glass.gd, episodes.gd, combat_moves.gd and combo.gd. The full godot:test run stalled in the unrelated results_ui.gd test after records and difficulty passed.
