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

def run_curiosity_discovery():
    """
    KALI NEURAL CURIOSITY ENGINE
    Identifies 'Conceptual Gaps' in her own training and generates new vectors.
    """
    logging.basicConfig(level=logging.INFO)
    logger = logging.getLogger("CURIOSITY")
    processor = DoubtProcessor()
    
    logger.info("🧠 KALI Neural Curiosity: Scanning training delta for expansion...")
    
    # 1. Read manifest to see what we have
    with open(os.path.join(project_root, "ARCHITECTURE_MANIFEST.md"), "r", encoding="utf-8") as f:
        manifest = f.read()
        
    # 2. Ask KALI to identify a missing vector
    discovery = processor.ai_service.ask_question(
        f"You have 110 training vectors currently. Based on the ARCHITECTURE_MANIFEST, identify ONE 'Missing Core Skill' required for absolute sovereignty.\n"
        f"Return as: 'Vector 111: [NAME] - [DESCRIPTION]'"
    )
    
    logger.info(f"[!] New Vector Discovered: {discovery}")
    
    # 3. Log to training data (This *is* the training for being curious)
    processor.training_logger.log("Curiosity Discovery Event", discovery)
    logger.info("[+] interaction Anchored.")

if __name__ == "__main__":
    run_curiosity_discovery()
