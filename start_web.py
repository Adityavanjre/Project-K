#!/usr/bin/env python3
"""
Alternative launcher for the web interface.
Tries different ports if the default one is blocked.
"""

import socket
import sys
import os

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
    # Try port 5000 for verification stability
    ports_to_try = [5000]
    
    app = create_app()
    config = load_config("config/config.json")
    
    for port in ports_to_try:
        if is_port_available(port):
            print(f"🚀 Starting KALI Web Interface...")
            print(f"📍 Access the application at: http://localhost:{port}")
            print(f"❓ KALI is ready to help!")
            print(f"💡 Press CTRL+C to stop the server")
            print("-" * 50)
            
            try:
                from waitress import serve
                serve(app, host='0.0.0.0', port=port, threads=4)
                break
            except Exception as e:
                print(f"Server on port {port} failed: {e}")
                continue
        else:
            print(f"Port {port} is not available, trying next...")
    
    else:
        print("❌ Could not find an available port. Please check your system.")

if __name__ == "__main__":
    main()
