import os
import re
import time
import logging

logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")
logger = logging.getLogger("TIME_PATCHER")

def scan_and_patch():
    # regex to find time.something usage (e.g., time.sleep, time.time, etc.)
    time_usage_pattern = re.compile(r'\btime\.(sleep|time|perf_counter|monotonic|strftime|gmtime|localtime|perf_counter_ns|time_ns)\b')
    # regex to find import time or from time import
    import_time_pattern = re.compile(r'^\s*(import\s+time|from\s+time\s+import|from\s+\.\s+import\s+time|from\s+\.\.\s+import\s+time)', re.MULTILINE)
    
    fixed_files = []
    
    for root, dirs, files in os.walk('.'):
        # Skip directories that shouldn't be modified
        if any(skip in root for skip in ['venv', '.git', '__pycache__', '.pytest_cache', 'node_modules', '.gemini']):
            continue
            
        for file in files:
            if file.endswith('.py'):
                path = os.path.join(root, file)
                try:
                    with open(path, 'r', encoding='utf-8', errors='ignore') as f:
                        lines = f.readlines()
                    
                    content = "".join(lines)
                    
                    if time_usage_pattern.search(content):
                        if not import_time_pattern.search(content):
                            # Also check for local imports inside functions to avoid double imports
                            if not re.search(r'^\s+import\s+time', content, re.MULTILINE):
                                logger.info(f"Patching {path}: Missing 'import time'")
                                
                                # Find best place to insert: after other imports or at top
                                insert_idx = 0
                                for i, line in enumerate(lines):
                                    if line.startswith(('import ', 'from ')):
                                        insert_idx = i
                                    elif i > 10: # Don't look too far
                                        break
                                
                                # Insert after the last import found (within the first 10 lines)
                                # or at line 0 if no imports found.
                                # Let's just put it at line 0 or after docstring.
                                if lines and lines[0].startswith('"""') or lines[0].startswith("'''"):
                                    # Find end of docstring
                                    for i, line in enumerate(lines):
                                        if i > 0 and (line.strip().endswith('"""') or line.strip().endswith("'''")):
                                            insert_idx = i + 1
                                            break
                                elif lines and lines[0].startswith('#!'):
                                    insert_idx = 1
                                
                                lines.insert(insert_idx, "import time\n")
                                
                                with open(path, 'w', encoding='utf-8') as f:
                                    f.writelines(lines)
                                
                                fixed_files.append(path)
                except Exception as e:
                    logger.error(f"Error processing {path}: {e}")
                    
    return fixed_files

if __name__ == "__main__":
    logger.info("Starting KALI Runtime Stability Repair: TIME_IMPORT_PATCH")
    fixed = scan_and_patch()
    if fixed:
        logger.info(f"Successfully patched {len(fixed)} files:")
        for f in fixed:
            logger.info(f" - {f}")
    else:
        logger.info("No missing 'time' imports detected. System is stable.")
    
    print("\nTIME_IMPORT_PATCH_COMPLETE")
