import os
import logging
from typing import Optional, Dict, Any, List
import subprocess
import sys
import time
from .integrity import IntegrityService

logger = logging.getLogger(__name__)


class BootGuardian:
    """SOVEREIGN/53: Orchestrates the Secure Boot and Self-Healing sequence (G-6)."""

    def __init__(self, project_root: str = "."):
        self.project_root = os.path.abspath(project_root)
        self.integrity_service = IntegrityService(self.project_root)
        self.vault = None # PURGED: EvolutionVault decommissioned
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
                if self.integrity_service._attempt_repair(rel_path):
                    repaired_count += 1
                else:
                    logger.error(f"KALI BIOS: Self-Healing failed for {rel_path} (Baseline Unavailable).")

            if repaired_count == len(violations) and len(violations) > 0:
                logger.info("KALI BIOS: Self-Healing Successful. Re-verifying...")
                self.is_repaired = True
                is_intact, _ = self.integrity_service.verify_integrity()

        if not is_intact:
            self.is_secure_ready = False
            self.error_log = violations
            logger.critical("KALI BIOS: BOOT_FAIL - Critical Integrity Failure.")
            return False

        self.is_secure_ready = True
        logger.info("KALI BIOS: BOOT_SUCCESS - System is Sovereign.")
        
        # 2. Automated Service Orchestration (G-6)
        self._ensure_gateway_running()
        
        return True

    def _ensure_gateway_running(self):
        """Orchestrate the Neural Gateway background service."""
        try:
            from .gateway import NeuralGateway
            if NeuralGateway.is_running():
                logger.info("KALI BIOS: Neural Gateway already active.")
                return True
            
            logger.info("KALI BIOS: Activating Neural Gateway...")
            gateway_path = os.path.join(self.project_root, "src", "core", "gateway.py")
            
            # Start in background without a window
            env = os.environ.copy()
            env["PYTHONPATH"] = f"{self.project_root}{os.pathsep}{os.path.join(self.project_root, 'src')}{os.pathsep}{env.get('PYTHONPATH', '')}"
            
            subprocess.Popen(
                [sys.executable, gateway_path],
                env=env,
                creationflags=subprocess.CREATE_NO_WINDOW if os.name == 'nt' else 0,
                cwd=self.project_root
            )
            
            # Brief pause to allow lock acquisition
            time.sleep(1)
            return True
        except Exception as e:
            logger.error(f"KALI BIOS: Gateway Orchestration Failure: {e}")
            return False

    def _find_latest_backup(self, rel_path: str) -> Optional[str]:
        return None # Vault decommissioned

    def get_bios_status(self) -> Dict[str, Any]:
        """Return real-time BIOS health data for Neural HUD."""
        return {
            "status": "SECURE" if self.is_secure_ready else "RECOVERY",
            "is_intact": self.is_secure_ready and not self.error_log,
            "was_repaired": self.is_repaired,
            "violations": len(self.error_log),
            "version": "1.1.0-RECOVERY",
        }
