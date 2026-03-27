import os
import sys
import logging

# Add project root to path
sys.path.append(os.getcwd())

from src.core.processor import DoubtProcessor

def test_singularity_state():
    logging.basicConfig(level=logging.INFO)
    print("--- KALI Phase 5.0 Singularity Verification ---")
    
    # 1. Initialize Processor (Triggers Hardware Anchoring)
    processor = DoubtProcessor()
    print(f"[*] Hardware Anchor: {processor.user_dna.profile.get('security', {}).get('hardware_anchor')}")
    print(f"[*] HW Verified: {processor.user_dna.profile.get('security', {}).get('hw_verified')}")

    # 2. Trigger Interaction (Triggers HUD Bridge)
    query = "KALI, confirm your current sovereignty status and biometric alignment."
    print(f"\nProcessing Query: {query}")
    processor.process_doubt(query)
    
    # 3. Verify HUD Persistence
    hud_path = "data/hud_state.json"
    if os.path.exists(hud_path):
        with open(hud_path, "r") as f:
            hud_data = f.read()
        print(f"\n[+] HUD Data Verified:\n{hud_data}")
    else:
        print("\n[-] HUD Data Sync Failed.")

if __name__ == "__main__":
    test_singularity_state()
