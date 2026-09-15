# Furnace Mouth background revision

`02-mouth.png` replaces screen 2 only. Generated with the built-in image generation tool from `../ashen-v1/02-mouth.png`. The original remains available there.

## Edit prompt

Use case: precise-object-edit. Edit target: the attached Ashen Depths furnace gate game background. Remove EVERY red/burgundy cloth banner, including both large outer banners and the two smaller inner banners, and their freestanding hanging poles/crossbars. Fill those small areas with seamless matching volcanic rock, iron architecture and ambient smoke. Preserve the exact composition, camera, framing, central iron gate, bridges, two giant angled exhaust pipes, lighting, dark realistic painted textures, and entire empty stone combat floor. Do not replace banners with any new decorations. Keep original image aspect ratio and all architecture at its original coordinates. Also remove the frozen gray smoke puff directly exiting the LEFT large angled pipe (around 33% across, 40% down), leaving a plausible dark pipe mouth and background ready for animated exhaust. Keep both pipes fully intact and rigid, do not enlarge or reposition their outlets. All other fire/smoke remains. No text, no characters.

## Runtime animation

The empty left pipe mouth is intentional: `godot/shaders/furnace_exhaust.gdshader` supplies moving exhaust for both angled outlets. The game renders the painting at 1440 × 810; outlet anchors are (501, 302) and (1073, 426). Smoke first follows the outgoing pressure, then curls upward, with independent turbulence and pressure variation. No banner warp is applied to this screen.
