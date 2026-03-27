#!/usr/bin/env python3
"""
KALI AUTOPILOT COMMANDER (Phase 4.60)
Role: The Sovereign Architect
Focus: Proactively scanning roadmap gaps and launching training missions without user input.
Toward 1,000 Verified Interactions.
"""

import os
import sys
import logging
import json
import time

project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
sys.path.insert(0, project_root)
sys.path.insert(0, os.path.join(project_root, 'src'))

from src.core.processor import DoubtProcessor
from scripts.ralph_loop import run_ralph_loop

def run_autopilot_commander(cycles: int = 5):
    logging.basicConfig(level=logging.INFO)
    logger = logging.getLogger("COMMANDER")
    
    logger.info(f"[!] KALI: Autopilot Commander Initializing (Target: 1,000 Interactions)...")
    
    processor = DoubtProcessor()
    roadmap_path = os.path.join(project_root, "KALI_MASTER_PLAN.md")
    
    for cycle in range(cycles):
        logger.info(f"\n--- [AUTOPILOT CYCLE {cycle+1}/{cycles}] ---")
        
        # 1. Gap Identification (Roadmap & DNA)
        with open(roadmap_path, "r", encoding="utf-8") as f:
            roadmap = f.read()
            
        analysis_prompt = (
            f"Compare this ROADMAP with KALI's current training logs. "
            f"Identify the #1 most critical TECHNICAL GAP that needs to be trained next to reach the Singularity. "
            f"Return ONLY a JSON object: {{'gap': 'topic', 'reason': 'why', 'mission_goal': 'detailed goal for Ralph Loop'}}."
            f"\n\nROADMAP:\n{roadmap[:1000]}"
        )
        
        try:
            gap_data = processor.ai_service.ask_json("KALI Autopilot Analysis", analysis_prompt)
            if not gap_data: continue
            
            gap_topic = gap_data["gap"]
            mission_goal = gap_data["mission_goal"]
            
            logger.info(f"[+] STRATEGIC GAP IDENTIFIED: {gap_topic}")
            logger.info(f"[*] REASON: {gap_data['reason']}")
            logger.info(f"[>] LAUNCHING MISSION: {mission_goal[:80]}...")
            
            # 2. Execute Ralph Loop iteration with the strategic goal
            run_ralph_loop(mission_goal, iterations=2)
            
            logger.info(f"[+] CYCLE {cycle+1} COMPLETE. Knowledge anchored.")
            
        except Exception as e:
            logger.error(f"Autopilot Cycle {cycle} failed: {e}")
            
    logger.info("[!] KALI: Autopilot session concluded. Re-tuning Neural HUD...")

if __name__ == "__main__":
    run_autopilot_commander()
