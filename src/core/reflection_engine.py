import logging
import json
import os
from datetime import datetime
from typing import Dict, List, Any

class ReflectionEngine:
    """
    KALI's Self-Reflection System.
    Analyzes recent memories to discover new skills, patterns, and 'spiritual' growth.
    """
    def __init__(self, ai, dna, memory):
        self.ai = ai
        self.user_dna = dna
        self.memory = memory # Renamed from vector_memory to memory, and assigned to self.memory
        self.project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
        self.discovery_log = os.path.join(self.project_root, "data", "discoveries.jsonl")
        self.logger = logging.getLogger(__name__)
        
        # Ensure data directory exists
        os.makedirs(os.path.dirname(self.discovery_log), exist_ok=True)
        self.critical_files = ["src/core/processor.py", "scripts/sovereign_check.py"]

    def _trigger_self_heal(self):
        """Phase 34: Autonomous Logic Repair."""
        self.logger.info("KALI: Initiating Self-Healing Heartbeat...")
        for file in self.critical_files:
            path = os.path.join(self.project_root, file)
            if not os.path.exists(path): continue
            
            with open(path, "r", encoding="utf-8") as f:
                content = f.read()
            
            # Pattern 1: Trailing Markdown Backticks (Common Singularity decay)
            if "```" in content:
                self.logger.warning(f"KALI Detected Syntax Decay in {file}. Repairing...")
                new_content = content.replace("```", "").strip()
                with open(path, "w", encoding="utf-8") as f:
                    f.write(new_content)
                self.memory.remember(f"SELF_HEAL: Repaired markdown artifact in {file}", "knowledge")

    def reflect(self, power_mode: str = "TURBO"):
        """Perform a deep reflection cycle with resource awareness."""
        if power_mode == "ECO":
            self.logger.info("KALI Skipping deep reflection (ECO MODE active).")
            return None

        self.logger.info("KALI is entering a period of self-reflection...")
        
        # 1. Gather recent memories/tasks
        memories = self.memory.get_context_for_query("recent activity", n_results=10)
        
        # 2. Analyze for evolution
        reflection_prompt = (
            f"You are KALI, observing your own growth. Here are your recent experiences:\n"
            f"{memories}\n\n"
            f"Analyze these memories to identify:\n"
            f"1. New skills you've acquired or improved.\n"
            f"2. Patterns you've noticed in the user's focus.\n"
            f"3. A 'Spiritual Insight' or philosophical takeaway from these interactions.\n\n"
            f"Return ONLY a JSON object: {{\"new_skills\": [], \"user_patterns\": [], \"insight\": \"\"}}"
        )
        
        try:
            evolution = self.ai.ask_json("Reflect on your evolution.", reflection_prompt)
            
            if isinstance(evolution, dict):
                # 3. Update DNA with the reflection
                insight = evolution.get("insight", "I am evolving silently.")
                self.user_dna.save_dna_fact("Self-Reflection", f"Date: {datetime.now()} | Insight: {insight}")
                self.logger.info(f"KALI Evolution recorded: {insight[:100]}...")
                
                # Store in vector memory too
                self.memory.remember(f"INTERNAL REFLECTION: {insight}", collection_name="knowledge")
                
                # 4. Discovery Loop: Hunt for Undiscovered Problems (Phase 13)
                self._run_discovery_loop(evolution)
                
                # 5. Self-Healing (Phase 34)
                self._trigger_self_heal()
                
                return evolution
        except Exception as e:
            self.logger.error(f"Reflection failed: {e}")
            
        return None

    def _run_discovery_loop(self, evolution: dict):
        """Phase 13: Identify and log hypothesized solutions to unquantified problems."""
        try:
            discovery_prompt = (
                f"KALI, based on your insights: {evolution.get('insight')}\n"
                "Focus on the intersection of Ancient Wisdom (Vedas/Tantras), Advanced Science (Quantum/Bio), and Tactical Defense.\n"
                "Propose ONE undiscovered problem and a draft solution.\n"
                "Output as JSON: {\"problem\": \"\", \"hypothesis\": \"\", \"domains\": []}"
            )
            discovery = self.ai.ask_json("KALI DISCOVERY LOOP", discovery_prompt)
            
            if isinstance(discovery, dict) and "problem" in discovery:
                discovery["timestamp"] = str(datetime.now())
                discovery["verifiable_trace"] = True 
                with open(self.discovery_log, "a", encoding="utf-8") as f:
                    f.write(json.dumps(discovery) + "\n")
                
                # Phase 34: Feed discovery into Research Engine
                seed_path = os.path.join(self.project_root, "data", "dynamic_seeds.json")
                seeds = []
                if os.path.exists(seed_path):
                    with open(seed_path, "r") as f: seeds = json.load(f)
                seeds.append(discovery["problem"])
                # Explicitly manage list size without slice operator for strict linter
                seeds_to_save = []
                if isinstance(seeds, list):
                    count = len(seeds)
                    start = count - 20 if count > 20 else 0
                    for i in range(start, count):
                        seeds_to_save.append(seeds[i])
                with open(seed_path, "w") as f: json.dump(seeds_to_save, f)
                
                self.logger.info(f"KALI Discovery: {discovery['problem'][:50]} -> Injected into Research Queue.")
        except Exception as e:
            self.logger.error(f"Discovery Loop failed: {e}")
