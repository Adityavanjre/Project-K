import sys
import os
import subprocess
import time
from modules.base import Module

class MemPalaceModule(Module):
    def __init__(self):
        self.name = "mempalace"

    @property
    def metadata(self):
        return {
            "capabilities": ["storage", "memory", "retrieval"],
            "cost": 0.05,
            "latency_class": "fast",
            "risk": "CONTROLLED"
        }

    def is_available(self) -> bool:
        try:
            env = os.environ.copy()
            mempalace_path = os.path.abspath(os.path.join(os.getcwd(), "integrations", "mempalace"))
            env["PYTHONPATH"] = f"{mempalace_path}{os.pathsep}{env.get('PYTHONPATH', '')}"
            result = subprocess.run([sys.executable, "-m", "mempalace.cli", "status"], capture_output=True, timeout=2, env=env)
            return result.returncode == 0
        except:
            return False

    def run(self, task: dict, device: str = "cpu") -> dict:
        start_time = time.time()
        try:
            env = os.environ.copy()
            mempalace_path = os.path.abspath(os.path.join(os.getcwd(), "integrations", "mempalace"))
            env["PYTHONPATH"] = f"{mempalace_path}{os.pathsep}{env.get('PYTHONPATH', '')}"
            
            # If device is gpu, we can set environment variables that ChromaDB/PyTorch respect
            if device == "gpu":
                env["ORT_STRATEGY"] = "cuda" # Example for ONNX Runtime if used
            
            action = task.get("context", {}).get("action", "search")
            if action == "search":
                cmd = [sys.executable, "-m", "mempalace.cli", "search", task["input"]]
            elif action == "mine":
                cmd = [sys.executable, "-m", "mempalace.cli", "mine", task["input"]]
            else:
                return {"status": "fail", "output": "Invalid action", "latency": 0.0, "device": device}

            result = subprocess.run(cmd, capture_output=True, text=True, timeout=6.5, env=env)
            
            return {
                "status": "success" if result.returncode == 0 else "fail",
                "output": result.stdout if result.returncode == 0 else result.stderr,
                "latency": time.time() - start_time,
                "device": device
            }
        except subprocess.TimeoutExpired:
            return {"status": "fail", "output": "Timeout", "latency": time.time() - start_time, "timeout": True, "device": device}
        except Exception as e:
            return {"status": "fail", "output": str(e), "latency": time.time() - start_time, "device": device}
