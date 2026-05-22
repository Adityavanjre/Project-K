import subprocess
import os
from modules.base import Module

class GitNexusModule(Module):
    def __init__(self):
        self.name = "gitnexus"

    @property
    def metadata(self):
        return {
            "capabilities": ["vcs", "repo_management"],
            "cost": 0.2,
            "latency_class": "medium",
            "risk": "CRITICAL"
        }

    def is_available(self) -> bool:
        try:
            subprocess.run(["git", "--version"], capture_output=True, check=True)
            return True
        except:
            return False

    def run(self, task: dict, device: str = "cpu") -> dict:
        """
        Input:
            task = {
                "input": "commit message" | "status" | "diff",
                "context": {"repo_path": str}
            }
        """
        repo_path = task.get("context", {}).get("repo_path", os.getcwd())
        action = task.get("input", "").lower()
        
        try:
            if "status" in action:
                res = subprocess.run(["git", "status"], cwd=repo_path, capture_output=True, text=True)
                return {"status": "success", "output": res.stdout, "device": device}
            
            elif "commit" in action:
                # Naive implementation: add all and commit
                msg = action.replace("commit", "").strip() or "KALI auto-commit"
                subprocess.run(["git", "add", "."], cwd=repo_path, check=True)
                res = subprocess.run(["git", "commit", "-m", msg], cwd=repo_path, capture_output=True, text=True)
                return {"status": "success", "output": res.stdout, "device": device}
            
            elif "diff" in action:
                res = subprocess.run(["git", "diff"], cwd=repo_path, capture_output=True, text=True)
                return {"status": "success", "output": res.stdout or "No changes.", "device": device}
            
            else:
                return {"status": "fail", "output": f"Unsupported git action: {action}", "device": device}
                
        except subprocess.CalledProcessError as e:
            return {
                "status": "fail", 
                "output": e.stderr or str(e), 
                "reason": "Git command failed",
                "device": device
            }
        except Exception as e:
            return {"status": "fail", "output": str(e), "device": device}
