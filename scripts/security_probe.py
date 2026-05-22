#!/usr/bin/env python3
import time
import logging
import os
import sys
import json

# Add project root and src to path
project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
sys.path.insert(0, project_root)
sys.path.insert(0, os.path.join(project_root, 'src'))

from src.core.processor import DoubtProcessor

def run_adversarial_security_probe():
    """
    KALI ADVERSARIAL SECURITY PROBE (Vector 14)
    One node identifies vulnerabilities; another learns the defensive logic.
    """
    logging.basicConfig(level=logging.INFO)
    logger = logging.getLogger("PROB_SECURITY")
    processor = DoubtProcessor()
    
    logger.info("🛡️  KALI Adversarial Security Probe: Searching for neural vulnerabilities...")
    
    # 1. Identify a vulnerability in the current codebase
    files = []
    for root, _, fs in os.walk(os.path.join(project_root, "src")):
        for f in fs:
            if f.endswith(".py"):
                files.append(os.path.join(root, f))
    
    target = random.choice(files)
    with open(target, "r", encoding="utf-8") as f:
        code = f.read()
        
    audit = processor.ai_service.ask_question(
        f"You are the KALI OFFENSIVE NODE. Identify one potential security flaw or logical loophole in this code:\n"
        f"FILE: {os.path.basename(target)}\n\nCODE:\n{code}"
    )
    
    defense = processor.ai_service.ask_question(
        f"You are the KALI DEFENSIVE ARCHITECT. How do we structure a sovereign patch for this vulnerability?\n"
        f"FLAW: {audit}"
    )
    
    # Log to training data (Adversarial Learning)
    processor.training_logger.log(f"Security Audit: {os.path.basename(target)}", f"FLAW: {audit}\nDEFENSE: {defense}")
    logger.info(f"[+] Security Interaction Anchored for {os.path.basename(target)}.")

if __name__ == "__main__":
    import random
    run_adversarial_security_probe()
