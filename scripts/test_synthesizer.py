#!/usr/bin/env python3
import time
import logging
import os
import sys

# Add project root and src to path
project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
sys.path.insert(0, project_root)
sys.path.insert(0, os.path.join(project_root, 'src'))

from src.core.processor import DoubtProcessor

def run_test_synthesizer():
    """
    KALI TEST SYNTHESIZER (Vector 19)
    Generates new system tests for core modules to probe edge cases.
    """
    logging.basicConfig(level=logging.INFO)
    logger = logging.getLogger("TEST_SYNTH")
    processor = DoubtProcessor()
    
    logger.info("🧪 KALI Test Synthesizer: Generating adversarial edge-case probes...")
    
    # 1. Select a functional file
    func_files = ["src/core/secure_boot.py", "src/core/planner.py"]
    target = os.path.join(project_root, random.choice(func_files))
    
    with open(target, "r", encoding="utf-8") as f:
        code = f.read()
        
    # 2. Generate Adversarial Test
    testing_logic = processor.ai_service.ask_question(
        f"Write a Python 'pytest' for this file that targets one extreme edge case or logical boundary.\n"
        f"FILE: {os.path.basename(target)}\n\nCODE:\n{code[:2000]}"
    )
    
    # 3. Log as interaction (We don't necessarily apply it immediately)
    processor.training_logger.log(f"Test Logic Synthesis: {os.path.basename(target)}", testing_logic)
    logger.info(f"[+] Test Synthesis Interaction Anchored.")

if __name__ == "__main__":
    import random
    run_test_synthesizer()
