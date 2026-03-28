import os
import sys
import logging

# Phase 4.14+: KALI Colab Native Terminal
# Allows direct interaction with KALI without the web HUD.

# 1. Path Stability
project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
if project_root not in sys.path:
    sys.path.insert(0, project_root)

try:
    from src.core.processor import DoubtProcessor
except ImportError:
    from core.processor import DoubtProcessor

def run_terminal():
    # Initialize Core
    print("\n" + "="*50)
    print("KALI SOVEREIGN TERMINAL v1.0 (COLAB_NATIVE)")
    print("="*50)
    print("Initializing Neural Layers...")
    
    # Disable console logging for a clean UI
    logging.getLogger().setLevel(logging.ERROR)
    
    processor = DoubtProcessor()
    
    print("\n[+] KALI IS ONLINE. ASCENSION COMPLETE.")
    print("[!] For Standard Chat: Just type your query.")
    print("[!] For Sovereign Missions: Start with '/core' (e.g. /core Mission: Fix UI)")
    print("[!] To Exit: Type 'EXIT'\n")

    while True:
        try:
            user_input = input("COMMANDER@KALI> ").strip()
            
            if user_input.upper() == "EXIT":
                print("Terminating Sovereignty Session. Goodbye, Sir.")
                break
            
            if not user_input:
                continue

            if user_input.lower().startswith("/core"):
                # Route to Sovereign Intelligence
                mission = user_input[5:].strip()
                print(f"[!] INITIATING SOVEREIGN MISSION: {mission}...")
                result = processor.sovereign_intel.process_command(mission)
                
                if result.get("success"):
                    print(f"\n[>>>] MISSION_SUCCESS: {result.get('message', 'Evolution Applied.')}")
                else:
                    print(f"\n[XXX] MISSION_FAILED: {result.get('error', 'Operation Aborted.')}")
            
            else:
                # Route to Standard Doubt Solver
                print("[*] KALI is thinking...")
                result = processor.process_doubt(user_input)
                
                if isinstance(result, dict):
                    print(f"\nKALI> {result.get('text', 'No response.')}")
                else:
                    print(f"\nKALI> {str(result)}")
            
            print("-" * 30)

        except KeyboardInterrupt:
            print("\nSession Interrupted. Standing by.")
            break
        except Exception as e:
            print(f"\n[!] CORE_ERROR: {e}")

if __name__ == "__main__":
    run_terminal()
