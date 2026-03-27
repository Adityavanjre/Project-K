#!/usr/bin/env python3
"""
KALI KNOWLEDGE CHECK RUNNER (Phase 4.30)
Lightweight standalone script — does NOT init the full DoubtProcessor.
Directly uses AIService + KnowledgeCheckEngine to avoid COM3/RoboticBridge crashes.

Seeds pending checks from training_data.jsonl if no queue exists yet.
"""

import logging
import os
import sys
import json

project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
sys.path.insert(0, project_root)
sys.path.insert(0, os.path.join(project_root, 'src'))

from src.core.ai_service import AIService
from src.core.knowledge_check import KnowledgeCheckEngine

logging.basicConfig(level=logging.WARNING)  # Suppress INFO noise from imports


def _seed_from_training_data(engine: KnowledgeCheckEngine, training_path: str, limit: int = 20):
    """
    Queue knowledge checks from the last `limit` entries in training_data.jsonl.
    Used on first run when no pending checks exist yet.
    """
    logger = logging.getLogger("KNOWLEDGE_SEED")
    logger.setLevel(logging.INFO)

    if not os.path.exists(training_path):
        print(f"No training data found at: {training_path}")
        return 0

    with open(training_path, "r", encoding="utf-8") as f:
        lines = [l.strip() for l in f if l.strip()]

    # Take up to `limit` lines from the tail (most recent interactions)
    selected = lines[-limit:]
    queued = 0
    for line in selected:
        try:
            record = json.loads(line)
            messages = record.get("messages", [])
            user_msg = next((m["content"] for m in messages if m["role"] == "user"), "")
            ai_msg = next((m["content"] for m in messages if m["role"] == "assistant"), "")
            if user_msg and ai_msg and len(ai_msg) > 30:
                engine.queue_check(user_msg[:200], ai_msg)
                queued += 1
        except Exception:
            continue

    print(f"Seeded {queued} knowledge checks from existing training data.")
    return queued


def run_knowledge_checks(max_checks: int = 20):
    print("\nKALI Knowledge Check Runner initializing...")

    # Lightweight init — no full processor, no COM3, no robotic bridge
    ai_service = AIService({})
    engine = KnowledgeCheckEngine(ai_service=ai_service, project_root=project_root)

    pending_path = engine.pending_path
    training_path = os.path.join(project_root, "data", "training_data.jsonl")

    # Seed from existing data if queue is empty
    pending_count = 0
    if os.path.exists(pending_path):
        with open(pending_path, "r", encoding="utf-8") as f:
            pending_count = sum(1 for l in f if l.strip())

    if pending_count == 0:
        print("No pending checks found. Seeding from training_data.jsonl...")
        seeded = _seed_from_training_data(engine, training_path, limit=max_checks)
        if seeded == 0:
            print("No training data to check. Run some training sessions first.")
            return
        pending_count = seeded

    print(f"Running {min(max_checks, pending_count)} checks...")
    results = engine.run_pending_checks(limit=max_checks)

    if not results:
        print("No results returned. Check logs for errors.")
        return

    # Summary table
    print("\n" + "="*80)
    print("KALI KNOWLEDGE CHECK RESULTS")
    print("="*80)
    print(f"{'STATUS':<10} {'SCORE':<8} {'TOPIC':<55}")
    print("-"*80)

    passed = 0
    failed = 0
    skipped = 0
    for result in results:
        status = result.get("status", "UNKNOWN")
        score = result.get("score")
        topic = result.get("topic", "")[:55]
        if status == "PASSED":
            mark = "[PASS]"
            passed += 1
        elif status == "FAILED":
            mark = "[FAIL]"
            failed += 1
        else:
            mark = "[SKIP]"
            skipped += 1
        score_str = f"{score}%" if score is not None else "N/A"
        print(f"{mark:<10} {score_str:<8} {topic}")

    print("-"*80)

    # Overall stats
    stats = engine.get_pass_rate()
    
    # Phase 4.50: Granular Atom Tracking
    atom_count = 0
    if os.path.exists(engine.anchored_path):
        with open(engine.anchored_path, "r", encoding="utf-8") as f:
            for line in f:
                if "VERIFIED_100" in line:
                    atom_count += 1
            
    unverified_count = 0
    if os.path.exists(engine.unverified_path):
        with open(engine.unverified_path, "r", encoding="utf-8") as f:
            unverified_count = sum(1 for l in f if l.strip())

    print(f"\nThis Run : Passed {passed} / {passed + failed} checks ({skipped} skipped)")
    
    print("\n" + "-"*40)
    print("KALI EVOLUTIONARY VELOCITY DASHBOARD")
    print("-" * 40)
    print(f"Sovereign Core (Atoms)    : {atom_count}")
    print(f"Quarantine (Unverified)   : {unverified_count} interactions")
    print(f"Pending Checks in Queue   : {pending_count} topics")
    
    if stats["total"] > 0 or atom_count > 0:
        pass_rate = stats.get('pass_rate', 0)
        avg_score = stats.get('avg_score', 0)
        print(f"Aggregate Pass Rate       : {pass_rate}%")
        print(f"Knowledge Accuracy        : {avg_score}%")
        # Sovereignty Calculation: (PassRate * 0.5) + (AtomCount / 100 * 50)
        sovereignty = (pass_rate * 0.5) + (min(50, (atom_count / 10)))
        print(f"SYSTEM SOVEREIGNTY LEVEL : {min(100, round(sovereignty, 1))}%")
    else:
        print("SYSTEM SOVEREIGNTY LEVEL : CALCULATING...")
    print("-" * 40)


    # Show failures
    failures_path = engine.failures_path
    if os.path.exists(failures_path):
        with open(failures_path, "r", encoding="utf-8") as f:
            failures = [json.loads(l) for l in f if l.strip()]

        if failures:
            print(f"\n{len(failures)} topics queued for Error Replay:")
            for i, failure in enumerate(failures[-5:], 1):
                if not isinstance(failure, dict): continue
                score_val = failure.get("score", 0)
                print(f"  {i}. [{score_val:.0f}%] {failure.get('topic', '')[:60]}")
                print(f"       Gap: {failure.get('gap', '')[:75]}")
            if len(failures) > 5:
                print(f"  ... and {len(failures)-5} more.")
            print("\nFix with: .\\venv_new\\Scripts\\python.exe scripts/error_replay_channel.py")

    if failed == 0 and passed > 0:
        print("\nAll checks passed. KALI has retained all tested training material.")


if __name__ == "__main__":
    max_checks = int(sys.argv[1]) if len(sys.argv) > 1 else 20
    run_knowledge_checks(max_checks)

