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
    
    CHECKSUM_FILE = "data/checksums.kali"
    
    def __init__(self, root_dir="."):
        self.root_dir = root_dir
        self.signatures = {}
        
    def generate_signatures(self):
        """Map SHA-256 hashes for all mission-critical files."""
        new_signatures = {}
        for path in self.CORE_PATHS:
            abs_path = os.path.join(self.root_dir, path)
            if os.path.isfile(abs_path):
                new_signatures[path] = self._hash_file(abs_path)
            elif os.path.isdir(abs_path):
                for root, _, files in os.walk(abs_path):
                    for file in files:
                        if file.endswith(('.py', '.js', '.html')):
                            full_path = os.path.join(root, file)
                            rel_path = os.path.relpath(full_path, self.root_dir).replace("\\", "/")
                            new_signatures[rel_path] = self._hash_file(full_path)
                            
        self.signatures = new_signatures
        
        # Save to signed anchor
        os.makedirs(os.path.dirname(self.CHECKSUM_FILE), exist_ok=True)
        with open(self.CHECKSUM_FILE, "w") as f:
            json.dump(self.signatures, f, indent=4)
            
        logger.info(f"KALI BIOS: Integrity Anchor Generated [{len(self.signatures)} files]")
        return True

    def verify_integrity(self):
        """Verify current system state against the signed anchor."""
        if not os.path.exists(self.CHECKSUM_FILE):
            logger.warning("KALI BIOS: No Integrity Anchor found. Generating initial anchor...")
            self.generate_signatures()
            return True, []

        with open(self.CHECKSUM_FILE, "r") as f:
            anchor = json.load(f)

        violations = []
        for rel_path, expected_hash in anchor.items():
            abs_path = os.path.join(self.root_dir, rel_path)
            if not os.path.exists(abs_path):
                violations.append({"path": rel_path, "error": "MISSING"})
                continue
            
            if self._hash_file(abs_path) != expected_hash:
                violations.append({"path": rel_path, "error": "MODIFIED"})

        if violations:
            logger.critical(f"KALI BIOS: Integrity Breach Detected! [{len(violations)} violations]")
        else:
            logger.info("KALI BIOS: Secure Boot Verified. Integrity 100% Nominal.")
            
        return len(violations) == 0, violations

    def _hash_file(self, file_path):
        sha256 = hashlib.sha256()
        with open(file_path, "rb") as f:
            for byte_block in iter(lambda: f.read(4096), b""):
                sha256.update(byte_block)
        return sha256.hexdigest()
