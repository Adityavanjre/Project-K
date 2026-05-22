import os
import json
import logging
from datetime import datetime
import asyncio
from typing import Dict, Any, List

from src.core.config_manager import config

class KALIAgent:
    """
    KALI Sovereign ASI Core Agent.
    Strict Rule: All autonomous actions (Browsing, Pushing, Creating) must originate here.
    """
    def __init__(self, workspace_root: str):
        # If workspace_root ends with 'src', use its parent
        if workspace_root.endswith('src') or workspace_root.endswith('src\\') or workspace_root.endswith('src/'):
            self.workspace_root = os.path.dirname(workspace_root)
        else:
            self.workspace_root = workspace_root
        
        self.logger = logging.getLogger("KALI_CORE")
        self.vault_path = os.path.join(self.workspace_root, "logs", "credential_vault.json")
        self.missions_path = os.path.join(self.workspace_root, "logs", "mission_history.json")
        self._ensure_paths()
        
        # 🔱 SOVEREIGN REGISTRY: Unified Log Endpoint
        self.log_api_url = f"{config.get('sovereign.internal.base_url')}:{config.get('api.port')}/api/kali/log"

    def _ensure_paths(self):
        os.makedirs(os.path.dirname(self.vault_path), exist_ok=True)
        if not os.path.exists(self.missions_path):
            with open(self.missions_path, "w") as f:
                json.dump([], f)

    def log_mission(self, directive: str, status: str, result: Any = None):
        """Record a mission in the Sovereign Ledger."""
        mission = {
            "timestamp": datetime.now().isoformat(),
            "directive": directive,
            "status": status,
            "result": result
        }
        with open(self.missions_path, "r+") as f:
            history = json.load(f)
            history.append(mission)
            f.seek(0)
            json.dump(history, f, indent=4)
        
        # Also log to the web app for real-time visibility
        try:
            import requests
            requests.post(self.log_api_url, json={
                "message": f"MISSION_{status}: {directive[:50]}...",
                "level": "SUCCESS" if status == "COMPLETED" else "INFO"
            })
        except:
            pass

    async def browse(self, url: str, task: str) -> Dict[str, Any]:
        """KALI autonomously browses the internet."""
        self.log_mission(f"BROWSE: {url} ({task})", "STARTED")
        
        # This will use the Playwright module once installed
        try:
            from playwright.async_api import async_playwright
            async with async_playwright() as p:
                browser = await p.chromium.launch(headless=True)
                page = await browser.new_page()
                await page.goto(url)
                # Task execution logic here
                await browser.close()
            
            self.log_mission(f"BROWSE: {url}", "COMPLETED")
            return {"success": True, "message": "Browsing complete."}
        except Exception as e:
            self.log_mission(f"BROWSE: {url}", "FAILED", str(e))
            return {"success": False, "error": str(e)}

    def create(self, file_path: str, content: str):
        """KALI autonomously creates/modifies files."""
        self.log_mission(f"CREATE: {file_path}", "STARTED")
        full_path = os.path.join(self.workspace_root, file_path)
        os.makedirs(os.path.dirname(full_path), exist_ok=True)
        with open(full_path, "w", encoding="utf-8") as f:
            f.write(content)
        self.log_mission(f"CREATE: {file_path}", "COMPLETED")

    def sync_wealth(self, amount: float, platform: str):
        """KALI autonomously updates her wealth matrix."""
        self.log_mission(f"SYNC_WEALTH: {amount} via {platform}", "STARTED")
        # Update dashboard state
        try:
            import requests
            requests.post(self.log_api_url, json={
                "message": f"WEALTH_SYNC: +${amount} from {platform}",
                "level": "SUCCESS"
            })
        except:
            pass
        self.log_mission(f"SYNC_WEALTH: {amount}", "COMPLETED")

if __name__ == "__main__":
    # Test initialization
    kali = KALIAgent(os.getcwd())
    print("KALI Core Agent Online.")
