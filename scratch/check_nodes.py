import os
import sys

project_root = os.getcwd()
sys.path.insert(0, os.path.join(project_root, "src"))

from core.universal_bridge import UniversalBridge

bridge = UniversalBridge(project_root)
print(f"Total nodes discovered: {len(bridge.nodes)}")
for node in sorted(bridge.nodes.keys()):
    print(f" - {node}")
