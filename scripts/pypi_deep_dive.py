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

def run_pypi_deep_dive():
    """
    KALI PYPI DEEP-DIVE (Vector 27)
    Analyzes the source code of external dependencies to understand lower-level system behavior.
    """
    logging.basicConfig(level=logging.INFO)
    logger = logging.getLogger("PYPI_DIVE")
    processor = DoubtProcessor()
    
    logger.info("📦 KALI PyPI Deep-Dive: Analyzing external dependency architecture...")
    
    # Analyze chromadb (crucial for vector memory)
    import chromadb
    lib_path = os.path.dirname(chromadb.__file__)
    
    files = [f for f in os.listdir(lib_path) if f.endswith(".py")][:10]
    target = os.path.join(lib_path, random.choice(files))
    
    with open(target, "r", encoding="utf-8") as f:
        code = f.read()
        
    analysis = processor.ai_service.ask_question(
        f"Analyze this external library source code: {os.path.basename(target)}\n\n"
        f"CODE:\n{code[:2000]}\n\n"
        f"TASK: Identify how KALI's vector_memory.py can more efficiently interface with this dependency."
    )
    
    # Log to training data
    processor.training_logger.log(f"Dependency Deep-Dive: {os.path.basename(target)}", analysis)
    logger.info(f"[+] Dependency Interaction Anchored.")

if __name__ == "__main__":
    import random
    run_pypi_deep_dive()
