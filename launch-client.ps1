# RS3 945 Client Launcher for OpenNXT
# PowerShell version with better error handling

$configUrl = "http://127.0.0.1/jav_config.ws"
$clientPath = "A:\RSPS\OpenNXT\client-test\rs2client.exe"

Write-Host "RS3 945 Client Launcher" -ForegroundColor Cyan
Write-Host "======================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Config URL: $configUrl"
Write-Host "Client: $clientPath"
Write-Host ""

# Check if client exists
if (!(Test-Path $clientPath)) {
    Write-Host "ERROR: Client not found at $clientPath" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# Check if OpenNXT server is running
Write-Host "Checking OpenNXT server..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri $configUrl -UseBasicParsing -ErrorAction Stop
    Write-Host "Server is running" -ForegroundColor Green
}
catch {
    Write-Host "ERROR: OpenNXT server is not responding!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Start the server first:" -ForegroundColor Yellow
    Write-Host "  cd A:\RSPS\OpenNXT-944" -ForegroundColor Cyan
    Write-Host "  java -jar .\build\libs\OpenNXT-944-1.0.0-all.jar run-server --skip-http-file-verification --enable-proxy-support" -ForegroundColor Cyan
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}

# Launch client
Write-Host ""
Write-Host "Launching client..." -ForegroundColor Yellow
Start-Process -FilePath $clientPath -ArgumentList "--configURI", $configUrl

Write-Host ""
Write-Host "Client launched" -ForegroundColor Green
Write-Host ""
Write-Host "If the client doesn't appear:"
Write-Host "  1. Check the server logs for connection errors"
Write-Host "  2. Verify the patched RSA keys match the server"
Write-Host "  3. Check Windows Task Manager for rs2client.exe process"
Write-Host ""
Read-Host "Press Enter to close"
