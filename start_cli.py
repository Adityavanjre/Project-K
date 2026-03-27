#!/usr/bin/env python3
"""
KALI Sovereign CLI Interface
Direct Command-Line interaction with 'Live Core' logic.
Phase 5: Sovereign Hardening.
"""

import os
import sys
import logging
import uuid
from typing import Dict, Any

# Add src directory to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'src'))

try:
    from core.processor import DoubtProcessor
    from utils.helpers import load_config
except ImportError as e:
    print(f"CRITICAL ERROR: KALI Core Modules not found: {e}")
    sys.exit(1)

# Configure logging to be less verbose for CLI
logging.getLogger("werkzeug").setLevel(logging.ERROR)
logging.getLogger("urllib3").setLevel(logging.ERROR)

def clear_screen():
    os.system('cls' if os.name == 'nt' else 'clear')

def main():
    config = load_config("config/config.json")
    processor = DoubtProcessor(config)
    
    clear_screen()
    print("-" * 60)
    print("🕉️  K.A.L.I. — SOVEREIGN COMMAND-LINE INTERFACE")
    print(f"SYSTEM STATUS: {processor.power_mode}")
    print("Sir, I am now native to your CMD.")
    print("Type 'exit' to terminate. Type 'manifest [idea]' to build projects.")
    print("-" * 60)

    while True:
        try:
            query = input("\n[KALI] > ").strip()
            
            if not query:
                continue
                
            if query.lower() in ["exit", "quit", "bye"]:
                print("Acknowledged, Sir. Powering down.")
                break
                
            if query.lower().startswith("manifest "):
                idea = query[9:].strip()
                print(f"[*] INITIATING PROJECT MANIFESTATION: {idea}...")
                result = processor.process_project_mentor(idea)
                
                print(f"\n[KALI RESPONSE]\n{result.get('response', '')}")
                print(f"\n[MANIFEST PATH]: {result.get('manifest_path', 'FAILED')}")
                if result.get("audio_url"):
                    print(f"[VOCAL SIGNATURE]: http://localhost:5000{result.get('audio_url')}")
                continue

            # Default Interaction
            print("[*] PROCESSING COGNITIVE SEED...")
            result = processor.process_doubt(query)
            
            if isinstance(result, dict):
                text = result.get("text", "")
                audio = result.get("audio_url", "")
                print(f"\n[KALI RESPONSE]\n{text}")
                if audio:
                    print(f"\n[VOCAL SIGNATURE]: http://localhost:5000{audio}")
            else:
                print(f"\n[KALI RESPONSE]\n{result}")

            # DPO Feedback Loop
            feedback = input("\n[ALIGNMENT] Sir, was this response satisfactory? (y/n/skip): ").lower().strip()
            if feedback == 'y':
                processor.log_preference(True)
                print("[+] Preference Archived.")
            elif feedback == 'n':
                processor.log_preference(False)
                print("[-] Critique Recorded. Recalibrating...")

        except KeyboardInterrupt:
            print("\nAcknowledged. Use 'exit' to safe-close.")
        except Exception as e:
            print(f"\n[!] ERROR IN COGNITIVE RETRIEVAL: {e}")

if __name__ == "__main__":
    main()
