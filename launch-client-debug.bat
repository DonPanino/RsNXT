@echo off
REM Diagnostic launcher with output capture
echo Starting RS3 client with diagnostics...
echo.

REM Create log directory
if not exist "A:\RSPS\OpenNXT\logs" mkdir "A:\RSPS\OpenNXT\logs"

REM Run with stdout/stderr capture
echo [%date% %time%] Launching client... > "A:\RSPS\OpenNXT\logs\client-launch.log"
"A:\RSPS\OpenNXT\client-test\rs2client.exe" --configURI http://127.0.0.1/jav_config.ws 2>>"A:\RSPS\OpenNXT\logs\client-launch.log"

echo.
echo Exit code: %ERRORLEVEL%
echo Log saved to: A:\RSPS\OpenNXT\logs\client-launch.log
echo.
type "A:\RSPS\OpenNXT\logs\client-launch.log"
echo.
pause
