#!/usr/bin/env python3
import time
import os
import sys

def tail_logs():
    # Use the mission history or standard log if available
    # For now, we tail the shadow_eval or a custom mission log
    log_path = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'data', 'mission_history.jsonl'))
    
    print("\n" + "="*70)
    print(" KALI SOVEREIGN MISSION FEED - LIVE STREAM ")
    print(" PRESS CTRL+C TO STOP MONITORING ")
    print("="*70)
    
    if not os.path.exists(log_path):
        # Create empty log if missing
        os.makedirs(os.path.dirname(log_path), exist_ok=True)
        with open(log_path, 'w') as f: pass
    
    with open(log_path, 'r') as f:
        # Go to end of file
        f.seek(0, os.SEEK_END)
        
        while True:
            line = f.readline()
            if not line:
                time.sleep(1)
                continue
            print(f"[KALI]> {line.strip()}")

if __name__ == "__main__":
    try:
        tail_logs()
    except KeyboardInterrupt:
        print("\n[!] FEED DISCONNECTED.")
