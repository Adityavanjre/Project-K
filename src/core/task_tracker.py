#!/usr/bin/env python3
"""
KALI TASK TRACKER
Phase 8: Sovereign Skill Autonomy
Persistent state management for multi-stage engineering projects.
"""

import json
import os
import logging
from datetime import datetime
from typing import Dict, Any, List, Optional

class TaskTracker:
    """Manages project progression and autonomous 'Next Steps'."""
    
    def __init__(self, state_path="data/project_status.json"):
        self.logger = logging.getLogger(__name__)
        self.state_path = os.path.abspath(state_path)
        self._init_state()
        self.state = self._load()

    def _init_state(self):
        os.makedirs(os.path.dirname(self.state_path), exist_ok=True)
        if not os.path.exists(self.state_path):
            with open(self.state_path, "w") as f:
                json.dump({"projects": {}, "last_update": None}, f)

    def _load(self) -> Dict[str, Any]:
        with open(self.state_path, "r") as f:
            return json.load(f)

    def _save(self):
        self.state["last_update"] = datetime.now().isoformat()
        with open(self.state_path, "w") as f:
            json.dump(self.state, f, indent=4)

    def update_project(self, name: str, progress: int, status: str, manifest_path: Optional[str] = None):
        """Updates or creates a project entry."""
        if name not in self.state["projects"]:
            self.state["projects"][name] = {
                "created": datetime.now().isoformat(),
                "history": []
            }
            
        proj = self.state["projects"][name]
        proj["progress"] = min(100, max(0, progress))
        proj["status"] = status
        proj["updated"] = datetime.now().isoformat()
        if manifest_path:
            proj["manifest_path"] = manifest_path
            
        proj["history"].append({
            "timestamp": datetime.now().isoformat(),
            "progress": progress,
            "status": status
        })
        self._save()
        self.logger.info(f"Project '{name}' updated to {progress}%, Sir.")

    def get_active_projects(self) -> List[Dict]:
        return [
            {"name": k, **v} for k, v in self.state["projects"].items() if v["progress"] < 100
        ]

    def get_autonomy_report(self) -> str:
        active = self.get_active_projects()
        if not active:
            return "Sir, all laboratory projects are currently 100% complete."
            
        lines = ["=== SOVEREIGN PROJECT STATUS ==="]
        for p in active:
            lines.append(f"[*] {p['name']}: {p['progress']}% | {p['status']}")
            
        return "\n".join(lines)

if __name__ == "__main__":
    tracker = TaskTracker()
    tracker.update_project("Mission 02", 75, "Feedback loop verified.")
    print(tracker.get_autonomy_report())
