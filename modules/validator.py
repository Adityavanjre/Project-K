import os
import time
from modules.permissions import RiskLevel

class PlanValidator:
    MAX_STEPS = 5 # Increased for multi-agent workflows

    @classmethod
    def validate(cls, plan: list, allowed_modules: list) -> tuple[bool, str, list]:
        """
        Validates a generated plan against the current registry.
        """
        if not isinstance(plan, list) or len(plan) == 0:
            return False, "Invalid plan format.", []
            
        if len(plan) > cls.MAX_STEPS:
            return False, f"Plan exceeds maximum of {cls.MAX_STEPS} steps.", []
            
        enriched_plan = []
        
        for i, step in enumerate(plan):
            step_num = i + 1
            if "type" not in step or "input" not in step:
                return False, f"Step {step_num} missing fields.", []
                
            if step["type"] not in allowed_modules:
                return False, f"Step {step_num} unauthorized module: {step['type']}", []
            
            # Risk Assignment
            risk = RiskLevel.SAFE
            if step["type"] == "memory":
                risk = RiskLevel.CONTROLLED
            elif step["type"] in ["code", "gitnexus"]:
                risk = RiskLevel.CRITICAL
                
            enriched_step = {**step, "risk": risk}
            enriched_plan.append(enriched_step)

        return True, "Validated", enriched_plan

class PerformanceValidator:
    @classmethod
    def validate_module(cls, module, bridge) -> tuple[bool, str]:
        """
        Performs a smoke test on a module before activation.
        """
        name = module.name
        metadata = module.metadata
        caps = metadata.get("capabilities", [])
        
        if not caps:
            return False, "Module has no capabilities."
            
        test_cap = caps[0]
        test_task = {"type": test_cap, "input": "KALI PERFORMANCE TEST"}
        
        print(f"[VALIDATOR] Running Performance Pass for {name}...")
        start = time.time()
        try:
            # Direct run (bypass bridge logic)
            result = module.run(test_task)
            latency = time.time() - start
            
            if result.get("status") != "success":
                return False, f"Module test run failed: {result.get('reason')}"
            
            # Latency bounds check
            l_class = metadata.get("latency_class", "medium")
            max_latency = 10.0 if l_class == "slow" else 5.0 if l_class == "medium" else 2.0
            
            if latency > max_latency:
                return False, f"Module latency ({latency:.2f}s) exceeds bounds for {l_class} class."
                
            return True, f"Passed. Latency: {latency:.2f}s"
        except Exception as e:
            return False, f"Exception during validation: {str(e)}"
