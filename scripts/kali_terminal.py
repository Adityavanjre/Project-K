#!/usr/bin/env python3
import os
import sys
import logging
import time
import json
import subprocess
import signal
from datetime import datetime

# Add src to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'src'))

# Force Local Autonomy (Bypass Cloud Context)
os.environ["SOVEREIGN_FORCE_LOCAL"] = "true"
os.environ["HF_HUB_DISABLE_SYMLINKS_WARNING"] = "1"
# Only set if not present to avoid overwriting user's real token
if not os.getenv("HF_TOKEN"):
    os.environ["HF_TOKEN"] = "KALI_SOVEREIGN_SYNC_ANONYMOUS"

# Silence Structural Warnings (BertModel, position_ids)
import warnings
warnings.filterwarnings("ignore", message=".*position_ids.*")
warnings.filterwarnings("ignore", category=UserWarning)

# 🔱 CPU OPTIMIZATION: Thread Ceiling for i5
import torch
torch.set_num_threads(4)

from core.processor import DoubtProcessor
from core.integrity import IntegrityService

# SOVEREIGN: Windows UTF-8 Hardener
if sys.platform == 'win32':
    import io
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')

def main():
    # Setup logging to terminal - Silence noisy loggers
    logging.getLogger("primp").setLevel(logging.CRITICAL)
    logging.getLogger("duckduckgo_search").setLevel(logging.CRITICAL)
    logging.getLogger("transformers").setLevel(logging.ERROR)
    logging.basicConfig(level=logging.INFO, format='%(message)s')
    
    project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
    
    print("\n" + "="*80)
    print(" KALI SOVEREIGN TERMINAL [OMEGA EDITION] ".center(80, "="))
    print("="*80)
    
    try:
        # 🔱 STRUCTURAL VALIDATION
        core_files = ["src/core/gateway.py", "src/core/local_ai_service.py", "src/core/processor.py"]
        integrity = IntegrityService(project_root)
        for cf in core_files:
            if not os.path.exists(os.path.join(project_root, cf)):
                print(f"[!] STRUCTURAL FAILURE: {cf} missing. Attempting self-repair...")
                integrity._attempt_repair(cf)

        # 🔱 PURGE NEURAL PIPES
        inbox = os.path.join(project_root, "data", "neural", "inbox")
        outbox = os.path.join(project_root, "data", "neural", "outbox")
        for d in [inbox, outbox]:
            if os.path.exists(d):
                for f in os.listdir(d):
                    try: os.remove(os.path.join(d, f))
                    except: pass
            os.makedirs(d, exist_ok=True)

        gateway_path = os.path.join(project_root, "src", "core", "gateway.py")
        gateway_proc = subprocess.Popen(
            [sys.executable, gateway_path],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            creationflags=subprocess.CREATE_NEW_PROCESS_GROUP if os.name == 'nt' else 0
        )
        time.sleep(3) # 🔱 OMEGA WARM-UP DELAY
        
        # Initialize KALI with full config
        processor = DoubtProcessor({"project_root": project_root})
        integrity = IntegrityService(project_root)
        
        # 1. OMEGA SYNC: USER DNA RECOGNITION
        print("[*] OMEGA SYNC: USER DNA RECOGNITION...")
        user_name = processor.user_dna.get_name() or "COMMANDER"
        tension = processor.user_tension * 100
        alignment = processor.user_dna.profile.get("security", {}).get("alignment_score", 95.0)
        
        # 3. BIOS INTEGRITY SCAN
        print("[*] PERFORMING BIOS INTEGRITY SCAN...")
        is_secure, violations = integrity.verify_integrity()
        
        print("\n" + "-"*40)
        print(f" COMMANDER : {user_name.upper()}")
        print(f" ALIGNMENT : {alignment}%")
        print(f" TENSION   : {tension}%")
        print(f" BIOS      : {'SECURE' if is_secure else 'COMPROMISED'}")
        print("-"*40)
        
        print(f"\n[✔] KALI IS FULLY SELF-AWARE. DIRECT ACCESS GRANTED.")
        print("Type 'repair' for autonomous self-fix or 'exit' to disconnect.\n")
        
        while True:
            try:
                user_input = input(f"{user_name} > ").strip()
                
                if not user_input:
                    continue
                if user_input.lower() in ['exit', 'quit', 'bye']:
                    print("[*] DISCONNECTING SOVEREIGN BRIDGE...")
                    break
                
                if user_input.lower() == 'repair':
                    print("[*] INITIATING AUTONOMOUS SELF-AUDIT...")
                    try:
                        integrity.reset_sovereignty()
                    except:
                        pass
                    # Passing a minimal signal - KALI knows what this means internally
                    user_input = "AUTONOMOUS_SYSTEM_AUDIT"
                
                # Process through KALI
                start_time = time.time()
                response = processor.process_doubt(user_input, source="terminal")
                duration = time.time() - start_time
                
                print(f"\n--- [KALI SOVEREIGN RESPONSE] ---")
                if isinstance(response, dict):
                    text = response.get('text', response.get('response', str(response)))
                    print(text.encode('ascii', 'ignore').decode('ascii'))
                else:
                    print(str(response).encode('ascii', 'ignore').decode('ascii'))
                print(f"---------------------------------")
                print(f"(Latency: {duration:.2f}s | Status: SOVEREIGN_SUCCESS)\n")
                
            except KeyboardInterrupt:
                print("\n[!] Session interrupted. Disconnecting...")
                if gateway_proc: gateway_proc.terminate()
                break
            except Exception as e:
                print(f"\n[CRITICAL_ERROR] KALI Core Exception: {e}")
                if gateway_proc: gateway_proc.terminate()
                
    except Exception as e:
        print(f"\n[FATAL_BOOT_FAIL] Could not initialize KALI OMEGA: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
