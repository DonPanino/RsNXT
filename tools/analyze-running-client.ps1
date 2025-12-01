# Analyze IPC while client is running
Write-Host "=== Analyzing IPC while RuneScape.exe is running ===" -ForegroundColor Cyan

$rsPid = (Get-Process -Name "RuneScape" -ErrorAction SilentlyContinue).Id
if (-not $rsPid) {
    Write-Host "RuneScape.exe not running - launch it first!" -ForegroundColor Red
    exit 1
}

Write-Host "`nRuneScape.exe PID: $rsPid" -ForegroundColor Green

Write-Host "`n[1] Checking for new named pipes..." -ForegroundColor Yellow
$pipes = Get-ChildItem "\\.\pipe\" -ErrorAction SilentlyContinue | Where-Object { 
    $_.Name -like "*jagex*" -or 
    $_.Name -like "*runescape*" -or 
    $_.Name -like "*rs*" -or
    $_.Name -like "*cef*" -or
    $_.Name -like "*chromium*"
}
if ($pipes) {
    $pipes | Select-Object FullName
} else {
    Write-Host "No obvious pipes found" -ForegroundColor Gray
}

Write-Host "`n[2] Checking process handles (requires Handle.exe from Sysinternals)..." -ForegroundColor Yellow
$handleExe = "C:\Program Files\Sysinternals\handle64.exe"
if (Test-Path $handleExe) {
    Write-Host "Running: handle64.exe -p $rsPid | findstr /i 'section event mutex pipe'" -ForegroundColor Gray
    & $handleExe -p $rsPid -nobanner | Select-String -Pattern "Section|Event|Mutex|Pipe|File" | Select-Object -First 20
} else {
    Write-Host "handle64.exe not found - download Sysinternals Suite" -ForegroundColor Gray
    Write-Host "URL: https://docs.microsoft.com/en-us/sysinternals/downloads/handle" -ForegroundColor Gray
}

Write-Host "`n[3] Checking open files/mapped sections..." -ForegroundColor Yellow
$proc = Get-Process -Id $rsPid
Write-Host "Module count: $($proc.Modules.Count)" -ForegroundColor Gray
Write-Host "Handle count: $($proc.HandleCount)" -ForegroundColor Gray
Write-Host "Threads: $($proc.Threads.Count)" -ForegroundColor Gray

Write-Host "`n[4] Checking for shared memory objects..." -ForegroundColor Yellow
Write-Host "(Need Process Explorer or WinObj to see Section objects)" -ForegroundColor Gray

Write-Host "`n[5] Checking parent-child relationship..." -ForegroundColor Yellow
$parent = Get-WmiObject Win32_Process | Where-Object {$_.ProcessId -eq $proc.Parent.Id}
if ($parent) {
    Write-Host "Parent: $($parent.Name) (PID $($parent.ProcessId))" -ForegroundColor Cyan
    Write-Host "Parent CommandLine: $($parent.CommandLine)" -ForegroundColor Gray
}

Write-Host "`n[6] Recommendation:" -ForegroundColor Cyan
Write-Host "Download Process Explorer (procexp.exe) from Sysinternals:" -ForegroundColor Yellow
Write-Host "https://docs.microsoft.com/en-us/sysinternals/downloads/process-explorer" -ForegroundColor White
Write-Host ""
Write-Host "In Process Explorer:" -ForegroundColor Yellow
Write-Host "  1. Find RuneScape.exe" -ForegroundColor Gray
Write-Host "  2. Right-click -> Properties" -ForegroundColor Gray
Write-Host "  3. Go to 'Handles' tab" -ForegroundColor Gray
Write-Host "  4. Look for Section, Event, Mutex, or Pipe objects" -ForegroundColor Gray
