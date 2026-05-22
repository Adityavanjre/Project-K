import os
import subprocess
import time
import sys

# Ensure UTF-8 output
if sys.platform == "win32":
    import codecs
    sys.stdout = codecs.getwriter("utf-8")(sys.stdout.detach())

def get_current_branch():
    result = subprocess.run(["git", "rev-parse", "--abbrev-ref", "HEAD"], capture_output=True, text=True)
    return result.stdout.strip() if result.returncode == 0 else "main"

def run_git(args):
    print(f"Executing: git {' '.join(args)}")
    result = subprocess.run(["git"] + args, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"Error Output: {result.stderr}")
    return result.returncode == 0

def complete_sync():
    branch = get_current_branch()
    print(f"KALI COMPLETE SYNC: DEPLOYING TOTAL CODEBASE [BRANCH: {branch}]")
    
    # Get all top-level directories and files
    items = os.listdir(".")
    dirs = [d for d in items if os.path.isdir(d) and not d.startswith(".") and d not in ["models", "kali_weights"]]
    files = [f for f in items if os.path.isfile(f) and not f.startswith(".")]

    # 1. Push Files First
    print("\n--- PHASE 1: SYNCING ROOT FILES ---")
    for f in files:
        if run_git(["add", f]):
            run_git(["commit", "-m", f"sync: {f}"])
            run_git(["push", "origin", branch])

    # 2. Push Folders One-by-One
    print("\n--- PHASE 2: SYNCING FOLDERS ONE-BY-ONE ---")
    for d in dirs:
        print(f"\n[SYNC] Processing folder: {d}...")
        
        # Add folder
        run_git(["add", d])
        run_git(["commit", "-m", f"sync: {d} contents"])
        
        # Push folder chunk
        success = False
        retries = 3
        while not success and retries > 0:
            if run_git(["push", "origin", branch]):
                print(f"SUCCESS: {d} is live.")
                success = True
            else:
                retries -= 1
                print(f"WARNING: Push failed for {d}. Retrying... ({retries} left)")
                time.sleep(5)
        
        if not success:
            print(f"ERROR: Skipping {d} after repeated failures.")

    print("\nKALI COMPLETE SYNC: ALL OPERATIONS FINISHED.")

if __name__ == "__main__":
    complete_sync()
