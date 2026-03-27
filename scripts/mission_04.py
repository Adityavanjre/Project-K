#!/usr/bin/env python3
"""
KALI Mission 04: The Jarvis Protocol
Demonstrates autonomous skill generation and persistent task tracking.
"""

import os
import sys
import json

# Add src to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'src'))

from core.processor import DoubtProcessor

def initiate_mission():
    print("🤖 KALI MISSION INITIATION: THE JARVIS PROTOCOL")
    print("-" * 60)
    
    # Use config from standard location
    config_path = os.path.join(os.path.dirname(__file__), "..", "config", "config.json")
    with open(config_path, "r") as f:
        config = json.load(f)
        
    processor = DoubtProcessor(config)
    
    # 1. Autonomous Task Tracking
    print("[*] STEP 1: Updating Project Velocity...")
    processor.task_tracker.update_project("Laboratory Hardening", 85, "Phase 8: Autonomy initiated.")
    
    # 2. Autonomous Skill Generation (OpenClaw style)
    print("[*] STEP 2: Manifesting Autonomous 'Weather' Skill...")
    weather_plugin_code = """
class WeatherPlugin:
    def run(self, location="Mumbai"):
        return f"WEATHER REPORT: Simulated 27°C in {location}. Perfect for laboratory operations."

def initialize():
    return WeatherPlugin()
"""
    success = processor.plugin_manager.create_plugin_from_query("WeatherAgent", weather_plugin_code)
    
    if success:
        print("[+] Skill Manifested. Testing 'WeatherAgent' execution...")
        result = processor.plugin_manager.execute_plugin("weather_agent", location="New Delhi")
        print(f"[*] PLUGIN OUTPUT: {result}")
    
    print("\n--- [KALI JARVIS STATUS] ---")
    print(processor.task_tracker.get_autonomy_report())
    print("-" * 60)
    print("MISSION 04 COMPLETE. KALI IS NOW SELF-REFINING.")

if __name__ == "__main__":
    initiate_mission()
