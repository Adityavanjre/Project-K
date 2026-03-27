#!/usr/bin/env python3
"""
KALI TEMPORAL REASONING CHANNEL (Phase 4.34)
Trains KALI on calendar-aware, deadline-aware, multi-phase project reasoning.
Addresses a gap where KALI understands design but not time-constrained planning.
"""

import logging
import os
import random
import sys

project_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
sys.path.insert(0, project_root)
sys.path.insert(0, os.path.join(project_root, 'src'))

from src.core.processor import DoubtProcessor

TEMPORAL_SCENARIOS = [
    {
        "prompt": (
            "You are managing a 5-phase hardware project. Phase 3 (PCB fabrication) is delayed by 11 days due to a component shortage. "
            "The final deadline is fixed. Phases 4 and 5 require Phase 3 to be complete before starting. "
            "Phase 4 has a 3-day buffer built in. Phase 5 has none. "
            "Re-plan the project: redistribute buffer, identify which tasks can be parallelized, and state clearly what the minimum team action is to avoid a deadline miss."
        ),
        "label": "Project Buffer Redistribution Under Constraint"
    },
    {
        "prompt": (
            "A sovereign AI hardware node project has 8 milestones over 16 weeks. "
            "It is currently week 6. Milestones 1-4 are complete. Milestone 5 is 60% done. "
            "Milestones 6, 7, 8 depend on 5 completing. A key engineer is unavailable for weeks 7-8. "
            "Generate a revised week-by-week plan. Identify the critical path, calculate float for each milestone, "
            "and output a risk-adjusted completion probability estimate."
        ),
        "label": "Critical Path Analysis with Resource Constraint"
    },
    {
        "prompt": (
            "Three simultaneous projects share the same microcontroller firmware team of 2 engineers: "
            "Project A (deadline: 4 weeks, 60 hours remaining), "
            "Project B (deadline: 6 weeks, 90 hours remaining), "
            "Project C (deadline: 3 weeks, 20 hours remaining). "
            "Engineers work 40 hours/week total. Using priority scheduling and earliest-deadline-first principles, "
            "generate an optimal weekly allocation table. Flag any deadlines that are at risk."
        ),
        "label": "Multi-Project Resource Scheduling with EDF"
    },
    {
        "prompt": (
            "A training pipeline processes 1000 target interactions. "
            "Currently at interaction 138. It processes approximately 20 interactions per hour autonomously. "
            "The knowledge check pass rate is currently 74%. Each failed check adds 1.5 extra interactions (retry). "
            "Calculate the projected completion time, the total interaction count including retries, "
            "and the week-by-week progress checkpoints assuming continuous 24-hour operation."
        ),
        "label": "Training Pipeline Completion Projection with Retry Overhead"
    },
    {
        "prompt": (
            "Design a 12-month KALI evolution roadmap. "
            "Month 1-3: Knowledge ingestion (target 500 clean training interactions). "
            "Month 4-6: Skill hardening (all knowledge checks must achieve >85% pass rate). "
            "Month 7-9: Cross-domain synthesis mastery. "
            "Month 10-12: Model replacement (achieving parity with GPT-4 class on domain benchmarks). "
            "For each phase, state: measurable completion criterion, leading indicator metrics, and failure recovery protocol."
        ),
        "label": "12-Month Evolution Roadmap with Phase Gates"
    }
]


def run_temporal_reasoning(iterations: int = 3):
    logging.basicConfig(level=logging.INFO)
    logger = logging.getLogger("TEMPORAL")
    processor = DoubtProcessor()

    logger.info("Temporal Reasoning Channel: Calendar-aware planning training initiated.")

    selected = random.sample(TEMPORAL_SCENARIOS, min(iterations, len(TEMPORAL_SCENARIOS)))

    for scenario in selected:
        logger.info(f"[TEMPORAL] {scenario['label']}")

        response = processor.ai_service.ask_question(
            f"You are KALI, the sovereign engineering strategist. {scenario['prompt']}"
        )

        processor.training_logger.log(
            f"TEMPORAL_REASONING [{scenario['label']}]: {scenario['prompt']}",
            response,
            "You are KALI, a sovereign time-aware engineering strategist."
        )

        logger.info(f"[+] Temporal scenario anchored: {scenario['label']}")

    logger.info("Temporal Reasoning Channel complete.")


if __name__ == "__main__":
    run_temporal_reasoning()
