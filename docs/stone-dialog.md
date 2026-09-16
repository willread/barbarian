# Stone dialog

`godot/scripts/stone_dialog.gd` is the reusable illustrated dialog view. Set
`title`, `body`, `detail`, and `buttons` (one or two labels) before adding it.
Text is drawn live, separate from the plaque artwork. Short single-line copy
works best; long labels shrink to fit.

Connect `chosen(index)`, `cancelled`, and `sound_requested(id)`. Call `handle(event)`
from the modal host. The host owns pause state, persistence, cursor visibility,
controller translation, and audio playback. Use a 1440×810 logical canvas scaled
to fit the viewport, as shown in `controls_hint.gd`.

Arrow keys, WASD, Tab/Shift-Tab move focus; Enter/keypad Enter/Space activate;
Escape cancels. Mouse hover and click work too. Activation requests `menu_select`
before emitting `chosen`; play it on an always-processing player so it remains
audible while gameplay is paused. The controls hint also translates controller
D-pad/stick, A and B/Start through the game's existing bindings.

The plaque was generated from the approved controls-prompt redesign. Gold serif
text, slate, bronze trim and fading ember highlights match that preview.
