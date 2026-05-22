import os
import json
import time
import subprocess
import traceback
from datetime import datetime

class EvolutionValidator:
    def __init__(self, project_root):
        self.project_root = project_root
        self.benchmarks_path = os.path.join(project_root, "data", "evolution", "benchmarks.json")
        self.memory_path = os.path.join(project_root, "data", "evolution", "evolution_memory.json")
        self._ensure_memory()

    def _ensure_memory(self):
        if not os.path.exists(self.memory_path):
            with open(self.memory_path, "w") as f:
                json.dump({"successful_patterns": [], "failed_patterns": [], "heuristics": {}}, f, indent=4)

    def load_benchmarks(self):
        if not os.path.exists(self.benchmarks_path):
            return {}
        with open(self.benchmarks_path, "r") as f:
            return json.load(f)

    def score_execution(self, code: str, test_script: str) -> dict:
        """
        Executes a specific test script against code.
        """
        try:
            full_script = f"{code}\n\n{test_script}\n\nprint(json.dumps(test(transform if 'transform' in locals() else read_logs if 'read_logs' in locals() else None)))"
            
            temp_file = "temp_evo_test.py"
            with open(temp_file, "w") as f:
                f.write("import json\nimport os\nimport time\n" + full_script)
            
            start = time.time()
            result = subprocess.run(["python", temp_file], capture_output=True, text=True, timeout=10)
            end = time.time()
            
            if os.path.exists(temp_file):
                os.remove(temp_file)
            
            if result.returncode != 0:
                return {"success": False, "score": 0.0, "time": end - start, "error": result.stderr}
            
            output = json.loads(result.stdout.strip())
            return {
                "success": output.get("success", False),
                "score": 1.0 if output.get("success") else 0.0,
                "time": output.get("time", end - start),
                "status": "Success"
            }
        except Exception as e:
            return {"success": False, "score": 0.0, "time": 0.0, "error": str(e)}

    def compare_evolution(self, test_script: str, before_code: str, after_code: str):
        """
        Compares before and after versions.
        Ensures NO degradation.
        """
        res_before = self.score_execution(before_code, test_script)
        res_after = self.score_execution(after_code, test_script)
        
        improvement = res_after["score"] - res_before["score"]
        perf_gain = (res_before["time"] - res_after["time"]) if res_before["time"] and res_after["time"] else 0
        
        # ROLLBACK LOGIC: If score decreases or performance drops significantly
        if improvement < 0 or (improvement == 0 and perf_gain < -0.1):
            return False, {
                "improvement": improvement,
                "perf_gain": perf_gain,
                "decision": "ROLLBACK",
                "reason": "Degradation detected"
            }
        
        return True, {
            "improvement": improvement,
            "perf_gain": perf_gain,
            "decision": "COMMIT",
            "reason": "Stable or Improved"
        }

    def record_memory(self, pattern_type, code, status, metrics):
        with open(self.memory_path, "r") as f:
            memory = json.load(f)
        
        entry = {
            "timestamp": datetime.now().isoformat(),
            "code": code,
            "metrics": metrics
        }
        
        if status == "COMMIT":
            memory["successful_patterns"].append(entry)
        else:
            memory["failed_patterns"].append(entry)
            
        with open(self.memory_path, "w") as f:
            json.dump(memory, f, indent=4)
