@echo off
echo.
echo [KALI] Setting up WhatsApp Bridge...
echo.

REM Check Node.js
where node >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Node.js not found. Install from https://nodejs.org
    pause
    exit /b 1
)

echo [KALI] Node.js found. Installing whatsapp-web.js dependencies...
cd /d "%~dp0"
call npm init -y >nul 2>&1
call npm install whatsapp-web.js express qrcode-terminal

echo.
echo [KALI] Setup complete.
echo [KALI] Now run: node scripts\whatsapp_bridge.js
echo [KALI] Scan the QR code with WhatsApp ^> Linked Devices
echo.
pause
