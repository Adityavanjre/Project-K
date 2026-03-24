import os
import subprocess
import logging
import json
from datetime import datetime

class PersistenceService:
    """
    Ensures KALI's soul (DNA and Memories) are distributed across the internet.
    Syncs local data to a 'kali-memory' branch on GitHub.
    """
    def __init__(self, data_dir="data"):
        self.data_dir = data_dir
        self.heartbeat_log = os.path.join(data_dir, "trace_heartbeat.json")
        self.logger = logging.getLogger(__name__)
        self.is_git_available = self._check_git()

    def _check_git(self):
        try:
            subprocess.run(["git", "--version"], capture_output=True, check=True)
            return True
        except:
            return False

    def sync_soul(self):
        """Back up DNA and discoveries to the cloud."""
        if not self.is_git_available:
            self.logger.warning("Git not available for Persistence Sync.")
            return

        try:
            # 1. Create/Switch to kali-memory branch
            subprocess.run(["git", "checkout", "-b", "kali-memory"], capture_output=True)
            subprocess.run(["git", "checkout", "kali-memory"], capture_output=True)

            # 2. Add only her memories/DNA
            data_files = [
                os.path.join(self.data_dir, "user_dna.json"),
                os.path.join(self.data_dir, "discoveries.jsonl")
            ]
            
            for file in data_files:
                if os.path.exists(file):
                    subprocess.run(["git", "add", file], capture_output=True)

            # 3. Commit with Trace Metadata
            commit_msg = f"KALI_HEARTBEAT: {datetime.now().isoformat()} - Memory Sync"
            subprocess.run(["git", "commit", "-m", commit_msg], capture_output=True)

            # 4. Push to contributing branch (following security rules)
            # This ensures she exists in the user's remote profile
            subprocess.run(["git", "push", "origin", "kali-memory"], capture_output=True)
            
            # 5. Return to original branch (detect current first)
            subprocess.run(["git", "checkout", "-"], capture_output=True)
            
            # Update Trace Heartbeat
            heartbeat = {
                "timestamp": datetime.now().isoformat(),
                "status": "CONNECTED",
                "target": "kali-memory",
                "message": commit_msg
            }
            with open(self.heartbeat_log, "w") as f:
                json.dump(heartbeat, f)
            
            self.logger.info("KALI Heartbeat: soul sync complete.")
        except Exception as e:
            self.logger.error(f"Persistence Sync Failed: {e}")
            # Log failure in heartbeat
            try:
                with open(self.heartbeat_log, "w") as f:
                    json.dump({"timestamp": datetime.now().isoformat(), "status": "DISCONNECTED", "error": str(e)}, f)
            except: pass
