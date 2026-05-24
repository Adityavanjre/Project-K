@echo off
title K.A.L.I. Sovereign Ignition
echo =======================================================
echo     K.A.L.I. (Knowledge Augmented Learning Intelligence)
echo     Initializing Sovereign Master Node...
echo =======================================================
echo.

:: Check if Python is installed
python --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Python is not installed or not in PATH.
    pause
    exit /b
)

:: Activate virtual environment if it exists
if exist "venv\Scripts\activate.bat" (
    echo [KALI] Activating isolated virtual environment...
    call venv\Scripts\activate.bat
) else (
    echo [KALI] No virtual environment found. Running on system Python...
)

echo.
echo [KALI] Igniting Neural Web Gateway (Backend + Frontend)...
echo -------------------------------------------------------

:: Run the master web entrypoint
python start_web.py

echo.
echo [KALI] Engine Shutdown.
pause
