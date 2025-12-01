# Test launching the official Jagex Launcher RS3 client
Write-Host "=== Testing Official Jagex Launcher RS3 Client ===" -ForegroundColor Cyan

$officialClient = "C:\Program Files (x86)\Jagex Launcher\Games\RuneScape\RuneScape.exe"

if (-not (Test-Path $officialClient)) {
    Write-Host "Official client not found: $officialClient" -ForegroundColor Red
    exit 1
}

Write-Host "Found official RS3 client (build 945)" -ForegroundColor Green

# Test 1: Launch with no arguments
Write-Host "`n[Test 1] Launching official client with NO arguments..." -ForegroundColor Yellow
$p1 = Start-Process -FilePath $officialClient -PassThru -Wait
Write-Host "Exit code: $($p1.ExitCode)" -ForegroundColor $(if ($p1.ExitCode -eq 0) { "Green" } else { "Red" })

# Test 2: Launch with our configURI
Write-Host "`n[Test 2] Launching with --configURI pointing to our server..." -ForegroundColor Yellow
$p2 = Start-Process -FilePath $officialClient -ArgumentList "--configURI http://127.0.0.1/jav_config.ws" -PassThru -Wait
Write-Host "Exit code: $($p2.ExitCode)" -ForegroundColor $(if ($p2.ExitCode -eq 0) { "Green" } else { "Red" })

Write-Host "`nNote: If the official client works, it means the binary needs to be in the" -ForegroundColor Yellow
Write-Host "correct directory structure with proper DLLs and environment." -ForegroundColor Yellow
