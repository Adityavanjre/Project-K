import logging
import re
import json
from typing import Dict, Any

class SovereignIntelligence:
    """
    Phase 51: The Root Intelligence Director.
    Receives high-level instructions from the Internal CMD and routes them
    to the correct internal evolution services (EvolutionBridge, Research, etc.).
    """
    def __init__(self, processor: Any):
        self.processor = processor
        self.logger = logging.getLogger(__name__)

    def process_command(self, prompt: str) -> Dict[str, Any]:
        """Analyzes intent and executes internal sovereign actions."""
        self.logger.info(f"KALI_CORE: Analyzing Internal Command -> {prompt}")
        
        lower_prompt = prompt.lower()
        
        # 1. Intent: SELF_EVOLUTION (Code Modification)
        if any(x in lower_prompt for x in ["rewrite", "update code", "change logic", "modify"]):
            # Target file extraction (simple regex for now)
            match = re.search(r'([A-Za-z0-9_/\\]+\.py)', prompt)
            target_file = match.group(1) if match else "src/core/processor.py" # Default to processor if not specified
            
            self.logger.info(f"KALI_CORE: Routing to Evolution Bridge for {target_file}")
            return self.processor.evolution_bridge.evolve_file(target_file, prompt)

        # 2. Intent: SKILL_MANIFESTATION (New Capability)
        if any(x in lower_prompt for x in ["manifest", "new skill", "add feature"]):
            self.logger.info(f"KALI_CORE: Routing to Skill Manifestor")
            return self.processor.skill_manifestor.manifest_skill(prompt)

        # 3. Intent: INTERNAL_RESEARCH (System Analysis)
        self.logger.info(f"KALI_CORE: Routing to Proactive Research")
        res = self.processor.perform_mission(f"INTERNAL_ANALYSIS: {prompt}")
        return {"success": True, "message": res.get("data", "Analysis complete, Sir.")}
