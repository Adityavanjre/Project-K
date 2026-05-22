#!/usr/bin/env python3
import os
import sys
import json
import logging
from datetime import datetime

# Add project root and src to path
project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
sys.path.insert(0, project_root)
sys.path.insert(0, os.path.join(project_root, 'src'))

from src.core.processor import DoubtProcessor

def run_autonomous_repair():
    logging.basicConfig(level=logging.INFO)
    logger = logging.getLogger("KALI.AUTONOMOUS_REPAIR")
    
    print("\n" + "="*70)
    print(" KALI AUTONOMOUS SELF-REPAIR SEQUENCE ")
    print("="*70)
    
    # 1. Load Audit Report
    report_path = os.path.join(project_root, "data", "last_audit_report.json")
    if not os.path.exists(report_path):
        logger.error("Audit report not found. Run mission_00_recursive_audit.py first.")
        return

    with open(report_path, "r") as f:
        report = json.load(f)
        
    processor = DoubtProcessor()
    
    # 2. Propose Mission
    mission_id = processor.mission_manager.propose_mission(
        goal="Autonomous Swarm Repair",
        details=f"Resolving the following audit failures: {json.dumps(report.get('actions_required'))}",
        risk_level="HIGH"
    )
    processor.mission_manager.authorize_mission(mission_id, "COMMANDER")
    
    logger.info(f"[*] MISSION {mission_id} AUTHORIZED.")
    logger.info("[*] Initiating KALI Evolution Engine...")

    # 3. Evolution Targets
    targets = [
        {
            "file": "scripts/mission_00_recursive_audit.py",
            "instruction": (
                "Rewrite the node detection logic in scripts/mission_00_recursive_audit.py. "
                "The current logic only supports Python imports and reports 'GHOST' for Node.js or mixed nodes. "
                "Update attempt_import or add a new check that verifies node health based on file structure: "
                "- For Node.js nodes (GitNexus, OpenHuman, MemPalace, Decepticon): Check for package.json and node_modules. "
                "- For Rust nodes (OpenHuman): Check for Cargo.toml. "
                "- For CUA: The path is integrations/swarm/cua/libs/python/agent. Fix the search_path logic so it searches in the parent directory of the cua_agent package."
            )
        },
        {
            "file": "integrations/swarm/cua/libs/python/agent/pyproject.toml",
            "instruction": "Update python version constraints to support Python 3.14.4 (e.g., change ^3.12 to >=3.12). Loosen pinned versions for common libraries like pydantic or torch if they conflict with 3.14."
        }
    ]

    for target in targets:
        logger.info(f"\n[REPAIR] EVOLVING: {target['file']}")
        
        res = processor.evolution_bridge.propose_evolution(target['file'], target['instruction'])
        
        if res["success"]:
            proposal_id = res["proposal_id"]
            logger.info(f"[+] Proposal {proposal_id} Generated.")
            
            # Auto-confirm for this autonomous mission
            confirm_res = processor.evolution_bridge.confirm_evolution(proposal_id, mission_id=mission_id)
            if confirm_res["success"]:
                logger.info(f"[+++] KALI: {target['file']} evolved successfully.")
            else:
                logger.error(f"[-] Evolution confirmation failed: {confirm_res.get('error')}")
        else:
            logger.error(f"[-] Evolution proposal failed: {res.get('error')}")
            if "sandbox_logs" in res:
                # Truncate logs if too long
                logs = res["sandbox_logs"]
                if len(logs) > 1000:
                    logs = logs[:500] + "\n... (truncated) ...\n" + logs[-500:]
                logger.error(f"Sandbox Logs:\n{logs}")

    # 4. Final Re-Audit
    logger.info("\n[FINISH] RE-RUNNING AUDIT TO VERIFY REPAIRS...")
    import subprocess
    subprocess.run([sys.executable, "scripts/mission_00_recursive_audit.py"], cwd=project_root)

    print("\n" + "="*70)
    print(" SELF-REPAIR SEQUENCE COMPLETE ")
    print("="*70 + "\n")

if __name__ == "__main__":
    run_autonomous_repair()
