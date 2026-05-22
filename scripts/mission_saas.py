import sys
import os
import time

# Add project root to sys.path
sys.path.append(os.getcwd())

from modules.bridge import UniversalBridge

def run_mission():
    print("--- INITIATING WEALTH GENERATION MISSION: SaaS LANDING PAGE ---")
    bridge = UniversalBridge()
    
    # Step 1: Boot KALI with Autonomy
    bridge.set_autonomy_mode(True)
    
    # Step 2: Run the Directive
    directive = "KALI, build a premium SaaS landing page for a productivity app with modern UI and strong conversion copy"
    
    print(f"Directive: {directive}")
    result = bridge.process_directive(directive)
    
    if result.get("status") == "success":
        print("\nMISSION ACCOMPLISHED")
        print(f"Goal ID: {result.get('goal_id')}")
        print("KALI has generated the first portfolio asset.")
    else:
        print("\nMISSION INTERRUPTED")
        print(result)

if __name__ == "__main__":
    run_mission()
