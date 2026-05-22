import os
import sys
import subprocess
import time

project_root = os.getcwd()
sys.path.insert(0, project_root)
sys.path.insert(0, os.path.join(project_root, 'src'))

from src.core.processor import DoubtProcessor

def validate():
    project_root = os.getcwd()
    env = os.environ.copy()
    env["PYTHONPATH"] = f"{project_root}{os.pathsep}{os.path.join(project_root, 'src')}{os.pathsep}{env.get('PYTHONPATH', '')}"
    
    print("[*] Launching Temporary Neural Gateway...")
    gateway_path = os.path.join(project_root, "src", "core", "gateway.py")
    gateway_proc = subprocess.Popen(
        [sys.executable, gateway_path],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        env=env
    )
    time.sleep(5)
    
    try:
        dp = DoubtProcessor()
        status = dp.get_system_status()
        
        print("--- REALITY VALIDATION REPORT ---")
        print(f"Sovereign Mode: {os.getenv('SOVEREIGN_FORCE_LOCAL', 'false')}")
        print(f"Local Node Ready: {status.get('local_node_ready')}")
        print(f"BIOS Secure: {status.get('is_sovereign')}")
        print(f"Nodes: {status.get('swarm_status')}")
        print(f"Models: {dp.ai_service.available_models}")
        print(f"CPU Usage: {status.get('cpu_usage')}%")
        print(f"Memory Usage: {status.get('memory_usage')}%")
        print("---------------------------------")
    finally:
        print("[*] Terminating Gateway.")
        gateway_proc.terminate()

if __name__ == "__main__":
    validate()
