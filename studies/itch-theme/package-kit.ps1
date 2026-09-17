$ErrorActionPreference = 'Stop'
$kitRoot = 'E:\Cairn-build-tools\itch-page-assets'
New-Item -ItemType Directory -Force -Path $kitRoot, "$kitRoot\screenshots", "$kitRoot\trailer" | Out-Null
Copy-Item -LiteralPath "$PSScriptRoot\assets\header-v4.png" -Destination "$kitRoot\cairn-header.png"
Copy-Item -LiteralPath "$PSScriptRoot\assets\stone-tile-512.jpg" -Destination "$kitRoot\cairn-stone-background.jpg"
Copy-Item -LiteralPath "$PSScriptRoot\assets\aqueduct.jpg" -Destination "$kitRoot\screenshots\01-aqueduct.jpg"
Copy-Item -LiteralPath "$PSScriptRoot\assets\foundry.jpg" -Destination "$kitRoot\screenshots\02-foundry.jpg"
Copy-Item -LiteralPath "$PSScriptRoot\assets\keep.jpg" -Destination "$kitRoot\screenshots\03-keep.jpg"
Copy-Item -LiteralPath "$PSScriptRoot\description.html", "$PSScriptRoot\SETUP.md" -Destination $kitRoot
Copy-Item -LiteralPath 'E:\Cairn-build-tools\trailer\cairn-first-cut.mp4' -Destination "$kitRoot\trailer\cairn-first-cut.mp4"
$recipe = Get-Content -LiteralPath "$PSScriptRoot\theme.json" -Raw | ConvertFrom-Json
$recipe.images.banner = 'cairn-header.png'
$recipe.images.background = 'cairn-stone-background.jpg'
$recipe.screenshots = @('screenshots/01-aqueduct.jpg', 'screenshots/02-foundry.jpg', 'screenshots/03-keep.jpg')
$recipe | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath "$kitRoot\theme-settings.json" -Encoding UTF8
Get-ChildItem -LiteralPath $kitRoot -Recurse -File | Select-Object FullName, Length
Write-Output $kitRoot
