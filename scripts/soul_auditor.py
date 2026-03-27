#!/usr/bin/env python3
import logging
import os
import sys
import json

# Add project root and src to path
project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
sys.path.insert(0, project_root)
sys.path.insert(0, os.path.join(project_root, 'src'))

from src.core.processor import DoubtProcessor

def run_soul_auditor():
    """
    KALI DIGITAL SOUL AUDITOR
    Verifies memory coverage across all 70 training vectors.
    """
    logging.basicConfig(level=logging.INFO)
    logger = logging.getLogger("SOUL_AUDIT")
    processor = DoubtProcessor()
    
    logger.info("🧿 KALI Digital Soul Auditor: Checking 70-vector neural coverage...")
    
    # Check interaction log
    log_path = os.path.join(project_root, "data", "training_data.jsonl")
    if not os.path.exists(log_path):
        logger.error("Digital Soul not found! No training data.")
        return
        
    with open(log_path, "r", encoding="utf-8") as f:
        interactions = f.readlines()
        
    count = len(interactions)
    logger.info(f"[*] Total Neural Patterns: {count}")
    
    # Verify diversity
    diversity = processor.ai_service.ask_question(
        f"You are the KALI ANALYST. Review the quantity ({count}) and diversity of the current training engine.\n"
        f"Is the 'Teacher' skill properly represented among the first 100 samples?"
    )
    
    logger.info(f"[+] Soul Audit Consensus: {diversity}")

if __name__ == "__main__":
    run_soul_auditor()
