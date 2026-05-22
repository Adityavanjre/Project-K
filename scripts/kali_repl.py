#!/usr/bin/env python3
import os
import sys
import logging

# Add project root and src to path
project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
sys.path.insert(0, os.path.join(project_root, 'src'))

from core.processor import DoubtProcessor

def start_repl():
    # Suppress non-critical logs
    logging.getLogger().setLevel(logging.ERROR)
    
    print("\n" + "="*70)
    print(" KALI SOVEREIGN REPL v1.0 ")
    print(" TYPE 'EXIT' TO DISCONNECT ")
    print("="*70)
    
    processor = DoubtProcessor()
    
    while True:
        try:
            query = input("\n[COMMANDER]> ").strip()
            if query.upper() == "EXIT":
                break
            if not query:
                continue
                
            print(f"\n[*] KALI: Processing...")
            res = processor.process_doubt(query)
            
            print("\n--- [KALI SOVEREIGN RESPONSE] ---")
            if isinstance(res, dict):
                print(res.get("text", str(res)))
            else:
                print(res)
            print("---------------------------------")
            
        except KeyboardInterrupt:
            break
        except Exception as e:
            print(f"\n[ERROR] Neural link disrupted: {e}")

    print("\n[!] KALI DISCONNECTED.")

if __name__ == "__main__":
    start_repl()
