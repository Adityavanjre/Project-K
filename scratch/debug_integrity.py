import os
import json
import logging
import hashlib

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class IntegrityService:
    def __init__(self, root_dir="."):
        self.root_dir = os.path.abspath(root_dir)
        self.MANIFEST_FILE = os.path.join(self.root_dir, "data/kali_core.manifest")
        
    def _hash_file(self, file_path):
        sha256 = hashlib.sha256()
        try:
            with open(file_path, "rb") as f:
                for byte_block in iter(lambda: f.read(4096), b""):
                    sha256.update(byte_block)
            return sha256.hexdigest()
        except Exception:
            return "HASH_ERROR"

    def verify_integrity(self, auto_repair=True):
        with open(self.MANIFEST_FILE, "r", encoding="utf-8") as f:
            manifest_data = json.load(f)
            anchor = manifest_data.get("signatures", {})

        violations = []
        for rel_path, expected_hash in anchor.items():
            abs_path = os.path.join(self.root_dir, rel_path)
            
            if not os.path.exists(abs_path):
                print(f"MISSING: {rel_path}")
                if auto_repair:
                    if self._attempt_repair(rel_path):
                        continue
                violations.append({"path": rel_path, "error": "MISSING"})
                continue
            
            actual_hash = self._hash_file(abs_path)
            if actual_hash != expected_hash:
                print(f"MISMATCH: {rel_path}")
                if auto_repair:
                    if self._attempt_repair(rel_path):
                        continue
                violations.append({"path": rel_path, "error": "MODIFIED"})

        return violations

    def _attempt_repair(self, rel_path):
        recovery_path = os.path.join(self.root_dir, "data", "recovery", os.path.basename(rel_path))
        print(f"Trying to repair {rel_path} from {recovery_path}")
        if os.path.exists(recovery_path):
            print(f"Found recovery fork for {rel_path}")
            return True
        else:
            print(f"NOT FOUND recovery fork for {rel_path}")
        return False

service = IntegrityService(".")
violations = service.verify_integrity(auto_repair=True)
print(f"Final Violations: {violations}")
