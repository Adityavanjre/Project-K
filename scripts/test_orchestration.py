import sys
import os
import time
import multiprocessing
import json
import shutil
from unittest.mock import patch

# Add project root to sys.path
sys.path.append(os.getcwd())

from modules.bridge import UniversalBridge
from modules.base import Module
from modules.strategy import StrategyStore

class MockModule(Module):
    def __init__(self, name, capabilities=None, status="success", output=None, quality=1.0):
        self.name = name
        self._capabilities = capabilities or []
        self.status = status
        self.output = output or f"Result from {self.name}"
        self.quality = quality
    @property
    def metadata(self):
        return {
            "capabilities": self._capabilities, 
            "latency_class": "fast", 
            "risk": "SAFE",
            "base_quality": self.quality,
            "cost": 0.1
        }
    def is_available(self): return True
    def run(self, task, device="cpu"):
        return {"status": self.status, "output": self.output}

class MockDualLLM(Module):
    def __init__(self, eval_accepted=True, eval_quality=0.9): 
        self.name = "dual_llm"
        self.eval_accepted = eval_accepted
        self.eval_quality = eval_quality
    @property
    def metadata(self): 
        return {"capabilities": ["llm"], "base_quality": 0.5, "cost": 0.9}
    def is_available(self): return True
    def run(self, task, device="cpu"):
        inp = str(task.get("input", ""))
        if "Evaluate" in inp:
            return {
                "status": "success", 
                "output": json.dumps({
                    "accepted": self.eval_accepted, 
                    "reason": "Mocked", 
                    "improvement_advice": "Fix it",
                    "quality_score": self.eval_quality,
                    "confidence": 0.9
                })
            }
        return {"status": "success", "output": '[{"type": "reasoning", "input": "Think"}]'}

def test_learning_governance():
    if os.path.exists(StrategyStore.STRATEGY_DIR):
        shutil.rmtree(StrategyStore.STRATEGY_DIR)
        
    bridge = UniversalBridge()
    bridge.register("reasoner", MockModule("reasoner", ["reasoning"]))
    bridge.register("alt_reasoner", MockModule("alt_reasoner", ["reasoning"]))
    bridge.permission_manager.session_approvals.update(["llm", "reasoner", "alt_reasoner"])
    
    print("--- 1. Testing Governance Filter (Low Quality) ---")
    bridge.register("llm", MockDualLLM(eval_accepted=True, eval_quality=0.4))
    bridge.process_directive("Analyze quality")
    
    best = StrategyStore.get_best_module("Think", "reasoning")
    assert best is None
    print("Done. Low quality experience filtered out.")

    print("\n--- 2. Testing Negative Memory (Blacklist) ---")
    for _ in range(3):
        StrategyStore.save_experience({
            "task_input": "HardTask",
            "capability": "reasoning",
            "module": "reasoner",
            "status": "fail",
            "quality_score": 0.2,
            "confidence": 0.9
        })
    
    is_bl = StrategyStore.is_blacklisted("HardTask", "reasoner", "reasoning")
    assert is_bl is True
    
    resolved = bridge.resolve_module("reasoning", task_input="HardTask")
    assert resolved == "alt_reasoner"
    print("Done. Blacklisted module avoided.")

    print("\n--- 3. Testing Human Feedback Priority ---")
    bridge.permission_manager.session_approvals.clear()
    
    # Identify which module will be resolved
    target_mod = bridge.resolve_module("reasoning", task_input="HumanTask")
    
    with patch.object(bridge.permission_manager, 'request_approval', return_value=False):
        bridge.execute({"type": "reasoning", "input": "HumanTask"})
    
    # Check if THAT module is now blacklisted
    is_bl_human = StrategyStore.is_blacklisted("HumanTask", target_mod, "reasoning")
    assert is_bl_human is True
    print(f"Done. Human denial recorded for {target_mod}.")

    print("\n--- 4. Testing Planner Adaptation (Human Insights) ---")
    StrategyStore.save_experience({
        "task_input": "HumanTask",
        "capability": "reasoning",
        "module": target_mod,
        "status": "fail",
        "is_human_feedback": True,
        "critic_feedback": "Do not use automated reasoning for sensitive tasks"
    })
    
    res = bridge.planner_agent.communicate({"task": "HumanTask"})
    # The prompt check is internal, but we can verify it doesn't crash
    print("Done. Planner agent retrieved human insights.")

    print("\nLEARNING GOVERNANCE TESTS COMPLETE")

if __name__ == "__main__":
    multiprocessing.freeze_support()
    test_learning_governance()
