import os
import subprocess
import time
import sys

# Ensure UTF-8 output for Windows CMD
if sys.platform == "win32":
    import codecs
    sys.stdout = codecs.getwriter("utf-8")(sys.stdout.detach())

def get_current_branch():
    result = subprocess.run(["git", "rev-parse", "--abbrev-ref", "HEAD"], capture_output=True, text=True)
    return result.stdout.strip() if result.returncode == 0 else "master"

def run_git(args):
    print(f"Executing: git {' '.join(args)}")
    result = subprocess.run(["git"] + args, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"Error Output: {result.stderr}")
    return result.returncode == 0

def sovereign_push(target_dir="integrations", remote="origin"):
    branch = get_current_branch()
    print(f"KALI SOVEREIGN PUSH: INITIALIZING DYNAMIC DEPLOYMENT [BRANCH: {branch}]")
    
    # 1. Push Core (Everything except target_dir)
    print(f"\n--- STEP 1: PUSHING CORE CODE (EXCLUDING {target_dir}) ---")
    
    # Unstage all to be safe
    run_git(["reset"])
    
    # Add core files
    run_git(["add", ".", f"--:!{target_dir}"])
    run_git(["commit", "-m", "chore: Deploy KALI Sovereign Core assets"])
    
    if run_git(["push", "-f", remote, branch]):
        print("SUCCESS: Core deployed.")
    else:
        print("FAILURE: Core deployment failed. Aborting.")
        return

    # 2. Push Integrations Chunk-by-Chunk
    if not os.path.exists(target_dir):
        print(f"Directory {target_dir} not found. Operation complete.")
        return

    folders = [f for f in os.listdir(target_dir) if os.path.isdir(os.path.join(target_dir, f))]
    print(f"\n--- STEP 2: PUSHING {len(folders)} MODULES FROM {target_dir} ---")

    for i, folder in enumerate(folders):
        folder_path = f"{target_dir}/{folder}"
        print(f"\n[{i+1}/{len(folders)}] Syncing: {folder}...")
        
        run_git(["add", folder_path])
        run_git(["commit", "-m", f"feat: Sync module {folder} to monolith"])
        
        success = False
        retries = 3
        while not success and retries > 0:
            if run_git(["push", remote, branch]):
                print(f"SUCCESS: Synced {folder}")
                success = True
            else:
                retries -= 1
                print(f"WARNING: Sync failed. Retrying... ({retries} left)")
                time.sleep(5)
        
        if not success:
            print(f"ERROR: Permanent failure on {folder}. Skipping.")

    print("\nKALI SOVEREIGN PUSH: DYNAMIC DEPLOYMENT COMPLETE.")

if __name__ == "__main__":
    target = sys.argv[1] if len(sys.argv) > 1 else "integrations"
    sovereign_push(target_dir=target)
