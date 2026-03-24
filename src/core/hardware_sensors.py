import psutil
import time

class HardwareSensors:
    """
    KALI PHYSICAL SENSORY SYSTEM
    Phase 27: Multi-Modal Awareness
    """
    
    @staticmethod
    def get_system_metrics():
        """Returns real-time system health metrics."""
        try:
            return {
                "cpu_usage": psutil.cpu_percent(interval=None),
                "memory_usage": psutil.virtual_memory().percent,
                "disk_usage": psutil.disk_usage('/').percent,
                "timestamp": time.time()
            }
        except Exception as e:
            return {"error": str(e)}

if __name__ == "__main__":
    sensors = HardwareSensors()
    print(sensors.get_system_metrics())
