#!/usr/bin/env python3
"""
KALI PROACTIVE DEBUGGING CHANNEL (Phase 4.40)
Role: The Refactorer
Focus: Identifying technical debt and suggesting proactive refactors across the project.
"""

import os
import sys
import logging
import random

project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
sys.path.insert(0, project_root)
sys.path.insert(0, os.path.join(project_root, 'src'))

from src.core.processor import DoubtProcessor

def run_proactive_debugging_channel():
    logging.basicConfig(level=logging.INFO)
    logger = logging.getLogger("REFACTOR")
    
    # Select a target component
    components = [
        "src/core/processor.py",
        "src/core/knowledge_check.py",
        "src/core/ai_service.py",
        "scripts/ralph_loop.py"
    ]
    
    target_file = random.choice(components)
    full_path = os.path.join(project_root, target_file)
    
    content = ""
    if os.path.exists(full_path):
        with open(full_path, "r", encoding="utf-8") as f:
            content = f.read()

    logger.info(f"[*] INITIATING PROACTIVE REFACTOR AUDIT: {target_file}...")
    
    processor = DoubtProcessor()
    
    # Ask KALI to perform a deep structural audit
    res = processor.process_doubt(
        f"PROACTIVE DEBUGGING MISSION: Audit {target_file} for technical debt, redundant logic, and performance bottlenecks.\n"
        f"CONTENT:\n{content[:2000]}\n\n"
        f"Provide a 'Refactor Manifest' that hardens this module for 'Singularity State' operation."
    )
    
    logger.info(f"[+] REFACTOR MANIFEST ANCHORED.")

if __name__ == "__main__":
    run_proactive_debugging_channel()
