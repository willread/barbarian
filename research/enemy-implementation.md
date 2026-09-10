# Ancient army enemy implementation

Three new regular enemies join the existing Ashen Legion:

- Bone Soldier: 12 HP, deliberate sword cut, connected cuts can lead to a slower follow-up.
- Shield Revenant: 16 HP, frontal weapon and charge blocks, slow turning, exposed flanks and a committed shield bash.
- Axe Marauder: 20 HP, faster pursuit, committed chop/overhead sequence, rushing approach against retreat. Active chops resist ordinary interruption; charge knockdowns still work.

Each new run shuffles the three regular encounter themes and mixes their compositions, entry sides and lanes. Encounters contain 3, 4 and 5 enemies respectively, guarantee all three new types, and end with the same solo Cairn Champion (84 HP). At half health the Champion gains cleave-to-overhead combinations. A boss health bar exposes this transition. The brief's cloak-tearing visual is not implemented.

Attack timings live in public/enemies.js and use the existing fixed-step mechanics clock. Lane checks, hit windows, knockdown physics, magic and persistent blood continue through the existing combat systems.

The four new body sheets contain 16 connected full-body poses each. public/enemy-rig.js attaches rigid weapons and the Revenant shield to per-pose hand anchors from public/enemy-art.js. Body scaling is constant across each sheet. Equipment has separate texture crops and grip pivots; the Champion uses the existing hero axe texture. Exact generation prompts are recorded in enemy-art-prompts.json; the supplied design brief is preserved in enemy-design-brief.txt.

Validation: test-enemies.mjs checks seeded encounter variety, guaranteed roster coverage, fixed final duel, shield directionality, turn vulnerability, attack commitment and Champion phase changes. test-game.mjs exercises the integrated damage hooks and progression alongside the existing regression suite. test-mechanics.mjs checks the original combat mechanics. Real-texture offline renders were inspected for all 64 poses and in the arena.
