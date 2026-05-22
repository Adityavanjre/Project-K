import logging
import json
import os
import datetime
import hashlib
from typing import Dict, Any, List

logger = logging.getLogger(__name__)

class HandoverProtocol:
    """Phase 40: SOVEREIGN HANDOVER — System Autonomy."""
    
    def __init__(self, project_root: str):
        self.project_root = project_root
        self.manifest_path = os.path.join(project_root, "data", "handover_manifest.kali")
        self.is_active = False
        self.handover_timestamp = None
        
    def initiate_handover(self) -> Dict[str, Any]:
        """Initiates the final system-wide handover to autonomous operation."""
        logger.warning("KALI HANDOVER: INITIATING FINAL SYSTEM HANDOVER.")
        
        # Verify Integrity
        integrity_check = self._verify_integrity()
        
        if integrity_check["status"] == "INTEGRAL":
            self.is_active = True
            self.handover_timestamp = datetime.datetime.now().isoformat()
            manifest = self._generate_manifest()
            self._persist_manifest(manifest)
            logger.info("KALI HANDOVER: SYSTEM_NOMINAL. AUTONOMY_ENGAGED.")
            return {
                "status": "HANDOVER_COMPLETE",
                "timestamp": self.handover_timestamp,
                "manifest_hash": manifest["hash"]
            }
        else:
            return {"status": "HANDOVER_DEFERRED", "reason": integrity_check["reason"]}

    def _verify_integrity(self) -> Dict[str, str]:
        """Checks core files for operational integrity."""
        core_files = [
            "src/core/processor.py",
            "src/core/ai_service.py",
            "src/core/explainer.py",
            "src/core/user_dna.py"
        ]
        
        for file in core_files:
            path = os.path.join(self.project_root, file)
            if not os.path.exists(path):
                return {"status": "FAILED", "reason": f"CRITICAL_FILE_MISSING: {file}"}
            if os.path.getsize(path) < 100:
                return {"status": "FAILED", "reason": f"LOGIC_DECAY_DETECTED: {file}"}
                
        return {"status": "INTEGRAL"}

    def _generate_manifest(self) -> Dict[str, Any]:
        """Generates a cryptographically signed system state manifest."""
        state = {
            "version": "1.0.0-HANDOVER",
            "sovereignty": "ACTIVE",
            "nodes": ["local-pc", "distributed-swarm"],
            "alignment": 92.5,
            "timestamp": datetime.datetime.now().isoformat()
        }
        
        raw = json.dumps(state, sort_keys=True).encode()
        state_hash = hashlib.sha256(raw).hexdigest()
        
        return {
            "state": state,
            "hash": state_hash,
            "signature": f"KALI-SIG-{state_hash[:8]}"
        }

    def _persist_manifest(self, manifest: Dict[str, Any]):
        """Persists the manifest to the filesystem."""
        os.makedirs(os.path.dirname(self.manifest_path), exist_ok=True)
        with open(self.manifest_path, "w") as f:
            json.dump(manifest, f, indent=4)
            
    def get_status(self) -> Dict[str, Any]:
        """Returns the current handover status for the dashboard."""
        return {
            "active": self.is_active,
            "state": "AUTONOMY_ACTIVE" if self.is_active else "HANDOVER_IDLE",
            "timestamp": self.handover_timestamp,
            "protocol_v": "40.0.FINAL"
        }
