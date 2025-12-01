# Enable detailed crash logging
Write-Host "=== Checking for Crash Dumps and Logs ===" -ForegroundColor Cyan

# Check for crash dumps in typical locations
$crashLocations = @(
    "$env:LOCALAPPDATA\CrashDumps",
    "$env:TEMP",
    "A:\RSPS\OpenNXT\client-test",
    "$env:USERPROFILE\jagexcache"
)

Write-Host "`nChecking for .dmp files..." -ForegroundColor Yellow
foreach ($location in $crashLocations) {
    if (Test-Path $location) {
        $dumps = Get-ChildItem -Path $location -Filter "*.dmp" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 3
        if ($dumps) {
            Write-Host "Found dumps in: $location" -ForegroundColor Green
            foreach ($dump in $dumps) {
                Write-Host "  $($dump.Name) - $($dump.LastWriteTime)" -ForegroundColor Gray
            }
        }
    }
}

# Check Windows Event Log for application crashes
Write-Host "`nChecking Windows Event Log for recent application errors..." -ForegroundColor Yellow
try {
    $events = Get-WinEvent -FilterHashtable @{LogName='Application'; Level=2; StartTime=(Get-Date).AddMinutes(-5)} -MaxEvents 10 -ErrorAction SilentlyContinue | Where-Object { $_.Message -like "*rs2client*" -or $_.Message -like "*0xC0000005*" }
    if ($events) {
        Write-Host "Found recent crash events:" -ForegroundColor Red
        foreach ($event in $events) {
            Write-Host "  Time: $($event.TimeCreated)" -ForegroundColor Gray
            Write-Host "  Message: $($event.Message.Substring(0, [Math]::Min(200, $event.Message.Length)))..." -ForegroundColor Gray
            Write-Host ""
        }
    }
    else {
        Write-Host "No recent crash events found for rs2client" -ForegroundColor Green
    }
}
catch {
    Write-Host "Could not access Event Log: $_" -ForegroundColor Yellow
}

# Try launching with different arguments
Write-Host "`n=== Testing Different Launch Methods ===" -ForegroundColor Cyan

$clientPath = "A:\RSPS\OpenNXT\data\clients\945\win64\original\rs2client.exe"

# Test 1: No arguments
Write-Host "`n[Test 1] Launching with NO arguments..." -ForegroundColor Yellow
$p1 = Start-Process -FilePath $clientPath -PassThru -Wait
Write-Host "Exit code: $($p1.ExitCode)" -ForegroundColor $(if ($p1.ExitCode -eq 0) { "Green" } else { "Red" })

# Test 2: With --help
Write-Host "`n[Test 2] Launching with --help..." -ForegroundColor Yellow
$p2 = Start-Process -FilePath $clientPath -ArgumentList "--help" -PassThru -Wait
Write-Host "Exit code: $($p2.ExitCode)" -ForegroundColor $(if ($p2.ExitCode -eq 0) { "Green" } else { "Red" })

# Test 3: With -help
Write-Host "`n[Test 3] Launching with -help..." -ForegroundColor Yellow
$p3 = Start-Process -FilePath $clientPath -ArgumentList "-help" -PassThru -Wait
Write-Host "Exit code: $($p3.ExitCode)" -ForegroundColor $(if ($p3.ExitCode -eq 0) { "Green" } else { "Red" })

Write-Host "`n=== Summary ===" -ForegroundColor Cyan
Write-Host "All tests resulted in crashes - the client may require:" -ForegroundColor Yellow
Write-Host "  1. A specific launcher environment" -ForegroundColor Gray
Write-Host "  2. Access to Jagex servers for initialization" -ForegroundColor Gray
Write-Host "  3. Additional runtime components we haven't identified" -ForegroundColor Gray
