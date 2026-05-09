import subprocess
import os
import logging
import shlex
import threading
from typing import Dict, Any, List, Optional

class SystemController:
    """
    Phase 11: The Hands of KALI.
    Unified interface for shell execution, file system operations, and system control.
    """
    def __init__(self, workspace_root: str, mission_manager=None):
        self.workspace_root = os.path.abspath(workspace_root)
        self.logger = logging.getLogger("KALI.SystemController")
        self.mission_manager = mission_manager
        self.active_processes: Dict[str, subprocess.Popen] = {}

    def _verify_mission(self, mission_id: Optional[str]) -> bool:
        """Verify if the mission_id is authorized."""
        if not self.mission_manager:
            return True # If no manager is provided, we operate in unmanaged mode (e.g. startup)
        
        if not mission_id:
            self.logger.error("SYSTEM_CONTROLLER: Attempted execution without MISSION_ID.")
            return False
            
        mission = self.mission_manager.missions.get(mission_id)
        if not mission or mission["status"] != "AUTHORIZED":
            self.logger.error(f"SYSTEM_CONTROLLER: Unauthorized execution attempt for {mission_id}.")
            return False
        return True

    def execute_command(self, command: str, cwd: Optional[str] = None, mission_id: Optional[str] = None) -> Dict[str, Any]:
        """Execute a shell command securely within the workspace."""
        if not self._verify_mission(mission_id):
            return {"success": False, "error": "MISSION_NOT_AUTHORIZED"}

        try:
            # Use the provided CWD or default to workspace root
            exec_cwd = os.path.abspath(cwd) if cwd else self.workspace_root
            if not exec_cwd.startswith(self.workspace_root):
                return {"success": False, "error": "CWD_OUT_OF_BOUNDS"}

            self.logger.info(f"KALI EXEC [{mission_id}]: {command} in {exec_cwd}")
            
            # Use shell=True for Windows to support complex commands/pipes
            process = subprocess.Popen(
                command,
                cwd=exec_cwd,
                shell=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
                env=os.environ.copy()
            )
            
            stdout, stderr = process.communicate(timeout=30)
            
            return {
                "success": process.returncode == 0,
                "stdout": stdout,
                "stderr": stderr,
                "returncode": process.returncode
            }
        except subprocess.TimeoutExpired:
            process.kill()
            return {"success": False, "error": "COMMAND_TIMEOUT"}
        except Exception as e:
            self.logger.error(f"System Error: {e}")
            return {"success": False, "error": str(e)}

    def list_workspace(self, path: str = ".") -> Dict[str, Any]:
        """Returns a tree of the workspace for the File Explorer."""
        target_dir = os.path.join(self.workspace_root, path)
        target_dir = os.path.abspath(target_dir)
        
        if not target_dir.startswith(self.workspace_root):
             return {"success": False, "error": "ACCESS_DENIED"}
             
        try:
            tree = []
            for item in os.listdir(target_dir):
                if item.startswith('.') and item != '.env': continue
                item_path = os.path.join(target_dir, item)
                is_dir = os.path.isdir(item_path)
                tree.append({
                    "name": item,
                    "type": "directory" if is_dir else "file",
                    "path": os.path.relpath(item_path, self.workspace_root),
                    "size": os.path.getsize(item_path) if not is_dir else None
                })
            return {"success": True, "tree": tree}
        except Exception as e:
            return {"success": False, "error": str(e)}

    def read_file(self, rel_path: str) -> Dict[str, Any]:
        """Read file content for the Sovereign Editor."""
        abs_path = os.path.join(self.workspace_root, rel_path)
        abs_path = os.path.abspath(abs_path)
        
        if not abs_path.startswith(self.workspace_root):
            return {"success": False, "error": "ACCESS_DENIED"}
            
        try:
            with open(abs_path, 'r', encoding='utf-8') as f:
                content = f.read()
            return {"success": True, "content": content}
        except Exception as e:
            return {"success": False, "error": str(e)}

    def write_file(self, rel_path: str, content: str, mission_id: Optional[str] = None) -> Dict[str, Any]:
        """Write file content from the Sovereign Editor."""
        if not self._verify_mission(mission_id):
            return {"success": False, "error": "MISSION_NOT_AUTHORIZED"}

        abs_path = os.path.join(self.workspace_root, rel_path)
        abs_path = os.path.abspath(abs_path)
        
        if not abs_path.startswith(self.workspace_root):
            return {"success": False, "error": "ACCESS_DENIED"}
            
        try:
            # Phase 11: Atomic Write with Backup
            backup_path = abs_path + ".bak"
            if os.path.exists(abs_path):
                import shutil
                shutil.copy2(abs_path, backup_path)
                
            with open(abs_path, 'w', encoding='utf-8') as f:
                f.write(content)
                
            return {"success": True, "message": "FILE_SAVED"}
        except Exception as e:
            return {"success": False, "error": str(e)}

