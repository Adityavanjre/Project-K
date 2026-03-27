#!/usr/bin/env python3
"""
KALI Mission 01: The Gateway Initiation
Initiates the first multi-modal engineering mission.
"""

import os
import sys
import json

# Add src to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'src'))

from core.processor import DoubtProcessor
from utils.helpers import load_config

def initiate_mission():
    print("🕉️  KALI MISSION INITIATION: SMART LOGIC GATEWAY")
    print("-" * 60)
    
    config = load_config("config/config.json")
    processor = DoubtProcessor(config)
    
    # The First Mission Command
    mission_query = "Manifest a 'Smart Logic Gateway' using a 74LS series IC and an Arduino. Explain the truth table and record it in my DNA."
    
    print(f"[*] QUERY: {mission_query}")
    print("[*] COGNITIVE ENGINES ENGAGED...")
    
    # We use process_doubt for general interaction or project_mentor for specific manifests
    # query contains 'manifest', so processor.py will trigger manifestation
    result = processor.process_doubt(mission_query)
    
    print("\n--- [KALI SOVEREIGN RESPONSE] ---")
    print(result.get("text", "Mission interpretation failed, Sir."))
    
    print("\n--- [MODAL OUTPUTS] ---")
    print(f"Vocal Signature (TTS): {result.get('audio_url', 'None')}")
    print(f"Manifest Status: ACTIVE")
    print(f"Power Mode: {result.get('power_mode', 'Normal')}")
    print("-" * 60)
    print("MISSION 01 INITIATED. CHECK YOUR DISK FOR THE MANIFEST.")

if __name__ == "__main__":
    initiate_mission()
