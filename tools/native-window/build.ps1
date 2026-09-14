$ErrorActionPreference = 'Stop'
$taskRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$vswhere = "${env:ProgramFiles(x86)}/Microsoft Visual Studio/Installer/vswhere.exe"
$installation = & $vswhere -latest -products '*' -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
$toolset = Get-ChildItem "$installation/VC/Tools/MSVC" -Directory | Sort-Object Name -Descending | Select-Object -First 1
$sdkRoot = "${env:ProgramFiles(x86)}/Windows Kits/10"
$sdk = Get-ChildItem "$sdkRoot/Include" -Directory | Sort-Object Name -Descending | Select-Object -First 1
$compiler = "$($toolset.FullName)/bin/Hostx64/x64/cl.exe"
$env:INCLUDE = "$($toolset.FullName)/include;$($sdk.FullName)/ucrt;$($sdk.FullName)/shared;$($sdk.FullName)/um"
$env:LIB = "$($toolset.FullName)/lib/x64;$sdkRoot/Lib/$($sdk.Name)/ucrt/x64;$sdkRoot/Lib/$($sdk.Name)/um/x64"
$buildRoot = 'E:/Cairn-build-tools/native-window'
New-Item -ItemType Directory -Force $buildRoot | Out-Null
& $compiler /nologo /LD /O2 /MT /W3 "$PSScriptRoot/aspect.c" "/Fo$buildRoot/aspect.obj" /link user32.lib "/OUT:$taskRoot/godot/native/cairn_aspect.dll" "/IMPLIB:$buildRoot/cairn_aspect.lib"
if ($LASTEXITCODE) { throw "Native aspect helper compilation failed: $LASTEXITCODE" }
