import os
import logging
from typing import Optional, Dict, Any, List
from .integrity import IntegrityService

logger = logging.getLogger(__name__)


class BootGuardian:
    """Phase 26/53: Orchestrates the Secure Boot and Self-Healing sequence (G-6)."""

    def __init__(self, project_root: str = "."):
        self.project_root = os.path.abspath(project_root)
        self.integrity_service = IntegrityService(self.project_root)
        from .evolution_vault import EvolutionVault
        self.vault = EvolutionVault(self.project_root)
        self.is_secure_ready = False
        self.is_repaired = False
        self.error_log = []

    def perform_secure_boot(self):
        """Execute Cryptographic Boot Sequence and Self-Healing."""
        logger.info("KALI BIOS: Initiating Secure Boot...")

        # 1. File Integrity Scan
        is_intact, violations = self.integrity_service.verify_integrity()

        if not is_intact:
            logger.warning(f"KALI BIOS: Integrity Breach! Found {len(violations)} violations. Attempting Self-Healing...")
            
            repaired_count = 0
            for violation in violations:
                rel_path = violation["path"]
                # Try to find the latest backup in the vault for this file
                backup_name = self._find_latest_backup(rel_path)
                if backup_name:
                    logger.info(f"KALI BIOS: Restoring {rel_path} from Vault ({backup_name})...")
                    if self.vault.restore(backup_name, rel_path):
                        repaired_count += 1
                else:
                    logger.error(f"KALI BIOS: No recovery fork found for {rel_path}. Sovereignty Compromised.")

            if repaired_count == len(violations):
                logger.info("KALI BIOS: Self-Healing Successful. Re-verifying...")
                self.is_repaired = True
                # Second pass to confirm
                is_intact, _ = self.integrity_service.verify_integrity()
                if is_intact:
                    logger.info("KALI BIOS: System Repaired & Secured.")

        if not is_intact:
            self.is_secure_ready = False
            self.error_log = violations
            logger.critical("KALI BIOS: BOOT_FAIL - Critical Integrity Failure.")
            return False

        self.is_secure_ready = True
        logger.info("KALI BIOS: BOOT_SUCCESS - System is Sovereign.")
        return True

    def _find_latest_backup(self, rel_path: str) -> Optional[str]:
        """
        Find the most recent valid backup file for a specific DNA path.
        Backups are expected in the format: YYYYMMDD_HHMMSS_hash_filename.py
        """
        file_name = os.path.basename(rel_path)
        try:
            # List all non-signature files in vault
            all_files = os.listdir(self.vault.vault_dir)
            # Filter for files that match this specific source file name
            backups = [f for f in all_files if f.endswith(file_name) and not f.endswith(".sig")]
            
            if not backups:
                return None
            
            # Sort by timestamp (prefix) descending
            backups.sort(reverse=True)
            return backups[0]
        except Exception as e:
            logger.error(f"KALI BIOS: Vault Access Error: {e}")
            return None

    def get_bios_status(self) -> Dict[str, Any]:
        """Return real-time BIOS health data for Neural HUD."""
        return {
            "status": "SECURE" if self.is_secure_ready else "RECOVERY",
            "is_intact": self.is_secure_ready and not self.error_log,
            "was_repaired": self.is_repaired,
            "violations": len(self.error_log),
            "version": "1.1.0-RECOVERY",
        }
