#!/usr/bin/env python3
import logging
import os
import sys
import random

# Add project root and src to path
project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
sys.path.insert(0, project_root)
sys.path.insert(0, os.path.join(project_root, 'src'))

from src.core.processor import DoubtProcessor

def run_failure_adversary():
    """
    KALI FAILURE-MODE ADVERSARY (Vector 29)
    One node simulates a critical system failure; the other synthesizes the solution.
    """
    logging.basicConfig(level=logging.INFO)
    logger = logging.getLogger("ADVERSARY")
    processor = DoubtProcessor()
    
    logger.info("💥 KALI Failure Adversary: Simultaneous fault-injection and recovery training...")
    
    failure_scenarios = [
        "Database corruption in user_dna.db via concurrent write locking.",
        "Buffer overflow on TTS generator payload.",
        "Infinite recursion loop in Ralph mission planning."
    ]
    scenario = random.choice(failure_scenarios)
    
    solution = processor.ai_service.ask_question(
        f"You are the KALI SRE. Develop a technical solution and preventative logic for this failure scenario:\n{scenario}"
    )
    
    # Log to training data
    processor.training_logger.log(f"Failure-Mode Recovery: {scenario}", solution)
    logger.info(f"[+] Failure Analysis Interaction Anchored.")

if __name__ == "__main__":
    run_failure_adversary()
