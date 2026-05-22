import sys
import os
import time

# Add project root to sys.path
sys.path.append(os.getcwd())

from modules.bridge import UniversalBridge
from modules.permissions import RiskLevel

def test_controlled_autonomy():
    print("--- Testing Controlled Autonomy ---")
    bridge = UniversalBridge()
    pm = bridge.permission_manager
    
    # Test 1: Autonomy OFF (Default)
    print("\nTest 1: Autonomy OFF (Default gating)")
    task = {"type": "memory", "input": "save session"}
    risk = pm.calculate_contextual_risk(task) # Should be CONTROLLED
    print(f"Task: {task['type']}, Risk: {risk}")
    
    # In a test environment without bridge.emit_event real UI, we check logic
    # request_approval will wait if self.bridge is set, so we temporarily unset for logic test
    orig_bridge = pm.bridge
    pm.bridge = None
    
    # Mock input to return False
    with patch('builtins.input', return_value='n'):
        approved = pm.request_approval(task, risk)
        print(f"Autonomy OFF Approved: {approved} (Expected: False)")
        assert not approved

    # Test 2: Autonomy ON (Auto-approve trusted)
    print("\nTest 2: Autonomy ON (Auto-approve trusted CONTROLLED)")
    bridge.set_autonomy_mode(True)
    # Memory has trust 85, threshold is 70
    approved = pm.request_approval(task, risk)
    print(f"Autonomy ON Approved: {approved} (Expected: True)")
    assert approved

    # Test 3: Autonomy ON (Block CRITICAL)
    print("\nTest 3: Autonomy ON (Still block CRITICAL)")
    task_crit = {"type": "code", "input": "delete all files"}
    risk_crit = pm.calculate_contextual_risk(task_crit) # Should be CRITICAL
    print(f"Task: {task_crit['type']}, Risk: {risk_crit}")
    
    with patch('builtins.input', return_value='n'):
        approved = pm.request_approval(task_crit, risk_crit)
        print(f"Critical Approved: {approved} (Expected: False)")
        assert not approved

    pm.bridge = orig_bridge
    print("\nSuccess! Controlled autonomy logic verified.")

from unittest.mock import patch
if __name__ == "__main__":
    test_controlled_autonomy()
