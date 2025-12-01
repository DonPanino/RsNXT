# Patch Official Jagex Launcher Client (requires admin)
Write-Host "=== Patching Official Jagex Launcher RS3 Client ===" -ForegroundColor Cyan
Write-Host "This will patch the installed client with your server's RSA keys" -ForegroundColor Yellow
Write-Host ""

# Check if running as admin
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "This script requires Administrator privileges!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Restarting as Administrator..." -ForegroundColor Yellow
    
    $scriptPath = $MyInvocation.MyCommand.Path
    Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoExit", "-File", $scriptPath
    exit
}

Write-Host "Running as Administrator" -ForegroundColor Green
Write-Host ""

# Check if client exists
$officialClient = "C:\Program Files (x86)\Jagex Launcher\Games\RuneScape\RuneScape.exe"
if (-not (Test-Path $officialClient)) {
    Write-Host "Official client not found: $officialClient" -ForegroundColor Red
    Write-Host "Please install Jagex Launcher and RuneScape first" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "Found official client: $officialClient" -ForegroundColor Green

# Check if RSA config exists
$rsaConfig = "A:\RSPS\OpenNXT\data\config\rsa.toml"
if (-not (Test-Path $rsaConfig)) {
    Write-Host "RSA config not found: $rsaConfig" -ForegroundColor Red
    Write-Host "Please run 'java -jar OpenNXT-All.jar run-tool rsa-key-generator' first" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "Found RSA config: $rsaConfig" -ForegroundColor Green
Write-Host ""

# Ask for confirmation
Write-Host "WARNING: This will modify the official RS3 client!" -ForegroundColor Yellow
Write-Host "A backup will be created as RuneScape.exe.backup" -ForegroundColor Gray
Write-Host ""
$confirm = Read-Host "Continue? (yes/no)"

if ($confirm -ne "yes") {
    Write-Host "Aborted" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 0
}

Write-Host ""
Write-Host "Running patcher..." -ForegroundColor Cyan

# Run the Python patcher
cd A:\RSPS\Tools
python patch_official_client.py

Write-Host ""
Read-Host "Press Enter to exit"
