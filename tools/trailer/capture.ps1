$ErrorActionPreference = 'Stop'
$repoPath = (Get-Location).Path
$overridePath = Join-Path $repoPath 'godot/override.cfg'
$previousOverride = if (Test-Path -LiteralPath $overridePath) { [IO.File]::ReadAllBytes($overridePath) } else { $null }
try {
    $settings = @('[display]', 'window/size/viewport_width=1920', 'window/size/viewport_height=1080', 'window/size/window_width_override=1920', 'window/size/window_height_override=1080')
    $settings | Set-Content -LiteralPath $overridePath
    $captureArgs = @('--path', ('"' + (Join-Path $repoPath 'godot') + '"'), '--script', 'res://trailer_capture.gd', '--resolution', '1920x1080', '--write-movie', 'E:/Cairn-build-tools/trailer/master.avi', '--fixed-fps', '30', '--rendering-driver', 'opengl3', '--', '--trailer-capture')
    $capture = Start-Process -FilePath E:/Cairn-build-tools/godot/Godot_v4.7.2-stable_win64_console.exe -ArgumentList $captureArgs -WindowStyle Hidden -Wait -PassThru -RedirectStandardOutput E:/Cairn-build-tools/trailer/master.log -RedirectStandardError E:/Cairn-build-tools/trailer/master-errors.log
    if ($capture.ExitCode -ne 0) { throw 'Capture failed; inspect master-errors.log' }
} finally {
    if ($null -ne $previousOverride) { [IO.File]::WriteAllBytes($overridePath,$previousOverride) } else { Remove-Item -LiteralPath $overridePath -ErrorAction SilentlyContinue }
}
