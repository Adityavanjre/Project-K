import os
import json
import hashlib
import time
import random
from datetime import datetime

class StrategyStore:
    STRATEGY_DIR = os.path.join(os.getcwd(), "data", "strategy")
    DECAY_HALFLIFE_DAYS = 7 # Strategies lose half weight every week

    @classmethod
    def save_experience(cls, experience: dict):
        # Phase 6.5: Quality Gate
        # Only store successes if they are high quality and confident
        if experience.get("status") == "success":
            quality = experience.get("quality_score", 1.0)
            confidence = experience.get("confidence", 1.0)
            if quality < 0.7 or confidence < 0.6:
                print(f"[GOVERNANCE] Experience rejected: Low quality ({quality}) or confidence ({confidence})")
                return

        if not os.path.exists(cls.STRATEGY_DIR):
            os.makedirs(cls.STRATEGY_DIR)
        
        task_input = experience.get("task_input", "")
        task_hash = hashlib.sha256(task_input.encode()).hexdigest()[:12]
        
        path = os.path.join(cls.STRATEGY_DIR, f"{task_hash}.json")
        experiences = []
        if os.path.exists(path):
            try:
                with open(path, "r") as f:
                    experiences = json.load(f)
            except: pass
            
        experiences.append({
            **experience,
            "timestamp": time.time(),
            "datetime": datetime.now().isoformat()
        })
        
        # Keep last 20 experiences for same task pattern
        experiences = experiences[-20:]
        
        with open(path, "w") as f:
            json.dump(experiences, f, indent=2)

    @classmethod
    def get_best_module(cls, task_input: str, capability: str) -> str:
        """Search for proven modules with Time Decay and Diversity."""
        task_hash = hashlib.sha256(task_input.encode()).hexdigest()[:12]
        path = os.path.join(cls.STRATEGY_DIR, f"{task_hash}.json")
        
        if not os.path.exists(path): return None
            
        try:
            with open(path, "r") as f:
                experiences = json.load(f)
            
            # Diversity Check: 10% of the time, ignore proven strategy to explore
            if random.random() < 0.10:
                print(f"[GOVERNANCE] Strategic exploration triggered for {capability}")
                return None

            now = time.time()
            module_scores = {}
            
            for exp in experiences:
                if exp.get("capability") != capability: continue
                mod = exp.get("module")
                
                # Phase 6.5: Time Decay
                age_days = (now - exp.get("timestamp", now)) / (24 * 3600)
                decay = 0.5 ** (age_days / cls.DECAY_HALFLIFE_DAYS)
                
                # Weighted score: Success = 1 * decay, Failure = -2 * decay (Negative Memory)
                # Human feedback is weighted much higher
                multiplier = 5.0 if exp.get("is_human_feedback") else 1.0
                
                if exp.get("status") == "success":
                    score = 1.0 * decay * multiplier * exp.get("quality_score", 1.0)
                else:
                    score = -3.0 * decay * multiplier # Heavy penalty for failures
                    
                module_scores[mod] = module_scores.get(mod, 0) + score
                
            if not module_scores: return None
            
            # Return module with highest weighted score
            best_mod, best_score = max(module_scores.items(), key=lambda x: x[1])
            
            # Only return if the score is significantly positive
            if best_score > 0.5:
                return best_mod
        except: pass
        return None

    @classmethod
    def is_blacklisted(cls, task_input: str, module_name: str, capability: str) -> bool:
        """Check if a module has a strong negative history for this task."""
        task_hash = hashlib.sha256(task_input.encode()).hexdigest()[:12]
        path = os.path.join(cls.STRATEGY_DIR, f"{task_hash}.json")
        if not os.path.exists(path): return False
        
        try:
            with open(path, "r") as f:
                experiences = json.load(f)
            
            neg_score = 0
            for exp in experiences:
                if exp.get("module") == module_name and exp.get("capability") == capability:
                    if exp.get("status") == "fail":
                        neg_score += 1
                        if exp.get("is_human_feedback"): neg_score += 5
                        
            return neg_score >= 3 # Blacklist after 3 failures (or 1 human rejection)
        except: return False

    @classmethod
    def get_feedback(cls, task_input: str) -> list:
        task_hash = hashlib.sha256(task_input.encode()).hexdigest()[:12]
        path = os.path.join(cls.STRATEGY_DIR, f"{task_hash}.json")
        if not os.path.exists(path): return []
        try:
            with open(path, "r") as f:
                experiences = json.load(f)
                # Sort by timestamp desc, take lessons from successes or human failures
                lessons = []
                for e in reversed(experiences):
                    if e.get("critic_feedback"):
                        prefix = "[HUMAN ADVICE]" if e.get("is_human_feedback") else "[SYSTEM LESSON]"
                        lessons.append(f"{prefix} {e['critic_feedback']}")
                return lessons[:5]
        except: return []
