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
from modules.registry import ModuleState, SandboxTier, ModuleRegistry

class MockModule(Module):
    def __init__(self, name, capabilities=None, status="success", tier=SandboxTier.EXPERIMENTAL):
        self.name = name
        self._capabilities = capabilities or []
        self.status = status
        self.tier = tier
    @property
    def metadata(self):
        return {
            "capabilities": self._capabilities, 
            "latency_class": "fast", 
            "risk": "SAFE",
            "base_quality": 1.0,
            "sandbox_tier": self.tier.value
        }
    def is_available(self): return True
    def run(self, task, device="cpu"):
        return {"status": self.status, "output": f"Result from {self.name}"}

def test_controlled_ecosystem():
    # Clear registry
    registry_file = os.path.join(os.getcwd(), "data", "module_registry.json")
    if os.path.exists(registry_file): os.remove(registry_file)
    
    bridge = UniversalBridge()
    bridge.permission_manager.session_approvals.update(["llm", "code", "memory", "new_mod", "secure_mod"])
    
    print("--- 1. Testing Registration and Inactive State ---")
    new_mod = MockModule("new_mod", ["extra_tool"])
    bridge.register("new_mod", new_mod) # Defaults to REGISTERED
    
    # Try to resolve 'extra_tool'
    resolved = bridge.resolve_module("extra_tool")
    assert resolved is None
    print("Done. REGISTERED module is correctly ignored.")

    print("\n--- 2. Testing Controlled Activation (Performance Pass) ---")
    success = bridge.activate_module("new_mod")
    assert success is True
    assert bridge.registry.get_state("new_mod") == ModuleState.ACTIVE
    
    resolved = bridge.resolve_module("extra_tool")
    assert resolved == "new_mod"
    print("Done. Module activated after successful Performance Pass.")

    print("\n--- 3. Testing Failed Activation ---")
    bad_mod = MockModule("bad_mod", ["broken_tool"], status="fail")
    bridge.register("bad_mod", bad_mod)
    success = bridge.activate_module("bad_mod")
    assert success is False
    assert bridge.registry.get_state("bad_mod") == ModuleState.INACTIVE
    print("Done. Broken module correctly kept INACTIVE.")

    print("\n--- 4. Testing Sandbox Tier Enforcement ---")
    # EXPERIMENTAL module
    exp_mod = MockModule("exp_mod", ["exp_tool"], tier=SandboxTier.EXPERIMENTAL)
    bridge.register("exp_mod", exp_mod, auto_activate=True) # Forced active but experimental
    
    # SAFE task should allow EXPERIMENTAL
    res_safe = bridge.resolve_module("exp_tool", risk_level="SAFE")
    assert res_safe == "exp_mod"
    
    # CRITICAL task should NOT allow EXPERIMENTAL
    res_crit = bridge.resolve_module("exp_tool", risk_level="CRITICAL")
    assert res_crit is None
    print("Done. Sandbox tiers enforced correctly.")

    print("\n--- 5. Testing SAFE Tier for CRITICAL Tasks ---")
    secure_mod = MockModule("secure_mod", ["secure_tool"], tier=SandboxTier.SAFE)
    bridge.register("secure_mod", secure_mod, auto_activate=True)
    
    res_crit_secure = bridge.resolve_module("secure_tool", risk_level="CRITICAL")
    assert res_crit_secure == "secure_mod"
    print("Done. SAFE modules allowed for CRITICAL tasks.")

    print("\nCONTROLLED ECOSYSTEM TESTS COMPLETE")

if __name__ == "__main__":
    multiprocessing.freeze_support()
    test_controlled_ecosystem()
