import os
import json
from enum import Enum
from datetime import datetime

class ModuleState(Enum):
    REGISTERED = "registered"  # Found but not yet tested
    TESTING = "testing"        # Undergoing performance validation
    ACTIVE = "active"          # Ready for production use
    INACTIVE = "inactive"      # Explicitly disabled or failed validation

class SandboxTier(Enum):
    SAFE = "safe"              # Minimal system access, proven stability
    CONTROLLED = "controlled"  # Standard access, monitored execution
    EXPERIMENTAL = "experimental" # New, unproven, or high-risk modules

class ModuleRegistry:
    REGISTRY_FILE = os.path.join(os.getcwd(), "data", "module_registry.json")

    def __init__(self):
        self.registry = self._load()

    def _load(self) -> dict:
        if os.path.exists(self.REGISTRY_FILE):
            try:
                with open(self.REGISTRY_FILE, "r") as f:
                    return json.load(f)
            except: pass
        return {}

    def _save(self):
        os.makedirs(os.path.dirname(self.REGISTRY_FILE), exist_ok=True)
        with open(self.REGISTRY_FILE, "w") as f:
            json.dump(self.registry, f, indent=2)

    def register_module(self, name: str, tier: SandboxTier):
        if name not in self.registry:
            self.registry[name] = {
                "state": ModuleState.REGISTERED.value,
                "tier": tier.value,
                "registered_at": datetime.now().isoformat(),
                "activated_at": None,
                "last_test_result": None
            }
            self._save()
            print(f"[REGISTRY] Registered new module: {name} (Tier: {tier.value})")

    def set_state(self, name: str, state: ModuleState, test_result: str = None):
        if name in self.registry:
            self.registry[name]["state"] = state.value
            if state == ModuleState.ACTIVE:
                self.registry[name]["activated_at"] = datetime.now().isoformat()
            if test_result:
                self.registry[name]["last_test_result"] = test_result
            self._save()
            print(f"[REGISTRY] Module {name} state changed to {state.value}")

    def get_state(self, name: str) -> ModuleState:
        data = self.registry.get(name)
        if not data: return ModuleState.REGISTERED
        return ModuleState(data["state"])

    def get_tier(self, name: str) -> SandboxTier:
        data = self.registry.get(name)
        if not data: return SandboxTier.EXPERIMENTAL
        return SandboxTier(data["tier"])

    def is_active(self, name: str) -> bool:
        return self.get_state(name) == ModuleState.ACTIVE

    def can_execute(self, name: str, risk_level: str) -> bool:
        """Enforce sandbox tiers against task risk levels."""
        tier = self.get_tier(name)
        state = self.get_state(name)
        
        if state != ModuleState.ACTIVE:
            return False
            
        if risk_level == "CRITICAL":
            return tier == SandboxTier.SAFE
        if risk_level == "CONTROLLED":
            return tier in [SandboxTier.SAFE, SandboxTier.CONTROLLED]
        
        return True # SAFE tasks allow EXPERIMENTAL modules
