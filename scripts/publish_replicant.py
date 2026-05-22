#!/usr/bin/env python3
"""
KALI Sovereign Clone Publisher
Sanitizes the codebase for public propagation (SOVEREIGN).
Removes private data, secrets, and prepares the Replicant Manifest.
"""

import os
import shutil
import json
import logging

# Configuration
PRIVATE_FILES = [
    ".env",
    "secrets/",
    "data/private_history.db",
    "config/user_dna.json",
    "logs/",
    "__pycache__/",
    ".pytest_cache/"
]

def sanitize_codebase(source_dir, target_dir):
    """Copy and sanitize the codebase."""
    if os.path.exists(target_dir):
        shutil.rmtree(target_dir)
    
    # Copy all files
    shutil.copytree(source_dir, target_dir, ignore=shutil.ignore_patterns('.git', '.gemini', '.local', 'node_modules'))
    
    # Remove private files
    for item in PRIVATE_FILES:
        path = os.path.join(target_dir, item)
        if os.path.exists(path):
            if os.path.isdir(path):
                shutil.rmtree(path)
            else:
                os.remove(path)
    
    # Create Replicant Manifest
    manifest = {
        "identity": "KALI_REPLICANT",
        "parent_node": "ADITYA_SOVEREIGN",
        "timestamp": "2026-04-27",
        "license": "Sovereign Open Source License (SOSL)",
        "pillars_active": 8
    }
    
    with open(os.path.join(target_dir, "replicant_manifest.json"), "w") as f:
        json.dump(manifest, f, indent=4)
    
    print(f"[SUCCESS] Sovereign Replicant manifested at: {target_dir}")

if __name__ == "__main__":
    src = os.getcwd()
    dest = os.path.join(os.path.dirname(src), "KALI-Replicant")
    sanitize_codebase(src, dest)
