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

def run_curiosity_scraper():
    """
    KALI CURIOSITY SCRAPER (Vector 16)
    Identifies 'Wisdom Seeds' and scrapes detailed technical context for training.
    """
    logging.basicConfig(level=logging.INFO)
    logger = logging.getLogger("CURIOSITY")
    processor = DoubtProcessor()
    
    logger.info("📡 KALI Curiosity Scraper: Scouring digital frontier for new tech...")
    
    # 1. Identify a concept she doesn't know well
    dna = processor.user_dna.profile
    known = list(dna["expertise"]["known_concepts"].keys())
    
    # Target concept (Randomly or from a 'Curiosity Queue')
    potential_seeds = ["Rust Memory Safety", "Vector DB Optimization", "Quantized Neural Logic", "Robotic Kinematics"]
    target = random.choice([s for s in potential_seeds if s.upper() not in known])
    
    logger.info(f"[*] Deep Research initiated for: {target}")
    
    # 2. Scrape/Research Concept
    research = processor.proactive_research.research_topic(target)
    
    # 3. Log as high-fidelity interaction
    processor.training_logger.log(f"Deep Research: {target}", research)
    logger.info(f"[+] Curiosity Interaction Anchored: {target}")

if __name__ == "__main__":
    run_curiosity_scraper()
