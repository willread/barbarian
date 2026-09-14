# Native Windows aspect constraint

`aspect.c` is a small C GDExtension that subclasses only this process's main Godot window. It handles `WM_SIZING` by editing the proposed outer rectangle before Windows applies it, subtracting the current non-client dimensions to maintain a 16:9 client area. It never calls SetWindowPos or changes the actual size during a drag. All eight drag directions preserve the opposite anchor; corners project the pointer proposal onto the aspect line. Dimensions round to individual pixels rather than 16-pixel increments.

Fullscreen bypasses the handler. The editor and headless tools are excluded, and the original window procedure is restored on unload. Windows display scaling is handled using the window's live client/border dimensions. WindowPreferences explicitly loads the extension configuration on native Windows, so Godot does not auto-load it on unsupported platforms. Web exports exclude `godot/native/*` entirely.

Build: `powershell -NoProfile -ExecutionPolicy Bypass -File tools/native-window/build.ps1`

Native integration test: `powershell -NoProfile -ExecutionPolicy Bypass -File tools/native-window/test.ps1`

Add `-Exported` to test the actual Windows export and its DLL.

The test launches its own hidden Godot window, verifies the installed handler, and sends 808 WM_SIZING proposals covering all edges, stable anchors, pixel increments and the absence of actual-window corrections. The test caller uses per-monitor DPI awareness to match Godot's coordinate space.

The checked-in DLL is built with MSVC and the static C runtime; exports place it beside the single Cairn.exe build. `npm run godot:build` rebuilds it when the source changes. Intermediate compiler artifacts remain in E:/Cairn-build-tools/native-window.

`vendor/gdextension_interface.h` is the unmodified Godot 4.4 stable C ABI header, downloaded from https://raw.githubusercontent.com/godotengine/godot/4.4/core/extension/gdextension_interface.h. Its upstream MIT license is retained in the header.

References: https://learn.microsoft.com/en-us/windows/win32/winmsg/wm-sizing and https://docs.godotengine.org/en/stable/tutorials/scripting/gdextension/gdextension_file.html.
