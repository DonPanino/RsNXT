# Test the original unpatched client to establish baseline behavior
Write-Host "=== Testing Original Unpatched Client ===" -ForegroundColor Cyan

$originalClient = "A:\RSPS\OpenNXT\data\clients\945\win64\original\rs2client.exe"

if (-not (Test-Path $originalClient)) {
    Write-Host "Original client not found: $originalClient" -ForegroundColor Red
    exit 1
}

Write-Host "Found original client" -ForegroundColor Green
Write-Host "Launching without any arguments..." -ForegroundColor Yellow

try {
    $process = Start-Process -FilePath $originalClient -PassThru -Wait
    $exitCode = $process.ExitCode
    if ($exitCode -eq 0) {
        Write-Host "`nOriginal client exited with code: $exitCode" -ForegroundColor Green
    }
    else {
        Write-Host "`nOriginal client exited with code: $exitCode" -ForegroundColor Red
    }
    
    if ($exitCode -eq 0) {
        Write-Host "Original client runs without crashing - problem is likely in patches" -ForegroundColor Yellow
    }
    else {
        Write-Host "Original client also crashes - problem is environment/dependencies" -ForegroundColor Yellow
    }
}
catch {
    Write-Host "Error launching original client: $_" -ForegroundColor Red
}
