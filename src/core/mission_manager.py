import uuid
import time
import logging
from typing import Dict, Any, List, Optional

class MissionManager:
    """
    Phase 14: The Sovereign Safety Gate.
    Manages high-stakes missions that require Commander Authorization.
    Ensures 'Real Work' is never executed without explicit verification.
    """
    def __init__(self):
        self.logger = logging.getLogger("KALI.MissionManager")
        self.missions: Dict[str, Dict[str, Any]] = {}
        self.history: List[Dict[str, Any]] = []

    def propose_mission(self, goal: str, details: str, risk_level: str = "MEDIUM") -> str:
        """KALI proposes a mission for Commander approval."""
        mission_id = f"MISSION_{uuid.uuid4().hex[:8].upper()}"
        self.missions[mission_id] = {
            "id": mission_id,
            "goal": goal,
            "details": details,
            "risk_level": risk_level,
            "status": "PENDING_AUTHORIZATION",
            "timestamp": time.time(),
            "authorized_by": None
        }
        self.logger.warning(f"MISSION_PROPOSAL: {mission_id} [{risk_level}] - {goal}")
        return mission_id

    def authorize_mission(self, mission_id: str, commander_id: str) -> bool:
        """Commander grants authority to execute the mission."""
        if mission_id in self.missions:
            self.missions[mission_id]["status"] = "AUTHORIZED"
            self.missions[mission_id]["authorized_by"] = commander_id
            self.missions[mission_id]["auth_timestamp"] = time.time()
            self.logger.info(f"MISSION_AUTHORIZED: {mission_id} by {commander_id}")
            return True
        return False

    def reject_mission(self, mission_id: str):
        """Commander denies authority."""
        if mission_id in self.missions:
            self.missions[mission_id]["status"] = "REJECTED"
            self.history.append(self.missions.pop(mission_id))
            return True
        return False

    def get_pending(self) -> List[Dict[str, Any]]:
        """Returns all missions awaiting authorization."""
        return [m for m in self.missions.values() if m["status"] == "PENDING_AUTHORIZATION"]

    def complete_mission(self, mission_id: str, result: str):
        """Mark mission as successful and move to history."""
        if mission_id in self.missions:
            m = self.missions.pop(mission_id)
            m["status"] = "COMPLETED"
            m["result"] = result
            m["end_timestamp"] = time.time()
            self.history.append(m)
            self.logger.info(f"MISSION_COMPLETE: {mission_id}")

    def fail_mission(self, mission_id: str, error: str):
        """Mark mission as failed and move to history."""
        if mission_id in self.missions:
            m = self.missions.pop(mission_id)
            m["status"] = "FAILED"
            m["error"] = error
            m["end_timestamp"] = time.time()
            self.history.append(m)
            self.logger.error(f"MISSION_FAILED: {mission_id} - {error}")
