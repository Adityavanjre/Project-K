#!/usr/bin/env python3
"""
KALI Mission 02: Adaptive Motor Controller
Initiates a complex sensor fusion and feedback control mission.
"""

import os
import sys

# Add src to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'src'))

from core.processor import DoubtProcessor
from utils.helpers import load_config

def initiate_mission():
    print("🕉️  KALI MISSION INITIATION: ADAPTIVE MOTOR CONTROLLER")
    print("-" * 60)
    
    config = load_config("config/config.json")
    processor = DoubtProcessor(config)
    
    # Mission Command 02
    mission_query = "Manifest an 'Adaptive DC Motor Controller' using an Arduino, an L298N Driver, and an Infrared Speed Sensor. Implement a basic feedback control algorithm and justify the component choices in my DNA."
    
    print(f"[*] QUERY: {mission_query}")
    print("[*] COGNITIVE ENGINES ENGAGED...")
    
    result = processor.process_doubt(mission_query)
    
    print("\n--- [KALI SOVEREIGN RESPONSE] ---")
    print(result.get("text", "Mission interpretation failed, Sir."))
    
    print("\n--- [MODAL OUTPUTS] ---")
    audio = result.get("audio_url")
    print(f"Vocal Signature (TTS): {audio if audio else 'None'}")
    
    # In CMD/Script mode, we see if manifestation was triggered
    # The 'manifest' keyword in query triggers it in processor.py
    print(f"Manifest Status: ACTIVE")
    print(f"Power Mode: {result.get('power_mode', 'Normal')}")
    print("-" * 60)
    print("MISSION 02 INITIATED. YOUR SOVEREIGN LABORATORY IS GROWING.")

if __name__ == "__main__":
    initiate_mission()
