# Floating HUD implementation

Game preview: http://localhost:3001/

Implements the approved top-center mockup: a 736×82 panel within the fixed 1440×810 game canvas, bronze trim reused without either skull ornament, portrait at left, stacked glass meters, integrated score at right. AREA and score share a left ink edge. Bold x1–x10 labels share the score baseline, including when width-limited. The boss name and thin glass health bar sit below the panel; the redundant BOSS label is removed.

The world now fills the entire 16:9 canvas without a bottom HUD reservation, camera zoom, or background-only vertical compression. Gameplay coordinates and actor scale remain unchanged. Existing window aspect enforcement and external stone padding are unchanged.

Validation: native captures at 1280×720, 1920×1080 and 800×450; x10 capture; exported Windows pack test; chapter, pause, King, swamp and combo tests. Full godot:test again stalled in the pre-existing results_ui.gd test after records and difficulty passed.
