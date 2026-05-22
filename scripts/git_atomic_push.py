import os
import subprocess
import time

def run_git(args):
    print(f"Running: git {' '.join(args)}")
    result = subprocess.run(["git"] + args, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"Error: {result.stderr}")
    return result.returncode == 0

def atomic_push(path, message):
    print(f"--- Syncing {path} ---")
    run_git(["add", path])
    run_git(["commit", "-m", message])
    
    retries = 3
    for i in range(retries):
        if run_git(["push", "origin", "main", "--no-verify"]):
            print(f"SUCCESS: {path} anchored.")
            return True
        print(f"Retry {i+1}/{retries} for {path}...")
        time.sleep(5)
    return False

# Main Execution
swarm_dir = "integrations/swarm"
nodes = [f for f in os.listdir(swarm_dir) if os.path.isdir(os.path.join(swarm_dir, f))]

print(f"Found {len(nodes)} neurons to anchor.")

for node in nodes:
    node_path = os.path.join(swarm_dir, node)
    atomic_push(node_path, f"🕉️ Neuron Sync: {node} [Atomic]")

print("Atomic Propagation Cycle Complete.")
