# Whole-body animation redraw

## Breathing, shadows and Stormcall (v7)

Idle uses only the canonical hero cel zero. A compact continuous chest displacement generates a cached 48-phase, 4.8-second breath. The face, axe head and lower body retain identical pixels, and there are no independently drawn limbs or crossfades between redrawn identities. All phases are prepared during loading so no pixel processing interrupts play. Reduced motion uses the still cel. Ground shadows use a wide radial opacity falloff and soften/spread as a fighter rises.

`public/art/storm-strike-v7.png` contains eight realistic lightning, dust and ember cels blended with screen compositing. Warm light falls onto the stone under each target. The source black matte disappears through blending; row-specific baselines keep the dust grounded. Exact built-in image-generation prompt and source are in `storm-strike-prompts.json`. See `ground-combat-implementation.md` for the deliberately faster cast and earned charge meter.

## Hero consistency repair (v6)

The current hero uses `hero-actions-v6.png`, `hero-close-moves-v6.png`, and `hero-extra-motion-v6.png` for corrected rigid axe construction. `hero-reactions-v6.png` replaces both older hero sheets used for damage, collapse and jumping: four hurt/recovery cels, four collapse cels, then four jump cels. The identity reference is the established idle hero, including his face, short fur skirt, round belt buckle, bronze bracers and fur-cuffed boots. Each pose remains a single complete painting.

The runtime chroma decoder now removes dark saturated key pixels as well as bright green, and removes the green excess from partially transparent edge pixels. It preserves existing alpha. This addresses dark green pockets and fringe spill that the former brightness threshold left behind. Reduced-motion playback also retains the selected recovery/knockdown pose instead of forcing cel zero.

Exact built-in image-generation edits, references and final asset paths are recorded in `hero-consistency-art-prompts.json`. Artwork is checked through the actual texture decoder and atlas renderer on alternating dark and light backgrounds before the production build. The earlier tables below document prior versions rather than the current hero damage assets.

The v3 animation pipeline replaces the segmented PaintedRig with complete painted cels. Each displayed pose is one sprite draw. There are no separately transformed thighs, shins, feet, torsos, or weapons, and no crossfade between different silhouettes.

## Extracted references

The supplied ROM is identified in `golden-axe-mechanics.md`. Local extraction reconstructs the Mega Drive sprite layer from Genesis Plus GX save-state VRAM, CRAM, and the linked sprite attribute table. It decodes 4-bpp tiles, palette selection, tile ordering, and flips; palette index zero remains transparent. This preserves complete assembled figures and excludes scenery.

- Ax Battler: RAM object `0xFFD000`, graphics palette 0, selected animation table `0x03A340`.
- Equivalent enemy: stage-one horned club soldier, RAM object `0xFFD100`, object type `0x38` (active bit masked), palette 1, animation table `0x071F72` in the sampled state. It supplies the compact guard, cautious approach, charge, and attack body mechanics for our existing armored undead swordsman. It is not claimed to be Golden Axe's skeleton.
- Hero extraction includes walk, standing slash, and jump samples. Enemy extraction observes 420 emulator updates and captures approach, charge, recovery, and attack states. The local target health is maintained to permit observation.
- VDP display can lag RAM animation selection; the dedicated walk-key sheet samples after the graphics upload. State-transition sheets label the sampled RAM state, not an assertion that every displayed pose changes on that same update.

Local outputs are in `work/golden-axe/references/`: `ax-battler-reference.png`, `ax-battler-walk-keys.png`, `ax-battler-attack.png`, `ax-battler-jump.png`, and `enemy-reference.png`. Extraction tools and ROM-derived imagery stay in ignored local research storage.

## Original painted assets

The redraw uses the extracted pictures as pose references and the existing `hero.png` / `enemy.png` as identity and material references. The barbarian retains black hair, fur, bronze details, and his axe. The undead retains the skull, horned bronze armor, ragged cape, and sword.

The selected movement and strike assets are direct paintovers of the extracted pose guides:

| Asset | Layout | Used for |
|---|---|---|
| `public/art/hero-walk-v4.png` | 4 × 1 | Four original walk key poses, nearly frontal torso and low feet |
| `public/art/hero-actions-v4.png` | 4 × 2 | Four restrained idle cels; source windup/contact/followthrough/recovery |
| `public/art/enemy-walk-v4.png` | 4 × 1 | Four original crouched approach poses; frame 0 also supplies guard |
| `public/art/enemy-attack-v4.png` | 4 × 1 | Original anticipation, rotation, contact, back-facing followthrough |
| `public/art/hero-motion-v3.png` | 4 × 4 | Last row only: complete-body jump poses |
| `public/art/hero-combat-v3.png` | 4 × 4 | Last two rows only: hurt and collapse |
| `public/art/enemy-combat-v3.png` | 4 × 4 | Last two rows only: hurt and collapse |
| `public/art/hero-extra-motion-v5.png` | 4 × 3 | Run, compact shoulder charge, jumping attack |
| `public/art/hero-close-moves-v5.png` | 4 × 4 | Pommel, throw, backward attack, high kick |
| `public/art/enemy-charge-v5.png` | 4 × 1 | Tucked airborne charge of the source-equivalent soldier |

The four-pose walks retain the source's 40-update hero and 56-update enemy cycles. Extra generated same-leg lifts are not used. More in-between poses require another pose-accurate pass rather than playback of inaccurate candidates. The source camera angle, foot placement and compact silhouette now guide the movement art, although the painted anatomy and equipment are still stylized rather than literally registered to each source joint.

Combat now follows the measured live action windows in `mechanics.js`: a selected normal blow returns at age 18 and is active at ages 8–12; the first enemy blow is active at 29–36 of its 51-update envelope. The corresponding painted contact pose remains visible for the active interval. See `ground-combat-implementation.md` for the contextual moves and evidence.

At texture load, chroma green is removed and each connected **complete figure** is assigned to its atlas cell. This retains sword/axe overhang across nominal cell boundaries without clipping it or displaying it in another character frame. Each complete cel is drawn once, anchored to the ground. Per-atlas size factors compensate for different illustration framing so the standing body remains similar in size across actions. No limb splitting or separate weapon drawing remains.

The jump now follows actual fixed-step height and velocity, including the -7 running launch and source air steering. All movement and reach share a 4.5-unit artwork scale. Landing and recovery select complete poses from the live state. Hurt and death paintings remain full-body adaptations; the ground-combat document distinguishes measured physics from adapted AI and collision details.

Exact selected prompts, reference paths, source output paths, and project paths are recorded in `painted-animation-prompts.json`. All redraws used the built-in image-generation tool. The actual saved assets use green RGB backgrounds decoded at runtime.

The subtle background animation remains intact. Validation uses the gameplay harness, real-texture offline rendering, artwork inspection, and the production build. The local playable preview was opened for the user's requested live demonstration.

The v5 sheets use new extracted pose guides and the established painted characters as style references. Exact prompts and source paths are in `hero-mechanics-art-prompts.json` and `enemy-charge-art-prompts.json`; all used built-in image generation. Generated body registration is approximate and normalized at atlas level. Close-move cel 9 has a malformed double-ended weapon and is excluded from playback; the backward attack uses the remaining complete poses. The source run/tackle hides the weapon, so the paintover does too. No body part is animated independently.
