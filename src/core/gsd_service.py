import logging
from enum import Enum
from typing import Dict, Any, List, Optional

logger = logging.getLogger(__name__)

class GSDPhase(Enum):
    INITIALIZE = "INITIALIZE"
    DISCUSS = "DISCUSS"
    PLAN = "PLAN"
    EXECUTE = "EXECUTE"
    VERIFY = "VERIFY"

class GSDService:
    """
    KALI GSD (Get Shit Done) Service.
    Phase-driven development and execution tracker.
    """
    
    def __init__(self):
        self.current_phase = GSDPhase.INITIALIZE
        self.project_state: Dict[str, Any] = {}
        self.history: List[Dict[str, Any]] = []

    def transition_to(self, phase: GSDPhase, meta: Optional[Dict[str, Any]] = None):
        """Transitions the project to a new GSD phase."""
        logger.info(f"KALI GSD: Transitioning from {self.current_phase.value} to {phase.value}")
        self.history.append({
            "from": self.current_phase.value,
            "to": phase.value,
            "meta": meta or {}
        })
        self.current_phase = phase

    def get_structured_prompt(self, idea: str) -> str:
        """Returns a spec-driven prompt based on the current phase."""
        if self.current_phase == GSDPhase.INITIALIZE:
            return f"INITIALIZE PROJECT: Research and define the scope for '{idea}'."
        elif self.current_phase == GSDPhase.PLAN:
            return f"PLAN EXECUTION: Create atomic, verifiable tasks for '{idea}'."
        elif self.current_phase == GSDPhase.EXECUTE:
            return f"EXECUTE MISSION: Implement the logic and manifests for '{idea}'."
        elif self.current_phase == GSDPhase.VERIFY:
            return f"VERIFY COMPLETION: Audit and test the manifests for '{idea}'."
        return f"GSD_{self.current_phase.value}: {idea}"

    def get_gsd_status(self) -> Dict[str, Any]:
        """Provides telemetry for the GSD HUD."""
        return {
            "current_phase": self.current_phase.value,
            "phases_completed": len(self.history),
            "is_active": True
        }
