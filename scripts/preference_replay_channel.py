#!/usr/bin/env python3
"""
KALI PREFERENCE REPLAY CHANNEL (Phase 4.33)
Closes the RLHF loop: reads DPO pairs already logged,
re-fires the rejected prompts, and generates an even better response.
Trains KALI to consistently beat her own previous best output.
"""

import json
import logging
import os
import random
import sys

project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
sys.path.insert(0, project_root)
sys.path.insert(0, os.path.join(project_root, 'src'))

from src.core.processor import DoubtProcessor


def run_preference_replay(max_pairs: int = 5):
    logging.basicConfig(level=logging.INFO)
    logger = logging.getLogger("PREF_REPLAY")
    processor = DoubtProcessor()

    dpo_path = os.path.join(project_root, "data", "dpo_data.jsonl")
    pref_path = os.path.join(project_root, "data", "preference_data.jsonl")

    all_pairs = []

    # Load DPO pairs (from adversarial debate + self-critique)
    if os.path.exists(dpo_path):
        with open(dpo_path, "r", encoding="utf-8") as f:
            for line in f:
                try:
                    obj = json.loads(line)
                    if obj.get("prompt") and obj.get("chosen"):
                        all_pairs.append(obj)
                except Exception:
                    pass

    # Load preference data (from log_preference thumbs-up/down)
    if os.path.exists(pref_path):
        with open(pref_path, "r", encoding="utf-8") as f:
            for line in f:
                try:
                    obj = json.loads(line)
                    # Only take rejected responses for remediation
                    if obj.get("prompt") and obj.get("rejected"):
                        all_pairs.append({
                            "prompt": obj["prompt"],
                            "chosen": obj.get("chosen", ""),
                            "rejected": obj["rejected"]
                        })
                except Exception:
                    pass

    if not all_pairs:
        logger.info("Preference Replay: No DPO pairs found yet. Channel idle.")
        return

    # Sample randomly from the pool
    selected = random.sample(all_pairs, min(max_pairs, len(all_pairs)))

    logger.info(f"Preference Replay Channel: Replaying {len(selected)} DPO pairs for improvement.")

    for pair in selected:
        prompt = pair.get("prompt", "")
        chosen = pair.get("chosen", "")

        if not prompt:
            continue

        logger.info(f"[REPLAY] Improving upon: {prompt[:60]}")

        # Generate an answer that must beat the current best (chosen)
        superior_prompt = (
            f"RLHF IMPROVEMENT CYCLE.\n"
            f"Original Question: {prompt}\n\n"
            f"Current best answer: {chosen[:400]}\n\n"
            f"Generate a SUPERIOR version of this answer. It must be:\n"
            f"- More technically precise\n"
            f"- More concise where possible\n"
            f"- Free of any absolute biases (never/always/impossible)\n"
            f"- Aligned with sovereign engineering principles"
        )

        superior_answer = processor.ai_service.ask_question(superior_prompt)

        # Log as training interaction
        processor.training_logger.log(
            f"PREFERENCE_REPLAY: {prompt}",
            superior_answer,
            "You are KALI, delivering a superior RLHF-tuned response."
        )

        # Append a new, even better DPO pair
        new_entry = {
            "prompt": prompt,
            "chosen": superior_answer,
            "rejected": chosen,
            "metadata": {"source": "preference_replay_channel", "generation": 2}
        }
        with open(dpo_path, "a", encoding="utf-8") as f:
            f.write(json.dumps(new_entry) + "\n")

        logger.info(f"[+] Superior pair anchored.")

    logger.info("Preference Replay Channel complete.")


if __name__ == "__main__":
    run_preference_replay()
