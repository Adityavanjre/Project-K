import os
import re

def scan_and_patch(root_dir):
    usage_pattern = re.compile(r'\btime\.(sleep|time|perf_counter|monotonic|strftime|gmtime|localtime)\b')
    import_pattern = re.compile(r'^\s*(import\s+time|from\s+time\s+import)', re.MULTILINE)
    
    fixed_files = []
    
    for root, dirs, files in os.walk(root_dir):
        if '.git' in dirs: dirs.remove('.git')
        if '__pycache__' in dirs: dirs.remove('__pycache__')
        
        for file in files:
            if file.endswith('.py'):
                path = os.path.join(root, file)
                try:
                    with open(path, 'r', encoding='utf-8', errors='ignore') as f:
                        content = f.read()
                    
                    # 1. Detect Usage
                    if usage_pattern.search(content):
                        # 2. Check for missing import
                        # We must ensure it's NOT imported at top OR locally
                        if not import_pattern.search(content) and not re.search(r'\bimport\s+time\b', content):
                            
                            # 3. Apply Patch
                            lines = content.splitlines()
                            # Find first non-comment, non-empty line
                            insert_idx = 0
                            for i, line in enumerate(lines):
                                if line.strip() and not line.strip().startswith('#') and '"""' not in line and "'''" not in line:
                                    insert_idx = i
                                    break
                            
                            lines.insert(insert_idx, "import time")
                            new_content = "\n".join(lines)
                            
                            with open(path, 'w', encoding='utf-8') as f:
                                f.write(new_content)
                            
                            fixed_files.append(path)
                            print(f"[FIXED] {path}")
                except Exception as e:
                    print(f"[ERROR] Reading {path}: {e}")
                    
    return fixed_files

if __name__ == "__main__":
    root = os.getcwd()
    print(f"--- KALI DEEP SCAN INITIATED: {root} ---")
    fixed = scan_and_patch(root)
    
    print("\n--- PATCH SUMMARY ---")
    if not fixed:
        print("NO MISSING IMPORTS FOUND. SYSTEM STABLE.")
    else:
        for f in fixed:
            print(f" - {f}")
        print(f"\nTOTAL FILES FIXED: {len(fixed)}")
    
    print("\nTIME_IMPORT_PATCH_COMPLETE")
