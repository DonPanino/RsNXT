# Launch RS3 945 client against local OpenNXT server
Write-Host "=== Launching RS3 945 Client Pack ===" -ForegroundColor Cyan

$clientDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$clientExe = Join-Path $clientDir "rs2client.exe"
$configUri = "http://127.0.0.1/jav_config.ws"

# Ensure jagexcache structure exists
$jc = Join-Path $env:USERPROFILE "jagexcache"
$live = Join-Path $jc "runescape\LIVE"
New-Item -ItemType Directory -Force -Path $jc | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $jc "runescape") | Out-Null
New-Item -ItemType Directory -Force -Path $live | Out-Null

# Copy minimal DLLs if missing
$dlldir = Join-Path $clientDir "DLLs"
$needed = @("D3Dcompiler_47.dll","libEGL.dll","libGLESv2.dll")
foreach ($dll in $needed) {
    $src = Join-Path $dlldir $dll
    $dst = Join-Path $clientDir $dll
    if ((Test-Path $src) -and -not (Test-Path $dst)) {
        Copy-Item $src $dst
    }
}

# Quick config check
try {
    $resp = Invoke-WebRequest $configUri -UseBasicParsing -TimeoutSec 5
    if ($resp.StatusCode -eq 200) {
        Write-Host "Config reachable: $configUri" -ForegroundColor Green
    }
    else {
        Write-Host "Config status: $($resp.StatusCode)" -ForegroundColor Yellow
    }
}
catch {
    Write-Host "Could not reach $configUri" -ForegroundColor Yellow
}

# Launch client with working directory
if (!(Test-Path $clientExe)) {
    Write-Host "Client not found: $clientExe" -ForegroundColor Red
    exit 1
}

Write-Host "Starting client..." -ForegroundColor Cyan
$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = $clientExe
$psi.WorkingDirectory = $clientDir
$psi.Arguments = "--configURI $configUri"
$psi.UseShellExecute = $true
$proc = [System.Diagnostics.Process]::Start($psi)
Write-Host "Launched (PID=$($proc.Id))" -ForegroundColor Green
