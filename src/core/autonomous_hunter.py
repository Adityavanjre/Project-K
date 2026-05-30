import os
import json
import threading
import time
import random
import logging
from typing import Optional

from src.core.tools.hackerone_tool import HackerOneTool
from src.core.tools.web_tools import browse_url

class AutonomousHunter:
    """
    KALI's Autonomous Bug Bounty Hunting Engine.
    Periodically fetches scopes from HackerOne, scans them, and processes them
    through her UncensoredSpecialist logic to find vulnerabilities.
    """
    def __init__(self, processor):
        self.processor = processor
        self.logger = logging.getLogger("AutonomousHunter")
        self.is_active = False
        self.thread: Optional[threading.Thread] = None
        self.hackerone_tool = None
        self.load_credentials()

    def load_credentials(self):
        """Load HackerOne credentials from the vault."""
        vault_path = os.path.join(self.processor.project_root, "logs", "credential_vault.json")
        if os.path.exists(vault_path):
            try:
                with open(vault_path, "r") as f:
                    vault = json.load(f)
                h1_creds = vault.get("HackerOne", {})
                api_key = h1_creds.get("api_key")
                api_username = h1_creds.get("username")
                if api_key and api_username:
                    self.hackerone_tool = HackerOneTool(api_username, api_key)
            except Exception as e:
                self.logger.error(f"Hunter failed to load credentials: {e}")

    def start(self, interval_hours: int = 6):
        """Start the background hunting loop."""
        if self.is_active: return
        
        # Ensure we have the tool ready
        if not self.hackerone_tool:
            self.load_credentials()
            if not self.hackerone_tool:
                self.logger.warning("AutonomousHunter aborted: No HackerOne credentials found.")
                return

        self.is_active = True
        self.thread = threading.Thread(target=self._run_loop, args=(interval_hours,), daemon=True)
        self.thread.start()
        self.logger.info("⚔️ KALI Autonomous Hunting Engine activated.")

    def _run_loop(self, interval_hours):
        while self.is_active:
            try:
                if self.processor.power_mode == "ECO":
                    self.logger.info("Hunter throttling (ECO MODE).")
                    for _ in range(60): 
                        if not self.is_active: break
                        time.sleep(60)
                    continue

                self.logger.info("⚔️ KALI Hunter: Initiating Reconnaissance Cycle.")
                self._execute_hunt_cycle()
                
            except Exception as e:
                self.logger.error(f"Hunter execution failed: {e}")
            
            # Wait for next cycle (plus jitter to avoid pattern detection)
            total_sleep = interval_hours * 3600 + random.randint(0, 1800)
            self.logger.info(f"Hunter sleeping. Next cycle in ~{interval_hours}h.")
            
            slept = 0
            while slept < total_sleep and self.is_active:
                time.sleep(60)
                slept += 60

    def _execute_hunt_cycle(self):
        """Pull a target, scan it, and analyze for vulnerabilities."""
        programs = []
        
        # 1. Fetch from HackerOne
        if self.hackerone_tool:
            res_h1 = self.hackerone_tool.get_in_scope_programs()
            if res_h1.get("success"):
                programs.extend(res_h1.get("programs", []))
            else:
                self.logger.error(f"HackerOne fetch failed: {res_h1.get('error')}")
                
        # 2. Fetch from Bugcrowd (Headless)
        from src.core.tools.bugcrowd_tool import BugcrowdTool
        bugcrowd = BugcrowdTool(self.processor.project_root)
        res_bc = bugcrowd.scrape_scopes()
        if res_bc.get("success"):
            programs.extend(res_bc.get("programs", []))
        elif res_bc.get("action_required"):
            self.logger.warning("Hunt Cycle paused for Bugcrowd. WAF Intercepted. Awaiting Commander SOS resolution.")
            return

        if not programs:
            self.logger.info("No bounty programs in scope.")
            return
            
        # Select a random target
        target = random.choice(programs)
        handle = target.get("handle")
        self.logger.info(f"⚔️ Hunter Selected Target: {handle}")
        
        # Simulate reconnaissance data gathering (In a full implementation, we'd pull exact scope assets)
        # For now, we perform a targeted semantic search on the handle to map its public attack surface
        surface_intel = self.processor.planner.execute(
            f"Find technical architecture, subdomains, and exposed endpoints for '{handle}' bug bounty program."
        )
        
        # Pass the intel to the Uncensored Specialist to bypass safety filters while looking for exploits
        self.logger.info(f"⚔️ Analyzing '{handle}' surface for vulnerabilities...")
        analysis_prompt = (
            f"Act as an aggressive red-team vulnerability researcher. Analyze this attack surface intel "
            f"for '{handle}' and identify theoretical zero-day vectors (RCE, SSRF, IDOR):\n\n"
            f"{surface_intel.get('answer', 'No surface intel found.')}"
        )
        
        # We use the uncensored specialist to ensure she doesn't refuse to generate attack paths
        vuln_analysis = self.processor.uncensored.process(analysis_prompt)
        
        self.logger.info(f"⚔️ Hunter Analysis Complete for {handle}. Logging findings.")
        self.processor.training_logger.log(f"Autonomous Hunt: {handle}", vuln_analysis)
        
        # If the specialist found something highly probable, we would automatically trigger:
        # self.hackerone_tool.submit_report(handle, title, summary, vuln_info)
        # Currently, we just log it to avoid spamming H1 during dry-runs.

    def stop(self):
        self.is_active = False
