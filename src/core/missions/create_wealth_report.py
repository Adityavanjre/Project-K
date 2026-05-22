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
    kali.log_mission("Wealth & Autonomy Report Creation", "STARTED")
    
    # 1. PULL: Extract data from mission history
    history_path = os.path.join(project_root, "logs", "mission_history.json")
    if not os.path.exists(history_path):
        history = []
    else:
        with open(history_path, "r") as f:
            history = json.load(f)
    
    kali.log_mission(f"PULLED: {len(history)} historical records.", "INFO")
    
    # 2. CREATE: Generate report content
    report_content = f"""
# KALI SOVEREIGN PERFORMANCE REPORT
Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}

## AUTONOMY METRICS
- Total Missions: {len(history)}
- Status: ACTIVE
- Mode: STRICT_AUTONOMY

## MISSION LEDGER
"""
    for m in history[-5:]: # Last 5
        report_content += f"- [{m['timestamp']}] {m['directive']} -> {m['status']}\n"

    report_content += "\n## WEALTH SYNC\n- Source: Local Audit Log\n- Total Verified Value: $0.00"
    
    # 3. PUSH: Save (Push) the report to the results directory
    report_filename = f"KALI_REPORT_{datetime.now().strftime('%Y%m%d_%H%M%S')}.md"
    report_path = os.path.join(project_root, "results", report_filename)
    
    kali.create(os.path.join("results", report_filename), report_content)
    
    kali.log_mission(f"PUSHED: {report_filename} to results/ tier.", "SUCCESS")
    kali.log_mission("Wealth & Autonomy Report Creation", "COMPLETED")

if __name__ == "__main__":
    run_mission()
