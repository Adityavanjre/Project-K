import sys
import os
import logging

# Set up logging to stdout
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("VERIFY")

# Add project root to path
sys.path.append(os.path.join(os.getcwd(), "src"))
sys.path.append(os.getcwd())

try:
    from core.processor import DoubtProcessor
    from utils.helpers import load_config
    
    config = load_config("config/config.json")
    logger.info("Initializing DoubtProcessor...")
    processor = DoubtProcessor(config)
    logger.info("DoubtProcessor initialized successfully!")
    
    # Check for service_registry
    if hasattr(processor, "service_registry"):
        logger.info(f"Service Registry Found: {list(processor.service_registry.keys())}")
    else:
        logger.error("Service Registry MISSING!")
        sys.exit(1)
        
    # Check for ollama_url in local_ai
    if hasattr(processor.local_ai, "ollama_url"):
        logger.info(f"Ollama URL Found: {processor.local_ai.ollama_url}")
    else:
        logger.error("Ollama URL MISSING in local_ai!")
        sys.exit(1)

    print("--- SUCCESS ---")
except Exception as e:
    logger.error(f"Validation FAILED: {e}")
    import traceback
    traceback.print_exc()
    sys.exit(1)
