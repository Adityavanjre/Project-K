import sys
import os
import subprocess
import time
from modules.base import Module

class AiderModule(Module):
    def __init__(self):
        self.name = "aider"

    @property
    def metadata(self):
        return {
            "capabilities": ["code_edit", "refactoring"],
            "cost": 0.5,
            "latency_class": "slow",
            "risk": "CRITICAL"
        }

    def is_available(self) -> bool:
        try:
            env = os.environ.copy()
            aider_path = os.path.abspath(os.path.join(os.getcwd(), "integrations", "aider"))
            env["PYTHONPATH"] = f"{aider_path}{os.pathsep}{env.get('PYTHONPATH', '')}"
            result = subprocess.run([sys.executable, "-m", "aider.main", "--version"], capture_output=True, timeout=2, env=env)
            return result.returncode == 0
        except:
            return False

    def run(self, task: dict, device: str = "cpu") -> dict:
        start_time = time.time()
        try:
            env = os.environ.copy()
            aider_path = os.path.abspath(os.path.join(os.getcwd(), "integrations", "aider"))
            env["PYTHONPATH"] = f"{aider_path}{os.pathsep}{env.get('PYTHONPATH', '')}"
            
            # Aider doesn't strictly support a --device flag, but we can pass it to underlying models
            # if we were configuring specific backends. For now, we respect the hardware hint.
            cmd = [sys.executable, "-m", "aider.main", "--message", task["input"], "--yes"]
            if "context" in task and "files" in task["context"]:
                cmd.extend(task["context"]["files"])

            result = subprocess.run(cmd, capture_output=True, text=True, timeout=300.0, env=env)
            
            return {
                "status": "success" if result.returncode == 0 else "fail",
                "output": result.stdout if result.returncode == 0 else result.stderr,
                "latency": time.time() - start_time,
                "device": device # Report back the device used
            }
        except subprocess.TimeoutExpired:
            return {"status": "fail", "output": "Timeout", "latency": time.time() - start_time, "timeout": True, "device": device}
        except Exception as e:
            return {"status": "fail", "output": str(e), "latency": time.time() - start_time, "device": device}
