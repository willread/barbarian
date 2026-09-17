# Selective loading and 4K texture audit

## Loading changes

- Startup no longer walks the assets directory or loads every actor atlas. Menu art loads as needed; the unused legacy valley no longer initializes behind the title screen.
- Starting gameplay warms the player's animations, hand overlays, shared equipment, fire frames and selected weapon. These resources are needed across episodes and remain cached.
- Each area warms the enemy types in that area's encounter plan, including its later waves and boss. Reinforcements therefore do not need to load their first animation frames during combat. Enemy cache entries from earlier areas are released when no longer part of the plan.
- Changing scenery drops old background and animation-sheet entries from the cache. Scene nodes release their remaining references when freed.
- Episode 2/3 music loads when selected, rather than at startup. Unselected episode tracks release their streams; the swamp loop is prepared for episode 2. Existing pause, looping and single-track playback behavior is retained.
- Bomb core and light-gradient textures are shared across bomb lifetimes and prepared before areas containing throwers or the Saint. They are released when leaving areas that need them. They are not globally preloaded into shareware or episode one.

This is selective area loading, not background streaming: area preparation happens at the existing area transition. The initial area still has a loading cost. It avoids replacing startup loading with a first-hit animation hitch.

## 4K audit

The audit reads source dimensions and runtime drawing metadata. Its generated data is in `texture-resolution-audit.json`; rerun with `node tools/godot/audit-texture-resolution.mjs`. No artwork was resized in this change.

| Asset | Source | Rendered at 4K | Assessment |
|---|---|---|---|
| Bomb body | 1254 × 1254 | Approximately 197 × 219 | Clearly more resolution than needed. A 512 × 512 runtime derivative would still provide over twice the required linear detail. |
| Largest swamp animation sheet | 3960 × 5760 total | Each 330 × 240 frame renders at 990 × 720 | Not oversized spatially. The sheet is large because it contains 288 frames. |
| Level paintings | Approximately 1672 × 941 | 3840 × 2160 | Already enlarged; downsampling would lose detail. |
| Reviewed actor atlases | See generated data | Enlarged further for large variants | No blanket reduction justified. |
| Unlockable weapons | 647–837 pixels tall | Approximately 288–437 pixels tall in gameplay | Modest candidates, but retain filtering/rotation headroom. Total savings are small. |
| Cutscene panoramas | See generated data | Drawn across 7680 pixels of width while panning | Must account for the full pan, not just one visible 4K frame. |

A 512² bomb texture would use about 1 MiB of uncompressed RGBA pixels versus 6 MiB now, saving roughly 5 MiB. A 256² derivative would provide little sampling headroom for rotation, so 512² is the conservative candidate. Keep the full-resolution source for editing. This estimate is not a measured VRAM or download-size saving.

The largest potential memory win is avoiding resident assets that aren't needed, not reducing the resolution of the backgrounds. Reducing animation frame count is a separate quality tradeoff and was not done.

## Validation

`asset_loading.gd` verifies title-only startup, warmed player frames, retained bomb resources, old-scenery eviction and release of unused enemy atlases. `episode_music.gd` verifies deferred music, looping, pause continuity, immediate track exclusivity and mute. Existing audio, swamp and Saint tests also exercise the revised loading paths.

### Bomb construction measurements

On the RTX 4070 with the graphical renderer active, 12 constructions per condition:

| Condition | Mean | Maximum |
|---|---:|---:|
| Explicitly release resources between bombs (cold control) | 25.06 ms | 27.48 ms |
| Retain the prepared resources (new gameplay behavior) | 0.103 ms | 0.125 ms |

This isolates the resource-loading hitch: the warmed constructor is about 243 times faster in this probe. It does not measure explosion rendering or promise that every possible frame spike is eliminated. The probe used source imports; the earlier packaged-build probe independently measured approximately 23.57 ms cold versus 0.216 ms with the texture retained. Headless selective-loading tests also measured every warmed construction below 1 ms.

Run the graphical probe with `tools/godot/benchmark.ps1 -AssetProbe`; add `-ExportedAssets` after rebuilding the Windows package. The web export and its packaged audio validation passed at build 17. Windows replacement was blocked by the running game at the time of this audit.
