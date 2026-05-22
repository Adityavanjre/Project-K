import os
import json
from datetime import datetime
import sys

# Ensure project root is in path
project_root = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
sys.path.insert(0, project_root)

try:
    from src.core.kali_agent import KALIAgent
except ImportError:
    from core.kali_agent import KALIAgent

def run_mission():
    kali = KALIAgent(project_root)
    kali.log_mission("Telemetry Vulnerability Aggregation", "STARTED")
    
    # 1. PULL: Extract findings from daemon logs or telemetry streams
    # For now, we use the known telemetry vulnerability
    findings = {
        "title": "System Telemetry Information Disclosure via Unauthenticated WebSocket",
        "vulnerability_information": """
The Project-K infrastructure exposes a real-time telemetry stream via SocketIO at `/api/telemetry`.
This endpoint is currently accessible without any session authentication or API token.

Impact:
An unauthenticated attacker can monitor the kinematic state, system integrity, and operational status of the KALI ASI in real-time.

Reproduction:
1. Connect to the WebSocket at the project root.
2. Listen for the 'telemetry_update' event.
3. Observe real-time system data.
""",
        "severity": "medium",
        "timestamp": datetime.now().isoformat()
    }
    
    kali.log_mission("PULLED: 1 Critical Telemetry Vulnerability identified.", "INFO")
    
    # 2. CREATE: Save the report archive (Push to reports/)
    report_path = os.path.join(project_root, "reports", "telemetry_bounty_report.json")
    os.makedirs(os.path.dirname(report_path), exist_ok=True)
    
    with open(report_path, "w") as f:
        json.dump(findings, f, indent=4)
    
    kali.log_mission("PUSHED: Telemetry Report Archive created in reports/ tier.", "SUCCESS")
    kali.log_mission("Telemetry Vulnerability Aggregation", "COMPLETED")

if __name__ == "__main__":
    run_mission()
