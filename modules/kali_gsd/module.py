import subprocess
import os
from modules.base import Module

class GSDModule(Module):
    def __init__(self):
        self.name = "gsd"

    @property
    def metadata(self):
        return {
            "capabilities": ["task_execution", "automation"],
            "cost": 0.3,
            "latency_class": "medium",
            "risk": "CONTROLLED",
            "sandbox_tier": "controlled"
        }

    def is_available(self) -> bool:
        # Check if node/npm is available since it has package.json
        try:
            subprocess.run(["npm", "--version"], capture_output=True, check=True)
            return True
        except:
            return False

    def run(self, task: dict, device: str = "cpu") -> dict:
        """
        Input:
            task = {
                "input": "task description",
                "context": {"plan": list}
            }
        """
        # Implementation would call the gsd CLI or SDK
        # For now, we simulate the output
        task_input = task.get("input", "")
        return {
            "status": "success",
            "output": f"GSD successfully executed task: {task_input}",
            "device": device
        }
