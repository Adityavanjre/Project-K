#!/usr/bin/env python3
"""
KALI META-ROLE GENERATOR (Phase 4.50)
Role: The Visionary
Focus: Dynamically inventing and training on new expert dimensions to reach 200+ channels.
"""

import os
import sys
import logging
import random
import json

project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
sys.path.insert(0, project_root)
sys.path.insert(0, os.path.join(project_root, 'src'))

from src.core.processor import DoubtProcessor

def run_meta_role_generator(iterations: int = 10):
    logging.basicConfig(level=logging.INFO)
    logger = logging.getLogger("META_GEN")
    
    logger.info(f"[*] KALI: Initiating Meta-Role Scaling ({iterations} iterations)...")
    
    processor = DoubtProcessor()
    
    for i in range(iterations):
        # 1. Decide: Hallucinate new or reinforce Core Identity?
        # Core identities (Mentor, Teacher, Bridge) get 40% weighting
        is_core = random.random() < 0.4
        if is_core:
            identity = random.choice(["Ultimate Mentor", "Universal Teacher", "Fabrication Architect", "Council Lead"])
            role_prompt = (
                f"You are the KALI CORE. Reinforce the '{identity}' persona. "
                "Construct a mission that tests the bridge between complex engineering theory and local fabrication. "
                "Return ONLY a JSON object: {'role': 'name', 'focus': 'description', 'mission': 'a complex pedagogical task'}."
            )
        else:
            role_prompt = (
                "You are the KALI EVOLUTIONARY ENGINE. Invent a highly specialized, future-tech expert role "
                "that doesn't exist yet but will be critical for a post-singularity engineering partner. "
                "Return ONLY a JSON object: {'role': 'name', 'focus': 'description', 'mission': 'a complex technical task'}."
            )
        
        try:
            role_data = processor.ai_service.ask_json("KALI Role Invention", role_prompt)
            if not role_data or "role" not in role_data: continue
            
            role_name = role_data["role"]
            mission = role_data["mission"]
            
            # Phase 4.50: Zero-Redundancy check
            # (Note: For dynamic roles, we assume the mission is new, but we check core keywords)
            if processor.knowledge_check.is_atom_mastered(role_name):
                logger.info(f"[-] {role_name} DIMENSION ALREADY SOVEREIGN. Skipping redundant training.")
                continue

            logger.info(f"[+] DYNAMIC DIMENSION: {role_name}")
            logger.info(f"[*] Mission: {mission[:100]}...")
            
            # Process as a Doubt mission with the specific role persona
            res = processor.process_doubt(f"ACT AS ROLE: {role_name}. Focus: {role_data['focus']}. Mission: {mission}")
            
            logger.info(f"[+] {role_name} DIMENSION ANCHORED.")
            
        except Exception as e:
            logger.error(f"Meta-Role Cycle {i} failed: {e}")

if __name__ == "__main__":
    count = int(sys.argv[1]) if len(sys.argv) > 1 else 10
    run_meta_role_generator(count)
