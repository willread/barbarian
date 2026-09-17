param([int]$Jobs = 8)
$ErrorActionPreference = 'Stop'
$taskRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$source = 'E:/Cairn-build-tools/godot-source-4.7.2'
$revision = 'ed1daf0bf001b61586d9930840f2f1394092c079'
$python = 'E:/Cairn-build-tools/native-window/python/Scripts/python.exe'
if (!(Test-Path "$source/SConstruct")) {
    & git clone --depth 1 --branch 4.7.2-stable https://github.com/godotengine/godot.git $source
    if ($LASTEXITCODE) { throw 'Godot source download failed' }
}
$actualRevision = & git -C $source rev-parse HEAD
if ($actualRevision -ne $revision) { throw 'Unexpected Godot source revision' }
if (!(Test-Path $python)) {
    & python -m venv 'E:/Cairn-build-tools/native-window/python'
    if ($LASTEXITCODE) { throw 'Python environment setup failed' }
}
& $python -m pip install scons==4.9.1 --disable-pip-version-check
if ($LASTEXITCODE) { throw 'SCons setup failed' }
$deps = 'E:/Cairn-build-tools/native-window/deps'
New-Item -ItemType Directory -Force $deps | Out-Null
if (!(Test-Path "$deps/angle/libANGLE.windows.x86_64.lib")) {
    Invoke-WebRequest 'https://github.com/godotengine/godot-angle-static/releases/download/chromium/7219/godot-angle-static-x86_64-msvc-release.zip' -OutFile "$deps/angle.zip"
    Expand-Archive -LiteralPath "$deps/angle.zip" -DestinationPath "$deps/angle" -Force
}
if (!(Test-Path "$deps/accesskit-c-0.22.3/include/accesskit.h")) {
    Invoke-WebRequest 'https://github.com/godotengine/godot-accesskit-c-static/releases/download/0.22.3/accesskit-c-0.22.3.zip' -OutFile "$deps/accesskit.zip"
    Expand-Archive -LiteralPath "$deps/accesskit.zip" -DestinationPath $deps -Force
}
# Keep every intermediate and downloaded dependency off C:.
$moduleRoot = 'E:/Cairn-build-tools/native-window/template-module'
New-Item -ItemType Directory -Force "$moduleRoot/module/cairn_aspect" | Out-Null
Copy-Item -LiteralPath "$PSScriptRoot/aspect.c" -Destination "$moduleRoot/aspect.c"
Get-ChildItem -LiteralPath "$PSScriptRoot/module/cairn_aspect" -File | Copy-Item -Destination "$moduleRoot/module/cairn_aspect"
$env:TEMP = 'E:/Cairn-build-tools/native-window/temp'
$env:TMP = $env:TEMP
New-Item -ItemType Directory -Force $env:TEMP | Out-Null
Push-Location $source
try {
    & $python -m SCons platform=windows target=template_release arch=x86_64 "custom_modules=$moduleRoot/module" use_static_cpp=yes debug_symbols=no lto=none d3d12=no "angle_libs=$deps/angle" "accesskit_sdk_path=$deps/accesskit-c-0.22.3" "-j$Jobs"
    if ($LASTEXITCODE) { throw 'Custom Godot template compilation failed' }
    $destination = 'E:/Cairn-build-tools/godot/cairn-windows-release.exe'
    Copy-Item -LiteralPath "$source/bin/godot.windows.template_release.x86_64.exe" -Destination $destination
    Write-Output "CAIRN_BUILTIN_TEMPLATE_READY: $destination"
} finally { Pop-Location }
