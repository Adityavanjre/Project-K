#!/usr/bin/env python3
"""
KALI SOCRATIC CHANNEL (Phase 4.40)
Role: The Socratic Student/Teacher
Focus: Dialectical reasoning, cross-model critique, and deep 'Why?' logic.
"""

import os
import sys
import logging
import random

project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
sys.path.insert(0, project_root)
sys.path.insert(0, os.path.join(project_root, 'src'))

from src.core.processor import DoubtProcessor

def run_socratic_channel():
    logging.basicConfig(level=logging.INFO)
    logger = logging.getLogger("SOCRATIC")
    
    topics = [
        "Why is Pulsed Width Modulation (PWM) more efficient than linear voltage regulation for motor control?",
        "Why does a Kalman Filter require a Gaussian distribution assumption for the noise model?",
        "Why is 4-bit quantization effective for large language models. What is actually lost?",
        "Why should KALI prioritize local model execution over API-based models for long-term sovereignty?",
        "Why is recursive self-optimization potentially dangerous without external data anchors?"
    ]
    
    target = random.choice(topics)
    logger.info(f"[*] INITIATING SOCRATIC DIALOGUE: {target[:60]}...")
    
    processor = DoubtProcessor()
    
    # Initiate a Council-based debate where one model keeps asking "Why?"
    res = processor.process_doubt(
        f"SOCRATIC MISSION: {target}. \n"
        f"Conduct a 3-step dialectical refinement. Explain, then identify a flaw, then provide a deeper synthesis."
    )
    
    logger.info(f"[+] SOCRATIC WISDOM ANCHORED.")

if __name__ == "__main__":
    run_socratic_channel()
