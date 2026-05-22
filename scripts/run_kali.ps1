# KALI - Unified Launch Script
# Starts Ollama and the KALI Workstation together.

Write-Host "INITIALIZING KALI UNIFIED INTELLIGENCE..." -ForegroundColor Cyan

# 1. Start Ollama if not running
if (-not (Get-Process "ollama" -ErrorAction SilentlyContinue)) {
    Write-Host "Starting Local AI Backend (Ollama)..." -ForegroundColor Yellow
    Start-Process "ollama" -ArgumentList "serve" -WindowStyle Hidden
    Start-Sleep -Seconds 5
}

# 2. Virtual Env Check
if (Test-Path "venv") {
    Write-Host "Activating Environment..." -ForegroundColor Gray
    .\venv\Scripts\Activate.ps1
}

# 3. Launch Web App
Write-Host "LAUNCHING KALI WORKSTATION AT http://localhost:8000" -ForegroundColor Green
python src/web_app.py
