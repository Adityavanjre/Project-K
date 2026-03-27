#!/usr/bin/env python3
import logging
import os
import sys

# Add project root and src to path
project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
sys.path.insert(0, project_root)
sys.path.insert(0, os.path.join(project_root, 'src'))

from src.core.processor import DoubtProcessor

def run_multi_agent_consensus():
    """
    KALI MULTI-AGENT CONSENSUS (Vector 24)
    Three KALI personalities debate a technical problem to reach a sovereign consensus.
    """
    logging.basicConfig(level=logging.INFO)
    logger = logging.getLogger("CONSENSUS")
    processor = DoubtProcessor()
    
    topic = "Recursive Model Updating Protocols"
    logger.info(f"⚖️ KALI Multi-Agent Consensus: '{topic}'")
    
    # Instance 1: The Architect
    a1 = processor.ai_service.ask_question(f"ARCHITECT: Propose the ideal implementation for {topic}")
    
    # Instance 2: The Auditor
    a2 = processor.ai_service.ask_question(f"AUDITOR: Identify the core failure modes of this implementation: {a1}")
    
    # Instance 3: The Coder
    a3 = processor.ai_service.ask_question(f"CODER: Write the final code resolving both the proposal and the audit: {a1}\n{a2}")
    
    # Log to training data (Debate Resolution)
    processor.training_logger.log(f"Consensus: {topic}", f"ARCH: {a1}\nAUDIT: {a2}\nFINAL: {a3}")
    logger.info("[+] Multi-Agent Consensus Anchored.")

if __name__ == "__main__":
    run_multi_agent_consensus()
