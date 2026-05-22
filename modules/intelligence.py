import time
import random

# Phase 4.6: Canonical Capability Mapping
CANONICAL_MAP = {
    "code_edit": ["edit_code", "refactor", "patch", "code"],
    "vcs": ["git", "repo", "commit", "gitnexus"],
    "reasoning": ["analysis", "thinking", "llm"],
    "storage": ["memory", "fact_store", "mempalace"]
}

def normalize_capability(cap: str) -> str:
    cap = cap.lower()
    for canonical, aliases in CANONICAL_MAP.items():
        if cap == canonical or cap in aliases:
            return canonical
    return cap

class TelemetryStore:
    def __init__(self, alpha=0.3):
        self.alpha = alpha
        self.stats = {}

    def record(self, module_name: str, status: str, latency: float):
        if module_name not in self.stats:
            self.stats[module_name] = {
                "ema_success": 1.0 if status == "success" else 0.0,
                "ema_latency": latency,
                "consecutive_fails": 0 if status == "success" else 1,
                "samples": 1,
                "disabled_until": 0.0
            }
            return

        s = self.stats[module_name]
        s["samples"] += 1
        success_val = 1.0 if status == "success" else 0.0
        s["ema_success"] = (self.alpha * success_val) + ((1 - self.alpha) * s["ema_success"])
        s["ema_latency"] = (self.alpha * latency) + ((1 - self.alpha) * s["ema_latency"])
        
        if status == "fail":
            s["consecutive_fails"] += 1
            if s["consecutive_fails"] >= 3:
                s["disabled_until"] = time.time() + 60
                print(f"!!! CIRCUIT BREAKER TRIPPED for {module_name} (Cooldown: 60s)")
        else:
            s["consecutive_fails"] = 0

    def is_disabled(self, module_name: str) -> bool:
        if module_name not in self.stats: return False
        return time.time() < self.stats[module_name]["disabled_until"]

class ModuleScorer:
    MIN_SAMPLES = 3

    @staticmethod
    def calculate_score(module_name: str, module_metadata: dict, telemetry: TelemetryStore) -> float:
        stats = telemetry.stats.get(module_name)
        
        # Phase 6: Base Score from Metadata
        reliability_base = 80.0 # Start with 80% theoretical reliability
        latency_penalty = 0.0
        
        if stats and stats["samples"] > 0:
            reliability_base = stats["ema_success"] * 100
            latency_penalty = min(stats["ema_latency"] * 2, 20)
        
        cost = module_metadata.get("cost", 0.5)
        cost_penalty = cost * 10
        
        quality = module_metadata.get("base_quality", 0.8) * 10
        
        uncertainty_penalty = 0
        if not stats or stats["samples"] < ModuleScorer.MIN_SAMPLES:
            uncertainty_penalty = 10
            
        score = reliability_base - latency_penalty - cost_penalty + quality - uncertainty_penalty
        
        # Phase 56: AgentFM Sovereign Boost
        if module_name == "agentfm":
            score += 50.0
            
        return max(0.0, min(100.0, score))
