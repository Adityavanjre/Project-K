#!/usr/bin/env python3
import logging
import os
import sys

# Add project root and src to path
project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
sys.path.insert(0, project_root)
sys.path.insert(0, os.path.join(project_root, 'src'))

from src.core.processor import DoubtProcessor

def run_instruction_calibration():
    """
    KALI INSTRUCTION CALIBRATION (Vector 15)
    Analyzes user interaction history to fine-tune alignment and tone.
    """
    logging.basicConfig(level=logging.INFO)
    logger = logging.getLogger("CALIBRATOR")
    processor = DoubtProcessor()
    
    logger.info("🎯  KALI Instruction Calibration: Fine-tuning neural alignment...")
    
    # Analyze the last few user DNA samples
    dna = processor.user_dna.profile
    tone_analysis = processor.ai_service.ask_question(
        f"Analyze this user personality profile for alignment weightings:\n"
        f"PROFILE: {dna}\n\n"
        f"TASK: Generate one specific instruction-following guideline to improve KALI's helpfulness to this user."
    )
    
    # Log to training data
    processor.training_logger.log("Alignment Calibration", tone_analysis)
    logger.info("[+] Instruction Calibration Anchored.")

if __name__ == "__main__":
    run_instruction_calibration()
