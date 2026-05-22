import sys
import os
import time
import multiprocessing
import json
from unittest.mock import patch

# Add project root to sys.path
sys.path.append(os.getcwd())

from modules.bridge import UniversalBridge
from modules.base import Module
from modules.registry import SandboxTier, ModuleState

class MockModule(Module):
    def __init__(self, name, capabilities=None):
        self.name = name
        self._capabilities = capabilities or []
    @property
    def metadata(self):
        return {"capabilities": self._capabilities, "latency_class": "fast", "risk": "SAFE", "base_quality": 1.0, "sandbox_tier": "safe"}
    def is_available(self): return True
    def run(self, task, device="cpu"):
        return {"status": "success", "output": f"Result from {self.name}"}

def test_intelligence_stream():
    print("--- Testing Intelligence Event Stream ---")
    bridge = UniversalBridge()
    bridge.register("mock", MockModule("mock", ["test_cap"]), auto_activate=True, tier=SandboxTier.SAFE)
    
    # Mock some agent communication to avoid actual LLM calls
    with patch("modules.agents.PlannerAgent.communicate") as mock_planner, \
         patch("modules.agents.CriticAgent.communicate") as mock_critic, \
         patch("modules.agents.ExecutorAgent.communicate") as mock_executor:
         
        mock_planner.return_value = {
            "plan": [
                {"type": "test_cap", "input": "Step 1"}
            ]
        }
        mock_executor.return_value = {"status": "success", "output": "Done"}
        mock_critic.return_value = {"accepted": True, "reason": "Perfect"}
        
        # Start a directive
        print("Starting directive: 'Run test step'")
        bridge.process_directive("Run test step")
        
        print("\nChecking Event Queue...")
        events = []
        while not bridge.event_queue.empty():
            events.append(bridge.event_queue.get())
        
        types = [e["type"] for e in events]
        print(f"Captured events: {types}")
        
        assert "goal_created" in types
        assert "step_started" in types
        assert "critic_log" in types
        assert "goal_progress" in types
        assert "goal_completed" in types
        
        print("\nSuccess! Bridge correctly emits intelligence events.")

if __name__ == "__main__":
    multiprocessing.freeze_support()
    test_intelligence_stream()
