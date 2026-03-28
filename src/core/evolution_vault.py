import os
import shutil
import hashlib
import logging
from datetime import datetime
from typing import Optional

class EvolutionVault:
    """
    Phase 4.25: Neural Forking Vault.
    Provides secure, timestamped, and SHA-256 verified backups of KALI's DNA
    before any autonomous evolution occurs.
    """
    def __init__(self, project_root: str):
        self.project_root = project_root
        self.vault_dir = os.path.join(project_root, ".evolution", "vault")
        
        if not os.path.exists(self.vault_dir):
            os.makedirs(self.vault_dir)
            
        self.logger = logging.getLogger("EvolutionVault")

    def _calculate_hash(self, file_path: str) -> str:
        sha256 = hashlib.sha256()
        with open(file_path, "rb") as f:
            for byte_block in iter(lambda: f.read(4096), b""):
                sha256.update(byte_block)
        return sha256.hexdigest()

    def create_backup(self, rel_path: str) -> Optional[str]:
        """
        Creates a secure fork of the target file.
        Returns the path to the backup file.
        """
        abs_path = os.path.abspath(os.path.join(self.project_root, rel_path))
        
        if not os.path.exists(abs_path):
            self.logger.error(f"VAULT_ERROR: Cannot backup non-existent file: {rel_path}")
            return None

        # 1. Generate Metadata
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        file_hash = self._calculate_hash(abs_path)
        file_name = os.path.basename(rel_path)
        
        # 2. Create Destination Path
        # Structure: .evolution/vault/20260328_183000_abc123_processor.py
        backup_name = f"{timestamp}_{file_hash[:8]}_{file_name}"
        backup_path = os.path.join(self.vault_dir, backup_name)

        try:
            shutil.copy2(abs_path, backup_path)
            
            # 3. Create Signature File
            sig_path = f"{backup_path}.sig"
            with open(sig_path, "w") as f:
                f.write(file_hash)
            
            self.logger.info(f"VAULT_SUCCESS: Secured {rel_path} -> {backup_name}")
            return backup_path
            
        except Exception as e:
            self.logger.error(f"VAULT_CRITICAL_FAIL: Backup failed for {rel_path}: {e}")
            return None

    def restore(self, backup_name: str, target_rel_path: str) -> bool:
        """Restores a file from the vault after verification."""
        backup_path = os.path.join(self.vault_dir, backup_name)
        sig_path = f"{backup_path}.sig"
        target_abs_path = os.path.abspath(os.path.join(self.project_root, target_rel_path))

        if not os.path.exists(backup_path) or not os.path.exists(sig_path):
            return False

        # Verify Signature before restore
        with open(sig_path, "r") as f:
            expected_hash = f.read().strip()
        
        actual_hash = self._calculate_hash(backup_path)
        
        if expected_hash != actual_hash:
            self.logger.error(f"VAULT_REJECTED: Signature mismatch for {backup_name}!")
            return False

        shutil.copy2(backup_path, target_abs_path)
        self.logger.info(f"VAULT_RESTORE: {target_rel_path} restored from {backup_name}")
        return True
