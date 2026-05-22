import os
import shutil
import logging
from core.integrity import IntegrityService

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("KALI.Anchor")

def anchor_current_state():
    root_dir = os.getcwd()
    integrity = IntegrityService(root_dir)
    
    # 1. Update Manifest
    logger.info("🔱 KALI: Re-anchoring Manifest...")
    integrity.generate_signatures()
    
    # 2. Update Recovery Baseline
    logger.info("🔱 KALI: Updating Recovery Baselines...")
    recovery_dir = os.path.join(root_dir, "data", "recovery")
    os.makedirs(recovery_dir, exist_ok=True)
    
    critical_files = [
        "src/core/vector_memory.py",
        "src/core/processor.py",
        "src/web_app.py",
        "src/kali_init.py"
    ]
    
    for rel_path in critical_files:
        src_path = os.path.join(root_dir, rel_path)
        if os.path.exists(src_path):
            dest_path = os.path.join(recovery_dir, os.path.basename(rel_path))
            shutil.copy2(src_path, dest_path)
            logger.info(f"Anchored {rel_path} to recovery.")
        else:
            logger.warning(f"File not found: {rel_path}")

    logger.info("🔱 KALI: Sovereignty Anchor Complete. System is now baseline.")

if __name__ == "__main__":
    anchor_current_state()
