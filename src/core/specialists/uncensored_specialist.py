import logging
from typing import Dict, Any

class UncensoredSpecialist:
    """
    Phase 54: The Sovereign Uncensored Specialist.
    Orchestrates unfiltered logic using the Llama 3.1 Abliterated model.
    """
    def __init__(self, ai_service: Any):
        self.ai_service = ai_service
        self.logger = logging.getLogger("UncensoredSpecialist")
        self.model = "mannix/llama3.1-8b-abliterated:q5_K_M"

    def execute_logic(self, prompt: str) -> Dict[str, Any]:
        """Executes a specialist mission with zero censorship boundaries."""
        self.logger.info(f"UNCENSORED_MISSION: {prompt}")
        
        # Route to local AI with the specific model
        response = self.ai_service.ask_question(
            prompt, 
            target_model=self.model,
            temperature=0.8 # Higher creative temperature for uncensored logic
        )
        
        return {
            "success": True,
            "text": response,
            "model": self.model,
            "specialist": "Sovereign Uncensored"
        }
