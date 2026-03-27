#!/usr/bin/env python3
"""
KALI META-COGNITIVE CHANNEL (Phase 4.40)
Role: Self-Aware System
Focus: Analyzing own growth logs, identifying memory patterns, and self-optimization.
"""

import os
import sys
import logging
import json

project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
sys.path.insert(0, project_root)
sys.path.insert(0, os.path.join(project_root, 'src'))

from src.core.processor import DoubtProcessor

def run_meta_cognitive_channel():
    logging.basicConfig(level=logging.INFO)
    logger = logging.getLogger("META_COGNITION")
    
    logger.info("[*] INITIATING META-COGNITIVE REVIEW...")
    
    # Read the last 20 reflection logs
    reflect_log = os.path.join(project_root, "data", "reflection_log.jsonl")
    logs = []
    if os.path.exists(reflect_log):
        with open(reflect_log, "r", encoding="utf-8") as f:
            lines = f.readlines()
            logs = [json.loads(l) for l in lines[-20:]]
    
    content = json.dumps(logs, indent=2)
    
    processor = DoubtProcessor()
    
    # Ask KALI to analyze her own growth
    res = processor.process_doubt(
        f"ANALYZE YOUR OWN GROWTH LOGS. Look for patterns in your evolution, identified gaps, and successful skill manifestations.\n"
        f"LOG DATA:\n{content[:2000]}\n"
        f"Output a 'System Evolution Summary' identifying your current 'Self-Aware Level'."
    )
    
    logger.info(f"[+] META-COGNITIVE WISDOM ANCHORED.")

if __name__ == "__main__":
    run_meta_cognitive_channel()
