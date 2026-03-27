import time
import logging
import os
import sys
import shutil
import subprocess
import random
import json

# Add project root and src to path
project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
sys.path.insert(0, project_root)
sys.path.insert(0, os.path.join(project_root, 'src'))

from src.core.processor import DoubtProcessor

class SelfOptimizingLoop:
    """
    KALI RECURSIVE SELF-UPDATE
    Allows KALI to analyze her own source code and implement architectural improvements.
    """
    def __init__(self, project_root: str):
        self.project_root = os.path.abspath(project_root)
        logging.basicConfig(level=logging.INFO) # Keep this for initial setup if not configured elsewhere
        self.logger = logging.getLogger("SELF_OPT")
        self.processor = DoubtProcessor()
        self.bios_manifest_path = os.path.join(self.project_root, "data", "bios_manifest.json")
        self.src_dir = os.path.join(project_root, "src")
        self.scripts_dir = os.path.join(project_root, "scripts")
        self.backup_dir = os.path.join(project_root, "backups", "self_update")
        
    def run_optimization_cycle(self, target_file: str = None, context: str = ""):
        """
        Runs one cycle of auditing and patching.
        If target_file is provided, focuses specifically on that node.
        """
        self.logger.info("📡 KALI Self-Optimization Loop Online. Auditing core neural pathways...")
        os.makedirs(self.backup_dir, exist_ok=True)
        
        if not target_file:
            files = []
            for d in [self.src_dir, self.scripts_dir]:
                for root, _, fs in os.walk(d):
                    if "backups" in root: continue
                    for f in fs:
                        if f.endswith(".py"):
                            files.append(os.path.join(root, f))
            target_file = random.choice(files) if files else None
            
        if not target_file: return
        
        self.logger.info(f"[*] Targeting: {os.path.basename(target_file)} for evolutionary audit.")
        
        with open(target_file, "r", encoding="utf-8") as f:
            code = f.read()
            
        # 2. Audit Code via KALI
        role = "KALI DEBUGGER" if context else "KALI ARCHITECT"
        audit_prompt = (
            f"You are the {role}. Analyze your own source code for: '{os.path.basename(target_file)}'.\n"
            f"IDENTIFY: One specific architectural improvement or bug fix.\n"
            + (f"ERROR CONTEXT:\n{context}\n\n" if context else "") +
            f"CODE:\n{code}\n\n"
            f"Return ONLY a JSON object with 'gap' (summary) and 'patch' (the full improved file content)."
        )
        
        try:
            optimization = self.processor.ai_service.ask_json("KALI Self-Audit", audit_prompt)
            if not optimization or "patch" not in optimization:
                self.logger.warning("KALI found no immediate gaps in this node.")
                return
            
            # 3. Apply Patch with Neural Forking
            self._apply_patch(target_file, optimization["patch"], optimization.get("gap", "Evolutionary patch."))
                
        except Exception as e:
            self.logger.error(f"Self-Optimization Cycle Failed: {e}")

    def _apply_patch(self, target_file: str, patch_code: str, gap_summary: str):
        """Phase 4.25: Neural Forking (Isolated patch verification)."""
        self.logger.info(f"[*] KALI: Initiating Neural Fork for {os.path.basename(target_file)}")
        
        # 1. Backup
        backup_path = os.path.join(self.backup_dir, f"{os.path.basename(target_file)}.{int(time.time())}.bak")
        shutil.copy2(target_file, backup_path)
        
        try:
            # 2. Apply to Target
            with open(target_file, "w", encoding="utf-8") as f:
                f.write(patch_code)
            
            # 3. Neural BIOS Check
            if not self._verify_bios_integrity(target_file):
                self.logger.error("[-] BIOS Integrity Hash Mismatch! Reverting.")
                shutil.copy2(backup_path, target_file)
                return

            # 4. Global Integrity Check (Pytest Gatekeeper)
            if self._verify_patch_with_pytest():
                self.logger.info(f"[+] KALI: Patch verified. Neural Link Restored.")
                self.logger.info(f"[*] Evolution: {gap_summary}")
                # 5. Log to Digital Soul
                self.processor.training_logger.log(f"Self-Update: {os.path.basename(target_file)}", gap_summary)
                # 6. Hot-Reload the affected service in memory (Phase 4.20)
                # Determine which core service corresponds to the patched file
                file_stem = os.path.basename(target_file).replace(".py", "")
                service_map = {
                    "ai_service": "ai_service",
                    "gsd_service": "gsd_service",
                    "vector_memory": "vector_memory"
                }
                if file_stem in service_map:
                    self.processor.hot_reload_service(service_map[file_stem])
                    self.logger.info(f"[+] Hot-Reload triggered for '{file_stem}'.")
                else:
                    self.logger.info(f"[*] No hot-reload target for '{file_stem}'. Patch is disk-only until restart.")
            else:
                self.logger.error("[-] KALI: Integrity check failed! Performing EMERGENCY REVERT.")
                shutil.copy2(backup_path, target_file)
        except Exception as e:
            self.logger.error(f"Patch verification failed: {e}")
            if os.path.exists(backup_path):
                shutil.copy2(backup_path, target_file)

    def _verify_bios_integrity(self, file_path: str) -> bool:
        """Phase 4.22: Neural BIOS Verification (Hash-based integrity check)"""
        if not os.path.exists(self.bios_manifest_path): return True
        try:
            import hashlib
            with open(self.bios_manifest_path, "r") as f:
                manifest = json.load(f)
            rel_path = os.path.relpath(file_path, self.project_root).replace("\\", "/")
            if rel_path not in manifest: return True
            
            with open(file_path, "rb") as f:
                current_hash = hashlib.sha256(f.read()).hexdigest()
            return current_hash == manifest[rel_path]
        except Exception as e:
            self.logger.error(f"BIOS Integrity Check Failed: {e}")
            return False

    def _verify_patch_with_pytest(self) -> bool:
        """Runs the system test suite to ensure the self-patch didn't break KALI."""
        self.logger.info("[?] Running recursive integrity checks (pytest)...")
        try:
            # We run the basic test suite as a lightweight gatekeeper
            res = subprocess.run(
                [sys.executable, "-m", "pytest", "tests/test_basic.py"],
                cwd=self.project_root,
                capture_output=True,
                text=True,
                timeout=60
            )
            return res.returncode == 0
        except Exception as e:
            self.logger.error(f"Integrity check crashed: {e}")
            return False

def run_self_optimizing_loop(error_msg: str = None):
    """
    Convenience wrapper for external calls (e.g. from ralph_loop).
    Attempts to identify the failing file from the error_msg if provided.
    """
    looper = SelfOptimizingLoop(project_root)
    target_file = None
    if error_msg:
        # Simple heuristic to find a .py file in the traceback
        import re
        matches = re.findall(r'File "(.*\.py)", line', error_msg)
        if matches:
            # Prefer files in the project directory
            for m in reversed(matches):
                if project_root in os.path.abspath(m):
                    target_file = m
                    break
    
    looper.run_optimization_cycle(target_file=target_file, context=error_msg)

if __name__ == "__main__":
    # If run directly as a script, perform a random audit cycle
    run_self_optimizing_loop()
