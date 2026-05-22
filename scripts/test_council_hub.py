import os
import sys
import logging
import asyncio

# Add src to path
sys.path.append(os.getcwd())

from src.core.ai_service import AIService
from src.core.council_service import CouncilService

async def test_council():
    logging.basicConfig(level=logging.INFO, format='%(levelname)s:%(name)s:%(message)s')
    
    print("--- KALI Council MsgHub Verification ---")
    
    # Initialize services
    ai = AIService()
    council = CouncilService(ai)
    
    # Complex query requiring multi-expert insight
    query = (
        "Design a low-cost, self-sustaining hydroponic system for a small balcony in Mumbai. "
        "I need a full BOM, assembly steps, and a scientific justification for the nutrient solution choice. "
        "Also, address the ethical implications of food sovereignty for urban dwellers."
    )
    
    print(f"Goal: {query}")
    print("\nInitiating Debate (1 Round)...")
    
    # Use 1 round for initial verification
    response = council.get_consensus(query, context="Level: Expert, Location: Mumbai", bypass_cache=True, debate_rounds=1)
    
    print("\n--- FINAL KALI RESPONSE ---")
    print(response)
    print("\n--- Verification Complete ---")

if __name__ == "__main__":
    asyncio.run(test_council())
