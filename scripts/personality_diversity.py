#!/usr/bin/env python3
import logging
import os
import sys

# Add project root and src to path
project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
sys.path.insert(0, project_root)
sys.path.insert(0, os.path.join(project_root, 'src'))

from src.core.processor import DoubtProcessor

def run_personality_diversity():
    """
    KALI PERSONALITY DIVERSITY (Vector 28)
    Triangulates approach via 3 distinct neural personas.
    """
    logging.basicConfig(level=logging.INFO)
    logger = logging.getLogger("DIVERSITY")
    processor = DoubtProcessor()
    
    problem = "Autonomous Self-Sustaining Hardware Infrastructure."
    logger.info(f"🎭 KALI Personality Diversity: Solving '{problem}'")
    
    # Persona 1: The Ethereal Teacher
    p1 = processor.ai_service.ask_question(f"PERSONA: KALI TEACHER. Explain {problem} in high-level architectural metaphors.")
    
    # Persona 2: The Ruthless Optimizer
    p2 = processor.ai_service.ask_question(f"PERSONA: KALI OPTIMIZER. Write a performance-first implementation for {problem}")
    
    # Persona 3: The Defensive Auditor
    p3 = processor.ai_service.ask_question(f"PERSONA: KALI AUDITOR. Find the security flaws in Persona 2's implementation.")
    
    # Log to training data
    processor.training_logger.log(f"Personality Debate: {problem}", f"TEACHER: {p1}\nOPTIMIZER: {p2}\nAUDITOR: {p3}")
    logger.info("[+] Diversity Interaction Anchored.")

if __name__ == "__main__":
    run_personality_diversity()
