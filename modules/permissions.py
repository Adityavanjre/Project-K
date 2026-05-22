import os
import hashlib
import time
import threading
from modules.logger import log_permission_event

class RiskLevel:
    SAFE = "SAFE"
    CONTROLLED = "CONTROLLED"
    CRITICAL = "CRITICAL"

class PermissionManager:
    def __init__(self):
        self.session_approvals = set()
        self.pattern_memory = {}
        self.trust_scores = {"llm": 100, "memory": 85, "code": 60, "gitnexus": 60}
        self.pending_requests = {} # {req_id: {"event": Event, "decision": None}}
        self.autonomy_enabled = False
        self.trust_threshold = 70
        self.bridge = None # Set by bridge

    def _generate_pattern_hash(self, task: dict) -> str:
        data = f"{task.get('type')}:{task.get('input')}"
        return hashlib.sha256(data.encode()).hexdigest()

    def calculate_contextual_risk(self, task: dict) -> str:
        base_risk = RiskLevel.SAFE
        module = task.get("type")
        input_str = str(task.get("input")).lower()
        
        if module == "memory": base_risk = RiskLevel.CONTROLLED
        elif module in ["code", "gitnexus"]: base_risk = RiskLevel.CRITICAL
        
        system_paths = ["modules/", "src/", "config/", "integrations/"]
        for path in system_paths:
            if path in input_str:
                if base_risk == RiskLevel.SAFE: base_risk = RiskLevel.CONTROLLED
                elif base_risk == RiskLevel.CONTROLLED: base_risk = RiskLevel.CRITICAL
                break
                
        if "all" in input_str or "*" in input_str or "recursive" in input_str:
            if base_risk == RiskLevel.CONTROLLED: base_risk = RiskLevel.CRITICAL
            
        trust = self.trust_scores.get(module, 0)
        if trust > 90 and base_risk == RiskLevel.CONTROLLED:
            base_risk = RiskLevel.SAFE
            
        return base_risk

    def request_approval(self, task: dict, risk_level: str) -> bool:
        module_name = task.get("type", "unknown")
        pattern_hash = self._generate_pattern_hash(task)
        module_trust = self.trust_scores.get(module_name, 0)

        # Autonomy Evaluation
        if risk_level == RiskLevel.SAFE: 
            return True
        
        if self.autonomy_enabled and risk_level == RiskLevel.CONTROLLED:
            if module_trust >= self.trust_threshold:
                log_permission_event("AUTO_APPROVED", f"{module_name} (Controlled Autonomy)", f"Trust: {module_trust}")
                return True
        
        # Pattern & Session Approvals
        if pattern_hash in self.pattern_memory: return True
        if module_name in self.session_approvals: return True

        # Phase 8: Emit UI event if bridge is available
        if self.bridge:
            req_id = hashlib.md5(f"{time.time()}:{module_name}".encode()).hexdigest()[:8]
            event = threading.Event()
            self.pending_requests[req_id] = {"event": event, "decision": None}
            
            self.bridge.emit_event("permission_request", {
                "id": req_id,
                "module": module_name,
                "type": "EXECUTE",
                "risk": risk_level,
                "reason": f"System requires execution of {module_name} for the current mission step."
            })
            
            # Wait for user (timeout after 5 mins)
            print(f"[PERMISSIONS] Waiting for user approval (ID: {req_id})...")
            event.wait(timeout=300.0)
            
            decision = self.pending_requests[req_id]["decision"]
            del self.pending_requests[req_id]
            
            if decision == "once": return True
            if decision == "always": 
                self.session_approvals.add(module_name)
                return True
            return False

        # Fallback to CLI
        log_permission_event("PERMISSION_REQUESTED", f"{module_name} execution", f"Risk: {risk_level}")
        print("\n" + "!" * 40)
        print(f"!!! KALI MODULAR PERMISSION REQUEST")
        print(f"!!! Action: {module_name}")
        print(f"!!! Risk:   {risk_level}")
        print(f"!!! Input:  {task.get('input')[:150]}...")
        print("!" * 40)
        
        try:
            choice = input("\nApprove? [y]es / [a]lways / [p]attern / [n]o: ").lower().strip()
            if choice == 'y': return True
            elif choice == 'a': self.session_approvals.add(module_name); return True
            elif choice == 'p': self.pattern_memory[pattern_hash] = "pattern"; return True
            else: return False
        except EOFError:
            return False

    def resolve_pending(self, req_id: str, choice: str):
        if req_id == "latest" and self.pending_requests:
            req_id = list(self.pending_requests.keys())[-1]
            
        if req_id in self.pending_requests:
            self.pending_requests[req_id]["decision"] = choice
            self.pending_requests[req_id]["event"].set()
            return True
        return False
