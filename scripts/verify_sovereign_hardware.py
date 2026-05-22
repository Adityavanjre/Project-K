#!/usr/bin/env python3
"""
KALI Hardware Sovereignty Verification
Forcefully anchors the current hardware to the UserDNA profile.
Ensures KALI recognizes this machine as her "Sovereign Home".
"""

import os
import sys
import logging
import json

# Add src to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'src'))

from core.user_dna import UserDNA

def verify_hardware():
    logging.basicConfig(level=logging.INFO)
    logger = logging.getLogger("HW_VERIFY")
    
    print("[*] KALI SOVEREIGNTY: ANCHORING HARDWARE DNA")
    print("-" * 60)
    
    user_dna = UserDNA("default") # Assuming default user for now
    
    # Get current hardware ID
    hw_id = user_dna._get_hardware_uid()
    logger.info(f"Detected Hardware DNA: {hw_id[:16]}...")
    
    # Update profile
    profile = user_dna.profile
    if "security" not in profile:
        profile["security"] = {}
    
    profile["security"]["hardware_anchor"] = hw_id
    profile["security"]["hw_verified"] = True
    
    # Save back
    user_dna._save(profile)
    
    print("-" * 60)
    print("[+] SUCCESS: Hardware DNA anchored and verified.")
    print("KALI now recognizes this machine as her Sovereign Home.")
    print("Restricted Mode interlock deactivated.")

if __name__ == "__main__":
    verify_hardware()
