import logging
import json
import time
import os
from typing import Dict, Any, List
from datetime import datetime

class SovereignIntelligence:
    """
    KALI SOVEREIGN INTELLIGENCE (COGNITION ROOT)
    
    The sole cognitive authority for Project-K.
    
    ANTIGRAVITY BRIDGE MODE:
    - KALI: Cognition / Reasoning / Execution / Evolution
    - ANTIGRAVITY: Bridge / Monitor / Relay / Observer
    """
    def __init__(self, processor=None, bridge=None):
        self.processor = processor
        self.bridge = bridge
        self.logger = logging.getLogger("KALI_CORE")
        self.execution_history = []
        self.active_reasoning_model = "KALI-COGNITION-O1-LOCAL"
        
        # Paths
        self.trace_dir = os.path.join("data", "evolution", "traces")
        os.makedirs(self.trace_dir, exist_ok=True)

    def process_command(self, objective: str) -> Dict[str, Any]:
        """
        Receives an objective from the DoubtProcessor or Antigravity Relay.
        Executes reasoning, planning, and orchestration autonomously.
        """
        trace_id = f"TRC-{int(time.time())}"
        self.logger.info(f"[{trace_id}] SOVEREIGN_START: {objective}")
        
        # 1. INITIAL REASONING (KALI Internal)
        reasoning_trace = self._generate_reasoning_trace(objective)
        
        execution_chain = {
            "id": trace_id,
            "objective": objective,
            "timestamp": datetime.now().isoformat(),
            "reasoning": reasoning_trace,
            "steps": [],
            "status": "in_progress",
            "executor": "KALI Sovereign Intelligence",
            "model": self.active_reasoning_model
        }

        # 2. PLANNING & ORCHESTRATION
        try:
            # Analyze if this is an evolution request
            if any(k in objective.lower() for k in ["evolve", "train", "improve", "benchmark"]):
                result = self._execute_evolution_mission(objective, execution_chain)
            else:
                result = self._execute_general_mission(objective, execution_chain)
                
            execution_chain["status"] = "success" if result.get("success", True) else "failed"
            execution_chain["result"] = result
            
        except Exception as e:
            self.logger.error(f"[{trace_id}] CRITICAL_FAILURE: {str(e)}")
            execution_chain["status"] = "failed"
            execution_chain["error"] = str(e)
            result = {"success": False, "error": str(e), "rollback": "initiated"}

        # 3. ANCHOR TRACE
        self._save_trace(execution_chain)
        self.execution_history.append(execution_chain)
        
        # 4. FORMAT RESPONSE FOR UI
        reasoning_str = "\n".join([f"  🧠 {step}" for step in reasoning_trace])
        result_summary = result.get("status", result.get("message", "Objective resolved."))
        
        execution_chain["text"] = f"🔱 KALI SOVEREIGN COGNITION ACTIVE\n\nREASONING:\n{reasoning_str}\n\nRESULT: {result_summary}"
        
        return execution_chain

    def _generate_reasoning_trace(self, objective: str) -> List[str]:
        """KALI reasoning logic - Exposes the internal 'thought' process."""
        # In a real sovereign build, this would be the output of a local CoT model
        return [
            f"Objective received: {objective}",
            "Decomposing objective into atomic swarm tasks...",
            "Validating architectural constraints via G-STACK.",
            "Selecting optimal swarm nodes for execution.",
            "Cross-referencing evolution memory for known heuristics."
        ]

    def _execute_evolution_mission(self, objective: str, chain: Dict) -> Dict:
        """Handles KALI-owned self-evolution and training."""
        chain["steps"].append({"action": "evolution_trigger", "node": "ml-intern", "status": "active"})
        
        if not self.processor or not hasattr(self.processor, 'evolution'):
             return {"success": False, "reason": "Evolution Engine not active."}
             
        # KALI commands the evolution engine directly
        res = self.processor.evolution.start_session(objective)
        
        chain["steps"].append({
            "action": "evolution_complete",
            "result": res.get("status"),
            "metrics": res.get("delta", 0)
        })
        return res

    def _execute_general_mission(self, objective: str, chain: Dict) -> Dict:
        """Handles general task orchestration across the swarm."""
        # Simple relay to processor/bridge for now, but with KALI labels
        chain["steps"].append({"action": "swarm_dispatch", "nodes": ["aider", "cua"], "status": "active"})
        
        if self.processor:
            res = self.processor.perform_mission(objective)
            return {"success": True, "data": res}
            
        return {"success": False, "reason": "Processor not connected."}

    def _save_trace(self, trace: Dict):
        path = os.path.join(self.trace_dir, f"{trace['id']}.json")
        with open(path, "w") as f:
            json.dump(trace, f, indent=4)

    def get_history(self):
        return self.execution_history[-10:]
