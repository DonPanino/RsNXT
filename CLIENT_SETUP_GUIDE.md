# RuneScape 945 Client Connection Guide

## Problem Discovered
The RS3 NXT client (build 945) **cannot run standalone** - it crashes immediately with Access Violation (0xC0000005) when launched directly. This is because:
- The client requires initialization by JagexLauncher.exe
- The launcher sets up the runtime environment, memory, and possibly injects code
- Both patched and unpatched clients crash the same way when run directly

## Solution
Use the **official Jagex Launcher** to launch the client, but redirect it to connect to your local server.

## Setup Steps

### 1. Patch the Official Client (REQUIRED - Run as Admin)
```powershell
cd A:\RSPS\OpenNXT
.\patch-official.ps1
```
This will:
- Create backup: `C:\Program Files (x86)\Jagex Launcher\Games\RuneScape\RuneScape.exe.backup`
- Patch the official client with your server's RSA keys from `data/config/rsa.toml`
- Requires Administrator privileges to modify Program Files

### 2. Setup Hosts File Redirection (OPTIONAL)
**Option A: Hosts File Method** (Redirects all RS3 traffic)
```powershell
cd A:\RSPS\OpenNXT
.\setup-hosts-redirect.ps1
```
This adds to `C:\Windows\System32\drivers\etc\hosts`:
```
127.0.0.1    world1.runescape.com
127.0.0.1    www.runescape.com
127.0.0.1    secure.runescape.com
```

**Option B: DNS Server Method** (More flexible, can keep live RS3 working)
- Keep hosts file unchanged
- We need to find Jagex Launcher arguments or config to specify custom server

### 3. Start Your Server
```powershell
cd A:\RSPS\OpenNXT
java -jar build\libs\OpenNXT-1.0.0-all.jar run-server --skip-http-file-verification
```
Make sure:
- HTTP server running on port 80 (serves /jav_config.ws)
- Game server running on port 43594
- Server logs show: `[Server] Listening on /0.0.0.0:43594`

### 4. Launch Through Jagex Launcher
```powershell
Start-Process "C:\Program Files (x86)\Jagex Launcher\JagexLauncher.exe"
```
- Click "RuneScape" in the launcher
- The patched client will use your server's RSA keys
- With hosts file redirection, it will connect to 127.0.0.1

## Verification
Watch your Server terminal for:
```
[HTTP][ms] from=/127.0.0.1:xxxxx uri=/ms?m=0&a=0
[HTTP][ms] Serving checksum table
```

If you see these logs, the client successfully:
1. Launched through Jagex Launcher (no crash)
2. Connected to your HTTP server (redirected via hosts or args)
3. Requested game cache/config

## Troubleshooting

### Client Still Crashes
- Did you run patch-official.ps1 as Administrator?
- Check if backup exists: `C:\Program Files (x86)\Jagex Launcher\Games\RuneScape\RuneScape.exe.backup`

### Client Launches But No Server Connection
- Check if hosts file was updated: `notepad C:\Windows\System32\drivers\etc\hosts`
- Verify server is running: `netstat -an | findstr :43594`
- Check firewall isn't blocking ports 80 or 43594

### Need to Play Real RS3
Restore the backup:
```powershell
Copy-Item "C:\Program Files (x86)\Jagex Launcher\Games\RuneScape\RuneScape.exe.backup" `
          "C:\Program Files (x86)\Jagex Launcher\Games\RuneScape\RuneScape.exe" -Force
```

And remove hosts entries or use a tool like HostsMan to toggle them.

## Next Steps After Connection
Once the client connects, you'll need to implement:
1. **Login protocol** - Handle client handshake and authentication
2. **World initialization** - Send PLAYER_INFO, NPC_INFO packets
3. **Protocol packets** - Complete the stubs in `data/prot/945/`
4. **Cache sync** - Ensure client cache matches server

## Alternative: Find Launcher Args
We could also try to find if JagexLauncher.exe accepts arguments to specify:
- Custom config URL
- Custom server address
- Development mode flags

This would avoid needing hosts file modifications.
