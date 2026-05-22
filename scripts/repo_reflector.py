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

def run_repo_reflection():
    """
    KALI REPO REFLECTION (Vector 12)
    Scans the repository structure to understand the project architecture.
    """
    logging.basicConfig(level=logging.INFO)
    logger = logging.getLogger("REPO_REFLECT")
    processor = DoubtProcessor()
    
    logger.info("📂  KALI Repo Reflection: Auditing project topology...")
    
    structure = []
    for root, dirs, files in os.walk(project_root):
        if ".git" in root or "__pycache__" in root or "venv" in root: continue
        rel_path = os.path.relpath(root, project_root)
        structure.append(f"DIR: {rel_path} ({len(files)} files)")
        
    structure_str = "\n".join(structure[:30]) # Limit to top 30 dirs
    
    reflection = processor.ai_service.ask_question(
        f"You are the KALI ARCHITECT. Analyze this repository structure and identify the core technical relationship between 'src/core' and 'scripts/'.\n"
        f"STRUCTURE:\n{structure_str}"
    )
    
    # Log to training data
    processor.training_logger.log("Architectural Reflection", reflection)
    logger.info("[+] Repo Reflection Interaction Anchored.")

if __name__ == "__main__":
    run_repo_reflection()
