# Minimal Launcher Stub - Acts as parent process for RS3 client
# Creates IPC pipes using own PID, then spawns client as child

Write-Host "=" -NoNewline; Write-Host ("=" * 59)
Write-Host "RS3 Minimal Launcher Stub" -ForegroundColor Cyan
Write-Host "=" -NoNewline; Write-Host ("=" * 59)

$launcherPid = $PID
Write-Host "`nLauncher PID: $launcherPid" -ForegroundColor Yellow

# Add pipe server type
Add-Type -TypeDefinition @"
using System;
using System.IO.Pipes;
using System.Threading.Tasks;

public class SimplePipeServer {
    private NamedPipeServerStream pipeIn;
    private NamedPipeServerStream pipeOut;
    
    public SimplePipeServer(int pid) {
        string baseName = "RS2LauncherConnection_" + pid;
        pipeIn = new NamedPipeServerStream(baseName + "_i", PipeDirection.Out);
        pipeOut = new NamedPipeServerStream(baseName + "_o", PipeDirection.In);
        Console.WriteLine("Created pipes: " + baseName + "_i/o");
    }
    
    public async Task WaitForClient(int seconds) {
        Console.WriteLine("Waiting for client connection...");
        var task1 = pipeIn.WaitForConnectionAsync();
        var task2 = pipeOut.WaitForConnectionAsync();
        await Task.WhenAll(task1, task2);
        Console.WriteLine("Client connected!");
    }
    
    public void Close() {
        if (pipeIn != null) pipeIn.Dispose();
        if (pipeOut != null) pipeOut.Dispose();
    }
}
"@

try {
    # Create pipes using this process's PID
    Write-Host "`nCreating IPC pipes..." -ForegroundColor Cyan
    $pipeServer = New-Object SimplePipeServer($launcherPid)
    
    # Launch client as child process
    $clientExe = "A:\RSPS\OpenNXT\client-pack-945\rs2client.exe"
    $clientDir = "A:\RSPS\OpenNXT\client-pack-945"
    
    if (!(Test-Path $clientExe)) {
        Write-Host "Client not found: $clientExe" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "Launching client as child process..." -ForegroundColor Cyan
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $clientExe
    $psi.WorkingDirectory = $clientDir
    $psi.UseShellExecute = $false
    
    $clientProc = [System.Diagnostics.Process]::Start($psi)
    Write-Host "Client launched (PID=$($clientProc.Id))" -ForegroundColor Green
    
    # Wait for client to connect (with timeout)
    Write-Host "`nWaiting for client to connect to pipes..." -ForegroundColor Yellow
    $waitTask = $pipeServer.WaitForClient(10)
    $completed = $waitTask.Wait([TimeSpan]::FromSeconds(10))
    
    if ($completed) {
        Write-Host "SUCCESS! Client connected to IPC pipes!" -ForegroundColor Green
        Write-Host "Client is running with launcher IPC active" -ForegroundColor Green
        Write-Host "`nKeeping launcher alive..." -ForegroundColor Yellow
        Write-Host "Press Ctrl+C to exit (this will kill the client)" -ForegroundColor Gray
        
        # Keep alive while client runs
        while (-not $clientProc.HasExited) {
            Start-Sleep -Seconds 1
        }
        
        Write-Host "`nClient exited" -ForegroundColor Yellow
    } else {
        Write-Host "Client did not connect to pipes" -ForegroundColor Red
        Start-Sleep -Seconds 2
        if ($clientProc.HasExited) {
            Write-Host "Client crashed (exit code: $($clientProc.ExitCode))" -ForegroundColor Red
        }
    }
    
} catch {
    Write-Host "Error: $_" -ForegroundColor Red
} finally {
    if ($pipeServer) {
        $pipeServer.Close()
    }
    Write-Host "`nCleaned up" -ForegroundColor Gray
}
