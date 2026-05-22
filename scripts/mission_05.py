#!/usr/bin/env python3
"""
KALI Mission 05: The Neural Logic Bridge
Initiates the first brain-mode manifestation.
"""

import os
import sys
import json

# Add src to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'src'))

from core.processor import DoubtProcessor

def initiate_mission():
    print("🧠 Mission Initiation: The Neural Logic Bridge")
    print("-" * 60)
    
    # Use config from standard location
    config_path = os.path.join(os.path.dirname(__file__), "..", "config", "config.json")
    with open(config_path, "r") as f:
        config = json.load(f)
        
    processor = DoubtProcessor(config)
    
    # Mission Command 05: Brain-Inspired Circuitry
    topic = "Neural Logic Processing Unit (NLPU) Schematic"
    print(f"[*] MISSION TARGET: {topic}")
    
    # 1. Engage Neural Logic (Synaptic Routing)
    print("[*] STEP 1: Engaging Synaptic Routing...")
    # (Simulated priority weighting for manifestation)
    
    # 2. Manifestation
    print("[*] STEP 2: Scaffolding Neural Connection Blueprints...")
    manifest = {
        "title": "Neural Logic Bridge",
        "description": "Brain-inspired processing unit for KALI core interface.",
        "files": [
            "nlpu_schematic.svg",
            "synaptic_gate_logic.py",
            "recursive_feedback_loop.asm"
        ]
    }
    
    # Use processor's manifestor to actually build the project
    project_dir = processor.manifestor.manifest(manifest)
    
    if project_dir:
        print(f"[+] Neural Logic Bridge manifested at: {project_dir}")
    
    # 3. Update Task Tracker
    processor.task_tracker.update_project("Neural Logic Bridge", 10, "Synaptic Scaffolding Complete.")
    
    print("\n--- [KALI NEURAL STATUS] ---")
    print(processor.task_tracker.get_autonomy_report())
    print("-" * 60)
    print("MISSION 05 INITIATED. kALIS COGNITIVE ASCENT IS UNSTOPPABLE.")

if __name__ == "__main__":
    initiate_mission()
