import logging
from typing import List, Dict, Any
from .agents.expert_agents import get_default_experts, ExpertAgent

class CouncilService:
    """
    The Great Council: A Multi-Agent MsgHub for KALI.
    Orchestrates specialized experts to debate and reach consensus.
    """
    def __init__(self, ai_service):
        self.ai = ai_service
        self.logger = logging.getLogger(__name__)
        self.experts = get_default_experts()

    def get_consensus(self, query: str, context: str = "", bypass_cache: bool = False, debate_rounds: int = 1) -> str:
        """
        Convenes the Council in a multi-round debate as a MsgHub.
        """
        self.logger.info(f"Convening KALI Council MsgHub for: {query.splitlines()[0]}...")
        
        debate_history = []
        
        # 1. Initial round: Each expert gives their perspective
        for expert in self.experts:
            prompt = expert.get_prompt_with_context(query, debate_history)
            sys_msg = f"{expert.system_prompt}\nYou are part of KALI's Council. User Context: {context}"
            
            response = self.ai.ask_question(
                prompt, 
                context=sys_msg, 
                temperature=0.7, 
                query_model=expert.model, 
                bypass_cache=bypass_cache
            )
            
            if response:
                debate_history.append({"role": expert.name, "content": response})
                self.logger.info(f"Council: {expert.name} provides initial insight.")

        # 2. Subsequent rounds: Experts critique and refine (if debate_rounds > 1)
        for r in range(debate_rounds - 1):
            self.logger.info(f"Council: Round {r+2} of debate initiating.")
            for expert in self.experts:
                # Ask expert to critique and improve based on others' views
                critique_prompt = f"Review the previous council insights. Refine your own stance or resolve contradictions. FOCUS: {query}"
                prompt = expert.get_prompt_with_context(critique_prompt, debate_history)
                
                response = self.ai.ask_question(
                    prompt, 
                    context=f"CONTRADICTION RESOLUTION MODE. {expert.system_prompt}", 
                    temperature=0.5, 
                    query_model=expert.model, 
                    bypass_cache=bypass_cache
                )
                if response:
                    debate_history.append({"role": expert.name, "content": response})

        # 3. Final Synthesis (The Lead)
        self.logger.info("Consolidating final Council consensus...")
        
        synthesis_prompt = (
            f"GOAL: {query}\n"
            f"COUNCIL DEBATE LOG:\n" + 
            "\n---\n".join([f"[{m['role']}]: {m['content']}" for m in debate_history]) + 
            "\n\nSynthesize the debate above into a single, master-level KALI response. "
            "Resolve any remaining conflicts, ensure technical precision, and prioritize user safety."
        )
        
        final_answer = self.ai.ask_question(synthesis_prompt, bypass_cache=bypass_cache)
        return final_answer
