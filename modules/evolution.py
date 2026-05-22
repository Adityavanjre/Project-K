import os
import json
import time
import random
from datetime import datetime
from typing import Dict, Any, List
from modules.intelligence import TelemetryStore
from src.core.evolution_validator import EvolutionValidator

class EvolutionEngine:
    """
    KALI EVOLUTION ENGINE — SOVEREIGN v2.0
    The core orchestrator for self-evolution cycles.
    """
    def __init__(self, bridge=None):
        self.bridge = bridge
        self.project_root = os.getcwd()
        self.matrix_path = os.path.join("data", "evolution", "skill_matrix.json")
        self.history_path = os.path.join("data", "evolution", "training_history.json")
        self.is_evolving = False
        self.active_session = None
        self.telemetry = TelemetryStore()
        self.validator = EvolutionValidator(self.project_root)
        
        # Benchmarks library
        self.benchmarks = self.validator.load_benchmarks()
        
        # Ensure directories exist
        os.makedirs(os.path.join("data", "evolution"), exist_ok=True)

    def get_status(self):
        matrix = self._load_matrix()
        return {
            "is_evolving": self.is_evolving,
            "active_session": self.active_session,
            "skill_matrix": matrix.get("domains", {}),
            "benchmarks": self.benchmarks,
            "history": self._load_history()
        }

    def start_session(self, objective: str) -> Dict[str, Any]:
        """
        KALI EVOLUTION: TRAINING_SESSION_INITIALIZATION
        
        Flow: Audit -> Selection -> Training -> Validation -> Knowledge Test -> Memory
        """
        if self.is_evolving:
            return {"status": "fail", "message": "Evolution session already in progress."}

        session_id = f"EVO-{int(time.time())}"
        self.is_evolving = True
        
        session = {
            "id": session_id,
            "objective": objective,
            "status": "initializing",
            "progress": 0,
            "start_time": datetime.now().isoformat(),
            "logs": [],
            "comparisons": [],
            "audit_report": None,
            "knowledge_test": None
        }
        self.active_session = session
        
        try:
            # 1. CODEBASE PURIFICATION (Audit before Training)
            from src.core.self_auditor import SelfAuditor
            auditor = SelfAuditor()
            audit_report = auditor.run_audit()
            session["audit_report"] = audit_report
            self._log("Purification scan complete. " + str(len(audit_report['issues'])) + " issues detected.")
            
            # 2. BENCHMARK SELECTION
            domain = self._resolve_domain(objective)
            benchmark = self._select_benchmark(domain)
            if not benchmark:
                self.is_evolving = False
                return {"status": "fail", "reason": f"No benchmark found for domain: {domain}"}
            
            self._log(f"Selected benchmark: {benchmark['name']} ({benchmark['id']})")
            
            # 3. SWARM & MODEL SELECTION
            specialist = self._select_swarm_specialist(domain)
            model = self._select_model(domain)
            self._log(f"Recruited swarm node: {specialist.upper()} | Model: {model.upper()}")

            # 4. BASELINE BENCHMARK
            self._log("Calculating baseline performance...")
            baseline_score = self.validator.score_execution(benchmark["input"], benchmark["test_script"])
            self._log(f"Baseline Score: {baseline_score['score']} | Perf: {baseline_score['time']:.4f}s")
            
            # 5. TRAINING (SWARM IMPROVEMENT)
            self._log(f"Swarm node [{specialist}] is generating improvements...")
            improvement_task = {
                "command": "improve",
                "params": {
                    "code": benchmark["input"],
                    "goal": benchmark["goal"],
                    "domain": domain,
                    "model": model
                }
            }
            improved_res = self.bridge.execute({"type": specialist, "input": json.dumps(improvement_task)})
            
            if improved_res.get("status") != "success":
                session["status"] = "failed"
                self.is_evolving = False
                return {"status": "fail", "reason": "Swarm improvement failed."}

            improved_code = improved_res.get("output", "")
            
            # 6. VALIDATION BENCHMARK
            self._log("Validating improved version...")
            validation_score = self.validator.score_execution(improved_code, benchmark["test_script"])
            self._log(f"Validation Score: {validation_score['score']} | Perf: {validation_score['time']:.4f}s")
            
            # 7. COMPARISON & DECISION
            delta = validation_score["score"] - baseline_score["score"]
            perf_gain = baseline_score["time"] - validation_score["time"]
            
            session["comparisons"].append({
                "benchmark": benchmark["name"],
                "baseline": baseline_score,
                "improved": validation_score,
                "delta": delta,
                "perf_gain": perf_gain
            })

            if delta > 0 or (delta == 0 and perf_gain > 0.001):
                self._log(f"Evolution COMMITTED: Improvement of {delta:.2f} detected (Perf Gain: {perf_gain:.4f}s)")
                session["status"] = "committed"
                self.validator.record_memory(domain, improved_code, "COMMIT", {"improvement": delta, "perf_gain": perf_gain})
                self._update_skill(domain, 0.1)
                
                # 8. KNOWLEDGE TEST (Verification of Retention)
                self._log("Executing follow-up KNOWLEDGE TEST...")
                knowledge_test = self.validator.score_execution(improved_code, benchmark["test_script"])
                session["knowledge_test"] = knowledge_test
                self._log(f"Knowledge Test: {'PASSED' if knowledge_test['success'] else 'FAILED'}")
            else:
                self._log("Evolution REJECTED: Degradation detected. Rolling back learning.")
                session["status"] = "rolled_back"
                self.validator.record_memory(domain, improved_code, "ROLLBACK", {"improvement": delta, "perf_gain": perf_gain, "reason": "Degradation detected"})

            session["progress"] = 100
            self._save_history(session)
            self.is_evolving = False
            return session

        except Exception as e:
            print(f"EVOLUTION_ERROR: {e}")
            session["status"] = "error"
            session["error"] = str(e)
            self.is_evolving = False
            return session

    def _resolve_domain(self, objective: str) -> str:
        mapping = {
            "Coding": "coding",
            "Debugging": "debugging",
            "Architecture": "architecture",
            "UI/UX": "ui_ux",
            "Backend": "backend"
        }
        return mapping.get(objective, "coding")

    def _select_benchmark(self, domain: str) -> Dict:
        if domain not in self.benchmarks or not self.benchmarks[domain]:
            return None
        return random.choice(self.benchmarks[domain])

    def _select_swarm_specialist(self, domain: str) -> str:
        mapping = {
            "coding": "aider",
            "debugging": "no_mistakes",
            "architecture": "graphify",
            "ui_ux": "easy_vibe",
            "backend": "wrkflw"
        }
        return mapping.get(domain, "aider")

    def _select_model(self, domain: str) -> str:
        map_path = os.path.join("data", "evolution", "model_map.json")
        if os.path.exists(map_path):
            with open(map_path, "r") as f:
                model_map = json.load(f)
            for name, info in model_map["models"].items():
                if domain in info["domains"]:
                    return name
        return "deepseek-coder-v2"

    def _update_skill(self, domain: str, delta: float):
        matrix = self._load_matrix()
        if "domains" not in matrix: matrix["domains"] = {}
        if domain not in matrix["domains"]:
            matrix["domains"][domain] = {"level": 1, "score": 0.0}
        
        matrix["domains"][domain]["score"] = min(1.0, matrix["domains"][domain]["score"] + delta)
        if matrix["domains"][domain]["score"] >= 1.0:
            matrix["domains"][domain]["level"] += 1
            matrix["domains"][domain]["score"] = 0.0
        
        matrix["timestamp"] = datetime.now().isoformat()
        with open(self.matrix_path, "w") as f:
            json.dump(matrix, f, indent=4)

    def _log(self, message):
        entry = {"timestamp": datetime.now().isoformat(), "message": message}
        print(f"[EVOLUTION] {message}")
        if self.active_session:
            self.active_session["logs"].append(entry)
        if self.bridge:
            self.bridge.emit_event("evolution_log", entry)

    def _load_matrix(self):
        if not os.path.exists(self.matrix_path):
            return {"domains": {}}
        try:
            with open(self.matrix_path, "r") as f:
                return json.load(f)
        except:
            return {"domains": {}}

    def _load_history(self):
        if not os.path.exists(self.history_path):
            return []
        try:
            with open(self.history_path, "r") as f:
                return json.load(f)
        except:
            return []

    def _save_history(self, session):
        history = self._load_history()
        history.append(session)
        history = history[-50:]
        with open(self.history_path, "w") as f:
            json.dump(history, f, indent=4)
