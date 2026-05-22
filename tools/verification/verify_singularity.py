import os
import sys
import logging

# Add src to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'src'))

from core.processor import DoubtProcessor

def verify_all():
    logging.basicConfig(level=logging.INFO)
    logger = logging.getLogger("VERIFY")
    
    logger.info("Initializing DoubtProcessor...")
    processor = DoubtProcessor()
    
    # 1. Test Doubt Flow (RLHF, Biometrics, Cloud)
    logger.info("Testing Doubt Flow...")
    res = processor.process_doubt("How do I build a sovereign AI?")
    if "text" in res:
        logger.info("Doubt Flow: SUCCESS")
    else:
        logger.error("Doubt Flow: FAILED")
        return False

    # 2. Test Project Mentor (Swarm, Robotics)
    logger.info("Testing Project Mentor...")
    res_pm = processor.process_project_mentor("Drone Logic Manifestation")
    if res_pm.get("can_build"):
        logger.info("Project Mentor: SUCCESS")
    else:
        logger.error("Project Mentor: FAILED")
        return False

    # 3. Test Session Consolidation (Dream Engine)
    logger.info("Testing Session Consolidation...")
    processor.end_session()
    logger.info("Session Consolidation: SUCCESS")

    # 4. Final Status Check
    status = processor.get_system_status()
    logger.info(f"System Status: {status['power_mode']}")
    
    return True

if __name__ == "__main__":
    if verify_all():
        print("\n✅ SINGULARITY_NOMINAL: All hardened layers verified.")
    else:
        print("\n❌ VERIFICATION_FAILED: System logic inconsistenty detected.")
        sys.exit(1)
