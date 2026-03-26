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
        self.logger.info(f"Convening KALI Council for: {query.splitlines()[0]}...")
        
        # Define Council Members (Perspectives) with specialized NVIDIA models
        perspectives = [
            {"role": "The Scientist", "prompt": "Focus on facts, physics, and empirical data. Be extremely critical.", "model": "mistralai/mistral-large-3-675b-instruct-2512"},
            {"role": "The Engineer", "prompt": "Focus on practical implementation, BOM, and assembly steps.", "model": "nvidia/usdcode-llama-3.1-70b-instruct"}, 
            {"role": "The Philosopher", "prompt": "Focus on the 'why', the ethics, and the broader context.", "model": "microsoft/phi-3-medium-128k-instruct"},
            {"role": "The Researcher", "prompt": "Focus on deep-dive knowledge retrieval and link generation.", "model": "google/gemma-7b"}
        ]
        
        responses = []
        
        # 1. Gather outputs from council members
        for member in perspectives:
            sys_msg = f"{member['prompt']}\nYou are part of KALI's Council. Context: {context}"
            # Ask the specific model for each expert
            response = self.ai.ask_question(query, context=sys_msg, temperature=0.6, query_model=member["model"])
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
