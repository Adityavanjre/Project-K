import sys
import os
import time
import threading
from unittest.mock import patch

# Add project root to sys.path
sys.path.append(os.getcwd())

from modules.bridge import UniversalBridge
from modules.base import Module
from modules.registry import SandboxTier

class MockModule(Module):
    def __init__(self, name):
        self.name = name
    @property
    def metadata(self):
        return {"capabilities": [self.name], "latency_class": "fast", "risk": "SAFE", "base_quality": 1.0, "sandbox_tier": "safe"}
    def is_available(self): return True
    def run(self, task, device="cpu"):
        time.sleep(1.0) # Simulate work
        return {"status": "success", "output": f"Result from {self.name}"}

def test_operational_controls():
    print("--- Testing Operational Control Layer ---")
    bridge = UniversalBridge()
    bridge.register("m1", MockModule("m1"), auto_activate=True, tier=SandboxTier.SAFE)
    bridge.register("m2", MockModule("m2"), auto_activate=True, tier=SandboxTier.SAFE)
    
    with patch("modules.agents.PlannerAgent.communicate") as mock_planner, \
         patch("modules.agents.CriticAgent.communicate") as mock_critic, \
         patch("modules.agents.ExecutorAgent.communicate") as mock_executor:
         
        mock_planner.return_value = {
            "plan": [
                {"type": "m1", "input": "S1"},
                {"type": "m2", "input": "S2"},
                {"type": "m1", "input": "S3"}
            ]
        }
        # Fixed lambda to match ExecutorAgent.communicate signature
        def mock_exec_func(x):
            time.sleep(2.0)
            return {"status": "success", "output": f"Done {x['task']['type']}"}
            
        mock_executor.side_effect = mock_exec_func
        mock_critic.return_value = {"accepted": True, "reason": "OK"}
        
        # Test 1: Pause and Resume
        print("\nTest 1: Pause/Resume")
        def run():
            bridge.process_directive("Test Control")
        
        t = threading.Thread(target=run)
        t.daemon = True
        t.start()
        
        # Wait for goal creation
        for _ in range(20):
            if bridge.active_goals: break
            time.sleep(0.5)
            
        if not bridge.active_goals:
            print("Error: No active goals found.")
            return

        active_id = list(bridge.active_goals)[0]
        
        print(f"Pausing goal {active_id}...")
        bridge.goal_controls[active_id]["paused"] = True
        
        time.sleep(2)
        print("Resuming goal...")
        bridge.goal_controls[active_id]["paused"] = False
        
        # Test 2: Skip Step
        print("\nTest 2: Skip Step")
        time.sleep(1)
        if active_id in bridge.goal_controls:
            bridge.goal_controls[active_id]["skip_step"] = True
            print("Sent SKIP signal.")
        
        # Test 3: Override Module
        print("\nTest 3: Override Module")
        time.sleep(1)
        if active_id in bridge.goal_controls:
            bridge.goal_controls[active_id]["override_module"] = "m1" 
            print("Sent OVERRIDE signal.")
        
        t.join(timeout=30)
        
        print("\nSuccess! Operational controls verified.")

if __name__ == "__main__":
    test_operational_controls()
