#!/usr/bin/env python3
import logging
import os
import sys

# Add project root and src to path
project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
sys.path.insert(0, project_root)
sys.path.insert(0, os.path.join(project_root, 'src'))

from src.core.biometric_service import BiometricService
from src.core.processor import DoubtProcessor

def run_psychological_calibration():
    """
    KALI PSYCHOLOGICAL CALIBRATION (Vectors 101-110)
    Trains the 'Teacher' and 'Mentor' to adjust based on user tension.
    """
    logging.basicConfig(level=logging.INFO)
    logger = logging.getLogger("PSYCH_CALIB")
    biometric = BiometricService()
    processor = DoubtProcessor()
    
    # Simulate high tension
    biometric.interaction_count = 50
    state = biometric.get_physiological_state(system_load=80.0)
    
    logger.info(f"🧘 KALI Psych Calibration: Adjusting tone for Tension {state['neural_tension']}...")
    
    analysis = processor.ai_service.ask_question(
        f"USER STATE: Neural Tension is {state['neural_tension']}. Tone required: {state['status']}.\n"
        f"TASK: Provide a technical explanation of 'Recursive Pointers' in a way that minimizes cognitive load."
    )
    
    processor.training_logger.log("Psychological Alignment Training", analysis)
    logger.info("[+] interaction Anchored.")

if __name__ == "__main__":
    run_psychological_calibration()
