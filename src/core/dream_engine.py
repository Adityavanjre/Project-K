#!/usr/bin/env python3
"""
KALI DREAM ENGINE
Phase 6: Sovereign Dream Cycle
Consolidates user interactions and synthesizes recursive insights.
"""

import json
import os
import logging
import random
from datetime import datetime
from typing import List, Dict, Any

class DreamEngine:
    """Mirrors human neural consolidation by replaying 'Digital Soul' logs."""
    
    def __init__(self, history_path="data/training_data.jsonl", wisdom_path="data/wisdom_seeds.jsonl"):
        self.logger = logging.getLogger(__name__)
        self.history_path = os.path.abspath(history_path)
        self.wisdom_path = os.path.abspath(wisdom_path)
        
    def dream(self) -> List[Dict]:
        """Runs a 'Consolidation Cycle' over the last 20 interactions."""
        if not os.path.exists(self.history_path):
            self.logger.warning("No Digital Soul found for dreaming.")
            return []
            
        logs = []
        with open(self.history_path, "r", encoding="utf-8") as f:
            for line in f:
                try:
                    logs.append(json.loads(line))
                except Exception:
                    pass
        
        self.logger.info(f"KALI Entering Dream Cycle for {len(logs)} total interactions (scanning last 20)...")
        wisdom_seeds = self._extract_wisdom(logs[-20:], label="dream_cycle")
        self._save_wisdom(wisdom_seeds)
        return wisdom_seeds

    def full_corpus_sweep(self) -> List[Dict]:
        """
        Phase 4.30: Full Digital Soul Sweep.
        Processes ALL interactions in chunks of 50,
        identifies long-term patterns, and synthesizes macro wisdom.
        Call once per day via ralph_loop or a scheduler.
        """
        if not os.path.exists(self.history_path):
            self.logger.warning("No Digital Soul found for full sweep.")
            return []

        logs = []
        with open(self.history_path, "r", encoding="utf-8") as f:
            for line in f:
                try:
                    logs.append(json.loads(line))
                except Exception:
                    pass

        total = len(logs)
        self.logger.info(f"KALI Full Corpus Sweep: Processing {total} interactions in chunks of 50.")

        all_seeds = []
        chunk_size = 50
        for chunk_start in range(0, total, chunk_size):
            chunk = logs[chunk_start:chunk_start + chunk_size]
            seeds = self._extract_wisdom(chunk, label=f"corpus_sweep_chunk_{chunk_start}")
            all_seeds.extend(seeds)

        self._save_wisdom(all_seeds)
        self.logger.info(f"Full Corpus Sweep complete. Extracted {len(all_seeds)} wisdom seeds from {total} interactions.")
        return all_seeds

    def _extract_wisdom(self, logs: List[Dict], label: str = "general") -> List[Dict]:
        """Extracts wisdom seeds from a list of interaction logs."""
        PATTERN_MAP = [
            {"keywords": ["circuit", "logic", "gpio", "i2c", "spi", "uart"], "pattern": "HARDWARE_PROTOCOL",
             "insight": "Integrate hardware protocol verification with low-latency gate checking."},
            {"keywords": ["pid", "control", "feedback", "motor", "servo", "pwm"], "pattern": "CONTROL_SYSTEMS",
             "insight": "PID tuning requires iterative testing; always log Kp/Ki/Kd values for each hardware iteration."},
            {"keywords": ["bom", "cost", "supplier", "price", "component"], "pattern": "ECONOMIC_ANALYSIS",
             "insight": "BOM cost modeling should include 15% buffer for supply chain volatility."},
            {"keywords": ["sha", "hash", "crypto", "integrity", "verify", "bios"], "pattern": "CRYPTOGRAPHIC_SECURITY",
             "insight": "All autonomous updates must pass SHA-256 verification before deployment."},
            {"keywords": ["roadmap", "phase", "milestone", "plan", "deadline"], "pattern": "PROJECT_PLANNING",
             "insight": "Phase gates require measurable completion criteria and risk-adjusted buffer allocations."},
            {"keywords": ["training", "learning", "vector", "interaction", "digital soul"], "pattern": "SELF_EVOLUTION",
             "insight": "Training density compounds exponentially with cross-channel synthesis."},
            {"keywords": ["test", "pytest", "assert", "verify", "check"], "pattern": "QUALITY_ASSURANCE",
             "insight": "Every self-patch must pass the pytest gatekeeper before replacing production code."},
        ]

        seeds = []
        for log in logs:
            messages = log.get("messages", [])
            for msg in messages:
                if msg.get("role") == "user":
                    content = msg.get("content", "").lower()
                    ts = log.get("timestamp", "")
                    for p in PATTERN_MAP:
                        if any(kw in content for kw in p["keywords"]):
                            seeds.append({
                                "pattern": p["pattern"],
                                "insight": p["insight"],
                                "source": ts,
                                "sweep_label": label
                            })
                            break  # One pattern per message
        return seeds
        
    def _save_wisdom(self, seeds: List[Dict]):
        os.makedirs(os.path.dirname(self.wisdom_path), exist_ok=True)
        with open(self.wisdom_path, "a", encoding="utf-8") as f:
            for seed in seeds:
                f.write(json.dumps(seed) + "\n")
        self.logger.info(f"Consolidated {len(seeds)} Wisdom Seeds, Sir.")

    def synthesize_augmented_data(self, processor, limit: int = 5) -> int:
        """
        Phase 4.11: Neural Augmentation.
        Takes existing Wisdom Seeds and 're-imagines' them as a full AI interaction.
        """
        if not os.path.exists(self.wisdom_path):
            return 0
            
        seeds = []
        with open(self.wisdom_path, "r", encoding="utf-8") as f:
            for line in f:
                seeds.append(json.loads(line))
        
        if not seeds: return 0
        
        # In HIT mode, we process more seeds
        batch = seeds[-limit:] 
        self.logger.info(f"KALI Augmentation: Re-imagining {len(batch)} wisdom seeds.")
        
        added_count = 0
        for seed in batch:
            prompt = f"Elaborate on this engineering insight for high-fidelity training: {seed['insight']}"
            response = processor.ai_service.ask_question(f"You are KALI. Elaborate on: '{seed['insight']}' in 5 technical steps.")
            
            # Phase 41: Peer-Reviewed Synthesis
            review = processor.review_service.review_manifest(response, "Synthetic Extension")
            if review.get("score", 0) >= 90:
                processor.training_logger.log(prompt, response, "You are KALI, an advanced AI mentor.")
                added_count += 1
                self.logger.info(f"[+] SEED_SYNTHESIS_SUCCESS (Score: {review.get('score')})")
            else:
                self.logger.warning(f"[-] SEED_SYNTHESIS_REJECTED (Score: {review.get('score')})")
            
        return added_count

    def run_high_intensity_training(self, processor):
        """
        Phase 50: HIT (High-Intensity Training).
        Exhausts the wisdom pool to reach the 10,000 threshold with high-fidelity logs.
        """
        self.logger.info("🚀 KALI: Initiating HIGH-INTENSITY TRAINING (HIT) MODE...")
        total_added = 0
        # Process in batches of 10 until wisdom is exhausted or reasonably sampled
        while True:
            added = self.synthesize_augmented_data(processor, limit=10)
            if added == 0: break
            total_added += added
            if total_added > 100: break # Safety break for single session
            
        self.logger.info(f"HIT CYCLE COMPLETE: Synthesized {total_added} high-fidelity interactions.")
        return total_added

if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)
    engine = DreamEngine()
    seeds = engine.dream()
    for s in seeds:
        print(f"[*] RECURSIVE INSIGHT: {s['insight']}")
