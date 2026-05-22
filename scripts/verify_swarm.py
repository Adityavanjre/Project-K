import sys
import os

# Add project root to sys.path
sys.path.append(os.getcwd())

from modules.bridge import UniversalBridge

def test_swarm_count():
    print("--- Verifying Swarm Node Registration ---")
    bridge = UniversalBridge()
    
    count = len(bridge.modules)
    print(f"Total Modules Registered: {count}")
    
    for name in sorted(bridge.modules.keys()):
        caps = bridge.modules[name].metadata.get("capabilities", [])
        print(f"- {name:20} Caps: {caps}")
        
    if count > 0:
        print(f"\nSuccess! Sovereign Swarm contains {count} dynamic nodes discovered at runtime.")
    else:
        print("\n[WARNING] No swarm nodes discovered. System may be in isolated mode.")
        sys.exit(1)

if __name__ == "__main__":
    test_swarm_count()
