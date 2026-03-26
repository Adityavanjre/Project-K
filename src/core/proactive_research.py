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
        # Use local variable to satisfy linter type checking
        cur_thread = threading.Thread(target=self._run_loop, args=(interval_hours,), daemon=True)
        self.thread = cur_thread
        cur_thread.start()
        self.logger.info("KALI Proactive Research Engine activated.")

    def _run_loop(self, interval_hours):
        while self.is_active:
            try:
                # 1. Check Power Mode
                if self.processor.power_mode == "ECO":
                    self.logger.info("KALI Research Engine throttling (ECO MODE).")
                    # Break long sleep into small chunks to stay responsive
                    for _ in range(60): # 1 hour = 60 * 60s
                        if not self.is_active: break
                        time.sleep(60)
                    continue

                # 2. Select a mission seed
                seed = self._get_next_seed()
                
                # 2. Execute a research mission via the planner
                self.logger.info(f"KALI Curiosity Triggered: Investigating '{seed}'")
                result = self.processor.planner.execute(f"Proactive research into {seed}")
                
                # 3. Store result in discovery log via reflection engine if possible
                if result and "answer" in result:
                    self.logger.info(f"KALI mastered a new domain: {seed}")
                
            except Exception as e:
                self.logger.error(f"Proactive Research failed: {e}")
            
            # Wait for next cycle (plus some jitter)
            total_sleep = interval_hours * 3600 + random.randint(0, 3600)
            self.logger.info(f"KALI Curiosity satisfied. Next mission in {interval_hours}h.")
            
            # Responsive sleep
            slept = 0
            while slept < total_sleep and self.is_active:
                time.sleep(60)
                slept += 60

    def research_topic(self, topic: str) -> str:
        """
        Execute a targeted research mission for a specific topic.
        Includes economic logic for parts/material research.
        """
        try:
            self.logger.info(f"Targeted Research: {topic}")
            
            # Enhance prompt if topic looks like a project or material
            if any(w in topic.lower() for w in ["build", "part", "material", "component", "cost", "price", "buy"]):
                enhanced_goal = (
                    f"Perform deep research into '{topic}'. "
                    f"MANDATORY: Identify exact material costs, compare multiple vendors, "
                    f"and provide direct purchase links for trusted sources."
                )
            else:
                enhanced_goal = topic

            result = self.processor.planner.execute(enhanced_goal)
            
            # Synthesize final report
            report = self.processor.explainer.ai.ask_question(
                f"Based on this research log, generate a comprehensive MISSION REPORT in Markdown format.\n"
                f"Research Data: {json.dumps(result)}\n"
                f"MANDATORY: Explicitly list costs and trusted vendor links if applicable."
            )
            return report
            
        except Exception as e:
            self.logger.error(f"Targeted research failed: {e}")
            return f"ERROR IN RESEARCH NEURAL PATHWAY: {e}"

    def _get_next_seed(self) -> str:
        """Prioritize dynamic seeds over static ones."""
        project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
        seed_path = os.path.join(project_root, "data", "dynamic_seeds.json")
        if os.path.exists(seed_path):
            with open(seed_path, "r") as f: seeds = json.load(f)
            if seeds:
                res = seeds.pop(0)
                with open(seed_path, "w") as f: json.dump(seeds, f)
                return res
        return random.choice(self.seeds)

    def stop(self):
        self.is_active = False
