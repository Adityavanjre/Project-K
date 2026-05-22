#!/usr/bin/env python3
"""
KALI Security Anchor Regeneration
Regenerates the cryptographic manifest for the current system state.
Run this after intentional core modifications to prevent BIOS boot locks.
"""

import os
import sys
import logging

# Add src to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'src'))

from core.integrity import IntegrityService

def regenerate_anchor():
    logging.basicConfig(level=logging.INFO)
    logger = logging.getLogger("SECURITY_ANCHOR")
    
    print("[*] KALI SECURITY: REGENERATING SYSTEM MANIFEST")
    print("-" * 60)
    
    # Force regeneration
    project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
    integrity = IntegrityService(project_root)
    
    # Path to manifest
    manifest_path = os.path.join(project_root, "data", "kali_core.manifest")
    if os.path.exists(manifest_path):
        os.remove(manifest_path)
        logger.info("Existing manifest purged.")
    
    integrity.generate_signatures()
    
    print("-" * 60)
    print("[+] SUCCESS: Security anchor synchronized with current system state.")
    print("KALI BIOS is now clear for Secure Boot.")

if __name__ == "__main__":
    regenerate_anchor()
