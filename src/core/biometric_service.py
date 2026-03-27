#!/usr/bin/env python3
"""
KALI BIOMETRIC SERVICE
Phase 21: Biometric HUD (Physiological Performance)
Implements physiological monitoring, Neural Tension, and Neural Resets.
"""

import time
import logging
from typing import Dict, Any

class BiometricService:
    """Monitors simulated physiological state and system stress."""
    
    def __init__(self, threshold_tension: float = 80.0):
        self.logger = logging.getLogger(__name__)
        self.threshold_tension = threshold_tension
        self.start_time = time.time()
        self.interaction_count = 0
        self.last_reset = time.time()

    def record_interaction(self):
        """Increments interaction count for tension calculation."""
        self.interaction_count += 1

    def calculate_neural_tension(self, system_load: float = 0.0) -> float:
        """
        Calculates Neural Tension Index (0-100).
        Logic: Weight density of interactions over time + system load.
        """
        elapsed = time.time() - self.last_reset
        # Interaction density: count / (elapsed mins + 1)
        density = self.interaction_count / ((elapsed / 60.0) + 1.0)
        
        # Tension = (density * 10) + (system_load * 0.5)
        tension = (density * 5.0) + (system_load * 0.3)
        return min(100.0, max(0.0, tension))

    def get_physiological_state(self, system_load: float = 0.0) -> Dict[str, Any]:
        """Returns the current physiological dashboard state."""
        tension = self.calculate_neural_tension(system_load)
        
        state = {
            "neural_tension": round(tension, 2),
            "status": "STABLE" if tension < self.threshold_tension else "TENSION_HIGH",
            "reset_suggested": tension >= self.threshold_tension,
            "logic_load": system_load,
            "session_duration_min": round((time.time() - self.start_time) / 60.0, 1)
        }
        
        if state["reset_suggested"]:
            self.logger.warning("KALI ALERT: Neural instability detected. Suggesting Performance Reset.")
            
        return state

    def perform_reset(self):
        """Resets the tension counters (simulating a performance reset)."""
        self.interaction_count = 0
        self.last_reset = time.time()
        self.logger.info("KALI: Neural Tension Reset Complete. System aligned.")

if __name__ == "__main__":
    service = BiometricService()
    # Simulate high interaction
    for _ in range(20):
        service.record_interaction()
    
    status = service.get_physiological_state(system_load=45.0)
    print(f"[*] Cognitive HUD State: {status}")
