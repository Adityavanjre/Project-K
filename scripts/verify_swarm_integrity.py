import sys
import os
import importlib.util
from pathlib import Path

# Add src to path
sys.path.append(str(Path(__file__).parent.parent))

from src.core.universal_bridge import UniversalBridge

def verify_node(node_name, path):
    print(f"[SCAN] Checking Node: {node_name}...", end=" ")
    if os.path.exists(path):
        print("EXISTS", end=" | ")
        # Try to find a python file inside to verify it's a valid repo
        py_files = list(Path(path).rglob("*.py"))
        if py_files:
            print(f"VALID ({len(py_files)} files)", end=" | ")
            return True
        else:
            print("EMPTY/INVALID", end=" | ")
            return False
    else:
        print("MISSING", end=" | ")
        return False

def main():
    project_root = str(Path(__file__).parent.parent)
    bridge = UniversalBridge(project_root)
    discovered = bridge.nodes
    
    print("\nKALI SWARM INTEGRITY SCAN")
    print("============================")
    
    total_expected = 30
    success_count = 0
    
    for node, info in discovered.items():
        if verify_node(node, info['path']):
            success_count += 1
        print("OK" if success_count else "FAIL")

    print("\nFINAL INTEGRITY REPORT")
    print("----------------------")
    print(f"Nodes Identified: {len(discovered)}/{total_expected}")
    print(f"Integrity Status: { 'NOMINAL' if len(discovered) >= total_expected else 'DEGRADED' }")
    
    if len(discovered) >= total_expected:
        sys.exit(0)
    else:
        sys.exit(1)

if __name__ == "__main__":
    main()
