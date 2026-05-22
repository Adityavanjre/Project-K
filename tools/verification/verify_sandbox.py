import os
import sys
import logging
import json
from unittest.mock import MagicMock

# Ensure src is in path
sys.path.insert(0, os.path.abspath("src"))

from core.evolution_bridge import EvolutionBridge

# Mock AI Service
mock_ai = MagicMock()

def test_sandbox():
    bridge = EvolutionBridge(os.getcwd(), mock_ai)
    
    # CASE 1: Valid Evolution (Add a comment)
    target = "src/core/data_structures.py"
    with open(target, "r") as f:
        original = f.read()
    
    mock_ai.ask_question.return_value = f"```python\n# KALI VALID UPGRADE\n{original}\n```"
    
    print("Testing Valid Evolution...")
    res = bridge.propose_evolution(target, "Add a comment.")
    print(f"Result: {res.get('message', res.get('error'))}")
    if res.get("success"):
        print(f"Proposal ID: {res['proposal_id']}")
        # Check logs
        if "PASSED" in res.get("sandbox_logs", "") or "collected" in res.get("sandbox_logs", ""):
             print("✅ Sandbox Logic Verified (Pass Path)")

    # CASE 2: Breaking Evolution (Change a class name that tests depend on)
    # Note: This requires the sandbox to actually run tests.
    # Let's try to break 'src/core/gsd_service.py' by removing 'add_task' which I just fixed.
    target_gsd = "src/core/gsd_service.py"
    with open(target_gsd, "r") as f:
        gsd_code = f.read()
    
    broken_gsd = gsd_code.replace("def add_task", "def removed_task")
    mock_ai.ask_question.return_value = f"```python\n{broken_gsd}\n```"
    
    print("\nTesting Breaking Evolution (should fail sandbox)...")
    res_fail = bridge.propose_evolution(target_gsd, "Rename add_task to removed_task.")
    print(f"Result: {res_fail.get('error')}")
    if not res_fail.get("success") and "functional verification" in res_fail.get("error", ""):
        print("✅ Sandbox Logic Verified (Fail Path - Regression Detected)")
    else:
        print(f"❌ Fail Path Failed. Logic: {res_fail}")

if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)
    test_sandbox()
