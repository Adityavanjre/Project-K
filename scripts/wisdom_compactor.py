#!/usr/bin/env python3
import time
import logging
import os
import sys
import json

# Add project root and src to path
project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
sys.path.insert(0, project_root)
sys.path.insert(0, os.path.join(project_root, 'src'))

from src.core.processor import DoubtProcessor

def run_wisdom_compactor():
    """
    KALI WISDOM COMPACTOR (Phase 4.26)
    Synthesizes raw training logs into High-Density Wisdom Seeds and
    injects them directly into Vector Memory.
    """
    logging.basicConfig(level=logging.INFO)
    logger = logging.getLogger("COMPACTOR")
    processor = DoubtProcessor()
    
    logger.info("⚡ KALI Wisdom Compactor: Synthesizing training logs into high-density seeds...")
    
    log_path = os.path.join(project_root, "data", "training_data.jsonl")
    if not os.path.exists(log_path):
        logger.error("No training data found to compact.")
        return
        
    with open(log_path, "r", encoding="utf-8") as f:
        lines = f.readlines()
        
    if len(lines) < 10:
        logger.warning("Complexity too low for compaction. Minimum 10 interactions required.")
        return
        
    # Group every 10 interactions
    batch_size = 10
    for i in range(0, len(lines), batch_size):
        batch = lines[i:i + batch_size]
        batch_text = "\n".join([json.loads(l)["goal"] for l in batch])
        
        # Synthesize into a Wisdom Seed
        seed = processor.ai_service.ask_question(
            f"You are the KALI ANALYST. Synthesize these 10 training interactions into ONE high-density technical pearl of wisdom.\n"
            f"INTERACTIONS:\n{batch_text}\n\n"
            f"OUTPUT: A single dense technical principle."
        )
        
        # Inject into Vector Memory
        processor.vector_memory.remember(seed, collection_name="knowledge", meta={"source": "singularity_seed", "batch": i//batch_size})
        logger.info(f"[+] Wisdom Seed {i//batch_size} Injected into Long-Term Memory.")

if __name__ == "__main__":
    run_wisdom_compactor()
