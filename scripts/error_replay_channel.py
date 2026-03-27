#!/usr/bin/env python3
"""
KALI ERROR REPLAY CHANNEL (Phase 4.31)
Re-trains on past failed interactions (Review Alert score < 70).
Turns every failure into a high-quality DPO pair.
"""

import json
import logging
import os
import sys

project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
sys.path.insert(0, project_root)
sys.path.insert(0, os.path.join(project_root, 'src'))

from src.core.processor import DoubtProcessor


def run_error_replay(max_replays: int = 5):
    logging.basicConfig(level=logging.INFO)
    logger = logging.getLogger("ERROR_REPLAY")
    processor = DoubtProcessor()

    failures_path = os.path.join(project_root, "data", "training_failures.jsonl")
    dpo_path = os.path.join(project_root, "data", "dpo_data.jsonl")

    if not os.path.exists(failures_path):
        logger.info("No training failures to replay. All clean.")
        return

    # Load pending failures
    with open(failures_path, "r", encoding="utf-8") as f:
        failures = [json.loads(l) for l in f if l.strip()]

    if not failures:
        logger.info("No pending failures. Channel idle.")
        return

    to_replay = failures[:max_replays]
    remaining = failures[max_replays:]

    logger.info(f"Error Replay Channel: Replaying {len(to_replay)} failed training topics.")

    for failure in to_replay:
        topic = failure.get("topic", "unknown")
        gap = failure.get("gap", "")
        retry_prompt = failure.get(
            "retry_prompt",
            f"Provide a comprehensive, detailed explanation of: {topic}. Address this gap: {gap}"
        )

        logger.info(f"[REPLAY] Topic: {topic[:60]} | Gap: {gap[:60]}")

        # Generate an improved answer specifically targeting the gap
        improved = processor.ai_service.ask_question(
            f"CRITICAL KNOWLEDGE GAP REMEDIATION.\n"
            f"Topic: {topic}\n"
            f"Identified Gap: {gap}\n\n"
            f"Provide a COMPLETE, PRECISE, technically rigorous explanation. "
            f"Ensure all key facts, formulas, and practical steps are covered. "
            f"Leave no ambiguity."
        )

        # Log as improved training interaction
        processor.training_logger.log(retry_prompt, improved, "You are KALI, an advanced AI mentor.")

        # Log as DPO pair (improved = chosen)
        original_topic_prompt = f"Explain: {topic}"
        dpo_entry = {
            "prompt": original_topic_prompt,
            "chosen": improved,
            "rejected": f"[PREVIOUS FAILED RESPONSE - Gap: {gap}]",
            "metadata": {
                "source": "error_replay_channel",
                "original_gap": gap,
                "gap_score": failure.get("score", 0)
            }
        }
        with open(dpo_path, "a", encoding="utf-8") as f:
            f.write(json.dumps(dpo_entry) + "\n")

        logger.info(f"[+] Replay Complete. Gap remediated and DPO pair anchored.")

    # Write back remaining failures
    with open(failures_path, "w", encoding="utf-8") as f:
        for item in remaining:
            f.write(json.dumps(item) + "\n")

    logger.info(f"Error Replay Channel complete. {len(remaining)} failures remain in queue.")


if __name__ == "__main__":
    run_error_replay()
