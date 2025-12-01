# Setup hosts file redirection for RS3 to connect to local server
Write-Host "=== Setup Hosts File Redirection ===" -ForegroundColor Cyan
Write-Host "This will redirect RuneScape domains to your local server" -ForegroundColor Yellow
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

$hostsFile = "C:\Windows\System32\drivers\etc\hosts"

# Backup hosts file
$backupFile = "$hostsFile.backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
Copy-Item $hostsFile $backupFile
Write-Host "Backed up hosts file to: $backupFile" -ForegroundColor Green

# RS3 domains to redirect (from jav_config.ws analysis)
$redirects = @(
    "world1.runescape.com",
    "world2.runescape.com", 
    "world3.runescape.com",
    "www.runescape.com",
    "secure.runescape.com",
    "services.runescape.com"
)

# Read current hosts file
$hostsContent = Get-Content $hostsFile

# Remove any existing RS redirects
$hostsContent = $hostsContent | Where-Object { $_ -notmatch "runescape\.com" }

# Add our redirects
Write-Host ""
Write-Host "Adding redirects:" -ForegroundColor Cyan
$newEntries = @()
foreach ($domain in $redirects) {
    $entry = "127.0.0.1    $domain"
    $newEntries += $entry
    Write-Host "  $entry" -ForegroundColor Gray
}

# Write updated hosts file (robust write for system file)
$hostsContent += ""
$hostsContent += "# RuneScape Private Server - Added $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
$hostsContent += $newEntries

# Use .NET API to avoid locked stream issues and enforce ASCII encoding
[System.IO.File]::WriteAllLines($hostsFile, $hostsContent, [System.Text.Encoding]::ASCII)

Write-Host ""
Write-Host "Hosts file updated successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "Now when you launch RS3 through Jagex Launcher:" -ForegroundColor Yellow
Write-Host "  1. It will connect to 127.0.0.1 instead of Jagex servers" -ForegroundColor Gray
Write-Host "  2. Make sure your OpenNXT server is running on port 43594" -ForegroundColor Gray
Write-Host "  3. Make sure your HTTP server is running on port 80" -ForegroundColor Gray
Write-Host ""
Write-Host "To undo this, restore from backup:" -ForegroundColor Cyan
Write-Host "  Copy-Item '$backupFile' '$hostsFile' -Force" -ForegroundColor Gray
Write-Host ""

Read-Host "Press Enter to exit"
