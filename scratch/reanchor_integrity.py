
import sys
import os

# Add src to path
project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
sys.path.insert(0, os.path.join(project_root, 'src'))

from core.integrity import IntegrityService

def reanchor():
    print("SOVEREIGN: Re-anchoring System Integrity...")
    integrity = IntegrityService(root_dir=project_root)
    integrity.generate_signatures()
    
    # Also update recovery files
    recovery_dir = os.path.join(project_root, "data", "recovery")
    os.makedirs(recovery_dir, exist_ok=True)
    
    import shutil
    for rel_path in ["src/core/gateway.py", "src/core/local_ai_service.py"]:
        src_path = os.path.join(project_root, rel_path)
        dst_path = os.path.join(recovery_dir, os.path.basename(rel_path))
        if os.path.exists(src_path):
            shutil.copy2(src_path, dst_path)
            print(f"[+] Updated Recovery Baseline: {rel_path}")

    print("SOVEREIGN: System Integrity Hardened.")

if __name__ == "__main__":
    reanchor()
