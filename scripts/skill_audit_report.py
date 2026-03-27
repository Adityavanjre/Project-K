#!/usr/bin/env python3
import logging
import os
import sys

# Add project root and src to path
project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
sys.path.insert(0, project_root)
sys.path.insert(0, os.path.join(project_root, 'src'))

from src.core.processor import DoubtProcessor

def run_skill_audit():
    """
    KALI SKILL AUDIT REPORT (Phase 4.27)
    Asks the core skill instances (Mentor/Teacher) to reflect on their own training journey.
    """
    logging.basicConfig(level=logging.INFO)
    logger = logging.getLogger("SKILL_AUDIT")
    processor = DoubtProcessor()
    
    logger.info("📐 KALI Skill Audit: Verifying Mentor/Teacher training density...")
    
    services = {
        "Explainer (Mentor/Teacher)": processor.explainer,
        "GSDService (Engineer)": processor.gsd_service,
        "ReviewService (Auditor)": processor.review_service
    }
    
    print("\n" + "*"*60)
    print("🎓 KALI CORE SKILL TRAINING REPORT")
    print("*"*60)
    
    for name, service in services.items():
        # Query memory for specific training logs related to this skill
        history = processor.vector_memory.recall(f"Training for {name}", collection_name="knowledge", n=3)
        
        reflection = processor.ai_service.ask_question(
            f"You are the {name}. Review your training history and summarize the top 3 evolutionary 'Lessons' you have learned from the 162 interactions.\n"
            f"RECENT TRAINING PATHS:\n" + "\n".join(history)
        )
        
        print(f"\n[+] SERVICE: {name}")
        print(f"    REFLECTION: {reflection}")
        
    print("*"*60 + "\n")

if __name__ == "__main__":
    run_skill_audit()
