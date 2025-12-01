Write-Host "=== Launch Ataraxia NXT Client Against OpenNXT ===" -ForegroundColor Cyan

$clientExe = "A:\RSPS\rsps-server\data\nxt clients\binary6\ataraxiaclient"
if (-not (Test-Path $clientExe)) {
    Write-Host "Client not found: $clientExe" -ForegroundColor Red
    exit 1
}

# Prepare jagexcache directories
$jc = "$env:USERPROFILE\jagexcache\runescape\LIVE"
New-Item -ItemType Directory -Force -Path $jc | Out-Null

# Generate local jav_config.ws pointing to localhost
$configPath = Join-Path $jc "jav_config.ws"
$config = @()
$config += "server_version=945"
$config += "binary_count=1"
$config += "download=2"
$config += "window_preferredwidth=1024"
$config += "window_preferredheight=768"
$config += "param=3=127.0.0.1"
$config += "param=35=http://127.0.0.1"
$config += "param=40=http://127.0.0.1"
$config += "param=41=43594"
$config += "param=43=43594"
$config += "param=44=80"
$config += "param=45=43594"
$config += "param=47=43594"
$config += "param=28=http://127.0.0.1"
$config += "param=38=http://127.0.0.1"
$config += "param=8=43594"
$config += "param=12=43594"
$config | Set-Content -Encoding ASCII -Path $configPath
Write-Host "Wrote config: $configPath" -ForegroundColor Green

# Launch client
Write-Host "Launching: $clientExe" -ForegroundColor Yellow
$p = Start-Process -FilePath $clientExe -PassThru
Start-Sleep -Seconds 2
if ($p.HasExited) {
    Write-Host "Client exited with code $($p.ExitCode)" -ForegroundColor Red
} else {
    Write-Host "Client started (PID $($p.Id))" -ForegroundColor Green
}
