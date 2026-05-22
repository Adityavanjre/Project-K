import threading
import time
import logging
from typing import List, Dict, Any, Optional
from .vision import NeocortexVision

class NeocortexSubconscious(threading.Thread):
    """
    The background learning loop of KALI's Neocortex.
    Monitors visual context and builds a short-term 'Subconscious' memory.
    """
    def __init__(self, vision: Optional[NeocortexVision] = None, interval: int = 60):
        super().__init__(daemon=True)
        self.vision = vision or NeocortexVision()
        self.interval = interval
        self.is_running = False
        self.logger = logging.getLogger(__name__)
        
        # Sliding window of recent context (last 10 captures)
        self.context_window: List[Dict[str, Any]] = []
        self.max_window_size = 10
        
        self._stop_event = threading.Event()

    def run(self):
        """Background loop execution."""
        self.is_running = True
        self.logger.info(f"Subconscious learning loop ENGAGED. Interval: {self.interval}s")
        
        while not self._stop_event.is_set():
            try:
                # Capture visual context
                context = self.vision.get_screen_context()
                
                if context.get("status") == "success":
                    self.add_to_window(context)
                    self.logger.info(f"Subconscious Update: {context['summary'][:100]}...")
                
            except Exception as e:
                self.logger.error(f"Subconscious tick failed: {e}")
            
            # Wait for next interval
            time.sleep(self.interval)

    def add_to_window(self, context: Dict[str, Any]):
        """Maintain a sliding window of recent visual history."""
        self.context_window.append(context)
        if len(self.context_window) > self.max_window_size:
            self.context_window.pop(0)

    def get_latest_context(self) -> Optional[str]:
        """Return a synthesized summary of the recent context window."""
        if not self.context_window:
            return None
        
        return self.context_window[-1]["summary"]

    def stop(self):
        """Disengage the background loop."""
        self._stop_event.set()
        self.is_running = False
        self.logger.info("Subconscious learning loop DISENGAGED.")

if __name__ == "__main__":
    # Diagnostic mode
    logging.basicConfig(level=logging.INFO)
    sub = NeocortexSubconscious(interval=10)
    sub.start()
    
    try:
        print("Subconscious is learning... Press Ctrl+C to stop.")
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        sub.stop()
