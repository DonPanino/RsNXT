# Launch RS3 through the official Jagex Launcher
Write-Host "=== Launching RS3 via Official Jagex Launcher ===" -ForegroundColor Cyan

$launcher = "C:\Program Files (x86)\Jagex Launcher\JagexLauncher.exe"

if (-not (Test-Path $launcher)) {
    Write-Host "Jagex Launcher not found: $launcher" -ForegroundColor Red
    exit 1
}

Write-Host "Found Jagex Launcher" -ForegroundColor Green
Write-Host "Launching RuneScape through official launcher..." -ForegroundColor Yellow
Write-Host "(This will launch to Jagex servers - watch for the client to load)" -ForegroundColor Gray

# Launch through the launcher (this will go to official servers)
Start-Process -FilePath $launcher

Write-Host "`nLauncher started. The client should appear shortly." -ForegroundColor Green
Write-Host "`nNow we need to find how to redirect it to our local server..." -ForegroundColor Yellow
Write-Host "Options:" -ForegroundColor Cyan
Write-Host "  1. Modify hosts file to redirect RS3 domains to 127.0.0.1" -ForegroundColor Gray
Write-Host "  2. Find launcher command-line args to specify custom server" -ForegroundColor Gray
Write-Host "  3. Patch the installed RuneScape.exe with our RSA keys" -ForegroundColor Gray
