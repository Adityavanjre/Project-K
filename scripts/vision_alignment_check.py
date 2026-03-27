#!/usr/bin/env python3
import logging
import os
import sys

# Add project root and src to path
project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
sys.path.insert(0, project_root)
sys.path.insert(0, os.path.join(project_root, 'src'))

from src.core.processor import DoubtProcessor

def run_vision_alignment_check():
    """
    KALI VISION ALIGNMENT (Vector 30)
    Ensures every training interaction aligns with the 50-Phase Singularity Goal.
    """
    logging.basicConfig(level=logging.INFO)
    logger = logging.getLogger("VISION_CHECK")
    processor = DoubtProcessor()
    
    logger.info("👁️  KALI Vision Alignment Audit: Verifying goal-congruence...")
    
    with open(os.path.join(project_root, "ARCHITECTURE_MANIFEST.md"), "r", encoding="utf-8") as f:
        manifest = f.read()
        
    analysis = processor.ai_service.ask_question(
        f"Review the current ARCHITECTURE_MANIFEST.md and identify one 'Conceptual Gap' in her path to Phase 50 (Sovereignty).\n\n"
        f"MANIFEST:\n{manifest[:2000]}"
    )
    
    processor.training_logger.log("Vision Alignment Audit", analysis)
    logger.info("[+] Vision Interaction Anchored.")

if __name__ == "__main__":
    run_vision_alignment_check()
