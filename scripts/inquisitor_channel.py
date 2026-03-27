#!/usr/bin/env python3
"""
KALI INQUISITOR CHANNEL (Phase 4.40)
Role: The Inquisitor
Focus: Analyzing anchored knowledge for rot, edge cases, and contradictions.
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

def run_inquisitor_channel():
    logging.basicConfig(level=logging.INFO)
    logger = logging.getLogger("INQUISITOR")
    
    # Read anchored training data
    anchored_path = os.path.join(project_root, "data", "training_data.jsonl")
    if not os.path.exists(anchored_path):
        logger.info("No anchored knowledge to interrogate. Skipping.")
        return

    with open(anchored_path, "r", encoding="utf-8") as f:
        lines = f.readlines()
        if not lines: return
        # Pick a random "perfect" memory to challenge
        memory = json.loads(random.choice(lines))
    
    msgs = memory.get("messages", [])
    topic = next((m["content"] for m in msgs if m["role"] == "user"), "")
    answer = next((m["content"] for m in msgs if m["role"] == "assistant"), "")

    logger.info(f"[*] INQUISITOR: Challenging Anchored Memory: '{topic[:60]}'")
    
    processor = DoubtProcessor()
    
    # The Inquisitor tries to break the previously successful training
    res = processor.process_doubt(
        f"INQUISITOR PROTOCOL: You are the devil's advocate. Challenge your own previous answer.\n"
        f"ORIGINAL TOPIC: {topic}\n"
        f"YOUR ANSWER: {answer[:600]}\n\n"
        f"Identify 3 edge cases where this answer fails or becomes inaccurate. "
        f"Then provide a 'Stress-Hardened' synthesis that covers these gaps."
    )
    
    logger.info(f"[+] MEMORY HARDENED AGAINST INQUISITION.")

if __name__ == "__main__":
    run_inquisitor_channel()
