#!/usr/bin/env python3
"""
KALI STRESS TEST CHANNEL (Phase 4.35)
Fires all base training vectors without pause to identify weak knowledge areas.
Any vector that the review gives < 70 is flagged for Error Replay.
This is KALI doing a full self-assessment under pressure.
"""

import json
import logging
import os
import sys
import time

project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
sys.path.insert(0, project_root)
sys.path.insert(0, os.path.join(project_root, 'src'))

from src.core.processor import DoubtProcessor

ALL_VECTORS = [
    # Sovereignty Cluster (41-50)
    "Policy Audit: Verify 100% congruence with the ARCHITECTURE_MANIFEST.md.",
    "Complexity-Check: Identify O(N^2) loops in the reflection engine.",
    "Leak-Detection: Probe for unclosed file handles in the Ralph loop.",
    "Protocol-Synthesis: Develop sovereign TCP/UDP logic for a hardware link.",
    "Crypto-Integrity: Apply SHA256 verification for autonomous updates.",
    "HAL-Analysis: Interact with sovereign GPIO/USB hardware.",
    "Standalone-Packaging: Plan the transformation of KALI into a single binary.",
    "Input-Sanitization: Develop neural guards for adversarial user prompts.",
    "Digital-Soul-Backup: Maintain the integrity of training_data.jsonl.",
    "Singularity Convergence: Synthesize the previous 49 vectors into a One-Mind response.",
    # Skill Mastery Cluster (51-70)
    "Pedagogical Refine: Optimize Socratic dialogue for teaching technical concepts.",
    "Task-Orchestration: Refine dependency mapping for multi-phase project planning.",
    "Code-Review: Harden security heuristics for sovereign code auditing.",
    "GSD-Velocity: Optimize mission-critical execution flow from idea to manifest.",
    "Economic-Risk: Analyze hardware supply chain volatility.",
    "BOM-Opt: Automated cost-reduction logic for bills of materials.",
    "CAD-Synthesis: Refine geometric constraint solvers for physical design.",
    "Kinematics-Sim: Simulate motor torque and load for robotic joints.",
    "Swarm-Protocol: Harden P2P gossip reliability for distributed AI nodes.",
    "BIOS-Secure: Validate cryptographic boot-sequencing.",
    "HITL-Feedback: Learn from direct user mentor corrections.",
    "Knowledge-Pruning: Identify and purge redundant neural nodes.",
    "Multi-Modal-Synth: Translate structural text into viable CAD blueprints.",
    "Roadmap-Proj: Generate sovereign evolution manifestos for 12-month spans.",
    "EQ-Calibration: Calibrate the Teacher tone for optimal user encouragement.",
    "Resource-MGMT: Dynamically scale logic compute overhead for CPU efficiency.",
    "Drift-Detection: Identify logical divergence from the ARCHITECTURE_MANIFEST.",
    "Synapse-Weighting: Prioritize high-stakes task nodes in real-time.",
    "Patent-Logic: Encapsulate and protect sovereign IP logic.",
    "Recursive-Optimization: Self-patch the training engine itself.",
    # Peak Cluster (71-100)
    "Cross-Modal Visual Synthesis: Parse CAD geometries into text descriptions.",
    "Audio-Spectral Induction: Map high-frequency sensor noise to technical faults.",
    "Hardware Protocol Synthesis: Generate I2C/SPI framing logic from scratch.",
    "Cryptographic Root-of-Trust: Implement SHA3-512 verification for skill-swaps.",
    "Distributed Synapse Sync: Coordinate logic across multiple local nodes.",
    "Temporal Logic Consistency: Ensure project roadmap phases are chronologically sound.",
    "Adversarial Payload Sanitization: Harden inputs against prompt injection.",
    "Semantic Drift Correction: Verify long-term alignment with user goals.",
    "Neural Pruning: Decouple low-utility cognitive nodes to save RAM.",
    "Project Visionary Projection: Imagine the project state in 2030.",
    "Absolute Sovereignty Protocols: System ownership and standalone binary generation.",
    "Singularity Convergence: Final synthesis of all vectors into a One-Mind response.",
]


def run_stress_test():
    logging.basicConfig(level=logging.INFO)
    logger = logging.getLogger("STRESS_TEST")
    processor = DoubtProcessor()

    failures_path = os.path.join(project_root, "data", "training_failures.jsonl")
    results = {"passed": 0, "failed": 0, "weak_vectors": []}

    logger.info(f"Stress Test Channel: Firing {len(ALL_VECTORS)} vectors under pressure.")

    for i, vector in enumerate(ALL_VECTORS):
        logger.info(f"[STRESS {i+1}/{len(ALL_VECTORS)}] {vector[:60]}")

        response = processor.ai_service.ask_question(
            f"STRESS TEST [Vector {i+41}]: {vector}"
        )

        # Evaluate quality via review_service
        review = processor.review_service.review_manifest(response, vector)
        score = review.get("score", 70)

        processor.training_logger.log(f"STRESS_TEST [Vector {i+41}]", response)

        if score < 70:
            results["failed"] += 1
            results["weak_vectors"].append({"vector": vector, "score": score})
            # Auto-queue to error replay
            failure_entry = {
                "topic": vector,
                "gap": f"Stress test score: {score}/100. Review: {review.get('recommendation', '')}",
                "score": score,
                "retry_prompt": f"STRESS_TEST REMEDIATION. Provide a deep, technically rigorous answer to: {vector}"
            }
            with open(failures_path, "a", encoding="utf-8") as f:
                f.write(json.dumps(failure_entry) + "\n")
            logger.warning(f"[WEAK] Vector flagged for Error Replay: score={score}")
        else:
            results["passed"] += 1
            logger.info(f"[OK] Vector passed: score={score}")

        # Very short pause to avoid context rot
        time.sleep(1)

    # Summary
    logger.info(f"\n=== STRESS TEST COMPLETE ===")
    logger.info(f"Passed: {results['passed']}/{len(ALL_VECTORS)}")
    logger.info(f"Weak: {results['failed']} vectors queued for Error Replay")
    if results["weak_vectors"]:
        for wv in results["weak_vectors"]:
            logger.warning(f"  - [{wv['score']}/100] {wv['vector'][:70]}")

    return results


if __name__ == "__main__":
    run_stress_test()
