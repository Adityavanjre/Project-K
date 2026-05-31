#!/usr/bin/env python3
"""
KALI Cloud Web Launcher.
Starts the Flask web app on the correct port for HuggingFace Spaces.
All heavy model loading is done lazily — this file must boot fast.
"""

import socket
import sys
import os

# Critical: set these BEFORE any imports to prevent thread crashes
os.environ["KMP_DUPLICATE_LIB_OK"] = "TRUE"
os.environ["TOKENIZERS_PARALLELISM"] = "false"
# On HF Spaces, force cloud mode so no local models are loaded on boot
if os.getenv("SPACE_ID"):  # HF sets this automatically
    os.environ["KALI_CLOUD_MODE"] = "true"
    os.environ["KALI_WEB_PORT"] = "7860"
    print("[KALI CLOUD] HuggingFace Space detected — CLOUD MODE active.")

# NOTE: SentenceTransformer pre-init removed — lazy loading only.
# Pre-loading on HF Spaces caused OOM and restart loops.

# Add src directory to Python path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "src"))

try:
    from web_app import create_app
except Exception as e:
    print(f"[CRITICAL] Failed to import web_app: {e}")
    import traceback
    traceback.print_exc()
    sys.exit(1)

try:
    from utils.helpers import load_config
    config = load_config("config/config.json")
except Exception as e:
    print(f"[WARNING] Could not load config: {e}")
    config = {}

def is_port_available(port):
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        try:
            s.bind(("0.0.0.0", port))
            return True
        except OSError:
            return False

def main():
    # Initialize required directories
    try:
        base_dir = os.path.dirname(os.path.abspath(__file__))
        for d in ["data/neural/inbox", "data/neural/outbox", "logs", "reports"]:
            os.makedirs(os.path.join(base_dir, d), exist_ok=True)
    except Exception as e:
        print(f"[WARNING] Failed to init directories: {e}")

    # Port selection: HF Spaces requires 7860
    web_port = int(os.getenv("KALI_WEB_PORT", "7860"))
    ports_to_try = [web_port, 5000, 5001, 8000, 8080]

    try:
        app = create_app()
    except Exception as e:
        print(f"[CRITICAL] create_app() failed: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)

    for port in ports_to_try:
        if is_port_available(port):
            print(f"[KALI CLOUD] Starting web server on port {port}...")
            try:
                from waitress import serve
                import logging
                logging.getLogger("waitress").setLevel(logging.INFO)

                # Always bind to 0.0.0.0 on HF (container needs external access)
                listen_host = "0.0.0.0"
                print(f"[KALI CLOUD] Listening on {listen_host}:{port}")
                serve(app, host=listen_host, port=port, threads=4, _quiet=False)
                break
            except Exception as e:
                print(f"[KALI CLOUD] Server on port {port} failed: {e}")
                import traceback
                traceback.print_exc()
                continue
        else:
            print(f"[KALI CLOUD] Port {port} busy, trying next...")
    else:
        print("[CRITICAL] No port available. Exiting.")
        sys.exit(1)

if __name__ == "__main__":
    main()
