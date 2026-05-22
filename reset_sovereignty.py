import sys
import os

# Add project root to sys.path
project_root = os.path.dirname(os.path.abspath(__file__))
sys.path.append(os.path.join(project_root, "src"))

from core.integrity import IntegrityService

def reset_kali_sovereignty():
    print("--- INITIATING EMERGENCY SOVEREIGNTY RE-ANCHORING ---")
    integrity = IntegrityService(project_root)
    
    # Force re-generation of the manifest with current file hashes
    success = integrity.reset_sovereignty()
    
    if success:
        print("SUCCESS: BIOS Ledger updated. System Integrity Re-Anchored.")
        print("KALI now recognizes your custom modifications as official Sovereign Code.")
    else:
        print("FAILED: Could not update the BIOS ledger.")

if __name__ == "__main__":
    reset_kali_sovereignty()
