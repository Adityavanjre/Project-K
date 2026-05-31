#!/bin/bash

echo "===== Application Startup at $(date) ====="

# === CLOUD MODE: Skip Ollama entirely on HF Spaces ===
# Ollama requires root or systemd on HF free tier — skip it
echo "[KALI CLOUD] Running in CLOUD MODE — Skipping Ollama (external API mode)"

# Check if model exists (mounted via HF Dataset bucket or pre-downloaded)
if [ -f "models/KALI_SOUL_SOVEREIGN.gguf" ]; then
    echo "[KALI CLOUD] Local model found. Registering with Ollama..."
    ollama serve &
    sleep 5
    echo "FROM $(pwd)/models/KALI_SOUL_SOVEREIGN.gguf" > Modelfile_runtime
    ollama create KALI -f Modelfile_runtime && echo "[KALI CLOUD] Local model registered."
else
    echo "[KALI CLOUD] No local GGUF model found — using external API (cloud mode). This is normal on HF Spaces."
fi

# Initialize required directories
echo "[KALI CLOUD] Initializing data directories..."
mkdir -p data/neural/inbox data/neural/outbox data/cache/neural logs reports

# Skip the neural gateway (requires local model) in cloud mode
# echo "[KALI CLOUD] Igniting Neural Gateway..."
# python -m src.core.gateway &

# Start the Web App on HF port 7860
echo "[KALI CLOUD] Starting KALI Web Gateway on port 7860..."
python start_web.py
