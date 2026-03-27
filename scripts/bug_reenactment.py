#!/usr/bin/env python3
import time
import logging
import os
import sys
import random

# Add project root and src to path
project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
sys.path.insert(0, project_root)
sys.path.insert(0, os.path.join(project_root, 'src'))

from src.core.processor import DoubtProcessor

def run_bug_reenactment():
    """
    KALI BUG RE-ENACTMENT (Vector 18)
    Parses logs to recreate 'Shadow Scenarios' of past errors for training.
    """
    logging.basicConfig(level=logging.INFO)
    logger = logging.getLogger("BUG_REALIVE")
    processor = DoubtProcessor()
    
    logger.info("🛠️  KALI Bug Re-enactment: Replaying past failures to build neural calluses...")
    
    # 1. Identify a past 'ERROR' from logs
    log_path = os.path.join(project_root, "logs", "kali_system.log")
    if not os.path.exists(log_path): return
    
    with open(log_path, "r", encoding="utf-8") as f:
        errors = [line for line in f.readlines() if "ERROR" in line]
        
    if not errors: return
    error_sample = random.choice(errors[-20:]) # Last 20 errors
    
    # 2. Analyze and Learn
    analysis = processor.ai_service.ask_question(
        f"You are the KALI FORENSICS NODE. Analyze this error log and explain why it occurred and how the system healed itself.\n"
        f"ERROR: {error_sample}"
    )
    
    # 3. Log as high-fidelity interaction
    processor.training_logger.log("Historical Bug Forensics", analysis)
    logger.info(f"[+] Bug Re-enactment Interaction Anchored.")

if __name__ == "__main__":
    run_bug_reenactment()
