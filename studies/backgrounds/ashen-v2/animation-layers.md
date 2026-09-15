# Ashen animation layers

Prepared with the built-in imagegen tool; original references remain in `../ashen-v1/`.

## Screen 1 track

`01-track-clear.png` provides the cleared railway inside one runtime shader region. Both cart textures come directly from the original painting, at their original scale. `ashen_track.gdshaderinc` places them on surveyed rail contact points and restores the foreground rail/support geometry over them. Three departure variants alternate with randomized parked and empty-track delays. The lower wrecks remain stationary.

### Clean-plate prompt

Use case: precise-object-edit. Edit target: original Ashfall Road game background. Make a clean plate for animating the EXISTING two ore carts: remove ONLY the TWO upright small ore wagons ON THE UPPER INTACT DIAGONAL RAILWAY (first cart around x=720,y=483; second around x=1180,y=549 in this 1672x941 image). Reconstruct the tiny mountain/fog/rail areas behind those carts faithfully. Preserve EXACTLY the full rail route, rail heights and perspective, all bridge supports and towers, the banners, cliffs, castle, lighting and empty stone ground. Leave the two overturned/destroyed carts on the LOWER BROKEN railway completely unchanged. Do not remove any rails or bridge geometry. No new train cars. All object positions and image framing must remain identical. The upper original carts will be restored in an animated regional layer.

## Screen 3

`03-crucible.png` is the banner-free background plate. `03-brazier.png` is a transparent layer, registered to the original hanging bowl's position and size. A small rigid pendulum rotation moves the bowl and chains together. Fire flicker is independent; descending lava streaks remain anchored to the left lip and trough.

### Background prompt

Use case: precise-object-edit. Edit target: the supplied Black Crucible game painting. Produce a clean background plate: remove both burgundy cloth banners at the extreme left and right and their hanging fittings. Also REMOVE ONLY the RIGHT of the two large foreground hanging braziers (the upright round bucket centered around x=880 y=285 in this 1672x941 image) together with its TWO supporting chains running to the top edge at x=820 and x=930, and the small fire directly inside that removed bucket. Reconstruct the obscured distant iron bridge, columns, smoke and foundry seamlessly. KEEP the LEFT tilted hanging brazier at x=580 y=185 with all its supporting chains and the bright narrow lava stream flowing from its lip to the receiving channel at x=680 y=480. Keep all distant fire/lava, bridges, gears, architecture, lighting, original coordinates and the entire empty stone combat floor exactly unchanged. Preserve the original aspect ratio and framing. No new objects, no banners, no characters, no text. The removed right brazier will be added back as a separate animated layer.

### Transparent layer prompt

Use case: background-extraction. Edit target: original Black Crucible painting. Isolate ONLY the RIGHT upright hanging iron brazier (round bucket centered x=880 y=285) with its two supporting chains at x=820 and x=930 extending through the top edge. Include its small fire and rim embers. Everything else must be genuinely transparent (alpha 0), including gaps between chain links. Retain this object's EXACT original position, pixel scale, silhouette, original dark iron/rust textures, orange reflected light and original perspective in the full 1672x941 canvas. No floor, no bridge, no smoke background, no left tilted brazier, no text. This is an aligned transparent game animation layer, not a new illustration. Do not center, enlarge, shrink or redesign the isolated object.
