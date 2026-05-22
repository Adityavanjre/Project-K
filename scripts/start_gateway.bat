@echo off
echo.
echo =====================================================
echo   KALI GATEWAY - SOVEREIGN: Channel Gateway Layer
echo =====================================================
echo.
echo Starting WhatsApp Bridge (Node.js)...
start "KALI WhatsApp Bridge" cmd /k "node scripts\whatsapp_bridge.js"

timeout /t 3 /nobreak >nul

echo Starting KALI Gateway Server (Python)...
start "KALI Gateway" cmd /k "cd /d %~dp0.. && python src\kali_gateway.py"

echo.
echo [KALI] Both services starting.
echo [KALI] WhatsApp Bridge: http://localhost:3001/status
echo [KALI] Gateway Status:  http://localhost:8001/gateway/status
echo [KALI] Web Interface:   http://localhost:8000
echo.
echo Scan the QR code in the 'KALI WhatsApp Bridge' window
echo to link your WhatsApp account.
echo.
pause
