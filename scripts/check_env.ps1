# KALI Environment Audit: BitNet Readiness
Write-Host "Initiating KALI Hardware/Software Audit..."

# 1. Check Git
$git = Get-Command git -ErrorAction SilentlyContinue
if ($git) {
    Write-Host "OK: Git version: $(git --version)"
} else {
    Write-Host "MISSING: Git is not installed. Please install from https://git-scm.com/"
}

# 2. Check CMake
$cmake = Get-Command cmake -ErrorAction SilentlyContinue
if ($cmake) {
    Write-Host "OK: CMake version: $(cmake --version | Select-Object -First 1)"
} else {
    Write-Host "MISSING: CMake is not in PATH. Required for building bitnet.cpp."
}

# 3. Check MSVC (cl.exe)
$cl = Get-Command cl -ErrorAction SilentlyContinue
if ($cl) {
    Write-Host "OK: MSVC (cl.exe) found."
} else {
    Write-Host "MISSING: MSVC (Visual Studio Compiler) not found."
    Write-Host "Recommendation: Install Visual Studio 2022 Desktop development with C++ workload."
}

# 4. Check Python
$python = Get-Command python -ErrorAction SilentlyContinue
if ($python) {
    Write-Host "OK: Python version: $(python --version)"
} else {
    Write-Host "MISSING: Python not found."
}

# 5. Check Ollama
$ollama = Get-Command ollama -ErrorAction SilentlyContinue
if ($ollama) {
    Write-Host "OK: Ollama version: $(ollama --version)"
} else {
    Write-Host "MISSING: Ollama not found."
}

Write-Host "Audit Complete."
