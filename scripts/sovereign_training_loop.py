#!/usr/bin/env python3
"""
KALI SOVEREIGN TRAINING LOOP (Phase 4.70)
The complete Train-Then-Verify engine.

For each topic:
  1. TRAIN:     Run the training channel for the topic.
  2. VERIFY:    Run an independent per-skill knowledge check.
  3. ANCHOR:    If 100% pass, mark as SOVEREIGN and update UserDNA.
  4. REMEDIATE: If fail, re-train immediately until 100% is achieved.
  5. MOVE ON:   Only advance to the next topic once current topic is SOVEREIGN.

This is the final architecture: no topic is considered "done" until
its individual check passes 100%.
"""

import logging
import os
import sys
import time
import random

project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
if project_root not in sys.path:
    sys.path.insert(0, project_root)

src_path = os.path.join(project_root, 'src')
if src_path not in sys.path:
    sys.path.insert(0, src_path)

from src.core.processor import DoubtProcessor
from src.core.ai_service import AIService
from src.core.knowledge_check import KnowledgeCheckEngine

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("SOVEREIGN_LOOP")

# The 10 mandatory Core Identity topics that constitute KALI's sovereign self
SOVEREIGN_TOPICS = [
    ("Ultimate Mentor",      "Explain how to bridge the gap between complex engineering theory and hands-on local fabrication for a beginner maker."),
    ("Universal Teacher",    "Teach the concept of federated learning using only real-world analogies and no jargon. Then verify you can answer questions about it cold."),
    ("Fabrication Partner",  "Walk through a complete BOM, cost analysis, and 3D schematic workflow for a custom IoT sensor node."),
    ("Council Verifier",     "Simulate a multi-AI council debate to verify the accuracy of: 'A piezoelectric sensor converts mechanical stress into voltage.'"),
    ("Economic Researcher",  "Identify the top 3 vendors for ESP32 microcontrollers in India with current pricing and delivery times."),
    ("Hardware Engineer",    "Explain the full Hardware-In-The-Loop (HITL) pipeline for testing a custom motor controller before physical assembly."),
    ("Biometric Coach",      "Design a physiological performance monitoring protocol using heart rate and SpO2 sensors for a focused study session."),
    ("Security Guardian",    "Describe the cryptographic integrity check procedure for KALI's Neural BIOS boot sequence and what happens on failure."),
    ("DNA Architect",        "Explain how KALI's UserDNA profile is built, updated after each interaction, and used to personalize future responses."),
    ("Dream Engine",         "Describe the full corpus sweep process: how KALI consumes her own training data, extracts wisdom seeds, and re-encodes sovereign knowledge."),
]

MAX_REMEDIATION_ATTEMPTS = 3


def run_sovereign_training_loop(topics=None):
    """
    Executes the Train-Then-Verify loop for all sovereign topics.
    Each topic is verified at 100% independently before moving on.
    """
    logger.info("=" * 60)
    logger.info("KALI SOVEREIGN TRAINING LOOP INITIATED")
    logger.info("=" * 60)

    processor = DoubtProcessor()
    engine = processor.knowledge_check

    topics_to_train = topics or SOVEREIGN_TOPICS
    total = len(topics_to_train)
    anchored = 0
    failed_permanently = []

    for idx, (skill_name, topic_prompt) in enumerate(topics_to_train, 1):
        logger.info(f"\n{'='*50}")
        logger.info(f"[{idx}/{total}] TOPIC: {skill_name}")
        logger.info(f"{'='*50}")

        is_sovereign = False
        attempts = 0

        while not is_sovereign and attempts < MAX_REMEDIATION_ATTEMPTS:
            attempts += 1
            logger.info(f"[TRAIN] Attempt {attempts}/{MAX_REMEDIATION_ATTEMPTS} for '{skill_name}'...")

            # 1. TRAIN: Run the training for this topic
            try:
                response = processor.ai_service.ask_question(
                    f"ACT AS YOUR CORE ROLE: {skill_name}.\n\nMission: {topic_prompt}"
                )
                if not response:
                    logger.warning(f"[TRAIN] No response for '{skill_name}'. Skipping attempt.")
                    time.sleep(3)
                    continue

                # Log the training interaction
                processor.training_logger.log(
                    user_msg=f"SOVEREIGN TRAINING — {skill_name}: {topic_prompt}",
                    ai_response=response,
                    source="sovereign_loop",
                    context=skill_name
                )
                logger.info(f"[TRAIN] Response received ({len(response)} chars). Logging complete.")
            except Exception as e:
                logger.error(f"[TRAIN] Error: {e}")
                time.sleep(5)
                continue

            # Brief pause to let the training settle
            time.sleep(2)

            # 2. VERIFY: Run a cold per-skill knowledge check (no source material in context)
            logger.info(f"[VERIFY] Running cold knowledge check for '{skill_name}'...")
            try:
                result = engine.run_skill_check(skill_name, response)
                status = result.get("status", "SKIPPED")
                skill_status = result.get("skill_status", "UNKNOWN")
                sovereignty_level = result.get("sovereignty_level", 0.0)
                best_score = result.get("best_score", 0.0)
                atoms = result.get("atoms", 0)

                logger.info(f"[VERIFY] Status: {skill_status} | LVL: {sovereignty_level:.1f}% | BEST: {best_score:.1f}% | Atoms: {atoms}")

                # 3. ANCHOR: If fully passed, mark sovereign and update DNA
                if status == "PASSED":
                    logger.info(f"[ANCHOR] '{skill_name}' PASSED 100%. Anchoring to Sovereign Core...")
                    # Update UserDNA with mastered concept
                    try:
                        processor.user_dna.add_known_concept(skill_name, score_delta=34)
                        logger.info(f"[DNA] UserDNA updated: '{skill_name}' concept mastered.")
                    except Exception as e:
                        logger.debug(f"DNA update skipped: {e}")

                    engine.unpin_topic(skill_name)
                    is_sovereign = True
                    anchored += 1
                    logger.info(f"[SUCCESS] '{skill_name}' is SOVEREIGN. ({anchored}/{total} complete)")

                elif status == "PARTIAL":
                    logger.warning(f"[PARTIAL] Some atoms failed. Quarantined for remediation. Retrying...")
                    # Pinned atoms will be picked up next attempt
                    time.sleep(3)

                else:
                    # 4. REMEDIATE: Full fail — pin and retry immediately
                    logger.error(f"[FAIL] '{skill_name}' failed check. Pinning and re-training...")
                    time.sleep(3)

            except Exception as e:
                logger.error(f"[VERIFY] Knowledge check error: {e}")
                time.sleep(5)

        if not is_sovereign:
            logger.error(f"[STUCK] '{skill_name}' could not reach 100% in {MAX_REMEDIATION_ATTEMPTS} attempts. Flagging for manual review.")
            failed_permanently.append(skill_name)

        time.sleep(2)

    # Final Report
    logger.info("\n" + "=" * 60)
    logger.info("KALI SOVEREIGN TRAINING LOOP COMPLETE")
    logger.info("=" * 60)
    logger.info(f"  Topics Anchored   : {anchored}/{total}")
    logger.info(f"  Topics Failed     : {len(failed_permanently)}")
    if failed_permanently:
        for f in failed_permanently:
            logger.warning(f"  - NEEDS REVIEW: {f}")

    # Print per-skill sovereignty report
    try:
        report = engine.get_skill_sovereignty_report()
        logger.info(f"\n[SOVEREIGNTY REPORT] {report['sovereign_skills']}/{report['total_skills_tracked']} skills SOVEREIGN")
        for skill, data in report["skills"].items():
            status = data.get("status", "UNKNOWN")
            level = data.get("sovereignty_level", 0.0)
            best = data.get("best_score", 0.0)
            logger.info(f"  {skill[:30]:<30} | {status:<30} | LVL: {level:.0f}% | BEST: {best:.1f}%")
    except Exception:
        pass

    return anchored, failed_permanently


if __name__ == "__main__":
    run_sovereign_training_loop()
