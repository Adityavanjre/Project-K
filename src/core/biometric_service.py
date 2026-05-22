import random
import time

class BiometricService:
    """
    KALI BIOMETRIC SERVICE [LIGHTWEIGHT RECOVERY]
    Tracks neural tension and physiological alignment.
    """
    def __init__(self):
        self.start_time = time.time()
        self.tension = 0.45
        self.alignment = 98.2

    def get_physiological_state(self, system_load: float = 0.0) -> dict:
        """
        Simulates physiological state based on system load.
        """
        # Slight drift based on time and load
        self.tension = 0.3 + (system_load / 100.0) * 0.4 + (random.random() * 0.1)
        self.tension = max(0.0, min(1.0, self.tension))
        
        return {
            "neural_tension": self.tension,
            "alignment": self.alignment,
            "heart_rate": 65 + int(self.tension * 40),
            "respiration": 12 + int(self.tension * 10),
            "gsr": 0.2 + (self.tension * 0.8),
            "timestamp": time.time()
        }

    def perform_reset(self):
        """Resets biometric baselines."""
        self.tension = 0.45
        self.alignment = 98.2
