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

def run_log_reflector():
    """
    KALI LOG REFLECTION
    Audits the system logs to identify performance bottlenecks or neural gaps.
    """
    logging.basicConfig(level=logging.INFO)
    logger = logging.getLogger("REFLECTOR")
    processor = DoubtProcessor()
    
    log_path = os.path.join(project_root, "logs", "kali_system.log")
    if not os.path.exists(log_path):
        logger.warning("No system log found for reflection.")
        return
        
    logger.info("🕵️ KALI Log Reflection: Auditing recent system telemetry...")
    
    # Read last 50 lines of logs
    with open(log_path, "r", encoding="utf-8") as f:
        lines = f.readlines()[-50:]
        log_snippet = "".join(lines)
        
    # Ask KALI to diagnose
    prompt = f"Analyze these system logs for technical debt, bottlenecks, or errors:\n\n{log_snippet}"
    diagnosis = processor.ai_service.ask_question(
        f"You are the KALI ANALYST. Perform a technical audit of these logs.\n"
        f"LOGS:\n{log_snippet}\n\n"
        f"IDENTIFY: One specific optimization or fix required."
    )
    
    # Log to training data (Self-Diagnosis)
    processor.training_logger.log("Internal System Audit", diagnosis)
    logger.info(f"[+] Diagnosis Anchored: {diagnosis[:100]}...")

if __name__ == "__main__":
    run_log_reflector()
