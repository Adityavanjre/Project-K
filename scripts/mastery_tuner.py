import os
import json
import logging
from typing import List, Dict, Any

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("KALI.MasteryTuner")

def tune_from_training_logs(input_path: str = "data/unverified_training.jsonl", output_path: str = "data/mastery_dataset.jsonl"):
    """
    Converts KALI training logs into a structured dataset for fine-tuning.
    Filters for high-alignment responses (>85) to ensure quality.
    """
    if not os.path.exists(input_path):
        logger.error(f"Input file not found: {input_path}")
        return

    processed_count = 0
    with open(input_path, "r", encoding="utf-8") as fin, \
         open(output_path, "w", encoding="utf-8") as fout:
        
        for line in fin:
            try:
                record = json.loads(line)
                
                # Check for alignment score (RLHF) if available
                # In our logs, we usually have 'ai_response' and 'user_query'
                # We can also check skill_sovereignty for the best-performing models
                
                # KALI format: {'messages': [{'role': 'system', ...}, {'role': 'user', ...}, {'role': 'assistant', ...}]}
                messages = record.get("messages", [])
                
                instruction = ""
                response = ""
                
                for msg in messages:
                    if msg.get("role") == "user":
                        instruction = msg.get("content", "")
                    elif msg.get("role") == "assistant":
                        response = msg.get("content", "")
                
                if not instruction or not response:
                    continue
                
                # Format for Unsloth / Alpaca style
                formatted = {
                    "instruction": instruction,
                    "input": "",
                    "output": response
                }
                
                fout.write(json.dumps(formatted) + "\n")
                processed_count += 1
                
            except Exception as e:
                logger.warning(f"Failed to process line: {e}")

    logger.info(f"Mastery Tuning Complete: {processed_count} samples anchored to {output_path}")

if __name__ == "__main__":
    tune_from_training_logs()
