import os
import sys

# Add src to path
sys.path.insert(0, os.path.join(os.getcwd(), 'src'))

from core.integrity import IntegrityService

def reanchor():
    print("[ANCHOR] KALI BIOS: Re-anchoring Sovereignty Manifest...")
    service = IntegrityService()
    success = service.reset_sovereignty()
    if success:
        print("[SUCCESS] KALI BIOS: Sovereignty Anchored. Integrity manifest updated.")
    else:
        print("[ERROR] KALI BIOS: Failed to anchor sovereignty.")

if __name__ == "__main__":
    reanchor()
