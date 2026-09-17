# Native performance benchmark — 16 September 2026

## Scope and method

Hardware: Ryzen 7 9700X, RTX 4070, 64 GB RAM, Windows, NVIDIA driver 595.79. Godot 4.7.2 Compatibility/OpenGL renderer. Full build 15 assets.

The exploratory sweep covered all 12 screens at 1920×1080 and 3840×2160. The final, instrumented run repeats three demanding cases: E1/3 rain, E2/2 swamp animation, and E3/4 furnace combat. Only the final run is used for the results below; early runs were affected by the game's background-window pause behavior.

Each final case runs for 23 seconds, excluding the first 3 seconds from steady-state statistics. Four living enemies use their normal AI on hard difficulty; the player has artificially high health and stands still. E3/4 deliberately adds three overlapping explosion visuals every three seconds while restarting the Saint's furnace attack. Natural bomb attacks continue as well. This is heavier than the usual boss encounter, not a recording of a normal playthrough. The benchmark reports actual peak explosion count.

The game renders into an always-updating SubViewport at the full tested resolution, with the world scaled to fill it. A smaller window displays the result. No upscaling or dynamic resolution is used. VSync and FPS limits are disabled. Input is disabled for the game node, and focus-loss pauses are cleared before updates. The test asserts that gameplay remains active.

Frame intervals include engine, game, driver, presentation-preview and scheduling costs. GPU and render-thread CPU timings come from Godot's viewport timing APIs; update timings measure the explicit game update only, not total CPU frame cost. The renderer is the development Godot binary reading the shipped Windows pack, **not a direct FPS capture of the release executable**. The native window-aspect extension is unavailable in this harness; it does not control the fixed offscreen render size. Browser performance is not measured.

GPU clocks are managed normally, not locked. Other desktop applications remain open. Percentiles are descriptive measurements from this machine, not statistical confidence intervals for other hardware. CPU and GPU timings overlap and must not simply be added or scaled into an exact FPS prediction.

## Results

| Case | Resolution | Average FPS | 99% of frames under | GPU time, 95th percentile |
|---|---|---:|---:|---:|
| E1/3 | 1080p | 133 | 14.50 ms | 2.17 ms |
| E2/2 | 1080p | 424 | 4.21 ms | 0.40 ms |
| E3/4 | 1080p | 208 | 12.54 ms | 2.27 ms |
| E1/3 | 4K | 113 | 14.54 ms | 3.20 ms |
| E2/2 | 4K | 328 | 9.74 ms | 0.86 ms |
| E3/4 | 4K | 105 | 15.53 ms | 8.06 ms |

60 FPS allows 16.67 ms per frame. All six final cases had their 99th-percentile frame interval below that threshold on this machine. This does not mean every frame met it: the furnace test recorded an isolated 229.6 ms interval at 1080p and a 43.8 ms maximum at 4K. The larger isolated interval is not causally explained by the bomb constructor measurement; desktop scheduling, driver and other stalls have not been separated.

The furnace test reached seven simultaneous explosions. Its 4K GPU time was 5.92 ms on average, 8.06 ms at the 95th percentile and 9.26 ms at the 99th percentile. The rain case had the largest typical measured render-thread CPU cost; game-update cost itself was generally under 1 ms.

### Confirmed bomb creation stall

Twelve isolated bomb constructions without a retained core texture averaged 23.57 ms (maximum 25.39 ms). Keeping the same texture alive reduced construction to 0.216 ms (maximum 0.263 ms). The real gameplay test logged matching 23–27 ms update spikes as bomb views appeared. This is strong evidence for caching the bomb core texture across bomb lifetimes. It does not prove every long frame has the same cause. No production optimization was applied in this benchmarking task.

### Memory correction

The exported-pack run reported roughly 387–622 MiB of texture memory across these cases, versus about 1.5–1.6 GiB in the source-asset exploratory run. The source figure includes assets not resident in this packaged run and should not be presented as the shipped game’s normal texture footprint. These counters are neither whole-process RAM nor total dedicated GPU allocation.

### Practical confidence

- **1080p, Ryzen 5 8600G / Radeon 760M, 16 GB dual-channel RAM:** moderate confidence in a good 60 FPS experience during ordinary play. Extreme effect overlaps and the confirmed loading hitch prevent a locked-60 claim. A lower-power Radeon 660M laptop is less certain.
- **4K, RTX 4060-class:** moderate confidence in ordinary 60 FPS play; limited margin for the deliberately excessive explosion case.
- **4K, RTX 4060 Ti-class:** stronger confidence in steady rendering headroom, but the asset-creation stall is CPU-side and can still hitch.

These are engineering estimates, not tested-device results. A sensitivity check illustrates the limits: multiplying the furnace GPU 95th-percentile time by 5–8 gives 11.35–18.16 ms at 1080p; multiplying the 4K result by 1.5–2 gives 12.09–16.12 ms, before other bottlenecks. These multipliers are hypothetical slowdowns, not calibrated mappings to the GPUs above. The 60 FPS budget can be crossed at the slow end. There is enough evidence to target these systems, not to certify them without a hardware run.

**Priority:** retain/reuse bomb resources, then re-run the same benchmark. Keep the existing visuals while doing that; the measurements do not justify broadly reducing effect quality. A representative target-machine run is the remaining step before publishing minimum specifications.


## Reproduce

Run from PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File tools/godot/benchmark.ps1 -Stress -ExportedAssets
```

Omit `-Stress` for the full 12-screen sweep. Omit `-ExportedAssets` to run source assets instead. `-AssetProbe -ExportedAssets` measures bomb construction with and without retaining its texture. The benchmark is opt-in, excluded from shipped builds, and does not modify gameplay or rebuild the executable.

Raw output is written under `E:/Cairn-build-tools/performance-*.json`. A snapshot of the final measurements accompanies this report.

## Extrapolation limits

Reasonable validation targets are a Ryzen 5 8600G / Radeon 760M desktop with 16 GB dual-channel RAM at 1080p, and an RTX 4060 or 4060 Ti system at 4K. These are targets for validation, not certified minimum requirements. Low-power laptop configurations and single-channel RAM can behave differently.

AMD identifies the 8600G's integrated GPU as the Radeon 760M in its [processor specifications](https://www.amd.com/en/products/processors/desktops/ryzen/8000-series/amd-ryzen-5-8600g.html). NVIDIA lists 29, 22 and 15 shader TFLOPS for the 4070, 4060 Ti and 4060 respectively in its [comparison table](https://www.nvidia.com/en-gb/geforce/graphics-cards/compare/). Those specifications contextualize the gap; they are **not game performance ratios**, particularly for this mixture of OpenGL draw calls, transparency, texture access and procedural effects.

Godot's [RenderingServer documentation](https://docs.godotengine.org/en/stable/classes/class_renderingserver.html) describes the viewport timing APIs used by the harness.
