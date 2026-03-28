import logging
import re
import json
from typing import Dict, Any
from .autonomous_coder import AutonomousCoder

class SovereignIntelligence:
    """
    Phase 51: The Root Intelligence Director.
    Receives high-level instructions from the Internal CMD and routes them
    to the correct internal evolution services (EvolutionBridge, Research, etc.).
    """
    def __init__(self, processor: Any):
        self.processor = processor
        self.logger = logging.getLogger(__name__)
        self.auto_coder = AutonomousCoder(processor)

    def process_command(self, prompt: str) -> Dict[str, Any]:
        """Analyzes intent and executes internal sovereign actions."""
        self.logger.info(f"KALI_CORE: Analyzing Internal Command -> {prompt}")
        
        lower_prompt = prompt.lower()
        
        # 1. Intent: SELF_EVOLUTION (High-Level Mission)
        # Check for keywords like "implement phase", "system-wide", "complex mission"
        is_mission = any(x in lower_prompt for x in ["mission", "implement phase", "complex", "system-wide", "optimize engine", "ui", "frontend", "responsive", "clean layout"])
        
        if any(x in lower_prompt for x in ["rewrite", "update code", "change logic", "modify", "evolve", "fix"]) or is_mission:
            # If it's a specific file mentions, use Bridge directly
            match = re.search(r'([A-Za-z0-9_/\\]+\\.py)', prompt) # Updated regex for windows paths
            if not match:
                match = re.search(r'([A-Za-z0-9_/\\]+\.py)', prompt)
            
            if match and not is_mission:
                target_file = match.group(1)
                self.logger.info(f"KALI_CORE: Routing to Evolution Bridge for {target_file}")
                return self.processor.evolution_bridge.evolve_file(target_file, prompt)
            else:
                # High-level mission: Route to Autonomous Coder
                self.logger.info(f"KALI_CORE: Routing to Autonomous Coder for complex mission: {prompt}")
                return self.auto_coder.execute_mission(prompt)

        # 2. Intent: SKILL_MANIFESTOR (New Capability)
        if any(x in lower_prompt for x in ["manifest", "new skill", "add feature"]):
            self.logger.info(f"KALI_CORE: Routing to Skill Manifestor")
            return self.processor.skill_manifestor.manifest_skill(prompt)

        # 3. Intent: INTERNAL_RESEARCH (System Analysis)
        self.logger.info(f"KALI_CORE: Routing to Proactive Research")
        res = self.processor.perform_mission(f"INTERNAL_ANALYSIS: {prompt}")
        return {"success": True, "message": res.get("data", "Analysis complete, Sir.")}
