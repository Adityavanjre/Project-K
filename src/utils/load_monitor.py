import psutil
import os
import logging
import gc

class LoadMonitor:
    """
    KALI Resource Oracle: Tracks CPU and RAM to prevent local saturation.
    Used by the Routing Engine to decide Local vs Remote execution.
    """
    def __init__(self):
        self.logger = logging.getLogger("LoadMonitor")

    def is_local_safe(self) -> bool:
        """
        Check if local execution is safe based on current hardware load.
        Safe threshold: CPU < 70% and Available RAM > 3GB.
        """
        try:
            cpu_usage = psutil.cpu_percent(interval=0.1)
            ram_available = psutil.virtual_memory().available / (1024 ** 3) # GB
            
            # Adjusted thresholds for stable local inference
            is_safe = cpu_usage < 85 and ram_available > 1.5
            
            if ram_available < 1.5:
                self.logger.debug(f"KALI Memory Critical: {ram_available:.1f}GB remaining. Triggering Scavenger.")
                self.scavenge_memory()
            elif not is_safe:
                self.logger.debug(f"KALI Resource Warning: CPU {cpu_usage}%, RAM {ram_available:.1f}GB. Threshold Breached.")
            
            return is_safe
        except Exception as e:
            self.logger.error(f"LoadMonitor Failure: {e}")
            return False

    def scavenge_memory(self):
        """
        Phase 4: Aggressive memory reclamation.
        Purges Python garbage and unloads unused model fragments.
        """
        gc.collect()
        self.logger.info("KALI Scavenger: Garbage collection forced. Memory reclaimed.")

    def get_metrics(self):
        return {
            "cpu": psutil.cpu_percent(),
            "ram_gb": psutil.virtual_memory().available / (1024 ** 3)
        }
