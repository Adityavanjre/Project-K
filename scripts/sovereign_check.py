import os
import socket
import hashlib
import requests
from dotenv import load_dotenv

load_dotenv()

class SovereignCheck:
    """
    KALI SOVEREIGNTY VALIDATOR
    Phase 28: Sovereign Distributed Identity
    """
    
    def __init__(self):
        self.owner_key = os.getenv("SECRET_OWNER_KEY")
        self.home_hostname = "adity-pc" # Hardcoded origin
        self.heartbeat_url = "https://raw.githubusercontent.com/adity/kali-heartbeat/main/status.json" # Placeholder
        
    def check_origin(self):
        """Checks if this instance is running on its true home."""
        current_hostname = socket.gethostname().lower()
        if "adity" not in current_hostname:
            return False, "HARDWARE_MITM_DETECTED"
        
        if not self.owner_key:
            return False, "ENV_DNA_MISSING"
            
        return True, "SOVEREIGN_HOME_VERIFIED"
        
    def check_heartbeat(self):
        """
        Verify against global trace. 
        In a real scenario, this would check a signed token on a remote server.
        """
        try:
            # For now, we simulate success if the owner key is correct.
            # In Phase 28, this will query a decentralized ledger or private API.
            if self.owner_key == "KALI_OWNER_ALPHA_99": # Example correct key
                return True
            return False
        except Exception:
            # Fail closed: No internet = GUEST_MODE for security
            return False

if __name__ == "__main__":
    checker = SovereignCheck()
    status, msg = checker.check_origin()
    print(f"[KALI_SOVEREIGNTY] Status: {status} | Message: {msg}")
