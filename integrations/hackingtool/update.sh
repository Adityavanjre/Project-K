#!/bin/bash
set -euo pipefail

INSTALL_DIR="/usr/share/hackingtool"

if [[ $EUID -ne 0 ]]; then
    echo "[ERROR] Run as root: sudo bash update.sh"
    exit 1
fi

if [[ ! -d "$INSTALL_DIR" ]]; then
    echo "[ERROR] Installation not found at $INSTALL_DIR. Run install.py first."
    exit 1
fi

echo "[*] Checking internet connection..."
if ! curl -sSf --max-time 10 https://github.com > /dev/null; then
    echo "[ERROR] No internet connection."
    exit 1
fi
echo "[✔] Internet OK"

echo "[*] Pulling latest changes..."
git -C "$INSTALL_DIR" config --local safe.directory "$INSTALL_DIR"
git -C "$INSTALL_DIR" pull --rebase

echo "[*] Updating Python dependencies..."
if [[ -f "$INSTALL_DIR/venv/bin/pip" ]]; then
    "$INSTALL_DIR/venv/bin/pip" install -q --upgrade -r "$INSTALL_DIR/requirements.txt"
else
    echo "[WARN] venv not found — skipping pip update. Run install.py to create it."
fi

echo "[✔] Hackingtool updated. Run 'hackingtool' to start."
