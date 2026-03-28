import json
import os
import logging
from datetime import datetime
from typing import Optional
from utils.pii_scrubber import PiiScrubber

logger = logging.getLogger(__name__)

class TrainingLogger:
    """
    Appends every AI interaction to a JSONL file.
    Format matches OpenAI/HuggingFace fine-tuning standard.
    """
    def __init__(self, path="data/unverified_training.jsonl", knowledge_check=None):
        self.path = path
        self.knowledge_check = knowledge_check
        os.makedirs(os.path.dirname(os.path.abspath(path)), exist_ok=True)

    def _scrub_pii(self, text: str, user_name: Optional[str] = None) -> str:
        """Sovereign PII Scrubbing (Phase 55: P-1)."""
        return PiiScrubber.scrub(text, user_name=user_name)

    def log(self, user_msg: str, ai_response: str, system_prompt: str = "", 
            source: str = "kali_live", context: str = "general", 
            model: str = "unknown", has_consent: bool = False,
            user_name: Optional[str] = None):
        """
        Log interaction to training dataset. 
        Gated by 'has_consent' to ensure privacy compliance.
        """
        if not has_consent:
            # Silence logging if no consent is granted
            return

        if not user_msg.strip() or not ai_response.strip():
            return
            
        # Scrub PII before logging (Phase 55: P-1)
        clean_user = self._scrub_pii(user_msg, user_name=user_name)
        clean_ai = self._scrub_pii(ai_response, user_name=user_name)
        
        record = {
            "messages": [
                {"role": "system",    "content": system_prompt or "You are KALI, an advanced AI mentor."},
                {"role": "user",      "content": clean_user},
                {"role": "assistant", "content": clean_ai}
            ],
            "timestamp": datetime.now().isoformat(),
            "source": source,
            "model": model,
            "pii_scrubbed": True
        }
        
        try:
            with open(self.path, "a", encoding="utf-8") as f:
                f.write(json.dumps(record) + "\n")
        except Exception as e:
            logger.error(f"FAILED TO LOG TRAINING DATA: {e}")
            return

        # Auto-queue knowledge check
        skip_sources = {"knowledge_check", "stress_test", "error_replay"}
        if self.knowledge_check and source not in skip_sources:
            try:
                self.knowledge_check.queue_check(clean_user[:200], clean_ai, context=context)
            except Exception as e:
                logger.debug(f"Knowledge check queue failed: {e}")
