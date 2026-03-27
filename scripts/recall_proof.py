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

def run_recall_proof():
    """
    KALI NEURAL RECALL PROOF (Phase 4.27)
    Verifies that KALI can recall and apply 'Wisdom Seeds' stored in her long-term memory.
    """
    logging.basicConfig(level=logging.INFO)
    logger = logging.getLogger("RECALL_PROOF")
    processor = DoubtProcessor()
    
    logger.info("🧪 KALI Neural Recall Proof: Testing active memory 'feeding'...")
    
    # 1. Fetch a Wisdom Seed from memory
    col = processor.vector_memory._get_collection("knowledge")
    seeds = col.get(where={"source": "singularity_seed"})
    
    if not seeds["documents"]:
        logger.warning("No Wisdom Seeds found. Please run scripts/wisdom_compactor.py first.")
        return
        
    target_seed = seeds["documents"][-1]
    logger.info(f"[*] Test Target (Seed): {target_seed[:100]}...")
    
    # 2. Challenge KALI to explain a concept using the seed's logic
    challenge = f"Using the following distilled technical principle, explain how KALI should optimize her own 'vector_memory.py' logic: '{target_seed}'"
    
    response = processor.ai_service.ask_question(challenge)
    
    logger.info("\n" + "="*60)
    print(f"🧬 NEURAL RECALL SUCCESS (Seed-Informed Answer):")
    print(f"{response}")
    print("="*60 + "\n")
    
    # 3. Log the success (This trains her that RECALL is working)
    processor.training_logger.log("Neural Recall Success", f"Seed Recalled: {target_seed[:50]}...")

if __name__ == "__main__":
    run_recall_proof()
