# Native Windows aspect constraint

Windows releases contain the resize hook inside Cairn.exe. No aspect DLL is distributed, extracted, or loaded by exports. Both full and shareware presets use the cached custom release template at `E:/Cairn-build-tools/godot/cairn-windows-release.exe`.

`aspect.c` handles WM_SIZING by editing the proposed rectangle before Windows applies it. It subtracts the current non-client dimensions to maintain a 16:9 client area. All eight directions preserve the opposite anchor, with individual-pixel rounding. It never corrects a drag using SetWindowPos. Fullscreen, editor, and headless operation bypass the hook.

The built-in module in `module/cairn_aspect` registers a `CairnNativeAspect` engine singleton. WindowPreferences detects this marker and skips GDExtension loading. Stock editor runs still use the development DLL/config under `godot/native`; these files are excluded from all release packs.

## Building

Normal `npm run godot:build` and the dedicated shareware script reuse the template. They rebuild it if missing or older than its source, export to the existing build location, delete the old build-folder DLL, then test the actual executable for the built-in module and absence of the DLL/config in its pack.

Manual engine build:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/native-window/build-template.ps1
```

The script pins Godot 4.7.2 (`ed1daf0bf001b61586d9930840f2f1394092c079`) and SCons 4.9.1. Sources, Python environment, dependencies, objects and templates stay on E:. MSVC and the Windows SDK must be installed. It builds with the static C++ runtime, OpenGL, statically linked ANGLE, AccessKit and Vulkan. Direct3D 12 is omitted; Cairn uses GL Compatibility. Update the pinned source and editor together when upgrading Godot.

To rebuild only the stock-editor fallback DLL, use `build.ps1`.

## Verification

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/native-window/test.ps1 -Exported
powershell -NoProfile -ExecutionPolicy Bypass -File tools/native-window/test.ps1 -Exported -Game
```

Both commands launch the actual exported game; `-Game` additionally waits for the opening presentation to finish. Each checks that the DLL is absent from the build directory and process modules, probes the installed native handler, then tests 808 WM_SIZING proposals across all eight edges. It verifies client aspect ratio, stable anchors, smooth pixel increments and absence of actual-window corrections. It launches and closes its own process and does not persist window preferences. Production templates disable external script overrides, so the build uses the internal `--native-template-test` argument for the embedded-module/pack check.

Without `-Exported`, the test exercises the stock-editor fallback DLL.

`vendor/gdextension_interface.h` retains its upstream MIT license and is used only by the development extension. Source: https://raw.githubusercontent.com/godotengine/godot/4.4/core/extension/gdextension_interface.h.
