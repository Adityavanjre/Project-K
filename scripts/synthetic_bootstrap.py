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

def run_synthetic_bootstrap():
    """
    KALI SYNTHETIC BOOTSTRAPPING (Vector 26)
    Generates high-fidelity training data from her own vector memory knowledge.
    """
    logging.basicConfig(level=logging.INFO)
    logger = logging.getLogger("BOOTSTRAP")
    processor = DoubtProcessor()
    
    logger.info("⚡ KALI Synthetic Bootstrapping: Recursive knowledge generation active...")
    
    # 1. Fetch random knowledge
    mems = processor.vector_memory.recall("advanced", n=5)
    if not mems: return
    
    seed = " ".join(mems)
    
    # 2. Generate new interactions
    synthetic = processor.ai_service.ask_question(
        f"Generate 5 high-fidelity technical Q&A pairs based on this knowledge seed:\n{seed[:2000]}\n"
        f"Format as JSON list of objects with 'goal' and 'answer'."
    )
    
    try:
        pairs = processor.ai_service._extract_json(synthetic)
        for p in pairs:
            processor.training_logger.log(p["goal"], p["answer"])
        logger.info(f"[+] Bootstrapped {len(pairs)} interactions into Digital Soul.")
    except:
        processor.training_logger.log("Synthetic Bulk Sync", synthetic)
        logger.info("[+] Bulk Interaction Anchored.")

if __name__ == "__main__":
    run_synthetic_bootstrap()
