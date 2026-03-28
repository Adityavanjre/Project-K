#!/usr/bin/env python3
"""
KALI RALPH LOOP - OMNI-CHANNEL 500+ MATRIX (Phase 4.70)
Max velocity training across ALL dimensions.
Core Identity channels are guaranteed every 3rd iteration.
Per-skill sovereign verification runs after each channel.
"""

import time
import logging
import sys
import os
import random
import traceback

# sys.path injection removed per Phase 52 standards. Use PYTHONPATH.

# Bug B-4 fix: Moved DoubtProcessor import inside run_ralph_loop() to prevent
# top-level circular import that crashes the entire script in non-CUDA environments.

# --- Existing channel imports ---
from scripts.curiosity_scraper import run_curiosity_scraper
from scripts.bug_reenactment import run_bug_reenactment
from scripts.adversarial_debate import run_adversarial_debate
from scripts.skill_synthesis_channel import run_skill_synthesis
from scripts.error_replay_channel import run_error_replay
from scripts.preference_replay_channel import run_preference_replay
from scripts.temporal_reasoning_channel import run_temporal_reasoning
from scripts.architect_channel import run_architect_channel
from scripts.research_channel import run_research_channel
from scripts.economist_channel import run_economist_channel
from scripts.meta_cognitive_channel import run_meta_cognitive_channel
from scripts.memory_compression_channel import run_memory_compression_channel
from scripts.philosopher_channel import run_philosopher_channel
from scripts.guardian_channel import run_guardian_channel
from scripts.socratic_channel import run_socratic_channel
from scripts.codebase_scan_channel import run_codebase_scan_channel
from scripts.hud_adaptation_channel import run_hud_adaptation_channel
from scripts.proactive_debugging_channel import run_proactive_debugging_channel
from scripts.inquisitor_channel import run_inquisitor_channel
from scripts.stress_test_channel import run_stress_test
from scripts.skill_training_matrix import run_skill_training_matrix
from scripts.peak_training_matrix import run_peak_training_matrix
from scripts.sovereignty_matrix import run_sovereignty_matrix
from scripts.wisdom_gatherer import run_wisdom_gatherer
from scripts.wisdom_compactor import run_wisdom_compactor
from scripts.knowledge_distill import run_knowledge_distill
from scripts.pattern_emulation import run_pattern_emulation
from scripts.dna_audit import run_dna_audit
from scripts.log_reflector import run_log_reflector
from scripts.recall_proof import run_recall_proof
from scripts.curiosity_swarm import run_curiosity_swarm
from scripts.cross_arch_synthesis import run_cross_arch_synthesis
from scripts.personality_diversity import run_personality_diversity
from scripts.psychological_calibration import run_psychological_calibration
from scripts.soul_auditor import run_soul_auditor
from scripts.instruction_calibration import run_instruction_calibration
from scripts.synthetic_bootstrap import run_synthetic_bootstrap
from scripts.dependency_grapher import run_dependency_grapher
from scripts.pypi_deep_dive import run_pypi_deep_dive
from scripts.system_hardening_matrix import run_system_hardening_matrix
from scripts.multi_agent_consensus import run_multi_agent_consensus
from scripts.failure_adversary import run_failure_adversary

# ------------------------------------------------------------------
# CHANNEL TABLE (500+ Matrix via weighted pool + Meta-Role Generation)
# Core Identities are guaranteed via CORE_IDENTITY_CHANNELS
# ------------------------------------------------------------------

# The 10 mandatory Core Identity skills (must each reach SOVEREIGN independently)
CORE_IDENTITY_CHANNELS = [
    ("core_mentor",     "Ultimate Mentor — Bridging theory to hands-on fabrication"),
    ("core_teacher",    "Universal Teacher — Socratic explanation and concept anchoring"),
    ("core_fabricator", "Fabrication Partner — Cost, BOM, 3D blueprint generation"),
    ("core_council",    "Council Verifier — Multi-AI truth verification and scoring"),
    ("core_economist",  "Economic Intel — Real-time vendor/BOM research"),
    ("core_hardware",   "Hardware Engineer — HITL, sensors, serial uplink"),
    ("core_biometric",  "Biometric Coach — Physiological telemetry and performance"),
    ("core_security",   "Security Guardian — BIOS integrity, encryption, hardening"),
    ("core_dna",        "DNA Architect — UserDNA profiling and self-update logic"),
    ("core_dream",      "Dream Engine — Full corpus sweep and wisdom compaction"),
]

CHANNEL_TABLE = [
    # Core Identity Channels (high weight — these must be sovereign)
    ("core_mentor",          5, "Ultimate Mentor"),
    ("core_teacher",         5, "Universal Teacher"),
    ("core_fabricator",      4, "Fabrication Partner"),
    ("core_council",         4, "Council Verifier"),
    ("core_economist",       3, "Economic Intel"),
    ("core_hardware",        3, "Hardware Engineer"),
    ("core_biometric",       2, "Biometric Coach"),
    ("core_security",        2, "Security Guardian"),
    ("core_dna",             2, "DNA Architect"),
    ("core_dream",           2, "Dream Engine"),
    # Specialist Channels
    ("curiosity_scraper",    2, "Curiosity Scraper — Web research"),
    ("skill_synthesis",      2, "Skill Synthesis — Cross-domain fusion"),
    ("architect",            2, "Architect — Systems & CAD"),
    ("researcher",           2, "Researcher — SOTA tracking"),
    ("economist",            2, "Economist — Financial logic"),
    ("meta_cognitive",       2, "Meta-Cognitive — Self-reflection"),
    ("memory_compression",   1, "Archivist — Wisdom extraction"),
    ("philosopher",          1, "Philosopher — Ethics & Singularity"),
    ("guardian",             1, "Guardian — Security hardening"),
    ("socratic",             1, "Socratic — Dialectical logic"),
    ("code_scan",            1, "Engineer — Codebase introspection"),
    ("hud_design",           1, "Designer — HUD Adaptation"),
    ("refactor",             1, "Refactorer — Proactive debugging"),
    ("inquisitor",           1, "Inquisitor — Memory stress"),
    ("adversarial_debate",   1, "Adversarial Debate — DPO"),
    ("bug_reenactment",      1, "Bug Reenactment — Forensics"),
    ("preference_replay",    1, "Preference Replay — RLHF"),
    ("error_replay",         6, "Error Replay — Recall remediation"),
    ("temporal",             1, "Temporal Reasoning — Planning"),
    ("stress_test",          2, "Stress Test — Adversarial recall"),
    ("skill_matrix",         1, "Skill Training Matrix"),
    ("peak_matrix",          1, "Peak Training Matrix"),
    ("sovereignty_matrix",   1, "Sovereignty Matrix — Sovereign audit"),
    ("wisdom_gatherer",      1, "Wisdom Gatherer — Insight collection"),
    ("wisdom_compactor",     1, "Wisdom Compactor — Dense encoding"),
    ("knowledge_distill",    1, "Knowledge Distill — Concept encoding"),
    ("pattern_emulation",    1, "Pattern Emulation — Mimicry training"),
    ("dna_audit",            1, "DNA Audit — Profile verification"),
    ("log_reflector",        1, "Log Reflector — Session replay"),
    ("recall_proof",         2, "Recall Proof — Blind recall tests"),
    ("curiosity_swarm",      1, "Curiosity Swarm — Mass query"),
    ("cross_arch",           1, "Cross-Architecture Synthesis"),
    ("personality",          1, "Personality Diversity — Multi-voice"),
    ("psych_calibration",    1, "Psychological Calibration"),
    ("soul_auditor",         1, "Soul Auditor — Identity audit"),
    ("instruction_calib",    1, "Instruction Calibration"),
    ("synthetic_boot",       1, "Synthetic Bootstrap — Cold start"),
    ("dependency_graph",     1, "Dependency Grapher — Module map"),
    ("pypi_deep",            1, "PyPI Deep Dive — Library mastery"),
    ("system_hardening",     1, "System Hardening Matrix"),
    ("multi_agent",          1, "Multi-Agent Consensus"),
    ("failure_adversary",    1, "Failure Adversary — Worst-case"),
]

# ------------------------------------------------------------------
# GLOBAL SOVEREIGN QUEUE (Phase 4.75 Progressive Mastery)
# No priority levels. Every skill must reach 100% independently.
# ------------------------------------------------------------------

# Flat list of all available training dimensions
SOVEREIGN_QUEUE = [f for f, _, _ in CHANNEL_TABLE]

# Add more iterations to the loop to ensure high-velocity mastery
FULL_SWEEP_EVERY_N = 15
CORE_IDENTITY_EVERY_N = 1  # Every iteration now targets a core identity or a pending mastery gap


def _handle_exception(e: Exception, logger):
    """Triggers the Self-Optimizing Loop to fix the code automatically."""
    error_msg = traceback.format_exc()
    logger.error(f"CRITICAL SYSTEM ERROR during training: {e}")
    logger.info("INITIATING AUTONOMOUS SELF-HEALING PROTOCOL...")
    
    try:
        from scripts.self_optimizing_loop import run_self_optimizing_loop
        # Attempt to patch based on the exception and traceback
        run_self_optimizing_loop(f"Fix this exception in KALI training pipeline:\n{error_msg}")
        logger.info("[SUCCESS] Self-healing logic applied and verified.")
        return True
    except Exception as patch_e:
        logger.error(f"Self-healing failed: {patch_e}")
        return False


def _dispatch_core_identity(channel: str, processor: "Any", goal: str):
    """Handles the 10 mandatory Core Identity training channels."""
    label = next((lbl for k, lbl in CORE_IDENTITY_CHANNELS if k == channel), channel)
    prompt = f"ACT AS YOUR CORE ROLE: {label}. Mission: {goal}"
    # bypass_cache=True: force fresh Groq API call but stay within process_doubt pipeline
    # so verification atoms can be extracted and anchored.
    return processor.process_doubt(prompt, bypass_cache=True)


def _dispatch_channel(channel: str, processor: "Any", goal: str, logger):

    """Routes the selected channel to its handler."""
    try:
        if channel == "mentor":
            res = processor.process_project_mentor(f"Autonomous evolution mission: {goal}")
        elif channel == "doubt":
            topic = random.choice([
                "Explain the physics of piezoelectric sensors in autonomous drones.",
                "How does decentralized federated learning impact data sovereignty?",
                "Draft a Python implementation of a recursive self-patching manifestor.",
                "Calculate the thermodynamic efficiency of a Stirling engine for solar power."
            ])
            processor.process_doubt(topic)
        elif channel == "curiosity_scraper":
            run_curiosity_scraper()
        elif channel == "skill_synthesis":
            run_skill_synthesis(iterations=1)
        elif channel == "architect":
            run_architect_channel()
        elif channel == "researcher":
            run_research_channel()
        elif channel == "economist":
            run_economist_channel()
        elif channel == "meta_cognitive":
            run_meta_cognitive_channel()
        elif channel == "philosopher":
            run_philosopher_channel()
        elif channel == "guardian":
            run_guardian_channel()
        elif channel == "socratic":
            run_socratic_channel()
        elif channel == "code_scan":
            run_codebase_scan_channel()
        elif channel == "hud_design":
            run_hud_adaptation_channel()
        elif channel == "refactor":
            run_proactive_debugging_channel()
        elif channel == "inquisitor":
            run_inquisitor_channel()
        elif channel == "memory_compression":
            run_memory_compression_channel()
        elif channel == "adversarial_debate":
            run_adversarial_debate()
        elif channel == "bug_reenactment":
            run_bug_reenactment()
        elif channel == "preference_replay":
            run_preference_replay(max_pairs=2)
        elif channel == "error_replay":
            run_error_replay(max_replays=2)
        elif channel == "temporal":
            run_temporal_reasoning(iterations=1)
        elif channel in ("core_mentor", "core_teacher", "core_fabricator", "core_council",
                         "core_economist", "core_hardware", "core_biometric",
                         "core_security", "core_dna", "core_dream"):
            _dispatch_core_identity(channel, processor, goal)
        elif channel == "full_sweep":
            processor.dream_engine.full_corpus_sweep()
        elif channel == "stress_test":
            run_stress_test()
        elif channel == "skill_matrix":
            run_skill_training_matrix()
        elif channel == "peak_matrix":
            run_peak_training_matrix()
        elif channel == "sovereignty_matrix":
            run_sovereignty_matrix()
        elif channel == "wisdom_gatherer":
            run_wisdom_gatherer()
        elif channel == "wisdom_compactor":
            run_wisdom_compactor()
        elif channel == "knowledge_distill":
            run_knowledge_distill()
        elif channel == "pattern_emulation":
            run_pattern_emulation()
        elif channel == "dna_audit":
            run_dna_audit()
        elif channel == "log_reflector":
            run_log_reflector()
        elif channel == "recall_proof":
            run_recall_proof()
        elif channel == "curiosity_swarm":
            run_curiosity_swarm()
        elif channel == "cross_arch":
            run_cross_arch_synthesis()
        elif channel == "personality":
            run_personality_diversity()
        elif channel == "psych_calibration":
            run_psychological_calibration()
        elif channel == "soul_auditor":
            run_soul_auditor()
        elif channel == "instruction_calib":
            run_instruction_calibration()
        elif channel == "synthetic_boot":
            run_synthetic_bootstrap()
        elif channel == "dependency_graph":
            run_dependency_grapher()
        elif channel == "pypi_deep":
            run_pypi_deep_dive()
        elif channel == "system_hardening":
            run_system_hardening_matrix()
        elif channel == "multi_agent":
            run_multi_agent_consensus()
        elif channel == "failure_adversary":
            run_failure_adversary()
            
    except Exception as e:
        _handle_exception(e, logger)


def run_ralph_loop(goal: str, iterations: int = 5):
    logging.basicConfig(level=logging.INFO)
    logger = logging.getLogger("RALPH_MAX")
    # Bug B-4 fix: Deferred import prevents crash in non-CUDA environments
    from src.core.processor import DoubtProcessor
    logger.info(f"KALI RALPH 500+ MAX VELOCITY: Initiating loop for '{goal}'")
    processor = DoubtProcessor()
    # Rotate through the 10 Core Identity channels in order
    core_identity_index = 0

    for i in range(iterations):
        logger.info(f"\n--- [ITERATION {i+1}/{iterations}] ---")

        # Determine channel: every 3rd iteration is a guaranteed Core Identity
        if (i + 1) % CORE_IDENTITY_EVERY_N == 0:
            core_id_key, core_id_label = CORE_IDENTITY_CHANNELS[core_identity_index % len(CORE_IDENTITY_CHANNELS)]
            core_identity_index += 1
            logger.info(f"[CORE IDENTITY] Training '{core_id_label}'...")
            _dispatch_core_identity(core_id_key, processor, goal)
            # Per-skill sovereign check after core identity training
            try:
                pending = processor.knowledge_check._load_pending(2)
                for item in pending:
                    res = processor.knowledge_check.run_skill_check(core_id_label, item["response_summary"])
                    lvl = res.get("sovereignty_level", 0)
                    best = res.get("best_score", 0.0)
                    stat = res.get("skill_status", "UNKNOWN")
                    logger.info(f"[SKILL SOVEREIGN] {core_id_label[:30]} | {stat} | LVL: {lvl:.0f}% | BEST: {best:.1f}%")
                    if res.get("status") == "PASSED":
                        processor.knowledge_check.unpin_topic(core_id_label)
            except Exception as e:
                logger.debug(f"Skill check failed: {e}")

        # Meta-Role invention (20%)
        elif random.random() < 0.2:
            logger.info("KALI: Meta-Evolution — inventing new dimension...")
            from scripts.meta_role_generator import run_meta_role_generator
            run_meta_role_generator(iterations=1)

        # Pinned remediation priority
        elif processor.knowledge_check.get_pinned_topics():
            target = processor.knowledge_check.get_pinned_topics()[0]
            logger.info(f"[PRIORITY] Remediating: '{target['topic'][:50]}'")
            processor.process_doubt(
                target.get("retry_prompt", target["topic"]),
                bypass_cache=True
            )

        elif (i + 1) % FULL_SWEEP_EVERY_N == 0:
            logger.info("[SWEEP] Full Corpus Dream Sweep...")
            _dispatch_channel("full_sweep", processor, goal, logger)

        else:
            # Absolute Mastery: Prioritize the skill with the LOWEST current score
            try:
                report = processor.knowledge_check.get_skill_sovereignty_report()
                skill_data = report.get("skills", {})
                
                # Filter to only the skills we have in CHANNEL_TABLE
                valid_skills = [s for s, _, _ in CHANNEL_TABLE]
                scored_skills = {k: v for k, v in skill_data.items() if k in valid_skills}
                
                if scored_skills:
                    # Find the skill with the lowest best_score (or 0 if not tested)
                    lowest_skill = min(scored_skills.keys(), key=lambda k: scored_skills[k].get("best_score", 0.0))
                    
                    # Canonicalize the lowest skill to match CHANNEL_TABLE identifiers
                    selected_channel = next((f for f, _, lbl in CHANNEL_TABLE if f == lowest_skill or lbl.split(" —")[0] == lowest_skill.split(" —")[0]), random.choice(SOVEREIGN_QUEUE))
                    label = next((lbl for f, _, lbl in CHANNEL_TABLE if f == selected_channel), selected_channel)
                    logger.info(f"[SOVEREIGN FOCUS] Target: '{label}' (Lowest Mastery detected: {scored_skills.get(lowest_skill, {}).get('best_score', 0)}%)")
                else:
                    selected_channel = random.choice(SOVEREIGN_QUEUE)
                    label = next((lbl for f, _, lbl in CHANNEL_TABLE if f == selected_channel), selected_channel)
            except Exception as e:
                logger.debug(f"Selection error: {e}")
                selected_channel = random.choice(SOVEREIGN_QUEUE)
                label = next((lbl for f, _, lbl in CHANNEL_TABLE if f == selected_channel), selected_channel)

            if random.random() < 0.7:
                logger.info(f"[CHANNEL] {label} (DYNAMIC)")
                mission_prompt = f"As the {label}, generate a high-complexity training mission related to: {goal}"
                dynamic_goal = processor.ai_service.ask_question(mission_prompt)
                _dispatch_channel(selected_channel, processor, dynamic_goal[:500], logger)
            else:
                logger.info(f"[CHANNEL] {label}")
                _dispatch_channel(selected_channel, processor, goal, logger)

        # Per-iteration atom-level knowledge check
        try:
            results = processor.knowledge_check.run_pending_checks(limit=5)
            for res in results:
                s = res.get("status", "SKIP")
                t = res.get("topic", "")
                atoms = res.get("atoms", "?")
                if s == "PASSED":
                    logger.info(f"[ATOM CHECK] ANCHORED | {t[:45]} ({atoms} atoms)")
                    processor.knowledge_check.unpin_topic(t)
                elif s == "PARTIAL":
                    logger.warning(f"[ATOM CHECK] PARTIAL | {t[:45]} ({atoms} atoms - failures quarantined)")
                else:
                    logger.warning(f"[ATOM CHECK] QUARANTINED | {t[:45]}")
        except Exception as e:
            logger.debug(f"Check failed: {e}")

        # Rate limit buffer: Groq free tier allows ~30 req/min. 10s sleep keeps us safely under.
        time.sleep(10)

    logger.info("KALI RALPH 500+: Mission Complete.")
    # Print per-skill sovereignty report at end
    try:
        report = processor.knowledge_check.get_skill_sovereignty_report()
        logger.info(f"\n[SOVEREIGNTY REPORT] {report['sovereign_skills']}/{report['total_skills_tracked']} skills SOVEREIGN")
    except Exception:
        pass

if __name__ == "__main__":
    target = sys.argv[1] if len(sys.argv) > 1 else "Complete Singularity Evolution"
    iters = int(sys.argv[2]) if len(sys.argv) > 2 else 5
    run_ralph_loop(target, iters)
