# Lane layout

Aim for a consistent bottom margin of about 5% of the scene height when the
painting supports it. Keep the rear edge close to the visible shoreline or rear
ground boundary. Overlapping near rocks belong in the foreground layer rather
than cutting irregular holes in the fighting lane.

Episode 2 uses a rectangular lane from 63% to 95% of image height on all four
screens. The bake exports `movement_y` from those same bounds, so player motion,
enemy movement, separation, knockback and dodge probes can use the whole lane.
Normal two-pixel collision padding still applies at its edges.

E2 foreground fog and added branch/reed overlays are disabled. Only E2/4's
existing painted corner rocks are composited above actors. Background moss,
charms, bells, standards and distant birds remain active.
