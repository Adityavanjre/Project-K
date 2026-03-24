import os
import json
import threading
import time
import random
import logging
from typing import List, Optional

class ProactiveResearchEngine:
    """
    KALI's autonomous 'curiosity' driver.
    Periodically identifies a gap in her universal knowledge and executes a research mission.
    """
    def __init__(self, processor):
        self.processor = processor
        self.logger = logging.getLogger(__name__)
        self.is_active = False
        self.thread: Optional[threading.Thread] = None
        
        # Universal Seed Topics (Defense, Ancient Wisdom, Science, Tech)
        self.seeds = [
            "Ancient Vedic wave frequencies and modern acoustics",
            "Next-generation solid-state battery tech for defense drones",
            "The intersection of Quantum Entanglement and Vedic Non-duality",
            "Advanced cryptographic protocols for decentralized sovereign networks",
            "Hidden patterns in global economic shifts and Ayurvedic medical trends",
            "autonomous swarm intelligence in biological systems vs robotics",
            "The philosophy of Absolute Mind in Tantric texts",
            "Neuro-symbolic AI architectures for self-evolving agents"
        ]

    def start(self, interval_hours: int = 12):
        """Start the background curiosity loop."""
        if self.is_active: return
        self.is_active = True
        self.thread = threading.Thread(target=self._run_loop, args=(interval_hours,), daemon=True)
        self.thread.start()
        self.logger.info("KALI Proactive Research Engine activated.")

    def _run_loop(self, interval_hours):
        while self.is_active:
            try:
                # 1. Check Power Mode
                if self.processor.power_mode == "ECO":
                    self.logger.info("KALI Research Engine throttling (ECO MODE).")
                    time.sleep(3600) # Wait an extra hour in ECO
                    continue

                # 2. Select a random seed or look for gaps in discoveries.jsonl
                seed = random.choice(self.seeds)
                
                # 2. Execute a research mission via the planner
                self.logger.info(f"KALI Curiosity Triggered: Investigating '{seed}'")
                result = self.processor.planner.execute(f"Proactive research into {seed}")
                
                # 3. Store result in discovery log via reflection engine if possible
                if result and "answer" in result:
                    self.logger.info(f"KALI mastered a new domain: {seed}")
                    # The planner already saves to vector memory
                
            except Exception as e:
                self.logger.error(f"Proactive Research failed: {e}")
            
            # Wait for next cycle (plus some jitter)
            time.sleep(interval_hours * 3600 + random.randint(0, 3600))

    def _get_next_seed(self) -> str:
        """Prioritize dynamic seeds over static ones."""
        seed_path = "d:/code/doubt-clearing-ai/data/dynamic_seeds.json"
        if os.path.exists(seed_path):
            with open(seed_path, "r") as f: seeds = json.load(f)
            if seeds:
                res = seeds.pop(0)
                with open(seed_path, "w") as f: json.dump(seeds, f)
                return res
        return random.choice(self.seeds)
            
            # Wait for next cycle (plus some jitter)
            time.sleep(interval_hours * 3600 + random.randint(0, 3600))

    def stop(self):
        self.is_active = False
