#!/usr/bin/env python3
import os
import sys
import time
import json
import logging

# Add src to path
project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
sys.path.insert(0, os.path.join(project_root, 'src'))

from core.processor import DoubtProcessor

def monitor_kali():
    processor = DoubtProcessor()
    
    print("\n" + "="*70)
    print(" KALI SOVEREIGN MONITOR CONSOLE ")
    print("="*70)
    
    try:
        status = processor.get_system_status()
        
        # 1. Core Health
        print(f"\n[CORE] Consciousness : {status.get('consciousness', 0)*100:.1f}%")
        print(f"[CORE] Power Mode     : {status.get('power_mode', 'UNKNOWN')}")
        print(f"[CORE] Sovereignty   : {status.get('sovereign_msg', 'UNVERIFIED')}")
        
        # 2. Swarm Status
        print(f"\n[SWARM] Node Status  : {status.get('swarm_status', 'OFFLINE')}")
        
        # 3. Wealth/Earning Status
        print(f"\n[WEALTH] Mission Mode : ACTIVE (Bug Hunter + Economist)")
        print(f"[WEALTH] Alignment    : {status.get('alignment_status', '0')}%")
        
        # 4. Neural Tension
        tension = status.get('tension', 0)
        tension_bar = "#" * int(tension * 10) + "-" * (10 - int(tension * 10))
        print(f"\n[NEURAL] User Tension : [{tension_bar}] {tension*100:.1f}%")
        
        # 5. Active Predictions
        preds = status.get('next_predictions', [])
        if preds:
            print("\n[INTENT] Next Predicted Steps:")
            for p in preds[:3]:
                print(f"  - {p}")

    except Exception as e:
        print(f"\n[ERROR] Monitoring link unstable: {e}")

    print("\n" + "="*70)
    print(" MONITORING ACTIVE - SYSTEM AUTONOMOUS ")
    print("="*70 + "\n")

if __name__ == "__main__":
    monitor_kali()
