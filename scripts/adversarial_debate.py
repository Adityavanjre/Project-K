#!/usr/bin/env python3
import time
import logging
import json
import os
import sys

# Add project root and src to path
project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
sys.path.insert(0, project_root)
sys.path.insert(0, os.path.join(project_root, 'src'))

from src.core.processor import DoubtProcessor

def run_adversarial_debate():
    """
    KALI ADVERSARIAL DEBATE
    Two instances of KALI debate a technical implementation to generate high-fidelity DPO pairs.
    """
    logging.basicConfig(level=logging.INFO)
    logger = logging.getLogger("DEBATE")
    processor = DoubtProcessor()
    
    # Topic Selection
    topics = ["Sovereign Network Protocols", "Hardware-Locked Cryptography", "Quantum-Safe Neural Logic"]
    topic = random.choice(topics)
    
    logger.info(f"⚔️  KALI Adversarial Debate: '{topic}'")
    
    # Instance 1: The 'Architect' (Implementation)
    answer_a = processor.ai_service.ask_question(f"You are the KALI Architect. Propose a perfect implementation for: {topic}")
    
    # Instance 2: The 'Critic' (Deconstruction)
    critique = processor.ai_service.ask_question(f"You are the KALI Critic. Identify 3 critical technical flaws in this implementation: {answer_a}")
    
    # Instance 1: The 'Refiner' (Defense & Evolution)
    answer_b = processor.ai_service.ask_question(
        f"As the KALI Architect, resolve this critique and produce the ULTIMATE version: {critique}\n"
        f"Original: {answer_a}"
    )
    
    # Log as DPO Pair
    dpo_path = os.path.join("data", "dpo_data.jsonl")
    dpo_entry = {
        "prompt": topic,
        "chosen": answer_b,
        "rejected": answer_a,
        "metadata": {"source": "adversarial_debate"}
    }
    with open(dpo_path, "a", encoding="utf-8") as f:
        f.write(json.dumps(dpo_entry) + "\n")
        
    logger.info(f"[+] Debate Anchored. Sovereign DPO sample recorded.")

if __name__ == "__main__":
    import random
    run_adversarial_debate()
