import sys
import os
import logging
import time
from datetime import datetime

# Enforce UTF-8 for stdout/stderr to prevent encoding crashes on Windows
if sys.stdout.encoding != 'utf-8':
    try:
        import io
        sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
        sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')
    except Exception:
        pass

# Global Logger Setup
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s [%(levelname)s] %(name)s: %(message)s',
    handlers=[
        logging.StreamHandler(sys.stdout),
        logging.FileHandler("kali_boot.log", encoding='utf-8')
    ]
)
logger = logging.getLogger("KALI.Boot")

def start_kali():
    """
    Sovereign Entry Point for KALI ASI.
    Ensures stable initialization of Flask, SocketIO, and Neural Dependencies.
    """
    logger.info("="*50)
    logger.info(f"🔱 KALI SOVEREIGN BOOT INITIATED: {datetime.now().isoformat()}")
    logger.info("="*50)
    
    try:
        # Load environment variables early
        from dotenv import load_dotenv
        load_dotenv()
        logger.info("[+] Environment loaded.")

        # Hardened Import: web_app factory
        logger.info("[+] Initializing Web Application Factory...")
        from web_app import create_app
        
        # Create App Instance
        app = create_app()
        if not app:
            raise RuntimeError("Flask app factory returned None.")
        
        # Extract socketio instance from app
        if not hasattr(app, 'socketio'):
            raise RuntimeError("App instance missing 'socketio' attribute.")
        
        socketio = app.socketio
        logger.info("[+] Flask & SocketIO stack verified.")

        # Final Boot Check
        port = int(os.getenv("PORT", 5000))
        debug_mode = os.getenv("FLASK_DEBUG", "false").lower() == "true"
        
        logger.info(f"🔱 KALI Online at http://localhost:{port}")
        logger.info("Press Ctrl+C to initiate Sovereign Shutdown.")
        
        # Start the Engine (Note: threading mode for stability on Win/Py3.14)
        # Phase 108: Fix for 'The Werkzeug web server is not designed to run in production' on Windows/threading
        socketio.run(app, host='0.0.0.0', port=port, debug=debug_mode, use_reloader=False, allow_unsafe_werkzeug=True)

    except Exception as e:
        logger.critical(f"❌ KALI BOOT_CRASH: {str(e)}")
        import traceback
        logger.error(traceback.format_exc())
        sys.exit(1)

if __name__ == "__main__":
    try:
        start_kali()
    except KeyboardInterrupt:
        logger.info("Sovereign Shutdown Signal Received.")
    except Exception as e:
        print(f"FATAL BOOT ERROR: {e}")
        sys.exit(1)
