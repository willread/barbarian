param([switch]$Exported, [switch]$Game)
$ErrorActionPreference = 'Stop'
$taskRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
Add-Type @'
using System;
using System.Runtime.InteropServices;
public class NativeAspectTest {
 [DllImport("user32.dll")] public static extern IntPtr SetThreadDpiAwarenessContext(IntPtr context);
 public delegate bool Enumerator(IntPtr h, IntPtr l);
 [DllImport("user32.dll")] public static extern bool EnumWindows(Enumerator e, IntPtr l);
 [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h,out uint p);
 [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetClassName(IntPtr h,System.Text.StringBuilder s,int n);
 public static IntPtr Find(uint pid) {
  IntPtr found=IntPtr.Zero;
  EnumWindows(delegate(IntPtr h,IntPtr l) { uint p; GetWindowThreadProcessId(h,out p); var name=new System.Text.StringBuilder(128); GetClassName(h,name,128); if(p==pid && name.ToString()=="Engine") { found=h; return false; } return true; },IntPtr.Zero);
  return found;
 }
 [StructLayout(LayoutKind.Sequential)] public struct Rect { public int left, top, right, bottom; }
 [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out Rect r);
 [DllImport("user32.dll")] public static extern bool GetClientRect(IntPtr h, out Rect r);
 [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern uint RegisterWindowMessage(string s);
 [DllImport("user32.dll", EntryPoint="SendMessageW")] public static extern IntPtr Probe(IntPtr h,uint m,IntPtr w,IntPtr l);
 [DllImport("user32.dll", EntryPoint="SendMessageW")] public static extern IntPtr Size(IntPtr h,uint m,IntPtr w,ref Rect r);
}
'@
$priorDpi=[NativeAspectTest]::SetThreadDpiAwarenessContext([IntPtr](-4))
$godot = 'E:/Cairn-build-tools/godot/Godot_v4.7.2-stable_win64.exe'
$arguments=@('--path', 'godot', '--script', 'tests/native_window.gd', '--', '--native-window-test')
if ($Exported) {
 $godot='E:/Cairn-build-tools/build/windows/Cairn.exe'
 if (Test-Path 'E:/Cairn-build-tools/build/windows/cairn_aspect.dll') { throw 'Remove the legacy build DLL before testing the embedded hook' }
 # Production templates intentionally reject external --script overrides.
 $arguments=@('--', '--native-window-test')
}
$testName = if ($Game) { 'game' } elseif ($Exported) { 'exported' } else { 'editor' }
$outputLog = "E:/Cairn-build-tools/native-window/$testName-test.log"
$errorLog = "E:/Cairn-build-tools/native-window/$testName-test-error.log"
$testProcess = Start-Process -FilePath $godot -ArgumentList $arguments -WorkingDirectory $taskRoot -WindowStyle Hidden -PassThru -RedirectStandardOutput $outputLog -RedirectStandardError $errorLog
try {
 $message = [NativeAspectTest]::RegisterWindowMessage('Cairn.NativeAspectRatio.16x9')
 $window = [IntPtr]::Zero
 for ($attempt=0; $attempt -lt 50; $attempt++) {
  Start-Sleep -Milliseconds 100
  $testProcess.Refresh()
  $window=[NativeAspectTest]::Find($testProcess.Id)
  if ($window -ne [IntPtr]::Zero -and [NativeAspectTest]::Probe($window,$message,[IntPtr]::Zero,[IntPtr]::Zero).ToInt64() -eq 0x169) { break }
 }
 if ($window -eq [IntPtr]::Zero -or [NativeAspectTest]::Probe($window,$message,[IntPtr]::Zero,[IntPtr]::Zero).ToInt64() -ne 0x169) { throw 'Native resize hook was not installed' }
 if ($Game) {
  Start-Sleep -Seconds 12
  $testProcess.Refresh()
  if ($testProcess.HasExited) { throw 'Game exited during startup' }
 }
 if ($Exported) {
  $testProcess.Refresh()
  if ($testProcess.Modules | Where-Object ModuleName -EQ 'cairn_aspect.dll') { throw 'The process loaded the legacy DLL' }
  Write-Output 'CAIRN_NO_ASPECT_DLL_OK: no DLL in the build folder or loaded process modules'
 }
 $outer=New-Object NativeAspectTest+Rect
 $client=New-Object NativeAspectTest+Rect
 [void][NativeAspectTest]::GetWindowRect($window,[ref]$outer)
 [void][NativeAspectTest]::GetClientRect($window,[ref]$client)
 $borderX=$outer.right-$outer.left-$client.right
 $borderY=$outer.bottom-$outer.top-$client.bottom
 foreach ($edge in 1..8) {
  $previousWidth=0
  foreach ($step in 0..100) {
   $rect=New-Object NativeAspectTest+Rect
   $rect.left=100; $rect.top=100
   $rect.right=100+960+$step+$borderX; $rect.bottom=100+600+$step+$borderY
   $before=$rect
   [void][NativeAspectTest]::Size($window,0x214,[IntPtr]$edge,[ref]$rect)
   $width=$rect.right-$rect.left-$borderX
   $height=$rect.bottom-$rect.top-$borderY
   if ([Math]::Abs($width*9-$height*16) -gt 13) { throw "Aspect ratio failed on edge $edge step $step width=$width height=$height border=$borderX,$borderY" }
   if ($edge -in 1,4,7) { if ($rect.right -ne $before.right) { throw 'Opposite horizontal edge moved' } }
   elseif ($rect.left -ne $before.left) { throw 'Opposite horizontal edge moved' }
   if ($edge -in 3,4,5) { if ($rect.bottom -ne $before.bottom) { throw 'Opposite vertical edge moved' } }
   elseif ($rect.top -ne $before.top) { throw 'Opposite vertical edge moved' }
   if ($previousWidth -and [Math]::Abs($width-$previousWidth) -gt 2) { throw 'Resize snapped instead of advancing by individual pixels' }
   $previousWidth=$width
  }
 }
 $after=New-Object NativeAspectTest+Rect
 [void][NativeAspectTest]::GetWindowRect($window,[ref]$after)
 if ($after.left -ne $outer.left -or $after.right -ne $outer.right -or $after.top -ne $outer.top -or $after.bottom -ne $outer.bottom) { throw 'Handler changed the actual window instead of the proposed rectangle' }
 Write-Output 'CAIRN_NATIVE_RESIZE_OK: 808 proposed rectangles; all eight edges, client aspect, stable anchors, pixel-smooth motion, no corrective SetWindowPos'
} finally {
 if (!$testProcess.HasExited) { [void][NativeAspectTest]::Probe($window,0x10,[IntPtr]::Zero,[IntPtr]::Zero); if (!$testProcess.WaitForExit(5000)) { Stop-Process -Id $testProcess.Id } }
 [void][NativeAspectTest]::SetThreadDpiAwarenessContext($priorDpi)
}
if (Select-String -LiteralPath $errorLog,$outputLog -Pattern '^(SCRIPT ERROR|SHADER ERROR|ERROR):' -Quiet) { throw 'Native run reported errors; inspect the test logs' }
