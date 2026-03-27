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

def run_adversarial_opt():
    """
    KALI ADVERSARIAL OPTIMIZATION (Vector 21)
    Two logic nodes compete to find the most efficient implementation for a core function.
    """
    logging.basicConfig(level=logging.INFO)
    logger = logging.getLogger("ADV_OPT")
    processor = DoubtProcessor()
    
    logger.info("⚡ KALI Adversarial Optimization: Benchmarking neural logic...")
    
    goal = "Optimize Vector Memory Recall latency for 1M+ records."
    
    # Node 1: Original
    p1 = processor.ai_service.ask_question(f"PROPOSE: {goal}")
    
    # Node 2: Adversary
    p2 = processor.ai_service.ask_question(f"OPTIMIZE PERF: {p1}")
    
    # Log to training data
    processor.training_logger.log(f"Optimization Debate: {goal}", f"V1: {p1}\nV2 (Optimized): {p2}")
    logger.info("[+] Optimization Interaction Anchored.")

if __name__ == "__main__":
    run_adversarial_opt()
