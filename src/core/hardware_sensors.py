import psutil
import logging

class HardwareSensors:
    """SOVEREIGN: Real-time hardware telemetry for KALI HUD."""
    
    def __init__(self):
        self.logger = logging.getLogger(__name__)
        
    def get_system_metrics(self):
        """Retrieve real CPU and Memory usage."""
        try:
            return {
                "cpu_usage": psutil.cpu_percent(),
                "memory_usage": psutil.virtual_memory().percent,
                "disk_usage": psutil.disk_usage('/').percent
            }
        except Exception as e:
            self.logger.error(f"SENSOR_FAILURE: {e}")
            return {"cpu_usage": 0, "memory_usage": 0, "disk_usage": 0}

    def get_status(self):
        return "OPTIMAL"
