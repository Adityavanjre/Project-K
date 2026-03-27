import json
import os
from datetime import datetime
from typing import Optional
import logging

logger = logging.getLogger(__name__)

class TrainingLogger:
    """
    Appends every AI interaction to a JSONL file.
    Format matches OpenAI/HuggingFace fine-tuning standard.
    Auto-queues a KnowledgeCheckEngine check after every log.
    """
    def __init__(self, path="data/unverified_training.jsonl", knowledge_check=None):
        self.path = path
        self.knowledge_check = knowledge_check  # KnowledgeCheckEngine injected by processor
        # Ensure 'data' directory exists
        os.makedirs(os.path.dirname(os.path.abspath(path)), exist_ok=True)

    def log(self, user_msg: str, ai_response: str, system_prompt: str = "", source: str = "kali_live", context: str = "general"):
        """Log a single interaction to the training dataset and queue a knowledge check."""
        if not user_msg.strip() or not ai_response.strip():
            return
            
        record = {
            "messages": [
                {"role": "system",    "content": system_prompt or "You are KALI, an advanced AI mentor."},
                {"role": "user",      "content": user_msg},
                {"role": "assistant", "content": ai_response}
            ],
            "timestamp": datetime.now().isoformat(),
            "source": source
        }
        
        try:
            with open(self.path, "a", encoding="utf-8") as f:
                f.write(json.dumps(record) + "\n")
        except Exception as e:
            print(f"FAILED TO LOG TRAINING DATA: {e}")
            return

        # Auto-queue knowledge check for this interaction
        # Skips channel-internal sources to avoid infinite loops
        skip_sources = {"knowledge_check", "stress_test", "error_replay"}
        if self.knowledge_check and source not in skip_sources:
            try:
                self.knowledge_check.queue_check(user_msg[:200], ai_response, context=context)
            except Exception as e:
                logger.debug(f"Knowledge check queue failed (non-critical): {e}")
