@echo off
setlocal
cd /d "%~dp0"
echo Building Cairn for browser and Windows.
echo Close the Windows game before building so Cairn.exe can be replaced.
echo.
call npm run godot:build
set "cairn_build_result=%errorlevel%"
echo.
if "%cairn_build_result%"=="0" (
  echo Build complete. Output paths are listed above.
) else (
  echo Build failed. See the error above. If Cairn.exe is open, close it and retry.
)
if /i not "%~1"=="--no-pause" pause
exit /b %cairn_build_result%
