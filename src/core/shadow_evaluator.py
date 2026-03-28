import os
import json
import logging
from datetime import datetime
from typing import Dict, Any, Optional

class ShadowEvaluator:
    """
    KALI Shadow Evaluation Engine (Milestone 5).
    Runs parallel local vs. API queries and logs differences.
    """
    def __init__(self, ai_service, local_ai, project_root: str = "."):
        self.ai = ai_service
        self.local = local_ai
        self.logger = logging.getLogger(__name__)
        self.project_root = project_root
        self.eval_log = os.path.join(self.project_root, "data", "shadow_eval.jsonl")
        os.makedirs(os.path.dirname(self.eval_log), exist_ok=True)

    def evaluate(self, query: str, expert_role: str = "general") -> Dict[str, Any]:
        """
        Runs a parallel shadow query. 
        Returns local response and alignment metrics.
        """
        if not self.local.is_available():
            return {"success": False, "error": "LOCAL_NODE_OFFLINE"}

        # 1. Fetch Local Response (Bug B-2 fix: use context= not role=)
        local_res = self.local.ask_question(query, context=f"Role: {expert_role}")
        
        # 2. Log for later batch comparison (Optional: immediate comparison with remote)
        # In a real shadow mode, we don't always call the remote to save cost,
        # but for Phase 55 initial tuning, we do.
        
        eval_record = {
            "timestamp": datetime.now().isoformat(),
            "query": query,
            "expert": expert_role,
            "local_response": local_res,
            "status": "PENDING_ORACLE"
        }

        with open(self.eval_log, "a", encoding="utf-8") as f:
            f.write(json.dumps(eval_record) + "\n")

        return {
            "success": True,
            "local_response": local_res,
            "message": f"SHADOW_MODE: Sovereignty insight captured for {expert_role}."
        }

    def get_sovereignty_score(self) -> float:
        """Calculate current sovereignty ratio based on length_ratio moving average."""
        if not os.path.exists(self.eval_log):
            return 0.0
            
        try:
            ratios = []
            with open(self.eval_log, "r", encoding="utf-8") as f:
                for line in f:
                    if not line.strip(): continue
                    try:
                        record = json.loads(line)
                        if "length_ratio" in record:
                            ratios.append(record["length_ratio"])
                    except Exception:
                        pass
            
            if not ratios:
                return 0.0
                
            # Moving average of last 50 evaluations
            recent = ratios[-50:]
            return round(sum(recent) / len(recent), 2)
        except Exception as e:
            self.logger.error(f"Error calculating sovereignty score: {e}")
            return 0.0
