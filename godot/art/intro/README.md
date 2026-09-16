# Episode 1 opening

The static ink panorama moves left to right by one 1440-pixel viewport over
8.2 seconds, following a 0.8-second establishing hold. The scene ends at 11.5
seconds, including a fade into the normal Episode 1 entrance. Any keyboard key, mouse button, controller button or trigger skips after the
first half-second. No skip label is shown.

The original panorama was generated with the built-in image-generation tool
for the user's approved concept: a continuous ink-drawn landscape showing
Cairn's burning hut, demons stealing his goat, and Cairn gripping his axe in
revenge. `godot/art/hero-portrait-v1.png` supplied the character reference.
The image is rendered at two screen widths, with a centered vertical crop.
There is no animated deformation or movement within the illustration.

Narration is the user's supplied Downloads file:
`ElevenLabs_2026-09-16T02_57_34_Cairn_gen_sp90_s50_sb75_se0_b_m2.mp3`.
The source is split at its natural pause without changing delivery: the first
line plays at 1 second; the second at 6.4 seconds, as Cairn comes into view.
The user supplied the exact words. Subtitles follow the separated lines.
Subtitles are white on a solid black bottom strip and remain visible when muted.

A single generated distorted guitar power-chord stab lands at 5.94 seconds,
0.46 seconds before "Now". Its short tail ducks by 16 dB as the
second line starts. It follows music/mute settings and stops on skip.
The original sound and generation prompt are in `soundboard/cutscenes/`.

Only a fresh Episode 1 selection plays the introduction. Retrying after death
goes directly to gameplay. Other episodes retain their existing entrances.

The existing music continues without restarting during the cutscene at 70%
of its normal amplitude (about -3.1 dB), then restores the normal mix on exit.
Narration and the opening guitar sting keep their own levels.
