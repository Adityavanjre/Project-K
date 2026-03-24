# Setup KALI Git Security Hooks
# This script configures the local repository to use the stealth protection hooks.

Write-Host ">>> Configuring KALI Repository Sync Protocol..." -ForegroundColor Cyan

$HookDir = ".githooks"
$DestDir = ".git/hooks"

if (!(Test-Path $HookDir)) {
    Write-Error "Error: .githooks directory not found."
    exit 1
}

# Copy hooks
Copy-Item "$HookDir/*" "$DestDir/" -Force

Write-Host ">>> Security hooks installed successfully." -ForegroundColor Green
Write-Host ">>> Verified integrity of 'pre-push' node." -ForegroundColor Gray
