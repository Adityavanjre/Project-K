import os
import ast
import json
import logging
from typing import Dict, Any, List

class SovereignAuditTool:
    """
    Project-K Sovereign Audit Tool.
    Scans the codebase to verify architectural integrity and safety gates.
    """
    def __init__(self, root: str):
        self.root = root
        self.report = {
            "tiers": {},
            "safety_gates": [],
            "anomalies": []
        }

    def run_audit(self):
        print("KALI SOVEREIGN AUDIT: INITIATING...")
        self._audit_tier("NUCLEUS", ["src/core/processor.py", "src/core/ai_service.py", "src/core/knowledge_check.py"])
        self._audit_tier("LIMBS", ["src/core/system_controller.py", "src/core/evolution_bridge.py"])
        self._audit_tier("SHIELD", ["src/core/mission_manager.py", "src/core/omega_protocol.py", "src/core/integrity.py"])
        self._audit_tier("ENGINES", ["src/core/code_executor.py", "src/core/council_service.py", "src/core/rlhf_service.py"])
        self._audit_tier("SENSORIUM", ["src/core/biometric_service.py", "src/core/swarm_service.py", "src/core/user_dna.py"])
        
        self._verify_safety_coupling()
        self._save_report()
        print("AUDIT COMPLETE. Report saved to data/audit_report.json")

    def _audit_tier(self, tier_name: str, files: List[str]):
        self.report["tiers"][tier_name] = []
        for f in files:
            path = os.path.join(self.root, f)
            if not os.path.exists(path):
                self.report["anomalies"].append(f"MISSING_FILE: {f}")
                continue
            
            try:
                with open(path, 'r', encoding='utf-8') as file:
                    tree = ast.parse(file.read())
                    functions = [node.name for node in ast.walk(tree) if isinstance(node, ast.FunctionDef)]
                    self.report["tiers"][tier_name].append({
                        "file": f,
                        "logic_units": functions,
                        "size_kb": round(os.path.getsize(path)/1024, 2)
                    })
            except Exception as e:
                self.report["anomalies"].append(f"PARSE_ERROR: {f} - {str(e)}")

    def _verify_safety_coupling(self):
        """Verifies if critical operations are mentioned in safety gates."""
        shield_path = os.path.join(self.root, "src/core/mission_manager.py")
        if os.path.exists(shield_path):
            with open(shield_path, 'r', encoding='utf-8') as f:
                content = f.read()
                if "authorize_mission" in content and "PENDING" in content:
                    self.report["safety_gates"].append("MISSION_GATING_ACTIVE")
        
        bridge_path = os.path.join(self.root, "src/core/evolution_bridge.py")
        if os.path.exists(bridge_path):
            with open(bridge_path, 'r', encoding='utf-8') as f:
                content = f.read()
                if "system_controller.run_shell" in content or "system_controller.write_file" in content:
                    self.report["safety_gates"].append("EVOLUTION_GATING_ACTIVE")
        
        exec_path = os.path.join(self.root, "src/core/code_executor.py")
        if os.path.exists(exec_path):
            with open(exec_path, 'r', encoding='utf-8') as f:
                content = f.read()
                if "ast.parse" in content and "multiprocessing.Process" in content:
                    self.report["safety_gates"].append("COMPUTATIONAL_SANDBOX_ACTIVE")

    def _save_report(self):
        os.makedirs(os.path.join(self.root, "data"), exist_ok=True)
        with open(os.path.join(self.root, "data/audit_report.json"), 'w', encoding='utf-8') as f:
            json.dump(self.report, f, indent=4)

if __name__ == "__main__":
    auditor = SovereignAuditTool(".")
    auditor.run_audit()
