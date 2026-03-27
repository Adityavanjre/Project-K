#!/usr/bin/env python3
import logging
import os
import sys

# Add project root and src to path
project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
sys.path.insert(0, project_root)
sys.path.insert(0, os.path.join(project_root, 'src'))

from src.core.processor import DoubtProcessor

def run_hardware_sim():
    """
    KALI HARDWARE-IN-THE-LOOP SIMULATION (Vector 25)
    Imagines hardware failures and generates handling logic.
    """
    logging.basicConfig(level=logging.INFO)
    logger = logging.getLogger("HW_SIM")
    processor = DoubtProcessor()
    
    logger.info("🔌 KALI Hardware Simulation: Injecting neural faults...")
    
    failure = "I2C Bus Contention leading to sensor blackout in a drone swarm."
    
    recovery = processor.ai_service.ask_question(
        f"You are the KALI HARDWARE ENGINEER. Develop a recovery protocol for this failure mode:\n"
        f"FAILURE: {failure}"
    )
    
    # Log to training data
    processor.training_logger.log(f"Hardware Recovery Synthesis: {failure}", recovery)
    logger.info("[+] Hardware Sim Interaction Anchored.")

if __name__ == "__main__":
    run_hardware_sim()
