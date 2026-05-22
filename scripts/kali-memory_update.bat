@echo off
echo [KALI] Updating Knowledge Graph (AST pass - zero API cost)...
cd /d "%~dp0.."
:: Set graphify path explicitly to avoid environment issues
set "GRAPHIFY_PATH=C:\Users\adity\AppData\Roaming\Python\Python314\Scripts"
"%GRAPHIFY_PATH%\graphify.exe" update .
echo.
echo [KALI] Graph updated. View results:
echo        graphify-out\GRAPH_REPORT.md
echo        graphify-out\graph.html
echo.
timeout /t 5

