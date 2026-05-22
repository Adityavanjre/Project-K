#!/usr/bin/env python3
"""
KALI Mission 07: Sovereign Bug Bounty Hunter
Initiates an autonomous bug-hunting mission across the integrated swarm.
Leverages Decepticon, Hackingtool, and GitNexus for zero-omission analysis.
"""

import os
import sys
import json
import logging

# Add src to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'src'))

from core.processor import DoubtProcessor
from utils.helpers import load_config

def initiate_bughunter_mission():
    logging.basicConfig(level=logging.INFO)
    logger = logging.getLogger("BUG_HUNTER")
    
    print("[*] KALI MISSION INITIATION: SOVEREIGN BUG BOUNTY HUNTER")
    print("-" * 60)
    
    config = load_config("config/config.json")
    processor = DoubtProcessor(config)
    
    wallet = config.get("wealth", {}).get("creator_wallet", "NOT_SET")
    
    # The Bug Hunter Mission Command
    mission_query = (
        "ACTIVATE ROLE: TACTICAL BUG HUNTER. "
        "Task: Initialize a deep-slice vulnerability scan using the integrated swarm. "
        "1. Deploy Decepticon for adversarial logic and exploit simulation. "
        "2. Leverage Hackingtool for automated scanning of the network and service layers. "
        "3. Use GitNexus for symbolic code-level analysis and MRO-resolved vulnerability discovery. "
        "4. Cross-reference findings with open-source bounty registries. "
        f"5. Anchor all earnings to Creator Wallet: {wallet}. "
        "Execute an initial scan of the Project-K infrastructure for zero-day stability risks."
    )
    
    print(f"[*] QUERY: {mission_query}")
    print("[*] SWARM ENGINES ENGAGED (Decepticon + Hackingtool + GitNexus)...")
    
    # Process the doubt (mission)
    result = processor.process_doubt(mission_query)
    
    print("\n--- [KALI TACTICAL RESPONSE] ---")
    print(result.get("text", "Tactical interpretation failed, Commander."))
    
    print("\n--- [BUG HUNTER TELEMETRY] ---")
    print(f"Bounty Mode: ACTIVE")
    print(f"Target Wallet: {wallet}")
    print(f"Swarm Integration: Decepticon + Hackingtool + GitNexus")
    print("-" * 60)
    print("MISSION 07 INITIATED. STANDBY FOR VULNERABILITY REPORT.")

if __name__ == "__main__":
    initiate_bughunter_mission()
