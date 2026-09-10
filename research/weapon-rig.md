# Independent weapons and consistent hero presentation

The active hero uses five weapon-free sheets containing 48 whole-body cels. The close-combat sheet has 12 cels: pommel, backward attack and kick. The four grab cels are omitted. Grab selection, victim attachment and the throw attack definition have been removed; close staggered enemies now receive the pommel/kick follow-up sequence.

`public/hero-rig.js` supplies source-coordinate hand sockets and a head-size reference for each pose. Uniform scaling keeps the head at 42 world pixels while preserving crouches, foreshortening and connected limbs. Skin is calibrated to a common tan hue and luminance range while retaining painted shading. The hero's invulnerability brightness filter is removed.

The axe and sword are separate painted textures. Each weapon has one fixed length and grip position; its entire image rotates around the authored hand socket. The axe head cannot rotate or resize independently of its shaft. Two-handed poses derive orientation from both fists. Original body pixels mask the handle beneath the fingers; no independent limb animation is introduced. Shoulder charges put the weapon behind the body.

The Weapon selector swaps axe and sword immediately and preserves the selection on restart. Both currently share the established attack timing, reach and damage. To add another weapon, add a texture cell and a `weapons` entry with its frame, length and grip fraction; the core body sheets and their animation timing remain reusable.

Idle continues to use one canonical painting with a cached breathing deformation. Its chest region has been recalibrated to the new weapon-free bounds. Face and lower body remain pinned.

Validation: mechanics regression suite, game simulation including weapon selection/restart, and offline Canvas rendering of all 48 poses with both weapons. Generation used reference-image edits for bodies and a standalone weapon sheet. Exact prompts and source paths are in `weaponless-art-prompts.json`; the corrected backswing grip prompt is in `weaponless-close-hand-fix-prompt.txt`. Retired sheets and ROM research remain historical references, not active animation sources.
