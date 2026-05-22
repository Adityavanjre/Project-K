import os
import sys
import json
import logging

project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
sys.path.insert(0, os.path.join(project_root, 'src'))

from core.knowledge_check import KnowledgeCheckEngine
from unittest.mock import MagicMock

def test_anchoring_live():
    logging.basicConfig(level=logging.INFO)
    logger = logging.getLogger("TEST_ANCHOR")

    # 1. Setup paths
    unverified = os.path.join(project_root, "data", "unverified_training.jsonl")
    anchored = os.path.join(project_root, "data", "training_data.jsonl")
    
    # 2. Create a mock record in unverified
    topic = "TEST_TOPIC_ANCHOR: The engine uses Python and JSON."
    record = {
        "messages": [
            {"role": "user", "content": topic},
            {"role": "assistant", "content": "KALI uses Python and JSON for anchoring logic."}
        ],
        "source": "test_anchor"
    }
    with open(unverified, "a", encoding="utf-8") as f:
        f.write(json.dumps(record) + "\n")
    
    logger.info(f"Created unverified record for topic: {topic}")

    # 3. Init Engine with mock AI that will 'pass' this topic
    mock_ai = MagicMock()
    # Return keywords that match 'Python and JSON'
    mock_ai.ask_question.return_value = "Python and JSON" 
    
    engine = KnowledgeCheckEngine(ai_service=mock_ai, project_root=project_root)
    
    # 4. Trigger the check (manually forcing success)
    # We bypass run_check's question generation to ensure PASS
    # and call _mark_success directly to test the ANCHOR logic.
    logger.info("Triggering _mark_success manually...")
    engine._mark_success(topic, 100.0, [{"question": "What tools?", "score": 100, "expected": "Python and JSON", "kali_answer": "Python and JSON"}])
    
    # 5. Verify anchoring
    if os.path.exists(anchored):
        with open(anchored, "r", encoding="utf-8") as f:
            lines = f.readlines()
            if any(topic in l for l in lines):
                logger.info("SUCCESS: Record found in anchored training_data.jsonl")
            else:
                logger.error("FAILURE: Record NOT found in anchored training_data.jsonl")
    
    if os.path.exists(unverified):
        with open(unverified, "r", encoding="utf-8") as f:
            lines = f.readlines()
            if any(topic in l for l in lines):
                logger.error("FAILURE: Record still in unverified_training.jsonl")
            else:
                logger.info("SUCCESS: Record removed from unverified_training.jsonl")

if __name__ == "__main__":
    test_anchoring_live()
