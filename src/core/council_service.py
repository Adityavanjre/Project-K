import logging
import json
from typing import List, Dict, Any

class CouncilService:
    """
    The Great Council: Merges outputs from multiple AI experts (or perspectives).
    Ensures high accuracy and cross-verification.
    """
    def __init__(self, ai_service):
        self.ai = ai_service
        self.logger = logging.getLogger(__name__)

    def get_consensus(self, query: str, context: str = "") -> str:
        """
        Queries multiple AI 'perspectives' and merges them.
        """
        self.logger.info(f"Convening The Great Council for: {query[:50]}...")
        
        # Define Council Members (Perspectives)
        perspectives = [
            {"role": "The Scientist", "prompt": "Focus on facts, physics, and empirical data. Be extremely critical."},
            {"role": "The Engineer", "prompt": "Focus on practical implementation, BOM, and assembly steps."},
            {"role": "The Philosopher", "prompt": "Focus on the 'why', the ethics, and the broader context."}
        ]
        
        responses = []
        
        # 1. Gather outputs from council members
        for member in perspectives:
            sys_msg = f"{member['prompt']}\nYou are part of KALI's Council. Context: {context}"
            # We vary temperature slightly per member to get diverse views
            response = self.ai.ask_question(query, context=sys_msg, temperature=0.6)
            if response:
                responses.append({"member": member["role"], "content": response})

        if not responses:
            return "Council failed to reach quorum. (Backend error)"

        # 2. Convening the Lead (Synthesis)
        self.logger.info("Consolidating Council insights...")
        
        synthesis_prompt = (
            f"GOAL: {query}\n"
            f"COUNCIL DEBATE:\n" + 
            "\n---\n".join([f"EXPERT ({r['member']}): {r['content']}" for r in responses]) + 
            "\n\nSynthesize these expert views into a single, unified KALI response. "
            "Resolve conflicts, prioritize safety, and provide a master-level answer."
        )
        
        final_answer = self.ai.ask_question(synthesis_prompt)
        return final_answer
