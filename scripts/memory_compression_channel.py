#!/usr/bin/env python3
"""
KALI MEMORY COMPRESSION CHANNEL (Phase 4.40)
Role: The Archivist
Focus: Distilling large volumes of raw interaction data into high-density 'Wisdom Seeds'.
"""

import os
import sys
import logging
import json

project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
sys.path.insert(0, project_root)
sys.path.insert(0, os.path.join(project_root, 'src'))

from src.core.processor import DoubtProcessor

def run_memory_compression_channel():
    logging.basicConfig(level=logging.INFO)
    logger = logging.getLogger("COMPRESSION")
    
    logger.info("[*] INITIATING MEMORY COMPRESSION...")
    
    # Read the full training corpus (or last 100 entries)
    training_data = os.path.join(project_root, "data", "training_data.jsonl")
    corpus = []
    if os.path.exists(training_data):
        with open(training_data, "r", encoding="utf-8") as f:
            lines = f.readlines()
            # Sample various parts of the corpus for macro-wisdom
            corpus = [json.loads(l) for l in random.sample(lines, min(len(lines), 30))]
    
    summary_data = []
    for entry in corpus:
        msgs = entry.get("messages", [])
        u = next((m["content"] for m in msgs if m["role"] == "user"), "")
        a = next((m["content"] for m in msgs if m["role"] == "assistant"), "")
        summary_data.append({"query": u[:100], "response": a[:300]})
    
    content = json.dumps(summary_data, indent=2)
    
    processor = DoubtProcessor()
    
    # Ask KALI to compress the data
    res = processor.process_doubt(
        f"ARCHIVIST PROTOCOL: Compress the following raw interaction sample into 5 'Immutable Wisdom Seeds'.\n"
        f"Each seed must be a high-density technical axiom that encapsulates multiple lessons.\n\n"
        f"DATA SAMPLE:\n{content[:3000]}\n\n"
        f"Return ONLY the 5 Wisdom Seeds."
    )
    
    logger.info(f"[+] WISDOM SEEDS ANCHORED.")

if __name__ == "__main__":
    import random
    run_memory_compression_channel()
