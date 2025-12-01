# Investigate JagexLauncher IPC mechanisms
Write-Host "=== Analyzing JagexLauncher IPC Setup ===" -ForegroundColor Cyan

$launcher = "C:\Program Files (x86)\Jagex Launcher\JagexLauncher.exe"
$clientExe = "C:\Program Files (x86)\Jagex Launcher\Games\RuneScape\RuneScape.exe"

# Launch JagexLauncher and capture environment
Write-Host "`n[1] Starting JagexLauncher..." -ForegroundColor Yellow
$launcherProc = Start-Process -FilePath $launcher -PassThru
Start-Sleep -Seconds 3

Write-Host "`n[2] Checking for named pipes..." -ForegroundColor Yellow
Get-ChildItem "\\.\pipe\" | Where-Object { $_.Name -like "*jagex*" -or $_.Name -like "*runescape*" -or $_.Name -like "*rs*" } | Select-Object FullName

Write-Host "`n[3] Checking launcher process details..." -ForegroundColor Yellow
$launcherProc | Select-Object Id,ProcessName,StartTime

Write-Host "`n[4] Checking environment variables in launcher context..." -ForegroundColor Yellow
# Can't directly read another process's env vars without WMI or debug tools
Write-Host "(Use Process Explorer or WMI to inspect launcher env vars)" -ForegroundColor Gray

Write-Host "`n[5] Checking for mutex/event objects..." -ForegroundColor Yellow
# Use Handle.exe or Process Explorer to see kernel objects

Write-Host "`n[6] Monitoring for child processes..." -ForegroundColor Yellow
Write-Host "Watch for RuneScape.exe spawning when you click Play..." -ForegroundColor Gray
Write-Host "If it spawns, we'll capture its command line arguments" -ForegroundColor Gray

Write-Host "`n[7] Instructions:" -ForegroundColor Cyan
Write-Host "  - Keep launcher open" -ForegroundColor Gray
Write-Host "  - Click 'Play' on RuneScape" -ForegroundColor Gray
Write-Host "  - Run this to capture client args:" -ForegroundColor Gray
Write-Host '    Get-WmiObject Win32_Process | Where-Object {$_.Name -eq "RuneScape.exe"} | Select-Object ProcessId,CommandLine' -ForegroundColor White

Write-Host "`n[8] Kill launcher when done:" -ForegroundColor Yellow
Write-Host "  Stop-Process -Id $($launcherProc.Id) -Force" -ForegroundColor Gray
