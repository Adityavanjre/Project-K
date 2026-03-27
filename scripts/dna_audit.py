#!/usr/bin/env python3
"""
KALI DNA DENSITY AUDIT
Phase 9: Neural Core Evolution
Evaluates evolutionary readiness for Phase 3.2 Fine-Tuning.
"""

import json
import os
import sys

def run_dna_audit():
    print("🧬 KALI DNA DENSITY AUDIT")
    print("-" * 60)
    
    log_path = os.path.abspath("data/training_data.jsonl")
    if not os.path.exists(log_path):
        print("[!] ERROR: No Digital Soul detected. (data/training_data.jsonl missing)")
        return
        
    count = 0
    total_tokens = 0
    with open(log_path, "r", encoding="utf-8") as f:
        for line in f:
            count += 1
            data = json.loads(line)
            # Rough token estimate
            for msg in data.get("messages", []):
                total_tokens += len(msg.get("content", "").split())
                
    print(f"[*] Interaction Count: {count}")
    print(f"[*] Experience Density: {total_tokens} words")
    
    threshold = 1000 # Increased for high-fidelity Singularity State
    if count >= threshold:
        print(f"[+] EVOLUTIONARY STATUS: CRITICAL MASS REACHED ({count}/{threshold})")
        print("[+] KALI IS READY FOR PHASE 3.2: AUTONOMOUS FINE-TUNING.")
    else:
        gap = threshold - count
        print(f"[-] EVOLUTIONARY STATUS: ACCUMULATING ({count}/{threshold})")
        print(f"[-] Need approximately {gap} more high-quality interactions before Evolution.")
    
    print("-" * 60)

if __name__ == "__main__":
    run_dna_audit()
