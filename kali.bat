@echo off
set OLLAMA_HOST=127.0.0.1:11435
if "%~1"=="" (
    ollama run KALI
) else (
    ollama run KALI %*
)
