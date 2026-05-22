import os
import json
import uuid
import tempfile
import time
from datetime import datetime

class Goal:
    def __init__(self, objective: str, plan: list, goal_id: str = None, status: str = "pending", progress: int = 0, context: dict = None, current_step: int = 0):
        self.id = goal_id or str(uuid.uuid4())[:8]
        self.objective = objective
        self.plan = plan
        # Initialize step status if missing
        for step in self.plan:
            if "status" not in step:
                step["status"] = "pending"
                
        self.status = status
        self.progress = progress
        self.context = context or {}
        self.current_step = current_step
        self.created_at = datetime.now().isoformat()

    def to_dict(self):
        return {
            "id": self.id,
            "objective": self.objective,
            "plan": self.plan,
            "status": self.status,
            "progress": self.progress,
            "context": self.context,
            "current_step": self.current_step,
            "created_at": self.created_at
        }

    @classmethod
    def from_dict(cls, data):
        return cls(
            objective=data["objective"],
            plan=data["plan"],
            goal_id=data["id"],
            status=data["status"],
            progress=data["progress"],
            context=data.get("context", {}),
            current_step=data.get("current_step", 0)
        )

class GoalManager:
    STORAGE_DIR = os.path.join(os.getcwd(), "data", "goals")

    @classmethod
    def save_goal(cls, goal: Goal):
        """Atomic write to prevent corruption."""
        if not os.path.exists(cls.STORAGE_DIR):
            os.makedirs(cls.STORAGE_DIR)
        
        final_path = os.path.join(cls.STORAGE_DIR, f"{goal.id}.json")
        
        # Use a temporary file for atomic write
        fd, temp_path = tempfile.mkstemp(dir=cls.STORAGE_DIR, suffix=".tmp")
        try:
            with os.fdopen(fd, 'w') as f:
                json.dump(goal.to_dict(), f, indent=2)
            # Atomic rename (on Windows, os.replace replaces existing)
            os.replace(temp_path, final_path)
        except Exception as e:
            if os.path.exists(temp_path):
                os.remove(temp_path)
            raise e

    @classmethod
    def load_goal(cls, goal_id: str) -> Goal:
        path = os.path.join(cls.STORAGE_DIR, f"{goal_id}.json")
        if not os.path.exists(path):
            return None
        try:
            with open(path, "r") as f:
                data = json.load(f)
                return Goal.from_dict(data)
        except json.JSONDecodeError:
            print(f"!!! CORRUPTION DETECTED in goal {goal_id}. Attempting recovery...")
            return None # Could add backup restoration here

    @classmethod
    def acquire_lock(cls, goal_id: str) -> bool:
        """Simple file-based lock to prevent concurrent execution."""
        lock_path = os.path.join(cls.STORAGE_DIR, f"{goal_id}.lock")
        if os.path.exists(lock_path):
            # Check if lock is stale (e.g., > 1 hour)
            if time.time() - os.path.getmtime(lock_path) > 3600:
                os.remove(lock_path)
            else:
                return False
        
        with open(lock_path, "w") as f:
            f.write(str(os.getpid()))
        return True

    @classmethod
    def release_lock(cls, goal_id: str):
        lock_path = os.path.join(cls.STORAGE_DIR, f"{goal_id}.lock")
        if os.path.exists(lock_path):
            os.remove(lock_path)

    @classmethod
    def create_goal(cls, objective: str, plan: list) -> Goal:
        goal = Goal(objective, plan)
        cls.save_goal(goal)
        return goal
