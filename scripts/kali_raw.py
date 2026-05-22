#!/usr/bin/env python3
import os
import sys
import logging
import time
import json
import uuid
import io

# SOVEREIGN: Windows UTF-8 Hardener
if sys.platform == 'win32':
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')

# Add project root and src to path
project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
sys.path.insert(0, project_root)
sys.path.insert(0, os.path.join(project_root, 'src'))

# Force Local Autonomy
os.environ["SOVEREIGN_FORCE_LOCAL"] = "true"
os.environ["USE_LOCAL_AI"] = "true"

from core.processor import DoubtProcessor
from core.integrity import IntegrityService

def setup_raw_logging():
    log_dir = os.path.join(project_root, "data", "logs")
    os.makedirs(log_dir, exist_ok=True)
    
    # Use simple ASCII for logging to avoid console encoding issues on Windows
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s [%(levelname)s] %(name)s: %(message)s',
        handlers=[
            logging.FileHandler(os.path.join(log_dir, "raw_cognition.log"), encoding='utf-8'),
            logging.StreamHandler(sys.stdout)
        ]
    )
    return logging.getLogger("RAW_KALI")

def main():
    logger = setup_raw_logging()
    logger.info("KALI SOVEREIGN: Entering RAW TERMINAL Mode...")
    
    # 1. Integrity Check
    integrity = IntegrityService(root_dir=project_root)
    is_intact, violations = integrity.verify_integrity(auto_repair=False)
    if not is_intact:
        logger.warning(f"BIOS ALERT: Integrity Breach Detected ({len(violations)} files).")
    else:
        logger.info("BIOS: Integrity Verified. System is Sovereign.")

    # 2. Initialize Processor
    logger.info("Initializing DoubtProcessor...")
    processor = DoubtProcessor(config={"project_root": project_root})
    
    # 3. Warmup Local AI
    logger.info("Warming up Local AI Gateway...")
    ai_service = getattr(processor, 'local_ai', getattr(processor, 'ai_service', None))
    
    if ai_service:
        # Check connection
        if ai_service.is_connected:
            logger.info(f"Ollama Connection Verified. Model: {ai_service.model}")
        else:
            logger.error("Ollama NOT detected. Please ensure 'ollama serve' is running.")
    else:
        logger.error("AI Service not found on processor.")

    print("\n" + "="*60)
    print(" KALI SOVEREIGN RAW TERMINAL")
    print(" Bypassing all Rich/Textual layers.")
    print("="*60 + "\n")

    while True:
        try:
            user_input = input("COMMANDER > ").strip()
            if not user_input:
                continue
            
            if user_input.lower() in ["exit", "quit", "shutdown"]:
                logger.info("Sovereign Shutdown Initiated.")
                break

            # PHASE 2: Input Execution Trace
            logger.info(f"INPUT_RECEIVED: {user_input}")
            
            start_time = time.time()
            
            # PHASE 3: Executor Validation
            logger.info("DISPATCHING_TO_PROCESSOR...")
            
            # Direct Processor Call
            # Fix: DoubtProcessor main method is process_doubt
            raw_response = processor.process_doubt(user_input)
            
            # Extract text from response dict
            if isinstance(raw_response, dict):
                response = raw_response.get("text", str(raw_response))
            else:
                response = str(raw_response)
            
            elapsed = time.time() - start_time
            
            # PHASE 4: Raw Response Rendering
            print(f"\nKALI RESPONSE [{elapsed:.2f}s]:")
            print("-" * 20)
            print(response)
            print("-" * 20 + "\n")
            
            logger.info(f"COGNITION_COMPLETE: {elapsed:.2f}s")

        except KeyboardInterrupt:
            print("\n[-] Interrupted by User.")
            break
        except Exception as e:
            logger.error(f"COGNITION_CRASH: {str(e)}")
            import traceback
            logger.error(traceback.format_exc())

if __name__ == "__main__":
    main()
