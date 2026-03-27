import json
import os
import time
import logging
from typing import Dict, Any

class HUDBridge:
    """
    Bridges KALI's internal state (Biometrics, Hardware) to the 
    manifested Visual HUD (biometric_dashboard.tsx).
    """
    def __init__(self, output_path: str = "data/hud_state.json"):
        self.output_path = os.path.abspath(output_path)
        self.logger = logging.getLogger("KALI.HUD")
        os.makedirs(os.path.dirname(self.output_path), exist_ok=True)

    def update_hud(self, biometric_state: Dict[str, Any], system_metrics: Dict[str, Any]):
        """Writes the latest state to the HUD JSON interface."""
        try:
            hud_data = {
                "biometrics": biometric_state,
                "hardware": system_metrics,
                "timestamp": time.time(),
                "status": "SOVEREIGN_CONNECTED"
            }
            
            with open(self.output_path, "w") as f:
                json.dump(hud_data, f, indent=2)
            
            # self.logger.debug(f"HUD Bridge Updated: {self.output_path}")
        except Exception as e:
            self.logger.error(f"HUD Bridge Sync Failed: {e}")

if __name__ == "__main__":
    # Test
    bridge = HUDBridge()
    bridge.update_hud({"tension": 12.5}, {"cpu": 45.0})
    print(f"HUD State written to {bridge.output_path}")
