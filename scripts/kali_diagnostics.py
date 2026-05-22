#!/usr/bin/env python3
import os
import sys
import logging
import time

# Add project root and src to path
project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
sys.path.insert(0, project_root)
sys.path.insert(0, os.path.join(project_root, 'src'))

from core.integrity import IntegrityService
from core.secure_boot import BootGuardian

def main():
    print("\n" + "="*60)
    print(" KALI SOVEREIGN DIAGNOSTICS & RECOVERY")
    print("="*60 + "\n")

    print("[1] Performing Full Integrity Audit...")
    integrity = IntegrityService(root_dir=project_root)
    is_intact, violations = integrity.verify_integrity(auto_repair=False)
    
    if is_intact:
        print("[PASS] System integrity verified. Signatures match manifest.")
    else:
        print(f"[FAIL] Integrity Breach! Found {len(violations)} violations.")
        for v in violations:
            print(f"  - {v}")
        
        choice = input("\nAttempt auto-repair from recovery baseline? (y/n): ").lower()
        if choice == 'y':
            print("Repairing...")
            integrity.verify_integrity(auto_repair=True)
            print("[DONE] Repair cycle complete.")

    print("\n[2] Checking BIOS Secure Boot Status...")
    guardian = BootGuardian(project_root=project_root)
    is_secure = guardian.perform_secure_boot()
    if is_secure:
        print("[PASS] BIOS Secure Boot active. System is Sovereign.")
    else:
        print("[FAIL] BIOS Security Breach detected.")

    print("\n[3] Validating Local AI Connectivity...")
    try:
        from core.local_ai_service import LocalAIService
        local_ai = LocalAIService()
        if local_ai.is_available():
            print(f"[PASS] Local AI detected: {local_ai.model}")
        else:
            print("[FAIL] Ollama/Local AI service not responding.")
    except Exception as e:
        print(f"[ERROR] AI Service check failed: {e}")

    print("\n" + "="*60)
    print(" DIAGNOSTICS COMPLETE")
    print("="*60 + "\n")
    input("Press Enter to return to launcher...")

if __name__ == "__main__":
    main()
