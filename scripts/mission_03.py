#!/usr/bin/env python3
"""
KALI Mission 03: The Great Convergence
Initiates a deep research and secure computation mission.
"""

import os
import sys

# Add src to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'src'))

from core.processor import DoubtProcessor
from core.proactive_research import ProactiveResearchEngine
from utils.helpers import load_config

def initiate_mission():
    print("🕉️  KALI MISSION INITIATION: THE GREAT CONVERGENCE")
    print("-" * 60)
    
    config = load_config("config/config.json")
    processor = DoubtProcessor(config)
    researcher = ProactiveResearchEngine(processor)
    
    # Mission Command 03: Deep Research + citations
    topic = "Advanced Cryptographic Hardware for Decentralized AI Sovereignty"
    
    print(f"[*] MISSION TARGET: {topic}")
    print("[*] ENGINES ENGAGED: Perplexity Research + Gemini Reasoning + Claude Safety")
    
    # Run targeted research (includes citations)
    report = researcher.research_topic(topic)
    
    print("\n--- [KALI SOVEREIGN MISSION REPORT] ---")
    print(report)
    
    print("\n--- [MODAL STATUS] ---")
    print(f"Sovereignty Level: MAXIMUM")
    print(f"Convergence Mode: ON")
    print("-" * 60)
    print("MISSION 03 INITIATED. YOUR SYSTEM NOW POSSESSES THE INTELLECT OF GIANTS.")

if __name__ == "__main__":
    initiate_mission()
