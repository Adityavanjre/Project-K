import os
import hashlib
import json
import logging

logger = logging.getLogger(__name__)

class IntegrityService:
    """Phase 26: Cryptographic System Integrity and Sovereignty."""
    
    CORE_PATHS = [
        "src/core",
        "src/utils",
        "src/web_app.py"
    ]
    
    MANIFEST_FILE = "data/kali_core.manifest"
    
    def __init__(self, root_dir="."):
        self.root_dir = os.path.abspath(root_dir)
        self.signatures = {}
        
    def generate_signatures(self):
        """Map SHA-256 hashes for all mission-critical files and save as manifest."""
        new_signatures = {}
        for path in self.CORE_PATHS:
            abs_path = os.path.join(self.root_dir, path)
            if os.path.isfile(abs_path):
                rel_path = os.path.relpath(abs_path, self.root_dir).replace("\\", "/")
                new_signatures[rel_path] = self._hash_file(abs_path)
            elif os.path.isdir(abs_path):
                for root, _, files in os.walk(abs_path):
                    for file in files:
                        if file.endswith(('.py', '.js', '.html', '.css')):
                            full_path = os.path.join(root, file)
                            rel_path = os.path.relpath(full_path, self.root_dir).replace("\\", "/")
                            new_signatures[rel_path] = self._hash_file(full_path)
                            
        self.signatures = new_signatures
        
        # Save to Manifest
        os.makedirs(os.path.dirname(self.MANIFEST_FILE), exist_ok=True)
        with open(self.MANIFEST_FILE, "w", encoding="utf-8") as f:
            json.dump({
                "version": "1.1.0",
                "generated_at": datetime.now().isoformat(),
                "signatures": self.signatures
            }, f, indent=4)
            
        logger.info(f"KALI Integrity: Manifest Generated [{len(self.signatures)} files]")
        return True

    def verify_integrity(self):
        """Verify system state against manifest. Returns (is_intact, violations)."""
        if not os.path.exists(self.MANIFEST_FILE):
            logger.warning("KALI Integrity: No Manifest found. Initializing security anchor...")
            self.generate_signatures()
            return True, []

        try:
            with open(self.MANIFEST_FILE, "r", encoding="utf-8") as f:
                manifest_data = json.load(f)
                anchor = manifest_data.get("signatures", {})
        except Exception as e:
            logger.error(f"KALI Integrity: Failed to read manifest: {e}")
            return False, [{"path": self.MANIFEST_FILE, "error": "MANIFEST_CORRUPT"}]

        violations = []
        for rel_path, expected_hash in anchor.items():
            abs_path = os.path.join(self.root_dir, rel_path)
            
            if not os.path.exists(abs_path):
                violations.append({"path": rel_path, "error": "MISSING"})
                continue
            
            actual_hash = self._hash_file(abs_path)
            if actual_hash != expected_hash:
                violations.append({
                    "path": rel_path, 
                    "error": "MODIFIED", 
                    "expected": expected_hash,
                    "actual": actual_hash
                })

        return len(violations) == 0, violations

    def _hash_file(self, file_path):
        """Standard SHA-256 Utility."""
        sha256 = hashlib.sha256()
        try:
            with open(file_path, "rb") as f:
                for byte_block in iter(lambda: f.read(4096), b""):
                    sha256.update(byte_block)
            return sha256.hexdigest()
        except Exception:
            return "HASH_ERROR"
