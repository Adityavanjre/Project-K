import os
import subprocess
import time
import sys

# Ensure UTF-8 output
if sys.platform == "win32":
    import codecs
    sys.stdout = codecs.getwriter("utf-8")(sys.stdout.detach())

def run_git(args):
    result = subprocess.run(["git"] + args, capture_output=True, text=True, shell=True)
    if result.returncode != 0:
        print(f"\nDEBUG ERROR: {result.stderr.strip()}", flush=True)
    return result.returncode == 0

def atomic_sync():
    print("KALI ATOMIC SYNC: LANDING ON MAIN...", flush=True)
    
    # Get all untracked files
    result = subprocess.run(["git", "ls-files", "--others", "--exclude-standard"], capture_output=True, text=True, shell=True)
    if result.returncode != 0:
        print(f"ERROR listing files: {result.stderr}", flush=True)
        return

    files = result.stdout.splitlines()
    
    batch_size = 50
    total_files = len(files)
    
    print(f"Total Files: {total_files}", flush=True)
    
    for i in range(0, total_files, batch_size):
        batch = files[i:i + batch_size]
        print(f"\n[BATCH] {i} to {min(i+batch_size, total_files)}...", end="", flush=True)
        
        for f in batch:
            subprocess.run(["git", "add", f], capture_output=True, shell=True)
        
        # Commit the batch
        if subprocess.run(["git", "commit", "-m", f"pulse: batch {i//batch_size}"], capture_output=True, shell=True).returncode == 0:
            success = False
            retries = 3
            while not success and retries > 0:
                push_args = ["git", "push", "origin", "HEAD:main"]
                if i == 0:
                    push_args.append("--force")
                
                res = subprocess.run(push_args, capture_output=True, text=True, shell=True)
                if res.returncode == 0:
                    print(" SUCCESS.", flush=True)
                    success = True
                else:
                    retries -= 1
                    print(f"\nDEBUG PUSH FAILED: {res.stderr.strip()}", flush=True)
                    print(".", end="", flush=True)
                    time.sleep(5)
            
            if not success:
                print(" FAILED.", flush=True)
        else:
            print(" SKIP.", flush=True)

if __name__ == "__main__":
    atomic_sync()
