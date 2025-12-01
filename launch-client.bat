@echo off
REM Simple launcher for RS3 945 client with OpenNXT server
REM
REM Usage: Run this batch file to launch the client

echo Starting RS3 945 Client...
echo.
echo Config URL: http://127.0.0.1/jav_config.ws
echo Client: A:\RSPS\OpenNXT-944\client-test\rs2client.exe
echo.

REM Check if OpenNXT server is running
powershell -Command "try { Invoke-WebRequest -Uri 'http://127.0.0.1/jav_config.ws' -UseBasicParsing -ErrorAction Stop | Out-Null; Write-Host 'OpenNXT server is running.' -ForegroundColor Green } catch { Write-Host 'ERROR: OpenNXT server is not running!' -ForegroundColor Red; Write-Host 'Start the server first:' -ForegroundColor Yellow; Write-Host '  cd A:\RSPS\OpenNXT-944' -ForegroundColor Yellow; Write-Host '  java -jar .\build\libs\OpenNXT-944-1.0.0-all.jar run-server --skip-http-file-verification --enable-proxy-support' -ForegroundColor Yellow; pause; exit 1 }"

echo.
echo Launching client...
start "" "A:\RSPS\OpenNXT-944\client-test\rs2client.exe" --configURI "http://127.0.0.1/jav_config.ws"

echo.
echo Client launched. Check for client window.
echo If the client doesn't appear, check the server logs for connection errors.
pause
