# Launch client with IPC session ID
param(
    [Parameter(Mandatory=$true)]
    [int]$SessionId
)

Write-Host "=== Launching RS3 945 with IPC Session $SessionId ===" -ForegroundColor Cyan

$clientDir = "A:\RSPS\OpenNXT\client-pack-945"
$clientExe = Join-Path $clientDir "rs2client.exe"

# Set environment variable for IPC
$env:RS2_LAUNCHER_SESSION = $SessionId

# Also try other possible env var names
$env:JAGEX_LAUNCHER_SESSION = $SessionId
$env:RS_LAUNCHER_PID = $SessionId

# Ensure jagexcache structure
$jc = Join-Path $env:USERPROFILE "jagexcache"
New-Item -ItemType Directory -Force -Path "$jc\runescape\LIVE" | Out-Null

# Launch client
Write-Host "Environment:" -ForegroundColor Yellow
Write-Host "  RS2_LAUNCHER_SESSION = $SessionId" -ForegroundColor Gray
Write-Host "  Working Dir: $clientDir" -ForegroundColor Gray

if (!(Test-Path $clientExe)) {
    Write-Host "Client not found: $clientExe" -ForegroundColor Red
    exit 1
}

Write-Host "`nLaunching client..." -ForegroundColor Cyan
$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = $clientExe
$psi.WorkingDirectory = $clientDir
$psi.UseShellExecute = $false
$psi.EnvironmentVariables["RS2_LAUNCHER_SESSION"] = $SessionId
$psi.EnvironmentVariables["JAGEX_LAUNCHER_SESSION"] = $SessionId
$psi.EnvironmentVariables["RS_LAUNCHER_PID"] = $SessionId

try {
    $proc = [System.Diagnostics.Process]::Start($psi)
    Write-Host "Launched (PID=$($proc.Id))" -ForegroundColor Green
    
    # Wait a moment to see if it crashes immediately
    Start-Sleep -Seconds 2
    if ($proc.HasExited) {
        Write-Host "Client exited immediately (exit code: $($proc.ExitCode))" -ForegroundColor Red
    }
    else {
        Write-Host "Client is running!" -ForegroundColor Green
        Write-Host "  Check pipe server terminal for connection messages" -ForegroundColor Gray
    }
}
catch {
    Write-Host "Failed to launch: $_" -ForegroundColor Red
}
