import json
import os
from datetime import datetime

class TrainingLogger:
    """
    Appends every AI interaction to a JSONL file.
    Format matches OpenAI/HuggingFace fine-tuning standard.
    """
    def __init__(self, path="data/training_data.jsonl"):
        self.path = path
        # Ensure 'data' directory exists
        os.makedirs(os.path.dirname(os.path.abspath(path)), exist_ok=True)

    def log(self, user_msg: str, ai_response: str, system_prompt: str = ""):
        """Log a single interaction to the training dataset."""
        if not user_msg.strip() or not ai_response.strip():
            return
            
        record = {
            "messages": [
                {"role": "system",    "content": system_prompt or "You are KALI, an advanced AI mentor."},
                {"role": "user",      "content": user_msg},
                {"role": "assistant", "content": ai_response}
            ],
            "timestamp": datetime.now().isoformat(),
            "source": "kali_live"
        }
        
        try:
            with open(self.path, "a", encoding="utf-8") as f:
                f.write(json.dumps(record) + "\n")
        except Exception as e:
            # Silent failure for logging to avoid crashing the main processor
            print(f"FAILED TO LOG TRAINING DATA: {e}")
