# Monitor for RuneScape.exe launch and capture full command line
Write-Host "Waiting for RuneScape.exe to launch..." -ForegroundColor Yellow
Write-Host "Click 'Play' in the Jagex Launcher now!" -ForegroundColor Cyan
Write-Host ""

$found = $false
$timeout = 30
$elapsed = 0

while (-not $found -and $elapsed -lt $timeout) {
    $rs = Get-WmiObject Win32_Process | Where-Object {$_.Name -eq "RuneScape.exe"}
    if ($rs) {
        $found = $true
        Write-Host "=== FOUND RuneScape.exe ===" -ForegroundColor Green
        Write-Host ""
        Write-Host "Process ID: $($rs.ProcessId)" -ForegroundColor Cyan
        Write-Host "Command Line:" -ForegroundColor Cyan
        Write-Host $rs.CommandLine -ForegroundColor White
        Write-Host ""
        Write-Host "Parent Process ID: $($rs.ParentProcessId)" -ForegroundColor Cyan
        
        # Get parent process
        $parent = Get-WmiObject Win32_Process | Where-Object {$_.ProcessId -eq $rs.ParentProcessId}
        if ($parent) {
            Write-Host "Parent: $($parent.Name) (PID $($parent.ProcessId))" -ForegroundColor Gray
        }
        
        # Get environment variables (requires debug privileges, may fail)
        Write-Host "`nTrying to get environment block..." -ForegroundColor Yellow
        try {
            $proc = Get-Process -Id $rs.ProcessId
            # Environment vars not directly accessible, but we can check working directory
            Write-Host "Working Directory: $($proc.Path)" -ForegroundColor Gray
        } catch {
            Write-Host "Could not access process details" -ForegroundColor Red
        }
    } else {
        Start-Sleep -Milliseconds 500
        $elapsed += 0.5
        Write-Host "." -NoNewline
    }
}

if (-not $found) {
    Write-Host "`nTimeout - RuneScape.exe did not launch" -ForegroundColor Red
}
