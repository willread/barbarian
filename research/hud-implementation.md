# Approved bottom HUD

Approved visual direction: dark stone and weathered bronze, crowned skull at left without tusk/horn, distinct ribs and beast jaw at right. No portrait, health/mana labels, keyboard badge or weapon caption.

The imagegen production backplate is public/art/hud-bronze-v1.png. Its upper 380 pixels are rendered beneath the arena on a separate 1440x252 canvas. The upper gauge frame is reused for the lower gauge to guarantee identical geometry. Live health and mana fills use identical 895x78 source-space interiors; mana pulses at full cast readiness. Score, wave, and the actual decoded weapon texture update live. Clicking or keyboard-activating the weapon socket swaps weapons. Semantic status and accessible labels remain available without visible labels.

The arena retains its original coordinates and hitboxes. The HUD occupies separate layout space and does not obscure the fighting floor. The page header is removed; pause, sound, fullscreen, and controls remain below the game.

Validation: existing combat/input suite plus HUD weapon toggling passes; production build succeeds. Real-texture offline HUD render inspected for frame alignment, typography, weapon socket and asymmetric ornaments.
