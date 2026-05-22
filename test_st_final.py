import sys
import logging
from sentence_transformers import SentenceTransformer

logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger("TestST")

try:
    logger.info("Starting model load...")
    model = SentenceTransformer('all-MiniLM-L6-v2')
    logger.info("Model loaded. Encoding test...")
    emb = model.encode("Hello world")
    logger.info(f"Encoded. Shape: {emb.shape}")
    print("SUCCESS")
except Exception as e:
    logger.error(f"ST_CRASH: {e}")
    sys.exit(1)
