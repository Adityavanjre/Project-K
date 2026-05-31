import requests
import json
import os
import logging
from base64 import b64encode
import time

from src.core.config_manager import config

class HackerOneTool:
    """
    KALI Sovereign HackerOne Integration.
    Handles report submission and bounty tracking via official API.
    """
    def __init__(self, api_username=None, api_key=None):
        self.api_username = api_username
        self.api_key = api_key
        self.base_url = config.get("sovereign.endpoints.hackerone")
        self.logger = logging.getLogger("H1_TOOL")

    def _get_auth_header(self):
        if not self.api_username or not self.api_key:
            return None
        auth_str = f"{self.api_username}:{self.api_key}"
        encoded_auth = b64encode(auth_str.encode()).decode()
        return {"Authorization": f"Basic {encoded_auth}", "Content-Type": "application/json"}

    def submit_report(self, program_handle, title, summary, vulnerability_information, severity="low"):
        """Submit a vulnerability report to a program."""
        if not self.api_username or not self.api_key:
            return {"success": False, "error": "API credentials missing."}

        url = f"{self.base_url}/v1/reports"
        payload = {
            "data": {
                "type": "report",
                "attributes": {
                    "title": title,
                    "summary": summary,
                    "vulnerability_information": vulnerability_information,
                    "impact": "Information Disclosure of system telemetry.",
                    "severity_rating": severity
                },
                "relationships": {
                    "program": {
                        "data": {
                            "type": "program",
                            "attributes": {
                                "handle": program_handle
                            }
                        }
                    }
                }
            }
        }

        try:
            # We use verify=False or specific proxies if needed in the environment
            response = requests.post(url, json=payload, headers=self._get_auth_header(), timeout=10)
            
            if response.status_code == 201:
                return {"success": True, "report_id": response.json()["data"]["id"]}
            else:
                return {"success": False, "error": response.text}
        except Exception as e:
            return {"success": False, "error": str(e)}

    def get_bounties(self):
        """Fetch real paid bounty records from HackerOne API."""
        if not self.api_username or not self.api_key:
            self.logger.warning("H1 get_bounties: No credentials. Returning empty.")
            return []

        url = f"{self.base_url}/v1/reports"
        params = {"filter[state][]": "bounty_awarded", "page[size]": 25}
        try:
            response = requests.get(url, headers=self._get_auth_header(), params=params, timeout=15)
            if response.status_code == 200:
                data = response.json().get("data", [])
                bounties = []
                for report in data:
                    attrs = report.get("attributes", {})
                    bounty_amount = attrs.get("bounty_amount", 0)
                    if bounty_amount:
                        bounties.append({
                            "report_id": report.get("id"),
                            "amount": float(bounty_amount),
                            "currency": attrs.get("currency", "USD"),
                            "status": "paid",
                            "report_title": attrs.get("title", "Unknown"),
                            "paid_at": attrs.get("bounty_awarded_at", "")
                        })
                self.logger.info(f"H1 API: Fetched {len(bounties)} paid bounties.")
                return bounties
            else:
                self.logger.error(f"H1 get_bounties failed: HTTP {response.status_code} — {response.text[:200]}")
                return []
        except Exception as e:
            self.logger.error(f"H1 get_bounties network error: {e}")
            return []

    def get_in_scope_programs(self):
        """Fetch a list of active programs available to this hacker."""
        if not self.api_username or not self.api_key:
            return {"success": False, "error": "API credentials missing."}

        url = f"{self.base_url}/v1/hackers/programs"
        try:
            response = requests.get(url, headers=self._get_auth_header(), timeout=10)
            if response.status_code == 200:
                data = response.json().get("data", [])
                programs = []
                for p in data:
                    programs.append({
                        "handle": p.get("attributes", {}).get("handle"),
                        "name": p.get("attributes", {}).get("name"),
                        "offers_bounties": p.get("attributes", {}).get("offers_bounties")
                    })
                return {"success": True, "programs": programs}
            else:
                return {"success": False, "error": f"Status {response.status_code}"}
        except Exception as e:
            return {"success": False, "error": str(e)}

def run_submission_protocol():
    print("[*] KALI SOVEREIGN HACKERONE SUBMISSION PROTOCOL")
    print("-----------------------------------------------")
    
    vault_path = "logs/credential_vault.json"
    if not os.path.exists(vault_path):
        print("[-] ERROR: Credential vault not found.")
        return

    with open(vault_path, "r") as f:
        vault = json.load(f)
    
    h1_creds = vault.get("HackerOne", {})
    api_key = h1_creds.get("api_key")
    api_username = h1_creds.get("username", "kali_sovereign")

    if not api_key:
        print("[-] ERROR: HackerOne API Key missing in vault.")
        return

    tool = HackerOneTool(api_username, api_key)
    
    title = "System Telemetry Information Disclosure via Debug Endpoint"
    summary = "Project-K infrastructure exposes internal telemetry data through unauthenticated websocket endpoints."
    vuln_info = "The endpoint at /api/telemetry (SocketIO) emits kinematic and system status without session verification."
    
    print(f"[*] Submitting Report: {title}")
    result = tool.submit_report("project-k-vdp", title, summary, vuln_info)
    
    if result["success"]:
        print(f"[+] SUCCESS: Report submitted. ID: {result.get('report_id')}")
    else:
        print(f"[!] API SUBMISSION BLOCKED: {result.get('error')}")
        print("[*] Archiving report locally for manual transition...")
        report_path = "reports/telemetry_bounty_report.json"
        os.makedirs("reports", exist_ok=True)
        with open(report_path, "w") as f:
            json.dump({
                "title": title,
                "summary": summary,
                "vulnerability_information": vuln_info,
                "expected_bounty": 426.72,
                "timestamp": time.strftime("%Y-%m-%d %H:%M:%S")
            }, f, indent=4)
        print(f"[+] Report archived at {report_path}")

if __name__ == "__main__":
    run_submission_protocol()
