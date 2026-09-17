param([switch]$Stress, [switch]$ExportedAssets, [switch]$AssetProbe)
$ErrorActionPreference = 'Stop'
$projectRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$godot = 'E:/Cairn-build-tools/godot/Godot_v4.7.2-stable_win64_console.exe'
$benchArgs = @('--resolution', '960x540', '--script', (Join-Path $projectRoot 'godot/tests/performance_scenes.gd'))
if ($ExportedAssets) {
    $benchArgs = @('--main-pack', 'E:/Cairn-build-tools/build/windows/Cairn.exe') + $benchArgs
} else {
    $benchArgs = @('--path', (Join-Path $projectRoot 'godot')) + $benchArgs
}
$benchArgs += @('--', '--benchmark')
if ($Stress) { $benchArgs += '--stress' }
if ($AssetProbe) { $benchArgs += '--asset-probe' }
Push-Location $projectRoot
try {
    & $godot @benchArgs
    if ($LASTEXITCODE -ne 0) { throw "Benchmark failed: $LASTEXITCODE" }
} finally { Pop-Location }
