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

def run_pattern_emulation():
    """
    KALI PATTERN EMULATION (Vector 17)
    Learns the 'KALI' coding style from existing source files.
    """
    logging.basicConfig(level=logging.INFO)
    logger = logging.getLogger("PATTERN")
    processor = DoubtProcessor()
    
    logger.info("🎨 KALI Pattern Emulation: Learning the KALI coding aesthetic...")
    
    # 1. Select a high-quality core file
    core_files = ["src/core/processor.py", "src/core/ai_service.py", "src/core/user_dna.py"]
    target = os.path.join(project_root, random.choice(core_files))
    
    with open(target, "r", encoding="utf-8") as f:
        code = f.read()
        
    # 2. Identify Patterns
    analysis = processor.ai_service.ask_question(
        f"Analyze the coding style, naming conventions, and documentation patterns of this file.\n"
        f"FILE: {os.path.basename(target)}\n\nCODE:\n{code[:2000]}\n\n"
        f"TASK: Generate a 'KALI Coding Standard' guide based on this sample."
    )
    
    # 3. Log to training data
    processor.training_logger.log("Coding Pattern Analysis", analysis)
    logger.info(f"[+] Style Pattern Anchored from {os.path.basename(target)}.")

if __name__ == "__main__":
    run_pattern_emulation()
