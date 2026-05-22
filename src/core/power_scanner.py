import os
import ast
import json
from datetime import datetime

PROJECT_ROOT = os.getcwd()
INTEGRATIONS_DIR = os.path.join(PROJECT_ROOT, "integrations")
LEDGER_PATH = os.path.join(PROJECT_ROOT, "logs", "sovereign_power_ledger.json")

def scan_node_features(node_id):
    """Deep-scans a single node for all callable functions."""
    node_path = os.path.join(INTEGRATIONS_DIR, node_id)
    features = []
    
    for root, _, files in os.walk(node_path):
        for file in files:
            if file.endswith(".py"):
                file_path = os.path.join(root, file)
                try:
                    with open(file_path, "r", encoding="utf-8") as f:
                        tree = ast.parse(f.read())
                        for node in ast.walk(tree):
                            if isinstance(node, ast.FunctionDef):
                                features.append({
                                    "name": node.name,
                                    "file": os.path.relpath(file_path, node_path),
                                    "type": "python_function"
                                })
                            elif isinstance(node, ast.ClassDef):
                                features.append({
                                    "name": node.name,
                                    "file": os.path.relpath(file_path, node_path),
                                    "type": "python_class"
                                })
                except Exception:
                    continue
    return features

def build_sovereign_ledger():
    print("Initiating Full Swarm Introspection...")
    ledger = {
        "timestamp": datetime.now().isoformat(),
        "total_nodes_scanned": 0,
        "total_features_inherited": 0,
        "swarm_matrix": {}
    }
    
    if not os.path.exists(INTEGRATIONS_DIR):
        print("[-] Integrations folder not found.")
        return

    for node_id in os.listdir(INTEGRATIONS_DIR):
        node_path = os.path.join(INTEGRATIONS_DIR, node_id)
        if os.path.isdir(node_path) and not node_id.startswith("."):
            print(f"Scanning Neuron: {node_id}...")
            features = scan_node_features(node_id)
            ledger["swarm_matrix"][node_id] = {
                "feature_count": len(features),
                "features": features
            }
            ledger["total_nodes_scanned"] += 1
            ledger["total_features_inherited"] += len(features)

    os.makedirs(os.path.dirname(LEDGER_PATH), exist_ok=True)
    with open(LEDGER_PATH, "w") as f:
        json.dump(ledger, f, indent=2)
        
    print(f"\nSOVEREIGN POWER LEDGER COMPLETE.")
    print(f"- Total Nodes: {ledger['total_nodes_scanned']}")
    print(f"- Total Features Inherited: {ledger['total_features_inherited']}")
    print(f"Ledger stored at: {LEDGER_PATH}")

if __name__ == "__main__":
    build_sovereign_ledger()
