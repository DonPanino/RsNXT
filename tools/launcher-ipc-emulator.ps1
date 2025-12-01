# RS3 Launcher IPC Emulator - PowerShell version
# Creates named pipes to trick the client into thinking the launcher is present

param(
    [int]$SessionId = $PID
)

Add-Type -TypeDefinition @"
using System;
using System.IO;
using System.IO.Pipes;
using System.Threading;
using System.Threading.Tasks;

public class LauncherPipeServer {
    private string pipeInName;
    private string pipeOutName;
    private NamedPipeServerStream pipeIn;
    private NamedPipeServerStream pipeOut;
    private bool running = false;
    
    public LauncherPipeServer(int sessionId) {
        pipeInName = "RS2LauncherConnection_" + sessionId + "_i";
        pipeOutName = "RS2LauncherConnection_" + sessionId + "_o";
    }
    
    public bool CreatePipes() {
        try {
            Console.WriteLine("Creating pipes:");
            Console.WriteLine("  Input:  " + pipeInName);
            Console.WriteLine("  Output: " + pipeOutName);
            
            // Input pipe (launcher -> client)
            pipeIn = new NamedPipeServerStream(pipeInName, PipeDirection.Out, 1);
            
            // Output pipe (client -> launcher)
            pipeOut = new NamedPipeServerStream(pipeOutName, PipeDirection.In, 1);
            
            Console.WriteLine("✓ Pipes created successfully");
            return true;
        } catch (Exception ex) {
            Console.WriteLine("✗ Failed to create pipes: " + ex.Message);
            return false;
        }
    }
    
    public async Task<bool> WaitForClient(int timeoutSeconds) {
        Console.WriteLine("\nWaiting for client to connect (timeout: " + timeoutSeconds + "s)...");
        
        try {
            // Wait for client connections with timeout
            var inTask = pipeIn.WaitForConnectionAsync();
            var outTask = pipeOut.WaitForConnectionAsync();
            
            var cts = new CancellationTokenSource(TimeSpan.FromSeconds(timeoutSeconds));
            
            await Task.WhenAll(inTask, outTask).ConfigureAwait(false);
            
            Console.WriteLine("✓ Client connected to both pipes");
            return true;
        } catch (Exception ex) {
            Console.WriteLine("✗ Error waiting for client: " + ex.Message);
            return false;
        }
    }
    
    public bool SendHandshake() {
        Console.WriteLine("\nSending handshake data...");
        try {
            // Send minimal handshake (we'll refine this based on client behavior)
            byte[] data = System.Text.Encoding.ASCII.GetBytes("READY");
            pipeIn.Write(data, 0, data.Length);
            pipeIn.Flush();
            Console.WriteLine("✓ Sent handshake");
            return true;
        } catch (Exception ex) {
            Console.WriteLine("✗ Failed to send handshake: " + ex.Message);
            return false;
        }
    }
    
    public void ListenLoop() {
        Console.WriteLine("\nListening for client messages...");
        running = true;
        
        try {
            byte[] buffer = new byte[4096];
            while (running && pipeOut.IsConnected) {
                int bytesRead = pipeOut.Read(buffer, 0, buffer.Length);
                if (bytesRead > 0) {
                    string msg = BitConverter.ToString(buffer, 0, Math.Min(bytesRead, 50));
                    Console.WriteLine("← Client sent: " + msg);
                }
            }
            Console.WriteLine("Client disconnected");
        } catch (Exception ex) {
            Console.WriteLine("Error in listen loop: " + ex.Message);
        }
    }
    
    public void Cleanup() {
        Console.WriteLine("\nCleaning up pipes...");
        running = false;
        if (pipeIn != null) pipeIn.Dispose();
        if (pipeOut != null) pipeOut.Dispose();
        Console.WriteLine("✓ Pipes closed");
    }
}
"@

Write-Host "=" -ForegroundColor Cyan -NoNewline; Write-Host ("=" * 59)
Write-Host "RS3 Launcher IPC Emulator" -ForegroundColor Cyan
Write-Host "=" -ForegroundColor Cyan -NoNewline; Write-Host ("=" * 59)

Write-Host "`nSession ID: $SessionId" -ForegroundColor Yellow

$server = New-Object LauncherPipeServer($SessionId)

if (-not $server.CreatePipes()) {
    exit 1
}

Write-Host "`n" -NoNewline
Write-Host "=" -ForegroundColor Green -NoNewline; Write-Host ("=" * 59)
Write-Host "Pipes are ready!" -ForegroundColor Green
Write-Host "=" -ForegroundColor Green -NoNewline; Write-Host ("=" * 59)

Write-Host "`nEnvironment variable to set:" -ForegroundColor Cyan
Write-Host "  `$env:RS2_LAUNCHER_SESSION = $SessionId" -ForegroundColor White

Write-Host "`nLaunch client with:" -ForegroundColor Cyan
Write-Host "  cd A:\RSPS\OpenNXT\client-pack-945" -ForegroundColor White
Write-Host "  `$env:RS2_LAUNCHER_SESSION = $SessionId; .\launch.ps1" -ForegroundColor White

Write-Host "`nPress Ctrl+C to stop the server" -ForegroundColor Yellow
Write-Host "=" -ForegroundColor Cyan -NoNewline; Write-Host ("=" * 59)

try {
    # Wait for client
    $task = $server.WaitForClient(120)
    $task.Wait()
    
    if ($task.Result) {
        # Send handshake
        $server.SendHandshake()
        
        # Listen for messages
        $server.ListenLoop()
    } else {
        Write-Host "`nNo client connected" -ForegroundColor Yellow
    }
} catch {
    Write-Host "`nError: $_" -ForegroundColor Red
} finally {
    $server.Cleanup()
}
