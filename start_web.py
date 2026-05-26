#!/usr/bin/env python3
"""
Alternative launcher for the web interface.
Tries different ports if the default one is blocked.
"""

import socket
import sys
import os

# Prevent Windows PyTorch/OpenMP multiprocessing crashes in background threads
os.environ["KMP_DUPLICATE_LIB_OK"] = "TRUE"
# Prevent HuggingFace tokenizers from crashing Windows background threads
os.environ["TOKENIZERS_PARALLELISM"] = "false"
try:
    import torch
    # Pre-initialize SentenceTransformer to prevent deep-call OpenMP crashes on Windows
    print("Pre-initializing PyTorch and SentenceTransformer...")
    from sentence_transformers import SentenceTransformer
    _ = SentenceTransformer('all-MiniLM-L6-v2', trust_remote_code=True, local_files_only=True)
    print("Pre-initialization complete.")
except Exception as e:
    print(f"Failed to pre-initialize: {e}")

# Add src directory to Python path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'src'))

from web_app import create_app
from utils.helpers import load_config

def is_port_available(port):
    """Check if a port is available."""
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        try:
            s.bind(('localhost', port))
            return True
        except OSError:
            return False

def main():
    """Start the web server on an available port."""
    # Try different ports
    web_port = int(os.getenv("KALI_WEB_PORT", "5000"))
    ports_to_try = [web_port, 5001, 8000, 8080]
    
    app = create_app()
    config = load_config("config/config.json")
    
    for port in ports_to_try:
        if is_port_available(port):
            print(f"Starting KALI Web Interface...")
            print(f"Access the application at: http://localhost:{port}")
            print(f"KALI is ready to help!")
            print(f"Press CTRL+C to stop the server")
            print("-" * 50)
            
            try:
                from waitress import serve
                import logging
                server_logger = logging.getLogger("waitress")
                server_logger.setLevel(logging.INFO)
                
                serve(app, host='127.0.0.1', port=port, threads=12, _quiet=False)
                # If serve returns, it means the server stopped.
                print(f"Waitress server on port {port} stopped.")
                break
            except Exception as e:
                print(f"CRITICAL: Server on port {port} failed: {e}")
                import traceback
                traceback.print_exc()
                continue
        else:
            print(f"Port {port} is not available, trying next...")
    
    else:
        print("Could not find an available port. Please check your system.")

if __name__ == "__main__":
    main()
