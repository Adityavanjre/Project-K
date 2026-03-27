#!/usr/bin/env python3
import time
import logging
import os
import sys
import random

# Add project root and src to path
project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
sys.path.insert(0, project_root)
sys.path.insert(0, os.path.join(project_root, 'src'))

from src.core.processor import DoubtProcessor

def run_knowledge_distill():
    """
    KALI KNOWLEDGE DISTILLATION (Neural Compression)
    Synthesizes long-form API responses into concise 'Local Wisdom' for model replacement.
    """
    logging.basicConfig(level=logging.INFO)
    logger = logging.getLogger("DISTILL")
    processor = DoubtProcessor()
    
    logger.info("💎 KALI Knowledge Distillation: Compressing API wisdom into local memory...")
    
    # 1. Fetch random past knowledge
    memories = processor.vector_memory.recall("advanced", n=3)
    if not memories: return
    
    seed = random.choice(memories)
    
    # 2. Distill into high-fidelity interaction
    distill = processor.ai_service.ask_question(
        f"You are the KALI ARCHITECT. Distill this technical context into a 'Perfect Instruction' for a future local model.\n"
        f"CONTEXT: {seed}\n\n"
        f"OUTPUT: A 'Prompt-Completion' pair that captures the core technical essence."
    )
    
    # 3. Log to training data (Distilled Samples)
    processor.training_logger.log("Knowledge Distillation", distill)
    logger.info(f"[+] Distilled Interaction Anchored.")

if __name__ == "__main__":
    run_knowledge_distill()
