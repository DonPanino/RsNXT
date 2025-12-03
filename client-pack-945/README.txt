RS3 Client Pack (Build 945)

Contents:
- rs2client.exe (patched RSA)
- JagexLauncher.exe (standalone stub)
- jav_config.ws (points to localhost)
- D3Dcompiler_47.dll, libEGL.dll, libGLESv2.dll (required DLLs)
- install.ps1 (bootstrap script)

Requirements:
- Latest GPU drivers (OpenGL 3.3+)
- Microsoft Visual C++ Redistributable (x64)
- OpenNXT server running on localhost (HTTP 80, game 43594)

Setup:
1) Run PowerShell as normal user.
2) In this folder, run:
   ./install.ps1
3) Start the client:
   ./JagexLauncher.exe

Notes:
- DLLs must be placed directly next to rs2client.exe.
- If install.ps1 reports missing DLLs and you have copies in DLLs/, it will copy them automatically.
- If the client still exits immediately, check CrashDumps under %LOCALAPPDATA%\CrashDumps.Client Pack 945

Contents:
- rs2client.exe (patched 945 client)
- DLLs/ (graphics runtime DLLs)
- jav_config.ws (945 config pointing to local server)
- launch.ps1 (launcher script)

Usage:
1) Ensure OpenNXT server is running on ports 80 and 43594
2) Run launch.ps1 to start the client against local server
