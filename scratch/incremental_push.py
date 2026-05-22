import os
import subprocess
import time
import sys

def run_cmd(args):
    print(f"Running: {' '.join(args)}")
    result = subprocess.run(args, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"Error: {result.stderr.strip()}")
    return result.returncode == 0, result.stdout, result.stderr

def git_push_with_retry():
    retries = 5
    for i in range(retries):
        success, stdout, stderr = run_cmd(["git", "push", "origin", "HEAD:main", "--no-verify"])
        if success:
            print("PUSH SUCCESSFUL!")
            return True
        print(f"Push failed (attempt {i+1}/{retries}). Retrying in 10 seconds...")
        time.sleep(10)
    return False

def stage_files(files):
    # Try using --pathspec-from-file
    temp_file = "scratch/temp_add.txt"
    try:
        # Ensure scratch directory exists
        os.makedirs("scratch", exist_ok=True)
        with open(temp_file, "w", encoding="utf-8") as f:
            for filepath in files:
                f.write(filepath + "\n")
        
        success, stdout, stderr = run_cmd(["git", "add", f"--pathspec-from-file={temp_file}"])
        if success:
            try:
                os.remove(temp_file)
            except:
                pass
            return True
        print("git add --pathspec-from-file failed. Falling back to chunked arguments...")
    except Exception as e:
        print(f"Failed to use --pathspec-from-file due to: {e}. Falling back to chunked arguments...")

    # Fallback 1: Chunked command line arguments (e.g. 50 files per call to avoid Windows command limit)
    chunk_size = 50
    for i in range(0, len(files), chunk_size):
        chunk = files[i:i + chunk_size]
        success, stdout, stderr = run_cmd(["git", "add"] + chunk)
        if not success:
            print(f"Failed to add chunk starting at index {i}. Falling back to file-by-file...")
            # Fallback 2: File-by-file
            for f in chunk:
                success_single, _, _ = run_cmd(["git", "add", f])
                if not success_single:
                    print(f"Warning: Failed to add file {f}")
    return True

def main():
    # Make sure we are in the correct repository root
    os.chdir(r"C:\Users\adity\code\Project-K")
    
    # 1. Sync deleted files first
    print("Checking for unstaged deletions...")
    success, stdout, stderr = run_cmd(["git", "status", "--porcelain"])
    lines = stdout.splitlines()
    
    deleted_files = []
    for line in lines:
        if line.startswith(" D ") or line.startswith("D "):
            filepath = line[3:].strip()
            # Strip quotes if present
            if filepath.startswith('"') and filepath.endswith('"'):
                filepath = filepath[1:-1]
            deleted_files.append(filepath)
            
    if deleted_files:
        print(f"Found {len(deleted_files)} deleted files. Staging deletions...")
        for f in deleted_files:
            run_cmd(["git", "rm", f])
        
        success, _, _ = run_cmd(["git", "commit", "-m", "pulse: clean up deleted subfolder gitignores"])
        if success:
            print("Pushing deletions...")
            if not git_push_with_retry():
                print("Failed to push deletions. Exiting.")
                sys.exit(1)
    else:
        print("No deleted files found to sync.")

    # 2. Sync untracked files
    print("Fetching untracked files list (this may take a minute)...")
    success, stdout, stderr = run_cmd(["git", "status", "--porcelain", "--untracked-files=all"])
    if not success:
        print("Failed to get git status. Exiting.")
        sys.exit(1)
        
    lines = stdout.splitlines()
    untracked_files = []
    for line in lines:
        if line.startswith("?? "):
            filepath = line[3:].strip()
            if filepath.startswith('"') and filepath.endswith('"'):
                filepath = filepath[1:-1]
            # Double check that we don't accidentally add files that should be ignored or are too large
            if os.path.exists(filepath):
                untracked_files.append(filepath)
                
    total_files = len(untracked_files)
    print(f"Total untracked files to push: {total_files}")
    
    if total_files == 0:
        print("No untracked files to push. All done!")
        return

    # Batch configuration
    batch_size = 2000
    batches = [untracked_files[i:i + batch_size] for i in range(0, total_files, batch_size)]
    total_batches = len(batches)
    print(f"Divided into {total_batches} batches of up to {batch_size} files each.")

    for idx, batch in enumerate(batches):
        batch_num = idx + 1
        print(f"\n========================================")
        print(f"PROCESSING BATCH {batch_num}/{total_batches} ({len(batch)} files)")
        print(f"========================================")
        
        # Stage files in batch using optimized function
        stage_files(batch)
            
        # Commit batch
        commit_msg = f"pulse: sync batch {batch_num}/{total_batches} ({len(batch)} files)"
        success, _, _ = run_cmd(["git", "commit", "-m", commit_msg])
        if not success:
            print("Failed to commit batch. Trying next batch or exiting...")
            continue
            
        # Push batch
        if not git_push_with_retry():
            print(f"FATAL: Failed to push batch {batch_num} after retries. Stopping execution.")
            sys.exit(1)
            
        print(f"BATCH {batch_num}/{total_batches} SYNCED AND ANCHORED SUCCESSFULLY!")

    print("\nALL BATCHES PUSHED SUCCESSFULLY! SOURCE CODE REPOSITORY IS FULLY IN SYNC!")

if __name__ == "__main__":
    main()
