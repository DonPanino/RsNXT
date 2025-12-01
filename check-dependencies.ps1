# Check for Visual C++ Redistributables and other dependencies
Write-Host "=== Checking Client Dependencies ===" -ForegroundColor Cyan

# Check if client exists
$clientPath = "A:\RSPS\OpenNXT\client-test\rs2client.exe"
if (Test-Path $clientPath) {
    Write-Host "Client exists: $clientPath" -ForegroundColor Green
    $clientSize = (Get-Item $clientPath).Length
    Write-Host "  Size: $clientSize bytes" -ForegroundColor Gray
}
else {
    Write-Host "Client not found: $clientPath" -ForegroundColor Red
    exit 1
}

# Check for required DLLs using Dependency Walker alternative
Write-Host "`n=== Checking for Visual C++ Redistributables ===" -ForegroundColor Cyan

# Check for VC++ 2015-2022 x64 runtime files
$systemRoot = $env:SystemRoot
$system32 = "$systemRoot\System32"

$requiredDlls = @(
    "vcruntime140.dll",
    "vcruntime140_1.dll",
    "msvcp140.dll",
    "msvcp140_1.dll",
    "msvcp140_2.dll",
    "concrt140.dll"
)

$missingDlls = @()
foreach ($dll in $requiredDlls) {
    $dllPath = "$system32\$dll"
    if (Test-Path $dllPath) {
        Write-Host "Found: $dll" -ForegroundColor Green
    }
    else {
        Write-Host "Missing: $dll" -ForegroundColor Red
        $missingDlls += $dll
    }
}

if ($missingDlls.Count -gt 0) {
    Write-Host "`nMissing DLL files detected!" -ForegroundColor Yellow
    Write-Host "Install Visual C++ 2015-2022 Redistributable (x64) from:" -ForegroundColor Yellow
    Write-Host "https://aka.ms/vs/17/release/vc_redist.x64.exe" -ForegroundColor Cyan
}

# Try to launch with more verbose error capture
Write-Host "`n=== Attempting Client Launch with Error Capture ===" -ForegroundColor Cyan

try {
    $process = Start-Process -FilePath $clientPath -ArgumentList "--configURI http://127.0.0.1/jav_config.ws" -PassThru -Wait
    $exitCode = $process.ExitCode
    if ($exitCode -eq 0) {
        Write-Host "Client exited with code: $exitCode" -ForegroundColor Green
    } else {
        Write-Host "Client exited with code: $exitCode" -ForegroundColor Red
    }
    
    if ($exitCode -ne 0) {
        Write-Host "`nExit code meanings:" -ForegroundColor Yellow
        Write-Host "  -1073741515 (0xC0000135): Missing DLL" -ForegroundColor Gray
        Write-Host "  -1073741819 (0xC0000005): Access Violation" -ForegroundColor Gray
        Write-Host "  -1073740791 (0xC0000409): Stack Buffer Overrun" -ForegroundColor Gray
    }
}
catch {
    Write-Host "Error launching client: $_" -ForegroundColor Red
}

# Check if client created any log files
Write-Host "`n=== Checking for Client Logs ===" -ForegroundColor Cyan
$clientDir = "A:\RSPS\OpenNXT\client-test"
$logFiles = Get-ChildItem -Path $clientDir -Filter "*.log" -ErrorAction SilentlyContinue
if ($logFiles) {
    Write-Host "Found log files:" -ForegroundColor Green
    foreach ($log in $logFiles) {
        Write-Host "  $($log.FullName)" -ForegroundColor Gray
        Write-Host "  Last modified: $($log.LastWriteTime)" -ForegroundColor Gray
    }
} else {
    Write-Host "No log files found in client directory" -ForegroundColor Yellow
}

# Check jagexcache directory
$cacheDir = "$env:USERPROFILE\jagexcache"
if (Test-Path $cacheDir) {
    Write-Host "`nFound jagexcache: $cacheDir" -ForegroundColor Green
    $cacheFiles = Get-ChildItem -Path $cacheDir -Recurse -File | Measure-Object
    Write-Host "  Contains $($cacheFiles.Count) files" -ForegroundColor Gray
}
else {
    Write-Host "`nJagexcache not found: $cacheDir" -ForegroundColor Yellow
}
